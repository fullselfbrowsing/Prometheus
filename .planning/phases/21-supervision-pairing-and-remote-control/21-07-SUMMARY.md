---
phase: 21-supervision-pairing-and-remote-control
plan: 07
subsystem: browser-supervision-capture
tags: [chromium, browser, mojo, apc, fanout, lifecycle, privacy, tdd]

requires:
  - phase: 21-06
    provides: Document-scoped Blink dirty/overflow endpoint with browser-owned host registration
provides:
  - Sole browser-owned exact-target/current-document Mojo and APC capture hub
  - Bounded generic Dashboard and Agent-compatibility consumers with independent ack, expiry, revoke, and resync state
  - Shared baseline/diff history with browser-derived session, target, document, and sequence stamps
  - Real renderer-to-browser fanout, navigation, disconnect, lifecycle, and secret-redaction proof
affects: [21-08, 21-09, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - One WebContents-scoped hub owns every renderer endpoint, APC capture, safe tree, epoch, and retained diff batch
    - Consumer cursors reference shared bounded history while ack, expiry, revoke, lag, and resync remain consumer-local
    - Browser capture performs bounded two-pass raw-form-value scrubbing before safe projection

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Make PrometheusSupervisionCaptureHub the sole Mojo/APC owner; generic consumers receive only opaque browser-created IDs and safe stamped baseline/diff values."
  - "Retain one baseline and bounded shared diff history per document epoch while maintaining independent offered, read, ack, expiry, revoke, lag, and resync state per consumer."
  - "Collect bounded raw form values before projection and scrub every canonical and accessibility-derived copy so password, payment, and OTP data cannot survive feature-gated APC output."
  - "Ignore speculative frame creation and generation-fence deferred subframe recovery so committed navigation, endpoint loss, and frame deletion converge without duplicate binding or capture."

patterns-established:
  - "One dirty epoch schedules at most one strict APC capture, and every attached consumer reads references to the same resulting baseline or diff."
  - "Document change, renderer loss, target close, and last detach clear shared state before rebinding or release and force consumer-local fresh baselines."
  - "Focused browser verification can overlay an exact temporary Blink modules dylib through rpath while proving reviewed output and Ninja metadata remain byte-identical."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-03]

duration: 2h52min
completed: 2026-07-22
---

# Phase 21 Plan 07: Sole Browser Supervision Capture Hub Summary

**Every supervision consumer on one target now shares one exact-document renderer binding and APC capture stream while retaining independent bounded delivery state, and real browser tests prove that the path fails closed across mutation, navigation, disconnect, and secret-bearing form content.**

## Performance

- **Duration:** 2h52min
- **Started:** 2026-07-22T03:18:23Z
- **Completed:** 2026-07-22T06:10:56Z
- **Tasks:** 3
- **Files modified:** 13 including exported patches, planning state, and this summary

## Accomplishments

- Added `PrometheusSupervisionCaptureHub`, a `WebContentsObserver` keyed to one browser target whose private frame entries alone own the Blink supervision control remotes, browser host receivers, `Enable`/`Disable` lifecycle, and strict APC calls.
- Added generic Dashboard and Agent-compatibility attachment APIs that expose only browser-created consumer IDs and safe stamped deliveries. No consumer receives Mojo endpoints, renderer identity, capture authority, or a way to call `Enable`.
- Built browser-derived session, stable-target, document-epoch, and monotonic-sequence stamps over one shared safe baseline and diff history. Identical captures emit no batch; changed captures advance exactly one shared sequence.
- Enforced 500-node/200 KiB baselines, 128-operation/64 KiB diffs, and 32-batch/256 KiB retained history. Expiry, revoke, ack, cursor, lag, and resync transitions remain independent for each consumer.
- Made overflow, retention gaps, invalid stamps, capture failure, document replacement, renderer loss, and stale callbacks fail closed to a consumer-specific fresh baseline without advancing another consumer.
- Added bounded two-pass form-value scrubbing before projection so password, payment-card, and OTP values are removed from both canonical form fields and accessibility-derived labels, text, names, placeholders, and options.
- Added six real browser fixtures using an embedded-server page whose own fetch-controlled script performs the mutation. Two consumers receive the same safe diff from one Blink dirty callback and one APC recapture without test-side DOM injection.
- Covered primary navigation, subframe replacement, renderer disconnect/rebind, target close, and last-consumer detach with exact enable/disable/capture counts and stale-generation rejection.
- Extended the verifier with exact hub/factory recompilation, browser ownership/privacy guards, direct source audits, a focused temporary Blink modules dylib, reviewed-artifact hashing, and exact patch-integrity checks.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Freeze sole renderer ownership and independent generic-consumer state** - nested `5fd340b393`; patch tracking `d7d386cd9`
2. **Task 2 (GREEN): Implement one exact-document Mojo/APC capture state machine** - nested `a2e4ee4869`; patch tracking `fe49f7636`
3. **Task 3 (GREEN): Prove real DOM recapture, fanout, navigation, and disconnect** - nested `10d8c0f63c`; patch tracking `d179fcf4a`

## Files Created/Modified

- `prometheus_supervision_capture_hub.h` / `.cc` - Sole browser-owned frame binding, APC projection, epoch/history, bounded consumer state, and lifecycle implementation.
- `prometheus_supervision_capture_hub_unittest.cc` - Ownership, shared capture, no-op, diff, ack, lag, overflow, expiry, revoke, last-detach, navigation, and stale-callback coverage.
- `prometheus_supervision_capture_hub_browsertest.cc` - Real server-authored mutation, two-consumer fanout, redaction, navigation, subframe, renderer-loss, target-close, and detach coverage.
- Browser and Views `BUILD.gn` files - Production, native-test, and browser-test target registration.
- `.planning/chromium/verify-phase-21.sh` - Exact capture-hub recompilation/linkage, temporary Blink module overlay, focused browser/native/Blink modes, privacy/ownership audits, and immutable-output checks.
- `patches/0016-test-21-07-specify-sole-supervision-capture-hub.patch` - Exact exported RED contract commit.
- `patches/0017-feat-21-07-implement-shared-supervision-capture-hub.patch` - Exact exported hub state-machine GREEN commit.
- `patches/0018-feat-21-07-prove-real-supervision-capture-fanout.patch` - Exact exported real-browser and lifecycle GREEN commit.

## Decisions Made

- The hub is the only production object in the supervision/browser surface allowed to own `PrometheusSupervisionDocument`, its receiver, APC options, or the APC call. Viewer, MCP, and Agent renderers remain downstream consumers only.
- Consumer attachment never rebinds the renderer. The first consumer starts one document generation; later consumers join its current baseline/history; the last detach performs the sole disable and state release.
- The hub validates the current primary HTTP(S) document through an exact `WeakDocumentPtr` before accepting APC output, and rejects a result whose document token or frame map no longer matches.
- One shared retained history bounds total capture storage. Per-consumer state stores cursors and acknowledgements rather than copied trees, and only the lagging consumer is forced to resync after a gap.
- APC feature defaults are not a sufficient privacy boundary: raw form values are collected under the same fixed bounds and all duplicate representations are scrubbed before projection.
- Speculative frame creation does not establish a renderer generation. Committed subframe navigation rotates the epoch, and a generation-fenced delayed recovery lets endpoint disconnect ordering settle without duplicating an enable or APC capture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Built an isolated focused Blink modules dylib for the live browser fixture**

- **Found during:** Task 3 browser gate
- **Issue:** The reviewed `out/Default/libblink_modules.dylib` predated Plan 21-06 and did not export the supervision document binder, so every browser binding disconnected and retried instead of reaching the real renderer endpoint.
- **Fix:** Linked only the exact supplement, generated Mojo, and modules-initializer objects into a sibling `out/Default/phase21-focused/blink-modules/libblink_modules.dylib`, codesigned it, verified its binder export, and prepended that isolated directory to the focused browser binary's rpath. The reviewed dylib, TOC, and Ninja metadata are hashed before and after every run.
- **Files modified:** `.planning/chromium/verify-phase-21.sh`
- **Verification:** All six real browser fixtures pass; the reviewed Blink dylib, TOC, `.ninja_log`, and `.ninja_deps` hashes remain unchanged.
- **Committed in:** `d179fcf4a` (Task 3 patch tracking commit)

**2. [Rule 2 - Missing Critical] Removed feature-gated and accessibility-derived secret copies from APC output**

- **Found during:** Task 3 real redaction fixture
- **Issue:** Payment/OTP redaction features were disabled in the focused build, and APC duplicated raw payment and OTP values into accessibility-derived container names even when canonical form values were cleared.
- **Fix:** Added a bounded first pass that collects raw form values and a second pass that clears canonical values plus matching label, text, field-name, placeholder, and option copies before safe projection. Collection overflow fails the capture closed.
- **Files modified:** `prometheus_supervision_capture_hub.cc`, `prometheus_supervision_capture_hub_browsertest.cc`
- **Verification:** Password, payment, and OTP sentinels are absent from both baseline and diff in the real browser fixture.
- **Committed in:** `10d8c0f63c` / `d179fcf4a` (Task 3)

**3. [Rule 1 - Bug] Coalesced speculative-frame and renderer-deletion lifecycle ordering**

- **Found during:** Task 3 subframe and renderer-disconnect fixtures
- **Issue:** Speculative frame creation and overlapping frame deletion/Mojo disconnect callbacks could rotate or recover the same document generation twice; a killed main renderer could delete its frame before the posted disconnect callback.
- **Fix:** Ignored speculative `RenderFrameCreated`, let committed subframe navigation own epoch rotation, made subframe disconnect immediately fail closed then recover through a generation-fenced delay, and made main-frame deletion start the same fail-closed epoch transition.
- **Files modified:** `prometheus_supervision_capture_hub.cc`, `prometheus_supervision_capture_hub_browsertest.cc`
- **Verification:** The subframe test observes the exact expected four enables, two disables, and two captures; all navigation, renderer-crash, target-close, and last-detach fixtures pass together.
- **Committed in:** `10d8c0f63c` / `d179fcf4a` (Task 3)

---

**Total deviations:** 3 auto-fixed issues (1 blocking verification issue, 1 missing privacy boundary, 1 lifecycle bug).
**Impact on plan:** All fixes were necessary to exercise the planned real path and enforce its privacy/lifecycle invariants. No downstream viewer, MCP, Agent renderer, or new authority surface was added.

## Issues Encountered

- The RED browser fixture initially linked a stale Agent profile-factory object; the verifier now recompiles that exact production dependency before linking so the retained RED failures reach only intended hub assertions.
- `ControllableHttpResponse` must be constructed in `SetUpOnMainThread` before the embedded server starts. Moving construction to the fixture lifecycle produced the intended server-controlled, page-authored mutation path.
- Literal shell command substitutions in the focused linker assembly and an `nm | rg -q` pipefail false negative were corrected by using the generated symbol manifest as the authoritative export check.

## Test Evidence

- Native RED gate - all 11 hub fixtures selected and failed only their intentional ownership/state assertions.
- Browser RED gate - all 3 initial fixtures selected and failed only their intentional hub assertions after exact dependency recompilation.
- Task 2 native GREEN gate - all 11 hub fixtures passed through the exact direct compile/link path.
- Final browser gate - all 6 `PrometheusSupervisionCaptureHubBrowserTest.*` fixtures passed across real mutation fanout, primary navigation, subframe replacement, renderer disconnect, target close, and last detach.
- Final combined native gate - all 27 hub, supervision projection, and supervision diff fixtures passed.
- Final Blink gate - all 12 `PrometheusSupervisionDocumentSupplementTest.*` fixtures passed against the focused generated-Mojo/renderer path.
- Ownership/privacy audit - the hub source contains exactly one production `Enable`, one APC call, one renderer remote, and one host receiver; no viewer, MCP, or Agent production file owns those facilities.
- Injection audit - production and the browser fixture contain no `ExecJs`, `EvalJs`, `ExecuteScript`, injected `MutationObserver`, raw mutation-field access, or HTML serialization path.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Reviewed Blink artifacts remained immutable - dylib hash `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; TOC hash `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patch identity - patches 0016, 0017, and 0018 have stable IDs `fab348625aeb20b0954c3350f97ec0d3cd2849f6`, `29692997c94f28e2419bb1a1f90d56a4522e631b`, and `a7f75fedc842701635d1cf2380d0cc217cb11bdd`, exactly matching their nested commits.
- Task 3 exact patch application produced tree `40583ec3b04b323e095f93fe4ffcfd6d7c2bfcdd`, identical to the nested commit tree, and reverse application passed.
- Root and nested `git diff --check` passed, and both implementation repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan establishes the shared browser capture primitive with automated native, Blink, and real-browser acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-08 can attach the dashboard and Agent compatibility delivery surfaces to this generic hub without giving either surface a renderer endpoint, `Enable` call, APC capture path, or duplicate document observer.

No blockers or threat flags remain. SUP-01, SUP-02, and SUP-03 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: all four capture-hub source/test artifacts plus both live GN registrations and verifier wiring
- FOUND: nested RED/GREEN commits `5fd340b393`, `a2e4ee4869`, and `10d8c0f63c`
- FOUND: matching non-empty exported patches `0016`, `0017`, and `0018` with exact stable identities
- VERIFIED: 11-test native RED, 3-test browser RED, 11-test Task 2 GREEN, 6-test final browser, 27-test combined native, and 12-test final Blink gates
- VERIFIED: source ownership/privacy, reviewed-artifact immutability, patch application/reversal, and exact metadata hashes
- VERIFIED: root and nested implementation repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
