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
            ["0.0.2"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.2.tar.gz",
                sha256 = "dd2199c76ea762fc2eb084967fa42953c8b876e076e41b57409f84b322e3161e",
            },
            ["0.0.3"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.3.tar.gz",
                sha256 = "55bc5c557f5c803279f923e0335a788a6d6f57289b3c2e1a0dd0cc46414b3524",
            },
            ["0.0.4"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.4.tar.gz",
                sha256 = "d10f7794225de45167e0ff88cb37532ae8a4f00d145fcdaa58fe19702467bc44",
            },
            ["0.0.5"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.5.tar.gz",
                sha256 = "6b729104166b8dd0db5c6d5018ffcd24c0df6a9fc0e4381f1f8151c22724bed6",
            },
        },
        macosx = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0",
            },
            ["0.0.2"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.2.tar.gz",
                sha256 = "dd2199c76ea762fc2eb084967fa42953c8b876e076e41b57409f84b322e3161e",
            },
            ["0.0.3"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.3.tar.gz",
                sha256 = "55bc5c557f5c803279f923e0335a788a6d6f57289b3c2e1a0dd0cc46414b3524",
            },
            ["0.0.4"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.4.tar.gz",
                sha256 = "d10f7794225de45167e0ff88cb37532ae8a4f00d145fcdaa58fe19702467bc44",
            },
            ["0.0.5"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.5.tar.gz",
                sha256 = "6b729104166b8dd0db5c6d5018ffcd24c0df6a9fc0e4381f1f8151c22724bed6",
            },
        },
        windows = {
            ["0.0.1"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.1.tar.gz",
                sha256 = "168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0",
            },
            ["0.0.2"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.2.tar.gz",
                sha256 = "dd2199c76ea762fc2eb084967fa42953c8b876e076e41b57409f84b322e3161e",
            },
            ["0.0.3"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.3.tar.gz",
                sha256 = "55bc5c557f5c803279f923e0335a788a6d6f57289b3c2e1a0dd0cc46414b3524",
            },
            ["0.0.4"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.4.tar.gz",
                sha256 = "d10f7794225de45167e0ff88cb37532ae8a4f00d145fcdaa58fe19702467bc44",
            },
            ["0.0.5"] = {
                url    = "https://github.com/mcpplibs/imgui-m/archive/refs/tags/0.0.5.tar.gz",
                sha256 = "6b729104166b8dd0db5c6d5018ffcd24c0df6a9fc0e4381f1f8151c22724bed6",
            },
        },
    },

    -- (no `mcpp` field -- default lookup will find <verdir>/*/mcpp.toml)
}
