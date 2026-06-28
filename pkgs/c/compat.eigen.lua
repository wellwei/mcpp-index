-- Form B inline descriptor for Eigen — a C++ template library for linear
-- algebra (matrices, vectors, numerical solvers, related algorithms). The
-- Eigen *core* is HEADER-ONLY: there is nothing to compile for normal use, so
-- the package exposes the source tree's root on the include path
-- (`#include <Eigen/Dense>` etc.) and carries a tiny anchor translation unit
-- so mcpp always has a buildable `lib` target (same shape as compat.opengl /
-- compat.khrplatform). The optional `blas` feature additionally compiles
-- Eigen's reference BLAS into that lib (see below).
--
-- `include_dirs = {"*"}` points at the tarball root (`eigen-<ver>/`), which is
-- exactly the directory upstream tells you to put on the include path. That
-- makes BOTH the stable modules under `Eigen/` and the experimental modules
-- under `unsupported/Eigen/` (Tensor, AutoDiff, Splines, MatrixFunctions, …)
-- resolvable out of the box.
--
-- Feature: `blas` — Eigen's reference BLAS implementation.
--   Eigen ships a full BLAS library under `blas/` (the `eigen_blas` target in
--   upstream CMake). Despite the historical name, it builds from pure C++
--   (`blas/*.cpp`) + f2c-translated C (`blas/f2c/*.c`) — NO Fortran compiler
--   is needed (the only `.f` files live under `blas/testing/`, the test
--   suite, and are not part of the library). So it fits mcpp's sources-only
--   feature gate cleanly, exactly like compat.cjson's `utils`: excluded by
--   default, and compiled into the `eigen` lib when the dependency requests
--   `features = ["blas"]`. The result exposes the standard BLAS symbols
--   (sgemm_/dgemm_/ddot_/… , Fortran ABI) for code that wants to link a BLAS.
--   Common.h pulls Eigen via a path RELATIVE to blas/ (`../Eigen/Core`), so
--   the sources must compile in place — they do, since `*/blas/*.cpp` keeps
--   them under the unpacked tree. Verified locally on mcpp 0.0.68.
--
-- What is NOT a feature here (and why):
--   * `unsupported/` modules are header-only and live BESIDE `Eigen/` under
--     the same tarball root, so the core include path (`*`) already exposes
--     them; a sources-only gate cannot hide headers, so there is nothing to
--     gate — they are simply available.
--   * Eigen's compile-define knobs (EIGEN_MPL2_ONLY, EIGEN_USE_BLAS/LAPACKE,
--     …) are preprocessor defines; the feature table carries only `sources`
--     on mcpp 0.0.68, so they cannot be feature-gated yet. If mcpp later lets
--     a feature contribute defines/cflags, `mpl2only` (-> -DEIGEN_MPL2_ONLY)
--     would be the clean fit.
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
        -- Optional: compile Eigen's reference BLAS (`eigen_blas`) into the lib.
        -- C++ + f2c-C only, no Fortran. Off by default; pulled in with
        -- `features = ["blas"]`. blas/ has exactly the 5 library .cpp and
        -- blas/f2c/ exactly the 18 library .c (the upstream eigen_blas source
        -- set); the `*.cpp`/`*.c` globs match them and nothing else.
        features     = {
            ["blas"] = {
                sources = {
                    "*/blas/*.cpp",
                    "*/blas/f2c/*.c",
                },
            },
        },
        deps         = { },
    },
}
