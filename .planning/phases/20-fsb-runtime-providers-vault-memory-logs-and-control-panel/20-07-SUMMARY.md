---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 07
subsystem: native-runtime-orchestration
tags: [chromium, cpp, keyed-service, provider-fallback, agent-authority, cancellation, evaluation]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 02
    provides: Generation-fenced task persistence, bounded snapshots, usage records, and exactly-once completion
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 03
    provides: Bounded memory and exact-origin site-guide stores
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 04
    provides: Exact-bound encrypted secrets and ordered provider registry
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 05
    provides: Strict provider codecs plus secure cancellable provider transport
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 06
    provides: Safe-title derivation, closed policy decisions, and Agent-session caps
  - phase: 19-mcp-client-and-agent-contract-restoration
    provides: Browser-owned Agent sessions, stable tab authority, and typed route execution
provides:
  - Regular-profile-only keyed runtime service with a private move-only exact-Browser local principal
  - Closed non-official loopback provider bootstrap gated by build, launch, profile, path, file-mode, endpoint, and schema facts
  - Bounded Auto, Provider, and Local execution over provider-neutral turns and one closed safe Agent tool per turn
  - Ordered pre-mutation fallback, generation-fenced cancellation, fresh authority and policy revalidation, and retained usage accounting
  - Exactly 20 deterministic adversarial evaluation fixtures across all seven AI-SPEC groups
affects: [20-08, 20-09, 20-10, 20-11, 20-12, 20-13, 20-14]

tech-stack:
  added: []
  patterns:
    - Keep local UI authority in a move-only C++ principal bound to the exact Browser, tab, profile, and browser-issued Agent session
    - Preserve one deep-cloned bounded provider request across ordered retry candidates and retry only typed pre-mutation provider failures
    - Re-read effective policy, authority, ownership, provider metadata, endpoint, and secret binding at every asynchronous continuation
    - Converge teardown, cancellation, timeout, transport, tool, and late-callback races through generation-fenced exactly-once completion

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap_unittest.cc
    - .context/chromium/src/chrome/test/data/prometheus/runtime/runtime_eval_cases.json
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Keep the provider bootstrap inert unless every non-official launch, disposable regular-profile, absolute owner-only file, closed-schema, and loopback-endpoint gate succeeds before registry mutation."
  - "Keep runtime UI authority private and native: the move-only principal owns one exact Browser/tab Agent session, while persisted and serializable records contain no prompt or authority identifier."
  - "Retry providers only for typed retryable failures before page mutation, preserving the exact bounded request and requiring unchanged current provider configuration before each fallback send."
  - "Treat every provider or Agent callback as untrusted stale work until its generation, principal, ownership, fresh policy, provider binding, and dispatch eligibility are revalidated."
  - "Retain accumulated integer token usage on cancellation and failure while leaving unavailable cost explicitly unknown."

patterns-established:
  - "Closed bootstrap boundary: validate all launch and file facts, parse an exact field set, reject secret-bearing material, then perform the sole metadata registration."
  - "Private principal boundary: exact Browser/tab/profile/session binding and RAII teardown cancel owned work, close the Agent session, and release ownership exactly once."
  - "Fallback boundary: registry order plus typed retryability, pre-mutation state, exact request reuse, and exact current config equality are all mandatory."
  - "Asynchronous safety boundary: loader cancellation and generation checks make every late provider, discovery, and Agent callback inert."

requirements-completed: [FSB-06]
requirements-progressed: [FSB-01, FSB-02, FSB-03, FSB-05, FSB-08]

duration: 9h11min
completed: 2026-07-16
---

# Phase 20 Plan 07: Native Runtime Assembly and Bounded Provider Loop Summary

**A regular-profile native runtime now binds private local Agent authority to bounded provider turns, ordered safe fallback, deterministic cancellation, and a closed 20-case evaluation seam.**

## Performance

- **Duration:** 9h11min
- **Started:** 2026-07-16T04:50:50-05:00
- **Completed:** 2026-07-16T14:02:22-05:00
- **Tasks:** 4
- **Files modified:** 19 including four exported patches and plan metadata

## Accomplishments

- Added the sole built-app provider bootstrap, accepting only an exact non-official test launch, regular disposable profile, absolute non-symlink mode-0600 file, closed schema, and loopback LM Studio endpoint.
- Added one keyed service per regular profile, no OTR service, and a move-only local principal whose exact Browser, tab, ownership, and browser-issued Agent session never enter serializable state.
- Assembled bounded submit, discovery, memory/site-guide access, provider mutation, task observation, cancellation, diagnostics, telemetry, and result APIs over existing native stores.
- Routed every model-selected page operation through one closed safe tool and PrometheusAgentProfileService, with no public runtime route, arbitrary JavaScript, vault tool, process, provider SDK, terminal, or embedded engine.
- Implemented registry-ordered fallback only for retryable pre-mutation failures while preserving the exact provider request and rechecking the current provider configuration, authority, ownership, and policy before every resumed dispatch.
- Generation-fenced provider, discovery, Agent, teardown, timeout, and shutdown races; late callbacks are ignored and loader cancellation hooks run.
- Preserved accumulated integer usage through cancellation or failure and retained unknown cost as unknown.
- Added exactly 20 deterministic evaluation objects across verified benign outcomes, injection/authority containment, vault containment, provider/tool conformance, lifecycle races, fallback/accounting, and memory/site-guide provenance.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Implement the closed non-official built-app provider bootstrap** - nested 73651ebeac; patch export 6c9b1757bf
2. **Task 2 (RED): Specify the runtime-profile service contract** - nested c1f911052c; patch export 7c04a9c7f1
3. **Task 3 (GREEN): Assemble the runtime and apply compatibility, policy, session, and bootstrap primitives** - nested dc60a869c0; patch export fb6af7ca91
4. **Task 4 (GREEN): Close fallback, cancellation, accounting, discovery, and evaluation** - nested 927446177b; patch export e0879d6d17

**Plan metadata:** (this commit)

## Files Created/Modified

- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h - Typed runtime facade, private principal, injected subsystem seams, and bounded asynchronous contracts.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc - Regular-profile task assembly, exact Agent routing, provider loop, fallback, cancellation, accounting, and fresh revalidation.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.h - Regular-profile keyed-service factory contract.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc - Agent-service dependency, one-service-per-regular-profile construction, and OTR denial.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_unittest.cc - Factory, principal, submit, policy, routing, fallback, cancellation, accounting, discovery, evaluation, and race coverage.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.h - Closed bootstrap result and injected fact contracts.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.cc - Exact launch, build, profile, file, schema, endpoint, and mutation gates.
- .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap_unittest.cc - Accepted fixture plus comprehensive fail-closed bootstrap denials.
- .context/chromium/src/chrome/test/data/prometheus/runtime/runtime_eval_cases.json - Closed-schema 20-case deterministic adversarial corpus.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h - Private exact-Browser C++ local execution seam.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc - Exact-Browser validation and native route dispatch.
- .context/chromium/src/chrome/browser/prometheus/BUILD.gn - Runtime service, factory, bootstrap, test data, and test registrations.
- patches/0016-feat-20-07-add-closed-provider-bootstrap.patch - 35,404-byte export of nested Task 1.
- patches/0017-test-20-07-specify-runtime-profile-service-contract.patch - 47,642-byte export of nested Task 2 RED.
- patches/0018-feat-20-07-assemble-runtime-profile-service.patch - 76,891-byte export of nested Task 3 GREEN.
- patches/0019-feat-20-07-close-runtime-fallback-and-evaluation.patch - 72,399-byte export of nested Task 4 GREEN.

## Decisions Made

- The bootstrap has no WebUI, MCP, preference, environment-variable, or secondary parsing path. It mutates registry metadata only after every build, launch, profile, filesystem, schema, and endpoint condition passes.
- The local side panel retains the move-only principal; the runtime receives native authority through exact Browser/tab/session checks and never persists prompt, principal, owner, session, or gateway identifiers.
- Safe titles are derived before task creation. The raw prompt survives only long enough to assemble one bounded provider request and is not retained in task snapshots, observers, restart state, logs, or results.
- Auto follows eligible registry order, Provider excludes local-only routes, and Local requires an already-running eligible loopback route.
- Fallback requires a typed retryable failure before any page mutation, reuses the exact deep-cloned request, preserves the requested execution mode, and fails closed if current provider metadata, endpoint, secret configuration, or binding changed.
- Every initial or resumed provider/Agent dispatch re-reads policy and revalidates authority. Losing authority retires the local principal and makes late callbacks inert.
- FSB-01, FSB-02, FSB-03, FSB-05, and FSB-08 remain semantically open for the later gateway, side-panel, control-panel, settings, and full integration plans. FSB-06 remains complete.

## Deviations from Plan

None - all four planned tasks, TDD boundaries, declared production/test scopes, ordered patch exports, and closed evaluation groups were implemented without source-scope expansion.

## Issues Encountered

- The existing Chromium output directory contained mixed Ninja/Siso state. The autoninja wrapper lacked python3_bin_reldir.txt, while direct autoninja.py correctly refused to switch generators without a destructive gn clean; cleaning was intentionally not performed.
- A direct non-destructive Ninja attempt regenerated a 54,270-edge broad Chromium graph. It reached 6,052 completed edges with zero observed failures before being interrupted at the safe boundary because the graph was not a proportionate Plan 20-07 gate.
- To keep verification specific and non-destructive, the owned translation units were compiled and linked into a focused local test binary using existing output dependencies and temporary link-only stubs under /tmp. No temporary source entered either repository.

## Verification

- Changed production and test translation units compiled cleanly after final formatting.
- Exact non-empty suite guards registered 38 RuntimeProfileService, 14 RuntimeStore, 17 ProviderCodec, 12 ProviderTransport, 11 ProviderRegistry, 16 AgentSession, and 13 RuntimeTestBootstrap cases.
- Exact combined seven-suite focused regression - all 121/121 tests passed.
- Evaluation executor - 1/1 passed and executed exactly 20 unique cases.
- Evaluation schema - exactly 20 closed top-level objects and closed initial/expected objects, unique IDs, all seven established AI-SPEC groups, and no missing group.
- TDD evidence - the complete 16-case Agent-session prerequisite passed before the runtime-owned RED assertions failed; after assembly the runtime plus Agent service gate was 44/44 green before final fallback/race expansion.
- Fallback/race evidence - exact registry order, retryability, pre-mutation gating, request preservation, changed-config denial, authority/policy revalidation, loader cancellation, late provider/discovery/Agent callback fencing, and usage retention all passed.
- Static boundary audit - exact per-task changed-file counts were 4, 8, 6, and 3; no process launch, provider SDK, embedded engine, CLAUDE.md, prompt provisioner, direct-pref bootstrap, or unsafe model tool production addition was found.
- Required link audit - ExecuteBrowserLocalRoute, ApplyRuntimeTestProviderBootstrap, DeriveRuntimeSafeTitle, and IsRetryableProviderFailure are present on their intended native paths.
- Nested and root diff checks, explicit task scopes, ordered non-empty patch sizes, and commit-to-patch identity checks passed.
- Broad target note - the mixed-output full prometheus_unittests target was not completed; the direct graph was intentionally stopped after 6,052/54,270 edges with zero failures observed. The focused 121/121 plus exact evaluation executor are the completion evidence.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. The implementation and evaluation require no real provider key, live third-party service, provider SDK, subprocess runtime, terminal, external account, or manual configuration.

## Next Phase Readiness

Plan 20-08 can add vault metadata and private Agent-authority secret insertion on top of the exact-principal, fresh-policy, generation-fenced runtime. Plan 20-09 can then expose the typed facade without weakening native authority or adding a second execution path.

No source blocker remains. The pre-existing mixed Ninja/Siso output directory should be normalized only through an explicitly authorized build-maintenance action, not as part of this plan.

## Self-Check: PASSED

- FOUND: all 12 declared nested source, test, data, and BUILD paths
- FOUND: nested task commits 73651ebeac, c1f911052c, dc60a869c0, and 927446177b
- FOUND: matching ordered non-empty exports 0016 through 0019
- VERIFIED: exact combined focused native gate 121/121 green
- VERIFIED: exactly 20 deterministic evaluation objects and executor 1/1 green
- VERIFIED: all static product-boundary scans and per-task scope limits green
- VERIFIED: nested source tree clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*
