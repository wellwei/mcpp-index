# 参考:仓库结构 / schema / CI / 关键文件

## 仓库布局

```
pkgs/<x>/<name>.lua          描述符。<x> = 完整包名首字母(compat.* → c, nlohmann.json → n, imgui → i)
tests/examples/<short>/      每库最小工程(<short> = 名去 compat./mcpplibs. 前缀)
  mcpp.toml                  [indices].compat = { path = "../../.." }
  src/main.{cpp,c}
tests/run_example.sh <short> 通用 runner:rm -rf target .mcpp → mcpp build → mcpp run
tests/smoke_compat_*.sh      旧全量 smoke(已降级为 nightly/dispatch 兜底)
tests/check_mirror_urls.lua  lint:GLOBAL+CN 表完整性 + CN 指向 mcpp-res
tests/list_cn_urls.lua       抽 CN url(mirror-cn-reachable 用)
README.md                    index 列表(三张表:mcpplibs 模块库 / 独立模块库 / 第三方 C/C++ 库)
.github/workflows/validate.yml   CI:lint / mirror-cn-reachable / detect / smoke-examples / smoke-full-linux / smoke-portable
.agents/docs/<date>-*.md     设计文档惯例
tools/gtc                    gitcode CLI(见 cn-mirror.md)
.xpkgindex.json              站点配置(标题/链接/install 模板),一般不动
```

## 外部仓库 / 文档

- mcpp 本体:https://github.com/mcpp-community/mcpp(本地常有 clone:`/home/speak/workspace/github/mcpp-community/mcpp`)
  - `mcpp --version` 对齐 CI;feature/glob 行为以 `src/manifest.cppm`、`src/modgraph/scanner.cppm`、`src/build/prepare.cppm` 为准。
- xpkg 扩展 schema(权威):https://github.com/mcpp-community/mcpp/blob/main/docs/04-schema-xpkg-extension.md(本仓 `.xpkgindex.json` 的 "mcpp ext" 链接);V1 xpkg spec:`d2learn/xim-pkgindex` `docs/V1/xpackage-spec.md`(url-template 在 ~line 172)。
- CN 镜像组织:gitcode `mcpp-res`。

## 描述符 schema 速查(Form B inline)

`package` 必填:`spec`、`namespace`、`name`、`description`、`licenses`、`repo`、`type="package"`、`xpm`、`mcpp`。

`xpm.<linux|macosx|windows>.<bare-version>`:
- `url`：字符串 或 `{ GLOBAL=…, CN=… }`(本仓一律用表)。
- `sha256`：必填,= 实际下载字节。

`mcpp`(常用键):
| 键 | 说明 |
|---|---|
| `language` | 一般 `"c++23"` |
| `import_std` | 多数 `false` |
| `c_standard` | C 源:`"c99"`/`"c11"` |
| `modules` | module 库:`{ "x.y" }` |
| `include_dirs` | glob 列表,暴露给消费者的头目录 |
| `generated_files` | `{ ["相对路径"]="内容字符串" }`;**不支持 `[[…]]`,用 `\n`/`\"`** |
| `sources` | glob 列表,编入 lib 的源 |
| `cflags`/`cxxflags`/`ldflags` | 追加到对应规则 |
| `targets` | `{ ["name"]={ kind="lib"/"bin", main=…, soname=… } }` |
| `features` | `{ ["f"]={ sources={…} } }` —— **只认 sources** |
| `deps` | `{ ["ns.name"]="ver" }` 扁平/点号式 |

## CI 行为(validate.yml)

- 触发:PR(改 `pkgs/**/*.lua`、`tests/**`、`README.md`、本 workflow)/ push main / nightly cron / 手动。
- `env.MCPP_VERSION` = 全 job 用的 mcpp 版本 —— **本地实测对齐它**。
- `lint`(总跑):lua 语法 `loadfile(f,'t')`;必含 `spec=`/`name=`/`xpm=`;**禁前导 v 版本**;`check_mirror_urls.lua`。
- `mirror-cn-reachable`(总跑):逐个 `curl` CN url 要 200。
- `detect`:PR 时 `git diff` 改动的 `pkgs/*/*.lua` → basename 去 `compat.` → 若存在 `tests/examples/<short>/` 则**只跑它**;改动 scaffolding/CI 或无 example → 全量回归。
- `smoke-examples (<short>)`:干净 runner 跑 `run_example.sh`,`MCPP_INDEX_MIRROR=GLOBAL`。
- `smoke-full-linux` / `smoke-portable(mac/win)`:全量(push/nightly/dispatch/脚手架变更才跑);本库 PR 应显示 `skipping`。

## 本地 lint 一把梭(等价 CI lint job)

```bash
fail=0
for f in pkgs/*/*.lua; do
  lua5.4 -e "assert(loadfile('$f','t'))" >/dev/null 2>&1 || { echo "SYNTAX $f"; fail=1; }
  for n in 'spec *=' 'name *=' 'xpm *='; do grep -q "$n" "$f" || { echo "MISS $n $f"; fail=1; }; done
  grep -nqE '\["v[0-9]+|\["[^"]+"\][[:space:]]*=[[:space:]]*"v[0-9]+' "$f" && { echo "LEADING-V $f"; fail=1; }
  lua5.4 tests/check_mirror_urls.lua "$f" >/dev/null 2>&1 || { echo "MIRROR $f"; fail=1; }
done
[ $fail -eq 0 ] && echo "ALL LINT PASS ✓"
```

## 合并后

`publish-artifact.yml` 在合到 `main` 后自动重发 mcpp-index artifact + 移指针,**无需发 mcpp 版本**。在线浏览:
https://mcpplibs.github.io/mcpp-index/

## 真实案例(逐字可抄)

| 形态 | 描述符 | example | 设计文档 / PR |
|---|---|---|---|
| C 源 + feature | `pkgs/c/compat.cjson.lua`、`compat.gtest.lua` | `tests/examples/cjson/` | `.agents/docs/2026-06-27-add-cjson-and-nlohmann-json-plan.md` / #48 |
| C++23 module(generated wrapper) | `pkgs/n/nlohmann.json.lua` | `tests/examples/nlohmann.json/` | 同上 / #48 |
| header-only + source-gated feature | `pkgs/c/compat.eigen.lua` | `tests/examples/eigen/` | `.agents/docs/2026-06-28-add-eigen-plan.md` / #50 |
| header-only(纯头) | `pkgs/c/compat.opengl.lua`、`compat.khrplatform.lua` | — | `.agents/docs/2026-06-03-gl-runtime-packages-plan.md` |
