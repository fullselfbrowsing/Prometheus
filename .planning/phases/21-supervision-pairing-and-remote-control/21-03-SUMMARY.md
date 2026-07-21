---
phase: 21-supervision-pairing-and-remote-control
plan: 03
subsystem: supervision-dom-stream-model
tags: [chromium, cpp, supervision, apc, structural-diff, privacy, tdd]

requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    provides: APC traversal, document-scoped DOM references, structured semantics, and restricted-frame metadata
  - phase: 21-01
    provides: Closed supervision types, browser-only stream authority, checked sequences, and hard resource limits
  - phase: 21-02
    provides: Dedicated bounded supervision transport contract with dashboard-only authority projection
provides:
  - Deterministic APC-native baselines with document-scoped refs, ordered structure, safe semantics, and all-or-nothing node/byte bounds
  - Structural omission of password, custom-password, payment, OTP, unknown-redaction, and restricted-frame content before serialization
  - Canonically ordered insert_subtree, remove, replace_fields, and reorder_children operations with bounded deterministic JSON
  - Independent per-viewer baseline acknowledgements, ordered diff queues, and fail-closed resynchronization on discontinuity or overflow
affects: [21-04, 21-05, 21-08, 21-09, 21-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - All-or-nothing structured projection and diff publication; caps never produce plausible truncated authority
    - Exact four-operation structural vocabulary with browser stream authority kept outside serialized diff payloads
    - Per-viewer checked sequence cursors that atomically clear retained state and require a fresh acknowledged baseline on ambiguity

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Project an input value only when APC explicitly marks it safe and the control is independently neither password, payment, nor OTP; absence and future redaction decisions fail closed."
  - "Emit restricted frames as safe boundary leaves and never traverse or serialize their child content."
  - "Keep stream authority out of diff JSON and make any malformed tree, reparenting ambiguity, authority mismatch, sequence discontinuity, wrap, or cap overflow require a fresh baseline."

patterns-established:
  - "Normalized node refs combine the current document token with DOM identity; same-site child documents switch tokens while retaining the closest emitted structural parent."
  - "Structural diffs are generated in canonical remove, insert, replace, reorder classes with lexicographic refs inside each class."
  - "Viewer queue count and byte retention are bounded independently; one viewer's acknowledgement or resync cannot advance or revoke another viewer."

requirements-completed: []
requirements-progressed: [SUP-02, SUP-03]

duration: 38min
completed: 2026-07-21
---

# Phase 21 Plan 03: Privacy-Safe Structural Baseline and Diff Summary

**Supervision now has a deterministic APC-native baseline and exact structural diff model that omits secrets before serialization and resynchronizes atomically on every authority, ordering, or resource-bound failure.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-07-21T22:59:39Z
- **Completed:** 2026-07-21T23:37:42Z
- **Tasks:** 3
- **Files modified:** 12 including exported patches and this summary

## Accomplishments

- Added deterministic preorder APC projection with document-scoped DOM refs, closest emitted parents, ordered child refs, bounded safe fields, same-site document transitions, and restricted-frame boundary leaves.
- Enforced structural privacy before serialization: only explicitly safe form values survive, while password, custom-password, payment, OTP, unknown-redaction, and restricted-frame sentinels are absent as both keys and values.
- Made baseline node, traversal, and serialized-byte overflow return an empty typed resync requirement rather than a truncated authoritative tree.
- Implemented the exact `insert_subtree`, `remove`, `replace_fields`, and `reorder_children` vocabulary with canonical ordering, deterministic JSON, and operation/byte ceilings.
- Added independent per-viewer baseline acknowledgement and retained diff cursors that reject session, target, epoch, sequence, wrap, queue, and byte discontinuities by clearing state and requiring a fresh baseline.
- Extended the metadata-preserving Phase 21 verifier to directly compile, link, select, and run all sixteen new projection/diff fixtures.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify strict APC privacy and deterministic diff fixtures** - nested `6398eeb8e1`; patch tracking `2c18df303`
2. **Task 2 (GREEN): Build the strict bounded APC baseline** - nested `e8baf37852`; patch tracking `8cdba406f`
3. **Task 3 (GREEN): Implement deterministic diff, ack, cursor, and resync behavior** - nested `a832ab2941`; patch tracking `015d9fe4b`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.h` - Normalized node/baseline types and bounded APC projection API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.cc` - Deterministic traversal, strict value redaction, restricted-frame boundaries, serialization, and all-or-nothing caps.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection_unittest.cc` - Five deterministic, document-boundary, privacy-sentinel, and node/byte-cap fixtures.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.h` - Exact structural operation model, authority-separated diff batches, and per-viewer cursor API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.cc` - Validated tree matching, canonical diff serialization, checked acknowledgement, bounded queues, and atomic resync behavior.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff_unittest.cc` - Eleven exact-operation, discontinuity, cap, wrap, and independent-viewer fixtures.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Projection/diff production source sets and browser-test registration.
- `.planning/chromium/verify-phase-21.sh` - Direct same-target projection/diff compile and link coverage without Ninja writes.
- `patches/0005-test-21-03-specify-bounded-supervision-projection-and-diff.patch` - Exact exported RED contract commit.
- `patches/0006-feat-21-03-implement-strict-bounded-APC-baseline.patch` - Exact exported baseline GREEN commit.
- `patches/0007-feat-21-03-implement-deterministic-diff-and-resync-cursors.patch` - Exact exported diff/cursor GREEN commit.

## Decisions Made

- APC's redaction decision is necessary but not sufficient for value projection: the projector also rejects password controls and credit-card/OTP autofill classifications, and treats absent or unrecognized decisions as sensitive.
- A restricted iframe remains observable only as a safe structural boundary with an approved reason; traversal stops before any child content can enter the normalized model.
- Baselines and diffs are authoritative only when complete. Duplicate refs, malformed parent/child structure, reparenting ambiguity, node/operation/byte overflow, and serialization failure yield an empty resync-required result.
- Serialized diff payloads contain only the four closed structural operations. Session, stable-tab, document-epoch, and sequence authority stays in the browser-only batch stamp.
- Every viewer owns a separate bounded acknowledgement cursor. Exact next-sequence and exact authority matching are mandatory, and any gap, duplicate, out-of-order value, wrap, retention overflow, or invalid acknowledgement atomically discards queued batches.

## Deviations from Plan

None - the plan's retained RED contract, strict bounded APC baseline, canonical structural diff, independent acknowledgement cursors, patch exports, privacy gates, and metadata-preserving verification were executed as written.

## Issues Encountered

- The initial RED verifier template used a synthesized test object as its query template. The runner wiring was corrected before retaining the RED commit; the final RED gate failed only through the sixteen intended ordinary GTest assertions.

## Verification

- RED gate - all 5 projection and 11 diff fixtures compiled, selected non-empty, and failed only through ordinary intended GTest assertions.
- GREEN gate - all 16 projection/diff fixtures passed together with no disabled test.
- Regression gate - all 42 retained `PrometheusSupervisionTypesTest.*`, `PrometheusSupervisionTransportCodecTest.*`, `PrometheusSupervisionProjectionTest.*`, and `PrometheusSupervisionDiffTest.*` cases passed together.
- Privacy gate - exact password, custom-password, payment, OTP, unknown-redaction, cross-site, and fenced-frame sentinels are absent from authoritative serialized output; the production projection/diff sources contain none of those values.
- Bounds/resync gate - tests cover the 500-node/200-KiB baseline, 128-op/64-KiB diff, 32-batch/256-KiB retained queue defaults, checked sequence wrap, and independent viewer cursors.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after every focused run.
- Patch identity - patches 0005, 0006, and 0007 have stable IDs `7a4a2c116e99725b40ce331ba44d3bc4aa563b04`, `cdd43444face9f49f9fae447cd4337a09d00bca0`, and `b7df7ce909f314367516c2b41671102c15e13843`, exactly matching their nested commits.
- Root and nested `git diff --check` - passed; both repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan establishes the in-process structural projection/diff contract with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-04 can bind this privacy-safe baseline/diff model to live page observation and the closed supervision transport without inventing new wire authority or best-effort truncation semantics.

No blockers or threat flags remain. SUP-02 and SUP-03 are progressed but intentionally remain phase-level incomplete until Phase 21 verification.

## Self-Check: PASSED

- FOUND: all six projection/diff source and test files plus BUILD/verifier wiring
- FOUND: nested RED/GREEN commits `6398eeb8e1`, `e8baf37852`, and `a832ab2941`
- FOUND: matching non-empty exported patches `0005`, `0006`, and `0007` with exact stable identities
- VERIFIED: 16 focused tests and 42 combined regression tests green, exact metadata hashes unchanged, privacy/stub searches clean, and both repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
