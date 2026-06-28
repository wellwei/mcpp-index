// Eigen is header-only; the compat package puts the source tree root on the
// include path so `#include <Eigen/...>` just works. Plain textual includes
// here (Eigen is not a module), so we do NOT mix in `import std;`.
//
// This example also opts into the `blas` feature (see mcpp.toml), which
// compiles Eigen's reference BLAS into the lib — so we additionally link and
// call dgemm_ (Fortran BLAS ABI) to prove the feature-gated build works.
#include <Eigen/Dense>
#include <cstdio>
#include <cmath>

// Standard Fortran BLAS ABI, provided by Eigen's eigen_blas (feature "blas").
extern "C" void dgemm_(const char* transa, const char* transb,
                       const int* m, const int* n, const int* k,
                       const double* alpha, const double* a, const int* lda,
                       const double* b, const int* ldb,
                       const double* beta, double* c, const int* ldc);

int main() {
    // --- core Eigen (header-only) ---
    // A * x for a 2x2 system: [[1,2],[3,4]] * [1,1]^T = [3,7]^T
    Eigen::Matrix2d A;
    A << 1, 2,
         3, 4;
    Eigen::Vector2d x(1.0, 1.0);
    Eigen::Vector2d y = A * x;
    double det = A.determinant();                       // -2
    Eigen::Vector2d z = A.colPivHouseholderQr().solve(y);  // back to [1,1]

    bool core_ok = y(0) == 3.0 && y(1) == 7.0 && det == -2.0
                   && std::abs(z(0) - 1.0) < 1e-9 && std::abs(z(1) - 1.0) < 1e-9;

    // --- BLAS feature: C = A * B via dgemm_ (column-major) ---
    // A = [[1,2],[3,4]] col-major = {1,3,2,4}; B = identity. Expect C == A.
    const double a[4] = {1, 3, 2, 4};
    const double b[4] = {1, 0, 0, 1};
    double c[4]       = {0, 0, 0, 0};
    const int n = 2;
    const double one = 1.0, zero = 0.0;
    dgemm_("N", "N", &n, &n, &n, &one, a, &n, b, &n, &zero, c, &n);
    bool blas_ok = c[0] == 1 && c[1] == 3 && c[2] == 2 && c[3] == 4;

    bool ok = core_ok && blas_ok;
    std::printf("eigen ok=%d  core=%d  blas(dgemm)=%d  y=[%g %g]  C=[%g %g %g %g]\n",
                ok, core_ok, blas_ok, y(0), y(1), c[0], c[1], c[2], c[3]);
    return ok ? 0 : 1;
}
