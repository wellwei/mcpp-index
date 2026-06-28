# 新增 Eigen 收录(compat 源码/header-only)+ GitCode CN 镜像方案

**日期**: 2026-06-28
**本仓**: `mcpp-community/mcpp-index`(github 别名 `mcpplibs/mcpp-index`)
**参考**: PR #48(cJSON compat + nlohmann.json module + per-pkg CI)
**目标**:
1. 收录 [`libeigen/eigen`](https://gitlab.com/libeigen/eigen) 最新版 **5.0.1** —— header-only C++ 线性代数库,
   **全兼容(compat)** 形态,用户 `#include <Eigen/Dense>` 开箱即用。文件名 `pkgs/c/compat.eigen.lua`。
2. 补 **GitCode CN 镜像** `mcpp-res/eigen`(`gitcode.com/mcpp-res/eigen/...`),用本仓 `tools/gtc` 推送。
3. 评估 Eigen 是否有可走 mcpp **feature 机制** 的"类 feature"可选项(见 §3 结论:当前不适用,已说明原因)。
4. 在 `tests/examples/eigen/` 放最小工程,CI 选跑(detect → `eigen` matrix job)。

---

## 1. 最新版本与上游布局(关键前置)

- 最新 tag:`git ls-remote --tags` 显示 **5.0.1**(>3.4.x,Eigen 已跨大版本到 5.x;另有 5.0.0 / 3.4.1)。收录 `5.0.1`。
- 上游托管在 **GitLab**(非 GitHub):
  GLOBAL = `https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz`(归档 sha256 已实测两次稳定:`e9c326dc…`)。
- tarball 单层 wrap `eigen-5.0.1/`,glob `*` 吸收。根目录含:
  - `Eigen/` —— **稳定模块**(Dense / Core / LU / QR / SVD / Sparse / Geometry …)
  - `unsupported/Eigen/` —— **实验模块**(CXX11/Tensor、AutoDiff、Splines、MatrixFunctions、FFT …)
  - `blas/` `lapack/` —— Eigen 自带的 BLAS/LAPACK 实现(含 12 个 **Fortran `.f`**,需 Fortran 编译器)
  - 许可:主体 **MPL-2.0**(另有少量 Apache/BSD/MINPACK 文件)
- **无 `.cppm`**:Eigen 5.0.1 仍是纯 header,未提供 C++ module 单元 → 走 compat header-only 形态(非 nlohmann 那种 module wrapper)。

## 2. descriptor 形态(header-only,参照 compat.opengl/khrplatform)

Eigen 无可编译源(纯模板头),故:
- `include_dirs = {"*"}` 暴露 tarball 根 —— 即上游推荐放入 include path 的目录;`#include <Eigen/...>` 与
  `#include <unsupported/Eigen/...>` 均可解析。
- 用一个 trivial anchor TU(`mcpp_generated/eigen_anchor.c`)给 mcpp 一个可构建的 `lib` 目标(同 opengl/khrplatform)。
- `language=c++23`、`c_standard=c11`(anchor 是 C)、`deps={}`。

## 3. feature 机制评估 —— 当前不适用(已记录原因)

用户要求"如果 Eigen 有类似 feature 的东西,可走 mcpp feature 机制"。结论:**当前(mcpp 0.0.68)不适用**,原因经源码核实:

- mcpp 包描述符的 `features` 表 **只能门控 `sources`**(feature 贡献额外源码 glob,默认排除、请求时编入 ——
  见 `compat.cjson` 的 `utils`、`compat.gtest` 的 `main`;源码 `manifest.cppm` 中 feature 子字段仅识别 `sources`,
  其余被 skip)。
- Eigen 是 header-only,**没有可门控的可选源码**。其天然的"可选轴"是 `unsupported/` 实验模块,但它与 `Eigen/`
  **同处 tarball 根** —— 任何暴露稳定核(`*`)的 include path 都不可避免地一并暴露 `unsupported/`(已实测:
  `<unsupported/Eigen/MatrixFunctions>` / `<AutoDiff>` 直接可编)。**既无源可门控,也无法用 sources-only 的
  feature 把头藏起来**。
- 其它 Eigen 开关(`EIGEN_MPL2_ONLY`、`EIGEN_USE_BLAS/LAPACKE`…)是编译 **define**,feature 表同样不能携带。
- `blas/` 是唯一可门控的真实源,但需 Fortran(`.f`)+ 独立 lib 目标,feature 仅能往既有目标 *追加* 源 → 不匹配,过重。

→ 故本期 **暴露完整头集(core + unsupported)、不加 feature**,并在 descriptor 注释中完整记录该分析。
若 mcpp 未来允许 feature 携带 define/cflags,`mpl2only`(→ `-DEIGEN_MPL2_ONLY`)是干净的接入点。

## 4. CN 镜像(gtc)

repo 名 = 包名去 `compat.` 前缀 = `eigen`:
```
gtc repo create mcpp-res/eigen
gtc repo push   mcpp-res/eigen <init>          # 新仓需先有 main 分支才能发 release
gtc release publish mcpp-res/eigen --tag 5.0.1 --target main --asset eigen-5.0.1.tar.gz
```
上传的就是 GLOBAL 同一个 tarball → CN/GLOBAL **byte-identical**(实测 sha 一致 + CN http 200)。
CN url:`https://gitcode.com/mcpp-res/eigen/releases/download/5.0.1/eigen-5.0.1.tar.gz`。

## 5. 最小工程 + CI

- `tests/examples/eigen/{mcpp.toml, src/main.cpp}` —— `#include <Eigen/Dense>`,2x2 线代往返断言
  (`A*x`、determinant、dot、QR solve)。纯文本 include,不混 `import std;`。
- `validate.yml` 的 detect 把 `compat.eigen.lua` → `eigen` → 命中 `tests/examples/eigen` → `smoke-examples (eigen)` 单跑。
- `mirror-cn-reachable` 覆盖新 CN url。

## 6. 落地记录(2026-06-28)

- CN 镜像:`mcpp-res/eigen@5.0.1` 已建 + 发布,CN 与 GLOBAL byte-identical(sha `e9c326dc…`),http 200。
- 本地实测(mcpp **0.0.68**,与 CI 同版本,`MCPP_INDEX_MIRROR=GLOBAL`):
  `tests/run_example.sh eigen` → `eigen ok=1 y=[3 7] det=-2 dot=5`,`OK: eigen`。
- `unsupported/` 可达性单独实测:`g++ -std=c++23 -I<root>` 编 `<Eigen/Dense> + <unsupported/Eigen/MatrixFunctions> +
  <AutoDiff>` → rc=0。
- 全量 lint 本地模拟通过(语法 / 必填字段 / 无前导 v / mirror url 检查)。
- **坑**:compat 包目录按 **完整包名首字母** 归类 —— `compat.eigen` → `pkgs/c/`(不是短名 `eigen` 的 `pkgs/e/`),
  否则本地 path index 扫不到(`dependency 'compat.eigen': not found in local index`)。
