-- Print every CN mirror URL found in a package descriptor, one per line,
-- as "<cn_url>\t<sha256-or-empty>". Used by CI to check that each mirrored
-- asset is actually reachable on gitcode. Plain-string urls are ignored.
--
-- Usage: lua5.4 tests/list_cn_urls.lua <file.lua>

function import(...)
    return setmetatable({}, {__index = function() return function() end end})
end

local path = assert(arg[1], "usage: list_cn_urls.lua <file>")
package = nil
local chunk = assert(loadfile(path, "t"))
chunk()

local p = package
if type(p) ~= "table" then os.exit(0) end

local seen = {}
local xpm = p.xpm or {}
for _, vt in pairs(xpm) do
    if type(vt) == "table" then
        for _, entry in pairs(vt) do
            if type(entry) == "table" and type(entry.url) == "table" then
                local cn = entry.url.CN
                if type(cn) == "string" and cn ~= "" and not seen[cn] then
                    seen[cn] = true
                    print(cn .. "\t" .. (entry.sha256 or ""))
                end
            end
        end
    end
end
