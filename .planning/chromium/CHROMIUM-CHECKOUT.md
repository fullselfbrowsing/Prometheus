# Chromium Checkout Handoff

**Created:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Chromium source checkout complete; Xcode/Metal toolchain fixed; GN generation complete; first `chrome` build running in detached `screen` session.

## Local Paths

| Item | Path |
|------|------|
| depot_tools | `.context/depot_tools` |
| Chromium gclient root | `.context/chromium` |
| Chromium source | `.context/chromium/src` |
| Falkon preservation bundle | `.context/falkon-preservation/falkon-prometheus-v1.bundle` |
| Falkon patch series | `.context/falkon-preservation/patches/` |

`.context/` is ignored by the root repository via the root checkout's `.git/info/exclude`, so the Chromium checkout and depot_tools installation do not dirty root git status.

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

Recorded depot_tools revision:

```text
c46c2e905
```

### Chromium fetch

Ran the shallow Chromium fetch:

```sh
mkdir -p .context/chromium
cd .context/chromium
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" fetch --no-history chromium
```

Checkout completed and hooks ran successfully.

Recorded Chromium revision:

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

The active developer directory is now full Xcode:

```text
/Applications/Xcode.app/Contents/Developer
```

The original blocker was fixed by switching `xcode-select` to full Xcode and accepting the Xcode license from Terminal. `xcodebuild -runFirstLaunch` also installed first-launch components.

The next build attempt found the Metal compiler wrapper but failed because the Metal Toolchain asset was not installed:

```text
error: cannot execute tool 'metal' due to missing Metal Toolchain; use: xcodebuild -downloadComponent MetalToolchain
```

That blocker was fixed with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -runFirstLaunch
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain
```

Verification:

```text
xcodebuild -version -> Xcode 26.5 / Build version 17F42
xcrun metal -v -> Apple metal version 32023.883
```

GN generation now succeeds:

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

## First Build Handoff

The first `chrome` build is long-running for a clean Chromium checkout. It was started with the faster non-TTY Siso settings that Chromium's `depot_tools/siso.py` applies when `AI_AGENT=1` is present:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

AI_AGENT=1 \
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
autoninja -C out/Default chrome
```

The active detached build handoff is:

```text
screen session: prometheus-chromium-build
Log file: .context/chromium-build-screen.log
Exit status file: .context/chromium-build-screen.status
Working directory: .context/chromium/src
Expected Siso flags: --quiet --batch=false --heartbeat_period=30s --offline
```

Monitor it with:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla
screen -ls
tail -f .context/chromium-build-screen.log
test -f .context/chromium-build-screen.status && cat .context/chromium-build-screen.status
```

If the `screen` session has exited and the Chromium binary is still missing, resume with:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

AI_AGENT=1 \
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
autoninja -C out/Default chrome
```

Then run:

```sh
/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium
```

If macOS shows incoming network permission prompts on repeated local builds, use Chromium's documented development workaround:

```sh
out/Default/Chromium.app/Contents/MacOS/Chromium --disable-features=DialMediaRouteProvider
```

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
