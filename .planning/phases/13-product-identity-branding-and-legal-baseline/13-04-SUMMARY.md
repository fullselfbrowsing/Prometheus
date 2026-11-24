---
phase: 13-product-identity-branding-and-legal-baseline
plan: 04
subsystem: branding
tags: [chromium, branding, identity, plutil, smoke-test, nyquist]

requires:
  - phase: 13-product-identity-branding-and-legal-baseline (plan 03)
    provides: Rebuilt Prometheus.app with BRANDING + GRD overrides
  - phase: 13-product-identity-branding-and-legal-baseline (plan 01)
    provides: smoke-launch-prometheus.sh identity gate
provides:
  - Automated Phase 13 identity gate (smoke launch + plutil identity assertions, status=0)
  - Human-verified runtime GUI identity (app menu, window title, About, Dock all read Prometheus)
  - Populated 13-VALIDATION.md Per-Task Verification Map; nyquist_compliant = true
  - CHROMIUM-CHECKOUT.md Phase 13 script-gate + patch-branch record
affects: [14-asset-and-design-system-port, 15-chromium-ui-shell, 24-packaging-release-validation]

tech-stack:
  added: []
  patterns:
    - "Branded smoke gate distinct from the unmodified-baseline gate"
    - "Runtime GRD strings verified by human checkpoint; bundle identity verified by plutil"

key-files:
  created: []
  modified:
    - .planning/chromium/CHROMIUM-CHECKOUT.md
    - .planning/chromium/check-chromium-env.sh
    - .planning/chromium/smoke-launch-prometheus.sh
    - .planning/phases/13-product-identity-branding-and-legal-baseline/13-VALIDATION.md

key-decisions:
  - "Env gate accepts the pinned baseline as an ancestor (not exact HEAD) once branding commits exist on prometheus/phase-13-branding"
  - "Smoke quit logic verifies actual process exit, then SIGTERM, then SIGKILL — osascript exit 0 alone is not trusted for a freshly-registered bundle id"

patterns-established:
  - "Pattern: blocking human-verify for runtime GUI strings that plutil/grep cannot observe"

requirements-completed: [BRAND-01, BRAND-02, BRAND-03, BRAND-04, BRAND-05, BRAND-06, BRAND-07]

duration: 15min
completed: 2026-06-24
---

# Phase 13 (Plan 04): Identity Gate + Human Verification Summary

**Automated Prometheus identity gate (smoke launch + plutil assertions, status=0) plus human-confirmed runtime GUI identity, closing the Phase 13 branding baseline.**

## Performance

- **Duration:** ~15 min (incl. human checkpoint)
- **Tasks:** 2 (1 automated + 1 blocking human-verify)
- **Files modified:** 4

## Accomplishments
- Ran `smoke-launch-prometheus.sh`: Prometheus.app launches, `CFBundleName=Prometheus` and `CFBundleIdentifier=com.fullselfbrowsing.prometheus` asserted via `plutil`, clean exit, `.context/prometheus-launch.status` = `status=0`.
- Populated `13-VALIDATION.md` Per-Task Verification Map (all Phase 13 tasks, requirement → command → status); set `nyquist_compliant: true`, `wave_0_complete: true`.
- Updated `CHROMIUM-CHECKOUT.md` with the Phase 13 script gate and the `prometheus/phase-13-branding` patch-branch record.
- **Human verification approved:** macOS app menu, About item, window title, Dock, and Activity Monitor all read Prometheus; no "Chromium" text in product surfaces.

## Task Commits

1. **Task 1: Run automated identity gate + finalize validation map** — `6cad8e124` (feat)
2. **Task 2: Human visual verification** — checkpoint approved by user (no code commit)

## Files Created/Modified
- `.planning/chromium/CHROMIUM-CHECKOUT.md` — Phase 13 patch branch + smoke gate recorded
- `.planning/chromium/check-chromium-env.sh` — accepts pinned baseline as ancestor (deviation, see below)
- `.planning/chromium/smoke-launch-prometheus.sh` — hardened quit/termination logic (deviation, see below)
- `.planning/phases/13-product-identity-branding-and-legal-baseline/13-VALIDATION.md` — verification map populated, nyquist_compliant

## Decisions Made
- Bundle-level identity is machine-verified (plutil); runtime GUI strings (GRD-rendered) require the human checkpoint — they cannot be observed by plutil/grep.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Env gate blocked once branding commits exist**
- **Found during:** Task 1 (smoke preflight)
- **Issue:** `check-chromium-env.sh` required HEAD == pinned baseline `0e8499df...`; the `prometheus/phase-13-branding` branch has 2 branding commits on top, so the strict equality check failed.
- **Fix:** Relaxed to accept the pinned baseline as an ancestor of HEAD (baseline still anchored; branding patches tracked).
- **Verification:** Smoke preflight passes on the branding branch; gate still fails if the baseline is absent from history.
- **Committed in:** `6cad8e124`

**2. [Rule 3 - Blocking] osascript quit race for freshly-registered bundle id**
- **Found during:** Task 1 (smoke launch)
- **Issue:** `osascript ... to quit` returned exit 0 for `com.fullselfbrowsing.prometheus` even when the quit was not delivered (Launch Services registration race in a non-interactive agent session).
- **Fix:** Verify the process actually exited within a grace period, then fall back to SIGTERM, then SIGKILL after the bounded wait. A launched-and-force-terminated app still counts as a passing identity smoke.
- **Verification:** Smoke exits 0 deterministically with `status=0`; no orphaned process.
- **Committed in:** `6cad8e124`

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking). No scope creep; both necessary to make the branded gate run deterministically.

## Issues Encountered
- None beyond the two deviations above.

## User Setup Required
None.

## Next Phase Readiness
- Prometheus identity baseline is established and human-verified. Phase 14 (asset & design-system port) can now slot ported icons/fonts into the branded app; Phase 24 packaging validates the notices ship.
- Carry-forward note: a stale `Chromium.app` remains beside `Prometheus.app` in the gitignored `out/Default` (incremental build leftover) — harmless, can be pruned on a clean rebuild.

---
*Phase: 13-product-identity-branding-and-legal-baseline*
*Completed: 2026-06-24*
