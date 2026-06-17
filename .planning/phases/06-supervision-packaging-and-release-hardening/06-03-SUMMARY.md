# Plan 06-03 Summary: macOS Package

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Added `tools/fsb-baseline/package-macos.sh`.
- Packages `prometheus.app` as `Prometheus.app` inside `Prometheus-macos.tar.gz`.
- Stages `libFalkonPrivate.dylib`, plugins, and themes into the app bundle for local validation.
- Includes GPL, theme notices, Falkon/KDE/Qt copyright, and source-availability text.

## Verification

- Release validation produced the tarball, smoke-launched the packaged app, and verified required runtime/legal files.
