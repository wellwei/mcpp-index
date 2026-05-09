-- Form A descriptor: the upstream repo ships its own mcpp.toml from
-- v0.2.1 onwards, so we omit the `mcpp` field — mcpp default-look-up
-- finds <verdir>/<repo-tag>/mcpp.toml inside the GitHub tarball wrap.
package = {
    spec        = "1",
    name        = "mcpplibs.tinyhttps",
    description = "Minimal C++23 HTTP/HTTPS client with SSE streaming support",
    licenses    = {"Apache-2.0"},
    repo        = "https://github.com/mcpplibs/tinyhttps",
    type        = "package",

    xpm = {
        linux = {
            ["0.2.1"] = {
                url    = "https://github.com/mcpplibs/tinyhttps/archive/refs/tags/0.2.1.tar.gz",
                sha256 = "88adc68b1c1ec635c409604547fdfe8486aa1b376bad28c74858ed1f3ce5391c",
            },
        },
        macosx = {
            ["0.2.1"] = {
                url    = "https://github.com/mcpplibs/tinyhttps/archive/refs/tags/0.2.1.tar.gz",
                sha256 = "88adc68b1c1ec635c409604547fdfe8486aa1b376bad28c74858ed1f3ce5391c",
            },
        },
        windows = {
            ["0.2.1"] = {
                url    = "https://github.com/mcpplibs/tinyhttps/archive/refs/tags/0.2.1.tar.gz",
                sha256 = "88adc68b1c1ec635c409604547fdfe8486aa1b376bad28c74858ed1f3ce5391c",
            },
        },
    },
}
