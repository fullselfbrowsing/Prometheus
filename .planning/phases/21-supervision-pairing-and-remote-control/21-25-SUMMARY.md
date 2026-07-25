---
phase: 21-supervision-pairing-and-remote-control
plan: 25
subsystem: built-app-supervision-integration
tags: [chromium, supervision, native-dialogs, gateway, mcp, smoke, teardown, privacy]

requires:
  - phase: 21-24
    provides: Exact browser-composition binding for the validated two-slot test handoff
provides:
  - Actual-widget, exact-browser, one-use supervision dialog automation for validated test launches
  - Built Prometheus process proof with two dashboard viewers and one independent MCP consumer
  - Real dashboard actions, shared capture/diff state, independent cursors, retention-gap resync, and controller conflict
  - Production dispatcher readiness, pending-diff cancellation, ordered unbind/shutdown, and post-unbind typed failure proof
affects: [21-26, phase-21-closeout, built-app-supervision-smoke]

tech-stack:
  added: []
  patterns:
    - Post-show weak-widget automation that traverses normal dialog accept/cancel callbacks
    - Owner-only 0600 bootstrap plus separately scoped and scrubbed external-client challenge
    - One production capture hub shared by independent dashboard and Agent consumers
    - Dialog/test-handoff/dashboard/Agent/gateway teardown ordering

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_mcp_integration_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_confirmation_browsertest.cc
    - tools/prometheus-mcp/smoke-browser.sh
    - tools/prometheus-mcp/test/fixture-server.mjs
    - tools/prometheus-mcp/test/smoke-client.mjs
    - tools/prometheus-mcp/test/smoke.test.mjs
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Construct and show the real native supervision widget before posting any automated response, close over only a weak widget, exact Browser, and closed dialog kind, and use the ordinary dialog accept/cancel path."
  - "Install dialog automation only after the validated first exact-target redemption and clear it before test composition, dashboard dispatch, Agent dispatch, or gateway teardown."
  - "Pass the 256-bit smoke challenge only to the separate client process, scrub every smoke-only variable from bridge children, and recursively denylist all challenge/code/session/bearer/nonce sentinels."
  - "Permit a successful action completion to observe only its own monotonically advanced capture sequence while retaining exact owner, controller lease, document, and authority-generation fences at admission and completion."
  - "Treat post-resync dashboard terminalization as a typed lifecycle outcome: require at least one explicit end and accept only exact empty-result UNAVAILABLE for a peer already closed by production lifecycle cleanup."

patterns-established:
  - "Test automation is an after-widget response seam, never a direct service/action callback and never a provider or vault dialog hook."
  - "The built smoke uses direct authenticated dashboard requests while keeping the five MCP compatibility routes authority-free."
  - "Production shutdown clears dialog automation and test handoff before dashboard waiters/dispatcher, Agent compatibility dispatch, and gateway IO."

requirements-completed: [SUP-01, SUP-02, SUP-03, SUP-04, SUP-05]

duration: 3h
completed: 2026-07-24
---

# Phase 21 Plan 25: Built-App Supervision Integration Summary

**The signed Prometheus app now proves the complete local supervision lifecycle with two dashboard viewers, one MCP consumer, actual native confirmation widgets, production dispatchers, secure test-only bootstrap scope, and ordered teardown.**

## Performance

- **Duration:** 3h
- **Started:** 2026-07-25T01:30:00Z
- **Completed:** 2026-07-25T04:30:02Z
- **Tasks:** 3
- **Files modified:** 10 nested native source/test files, 5 root smoke/verifier files, and 4 ordered patch exports

## Accomplishments

- Added a narrow supervision-only dialog automation contract that observes only the exact Browser and closed enable-control/remote-action kind after the real widget is visible, consumes one scripted response, and follows the normal native callback and revalidation path.
- Proved mismatch, replay, removed-widget, wrong-kind, and provider/vault non-interference behavior; automation is installed only from the validated bootstrap/redemption composition and cleared first during every teardown path.
- Generated a random 256-bit challenge, wrote the exact bootstrap with exclusive creation and 0600/no-follow validation, launched the built app with the existing production gateway, passed the challenge only to a separate client, and scrubbed smoke authority from bridge child environments and captured output.
- Exercised two dashboard viewers and one independent MCP consumer against one real tab/document capture hub, including independent baselines/acks, verified mutation, shared diffs, controller conflict, ordinary and consequential actions through real dialogs, navigation, retention overflow, typed resync, fresh shared baselines, end/terminal cleanup, and compatibility-route authority privacy.
- Added a production integration browser test that observes supervision health transition from sanitized `not_ready` to `ready`, binds two dashboards plus MCP through `PrometheusBrowserMainExtraParts`, cancels one pending diff exactly once, restores typed dashboard/Agent failures after ordered unbind, and sees no late dialog callback.
- Extended the focused verifier with secure-smoke guards, the post-action capture regression, the production integration test, and a static order check for dialog automation, test composition, dashboard dispatcher, Agent dispatcher, and gateway shutdown.

## Task Commits

Each TDD task was committed in nested Chromium and exported into the ordered root patch chain; final self-check added one narrow test-fixture correction:

1. **Task 1 (RED): Freeze the actual-dialog automation contract** — nested `a80b5f43e9`, root `e5547c4f1`, patch `0065`
2. **Task 2 (GREEN): Implement actual-dialog automation and drive the built two-viewer/MCP lifecycle** — nested `e328fef76d`, root `00c0c54bb`, patch `0066`
3. **Task 3 (GREEN): Prove production binding and shutdown** — nested `b49829295a`, root `d235ace11`, patch `0067`
4. **Closeout correction: Compile the owning integration object and acknowledge both production viewer cursors before opening the pending diff** — nested `9b541ee6a9`, root `b5ddfec46`, patch `0068`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved action completion after its own verified DOM mutation**

- **Found during:** Task 2 built-app action smoke
- **Issue:** A successful real Agent action advanced the shared capture sequence before its completion callback, so the original completion fence rejected the action's own verified mutation even though Browser, profile, tab, document, owner, controller lease, and authority generation were unchanged.
- **Fix:** Added a completion-only capture-advance mode. Admission, confirmation, and pre-dispatch checks remain exact; completion accepts only monotonic sequence advance while every authority and document fence remains exact.
- **Files modified:** `prometheus_supervision_action_controller.h`, `.cc`, and `_unittest.cc`
- **Verification:** `PrometheusSupervisionActionControllerTest.SuccessfulRouteMayAdvanceCaptureBeforeCompletion` passed; existing target/navigation/owner invalidation coverage remained green.
- **Committed in:** `e328fef76d`

**2. [Rule 3 - Blocking] Scoped bootstrap file reads around Chromium blocking restrictions**

- **Found during:** Task 2 built-app launch
- **Issue:** The validated bootstrap is inspected after browser blocking restrictions are active, causing the test launch to stop before handoff installation.
- **Fix:** Added `base::ScopedAllowBlockingForTesting` only inside the explicit test-bootstrap inspect/read path. Ordinary launches never invoke those callbacks.
- **Files modified:** `prometheus_supervision_test_bootstrap.cc`
- **Verification:** The final signed-app smoke passed while production-inert launch gating and ordinary/official non-bind guards remained intact.
- **Committed in:** `e328fef76d`

**3. [Rule 3 - Blocking] Generated fresh exact-document refs for retention overflow**

- **Found during:** Task 2 two-viewer retention-gap smoke
- **Issue:** Repeating one retained button reference correctly triggered Agent repeat protection before enough real mutations accumulated to overflow the bounded diff history.
- **Fix:** The deterministic fixture replaces the clicked button with an equivalent node after each mutation, and the external MCP consumer refreshes the real DOM snapshot/reference for every verified click.
- **Files modified:** `fixture-server.mjs`, `smoke-client.mjs`
- **Verification:** Both dashboard viewers independently received `RESYNC_REQUIRED`, then obtained fresh baselines with the same newer document epoch/sequence.
- **Committed in:** root `00c0c54bb`

**4. [Rule 1 - Bug] Made the final production pending-diff proof runnable**

- **Found during:** Final evidence-log self-check
- **Issue:** The focused linker carried a stale MCP integration object, so the first nominal 7-case run selected only the confirmation suite. After exact-compiling the owning object, the production case truthfully failed because its initial viewer baselines had not been acknowledged and the requested diff therefore completed immediately instead of becoming a long poll.
- **Fix:** Added exact compilation of `prometheus_mcp_integration_browsertest.o` to the focused verifier and acknowledged both independent dashboard baselines before opening the production pending diff.
- **Files modified:** `prometheus_mcp_integration_browsertest.cc`, `.planning/chromium/verify-phase-21.sh`
- **Verification:** The corrected filter selected 8 runnable cases, including `SupervisionProductionBindingCancelsPendingDiffBeforeGatewayShutdown`, and passed 8/8 with all protected hashes unchanged.
- **Committed in:** nested `9b541ee6a9`, root `b5ddfec46`

---

**Total deviations:** 4 auto-fixed issues.
**Impact on plan:** The fixes were required to exercise the planned real production paths. They did not broaden automation, authority, or production launch scope.

## Issues Encountered

- The focused verifier builds a temporary Blink module and browser-test binary but does not relink the signed app. The app's production component objects were therefore refreshed from their exact Siso query commands, the component dylib was relinked/ad-hoc signed, and only the browser process received the focused Blink library path; the reviewed Blink dylib stayed byte-identical.
- After both retention-gap baselines are delivered, production lifecycle cleanup can close one dashboard before its explicit end request. The smoke accepts only an explicit `{ended:true}` or exact typed `UNAVAILABLE` with an empty result, and still requires at least one explicit end plus a later typed-unavailable heartbeat.

## Test Evidence

- Task 1 RED selected the three retained dialog-automation browser cases, failed only the two missing-behavior cases, passed the provider/vault non-interference case, and had no crash; the GREEN rerun passed all 3/3.
- The action completion regression passed 1/1.
- `node --test tools/prometheus-mcp/test/smoke.test.mjs` passed 10/10.
- The final relinked signed-app `bash tools/prometheus-mcp/smoke-browser.sh` passed with two dashboard viewers, one MCP consumer, real enable/action dialogs, shared mutations/diffs, independent acknowledgements, conflict, navigation, retention-gap resync, cleanup, and privacy sentinel scans.
- The required focused browser verifier selected and passed 8/8 production-binding and confirmation tests.
- `node --test tools/prometheus-mcp/test/native-client.test.mjs tools/prometheus-mcp/test/smoke.test.mjs` passed 21/21 with zero failures, cancellation, skips, or todos.
- Patches `0065`, `0066`, `0067`, and `0068` have stable patch IDs `e137437b1579d48435dab84bb694e98b4c89c12c`, `c3ad68aad8184660795c181b0609293249172ece`, `8b3a7735f2ffae53f7a3acd699058655bd7dbf73`, and `beac400f65e6049482262a8cc4dd0b98bf732da6`; each is byte-identical to a fresh export of its nested commit.
- Patch SHA-256 values are `e64b70088bad7173b7cfa145a9a86a8e3baa96fdb63b7735a8685a2aa0e107f2`, `7a21fed55ff46f0b9b460d26cbd4e0b255ebd88c25f35d574892d4e90e1ae89a`, `76558400043a0d5d7a5a6767d5e4ee973fac379c3c75cfb6cdd363623d397dda`, and `09563a61e4fd8948251546bb97e235908c5c43d9f786e55e89eb84fafb16a8e5`.
- Applying `0065–0068` through an isolated temporary index at nested base `6f86487de6` produced exact tree `e65ae13f630f2b8fff2543b9c70521565476b32d`, matching nested Chromium HEAD.
- `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Reviewed Blink dylib remained `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; its TOC remained `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`; framework resources remained `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`.

## User Setup Required

None. The automation/handoff remains absent unless an eligible non-official disposable runtime-test launch supplies both the existing runtime-test switches and the exact owner-only supervision bootstrap.

## Next Phase Readiness

Plan 21-26 can run the complete Phase 21 verification matrix and publish milestone closeout evidence. Plan 21-25 leaves no known blocker.

## Self-Check: PASSED

- FOUND: nested commits `a80b5f43e9`, `e328fef76d`, `b49829295a`, and `9b541ee6a9`
- FOUND: root task/correction commits `e5547c4f1`, `00c0c54bb`, `d235ace11`, and `b5ddfec46`
- FOUND: ordered non-empty patches `0065`, `0066`, `0067`, and `0068`
- VERIFIED: intended dialog RED, 3/3 dialog GREEN, 1/1 action regression, 10/10 smoke static suite, signed-app live smoke, 8/8 focused browser gate, and 21/21 final Node gate
- VERIFIED: actual widgets, exact Browser/kind/order, provider/vault non-interference, two dashboards plus MCP, shared hub, independent cursors, controller conflict, real actions, navigation/resync, production readiness, pending cancellation, ordered teardown, post-unbind typed failure, credential privacy, patch identity/replay, and byte-identical protected artifacts

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
