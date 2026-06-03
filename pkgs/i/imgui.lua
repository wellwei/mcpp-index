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
                sha256 = "168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0",
            },
        },
        macosx = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0",
            },
        },
        windows = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0",
            },
        },
    },

    -- (no `mcpp` field -- default lookup will find <verdir>/*/mcpp.toml)
}
