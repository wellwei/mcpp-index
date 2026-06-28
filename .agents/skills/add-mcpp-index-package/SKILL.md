---
name: add-mcpp-index-package
description: Use when adding a new third-party library/package to the mcpp-index repo — writing a pkgs/*/*.lua descriptor, setting up a GitCode CN mirror via gtc, adding a minimal example, and opening a green PR. Covers the four package shapes (C-source compat / header-only / C++23 module / external Form-A module repo), the GLOBAL+CN mirror table, lint rules, the feature (sources-only) gate, and local + CI verification.
---

# 给 mcpp-index 新增一个库(SOP)

把一个上游库收录进 [`mcpp-index`](https://github.com/mcpplibs/mcpp-index) 的标准流程。产出 = 一个
`pkgs/<x>/<name>.lua` 描述符 + GitCode CN 镜像 + `tests/examples/` 最小工程 + README 一行 + 设计文档,最终
**本地实测绿 → 开 PR → CI 全绿 → 合并**(合并后 `publish-artifact.yml` 自动重发 index artifact)。

参考真实落地案例(逐字可抄):
- `.agents/docs/2026-06-27-add-cjson-and-nlohmann-json-plan.md`(C 源码 compat + 模块库)
- `.agents/docs/2026-06-28-add-eigen-plan.md`(header-only + source-gated `blas` feature)
- 既有 PR:#48(cjson + nlohmann.json),#50(eigen)。

> 配套参考文件(在仓库 `docs/` 下,人/agent 共用,按需读):
> - [docs/package-types.md](../../../docs/package-types.md) —— 四种库形态的描述符模板 + 真实样例路径
> - [docs/cn-mirror.md](../../../docs/cn-mirror.md) —— gtc / gitcode CN 镜像闭环(含无 mcpp-res 权限的回退)
> - [docs/repository-and-schema.md](../../../docs/repository-and-schema.md) —— 仓库结构、schema、CI、关键文件、踩坑清单

## 何时用 / 不用
- **用**:把一个新库(或新版本)加进 mcpp-index。两种来源都适用:
  - **(a) 第三方上游库** —— 自己没有 mcpp 支持(如 cJSON / Eigen / nlohmann),由本仓以 `compat` 形态适配。
  - **(b) 用户基于 mcpp 开发的库** —— 上游已经是 mcpp 工程(自带 `mcpp.toml`、`mcpp emit xpkg` 产出描述符、自有 release),
    要登记进索引(如 `mcpplibs.*`、`tensorvia-cpu`)。这类多是 **Form A**:描述符只声明元数据 + 下载地址,无需内联构建。
- **不用**:改 mcpp 本体、改 xlings 引擎、纯文档。那些不在本仓。

## 总流程(12 步)

按顺序做;每步的细节进对应参考文件。建议用 todo 跟踪。

1. **调研来源与形态**(最关键,决定模板)
   - **先分清来源**:是 (a) 第三方上游库,还是 (b) 用户自己的 mcpp 库?
     - (b) 自有 mcpp 库:形态已定(Form A,模块库),版本/release 上游已有 → 本步很轻,直接拿上游 `mcpp emit xpkg` 的描述符
       或照 `pkgs/t/tensorvia-cpu.lua` 写;重点落在镜像 + 登记 + 验证。
     - (a) 第三方库:需判形态(下面)。
   - 上游仓库、**最新 tag/版本**(`git ls-remote --tags <repo>` → `sort -V | tail`;注意大版本跳跃,如 Eigen 3.4 → 5.x)。
   - License、源码布局:下 tarball,`tar -tzf` 看顶层 wrap 目录 + 子目录;判断是
     **纯头 / C 源码 / 自带 `.cppm` 模块 / 有可选组件(可做 feature)**。
   - 算 `sha256sum`,并**复算两次确认稳定**(GitLab/部分归档会重新打包导致 sha 漂移 → CI 用 GLOBAL 拉取会校验失败)。
2. **定形态 → 选模板**:见 [docs/package-types.md](../../../docs/package-types.md)。四类:C-source compat / header-only / C++23 module(generated wrapper)/ 外部 Form-A 模块仓。
3. **建 CN 镜像**:`gtc` 在 gitcode `mcpp-res` org 下建仓 + 发 release,上传**与 GLOBAL 同一个 tarball**(保证 byte-identical → 同 sha)。**没有 `mcpp-res` 写权限时**:不要写镜像表,直接用 plain-string `url = "<GLOBAL 上游 release>"`(lint 允许;CN 用户回落上游),留给维护者后补镜像 —— 详见 [docs/cn-mirror.md](../../../docs/cn-mirror.md)。
4. **写描述符** `pkgs/<x>/<name>.lua`
   - ⚠️ **目录 `<x>` = 完整包名首字母**(`compat.eigen` → `pkgs/c/`,`nlohmann.json` → `pkgs/n/`),**不是短名**。放错本地 path index 会 `not found in local index`。
   - 三平台 `xpm`(linux/macosx/windows),每个版本 `url = { GLOBAL=…, CN=… }` + `sha256`。
   - 版本号写**裸版本**(`"1.2.3"`,不带前导 `v`);下载 URL 里可保留上游 `…/v1.2.3.tar.gz`。
5. **识别可门控的可选组件 → feature**(见下"feature 机制")。只能门控 **sources**。
6. **最小工程** `tests/examples/<short>/`(`short` = 包名去 `compat.`/`mcpplibs.` 前缀)
   - `mcpp.toml`(`[indices].compat = { path = "../../.." }` 指回仓根)+ 一个 `src/main.*`,做一个**会失败的真断言**(`return ok?0:1`)。
   - 若要测 feature:依赖写长式 `name = { version = "…", features = ["…"] }`。
7. **本地实测**(用与 CI 同版本的 mcpp):见下"本地验证"。必须真跑过 `mcpp build && mcpp run` 绿。
8. **README** 在对应表(mcpplibs 模块库 / 独立模块库 / 第三方 C/C++ 库)加一行。
9. **设计文档** `.agents/docs/<YYYY-MM-DD>-add-<lib>-plan.md`,记录形态判断、镜像、feature 评估、实测结论、踩坑。
10. **本地 lint**:模拟 `validate.yml` 的 lint(语法 / 必填字段 / 无前导 v / mirror 检查)。见 [docs/repository-and-schema.md](../../../docs/repository-and-schema.md)。
11. **分支 → commit → push → PR**(从 `main` 切新分支;别直接推 main)。PR 描述写清形态、镜像、feature、实测。
12. **盯 CI 绿**:`detect` 应只选中本库的 example(`smoke-full-linux`/`portable` 显示 `skipping`),`smoke-examples (<short>)` 绿;`mirror-cn-reachable` 覆盖新 CN url。合并交维护者。

## feature 机制(务必读准)

mcpp **0.0.68** 的包描述符 `features` 表 **只能门控 `sources`**(其它子字段被 skip;源码核实见 `manifest.cppm` 的 features 解析)。

```lua
mcpp = {
    sources  = { "*/core.c" },                 -- 默认总编
    features = {
        ["extra"] = { sources = { "*/extra.c" } },  -- 默认排除;features=["extra"] 时编入同一个 lib 目标
    },
}
```
- 消费侧:`dep = { version = "…", features = ["extra"] }`。
- 真实例:`compat.gtest` 的 `main`(gtest_main.cc)、`compat.cjson` 的 `utils`(cJSON_Utils.c)、`compat.eigen` 的 `blas`(`*/blas/*.cpp` + `*/blas/f2c/*.c`)。
- **判定"可不可以做 feature"**:这个可选组件是不是**额外的可编译源码**?是 → 能门控。
  纯头(如 Eigen `unsupported/`,与核共享 include 根,藏不住)→ 不能。
  编译 **define**(如 `EIGEN_MPL2_ONLY`、`EIGEN_USE_BLAS`)→ 当前 feature 表带不了 → 不能(留注释,待 mcpp 支持 define/cflags)。
- **glob**:支持 `*`(段内)与 `**`(跨段),所以 `*/blas/*.cpp`、`*/foo/**/*.c` 都行。
- **必须做负向验证**:不带 feature 时那个符号/源应**确实缺失**(链接 `undefined reference` 或编译找不到),证明门控真生效——不是默认就编进去了。

## 本地验证(与 CI 同版本)

CI 的 mcpp 版本 = `.github/workflows/validate.yml` 的 `env.MCPP_VERSION`。**用同一版本本地跑**,别用恰好装着的旧版。

```bash
MV=$(grep -oP 'MCPP_VERSION:\s*"\K[0-9.]+' .github/workflows/validate.yml)
curl -L -fsS -o mcpp.tgz "https://github.com/mcpp-community/mcpp/releases/download/v$MV/mcpp-$MV-linux-x86_64.tar.gz"
tar -xzf mcpp.tgz
root="$PWD/mcpp-$MV-linux-x86_64"
mkdir -p ~/.mcpp/registry && cp -a "$root/registry/." ~/.mcpp/registry/
export MCPP="$root/bin/mcpp"
export MCPP_VENDORED_XLINGS="$root/registry/bin/xlings"
export MCPP_INDEX_MIRROR=GLOBAL          # CI example 走 GLOBAL;CN 由 mirror-cn-reachable 单独兜
MCPP="$MCPP" bash tests/run_example.sh <short>
```
- 输出末尾要有你的断言行 + `OK: <short>`。
- run_example.sh 会 `rm -rf target .mcpp` 从干净态走真实管线(fetch→generate→compile→link→run)。
- 想直接看头/源:解包在 `tests/examples/<short>/.mcpp/.xlings/data/xpkgs/<idx>-x-<name>/<ver>/<wrap>/`。

## 红线 / 常见错误

- ❌ 把 `compat.foo.lua` 放进 `pkgs/f/`。✅ 放 `pkgs/c/`(完整名首字母)。
- ❌ 版本写 `"v1.2.3"`。✅ 裸 `"1.2.3"`(lint 会拦前导 v)。
- ❌ CN 镜像传了"加工过"的包(≠ GLOBAL)。✅ 传 GLOBAL 同一个 tarball,sha 一致;否则破坏 GLOBAL/CN 一致性。
- ❌ 只 `mcpp build` 不 `run`,或例子里没有真断言。✅ 真跑 + `return ok?0:1`。
- ❌ 宣称"做了 feature"却没负向验证。✅ 证明默认确实不含。
- ❌ 没对齐 CI 的 mcpp 版本,本地绿 CI 红。✅ 读 `MCPP_VERSION`。
- ❌ 直接 push `main`。✅ 切分支开 PR。
- 完成前遵循 `verification-before-completion`:**贴出真实命令输出**再说"绿/完成",不要凭感觉。
