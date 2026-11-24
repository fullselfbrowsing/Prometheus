---
phase: 21-supervision-pairing-and-remote-control
plan: 01
subsystem: native-supervision-foundation
tags: [chromium, cpp, supervision, authority, privacy, tdd]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Browser-issued profile sessions, stable tab identity, and ownership authority
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    provides: Browser-owned document identity, structured page snapshots, and verified actions
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    provides: Native runtime policy, exact-window authority, and metadata-safe serialization patterns
provides:
  - Closed pairing, viewer, stream, remote-action, audit, terminal, and error vocabularies
  - Browser-only stream, target, and controller authority bindings with checked generation and sequence advancement
  - Explicit default and hard resource limits plus privacy-safe sanitized snapshot projectors
  - Metadata-preserving direct Phase 21 focused-test runner with strict RED and GREEN modes
affects: [21-02, 21-03, 21-04, 21-05, 21-06, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Closed enum-to-string contracts that reject unknown values
    - Browser-only authority types with no prefs or base::Value projection
    - Structurally allowlisted sanitized snapshots with bounded strings, collections, counts, and times
    - Direct same-target compile/link verification that preserves reviewed Ninja metadata

key-files:
  created:
    - .planning/chromium/verify-phase-21.sh
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Keep session, document epoch, controller lease, and generation authority in browser-only memory types with no serialization surface."
  - "Represent the stable tab identity in the standalone contract as a positive int32_t and resolve it to live tab authority only in the owning browser service."
  - "Canonicalize observable origins to HTTP(S) origins and replace labels or titles containing authority/content markers with fixed safe fallbacks."

patterns-established:
  - "Terminal pairing and viewer states have no outgoing transitions; sequence and generation wrap fail closed."
  - "Every caller-controlled resource limit maps zero to its approved default and clamps positive values at an explicit hard maximum."
  - "Sanitized output is constructed from approved metadata keys only; raw code, session, lease, bearer, profile, document, selector, and content fields are structurally absent."

requirements-completed: []
requirements-progressed: [SUP-02, SUP-03, SUP-04, SUP-05]

duration: 41min
completed: 2026-07-21
---

# Phase 21 Plan 01: Native Supervision Contract Summary

**A closed, bounded native supervision vocabulary now separates browser-only session/tab/document authority from privacy-safe UI and transport snapshots, with a non-Ninja focused verifier proving the contract.**

## Performance

- **Duration:** 41 min
- **Started:** 2026-07-21T21:30:49Z
- **Completed:** 2026-07-21T22:11:42Z
- **Tasks:** 3
- **Files modified:** 8 including exported patches and this summary

## Accomplishments

- Defined every approved pairing, viewer/controller, stream, remote-action, audit, terminal, and typed-error state as a closed native enum with fail-closed parsing.
- Added exact default/hard bounds, ambiguity-safe pairing-code validation, non-wrapping sequence/generation helpers, and browser-only session/tab/document/controller bindings.
- Added sanitized target, client, session, audit, and aggregate projectors that canonicalize origins, bound all observable values, and recursively remove exact authority/content sentinels.
- Added a strict focused verifier that directly compiles and links selected browser tests, rejects empty selections and non-assertion RED failures, and proves `.ninja_log` and `.ninja_deps` remain byte-identical.

## Task Commits

Each task was committed atomically; nested Chromium commits were immediately exported as stable source-only patches:

1. **Task 1: Create metadata-preserving focused verification scaffold** - root `0d2bdbb25`
2. **Task 2 (RED): Specify closed supervision contract** - nested `5cf320abe1`; patch export `f0f8203ea`
3. **Task 3 (GREEN): Implement closed native contract** - nested `1b30708fba`; patch export `7148ffa75`

**Plan metadata:** `ec895d63d`

## Files Created/Modified

- `.planning/chromium/verify-phase-21.sh` - Strict direct-compile/focused-link runner with non-empty selection, assertion-only RED mode, and Ninja metadata hashing.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.h` - Closed states, approved limits, browser-only identity/authority bindings, sanitized DTOs, and public contract helpers.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.cc` - Exhaustive conversions and transition graphs, clamps, checked identities, safe label/origin projection, and allowlisted serializers.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types_unittest.cc` - Thirteen exhaustive transition, cap, identity, privacy, serialization, and malformed-input tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Production source set and focused browser-test registration.
- `patches/0001-test-21-01-specify-closed-supervision-contract.patch` - Exact exported RED contract commit.
- `patches/0002-feat-21-01-implement-closed-supervision-contract.patch` - Exact exported GREEN implementation commit.

## Decisions Made

- Raw session tokens, controller leases, document epochs, and target/authority generations remain memory-only C++ values. No raw authority type has a prefs, UI, diagnostics, audit, or `base::Value` serializer.
- The foundational type layer carries a positive stable tab integer without importing the full tab-interface dependency graph; the owning browser service must resolve and revalidate that identifier against live exact-tab authority.
- Observable origins are reduced to canonical HTTP(S) origins. Observable labels and titles collapse whitespace, enforce UTF-8 byte bounds, and fall back to fixed safe text when authority/content markers appear.
- Sanitized dictionaries structurally omit prohibited fields rather than emitting empty, redacted, or masked authority-shaped keys.

## Deviations from Plan

None - the plan's direct-verifier, RED specification, GREEN implementation, patch export, and privacy boundaries were executed as written.

## Issues Encountered

- The standalone direct compile exposed transitive tab/graphics dependencies when experimenting with a full tab handle; the research-approved positive `int32_t` stable-tab representation kept the contract layer independent while preserving exact-tab semantics for the owning service.
- GREEN compilation exposed two mechanical C++ conversions, and the privacy test exposed a missing `lease` marker plus a `release` substring edge case. Explicit conversion and boundary-aware marker matching resolved them; the complete suite was rerun after each final fix.

## Verification

- Existing verifier probe — 14/14 `PrometheusAgentRouteTest.*` cases passed without Ninja.
- RED gate — 13 registered supervision cases compiled and failed only through intended GTest assertions.
- GREEN gate — all 13 `PrometheusSupervisionTypesTest.*` cases passed with no disabled tests.
- Metadata preservation — `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after every focused run.
- Privacy boundary search — no authority-bearing `ToValue`/`FromValue`, prefs dependency, or forbidden sanitized-output key exists.
- Patch identity — both exported patches are non-empty, source-only, and have the same stable patch ID as their nested commits.
- Root and nested `git diff --check` — passed.

Human UAT was not run and is not claimed; this plan is a native contract foundation with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-02 can define the bounded dashboard supervision wire codec and privacy
contract against one closed native vocabulary. Later service, streaming,
gateway, remote-control, audit, and UI plans can depend on the same sanitized
DTO surface.

No blockers or threat flags remain.

## Self-Check: PASSED

- FOUND: focused Phase 21 verifier and all three supervision type/source/test files
- FOUND: nested RED/GREEN commits `5cf320abe1` and `1b30708fba`
- FOUND: matching non-empty exported patches `0001` and `0002`
- VERIFIED: 13 focused tests green, exact metadata hashes unchanged, and nested Chromium clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
