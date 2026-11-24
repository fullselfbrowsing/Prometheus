# Plan 02-04 Summary: Docs and Rebrand Verification

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Replaced the product README with Prometheus build/run/legal guidance.
- Updated baseline smoke docs and binary discovery to prefer `prometheus.app/Contents/MacOS/prometheus`.
- Updated runtime-facing logs, prompts, notifications, and menu labels that still exposed Falkon as the product identity.
- Rebranded Linux appstream default metadata while leaving inherited translated/legal text for later translation/legal strategy work.

## Verification

- `cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo` exited 0.
- `cmake --build build/fsb-baseline` exited 0.
- `./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus --wait 1` exited 0.
- No `prometheus` process remained after smoke verification.
