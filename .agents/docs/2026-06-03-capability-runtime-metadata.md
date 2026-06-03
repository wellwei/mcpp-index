# mcpp-index: Capability & Runtime Metadata (Long-term Design)

> Created: 2026-06-03 · Owner: sunrisepeak · Status: design (industrial / long-term)
> Repo: `mcpp-community/mcpp-index` (redirects to `mcpplibs/mcpp-index`)
> Master plan: `/home/speak/workspace/github/agentdocs/2026-06-03-mcpp-ecosystem-architecture-plan.md`
> Sibling sub-doc: `.agents/docs/2026-06-03-gl-runtime-packages-plan.md` (the GL runtime package
> boundary this design generalizes from).

This document specifies how the mcpp package registry models **dependency capabilities and runtime
requirements** as long-term, industrial metadata — not as one-off scripts or per-consumer pins. It
is written to outlive any single package (imgui, glfw) and to guide every native package that touches
a non-vendorable host resource (GPU driver, GLVND, display server).

---

## 1. The two-plane dependency model

mcpp dependencies split into two planes. The split is a hard rule, not a convenience.

### 1.1 Hermetic plane (vendored, reproducible)

- **Content:** source packages + toolchains.
- **Properties:** content-addressed, pinned by `sha256`, byte-reproducible via lockfile + index checksums.
- **Examples today:**
  - `compat.opengl` — Khronos OpenGL **headers** only (registry tarball, sha256-pinned). It is a
    header provider and must **not** become a host driver wrapper.
  - `compat.glfw` — GLFW built from upstream source (tag `3.4`, sha256-pinned), per-platform sources.
  - `imgui` — the module package, source tarball sha256-pinned.

The hermetic plane is where Cargo-style guarantees apply directly: SemVer resolution, lockfile,
index checksum verification. Anything here can and must be vendored and hashed.

### 1.2 Host plane (discovered, passed through, never vendored)

- **Content:** GPU drivers, GLVND/GLX dispatch, display server (X11/Wayland) — host singletons that
  are machine-specific and licensed/installed outside the package world.
- **Properties:** **discovered at install time** on the host and **passed through** via binding
  (symlink farm + RUNPATH), never copied into the registry, never sha256-pinned as redistributable.
- **Reproducibility model:** **intent-level**, not byte-level. The manifest declares *what capability
  is needed* (e.g. `opengl.glx.driver`); `mcpp doctor`/`why` records *what host actually satisfied it*.
  Two machines with different NVIDIA driver builds are both "reproducible" w.r.t. the declared intent.

**Iron rule:** GPU drivers and host singletons live in the host plane forever. Vendoring a vendor
driver tarball as if it were a normal redistributable package is prohibited.

The worked example of the host plane is `compat.glx-runtime` (next section).

---

## 2. Capability / runtime metadata schema (as it exists today)

Native packages declare runtime needs under `mcpp.runtime` (and, on Linux, under
`mcpp.linux.runtime`). The schema in production today is:

```lua
runtime = {
    library_dirs = { ... },   -- dirs to add to the consumer's RUNPATH/link runtime dirs
    dlopen_libs  = { ... },   -- soname strings the package will dlopen at runtime
    capabilities = { ... },   -- abstract host capabilities required (provider-resolved)
}
```

These propagate along the dependency graph: a consumer of a package inherits that package's
`runtime` requirements (and so does a consumer of a consumer). imgui declares **none** of this — it
inherits everything transitively through `compat.glfw` / `compat.opengl`.

### 2.1 Worked example: `compat.glx-runtime` (the host-plane adapter)

File: `pkgs/c/compat.glx-runtime.lua`. Verified contents:

- It is a real package (`type = "package"`, version `"2026.06.03"`) but its tarball is just a Khronos
  README pinned for provenance; the substance is its `install()` script.
- `install()` calls `link_runtime_libs()`, which **symlinks the HOST's GLVND/GL/GLX libraries** out of
  host library dirs into its install dir `mcpp_generated/glx_runtime/lib`. The discovered patterns are:
  `libGL.so*`, `libGLX.so*`, `libGLX_*.so*` (covers `libGLX_nvidia*`), `libGLdispatch.so*`,
  `libOpenGL.so*`, `libEGL.so*`, `libEGL_*.so*`, `libGLES*.so*`, `libnvidia*.so*`, `libglapi.so*`,
  `libdrm*.so*`, `libexpat.so*`, `libxshmfence.so*`, `libbsd.so*`, `libmd.so*`.
- Host search dirs: `$MCPP_HOST_GL_LIBRARY_PATH` (override) then `/lib/x86_64-linux-gnu`,
  `/usr/lib/x86_64-linux-gnu`, `/lib64`, `/usr/lib64`, `/usr/lib`.
- It **fails the install** if `libGLX.so.0` or `libGL.so.1` are not found on the host — i.e. the host
  plane is validated, not silently skipped.
- It declares:
  ```lua
  runtime = {
      library_dirs = { "mcpp_generated/glx_runtime/lib" },
      dlopen_libs  = { "libGLX.so.0", "libGL.so.1", "libGL.so" },
      capabilities = { "x11.display", "opengl.glx.driver" },
  }
  ```
- It depends on `compat.xext = "1.3.7"`.

This is exactly the "host plane" passthrough: drivers are host-specific, discovered, symlinked, and
exposed via `library_dirs` so the consumer's RUNPATH can find them — never vendored.

### 2.2 Dependency wiring: glfw -> glx-runtime (Linux)

File: `pkgs/c/compat.glfw.lua`. Verified: the Linux block declares BOTH the runtime capabilities AND
the dep on the host-plane package, so any consumer of glfw transitively pulls glx-runtime:

```lua
linux = {
    cflags = { "-D_DEFAULT_SOURCE", "-D_GLFW_X11" },
    runtime = {
        dlopen_libs  = { "libGLX.so.0", "libGL.so.1", "libGL.so" },
        capabilities = { "x11.display", "opengl.glx.driver" },
    },
    deps = {
        ["compat.glx-runtime"] = "2026.06.03",
        ["compat.x11"]       = "1.8.13",
        ["compat.xcursor"]   = "1.2.3",
        ["compat.xext"]      = "1.3.7",
        ["compat.xfixes"]    = "6.0.2",
        ["compat.xi"]        = "1.8.3",
        ["compat.xinerama"]  = "1.1.6",
        ["compat.xorgproto"] = "2025.1",
        ["compat.xrandr"]    = "1.5.5",
        ["compat.xrender"]   = "0.9.12",
    },
}
```

`compat.glfw` also has a top-level `deps = { ["compat.opengl"] = "2026.05.31" }` (headers, hermetic
plane). `compat.opengl` is header-only and depends only on `compat.khrplatform` — it does **not**
declare any `runtime` block, which is correct (headers carry no runtime host requirement).

**Conclusion (verified):** the wiring `glfw -> glx-runtime` is present and correct on Linux. The
capability set and dep version (`2026.06.03`) match the glx-runtime package's own version. The
remaining gaps to a no-shim window run live in the **mcpp core** (RUNPATH must include the dependency
`runtime.library_dirs`) and in stale consumer lockfiles — not in this metadata. See master plan R2/R3.

---

## 3. Proposed additions (long-term)

These are not yet in the schema. They are the declarative spine that lets mcpp stay zero-config while
remaining correct across ABIs and platforms.

### 3.1 `abi` capability declared by native packages

**Gap (verified today):** there is **no `abi` field** on `compat.glfw`, `compat.opengl`, or
`compat.glx-runtime`. A grep for `abi` matches only the `capabilities` lines — confirming the field is
absent. Nothing in the index tells the resolver that these packages link against glibc.

**Why it matters:** mcpp's bootstrap default toolchain on a fresh host is `gcc-musl-static`. musl
cannot link the glibc world (X11/GL), which is the master-plan **R1** failure (`arc4random_buf`
implicit decl while linking `libXdmcp`). Today the only workarounds are pinning a toolchain (which we
explicitly want to avoid) or setting an env-level default.

**Proposal:** native packages declare an ABI capability, e.g.

```lua
mcpp = {
    abi = "glibc",   -- one of: "glibc" | "musl" | "msvc"
    -- ...
}
```

The resolver unions ABI requirements across the dependency graph and **auto-selects an
ABI-compatible toolchain** (here: a glibc gcc). This removes the musl-static default trap **without
any consumer pinning** — the package states its truth (glibc) and the resolver does the rest. The
master plan calls this "abi drives toolchain selection."

### 3.2 Capability -> provider resolution

Capabilities like `opengl.glx.driver` and `x11.display` are abstract today; `compat.glx-runtime`
happens to be the thing that satisfies them on Linux, wired by hand via `deps`. Long term, make this a
**registry-level capability -> provider map per platform**, e.g.:

| capability          | linux provider        | macosx provider  | windows provider |
|---------------------|-----------------------|------------------|------------------|
| `opengl.glx.driver` | `glvnd-linux` (≈ glx-runtime) | `opengl-macos` | `opengl-win` |
| `x11.display`       | `x11-runtime`         | (n/a)            | (n/a)            |

A package that declares `capabilities = { "opengl.glx.driver" }` would then have the correct provider
package injected automatically for the active platform, instead of every windowing package
hand-listing `compat.glx-runtime` in its Linux `deps`. This keeps consumers and even mid-tier packages
free of platform-specific provider wiring.

### 3.3 Declarative-first, with an imperative escape hatch

Both additions are **declarative-first**: packages state intent (`abi`, `capabilities`), the resolver
computes the plan. But we deliberately keep the **imperative escape hatch** — the `install()` Lua
scripts (as `compat.glx-runtime` already uses) remain available for the long tail (host discovery,
symlink farms, anything not expressible declaratively). This mirrors Cargo's `build.rs` lesson: a pure
declarative model eventually hits a case it can't express, so an escape hatch must always exist.

---

## 4. Immutable-version policy

**Policy:** a published version is immutable. Once `name@version` is in the index with a `sha256`, that
pairing never changes. Fixes and content changes ship as a **new version**, never as an in-place
overwrite. This is the crates.io lesson — overwriting a published version silently breaks every
lockfile that already trusts the old checksum.

**The imgui 0.0.1 sha bump (PR #30) is a one-time exception.** The `imgui-m` 0.0.1 git tag was *moved*
onto the merged backend-abstraction + cross-platform commit, so the GitHub source tarball checksum
changed:

- old: `b87188bd2ca7d8010a695d5ebfccd76eb3e28b3e002885207493225057f5e190`
- new: `168d1f9a2dfc3823d671385654823f7eba25f146d029ceeacfb19a84617af4a0`

PR #30 updates `pkgs/i/imgui.lua` (linux/macosx/windows) so `imgui = "0.0.1"` resolves against the
re-released tarball. This is acceptable **only** as a transitional fix while 0.0.1 is the first/early
release. **Future releases must bump the version** (0.0.2, …) rather than re-tagging and overwriting a
published sha. The master plan records the same caveat (§2.4 / §4.3 / §8).

---

## 5. Status / cross-references

- **PR #30** (`imgui: update 0.0.1 sha256 for re-released tarball`): OPEN, mergeable, base `main`,
  head `imgui-0.0.1-rerelease`, author Sunrisepeak — https://github.com/mcpplibs/mcpp-index/pull/30
- Verified metadata files:
  - `pkgs/c/compat.glx-runtime.lua` — host-plane GL passthrough (symlink farm + runtime block).
  - `pkgs/c/compat.glfw.lua` — Linux `deps` on `compat.glx-runtime` + matching `runtime` capabilities.
  - `pkgs/c/compat.opengl.lua` — header-only, no runtime block (correct).
  - `pkgs/i/imgui.lua` — Form A descriptor, sha being updated by PR #30.
- **abi gap:** no `abi` field on any compat package today (verified). Section 3.1 is the proposed fix.
- Sibling: `.agents/docs/2026-06-03-gl-runtime-packages-plan.md` (package boundary checkpoint, PR #27).
- Master plan: `/home/speak/workspace/github/agentdocs/2026-06-03-mcpp-ecosystem-architecture-plan.md`.
