-- Form A descriptor: the public imgui module package ships its own
-- mcpp.toml. mcpp's default lookup finds <verdir>/*/mcpp.toml inside
-- the GitHub source tarball wrap.
--
package = {
    spec        = "1",
    name        = "imgui",
    namespace   = "",
    description = "C++23 module package for Dear ImGui core and GLFW/OpenGL3 backends",
    licenses    = {"MIT"},
    repo        = "https://github.com/mcpplibs/imgui-m",
    type        = "package",

    xpm = {
        linux = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "b87188bd2ca7d8010a695d5ebfccd76eb3e28b3e002885207493225057f5e190",
            },
        },
        macosx = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "b87188bd2ca7d8010a695d5ebfccd76eb3e28b3e002885207493225057f5e190",
            },
        },
        windows = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "b87188bd2ca7d8010a695d5ebfccd76eb3e28b3e002885207493225057f5e190",
            },
        },
    },

    -- (no `mcpp` field -- default lookup will find <verdir>/*/mcpp.toml)
}
