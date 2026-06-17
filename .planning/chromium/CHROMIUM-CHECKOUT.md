# Chromium Checkout Handoff

**Created:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Chromium source checkout complete; GN generation blocked by unaccepted Xcode license.

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

## Local Build Blocker

Full Xcode is installed:

```text
/Applications/Xcode.app
Xcode 26.5
Build version 17F42
```

But the active developer directory is Command Line Tools:

```text
/Library/Developer/CommandLineTools
```

GN generation with the active Command Line Tools path fails because Chromium's macOS SDK script calls `xcodebuild -version`, and `xcodebuild` requires full Xcode.

GN generation with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` fails because the Xcode license has not been accepted:

```text
You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license.
```

Do not have an agent accept this legal agreement silently. The user should review/accept it from Terminal.

## Resume Commands After Xcode License Acceptance

After the user accepts the Xcode license, resume with:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
```

Then build:

```sh
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

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
