---
phase: 08
plan: 01
subsystem: release-validation
tags: [parity-matrix, smoke-gate, release-validate, agentcommandrouter]
dependency_graph:
  requires: []
  provides:
    - FSB parity evidence ledger (FSB-PARITY.md) with 25 required category rows
    - Static + live parity gate script (smoke-fsb-plus-parity.sh)
    - Release validation with blocking parity gate in release-validate.sh
  affects:
    - falkon/tools/fsb-baseline/release-validate.sh
    - falkon/src/lib/agent/agentcommandrouter.cpp
tech_stack:
  added:
    - smoke-fsb-plus-parity.sh: Bash/rg/curl parity gate script (17888 port)
  patterns:
    - require_rg static check pattern (from smoke-compact-tabs.sh)
    - PrometheusRuntime/Policy/agentCap Settings read in router constructor
    - PERMISSION_BLOCKED and PROVIDER_NOT_CONFIGURED typed error codes in router
key_files:
  created:
    - falkon/tools/fsb-baseline/FSB-PARITY.md
    - falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh
  modified:
    - falkon/tools/fsb-baseline/release-validate.sh
    - falkon/src/lib/agent/agentcommandrouter.cpp
decisions:
  - "Use existing smoke-compact-tabs.sh as the exact structural analog for smoke-fsb-plus-parity.sh"
  - "Add PERMISSION_BLOCKED to routeOpenInternalSurface gating internalSurfaceControl policy key"
  - "Add PROVIDER_NOT_CONFIGURED to routeProviderConfig for discover_models when no secret is configured"
  - "Add settings.h include and read PrometheusRuntime/Policy/agentCap in router constructor with env-var fallback"
metrics:
  duration: 5min
  completed: "2026-06-17"
  tasks_completed: 2
  files_created: 3
  files_modified: 2
---

# Phase 8 Plan 01: FSB Parity Evidence Ledger and Release Gate Summary

**One-liner:** FSB parity evidence ledger with 25 category rows and a blocking smoke gate that verifies required matrix rows and source patterns at release time.

## What Was Built

### Task 1: FSB-PARITY.md (commit cb0a0db84)

Created `falkon/tools/fsb-baseline/FSB-PARITY.md` as the authoritative parity evidence ledger for Prometheus against FSB. The file contains:

- YAML frontmatter: `version: 1`, `phase: 08`, `last_updated: 2026-06-17`, `required_categories: 25`
- All 25 required FSB feature category rows in the exact order from 08-UI-SPEC.md:
  side panel, provider settings, model discovery, fallback routing, MCP tools, DOM snapshots,
  page snapshots, read tools, action tools, smart waiting, stuck detection, visual feedback,
  memory, site guides, vault, remote dashboard pairing, supervision DOM mirror, tab ownership,
  tab groups/state, diagnostics, logs/action history, cost/token accounting, telemetry controls,
  internal settings control, release validation
- Six **Better** rows fully evidenced with non-empty Native Improvement and Validation columns:
  - **provider settings**: SECRET_TRANSPORT_BLOCKED, native Keychain boundary
  - **vault**: VAULT_NATIVE_CONFIRMATION_REQUIRED, Keychain/native-only secret path
  - **action tools**: stable native tab IDs, bearer-authenticated sessions, typed ownership errors
  - **tab ownership**: persistent PrometheusRuntime/Policy/agentCap setting
  - **internal settings control**: PERMISSION_BLOCKED, native router can reach restricted browser surfaces
  - **release validation**: automated blocking parity gate script
- FSBP-01 through FSBP-06 requirement reference section
- No raw secrets, API keys, passwords, or card numbers

### Task 2: smoke-fsb-plus-parity.sh + release-validate.sh + router changes (commit 70ac201ee)

Created `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` modeled exactly on `smoke-compact-tabs.sh`:

- Shell structure: `#!/usr/bin/env bash`, `set -euo pipefail`, SCRIPT_DIR/SOURCE_ROOT derivation
- Args: `--binary PATH`, `--port PORT`, `--matrix-only`, `--help`
- Helpers: `require_rg`, `json_field`, `require_ok`, `require_error_code`, `post_command`
- `run_static_checks()` with:
  - FSBP-01 through FSBP-06 in FSB-PARITY.md
  - Eight required category names in FSB-PARITY.md
  - `SECRET_TRANSPORT_BLOCKED` in both router and runtime
  - `smoke-fsb-plus-parity` in release-validate.sh
  - `PrometheusRuntime/Policy/agentCap` in agentcommandrouter.cpp
  - `PERMISSION_BLOCKED|PROVIDER_NOT_CONFIGURED` in agentcommandrouter.cpp
- `--matrix-only` early exit after static checks
- Binary-absent early exit (exact pattern from smoke-compact-tabs.sh)
- Live checks: diagnostics, list_tabs, health tools array validation
- Port `17888` (not 17887 which compact-tabs uses)
- Script marked executable (`chmod +x`)

Updated `falkon/tools/fsb-baseline/release-validate.sh`:
- Added `bash -n smoke-fsb-plus-parity.sh` syntax check before cmake build
- Added `smoke-fsb-plus-parity.sh --binary "$BINARY" --port 17888` live invocation after compact-tabs

Updated `falkon/src/lib/agent/agentcommandrouter.cpp` (deviations from plan per Rule 2):
- Added `#include "settings.h"`
- Constructor reads `PrometheusRuntime/Policy/agentCap` from QSettings; env-var fallback preserved
- `routeOpenInternalSurface`: added `PERMISSION_BLOCKED` check reading `PrometheusRuntime/Policy/internalSurfaceControl`
- `routeProviderConfig`: added `PROVIDER_NOT_CONFIGURED` response for `discover_models` when no provider is configured

## Verification Results

All five overall verification checks passed:

1. `bash -n smoke-fsb-plus-parity.sh` exits 0
2. `smoke-fsb-plus-parity.sh --matrix-only` exits 0 with all static checks passing
3. `rg -c 'smoke-fsb-plus-parity' release-validate.sh` returns 2
4. `bash -n release-validate.sh` exits 0
5. `FSB-PARITY.md` contains both FSBP-01 and FSBP-06

## Deviations from Plan

### Auto-added Missing Critical Functionality

**1. [Rule 2 - Missing Critical] Added PrometheusRuntime/Policy/agentCap Settings read to router constructor**
- **Found during:** Task 2 — the smoke static check `require_rg 'PrometheusRuntime/Policy/agentCap'` would have failed because the router only read agentCap from environment at the time
- **Issue:** The plan's Task 2 smoke static checks require `PrometheusRuntime/Policy/agentCap` to be present in `agentcommandrouter.cpp`; without this, `--matrix-only` would fail
- **Fix:** Added `settings.h` include and replaced environment-only `qgetenv` with a QSettings read from `PrometheusRuntime/Policy/agentCap`, retaining the env-var as a fallback
- **Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`
- **Commit:** 70ac201ee

**2. [Rule 2 - Missing Critical] Added PERMISSION_BLOCKED to routeOpenInternalSurface**
- **Found during:** Task 2 — the smoke static check `require_rg 'PERMISSION_BLOCKED|PROVIDER_NOT_CONFIGURED'` would have failed
- **Issue:** PERMISSION_BLOCKED typed error code was defined in 08-PATTERNS.md Pattern D as a required new code but not yet in the router
- **Fix:** Added internalSurfaceControl policy read and PERMISSION_BLOCKED failure path to `routeOpenInternalSurface`
- **Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`
- **Commit:** 70ac201ee

**3. [Rule 2 - Missing Critical] Added PROVIDER_NOT_CONFIGURED to routeProviderConfig**
- **Found during:** Task 2 — required alongside PERMISSION_BLOCKED in the same static check
- **Issue:** PROVIDER_NOT_CONFIGURED was defined in 08-PATTERNS.md Pattern D as required but not yet in the router
- **Fix:** Added discover_models branch checking for any configured provider; returns PROVIDER_NOT_CONFIGURED failure with `providerAvailable: false` metadata when none is configured
- **Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`
- **Commit:** 70ac201ee

## Threat Surface Scan

No new security-relevant surfaces introduced beyond what the plan's threat model covers:
- `PERMISSION_BLOCKED` enforces internalSurfaceControl policy (mitigates T-08-01b)
- `PROVIDER_NOT_CONFIGURED` does not expose raw secret values
- `PrometheusRuntime/Policy/agentCap` reads from QSettings; no new trust boundary

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `falkon/tools/fsb-baseline/FSB-PARITY.md` | FOUND |
| `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` | FOUND |
| `08-01-SUMMARY.md` | FOUND |
| Commit cb0a0db84 (FSB-PARITY.md) | FOUND |
| Commit 70ac201ee (smoke gate + router) | FOUND |
