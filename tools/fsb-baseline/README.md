# Prometheus Baseline

This directory captures the Phase 1 baseline for the local Falkon-derived browser before rebrand or native agent-control work begins. The target product identity is Prometheus, with "Powered by FSB" as the affiliation/tagline.

## Preflight

Run from the Falkon checkout:

```sh
./tools/fsb-baseline/preflight.sh
```

The preflight checks local build prerequisites and does not install packages or mutate the system. It currently expects:

- `cmake`
- `ninja`
- `git`
- Qt 6 with QtWebEngine CMake package metadata
- Extra CMake Modules and the required KF6 package metadata used by `CMakeLists.txt`

On this workstation, `cmake`, `ninja`, and `qmake` were not present on `PATH` when Phase 1 ran. That blocks direct configure/build validation until build tools are installed deliberately.

## Configure And Build

After prerequisites are available, use a contained baseline build directory:

```sh
cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/fsb-baseline
```

The expected executable path is usually one of:

- `build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus`
- `build/fsb-baseline/bin/prometheus`

## Smoke Test

After a binary exists:

```sh
./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus
```

The smoke script launches the browser with a local `data:` URL, attempts a second URL invocation, waits briefly, then terminates the launched process. It records logs under `/tmp/fsb-browser-smoke.*` by default.

## Inventories

- `product-identity-inventory.md` maps product-visible Falkon/KDE/Qt identity surfaces for Phase 2.
- `legal-notice-inventory.md` maps inherited legal surfaces that later phases must preserve.
