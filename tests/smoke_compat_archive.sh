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
trap 'rm -rf "$TMP"' EXIT
SMOKE_CACHE_DIR="${MCPP_INDEX_SMOKE_CACHE_DIR:-}"
SMOKE_XPKGS_DIR="${MCPP_INDEX_SMOKE_XPKGS_DIR:-}"

export MCPP_HOME="$TMP/mcpp-home"
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
echo "OK"
