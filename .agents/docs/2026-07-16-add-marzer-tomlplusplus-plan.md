# 收录 toml++(marzer.tomlplusplus)3.4.0

> PR: https://github.com/mcpplibs/mcpp-index/pull/64
> 日期:2026-07-16
> 背景:PR #64 原以 fork 形态提交,按 review 意见([comment](https://github.com/mcpplibs/mcpp-index/pull/64#issuecomment-4907425691))
> 参照 `nlohmann.json` 重做。本文记录形态判定、镜像、验证结论与注意事项。

## 1. 来源与形态判定

- 来源:**(a) 第三方上游库**。上游 [marzer/tomlplusplus](https://github.com/marzer/tomlplusplus) 不提供 mcpp 支持。
- 版本:`v3.4.0`(截至 2026-07-16 的最新 release tag)。
- License:MIT。
- 布局:tarball 顶层 wrap 目录为 `tomlplusplus-3.4.0/`,头文件位于 `include/toml++/`,**header-only**。
- 形态:**C++23 module(generated wrapper)** —— 与 `nlohmann.json` 同类。

判定依据:release tarball **不含** 任何 `.cppm`:

```console
$ tar tzf tomlplusplus-3.4.0.tar.gz | grep -iE 'cppm|modules'
tomlplusplus-3.4.0/.gitmodules          # 仅 git submodule 配置,非模块单元
```

而上游**确实**已编写官方模块单元 `src/modules/tomlplusplus.cppm`(`export module tomlplusplus;`),
但它只存在于 `master` 分支,未进入 v3.4.0。因此采用 `generated_files` 内嵌该 cppm,
基础头文件仍 pin 在可复现的 v3.4.0 release tag —— **信任链上不引入 fork**。

## 2. 关键注意事项:master 的 cppm 不能原样内嵌

⚠️ 这是本次收录最容易踩的坑,与 `nlohmann.json`(可 VERBATIM 内嵌)不同。

上游 master 的 cppm 面向 master 的头文件编写,其中一行:

```cpp
using TOML_NAMESPACE::get_line;
```

`get_line` 是 v3.4.0 **之后**才加入 `include/toml++/impl/source_region.hpp` 的。对 pinned 的 v3.4.0 头文件做
负向验证,确认其确实不存在:

```console
$ grep -rn "get_line" tomlplusplus-3.4.0/          # 整个 tarball 无任何命中

$ cat probe.cpp
#include <toml++/toml.hpp>
namespace probe { using toml::get_line; }
int main(){}

$ g++ -std=c++17 -fsyntax-only -Iinclude probe.cpp
probe.cpp:2:31: error: 'get_line' has not been declared in 'toml'

$ # 对照组:同一探针换成 toml::parse,编译通过 —— 证明头文件本身无恙
```

**结论**:内嵌版本删除该行,其余**逐字节一致**(已用 `diff` 对内嵌内容与上游 master 减去该行的结果做校验,结果 IDENTICAL)。
差异已在描述符注释中写明。

**演进条件**:待上游发布 >3.4.0 且随 release 附带 `src/modules/tomlplusplus.cppm` 时,可切回
`sources = { "*/src/modules/tomlplusplus.cppm" }` 并删除 `generated_files`,`get_line` 会随之回归。

## 3. 描述符

- 路径:`pkgs/m/marzer.tomlplusplus.lua`(目录取**完整包名首字母** `m`)。
- 命名:`marzer.tomlplusplus`,遵循 `nlohmann.json` 的 `<命名空间>.<库>` 约定。
- `include_dirs = { "*/include" }`:cppm 的 global-module fragment 内 `#include <toml++/toml.hpp>` 由此解析;
  同时保留用户直接 `#include` 的能力。`*` 吸收 `tomlplusplus-3.4.0/` wrap 层。
- `generated_files` 的 key 为 verdir 相对路径(无 glob),与 `nlohmann.json` 一致。
- 多行字符串采用 `[==[ ]==]`(而非 `[[ ]]`):与 `nlohmann.json` 保持一致,且对 payload 中可能出现的
  `[[`/`]]` 更稳妥。已确认 payload 不含 `]==]`。
- 版本号采用裸版本 `"3.4.0"`;URL 中保留上游 `…/v3.4.0.tar.gz` 拼写。

## 4. feature 评估

**不实现 feature**。toml++ 为 header-only,无“额外的可编译源码”可供门控;其可选行为(如 `TOML_EXCEPTIONS`、
`TOML_ENABLE_FORMATTERS`)均为编译期 **define**,而 `features` 表当前仅能门控 `sources`,无法携带 define。
与 Eigen 的 `EIGEN_MPL2_ONLY` 属同类限制,待 mcpp 支持 define/cflags 后再评估。

## 5. CN 镜像

- 新建 gitcode 仓库 `mcpp-res/tomlplusplus`(经 `gtc repo create` + init commit 建立 `main` 分支)。
- release tag `3.4.0`,资产 `tomlplusplus-3.4.0.tar.gz`,上传的是**与 GLOBAL 完全相同**的 tarball。
- 字节一致性验证:

```console
CN  sha: 8517f65938a4faae9ccf8ebb36631a38c1cadfb5efa85d9a72e15b9e97d25155
GLB sha: 8517f65938a4faae9ccf8ebb36631a38c1cadfb5efa85d9a72e15b9e97d25155
cmp   : byte-identical
```

- sha 稳定性:GLOBAL 重复下载两次,sha 一致(无 GitLab 式重打包漂移)。

## 6. 验证结论

测试工程 `tests/examples/marzer.tomlplusplus/`,已登记进根 `mcpp.toml` 的 `[workspace].members`
(本仓测试面已由 `run_example.sh` 迁移至 `mcpp test --workspace`,故不再新增 `src/main.cpp` 式 bin 例子)。
断言覆盖 parse、typed access、array/table 节点、`_toml` 字面量、serialize→reparse 往返。

| 检查 | 结果 |
|---|---|
| `mcpp test`(GLOBAL) | ✅ `parse ... ok` — 1 passed |
| `mcpp test`(`MCPP_INDEX_MIRROR=CN`,清 `target .mcpp mcpp.lock` 后真实重新下载) | ✅ `parse ... ok` — 1 passed |
| CN vs GLOBAL 字节比对 | ✅ byte-identical |
| 全量 lint(46 descriptor,含 `check_mirror_urls.lua`) | ✅ all valid |
| `mcpp xpkg parse`(CI pin 0.0.91 与本地 0.0.93) | ✅ OK |
| 内嵌 cppm vs 上游 master 减 get_line | ✅ `diff` IDENTICAL |

## 7. 其它

- PR #64 原分支落后 `main` 10 个提交,已 rebase 到最新 `main` 后强推(`maintainerCanModify` 为 true)。
- 原 `pkgs/c/compat.tomlplusplus.lua` 与 `tests/examples/tomlplusplus/` 已删除。
