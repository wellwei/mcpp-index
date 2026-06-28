# 库形态与描述符模板

先判断库属于哪一类,再抄对应模板。所有 `mcpp = {}` 内路径是**相对 verdir 的 GLOB**,前导 `*` 吸收 tarball 的
`<repo>-<tag>/` wrap 层;`*` 匹配单段、`**` 跨段(`*/blas/*.cpp` 合法)。

四类速判:

| 形态 | 特征 | 真实样例 | 关键字段 |
|---|---|---|---|
| **A. C 源码 compat** | 纯 C/少量源、用户 `#include <foo.h>` | `pkgs/c/compat.cjson.lua`、`compat.zlib.lua`、`compat.gtest.lua` | `sources` + `c_standard` |
| **B. header-only** | 纯头、无需编译 | `pkgs/c/compat.eigen.lua`、`compat.opengl.lua`、`compat.khrplatform.lua` | `include_dirs` + anchor 源 |
| **C. C++23 module** | 暴露 `import x.y;` | `pkgs/n/nlohmann.json.lua` | `modules` + `generated_files`/源 `.cppm` |
| **D. 外部 Form-A 模块仓** | 上游自带 mcpp 描述,独立仓 | `pkgs/i/imgui.lua`、`pkgs/m/mcpplibs.*` | `mcpp = "<repo 路径>"`(Form A) |

公共骨架(`package` 头 + `xpm`),A/B/C 通用:

```lua
package = {
    spec        = "1",
    namespace   = "compat",          -- compat / nlohmann / mcpplibs / …(决定 import 前缀与依赖 key)
    name        = "compat.<lib>",    -- 完整包名;决定 pkgs/<首字母>/ 落点
    description = "…",
    licenses    = {"MIT"},           -- SPDX
    repo        = "https://…",
    type        = "package",

    xpm = {  -- 三平台都写;纯源码/纯头时三平台同 url+sha256
        linux   = { ["1.2.3"] = { url = { GLOBAL = "https://…/v1.2.3.tar.gz",
                                          CN     = "https://gitcode.com/mcpp-res/<slug>/releases/download/1.2.3/<slug>-1.2.3.tar.gz" },
                                  sha256 = "<算出来>" } },
        macosx  = { ["1.2.3"] = { url = { GLOBAL = "…", CN = "…" }, sha256 = "…" } },
        windows = { ["1.2.3"] = { url = { GLOBAL = "…", CN = "…" }, sha256 = "…" } },
    },

    mcpp = { … 见下各形态 … },
}
```

---

## A. C 源码 compat(`compat.cjson` / `compat.zlib`)

把 C 源编成 lib,头经 `include_dirs` 暴露。可选组件走 `features` 门控。

```lua
mcpp = {
    language     = "c++23",   -- 与既有 compat 对齐;真正的 C 由 c_standard 决定
    import_std   = false,
    c_standard   = "c99",     -- 或 c11
    include_dirs = { "*" },           -- 暴露顶层头(*/foo.h)
    sources      = { "*/cJSON.c" },   -- 核心源,总编
    targets      = { ["cjson"] = { kind = "lib" } },
    features     = {                  -- 可选扩展,默认不编
        ["utils"] = { sources = { "*/cJSON_Utils.c" } },
    },
    deps         = { },
}
```
要点:多源时逐个列(见 `compat.zlib` 列了 15 个 `.c`),或用 glob;需要配置头时用 `generated_files` 合成
(zlib 用 `mcpp_generated/include/mcpp_zlib_config.h` + `cflags = {"-include …"}`)。

## B. header-only(`compat.eigen` / `compat.opengl`)

无可编译源:`include_dirs` 暴露头,加一个 trivial anchor `.c` 给 mcpp 一个可构建的 lib 目标。

```lua
mcpp = {
    language     = "c++23",
    import_std   = false,
    c_standard   = "c11",
    include_dirs = { "*" },           -- 或更精确 "*/include" / "*/api"
    generated_files = {
        ["mcpp_generated/<lib>_anchor.c"] = "int mcpp_compat_<lib>_anchor(void) { return 0; }\n",
    },
    sources      = { "mcpp_generated/<lib>_anchor.c" },
    targets      = { ["<lib>"] = { kind = "lib" } },
    -- 若有"额外可编译源"组件(不是纯头!)→ source-gated feature:
    features     = {
        ["blas"] = { sources = { "*/blas/*.cpp", "*/blas/f2c/*.c" } },  -- eigen 实例
    },
    deps         = { },
}
```
注意:**纯头的可选项藏不住**(共享 include 根)→ 不要硬做 feature;只有"额外可编译源"才门控得了(eigen `blas` 就是
C++/f2c-C,无 Fortran → 可门控)。

## C. C++23 module(`nlohmann.json`)

让用户 `import x.y;`。两条路:
1. **上游已带 `.cppm`**:直接 `sources = { "*/path/to/unit.cppm" }`。
2. **上游 release 不带**(常见):用 `generated_files` 合成 wrapper(`#include <header>` + `export module x.y;` +
   `export using …`),基底头 pin 已发布 tag。**逐字复用上游官方 wrapper,别自己猜符号清单**。

```lua
mcpp = {
    schema       = "0.1",
    language     = "c++23",
    import_std   = false,                 -- wrapper 含上游头,开 import std 易冲突
    modules      = { "nlohmann.json" },
    include_dirs = { "*/single_include" }, -- 让 wrapper 内 #include <…> 可解析
    generated_files = {
        ["mcpp_generated/nlohmann.json.cppm"] = "module;\n#include <nlohmann/json.hpp>\nexport module nlohmann.json;\n…",
    },
    sources      = { "mcpp_generated/nlohmann.json.cppm" },
    targets      = { ["nlohmann_json"] = { kind = "lib" } },
    deps         = { },
}
```
⚠️ **mcpp 段解析器不支持 Lua 长括号 `[[ … ]]`**:`generated_files` 内容必须用双引号字符串 + `\n`/`\"` 转义
(否则 `malformed mcpp segment`)。消费侧:`import x.y;` 别和文本 `#include <string>` 混用(GCC modules 冲突),
配 `import std;`。

## D. 外部 Form-A 模块仓(`imgui` / `mcpplibs.*`)

上游/独立仓自带 mcpp 描述符,本仓只做"指针":`mcpp = "<相对/远程路径>"`(Form A,而非 inline 的 Form B)。
新增独立库基本属于另一个仓(如 `mcpplibs/imgui-m`),本仓只登记。照抄 `pkgs/i/imgui.lua`、`pkgs/m/mcpplibs.xpkg.lua` 的写法。

---

## 最小工程(`tests/examples/<short>/`)

`mcpp.toml`(短依赖 / 长依赖二选一):
```toml
[package]
name = "<short>-example"
version = "0.1.0"
[toolchain]
default = "gcc@16.1.0"
[indices]
compat = { path = "../../.." }            # 指回仓根 → 用本地描述符
[dependencies.compat]
<short> = "1.2.3"                          # 或:<short> = { version = "1.2.3", features = ["…"] }
[targets.<short>-example]
kind = "bin"
main = "src/main.cpp"                      # C 库可用 .c
```
`src/main.cpp`:做**真断言**并 `return ok ? 0 : 1`(别只打印)。module 库用 `import std; import x.y;`;
header/C 库用文本 `#include`。
