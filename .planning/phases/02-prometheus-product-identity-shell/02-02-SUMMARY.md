# Plan 02-02 Summary: Icons, Bookmarks, and About Surfaces

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Added a Prometheus SVG mark to the Qt resource bundle.
- Generated and packaged a Prometheus `.icns` for the macOS app bundle.
- Updated About dialog title/content to `About Prometheus` and `Powered by FSB`.
- Replaced default bookmarks with Prometheus, FSB, GitHub org, and PhantomStream-oriented entries.
- Updated built-in start/about/config pages to use the Prometheus mark.

## Verification

- `falkon/src/lib/data/icons.qrc` includes `icons/prometheus.svg`.
- `falkon/src/lib/data/icons/exeicons/prometheus.icns` is a valid macOS icon file.
- `build/fsb-baseline/bin/prometheus.app/Contents/Resources/prometheus.icns` is present after rebuild.
