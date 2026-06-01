#!/usr/bin/env bash
# Smoke-test archive/compression compat packages through this checkout as a
# local mcpp path index.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCPP_BIN="${MCPP:-}"
if [[ -z "$MCPP_BIN" ]]; then
    MCPP_BIN="$(command -v mcpp || true)"
fi
if [[ -z "$MCPP_BIN" || ! -x "$MCPP_BIN" ]]; then
    echo "FATAL: set MCPP=/path/to/mcpp or put mcpp on PATH" >&2
    exit 1
fi

TMP="$(mktemp -d)"
if [[ "${MCPP_INDEX_KEEP_SMOKE_TMP:-0}" == "1" ]]; then
    echo "KEEP: $TMP"
else
    trap 'rm -rf "$TMP"' EXIT
fi
SMOKE_CACHE_DIR="${MCPP_INDEX_SMOKE_CACHE_DIR:-}"
SMOKE_XPKGS_DIR="${MCPP_INDEX_SMOKE_XPKGS_DIR:-}"

if [[ -n "${MCPP_INDEX_SMOKE_MCPP_HOME:-}" ]]; then
    export MCPP_HOME="$MCPP_INDEX_SMOKE_MCPP_HOME"
else
    export MCPP_HOME="$TMP/mcpp-home"
fi
mkdir -p "$MCPP_HOME"

USER_MCPP="${HOME}/.mcpp"
mkdir -p "$MCPP_HOME/registry/data/xpkgs"
link_xpkgs() {
    local src="$1"
    [[ -d "$src" ]] || return 0
    find "$src" -mindepth 1 -maxdepth 1 -type d | while read -r pkg; do
        [[ "$(basename "$pkg")" == compat-x-* ]] && continue
        ln -s "$pkg" "$MCPP_HOME/registry/data/xpkgs/$(basename "$pkg")" 2>/dev/null || true
    done
}
link_xpkgs "$SMOKE_XPKGS_DIR"
link_xpkgs "$USER_MCPP/registry/data/xpkgs"
if [[ -d "$USER_MCPP/registry/data/xim-pkgindex" ]]; then
    mkdir -p "$MCPP_HOME/registry/data/xim-pkgindex"
    cp -a "$USER_MCPP/registry/data/xim-pkgindex/." "$MCPP_HOME/registry/data/xim-pkgindex/" 2>/dev/null || true
    rm -f "$MCPP_HOME/registry/data/xim-pkgindex/.xlings-index-cache.json"
fi
if [[ -d "$USER_MCPP/registry/bin" ]]; then
    mkdir -p "$MCPP_HOME/registry"
    ln -s "$USER_MCPP/registry/bin" "$MCPP_HOME/registry/bin" 2>/dev/null || true
fi
if [[ -f "$USER_MCPP/config.toml" ]]; then
    cp -f "$USER_MCPP/config.toml" "$MCPP_HOME/config.toml" 2>/dev/null || true
fi

mkdir -p "$TMP/compat-archive-smoke/src"
cd "$TMP/compat-archive-smoke"
cat > mcpp.toml <<EOF
[package]
name = "compat-archive-smoke"
version = "0.1.0"

[toolchain]
default = "gcc@16.1.0"

[indices]
compat = { path = "$ROOT" }

[dependencies.compat]
libarchive = "3.8.7"

[targets.compat-archive-smoke]
kind = "bin"
main = "src/main.cpp"
EOF

if [[ -n "$SMOKE_CACHE_DIR" && -d "$SMOKE_CACHE_DIR" ]]; then
    mkdir -p .mcpp/.xlings/data/runtimedir
    find "$SMOKE_CACHE_DIR" -maxdepth 1 -type f \
        \( -name '*.tar.gz' -o -name '*.tar.xz' -o -name '*.zip' \) \
        -exec cp -f {} .mcpp/.xlings/data/runtimedir/ \;
fi

cat > src/main.cpp <<'EOF'
#include <archive.h>
#include <archive_entry.h>
#include <bzlib.h>
#include <lz4.h>
#include <lzma.h>
#include <zlib.h>
#include <zstd.h>

int main() {
    archive* writer = archive_write_new();
    if (!writer) return 1;
    archive_write_free(writer);

    archive_entry* entry = archive_entry_new();
    if (!entry) return 2;
    archive_entry_free(entry);

    if (!archive_version_string()) return 3;
    if (!zlibVersion()) return 4;
    if (!BZ2_bzlibVersion()) return 5;
    if (LZ4_versionNumber() <= 0) return 6;
    if (ZSTD_versionNumber() == 0) return 7;
    if (lzma_version_number() == 0) return 8;
    return 0;
}
EOF

"$MCPP_BIN" build
"$MCPP_BIN" run

mkdir -p "$TMP/compat-compression-standalone-smoke/src"
cd "$TMP/compat-compression-standalone-smoke"
cat > mcpp.toml <<EOF
[package]
name = "compat-compression-standalone-smoke"
version = "0.1.0"

[toolchain]
default = "gcc@16.1.0"

[indices]
compat = { path = "$ROOT" }

[dependencies.compat]
zlib = "1.3.2"
bzip2 = "1.0.8"
lz4 = "1.10.0"
xz = "5.8.3"
zstd = "1.5.7"

[targets.compat-compression-standalone-smoke]
kind = "bin"
main = "src/main.cpp"
EOF

if [[ -n "$SMOKE_CACHE_DIR" && -d "$SMOKE_CACHE_DIR" ]]; then
    mkdir -p .mcpp/.xlings/data/runtimedir
    find "$SMOKE_CACHE_DIR" -maxdepth 1 -type f \
        \( -name '*.tar.gz' -o -name '*.tar.xz' -o -name '*.zip' \) \
        -exec cp -f {} .mcpp/.xlings/data/runtimedir/ \;
fi

cat > src/main.cpp <<'EOF'
#include <bzlib.h>
#include <lz4.h>
#include <lzma.h>
#include <zlib.h>
#include <zstd.h>

#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

static bool same_bytes(const void* actual, size_t actual_size,
                       const void* expected, size_t expected_size) {
    return actual_size == expected_size &&
           std::memcmp(actual, expected, expected_size) == 0;
}

int main() {
    const uint8_t input[] = "mcpp compat compression smoke";
    const size_t input_size = sizeof(input) - 1;

    uint8_t zlib_compressed[256] = {};
    uLongf zlib_compressed_size = sizeof(zlib_compressed);
    if (compress2(zlib_compressed, &zlib_compressed_size, input,
                  static_cast<uLong>(input_size), Z_BEST_SPEED) != Z_OK) {
        return 1;
    }
    uint8_t zlib_output[sizeof(input)] = {};
    uLongf zlib_output_size = input_size;
    if (uncompress(zlib_output, &zlib_output_size, zlib_compressed,
                   zlib_compressed_size) != Z_OK ||
        !same_bytes(zlib_output, zlib_output_size, input, input_size)) {
        return 2;
    }

    char bzip2_compressed[256] = {};
    unsigned int bzip2_compressed_size = sizeof(bzip2_compressed);
    if (BZ2_bzBuffToBuffCompress(
            bzip2_compressed, &bzip2_compressed_size,
            const_cast<char*>(reinterpret_cast<const char*>(input)),
            static_cast<unsigned int>(input_size), 1, 0, 30) != BZ_OK) {
        return 3;
    }
    char bzip2_output[sizeof(input)] = {};
    unsigned int bzip2_output_size = input_size;
    if (BZ2_bzBuffToBuffDecompress(bzip2_output, &bzip2_output_size,
                                   bzip2_compressed, bzip2_compressed_size,
                                   0, 0) != BZ_OK ||
        !same_bytes(bzip2_output, bzip2_output_size, input, input_size)) {
        return 4;
    }

    char lz4_compressed[256] = {};
    const int lz4_compressed_size =
        LZ4_compress_default(reinterpret_cast<const char*>(input),
                             lz4_compressed, static_cast<int>(input_size),
                             sizeof(lz4_compressed));
    if (lz4_compressed_size <= 0) {
        return 5;
    }
    char lz4_output[sizeof(input)] = {};
    const int lz4_output_size =
        LZ4_decompress_safe(lz4_compressed, lz4_output, lz4_compressed_size,
                            sizeof(lz4_output));
    if (lz4_output_size < 0 ||
        !same_bytes(lz4_output, static_cast<size_t>(lz4_output_size), input,
                    input_size)) {
        return 6;
    }

    std::vector<char> zstd_compressed(ZSTD_compressBound(input_size));
    const size_t zstd_compressed_size =
        ZSTD_compress(zstd_compressed.data(), zstd_compressed.size(), input,
                      input_size, 1);
    if (ZSTD_isError(zstd_compressed_size)) {
        return 7;
    }
    std::vector<char> zstd_output(input_size);
    const size_t zstd_output_size =
        ZSTD_decompress(zstd_output.data(), zstd_output.size(),
                        zstd_compressed.data(), zstd_compressed_size);
    if (ZSTD_isError(zstd_output_size) ||
        !same_bytes(zstd_output.data(), zstd_output_size, input, input_size)) {
        return 8;
    }

    std::vector<uint8_t> xz_compressed(lzma_stream_buffer_bound(input_size));
    size_t xz_compressed_pos = 0;
    if (lzma_easy_buffer_encode(0, LZMA_CHECK_CRC64, nullptr, input,
                                input_size, xz_compressed.data(),
                                &xz_compressed_pos,
                                xz_compressed.size()) != LZMA_OK) {
        return 9;
    }
    uint64_t xz_memlimit = (std::numeric_limits<uint64_t>::max)();
    size_t xz_input_pos = 0;
    size_t xz_output_pos = 0;
    std::vector<uint8_t> xz_output(input_size);
    if (lzma_stream_buffer_decode(&xz_memlimit, 0, nullptr,
                                  xz_compressed.data(), &xz_input_pos,
                                  xz_compressed_pos, xz_output.data(),
                                  &xz_output_pos, xz_output.size()) !=
            LZMA_OK ||
        !same_bytes(xz_output.data(), xz_output_pos, input, input_size)) {
        return 10;
    }

    return 0;
}
EOF

"$MCPP_BIN" build
"$MCPP_BIN" run
echo "OK"
