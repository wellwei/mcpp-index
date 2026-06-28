// Eigen is header-only; the compat package puts the source tree root on the
// include path so `#include <Eigen/...>` just works. Plain textual includes
// here (Eigen is not a module), so we do NOT mix in `import std;`.
#include <Eigen/Dense>
#include <cstdio>
#include <cmath>

int main() {
    // A * x for a 2x2 system: [[1,2],[3,4]] * [1,1]^T = [3,7]^T
    Eigen::Matrix2d A;
    A << 1, 2,
         3, 4;
    Eigen::Vector2d x(1.0, 1.0);
    Eigen::Vector2d y = A * x;

    double det = A.determinant();          // 1*4 - 2*3 = -2
    double dot = x.dot(Eigen::Vector2d(2.0, 3.0));  // 1*2 + 1*3 = 5

    // Solve A z = y, expect z back to [1,1].
    Eigen::Vector2d z = A.colPivHouseholderQr().solve(y);

    bool ok = y(0) == 3.0 && y(1) == 7.0
              && det == -2.0 && dot == 5.0
              && std::abs(z(0) - 1.0) < 1e-9 && std::abs(z(1) - 1.0) < 1e-9;

    std::printf("eigen ok=%d  y=[%g %g]  det=%g  dot=%g\n",
                ok, y(0), y(1), det, dot);
    return ok ? 0 : 1;
}
