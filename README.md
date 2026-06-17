# Prometheus

Prometheus is an agent-native desktop browser powered by FSB. It is derived from the Falkon/QtWebEngine codebase and preserves inherited legal notices while replacing product-visible identity with Prometheus.

## Baseline Build

```sh
./tools/fsb-baseline/preflight.sh
cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/fsb-baseline
```

The macOS baseline binary is:

```sh
build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus
```

## Smoke Test

```sh
./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus --wait 1
```

## Legal Notices

Prometheus is built from GPL-licensed Falkon/KDE/Qt source. Required inherited copyright and license notices must remain available in source and release artifacts. See:

- `COPYING`
- `tools/fsb-baseline/legal-notice-inventory.md`
- in-app About/Licenses surfaces

## Upstream Attribution

The bootstrap browser foundation comes from Falkon, a KDE QtWebEngine browser. Product-visible identity is Prometheus; inherited legal attribution remains preserved.
