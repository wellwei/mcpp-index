-- Regression coverage for compat.openssl's external-command failure paths.
-- The descriptor itself runs unchanged; only the xpkg runtime boundary is
-- supplied here so these cases do not need a real OpenSSL build.

local descriptor = arg[1] or "pkgs/c/compat.openssl.lua"

local function fail(message)
    error(message, 2)
end

local function assert_true(value, message)
    if not value then fail(message or "expected true") end
end

local function assert_false(value, message)
    if value then fail(message or "expected false") end
end

local function new_runtime(execute)
    local calls = {}
    local errors = {}
    local install_file_calls = 0

    local fake_os = {
        default_njob = function() return 2 end,
        exec = function(command)
            calls[#calls + 1] = command
            return execute(command)
        end,
        host = function() return "linux" end,
        isdir = function() return true end,
        isfile = function(pathname)
            return pathname:find("libcrypto.a", 1, true) ~= nil
                or pathname:find("libssl.a", 1, true) ~= nil
        end,
        mkdir = function() end,
        tryrm = function() end,
    }

    local env = {
        io = {
            readfile = function() return "simulated build log" end,
            writefile = function() end,
        },
        log = {
            error = function(fmt, ...)
                errors[#errors + 1] = string.format(fmt, ...)
            end,
        },
        math = math,
        os = fake_os,
        path = {
            join = function(...) return table.concat({...}, "/") end,
        },
        pkginfo = {
            build_dep = function() return nil end,
            install_dir = function() return "install" end,
            install_file = function()
                install_file_calls = install_file_calls + 1
                return nil
            end,
            version = function() return "3.5.1" end,
        },
        string = string,
        table = table,
        tostring = tostring,
        type = type,
    }

    env.pcall = pcall
    env.import = function(name)
        if name == "xim.libxpkg.system" then
            env.system = {
                exec = function(command)
                    local result = fake_os.exec(command)
                    if result == 0 or result == true then return end
                    error("exec failed: " .. command, 0)
                end,
            }
        end
    end
    setmetatable(env, {__index = function(_, key)
        fail("unexpected descriptor global: " .. tostring(key))
    end})

    local chunk = assert(loadfile(descriptor, "t", env))
    chunk()

    return {
        calls = calls,
        errors = errors,
        install = assert(env.install),
        install_file_calls = function() return install_file_calls end,
    }
end

local function commands_contain(calls, needle)
    for _, command in ipairs(calls) do
        if command:find(needle, 1, true) then return true end
    end
    return false
end

local function errors_contain(errors, needle)
    for _, message in ipairs(errors) do
        if message:find(needle, 1, true) then return true end
    end
    return false
end

local tests = {
    {
        name = "missing Perl core module stops before source access",
        run = function()
            local runtime = new_runtime(function(command)
                if command:find("perl -M", 1, true) then
                    return nil, "exit", 2
                end
                return true
            end)

            assert_false(runtime.install(), "install must reject an incomplete Perl")
            assert_true(commands_contain(runtime.calls, "perl -M"),
                        "install must probe the Perl modules OpenSSL requires")
            assert_true(errors_contain(runtime.errors, "FindBin"),
                        "diagnostic must identify the missing Perl module")
            assert_true(runtime.install_file_calls() == 0,
                        "Perl preflight must run before reading the source archive")
            assert_false(commands_contain(runtime.calls, "./config"),
                         "./config must not run after Perl preflight failure")
            assert_false(commands_contain(runtime.calls, " -j2"),
                         "make must not run after Perl preflight failure")
        end,
    },
    {
        name = "failed config stops before make",
        run = function()
            local runtime = new_runtime(function(command)
                if command:find("./config", 1, true) then
                    return nil, "exit", 2
                end
                return true
            end)

            assert_false(runtime.install(), "install must fail when ./config fails")
            assert_true(commands_contain(runtime.calls, "./config"),
                        "test setup must reach ./config")
            assert_false(commands_contain(runtime.calls, " -j2"),
                         "make must not run after ./config failure")
            assert_false(commands_contain(runtime.calls, "install_sw"),
                         "install_sw must not run after ./config failure")
            assert_true(errors_contain(runtime.errors, "./config failed"),
                        "diagnostic must identify ./config as the failed step")
        end,
    },
}

local failed = false
for _, test in ipairs(tests) do
    local ok, err = pcall(test.run)
    if not ok then
        io.stderr:write("not ok - " .. test.name .. "\n" .. tostring(err) .. "\n")
        failed = true
    else
        io.stdout:write("ok - " .. test.name .. "\n")
    end
end
if failed then os.exit(1) end
