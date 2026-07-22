---
phase: 21-supervision-pairing-and-remote-control
plan: 15
subsystem: chromium-supervision-native-consent
tags: [chromium, supervision, views, consent, remote-control, authority, privacy, tdd]

requires:
  - phase: 21-14
    provides: Exact-browser typed Agent action admission and one bounded consequential confirmation slot
  - phase: 20-08
    provides: Existing browser-native runtime and vault confirmation dialogs
provides:
  - Browser-native safe-default approval before a redeemed viewer can gain control
  - Browser-native allow-once consent before each consequential remote action
  - Fresh exact Browser/tab/document/owner/controller/expiry/generation revalidation after approval
  - Dependency-neutral sanitized dialog API with no backend authority or raw action values
affects: [21-16, 21-17, 21-18, 21-19, 21-23, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Native dialog launchers receive display-safe closed models while backend services retain all authority
    - Safe actions own initial focus and Escape/window-close paths converge on one denied result
    - Consequential approval is bound to one pending action ID and followed by complete fresh admission

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_confirmation_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep the supervision dialog API sanitized and dependency-neutral; the profile service and action controller retain authority and perform every post-result check."
  - "Make `Keep view only` and `Block action` the initial-focus and Escape defaults, with close and launch failure producing the same exactly-once denial."
  - "Bind consequential consent directly to the controller's pending action ID and remove the public manual confirmation resolver so no dashboard path can pre-approve a mutation."
  - "Leave vault-shaped work outside supervision action classification and preserve its separate existing native confirmation boundary."

patterns-established:
  - "One-way native consent: backend creates a bounded display model, Views returns only approved or denied, and backend revalidates fresh authority."
  - "Approval is not authority: session, target, immutable nonempty owner, controller lease, expiry, document, sequence, and generation must still match after consent."
  - "Closed consequential display: category, client, target, site, expiry, and permission boundary are allowed; raw text, key, option, file, ref, and URL values are forbidden."

requirements-completed: []
requirements-progressed: [SUP-03, SUP-04]

duration: 1h27min
completed: 2026-07-22
---

# Phase 21 Plan 15: Native Supervision Consent Summary

**Remote control and every consequential remote action now require a visible browser-native safe-default approval followed by fresh exact-target authority validation, while vault confirmation remains an independent boundary.**

## Performance

- **Duration:** 1h27min
- **Started:** 2026-07-22T14:36:59Z
- **Completed:** 2026-07-22T16:04:03Z
- **Tasks:** 3
- **Files modified:** 12 source, test, build, and verifier files; 3 ordered patch exports

## Accomplishments

- Added a closed, sanitized `PrometheusSupervisionDialogModel`/result/callback/launcher API and split Views build ownership into an acyclic API target plus native implementation.
- Implemented exact `Enable remote control?` and `Confirm remote action` Views dialogs with required copy and rows, safe secondary-button focus, and exactly-once denial for Escape and window close.
- Kept redeemed viewers view-only until native enable approval succeeds and the profile service freshly revalidates the exact session, URL, `WebContents`, document epoch, expiry, immutable nonempty redemption owner, live owner, authority generation, and sole-controller state.
- Bound consequential consent to one pending action ID, then repeated exact Browser/tab/session/owner/controller/lease/document/sequence/generation admission before route construction and again at typed Agent dispatch.
- Removed the externally resolvable confirmation path: consequential actions launch native consent automatically, and denied, stale, late, unavailable, stopped, expired, torn-down, or changed-authority callbacks dispatch zero actions.
- Kept raw action values out of dialog models and view labels, rejected vault-shaped action payloads, and left the existing vault confirmation flow untouched.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Specify native supervision consent dialogs** — nested `7f641da2f3`, root `15221b23c`, patch `0036`
2. **Task 2 (GREEN): Require native approval for remote control** — nested `8c91e4a5f7`, root `eaa5d2015`, patch `0037`
3. **Task 3 (GREEN): Gate consequential actions with native consent** — nested `cc05b75088`, root `d75301661`, patch `0038`

## Files Created/Modified

- `prometheus_runtime_dialogs.h` — Closed supervision dialog kinds, sanitized model, two-value result, one-shot callback, and narrow launcher type.
- `prometheus_runtime_dialogs.cc` — Native enable-control and consequential-action dialogs, bounded UTF-8 validation, exact copy/rows, safe focus, and exactly-once reply handling.
- `prometheus_supervision_profile_service.h/.cc` — Injected/default dialog launcher, pending enable snapshot, lifecycle invalidation, and post-approval controller-lease creation.
- `prometheus_supervision_action_controller.h/.cc` — Automatic allow-once launch, pending-action callback binding, full fresh revalidation, and removal of manual approval resolution.
- `prometheus_supervision_profile_service_unittest.cc` — Approval, denial, empty/changed owner, expiry, changed document, competitor, and action lifecycle coverage.
- `prometheus_supervision_action_controller_unittest.cc` — Confirmation approval/denial/unavailable/stale/late-result and vault non-bypass coverage.
- `prometheus_supervision_confirmation_browsertest.cc` — Exact copy, row order, safe focus, Escape/close, raw-value absence, and real native-dialog-to-Agent-dispatch integration.
- Browser and Views `BUILD.gn` files — Acyclic dialog API/implementation ownership and browser-test linkage.
- `.planning/chromium/verify-phase-21.sh` — Exact dialog compile/link synthesis, focused test selection, GN-cycle checks, privacy guards, and artifact-integrity checks.
- `patches/0036` through `0038` — Stable ordered nested Chromium patch exports.

## Decisions Made

- Views owns presentation only. The dialog model carries bounded client, target, site, expiry, category, and permission-boundary labels; it carries no session, lease, owner, document, profile, code, renderer, or action-value authority.
- Native approval never repairs or transfers authority. An empty redemption owner terminalizes the viewer, and owner loss or replacement requires a new pairing rather than adopting the current owner.
- Control approval snapshots the exact visible target and service generation but creates no lease until every field is still current after the dialog result.
- Consequential approval is allow-once for the bound pending action only. Route construction and the existing Agent action engine remain the sole mutation dispatcher and repeat their own live checks.
- Vault is not a consequential-action subtype. Vault-shaped or ambiguous supervision payloads fail classification and cannot inherit control or allow-once approval.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Located the browser integration test in the browser-owned Prometheus target**

- **Found during:** Task 1 build wiring
- **Issue:** The plan's file list placed the integration test under `ui/views/prometheus`, but the test exercises profile/action services and belongs to the existing browser Prometheus browser-test target; placing it in Views would weaken the intended one-way dependency split.
- **Fix:** Added `chrome/browser/prometheus/prometheus_supervision_confirmation_browsertest.cc` while keeping the dialog implementation under Views and splitting out a narrow `runtime_dialogs_api` target.
- **Verification:** GN/source guards prove the browser target depends on the API, the Views implementation depends on the API, and neither dialog target depends back on supervision services.
- **Committed in:** `7f641da2f3`

**2. [Rule 3 - Blocking] Isolated the browser fixture from unrelated initial-WebUI startup**

- **Found during:** Task 2 browser GREEN gate
- **Issue:** The browser harness repeatedly timed out in `WaitUntilInitialWebUIPaintAndFlushMetricsForTesting` before any supervision test body ran.
- **Fix:** Disabled `features::kInitialWebUI` only in this native-dialog fixture; the product implementation remains unchanged and uses no WebUI consent path.
- **Verification:** Both focused enable-control browser tests and all four final supervision confirmation browser tests execute and pass.
- **Committed in:** `8c91e4a5f7`

---

**Total deviations:** 2 auto-fixed blocking test/build integration issues.
**Impact on plan:** Both changes preserve the planned browser-native, one-way dependency boundary and make the intended integration tests executable; no product scope or authority surface was expanded.

## Issues Encountered

- Chromium's browser-test startup initially blocked before test execution on unrelated initial-WebUI paint. Fixture-local feature isolation restored deterministic native-dialog coverage.
- The Chromium formatter touched adjacent pre-existing formatting in Task 3 files. Review confirmed those additional changes are whitespace-only; final static, diff, compile, link, and focused runtime gates remain clean.

## Test Evidence

- RED gate: 3 focused browser tests were selected and failed only their intended unimplemented dialog assertions, with no crash, fatal, empty selection, or infrastructure failure.
- Enable-control GREEN: 3 `PrometheusSupervisionProfileServiceTest.EnableControl*` tests and 2 `PrometheusSupervisionConfirmationBrowserTest.EnableControl*` tests passed.
- Final native consent GREEN: all 4 `PrometheusSupervisionConfirmationBrowserTest.*` integration tests passed, including real request → native dialog → approval → fresh validation → exactly one Agent dispatch and Escape → zero additional dispatch.
- Controller regressions: 5 focused `Confirmation*`/`Vault*` tests passed, including deny, unavailable launcher, stale generation, late callback, exact-once approval, and vault-shaped rejection.
- Profile action regressions: all 5 focused `PrometheusSupervisionProfileServiceTest.Action*` tests passed after the final wiring.
- Static guards prove exact copy, raw-value absence, no backend include/dependency cycle, no manual/dashboard confirmation resolver, no alternate dispatcher, and no vault bypass.
- Exact object compiles, focused link, browser-test discovery, code signing, verifier shell syntax, and root/nested `git diff --check` passed.
- All three exported patches have stable patch IDs identical to nested commits `7f641da2f3`, `8c91e4a5f7`, and `cc05b75088`.
- Reviewed `.ninja_log`, `.ninja_deps`, Blink dylib, and Blink TOC hashes remained byte-identical through verification.

Human UAT was not run and is not claimed. Browser-owned supervision state projection and visible persistent UI remain for Plans 21-16 onward.

## User Setup Required

None. No credentials, packages, listeners, dashboards, or external configuration are required.

## Next Phase Readiness

Plan 21-16 can project the now-authoritative view-only/controller/pending-action state into browser-owned tab state. The consent paths expose closed metadata only, cancel safely across lifecycle loss, and leave all authority in the owning profile service and action controller.

SUP-03 and SUP-04 remain phase-level in progress until the state projection, visible browser UI, built-app smoke, and Phase 21 closeout plans are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `7f641da2f3`, `8c91e4a5f7`, and `cc05b75088`
- FOUND: ordered root patches `0036`, `0037`, and `0038`
- VERIFIED: 3-test RED, 3-test enable-service GREEN, 2-test enable-browser GREEN, 5-test controller/vault, 5-test profile-action, and 4-test final browser gates
- VERIFIED: native safe defaults, post-approval authority checks, exact Agent dispatch, vault non-bypass, privacy guards, acyclic linkage, patch identity, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
