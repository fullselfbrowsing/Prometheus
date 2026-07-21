---
phase: 21-supervision-pairing-and-remote-control
plan: 02
subsystem: supervision-transport-boundary
tags: [chromium, cpp, supervision, transport, privacy, tdd]

requires:
  - phase: 21-01
    provides: Closed native supervision vocabulary, browser-only authority types, sanitized DTOs, and focused verifier
provides:
  - Exactly seven closed dashboard operations with distinct typed parameter variants and operation-specific allowlists
  - Recursive prototype, authority, route, script, vault, secret, and stale-shape rejection before dispatch
  - Exact request, string, numeric, action, nesting, and result bounds with stable typed failures
  - Separate dashboard and compatibility serializers that make dashboard wire authority unreachable from sanitized projections
affects: [21-03, 21-04, 21-08, 21-09, 21-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Closed JSON schemas parsed directly into operation-specific C++ variants without dictionary passthrough
    - Recursive normalized-key denylist applied before exact per-level allowlists
    - Dedicated dashboard-only authority DTO projected by one serializer while compatibility output is rebuilt from sanitized metadata
    - Stable non-echoing transport errors with exact input, output, UTF-8, integer, sequence, and action bounds

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Parse each of the seven operations into a distinct typed variant and reject every unknown key before native service dispatch."
  - "Permit browser-issued dashboard session, document epoch, and sequence only through the authenticated dashboard serializer; compatibility output reconstructs an allowlisted sanitized payload without any authority projection path."
  - "Normalize the one-time pairing code only for redemption, derive the client label through the native safe-label projector, and use fixed non-echoing failures for all malformed input."

patterns-established:
  - "Recursive normalized-key scanning rejects prototype, identity, authority, arbitrary-route, script, vault, secret, selector, typed-value, and page-content aliases at every JSON depth."
  - "Remote actions have ten exact category-specific shapes; action arguments never survive into errors, audit, or serialized compatibility state."
  - "JSON sequences accept only positive exactly representable integers through 2^53-1, while requests and results fail typed above 1 MiB and 2 MiB respectively."

requirements-completed: []
requirements-progressed: [SUP-02, SUP-03, SUP-04, SUP-05]

duration: 33min
completed: 2026-07-21
---

# Phase 21 Plan 02: Dedicated Supervision Transport Codec Summary

**The dashboard perimeter now accepts only seven exact bounded supervision operations and emits deterministic privacy-separated results, with dashboard authority structurally absent from every compatibility projection.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-07-21T22:20:26Z
- **Completed:** 2026-07-21T22:53:15Z
- **Tasks:** 2
- **Files modified:** 8 including exported patches and this summary

## Accomplishments

- Froze and implemented the exact `redeem`, `baseline`, `diff`, `ack`, `action`, `heartbeat`, and `end` schemas as distinct typed C++ variants with no permissive dictionary passthrough.
- Added normalized recursive rejection for prototype pollution, caller-selected profile/Browser/window/tab/owner/controller/session/document identity, arbitrary routes, scripts, vaults, secrets, selectors, typed values, and page content before dispatch.
- Normalized one ambiguity-safe eight-character pairing code only on redemption, derived one privacy-safe client label, and enforced bounded UTF-8, exact numeric semantics, ten closed remote-action shapes, a 1 MiB request ceiling, and a 2 MiB result ceiling.
- Split result projection into an authenticated dashboard serializer that alone can carry browser-issued session/epoch/sequence stamps and a compatibility serializer that reconstructs only allowlisted sanitized metadata.
- Extended the Phase 21 direct runner to compile and link the new codec and its thirteen-test contract while preserving the reviewed Ninja metadata byte-for-byte.

## Task Commits

Each task was committed atomically; nested Chromium commits were immediately exported as stable source-only patches:

1. **Task 1 (RED): Freeze operation schemas, bounds, and prohibited authority fields** - nested `33714e77ee`; patch tracking `ef227d995`
2. **Task 2 (GREEN): Implement strict parse and bounded serialization** - nested `4f2a57cdca`; patch tracking `cc1c622ea`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.h` - Seven operation enums and typed parameter variants, dashboard-only authority DTO, typed transport result, and exact public bounds.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.cc` - Closed parser, normalized recursive denylist, checked field readers, action dispatch, stable errors, and separate dashboard/compatibility serializers.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec_unittest.cc` - Thirteen exhaustive operation, extra-key, alias-injection, malformed-shape, boundary, action, determinism, authority-projection, sentinel, and typed-error cases.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Codec production source set and browser-test registration.
- `.planning/chromium/verify-phase-21.sh` - Same-target direct compile/link coverage for the codec source and test without writing Ninja state.
- `patches/0003-test-21-02-specify-closed-supervision-transport.patch` - Exact exported RED contract commit.
- `patches/0004-feat-21-02-implement-closed-supervision-transport.patch` - Exact exported GREEN implementation commit.

## Decisions Made

- The wire contract is a seven-member operation enum paired with a seven-member parameter variant. Every level has an exact allowlist, so adding a field requires an explicit contract and test change.
- A normalized recursive field scan runs before exact shape parsing. Prototype, authority, content, secret, and stale identity aliases therefore fail even when nested inside otherwise invalid containers.
- Dashboard wire authority lives in a dedicated C++ DTO and can be projected only when the dashboard serializer is selected. The compatibility serializer ignores that DTO and independently constructs an approved sanitized result dictionary.
- Pairing-code normalization strips only ASCII whitespace and hyphens, uppercases the result, and reuses native ambiguity-safe validation. Parse failures use fixed guidance and never reflect caller values or action arguments.

## Deviations from Plan

None - the plan's closed schemas, retained RED contract, strict GREEN parser and serializers, patch exports, privacy boundary, and metadata-preserving verification were executed as written.

## Issues Encountered

- The initial RED compile found a raw-string delimiter collision in the invalid JavaScript fixture and one heterogeneous initializer. Both test-authoring issues were corrected before retaining the RED gate; the final RED run failed only through ordinary intended GTest assertions.

## Verification

- RED gate — 13 registered `PrometheusSupervisionTransportCodecTest.*` cases compiled, selected non-empty, and exited with ordinary assertion status 1 rather than a crash or fatal error.
- GREEN gate — all 13 codec cases passed with no disabled fixture.
- Regression gate — the 13 codec cases plus all 13 retained `PrometheusSupervisionTypesTest.*` cases passed together, 26/26.
- Contract/privacy gate — every operation and action category has an exact allowlist; recursive forbidden-field scans precede parsing; dashboard authority keys and exact authority/content sentinels are absent from compatibility output.
- Bounds gate — at/over cases cover UTF-8 strings, safe labels, opaque sessions, integer sequences, action parameters, the 1 MiB request ceiling, and bounded/unsanitized result failures.
- Metadata preservation — `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after every focused run.
- Patch identity — patch 0003 stable ID `b330523f3adb0ea05638b7b0dbd8d84b3ebe240b` and patch 0004 stable ID `8e672b6db8189e9caf6a2d3e916727ae27f2e7be` exactly match their nested commits; both patches are non-empty and source-only.
- Root and nested `git diff --check` — passed.

Human UAT was not run and is not claimed; this plan establishes a native transport and privacy contract with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-03 can implement privacy-safe APC baseline projection and deterministic
structural diff/ack/resync semantics behind this closed transport contract.

No blockers or threat flags remain.

## Self-Check: PASSED

- FOUND: all three supervision transport codec source/test files and their BUILD/verifier wiring
- FOUND: nested RED/GREEN commits `33714e77ee` and `4f2a57cdca`
- FOUND: matching non-empty exported patches `0003` and `0004` with exact stable patch identities
- VERIFIED: 13 focused codec tests and 26 combined regression tests green, exact metadata hashes unchanged, and both repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
