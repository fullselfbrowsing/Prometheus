---
phase: 08
plan: 03
subsystem: preferences-policy-ui
tags: [preferences, settings, agent-policy, prometheus, qt-ui]
dependency_graph:
  requires:
    - 08-02: PrometheusRuntime/Policy group and key names established by agentcommandrouter
  provides:
    - Preferences dialog Prometheus tab with all 10 required policy controls
    - loadSettings reads PrometheusRuntime/Policy group matching router key names
    - saveSettings writes PrometheusRuntime/Policy group for 8 mutable controls
  affects:
    - 08-04: FSB parity matrix can reference settings page for agent policy controls
tech_stack:
  added: []
  patterns:
    - QFormLayout inside a QVBoxLayout for the Prometheus settings page
    - Settings beginGroup/endGroup in constructor (load) and saveSettings (save) for PrometheusRuntime/Policy
    - Locked security invariants: vaultBoundaryCheck and vaultAutofillCheck always true, never written to Settings
    - QListWidget + QStackedWidget navigation: new Prometheus item at index 13
key_files:
  created: []
  modified:
    - falkon/src/lib/preferences/preferences.ui
    - falkon/src/lib/preferences/preferences.cpp
decisions:
  - vaultBoundaryCheck and vaultAutofillCheck are display-only; values are always true and are never written to Settings (security invariants matching Plan 02 vaultBoundary locked default)
  - setCategoryIcon(13, QIcon::fromTheme("system-run")) used as placeholder; Phase 9 will replace with bundled Font Awesome icon
  - Load block placed before the CONNECTS section in the constructor, after the proxy settings endGroup
  - No new slot declarations needed in preferences.h; no UI signal connections required for the new controls
metrics:
  duration: 3min
  completed_date: "2026-06-16"
  tasks: 2
  files: 2
---

# Phase 8 Plan 03: Prometheus Agent Policy Preferences Tab Summary

Prometheus agent policy settings tab added to the Preferences dialog, wiring all ten required controls to the shared PrometheusRuntime/Policy Settings group that the router reads at startup.

## What Was Built

### Task 1: Add Prometheus agent policy page to preferences.ui

Added a new "Prometheus" entry to the `listWidget` (index 13, last position) and a corresponding `prometheusPage` widget to the `stackedWidget`. The page layout uses a `QVBoxLayout` containing a bold heading label ("Prometheus Agent Policy", 10pt) and a `QFormLayout` frame with all ten required controls:

1. `agentCapSpin` — QSpinBox, range 1-16, default value 4, accessible name "Agent cap"
2. `internalSurfaceCheck` — QCheckBox unchecked, accessible name "Internal surface control"
3. `tabOwnershipCheck` — QCheckBox checked, accessible name "Tab ownership enforcement"
4. `bgTabActionsCheck` — QCheckBox checked, accessible name "Background tab actions"
5. `visualFeedbackCheck` — QCheckBox checked, accessible name "Visual feedback"
6. `prometheusSeparator` — horizontal Line separating visual feedback from security-sensitive rows
7. `telemetryCombo` — QComboBox with items "Local only" (index 0) and "Off" (index 1), accessible name "Telemetry"
8. `vaultBoundaryCheck` — QCheckBox checked and **disabled** (security invariant); tooltip: "Provider and vault secrets cannot cross MCP or remote transports. This is a security invariant."
9. `vaultAutofillCheck` — QCheckBox checked and **disabled** (security invariant); tooltip: "Vault autofill requires foreground confirmation. This is a security invariant."
10. `supervisionPairingCheck` — QCheckBox unchecked, accessible name "Supervision pairing"
11. `dashboardRemoteCheck` — QCheckBox unchecked, accessible name "Dashboard remote control"

No QLineEdit or QTextEdit with password echo mode added to the Prometheus tab.

### Task 2: Wire Prometheus policy controls into loadSettings and saveSettings

**preferences.cpp constructor (loadSettings):** Added `PrometheusRuntime/Policy` block reading:
- `agentCap` (default 4) into `agentCapSpin`
- `internalSurfaceControl` (default false) into `internalSurfaceCheck`
- `tabOwnershipEnforcement` (default true) into `tabOwnershipCheck`
- `backgroundTabActions` (default true) into `bgTabActionsCheck`
- `visualFeedback` (default true) into `visualFeedbackCheck`
- `telemetry` (default 0) into `telemetryCombo`
- `supervisionPairing` (default false) into `supervisionPairingCheck`
- `dashboardRemoteControl` (default false) into `dashboardRemoteCheck`
- `vaultBoundaryCheck` and `vaultAutofillCheck` are always true; not read from Settings

**preferences.cpp saveSettings():** Added `PrometheusRuntime/Policy` block writing the same 8 mutable controls. The locked vault rows are intentionally excluded. No `settings.sync()` call added.

**preferences.cpp icon setup:** Added `setCategoryIcon(13, QIcon::fromTheme("system-run"))` as a placeholder icon for the new Prometheus nav entry.

**preferences.h:** No changes needed; no new slot declarations required.

## Verification Results

Build verification:
```
cmake --build falkon/build/fsb-baseline --target FalkonPrivate -j2
[4/4] Linking CXX shared library bin/libFalkonPrivate.dylib
```
Exit 0, one pre-existing deprecation warning (`Q_OS_OSX`), no new errors.

Acceptance criteria verified:
- `rg 'PrometheusRuntime/Policy' preferences.cpp` — 2 matches (load + save)
- `rg 'agentCapSpin|tabOwnershipCheck|visualFeedbackCheck|telemetryCombo' preferences.cpp` — 8 lines (4 in load, 4 in save)
- `rg 'vaultBoundaryCheck.*setValue|setValue.*vaultBoundary' preferences.cpp` — 0 matches (locked rows not written)
- XML validation: all 10 required objectNames present, `vaultBoundaryCheck` and `vaultAutofillCheck` have `enabled=false`
- `listWidget` last item is "Prometheus"; `prometheusPage` is the last widget in `stackedWidget`

## Deviations from Plan

None. Plan executed exactly as written.

## Threat Surface Scan

- T-08-03: `agentCapSpin` range enforced to 1-16 at UI level via `minimum=1, maximum=16` properties.
- T-08-03b: `vaultBoundaryCheck` and `vaultAutofillCheck` are `enabled=false` in preferences.ui and not written in `saveSettings`; invariants cannot be overridden through the dialog.
- T-08-03c: No QLineEdit or QTextEdit with `echoMode=Password` added to the Prometheus tab. The pre-existing `proxyPassword` QLineEdit in the proxy settings section is unrelated.

No new network endpoints, auth paths, or schema changes beyond the plan's threat register.

## Self-Check: PASSED

Files verified:
- `falkon/src/lib/preferences/preferences.ui` — FOUND
- `falkon/src/lib/preferences/preferences.cpp` — FOUND

Commits verified:
- `170990994` feat(08-03): add Prometheus agent policy page to preferences.ui — FOUND
- `a9919046d` feat(08-03): wire Prometheus policy controls into loadSettings and saveSettings — FOUND
