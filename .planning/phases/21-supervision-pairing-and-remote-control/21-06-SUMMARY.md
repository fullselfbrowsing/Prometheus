---
phase: 21-supervision-pairing-and-remote-control
plan: 06
subsystem: blink-supervision-document
tags: [chromium, blink, mojo, mutation-observer, lifecycle, privacy, tdd]

requires:
  - phase: 21-05
    provides: One safely composed regular-profile supervision owner over Agent authority
provides:
  - Document-scoped Blink Supplement producing content-free dirty and overflow intent
  - Bidirectional Mojo with browser-owned host registration and explicit enable/disable control
  - Fixed 256-record ceiling, deterministic 50 ms coalescing, and one overflow collapse
  - Renderer interface registration plus convergent receiver, host, navigation, and GC lifecycle
affects: [21-07, 21-08, 21-09, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Blink document Supplements own renderer observation while browser services retain capture and authority
    - MutationObserver delegates forward only bounded record counts and never inspect record content
    - Heap Mojo endpoints and document-context teardown converge through one idempotent Disable path

key-files:
  created:
    - .context/chromium/src/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom
    - .context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.h
    - .context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.cc
    - .context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement_unittest.cc
  modified:
    - .context/chromium/src/third_party/blink/public/mojom/BUILD.gn
    - .context/chromium/src/third_party/blink/renderer/modules/content_extraction/BUILD.gn
    - .context/chromium/src/third_party/blink/renderer/modules/BUILD.gn
    - .context/chromium/src/third_party/blink/renderer/modules/modules_initializer.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Carry only kDirty or kOverflow from renderer to browser; page content, records, identity, authority, and sequencing remain absent from Mojo."
  - "Observe the document-element subtree only while enabled, collapse more than 256 pending records to overflow, and debounce the first eligible mutation for exactly 50 ms."
  - "Create one Supplement per current Document and treat repeated Enable as host-generation replacement, never as consumer attachment."

patterns-established:
  - "The renderer announces invalidation only; the Plan 07 browser hub remains the sole recapture and fan-out owner."
  - "Disable, receiver loss, host loss, context destruction, and document replacement all cancel observation and pending delivery before releasing endpoints."
  - "Focused Blink verification generates new Mojo directly, compiles exact same-target objects, and preserves reviewed Ninja metadata byte-for-byte."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02]

duration: 56min
completed: 2026-07-21
---

# Phase 21 Plan 06: Blink Document Dirty-Signal Summary

**Each live Blink document can now emit only bounded dirty or overflow intent to one browser-owned host, with no MutationRecord content, renderer authority, page script, or late lifecycle callback.**

## Performance

- **Duration:** 56 min
- **Started:** 2026-07-22T02:14:39Z
- **Completed:** 2026-07-22T03:10:59Z
- **Tasks:** 3
- **Files modified:** 15 including exported patches, planning state, and this summary

## Accomplishments

- Added a public Blink Mojo contract whose document endpoint exposes only `Enable(host)` and `Disable()`, whose host exposes only `OnDocumentDirty(signal)`, and whose closed signal enum contains only `kDirty` and `kOverflow`.
- Added one `Supplement<Document>` with traced Heap Mojo endpoints, a traced MutationObserver, a document task-runner timer, and explicit execution-context teardown.
- Observed child-list, attribute, and character-data changes across the document-element subtree while enabled. The delegate reads only `records.size()` and immediately reduces that count into bounded state.
- Coalesced ordinary bursts to one dirty callback after exactly 50 ms and collapsed any burst beyond the fixed 256-record ceiling to one overflow callback.
- Registered the receiver through `ModulesInitializer::InitLocalFrame`, creating or resolving the current Document's Supplement through `ProvideTo` and replacing the prior receiver generation safely.
- Converged explicit disable, repeated enable, receiver loss, host loss, document replacement, context destruction, and repeated teardown without late delivery; re-enable after host loss remains safe.
- Extended Phase 21 verification with direct Mojo generation, exact production/test/initializer compilation, a Blink-aware focused link, privacy/static audits, expected-failure support, and Ninja metadata preservation.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify the bidirectional Mojo and document-Supplement contract** - nested `fdb388d8b3`; patch tracking `87ea739d1`
2. **Task 2 (GREEN): Implement bounded MutationObserver coalescing** - nested `90bec65fc4`; patch tracking `6461293fe`
3. **Task 3 (GREEN): Bind the renderer interface and close lifecycle edges** - nested `2e07def59d`; patch tracking `c62403a43`

## Files Created/Modified

- `prometheus_supervision_document.mojom` - Closed renderer control, browser host, and dirty/overflow enum contract.
- `prometheus_supervision_document_supplement.h` / `.cc` - Document ownership, bounded MutationObserver reduction, timer, Heap Mojo endpoints, and teardown convergence.
- `prometheus_supervision_document_supplement_unittest.cc` - Mock-time dirty, character-data, coalescing, overflow, replacement, disconnect, navigation, GC, re-enable, and idempotence coverage.
- Blink public/modules `BUILD.gn` files - Real Mojo, production source, and unit-test target membership.
- `modules_initializer.cc` - Live local-frame interface registration against the current Document.
- `.planning/chromium/verify-phase-21.sh` - `--focus-blink`, direct generated-Mojo compilation, focused Blink linkage, source privacy audit, and initializer compile proof.
- `patches/0013-test-21-06-specify-Blink-supervision-document-contra.patch` - Exact exported RED contract commit.
- `patches/0014-feat-21-06-implement-bounded-document-dirty-signals.patch` - Exact exported bounded-observer GREEN commit.
- `patches/0015-feat-21-06-bind-supervision-document-lifecycle.patch` - Exact exported renderer-binder and teardown GREEN commit.

## Decisions Made

- Renderer code never derives or transports the supervised target identity, document epoch, controller lease, sequence, URL, selector, node, or content. It reports invalidation only; browser-owned APC capture remains authoritative.
- The MutationObserver delegate does not loop over records and cannot access targets, nodes, attributes, or old/new values. It forwards only the vector size into a checked fixed-cap transition.
- A new `Enable` first executes the same complete cleanup path as `Disable`, then binds one replacement host and begins observation. It therefore models document/reconnect generation replacement rather than adding a second consumer.
- Host loss disables observation while leaving the control receiver available for a later browser re-enable. Receiver loss disables observation and closes the receiver generation.
- Context destruction performs cleanup explicitly even though Heap Mojo wrappers also observe context lifetime; repeated paths are intentionally idempotent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Built a focused Blink link from the available partial-checkout target graph**

- **Found during:** Task 1 RED gate
- **Issue:** The reviewed `blink_unittests` edge referenced many unrelated objects that were absent from this partial Chromium output, so reconstructing its full response file could not link despite every Plan 06 object compiling.
- **Fix:** Reused the existing small Blink-capable renderer unit target, appended only the exact Plan 06 production/test/generated-Mojo objects and required Blink test-support objects, and replaced its content test main with Blink's real `run_all_tests` environment to avoid double-attaching the V8 CppHeap.
- **Files modified:** `.planning/chromium/verify-phase-21.sh`
- **Verification:** The accepted RED run selected nine tests and failed only four intended ordinary signal assertions; the final fixture selected and passed all twelve tests without a crash or fatal.
- **Committed in:** `87ea739d1` (Task 1 patch tracking commit)

---

**Total deviations:** 1 auto-fixed blocking verification issue.
**Impact on plan:** The focused harness executes the planned real Blink fixture and exact renderer compilation without broadening product behavior or mutating reviewed Ninja metadata.

## Issues Encountered

- Initial direct compilation required the concrete `LocalDOMWindow` include for Heap Mojo context conversion and the lifecycle observer to receive `frame.DomWindow()` rather than the Document pointer. Both were compile-time integration corrections made before retaining their respective gates.
- The first small-target test run used content's global Blink environment and then constructed the fixture's Blink task environment, triggering a CppHeap attachment check. Swapping only the test main to Blink's standard environment resolved the harness mismatch; product code was unchanged.

## Test Evidence

- RED gate - 9 tests selected; 5 teardown/disable fixtures passed and exactly 4 dirty/overflow/replacement signal assertions failed through ordinary GTest status, with no crash, fatal, or infrastructure failure.
- Task 2 GREEN gate - all 5 selected dirty, character-data, coalescing, overflow, and disable fixtures passed deterministically under mock time.
- Final Blink gate - all 12 fixtures passed across receiver loss, host loss and re-enable, repeated enable, document replacement, GC tracing, and repeated teardown.
- Renderer compile gate - generated Blink/shared Mojo objects, the Supplement, its unit fixture, Blink test support, and the changed real `modules_initializer.o` all compiled from exact reviewed same-target commands.
- Regression gate - all 68 retained supervision types, transport codec, projection, diff, profile-service, and Agent-profile observation tests passed together.
- Privacy/source gate - Mojo exposes only the two control methods and one enum callback; production source contains no MutationRecord field access, JSON/HTML serialization, script execution, or renderer-provided identity/content path.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after final Blink and regression runs.
- Patch identity - patches 0013, 0014, and 0015 have stable IDs `4e3a1bbbc2908a7db2cd62fde9f5fca7eaef8543`, `99bb4314e1834c5fd7c9e259f3e68b0c377675c1`, and `35883b853bcdabe0bb5ebf15153b1006eff9968f`, exactly matching their nested commits.
- Root and nested `git diff --check` passed, and both repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan establishes the native Blink invalidation producer with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-07 can create the sole browser-owned per-target/document capture hub, call `Enable` once per active document generation, recapture through browser-owned APC, and fan sanitized results to consumers without adding another renderer observer.

No blockers or threat flags remain. SUP-01 and SUP-02 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: all eight planned Chromium source/build artifacts plus verifier wiring
- FOUND: nested RED/GREEN commits `fdb388d8b3`, `90bec65fc4`, and `2e07def59d`
- FOUND: matching non-empty exported patches `0013`, `0014`, and `0015` with exact stable identities
- VERIFIED: 9-test RED, 5-test Task 2 GREEN, 12-test final Blink fixture, and 68-test browser regression; privacy/static checks and exact metadata hashes pass
- VERIFIED: root and nested repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
