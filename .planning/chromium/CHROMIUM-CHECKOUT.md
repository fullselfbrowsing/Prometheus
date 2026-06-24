# Chromium Checkout Handoff

**Created:** 2026-06-17
**Updated:** 2026-06-24
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Phase 12 complete. Chromium source checkout, Xcode/Metal toolchain, GN generation, baseline build, unmodified launch, and artifact isolation all verified. Prometheus-specific Chromium patches may proceed.

## Baseline Identity

```text
Chromium revision: 0e8499df5172f55d0d29e2b92ef7e6a704529578
depot_tools revision: ea253a3e3ae7653cafd343be001dc5cbe69b3ad0
GN args: is_debug=false is_component_build=true symbol_level=0
Build gate: bash .planning/chromium/build-chromium-baseline.sh --no-op-ok
Launch gate: bash .planning/chromium/smoke-launch-unmodified.sh
Isolation gate: bash .planning/chromium/verify-artifact-isolation.sh
Future branch example: git new-branch prometheus/phase-13-branding
Patch export command includes: git format-patch
```

## Local Paths

| Item | Path |
|------|------|
| depot_tools | `.context/depot_tools` |
| Chromium gclient root | `.context/chromium` |
| Chromium source | `.context/chromium/src` |
| Build directory | `.context/chromium/src/out/Default` |
| Chromium binary | `.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium` |
| Falkon preservation bundle | `.context/falkon-preservation/falkon-prometheus-v1.bundle` |
| Falkon patch series | `.context/falkon-preservation/patches/` |

`.context/` is ignored by the root repository via both `.gitignore` (tracked) and the root checkout's `.git/info/exclude`, so the Chromium checkout, depot_tools installation, build artifacts, and launch evidence do not dirty root git status.

## Minimum Local Requirements

The following must be present and functional before any Phase 12 gate script passes:

- **100GB free disk buffer** (Chromium source ~30GB, depot_tools ~700MB, build artifacts ~30GB+)
- **macOS arm64** (scripts and binary are arm64; Intel is not validated)
- **Xcode** full installation at `/Applications/Xcode.app` (Command Line Tools alone are insufficient)
- **MacOSX.sdk** (bundled with Xcode; required by the Chromium toolchain)
- **Metal Toolchain** (install with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain`)
- **depot_tools** at `.context/depot_tools` (clone from `https://chromium.googlesource.com/chromium/tools/depot_tools.git`)
- **GN** binary at `.context/chromium/src/buildtools/mac/gn` (installed by Chromium hooks during `fetch`)
- **Ninja** / **autoninja** via depot_tools (autoninja wraps ninja with Siso remote execution support)
- **autoninja** on PATH via depot_tools
- **fetch --no-history chromium** was used for the initial checkout (not `gclient sync` from scratch); re-fetch is only needed if `.context/chromium/src` is missing entirely

Locked GN args for this baseline: `is_debug=false is_component_build=true symbol_level=0`

## Phase 12 Script Gates

Run these scripts in order. Each is fail-fast and exits nonzero with a concrete remediation message on failure.

```sh
bash .planning/chromium/check-chromium-env.sh
bash .planning/chromium/build-chromium-baseline.sh --no-op-ok
bash .planning/chromium/smoke-launch-unmodified.sh
bash .planning/chromium/verify-artifact-isolation.sh
```

- **check-chromium-env.sh**: Asserts depot_tools, Chromium checkout, pinned revision `0e8499df5172f55d0d29e2b92ef7e6a704529578`, GN args, built binary, Xcode, Metal toolchain, autoninja, and gclient validate. Never fetches or builds.
- **build-chromium-baseline.sh --no-op-ok**: Runs locked GN gen and autoninja. Accepts `--no-op-ok` (same behavior as no argument; both run GN + build). Writes `.context/chromium-build-baseline.status` and `.context/chromium-build-baseline.log`. Runs artifact isolation gate on success.
- **smoke-launch-unmodified.sh**: Launches the unmodified Chromium binary with an isolated profile and a `data:` smoke page. Checks process alive after 8s, quits cleanly via osascript, and writes `.context/chromium-launch.status` and `.context/chromium-launch.log`. Runs artifact isolation gate on success.
- **verify-artifact-isolation.sh**: Asserts `.gitignore` covers all Chromium artifact patterns, that `git check-ignore -v` confirms `.gitignore` (not only gitdir-local exclude) is the ignore source, that `git ls-files` returns nothing for artifact paths, and that `git status --short` is clean of forbidden Chromium paths.

## Completed

### Falkon retirement gate

- Verified the Falkon preservation bundle.
- Restored the bundle into a temporary clone and confirmed the restored HEAD matched `b0521c9d37e7545c680b78dfcc24f777a984091c`.
- Removed the active `falkon/` checkout from the workspace.
- Kept the bundle and 81 patch files in `.context/falkon-preservation/`.

### depot_tools

Installed local depot_tools:

```sh
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git .context/depot_tools
```

Recorded depot_tools revision at build time:

```text
ea253a3e3ae7653cafd343be001dc5cbe69b3ad0
```

### Chromium fetch

Ran the shallow Chromium fetch:

```sh
mkdir -p .context/chromium
cd .context/chromium
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" fetch --no-history chromium
```

Checkout completed and hooks ran successfully.

Recorded Chromium revision (pinned baseline):

```text
0e8499df5172f55d0d29e2b92ef7e6a704529578
```

Approximate local sizes after checkout:

```text
.context/chromium       30G
.context/depot_tools   698M
.context/falkon-preservation 41M
```

## Local Build Status

Full Xcode is installed:

```text
/Applications/Xcode.app
Xcode 26.5
Build version 17F42
```

The active developer directory is full Xcode:

```text
/Applications/Xcode.app/Contents/Developer
```

The original Xcode blocker was fixed by switching `xcode-select` to full Xcode and accepting the Xcode license from Terminal. `xcodebuild -runFirstLaunch` also installed first-launch components.

The Metal Toolchain blocker was fixed with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -runFirstLaunch
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain
```

Verification:

```text
xcodebuild -version -> Xcode 26.5 / Build version 17F42
xcrun metal -v -> Apple metal version 32023.883
```

GN generation succeeds:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
```

Result:

```text
Done. Made 31437 targets from 4783 files
```

## First Build Result

The first `chrome` build for the clean Chromium checkout completed successfully. Phase 11 research found exit status `0`, no active `prometheus-chromium-build` screen, and `.context/chromium-build-screen.log` ending with Chromium's successful build message.

Phase 12 Plan 02 confirmed the build is reproducible. Running `bash .planning/chromium/build-chromium-baseline.sh --no-op-ok` exits 0 with `.context/chromium-build-baseline.status` recording `status=0`.

Reproduction command:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

AI_AGENT=1 \
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
autoninja -C out/Default chrome
```

Recorded build result:

```text
chromium_revision=0e8499df5172f55d0d29e2b92ef7e6a704529578
depot_tools_revision=ea253a3e3ae7653cafd343be001dc5cbe69b3ad0
gn_args=is_debug = false is_component_build = true symbol_level = 0
gn_status=0
build_status=0
status=0
log_file: .context/chromium-build-baseline.log
working_directory: .context/chromium/src
```

If the Chromium binary is missing or the prior result needs to be reproduced, rerun:

```sh
bash .planning/chromium/build-chromium-baseline.sh --no-op-ok
```

## Unmodified Launch Result

Phase 12 Plan 03 confirmed the unmodified Chromium app launches, accepts a `data:` smoke page, passes the 8s alive check, and quits cleanly before any Prometheus source patches are introduced.

**The normal path is attempted first.** The workaround below is an explicit retry option for development noise, not the baseline proof.

Launch command used:

```sh
.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium \
  --user-data-dir=<isolated-profile> \
  --no-first-run \
  --no-default-browser-check \
  'data:text/html,<title>Prometheus Chromium Baseline Smoke</title><h1>OK</h1>'
```

Evidence:

```text
chromium_revision=0e8499df5172f55d0d29e2b92ef7e6a704529578
gn_args=is_debug = false is_component_build = true symbol_level = 0
attempt=normal
normal_attempt_status=0
workaround_attempt_status=-
workaround_used=false
status=0
patches_blocked=false
log_file: .context/chromium-launch.log
status_file: .context/chromium-launch.status
profile_dir: .context/chromium-smoke-profile.<random>
```

Reproduce with:

```sh
bash .planning/chromium/smoke-launch-unmodified.sh
```

**`--disable-features=DialMediaRouteProvider` workaround:** On macOS, repeated local builds can trigger system-level local network permission prompts that interfere with launch. If the normal path fails because of this noise, retry with:

```sh
bash .planning/chromium/smoke-launch-unmodified.sh --with-dial-workaround
```

The `--with-dial-workaround` flag attempts the normal path first; only if that fails does it retry with `--disable-features=DialMediaRouteProvider`. This workaround suppresses the DIAL media router so the local network permission dialog does not appear. Do not present this workaround as the default baseline proof; the Phase 12 baseline was proven on the normal path with `workaround_used=false`.

**Downstream gate:** If `.context/chromium-launch.status` records `patches_blocked=true` or a nonzero status, Prometheus-specific Chromium patches are blocked until the launch blocker is fixed or explicitly documented.

## Build Args Chosen

```gn
is_debug = false
is_component_build = true
symbol_level = 0
```

Rationale:

- `is_debug=false`: faster linking/full rebuilds than debug for local Chromium.
- `is_component_build=true`: faster incremental linking via many smaller dylibs.
- `symbol_level=0`: avoids huge debug symbol generation during the first baseline build.

These match Chromium's official Mac build guidance for faster local builds.

## Artifact Isolation Policy

The project uses a **tracked `.gitignore` policy** for Chromium artifact isolation. `.gitignore` at the root covers `.context/`, `.gclient`, `.gclient_entries`, `depot_tools/`, `out/`, and wildcard patterns for `.log`, `.status`, `.tmp`, and `.cache` files.

The tracked `.gitignore` policy is preferred over a gitdir-local exclude because it works in fresh clones without manual setup.

`bash .planning/chromium/verify-artifact-isolation.sh` is a **blocking gate** and must pass before accepting any build or launch evidence as baseline proof. It asserts:

1. `.gitignore` exists and contains all required policy lines.
2. `git check-ignore -v` confirms `.gitignore` is the ignore source for key artifact paths (not only gitdir-local exclude).
3. `git ls-files` returns nothing for known artifact paths.
4. `git status --short` is clean of forbidden Chromium artifact patterns.

## Patch Branch And Export Discipline

Phase 12 establishes the isolation contract before Prometheus-specific Chromium source changes begin. Later phases must follow this discipline:

- **Source edit location:** Future Chromium source edits happen inside `.context/chromium/src`. This directory is a separate git checkout managed by depot_tools. The root Prometheus planning repository stores docs, scripts, evidence, and exported patch guidance only.
- **No direct commits on Chromium `main` or detached baseline:** do not commit Prometheus changes directly on Chromium `main` or on a detached baseline commit. Always work from a named branch.
- **Create named branches:** Before any source edits, create a named Chromium branch, for example:
  ```sh
  git new-branch prometheus/phase-13-branding
  ```
  Run this command from inside `.context/chromium/src`.
- **Export patches after source edits:** After editing source files and committing to the named branch, export patches relative to the pinned baseline:
  ```sh
  git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD -o ../../../../.context/chromium-patches/phase-13-branding
  ```
  Exported patch files are stored under `.context/chromium-patches/` (ignored by root git) and referenced from tracked planning docs.
- **After rebases:** After any rebase or upstream sync, run `gclient sync`, then `gn gen`, then build, then launch smoke, and then artifact isolation again to confirm the baseline is still sound.
- **License boundary:** Falkon is GPLv3 and Chromium is under a different license structure. Prometheus behavior, design, and contracts can be reimplemented, but GPL Falkon implementation code must not be copied into `.context/chromium/src` without explicit license review.

## Phase 13 Script Gates

Run this script after the Prometheus branding rebuild is complete (Wave 2). It launches Prometheus.app with an isolated profile, asserts CFBundleName and CFBundleIdentifier via plutil, and writes `.context/prometheus-launch.status`.

```sh
bash .planning/chromium/smoke-launch-prometheus.sh
```

- **smoke-launch-prometheus.sh**: Asserts Prometheus.app exists at `out/Default`, launches it with `--no-first-run --no-default-browser-check` and a smoke `data:` URL, checks process alive after 8s, stops it, verifies artifact isolation, asserts CFBundleName=Prometheus and CFBundleIdentifier=com.fullselfbrowsing.prometheus via plutil, and writes `.context/prometheus-launch.status` with `status=0` on success.

The Phase 12 script gates (env/build/isolation) remain the baseline and must pass before Phase 13 gates run.

## Phase 13 Patches

**Branch:** `prometheus/phase-13-branding`
**Patch directory:** `.context/chromium-patches/phase-13-branding/`
**Pinned baseline:** `0e8499df5172f55d0d29e2b92ef7e6a704529578`

### Patch 1: BRANDING file override

Commit: `branding: override BRANDING file for Prometheus identity`

Fields changed:

| Field | Upstream value | Prometheus override |
|-------|---------------|---------------------|
| `COMPANY_FULLNAME` | `The Chromium Authors` | `Full Self Browsing` |
| `COMPANY_SHORTNAME` | `The Chromium Authors` | `FSB` |
| `PRODUCT_FULLNAME` | `Chromium` | `Prometheus` |
| `PRODUCT_SHORTNAME` | `Chromium` | `Prometheus` |
| `PRODUCT_INSTALLER_FULLNAME` | `Chromium Installer` | `Prometheus Installer` |
| `PRODUCT_INSTALLER_SHORTNAME` | `Chromium Installer` | `Prometheus Installer` |
| `COPYRIGHT` | `Copyright @LASTCHANGE_YEAR@ The Chromium Authors. All rights reserved.` | `Copyright 2024-2026 Full Self Browsing. Powered by Chromium.` |
| `MAC_BUNDLE_ID` | `org.chromium.Chromium` | `com.fullselfbrowsing.prometheus` |
| `MAC_CREATOR_CODE` | `Cr24` | `Cr24` (unchanged) |
| `MAC_TEAM_ID` | (empty) | (empty, unchanged — notarization deferred to Phase 24) |

After applying this patch, `gn gen` must be re-run before `autoninja`. The `branding.gni` `exec_script` reads BRANDING at GN generation time only. GN gen command used:

```sh
cd .context/chromium/src
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="$(pwd)/../../depot_tools:${PATH}"
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
```

### Patch 2: chromium_strings.grd product-name overrides

Commit: `branding: override chromium_strings.grd product-name strings for Prometheus`

All 11 high-visibility IDS_* strings overridden to Prometheus identity. Includes both `use_titlecase` and `not use_titlecase` branches of `IDS_ABOUT` for macOS. ChromeOS branch left unchanged.

### Applying Patches on a Fresh Checkout

```sh
cd .context/chromium/src
git checkout -b prometheus/phase-13-branding 0e8499df5172f55d0d29e2b92ef7e6a704529578
git am /path/to/.context/chromium-patches/phase-13-branding/0001-*.patch
git am /path/to/.context/chromium-patches/phase-13-branding/0002-*.patch
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="$(pwd)/../../depot_tools:${PATH}"
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
AI_AGENT=1 autoninja -C out/Default chrome
```

### Exporting the Patch Series

```sh
cd .context/chromium/src
git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD \
  -o /absolute/path/to/puebla/.context/chromium-patches/phase-13-branding
```

Note: use an absolute `-o` path. The relative path `../../../../.context/chromium-patches/` resolves above the project root when run from `src` inside a subdirectory.
