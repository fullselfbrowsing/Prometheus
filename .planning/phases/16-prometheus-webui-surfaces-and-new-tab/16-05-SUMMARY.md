---
phase: 16-prometheus-webui-surfaces-and-new-tab
plan: 05
subsystem: ui
tags: [chromium, webui, security, tests, resources]
requires:
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 02
    provides: Ask FSB handoff state
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 03
    provides: WebUI-backed side panel
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 04
    provides: Control Panel WebUI shell
provides:
  - Consume-on-read Ask FSB pending prompt adapter over browser-owned user data
  - Prometheus WebUI unit tests for prompt bounds, empty prompt clearing, one-shot consume behavior, and secret fixture absence
  - Resource scanner for Phase 16 WebUI remote URL, URL/history leakage, and secret fixture gates
  - Packaged-resource iteration notes for Prometheus WebUI
affects: [phase-16, prometheus-webui, security, testing]
tech-stack:
  added: []
  patterns:
    - Browser-owned handoff state is adapted through `base::SupportsUserData`
    - Root resource gates scan source resources before Chromium build/test loops
key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_webui_unittest.cc
    - .planning/chromium/verify-prometheus-webui-resources.sh
    - .planning/chromium/PROMETHEUS-WEBUI-ITERATION.md
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
key-decisions:
  - "Pending Ask FSB prompt reads now consume the browser-owned state; tests inspect the live opened side-panel WebView rather than navigating a second side-panel page."
  - "Prometheus WebUI iteration remains package-backed by default; disk-loaded WebUI is deferred until it can pass the same resource/security gates."
patterns-established:
  - "Use `verify-prometheus-webui-resources.sh` before packaging-sensitive Prometheus WebUI changes."
requirements-completed: [WEBUI-05, WEBUI-06, WEBUI-07]
duration: 13min
completed: 2026-07-07
---

# Phase 16 Plan 05: WebUI Resource and Data Safety Summary

**Safe browser-owned data adapters plus static Prometheus WebUI resource gates**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-07T07:54:57Z
- **Completed:** 2026-07-07T08:08:12Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Changed pending Ask FSB reads to consume the prompt after one read.
- Added `base::SupportsUserData` adapter functions for prompt handoff storage so pure unit tests can cover the storage semantics without full profile setup.
- Added `PrometheusWebUIHandoffTest` unit coverage for empty prompts, trimming, prompt bounds, and consume-on-read behavior.
- Added `PrometheusWebUIResourceTest` coverage that packaged renderer resources do not contain known secret fixture strings.
- Updated the browser handoff regression to inspect the actual live side-panel WebView opened by Ask FSB.
- Added `.planning/chromium/verify-prometheus-webui-resources.sh` to fail on remote URLs, `@import`, external `src`/`href`, URL/history prompt transport, and known secret fixtures.
- Documented the package-backed WebUI iteration loop in `.planning/chromium/PROMETHEUS-WEBUI-ITERATION.md`.

## Task Commits

1. **Task 1: Add safe data adapter tests** - Chromium `b46e7a5d1e`
2. **Task 2: Add resource scanner and iteration docs** - root `a9afd3e2e`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_webui_unittest.cc` - New WebUI handoff/resource unit tests.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.*` - User-data adapter functions and consume-on-read semantics.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Added the new unit-test source.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc` - Updated Ask FSB browser test to inspect the live opened side-panel WebView.
- `.planning/chromium/verify-prometheus-webui-resources.sh` - Static Prometheus WebUI resource gate.
- `.planning/chromium/PROMETHEUS-WEBUI-ITERATION.md` - Package-backed local iteration notes.

## Decisions Made

- Use consume-on-read for pending prompts so renderer seed state is one-shot and cannot be replayed by later side-panel navigations.
- Keep the fast iteration path package-backed for now, because Prometheus resource IDs, pak coverage, and security scanning are part of the phase gate.
- Let the scanner forbid known secret fixture strings while allowing required UI-SPEC security copy such as `Provider secret blocked`.

## Deviations from Plan

- Rather than introducing a larger placeholder data model, the plan focused on the actual browser-owned state currently crossing into renderer-visible WebUI: Ask FSB pending prompt data and packaged WebUI resource strings.

## Issues Encountered

- Plain `TestingProfile` setup was too heavy for `prometheus_unittests`; the helper now exposes a `base::SupportsUserData` adapter so unit tests can cover storage semantics directly.
- Consume-on-read invalidated the old browser test that navigated a second side-panel WebUI. The test now reads the live WebView opened by the handoff path.

## Verification

- `bash .planning/chromium/verify-prometheus-webui-resources.sh` - passed.
- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default prometheus_unittests browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusWebUI*'` - passed, 4/4 tests.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*:*PrometheusNewTab*:*PrometheusControlPanel*'` - passed, 6/6 tests.
- `cd .context/chromium/src && git diff --check` - passed.
- `git diff --check` - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 16-06 can run the cross-plan WebUI validation/export gate using the new resource scanner and existing focused browser/unit tests.

---
*Phase: 16-prometheus-webui-surfaces-and-new-tab*
*Completed: 2026-07-07*
