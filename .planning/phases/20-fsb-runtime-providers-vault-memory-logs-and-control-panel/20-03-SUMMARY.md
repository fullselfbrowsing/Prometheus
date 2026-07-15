---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 03
subsystem: native-memory-and-site-guides
tags: [chromium, cpp, prefs, memory, site-guides, origin-policy, tdd]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 01
    provides: Versioned profile dictionary, bounded UTF-8 helpers, and native runtime policy contracts
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 02
    provides: Profile persistence, opaque-ID, strict hydration, and deterministic LRU/FIFO patterns
provides:
  - Distinct typed memory and site-guide create/get/list/search/update/delete APIs
  - Caller-owned and explicitly shared MCP visibility with profile-wide browser UI snapshots
  - Strict restart-safe profile persistence with opaque UUIDs, hashed caller keys, byte counts, and corruption repair
  - Unicode case-folded bounded search plus deterministic count and UTF-8 byte eviction
  - Exact canonical HTTP(S) origin binding and fresh committed-document revalidation for guide application
  - Content-free bounded guide-application audit metadata with no automatic page, form, prompt, or secret capture
affects: [20-07, 20-09, 20-10, 20-13, 20-14]

tech-stack:
  added: []
  patterns:
    - Strict versioned sub-store below the shared prometheus.runtime profile dictionary
    - Domain-separated hashed caller keys with browser-issued opaque record IDs
    - url::Origin canonicalization plus document-token revalidation at apply time
    - Global content-byte LRU with per-type count bounds and FIFO apply evidence

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Persist only a domain-separated hash of the caller principal; raw caller and gateway authority identifiers never enter the memory schema or public records."
  - "Measure quotas from bounded UTF-8 record content while separately bounding memory count, guide count, search results, and application history."
  - "Accept guide definitions only as canonical HTTP(S) origins and rederive the current committed document's url::Origin immediately before every apply."

patterns-established:
  - "Caller reads expose owned plus explicitly shared records; browser UI snapshots are profile-wide and never include owner keys."
  - "Hydration requires an exact allowlisted schema, drops malformed or duplicate records, and rewrites canonical data to remove unsolicited fields."
  - "Get, search, update, and authorized guide application advance a persisted access sequence used for deterministic LRU eviction."

requirements-completed: [FSB-06]

duration: 21min
completed: 2026-07-15
---

# Phase 20 Plan 03: Bounded Memory and Exact-Origin Site Guides Summary

**One restart-safe native store now provides caller-filtered memory and exact-origin site-guide CRUD/search/apply with fixed quotas, Unicode search, deterministic eviction, and no implicit capture path.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-15T14:49:51-05:00
- **Completed:** 2026-07-15T15:10:59-05:00
- **Tasks:** 2
- **Files modified:** 7 including exported patches and this summary

## Accomplishments

- Added distinct typed memory and site-guide APIs for create, get, list, search, update, delete, profile-wide snapshots, and guide application.
- Persisted stable UUID records below `prometheus.runtime.data.memory_store` with strict schema hydration, integer timestamps, exact byte counts, hashed caller ownership, and restart repair.
- Enforced caller-owned versus explicitly shared visibility without exposing caller keys or gateway authority session IDs in public results.
- Added Unicode case-folded search, normalized/deduplicated bounded tags, exact field/query/result limits, per-type count caps, and deterministic global LRU byte eviction.
- Bound guides to canonical HTTP(S) origins and denied stale/non-current documents, scheme/host/effective-port mismatches, subdomains, opaque origins, and unsafe guide definitions.
- Kept guide-application evidence to guide ID, canonical origin, closed outcome, and timestamp; cookie, form, vault, payment, provider-secret, prompt, and page-text sentinels are never auto-ingested.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Define memory and exact-origin guide behavior (RED)** - nested `00e1542fbf`; patch export `8a752436e`
2. **Task 2: Implement bounded persistence and guide application (GREEN)** - nested `55325eca99`; patch export `a27bb6704`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.h` - Typed records, statuses, bounds, caller/browser views, CRUD/search, and guide-application contract.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.cc` - Strict persistence, owner hashing, normalization, Unicode search, LRU/FIFO bounds, corruption repair, and exact-origin enforcement.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_memory_store_unittest.cc` - Twelve focused CRUD, visibility, exact-limit, eviction, restart, origin, and no-capture tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Memory-store source set, direct i18n/crypto/runtime dependencies, and unit-test registration.
- `patches/0006-test-20-03-specify-bounded-memory-and-exact-origin-guides.patch` - Exported compileable RED contract commit.
- `patches/0007-feat-20-03-implement-bounded-memory-and-exact-origin-guides.patch` - Exported passing GREEN implementation commit.

## Decisions Made

- Used a domain-separated SHA-256 caller key solely for persisted record ownership lookup. Browser-issued UUIDs remain the only public record IDs, while upstream profile/session authority remains outside this store.
- Counted bounded user-visible UTF-8 record content for the shared byte ceiling so exact limits remain stable rather than varying with JSON field overhead.
- Used one persisted monotonic access sequence across memories and guides so count and byte eviction are deterministic across restarts.
- Required exact schema sizes and canonical normalized fields during hydration; malformed, duplicate, or unsolicited records are omitted before the store rewrites its allowlisted form.
- Kept guide definition validation stricter than guide use: definitions accept an origin URL only, while apply derives an origin from a fresh committed URL that may naturally contain a path, query, or fragment.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The workspace's `out/Default` contains both legacy Ninja and Siso metadata, so the `autoninja` wrapper refuses to choose a backend. Per the execution handoff, validation used the pinned warmed `third_party/ninja/ninja` binary directly; the target built and linked successfully without cleaning or invalidating the Chromium cache.
- The first GREEN compile identified the current `GURL` path accessor (`path()` rather than `path_piece()`); the implementation was corrected before any GREEN test or commit.

## Verification

- Raw pinned Ninja build of `prometheus_unittests` - passed; final incremental run reported no work to do.
- `PrometheusMemoryStoreTest.*` list guard - 12 registered tests, zero disabled.
- `PrometheusRuntimeTypesTest.*` list guard - 13 registered tests, zero disabled.
- Combined memory/runtime contract gate - all 25 tests passed.
- Exact-limit evidence - title, text, UTF-8 tag, query, result count, memory/guide count, and total content-byte limit/one-over cases passed.
- Visibility and authority evidence - caller-owned plus explicitly shared filtering passed; serialized prefs contain neither caller strings nor gateway/session authority fields.
- Origin evidence - case/default-port canonicalization and path/query/userinfo/fragment definition rejection passed; stale, non-current, scheme, subdomain, port, opaque, and `about:blank` apply denials passed.
- No-capture evidence - exact cookie, form, vault, payment, provider-secret, prompt, and page-text sentinels were removed from repaired prefs and absent from records/apply metadata.
- Chromium formatting, nested/root `git diff --check`, and nested/root clean-tree checks - passed.
- Export verification - both patches are non-empty; their mail headers exactly name nested commits `00e1542fbf` and `55325eca99`; the GREEN patch reverse-apply check passed at nested HEAD.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. Memory and site guides are local profile primitives and require no external service, provider key, or runtime.

## Next Phase Readiness

Plan 20-04 can add origin-bound encrypted provider/vault envelopes and provider metadata beside the memory sub-store. Plans 20-07, 20-09, 20-10, and 20-13 can consume these typed caller/browser APIs without inventing a second visibility or origin policy.

## Self-Check: PASSED

- FOUND: memory-store header, implementation, focused fixture, and BUILD wiring
- FOUND: nested RED/GREEN commits `00e1542fbf` and `55325eca99`
- FOUND: matching non-empty exported patches `0006` and `0007`
- VERIFIED: 12 memory tests plus 13 runtime regressions green
- VERIFIED: both repositories clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-15*
