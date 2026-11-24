---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 01
subsystem: native-runtime-foundation
tags: [chromium, cpp, prefs, lifecycle, policy, tdd]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Native action authority, ownership, and profile boundaries
  - phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
    provides: External MCP provenance and native gateway contracts
provides:
  - Closed runtime origin, requested/effective execution, lifecycle, error, limits, usage, and sanitized snapshot types
  - Exhaustive legal-transition, terminal-state, clamp, accounting, UTF-8, and serialization enforcement
  - One versioned local/non-syncable profile namespace for bounded runtime data, encrypted envelopes, and effective policy
  - Locked ownership, native-only vault transport, per-use vault confirmation, and Phase 21 supervision boundaries
affects: [20-02, 20-03, 20-04, 20-06, 20-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Closed enum-to-string contracts with fail-closed parsing
    - Allowlisted content-free base::Value serialization
    - Versioned non-syncable profile dictionaries with clamped effective policy

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prefs/browser_prefs.cc
    - .context/chromium/src/chrome/browser/prefs/BUILD.gn

key-decisions:
  - "Keep MCP solely as task provenance; requested execution remains Auto, Provider, or Local and effective execution remains Hosted, Routed, or Local."
  - "Store all Phase 20 profile state below one schema-versioned prometheus.runtime dictionary registered with zero sync flags."
  - "Ignore persisted attempts to weaken tab ownership, native-only secret handling, per-use vault confirmation, or the truthful Phase 21-not-ready state."

patterns-established:
  - "Every caller-controlled cap is normalized through one deterministic default/hard-limit clamp."
  - "Unknown cost remains distinct from measured zero and checked integer addition rejects negative values and overflow."
  - "Serializable task metadata is structurally allowlisted and cannot carry prompts, page observations, action content, credentials, paths, or session authority."

requirements-completed: []
requirements-progressed: [FSB-02, FSB-05, FSB-08]

duration: 14min
completed: 2026-07-13
---

# Phase 20 Plan 01: Native Runtime Contract and Policy Foundation Summary

**Closed native lifecycle and accounting contracts now sit above one versioned, non-syncable profile policy namespace whose security invariants cannot be weakened by stored values.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-13T08:58:00-05:00
- **Completed:** 2026-07-13T09:12:00-05:00
- **Tasks:** 3
- **Files modified:** 11 including exported patches and this summary

## Accomplishments

- Defined independent task origin, requested execution, and effective execution vocabularies so an external MCP caller can never parse as an execution engine.
- Implemented an exact lifecycle graph with immutable terminal states, fixed default/hard budgets, checked integer usage and cost accounting, UTF-8 byte limits, and content-free task snapshots.
- Registered one `prometheus.runtime` regular-profile dictionary with schema version, bounded-data container, encrypted-envelope list, settings, and zero sync flags.
- Clamped corrupt/oversized policy values and locked ownership, native-only vault handling, fresh confirmation per use, and Phase 21 supervision readiness regardless of persisted input.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Specify native runtime contracts (RED)** - nested `116c87dc17`; patch export `9f4fb9187`
2. **Task 2: Implement closed runtime types (GREEN)** - nested `bfe5e52500`; patch export `b26d5aa62`
3. **Task 3: Add versioned runtime policy prefs** - nested `545dc040d7`; patch export `e97d19b9e`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.{h,cc}` - Closed runtime vocabulary, transitions, caps, checked accounting, bounds, and sanitized DTO serialization.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.{h,cc}` - Versioned local profile registration plus effective-policy parsing and writing.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types_unittest.cc` - Thirteen focused contract, corruption, clamp, scope, and invariant tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Runtime type/pref targets and focused test dependencies.
- `.context/chromium/src/chrome/browser/prefs/browser_prefs.cc` - Desktop regular-profile registration hook.
- `.context/chromium/src/chrome/browser/prefs/BUILD.gn` - Production dependency for the pref registration implementation.
- `patches/0001-test-20-01-specify-native-runtime-contracts.patch` - Exported RED contract commit.
- `patches/0002-feat-20-01-implement-closed-runtime-types.patch` - Exported GREEN runtime-type commit.
- `patches/0003-feat-20-01-add-runtime-policy-prefs.patch` - Exported pref/policy commit.

## Decisions Made

- Used one top-level profile dictionary rather than independent pref paths so later bounded stores share one version and migration boundary.
- Made mutable user settings explicit while serializing and reasserting locked policy values on every write.
- Kept encrypted envelopes as an empty typed collection in the schema; later secret-store work owns encryption and may never place plaintext in this namespace.

## Deviations from Plan

### Auto-fixed Issues

**1. Added the production pref-target dependency**

- **Found during:** Task 3 production integration review
- **Issue:** Calling the new registration function from `browser_prefs.cc` requires the owning `prefs:impl` target to link the Prometheus pref source set, but the plan's file list omitted `chrome/browser/prefs/BUILD.gn`.
- **Fix:** Added the desktop-only dependency and compiled `obj/chrome/browser/prefs/impl/browser_prefs.o`.
- **Files modified:** `.context/chromium/src/chrome/browser/prefs/BUILD.gn`
- **Verification:** Production browser-pref translation unit compiled successfully.
- **Committed in:** nested `545dc040d7`

**2. Added value equality for exact policy-default assertions**

- **Found during:** Task 3 default-policy tests
- **Issue:** `RuntimeLimits` had no structural equality operator, making an exact full-default assertion unnecessarily field-by-field.
- **Fix:** Added defaulted value equality to the closed limits struct.
- **Files modified:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.h`
- **Verification:** All thirteen focused tests compile and pass.
- **Committed in:** nested `545dc040d7`

---

**Total deviations:** 2 auto-fixed integration/testability issues.
**Impact on plan:** Both changes are necessary to verify and link the planned contract; neither expands runtime capability or introduces an embedded agent.

## Issues Encountered

The initial build shell lacked depot_tools on `PATH`; using the workspace-pinned `.context/depot_tools` restored the exact build command. No source issue was involved.

## Verification

- `prometheus_unittests` build — passed.
- `PrometheusRuntimeTypesTest.*` list guard — 13 registered tests.
- `PrometheusRuntimeTypesTest.*` — all 13 green.
- `obj/chrome/browser/prefs/impl/browser_prefs.o` production compile — passed.
- Non-syncable registration — exact registration flags are `0`.
- Embedded-runtime boundary search — no Claude runtime, engine selector, process-spawn, or terminal integration contract introduced.
- Nested `git diff --check` — passed.
- Export verification — all three generated patch files are non-empty; Task 3 patch hash exactly matches `git format-patch -1 --stdout`.

Human UAT was not run and is not claimed; it remains deferred to Phase 24 as planned.

## User Setup Required

None. No provider credentials, services, or external runtimes are required for this foundation.

## Next Phase Readiness

Plan 20-02 can build the bounded restart-safe task/event/action/diagnostic store against the versioned profile namespace and closed lifecycle types. Keyed-service regular-versus-OTR admission remains deliberately owned by Plan 20-06.

## Self-Check: PASSED

- FOUND: all five runtime contract/pref source and test files
- FOUND: nested commits `116c87dc17`, `bfe5e52500`, and `545dc040d7`
- FOUND: matching exported patches `0001` through `0003`
- VERIFIED: 13 focused tests green and both repositories clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-13*
