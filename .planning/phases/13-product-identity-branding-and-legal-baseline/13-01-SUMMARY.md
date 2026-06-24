---
phase: "13-product-identity-branding-and-legal-baseline"
plan: "01"
subsystem: "chromium-gate-scripts"
tags: ["gpl-guard", "smoke-launch", "branding", "BRAND-05", "bash-gate"]
dependency_graph:
  requires:
    - "Phase 12 gate skeleton (check-chromium-env.sh, verify-artifact-isolation.sh, smoke-launch-unmodified.sh)"
  provides:
    - "check-falkon-gpl-guard.sh — GPL Falkon contamination guard for Prometheus Chromium source dirs"
    - "smoke-launch-prometheus.sh — identity-asserting smoke launch gate for rebranded Prometheus.app"
  affects:
    - "Phase 13 Wave 2 rebuild gate (smoke-launch-prometheus.sh must pass after BRANDING patch)"
    - "BRAND-05 compliance (GPL guard must run before every Prometheus-branch commit)"
tech_stack:
  added: []
  patterns:
    - "Phase-12 gate skeleton: set -euo pipefail, SCRIPT_DIR/PROJECT_ROOT resolution, fail()-to-stderr, final printf with period"
    - "FOUND accumulator pattern for multi-pattern grep scan with 2>/dev/null || true safety"
    - "plutil -p identity assertion for CFBundleName and CFBundleIdentifier post-launch verification"
key_files:
  created:
    - ".planning/chromium/check-falkon-gpl-guard.sh"
    - ".planning/chromium/smoke-launch-prometheus.sh"
  modified: []
decisions:
  - "GPL guard scans only chrome/browser/prometheus and components/prometheus (not full Chromium tree) to avoid false positives from unrelated third-party code"
  - "smoke-launch-prometheus.sh is a new sibling file; smoke-launch-unmodified.sh is preserved unchanged as the immutable unmodified baseline reference"
  - "Identity assertions (plutil -p) are placed after the artifact isolation gate call, before the final success printf"
  - "Binary existence check fails with a clear Wave-2 rebuild message before any launch attempt"
metrics:
  duration: "3min"
  completed: "2026-06-23"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 13 Plan 01: GPL Falkon Guard and Prometheus Smoke-Launch Gate Summary

**One-liner:** Two executable bash gate scripts establishing GPL contamination guard and post-BRANDING-rebuild identity smoke launch for Prometheus.app.

## What Was Built

**Task 1 — GPL Falkon source guard (`check-falkon-gpl-guard.sh`):**

Scans `chrome/browser/prometheus` and `components/prometheus` for nine Falkon C++/Qt GPL signatures (class names, namespaces, Qt-specific headers). Uses a FOUND accumulator pattern so all matching patterns are reported before failing. Exits 0 cleanly when those directories do not yet exist (the expected pre-Wave-2 state). Follows the exact Phase-12 gate skeleton.

**Task 2 — Prometheus smoke-launch gate (`smoke-launch-prometheus.sh`):**

Parallel to `smoke-launch-unmodified.sh` but targets `Prometheus.app/Contents/MacOS/Prometheus`, writes evidence to `prometheus-launch.status` and `prometheus-launch.log`, quits via bundle ID `com.fullselfbrowsing.prometheus` / app name `Prometheus`, and adds post-launch `plutil -p` identity assertions verifying both CFBundleName contains `Prometheus` and CFBundleIdentifier matches `com.fullselfbrowsing.prometheus`. The script cannot be run until Wave 2 builds `Prometheus.app` (guarded by a binary existence check with a clear rebuild message).

## Deviations from Plan

None. Plan executed exactly as written. Both scripts match the Phase-12 gate skeleton, all nine GPL patterns are present, all acceptance criteria verified before commit.

## Self-Check

**Created files exist:**
- `.planning/chromium/check-falkon-gpl-guard.sh` — created, executable, syntax-valid, runs clean
- `.planning/chromium/smoke-launch-prometheus.sh` — created, executable, `bash -n` passes

**Commits exist:**
- `dbd682582` — feat(13-01): author GPL Falkon source guard gate script
- `9f9f8a100` — feat(13-01): author Prometheus smoke-launch identity gate

**Unmodified baseline preserved:**
- `git diff --quiet .planning/chromium/smoke-launch-unmodified.sh` exits 0

## Self-Check: PASSED

All created files exist and are executable. Both commits verified in git log. smoke-launch-unmodified.sh is unchanged.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns outside `.context/`, or schema changes introduced. Both scripts are read-only gate tools.
