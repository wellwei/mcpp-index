-- Form B inline descriptor for Eigen — a C++ template library for linear
-- algebra (matrices, vectors, numerical solvers, related algorithms). Eigen
-- is HEADER-ONLY: there is nothing to compile, so the package just exposes
-- the source tree's root on the include path (`#include <Eigen/Dense>` etc.)
-- and carries a tiny anchor translation unit so mcpp still has a buildable
-- `lib` target (same shape as compat.opengl / compat.khrplatform).
--
-- `include_dirs = {"*"}` points at the tarball root (`eigen-<ver>/`), which is
-- exactly the directory upstream tells you to put on the include path. That
-- makes BOTH the stable modules under `Eigen/` and the experimental modules
-- under `unsupported/Eigen/` (Tensor, AutoDiff, Splines, MatrixFunctions, …)
-- resolvable — see the note on features below for why `unsupported` is not a
-- separate opt-in here.
--
-- On the `feature` mechanism (asked for, deliberately omitted — analysis):
--   mcpp's package-descriptor `features` table gates **sources only** (a
--   feature contributes extra source globs that are excluded by default and
--   compiled in when the feature is requested — see compat.cjson's `utils`
--   and compat.gtest's `main`). Eigen has no such optional *source*: it is
--   header-only. Its natural opt-in axis would be the `unsupported/` modules,
--   but those are headers that live BESIDE `Eigen/` under the same tarball
--   root, so any include path that exposes the stable core (`*`) inevitably
--   exposes `unsupported/` too — there is no source to gate and no way to
--   hide the headers behind a feature with the current (sources-only) gate.
--   Other Eigen knobs (EIGEN_MPL2_ONLY, EIGEN_USE_BLAS/LAPACKE, …) are
--   compile *defines*, which the feature table also cannot carry on mcpp
--   0.0.68. So a feature here would be cosmetic/misleading; we expose the
--   full header set instead and document it. If mcpp later lets a feature
--   contribute defines/cflags, an `mpl2only` (-> -DEIGEN_MPL2_ONLY) feature
--   would be the clean fit.
--
-- All `mcpp` paths are GLOBS relative to the verdir; the leading `*` absorbs
-- the GitLab archive's `eigen-<tag>/` wrap layer.
package = {
    spec        = "1",
    namespace   = "compat",
    name        = "compat.eigen",
    description = "C++ template library for linear algebra (header-only)",
    licenses    = {"MPL-2.0"},
    repo        = "https://gitlab.com/libeigen/eigen",
    type        = "package",

    xpm = {
        linux = {
            ["5.0.1"] = {
                url    = {
                    GLOBAL = "https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz",
                    CN     = "https://gitcode.com/mcpp-res/eigen/releases/download/5.0.1/eigen-5.0.1.tar.gz",
                },
                sha256 = "e9c326dc8c05cd1e044c71f30f1b2e34a6161a3b6ecf445d56b53ff1669e3dec",
            },
        },
        macosx = {
            ["5.0.1"] = {
                url    = {
                    GLOBAL = "https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz",
                    CN     = "https://gitcode.com/mcpp-res/eigen/releases/download/5.0.1/eigen-5.0.1.tar.gz",
                },
                sha256 = "e9c326dc8c05cd1e044c71f30f1b2e34a6161a3b6ecf445d56b53ff1669e3dec",
            },
        },
        windows = {
            ["5.0.1"] = {
                url    = {
                    GLOBAL = "https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz",
                    CN     = "https://gitcode.com/mcpp-res/eigen/releases/download/5.0.1/eigen-5.0.1.tar.gz",
                },
                sha256 = "e9c326dc8c05cd1e044c71f30f1b2e34a6161a3b6ecf445d56b53ff1669e3dec",
            },
        },
    },

    mcpp = {
        language     = "c++23",
        import_std   = false,
        c_standard   = "c11",
        -- Tarball root: exposes `Eigen/` (stable) and `unsupported/Eigen/`
        -- (experimental) to consumers writing `#include <Eigen/...>`.
        include_dirs = { "*" },
        -- Header-only: a trivial anchor TU gives mcpp a buildable lib target.
        generated_files = {
            ["mcpp_generated/eigen_anchor.c"] = "int mcpp_compat_eigen_headers_anchor(void) { return 0; }\n",
        },
        sources      = { "mcpp_generated/eigen_anchor.c" },
        targets      = { ["eigen"] = { kind = "lib" } },
        deps         = { },
    },
}
