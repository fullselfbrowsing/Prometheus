# Plan 02-01 Summary: App Metadata and Platform Identity

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Set runtime product name to `Prometheus` and homepage/support URLs to the FSB site.
- Set macOS bundle identity to `com.fullselfbrowsing.prometheus`.
- Set build output name to `prometheus`, producing `prometheus.app/Contents/MacOS/prometheus`.
- Rebranded default Linux desktop metadata to `Name=Prometheus`, `Icon=prometheus`, and `Exec=prometheus`.
- Updated Windows version metadata to Prometheus and Full Self Browsing.

## Verification

- `cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo` exited 0.
- `cmake --build build/fsb-baseline` exited 0.
- Generated bundle metadata contains `CFBundleName=Prometheus`, `CFBundleDisplayName=Prometheus`, `CFBundleExecutable=prometheus`, and `CFBundleIdentifier=com.fullselfbrowsing.prometheus`.
