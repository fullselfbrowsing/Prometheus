---
phase: 21-supervision-pairing-and-remote-control
plan: 10
subsystem: agent-supervision-transport
tags: [chromium, agent, supervision, transport, apc, privacy, tdd]

requires:
  - phase: 21-09
    provides: Authenticated abstract dashboard supervision gateway with cancellation and sanitized readiness
provides:
  - Exactly five bijective native Agent supervision route identities with empty caller-scoped argument objects
  - Closed authority-free success union for local UI, real baseline, real diff, actual no-change, and ended outcomes
  - Bounded deterministic safe-APC node/diff serialization with graph validation and recursive forbidden-value rejection
  - Focused direct-codec compilation, GN membership, privacy, layering, and metadata-preservation gates
affects: [21-11, 21-12, phase-21-supervision, mcp-catalog]

tech-stack:
  added: []
  patterns:
    - Compatibility requests retain only the browser-issued Agent session envelope; target, params, and visual must be absent or empty objects
    - Route and payload variant must match exactly before a supervision result can serialize
    - The codec projects supplied semantics only and rejects empty baseline/diff stand-ins rather than inventing stream outcomes

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep all five MCP-compatible supervision routes caller-scoped and argument-free; browser-owned dispatch will derive target, cursor, pairing, document, and controller authority in later plans."
  - "Use one five-alternative typed success payload and require an exact route/payload pairing before serialization; typed failures remain the outer AgentRouteResult contract."
  - "Represent create and end with fixed markers, start/snapshot with a nonempty authoritative safe-APC baseline, and diff with either nonempty structural operations or an explicit no-change marker."
  - "Validate node topology, operation shape, counts, bytes, UTF-8, and sensitive/authority/content sentinels before producing deterministic JSON; reject rather than ambiguously redact."

patterns-established:
  - "Supervision success JSON has exactly five root keys: ok, error_code, message, recovery, and supervision."
  - "Safe APC nodes serialize only ref, optional parent_ref, children, and bounded fields; no browser/profile/tab, dashboard, controller, document, sequence, cursor, bearer, URL, selector, renderer, or raw-content field exists."
  - "The existing Agent service and page-adapter switches acknowledge the five enum values with fixed not-ready/unsupported failures until abstract dispatch is installed."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-05]

duration: 50min
completed: 2026-07-22
---

# Phase 21 Plan 10: Closed Agent Supervision Transport Summary

**Exactly five empty-schema supervision commands now have bijective native Agent identities and a deterministic bounded success union that cannot carry caller-selected authority, credentials, raw page structures, or invented stream outcomes.**

## Performance

- **Duration:** 50min
- **Started:** 2026-07-22T08:48:08Z
- **Completed:** 2026-07-22T09:37:56Z
- **Tasks:** 2
- **Files modified:** 13 including exported patches, planning state, and this summary

## Accomplishments

- Added `create_supervision_pairing`, `start_supervision_session`, `get_supervision_snapshot`, `get_supervision_diff`, and `end_supervision_session` as the only five new native `AgentRouteName` values. The 37-entry conversion table is compile-time counted, round-trips bijectively, rejects legacy visual-session aliases, and returns no fallback identity for an invalid enum value.
- Made every compatibility request caller-scoped and argument-free. The existing browser-issued Agent `session_id` remains the authenticated envelope, while `target`, `params`, and `visual` must be absent or empty dictionaries; any target, tab, URL, content, code, cursor, session override, visual label, or unknown top-level field fails before dispatch.
- Added a five-alternative authority-free result union: fixed local-control-panel intent, nonempty safe-APC baseline, nonempty structural diff, explicit actual-no-change, and fixed ended. Route/payload mismatch, generic-result mixing, empty baseline/diff stand-ins, malformed topology, and stale operation shapes fail serialization.
- Serialized baseline nodes and insert/remove/replace/reorder operations using the same safe structural vocabulary as the native supervision projection/diff layer. Output is deterministic and bounded by node, child, ref, operation, diff-byte, UTF-8, and overall result caps.
- Added recursive forbidden-value checks for credential, pairing, dashboard, controller, browser/profile/window/tab/owner, document, sequence/cursor, selector/URL, renderer, and raw-content sentinel vocabulary. Unsafe success data and unsafe typed-error text return fixed non-echoing failures instead of redaction.
- Extended the real browser BUILD target and Phase 21 verifier to compile the exact Agent transport codec and synthesized codec fixture, require the closed declarations/tests/GN membership, and reject concrete supervision service, factory, capture, renderer, document, or legacy visual-route dependencies.
- Kept dispatch out of this plan. The Agent service and page adapter explicitly fail the five new enum cases as not connected/unsupported so exhaustive switches compile without introducing a concrete service edge before Plans 11-12.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Freeze five route identities, empty requests, and bounded result variants** - nested `8854e74942`; patch tracking `bde625069`
2. **Task 2 (GREEN): Implement exhaustive route/codec conversions and structural privacy** - nested `e676c99241`; patch tracking `e9c362fdf`

## Files Created/Modified

- `prometheus_agent_route.h` / `.cc` - Five enum/string identities, public bounds, safe node/diff DTOs, closed five-variant success payload, and supervision success factory.
- `prometheus_agent_transport_codec.cc` - Empty-argument parser branch, exact route/payload matching, bounded topology and operation validation, deterministic safe-APC serialization, fixed markers, and forbidden-value rejection.
- `prometheus_agent_transport_codec_unittest.cc` - Exact-five manifest, empty request perimeter, closed union, deterministic baseline/diff/no-change/marker shapes, bounds, malformed topology, mixed metadata, and recursive privacy coverage.
- `prometheus_agent_service.cc` / `prometheus_page_adapter.cc` - Explicit fixed-failure switch cases only; no supervision service lookup or concrete dispatch.
- Browser `BUILD.gn` - New codec fixture in the existing Prometheus unit-test target.
- `.planning/chromium/verify-phase-21.sh` - Exact codec production/test-object compilation plus declaration, fixture, GN, privacy, layering, and legacy-name guards.
- `patches/0026-test-21-10-specify-closed-supervision-route-contract.patch` - Exact exported RED contract commit.
- `patches/0027-feat-21-10-implement-closed-supervision-transport.patch` - Exact exported GREEN implementation commit.

## Decisions Made

- The existing Agent `session_id` remains the authenticated transport envelope, but it is not supervision stream authority. Compatibility callers cannot select a target, dashboard session, pairing code, consumer cursor, document epoch, sequence, controller, or browser identity.
- A success payload carries its originating native route internally and must use the one allowed variant for that route. Create returns only intentional local-UI direction; start and snapshot require a real baseline; diff requires either real operations or explicit no-change; end returns only a fixed marker.
- Empty baselines and empty structural diffs are invalid. This prevents the transport layer from converting missing semantics into plausible success; Plan 12 must supply an authoritative baseline, a real diff, explicit no-change, or a typed error.
- Node collections require bounded unique refs, one coherent root, reciprocal parent/child edges, and no cycles. Inserted subtrees require one coherent internal or external root; each diff operation rejects fields belonging to another variant.
- Secret and authority sentinel matching is case-insensitive and token-bounded, which rejects the fixed adversarial vocabulary without matching incidental substrings such as `secretary` or `curl`.
- Supervision success serialization intentionally omits elapsed time, target, changed-state, page, element, tab/window, and diagnostic metadata. The existing audit path can classify the enum route without copying safe-APC payload content.

## Deviations from Plan

- Added explicit cases to `prometheus_agent_service.cc` and `prometheus_page_adapter.cc`, two files not listed in the plan frontmatter. Adding enum values made their exhaustive dispatch switches part of compileability; the new cases return fixed not-ready/unsupported failures and do not perform service lookup, capture, renderer access, or dispatch. This preserves the intended Plan 10/11 boundary.

## Issues Encountered

- The first RED run found an aggregate-brace error in the newly synthesized invalid-request fixture before reaching GTest assertions. The fixture initializer was corrected, then the required RED command selected eight tests and failed only through ordinary intended assertions.
- The final privacy review tightened initially permissive empty baseline/diff handling and broadened sentinel vocabulary. Both the exact and combined suites were rerun after those changes.

## Test Evidence

- The accepted RED gate selected 8 supervision codec tests: 7 failed through intended route/parser/serializer/privacy assertions and the compile-time five-variant union test already passed. No crash, fatal process exit, source-guard failure, or empty selection occurred.
- The final exact GREEN gate selected and passed all 8 `PrometheusAgentTransportCodecTest.*` tests after direct production/test object compilation.
- The final combined regression selected and passed 48 tests across `PrometheusAgentTransportCodecTest.*`, existing `PrometheusAgentTransportTest.*`, `PrometheusAgentRouteTest.*`, and `PrometheusRuntimeTransportCodecTest.*`.
- Every focused run passed Agent ownership/composition, abstract gateway, supervision route/result/GN, capture-hub ownership/privacy, concrete-dependency, legacy-name, and exact-source guards.
- `.ninja_log` stayed `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` stayed `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`; reviewed `libblink_modules.dylib` stayed `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; its TOC stayed `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patches 0026 and 0027 have stable IDs `f7c81cd5e223bd2db6a37594d036cebacb4f28a1` and `de1d247d8f2e8e5929206f2d94a9c9eb70020fa2`, exactly matching nested commits `8854e74942` and `e676c99241` in ordered ancestry.
- Root and nested `git diff --check` passed, verifier shell syntax passed, and both implementation repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan freezes a native transport contract whose acceptance is fully automated.

## User Setup Required

None. No credentials, external services, listeners, dashboards, or configuration are required.

## Next Phase Readiness

Plan 21-11 can bind these five exact native identities to the abstract Agent supervision dispatcher at the legal browser composition root. Plan 21-12 can then translate real profile-service/capture-hub semantics into the closed baseline/diff/no-change/error values without changing the compatibility wire contract.

No blockers or threat flags remain. SUP-01, SUP-02, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: exactly five new native route strings and five typed success alternatives, with no legacy visual-session alias
- FOUND: empty caller-scoped request handling with no target, authority, cursor, code, or content argument path
- FOUND: deterministic fixed local-UI/ended markers, real baseline/diff, explicit no-change, and outer typed-error handling
- FOUND: no concrete supervision service, factory, capture hub, renderer, document, Browser, profile, or WebContents dependency in route/codec
- FOUND: nested commits `8854e74942` and `e676c99241`
- FOUND: matching non-empty exported patches 0026 and 0027 with exact stable identities and ordered ancestry
- VERIFIED: 8-test RED, 8-test exact GREEN, and 48-test combined regression gates
- VERIFIED: malformed topology, wrong variants, empty outcome rejection, caps, mixed metadata, recursive privacy, exact-source, and immutable-build-artifact guarantees
- VERIFIED: root and nested implementation repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
