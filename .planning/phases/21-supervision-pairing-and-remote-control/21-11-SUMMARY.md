---
phase: 21-supervision-pairing-and-remote-control
plan: 11
subsystem: agent-supervision-composition
tags: [chromium, agent, supervision, gateway, composition, lifecycle, tdd]

requires:
  - phase: 21-10
    provides: Five closed native Agent supervision routes and bounded authority-free result values
provides:
  - Exact SessionBinding Browser/stable-tab canonicalization for all five supervision routes
  - Agent-only asynchronous dispatcher seam with exhaustive typed failure and one-shot teardown behavior
  - Sole concrete browser composition bridge for Agent compatibility and dashboard supervision dispatch
  - Acyclic GN ownership separating Agent/gateway targets from concrete supervision implementation
affects: [21-12, phase-21-supervision, agent-gateway, browser-composition]

tech-stack:
  added: []
  patterns:
    - Caller scope is discarded and rebuilt only from the authenticated weak Browser and stable tab binding
    - Agent and gateway code retain neutral callbacks while the top-level browser composition owns concrete lookup
    - Teardown clears dashboard work before Agent dispatch and gateway shutdown

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Canonicalize all five supervision requests from the authenticated SessionBinding and enter Agent service through ExecuteBrowserLocalRoute with the exact live Browser."
  - "Keep the process-wide Agent dispatcher signature limited to BrowserWindowInterface, closed AgentRouteRequest, and RouteCallback; no concrete supervision type crosses into Agent or gateway code."
  - "Make PrometheusBrowserMainExtraParts the only dual-subsystem owner and clear dashboard dispatch before Agent dispatch and gateway shutdown."
  - "Expose a typed not-ready compatibility seam now and leave authoritative stream semantics to Plan 21-12 rather than returning canned success."

patterns-established:
  - "Every supervision route rejects caller target fields, OTR/wrong/deleting Browser state, stale session/window IDs, missing stable tabs, and absent dispatch before concrete semantics."
  - "Late dispatcher completion after Agent service destruction resolves exactly once as browser_shutting_down."
  - "The prometheus_browser_composition target alone owns main-extra-parts and both Agent-gateway and concrete-supervision dependencies."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-03, SUP-05]

duration: 57min
completed: 2026-07-22
---

# Phase 21 Plan 11: Pinned Supervision Dispatch Summary

**All five compatibility commands now traverse the authenticated exact-Browser Agent path through a dependency-neutral dispatcher, while one top-level composition owner binds and tears down both concrete supervision entry points.**

## Performance

- **Duration:** 57min
- **Started:** 2026-07-22T09:51:47Z
- **Completed:** 2026-07-22T10:49:32Z
- **Tasks:** 3
- **Files modified:** 18 including nested Chromium sources, exported patches, verifier, planning state, and this summary

## Accomplishments

- Pinned the five supervision commands to the authenticated SessionBinding weak Browser and stored stable tab. Caller-selected targets are rejected; the gateway rebuilds the canonical target and invokes ExecuteBrowserLocalRoute on the exact regular-profile Browser.
- Added an Agent-only asynchronous dispatcher and exhaustive route classification. Invalid, stale, absent, cleared, and unbound paths return bounded typed failures without reaching concrete semantics, while service destruction safely resolves a retained late callback exactly once.
- Installed both concrete bridges only in PrometheusBrowserMainExtraParts. Agent compatibility resolves the request Browser's exact regular-profile service; dashboard pairing uses bounded unique-owner discovery and later calls use only the retained opaque session owner.
- Split main-extra-parts into prometheus_browser_composition, leaving Agent service/profile/gateway targets free of concrete supervision service, factory, capture, renderer, and implementation dependencies.
- Ordered teardown as dashboard cancellation/clear, Agent dispatcher clear, then gateway shutdown and composition destruction. Repeated clears remain harmless.
- Extended the Phase 21 verifier with exact Agent-session and composition compilation plus pinned-scope, concrete-dependency, GN ownership, sole-bridge, and teardown-order guards.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify pinned gateway scope and exhaustive five-route dispatch** — nested 481a7363c2; patch tracking a60c5dac6
2. **Task 2 (GREEN): Bind dashboard and Agent semantics only at the composition root** — nested 1e9f98949f; patch tracking b4ebad632
3. **Task 3 (GREEN): Prove dual binding, ordered unbind, and layering behavior** — retained tests and structural gates completed in nested 1e9f98949f and patch tracking b4ebad632

## Files Created/Modified

- prometheus_agent_gateway.cc — Explicit five-route classification, authenticated binding validation, stable-tab target canonicalization, and exact Browser-local entry.
- prometheus_agent_service.h / .cc — Dependency-neutral process dispatcher, exhaustive classification, exact live-scope validation, async audit completion, and shutdown-safe late callbacks.
- prometheus_agent_service_unittest.cc — All-five fake dispatch, invalid-target/unbound zero-dispatch, repeated-clear, and post-destruction completion coverage.
- prometheus_agent_profile_service.h — Narrow composition accessors without a concrete supervision friend edge.
- prometheus_supervision_profile_service.h / .cc and factory — Narrow exact-owner/compatibility seams needed by the legal composition root; unavailable remains typed until Plan 12 supplies real semantics.
- prometheus_browser_main_extra_parts.h / .cc — Sole Agent and dashboard concrete composition, bounded pairing-owner lookup, opaque dashboard-session ownership, cancellation, readiness, and ordered teardown.
- Chromium Prometheus BUILD.gn and chrome/browser/BUILD.gn — Separate composition source set linked by the browser while Agent/gateway targets remain acyclic.
- .planning/chromium/verify-phase-21.sh — Exact preservation-object compilation and static pinned-dispatch/layering/teardown guards.
- patches/0028-test-21-11-specify-pinned-supervision-route-dispatch.patch — Exact exported RED contract.
- patches/0029-feat-21-11-wire-pinned-supervision-route-dispatch.patch — Exact exported GREEN implementation.

## Decisions Made

- Gateway callers retain only their authenticated Agent session envelope. Browser, window, tab, and route target scope are reconstructed from the live SessionBinding; no active profile/window lookup or profile-wide dispatch is allowed.
- Agent service owns a closed abstract callback rather than a supervision implementation dependency. The top-level browser composition is the only location allowed to include both subsystem factories and concrete service types.
- Dashboard redeem performs a bounded loaded-regular-profile scan and requires one unique pairing owner. Subsequent dashboard calls retain only an opaque-session-to-weak-service association and never repeat an active-profile search.
- The new ExecuteCompatibilityRoute seam validates exact regular-profile scope but returns capability_not_ready until Plan 12 installs real pairing/session/snapshot/diff/end semantics. Plan 11 proves transport and ownership without inventing success.
- Teardown cancels and clears the dashboard bundle before clearing Agent dispatch, then shuts down the gateway and destroys composition state. This prevents new work and makes late completions bounded.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Build preservation blocker] Recompiled the stale Agent session preservation object**

- **Found during:** Task 1 RED verification
- **Issue:** Plan 10 expanded Agent DTOs, but the preserved prometheus_agent_session.o still carried the prior ABI and prevented the focused binary from reaching the intended GTest failure.
- **Fix:** Added exact Agent-session source compilation to the Phase 21 verifier before the preserved focused link.
- **Files modified:** .planning/chromium/verify-phase-21.sh
- **Verification:** The accepted RED selected one test and failed only its intended assertion; the final focused binary linked and passed all three tests.
- **Committed in:** a60c5dac6 and b4ebad632

**2. [Rule 3 - Missing critical composition seam] Added narrow concrete-service owner and compatibility APIs**

- **Found during:** Task 2 composition binding
- **Issue:** The plan required main-extra-parts to call ExecuteCompatibilityRoute and retain pairing/session owners, but those narrow service APIs did not yet exist and their service files were omitted from files_modified.
- **Fix:** Added exact-scope owner queries, weak-service access, and a fail-closed compatibility stub; updated the factory to use the public narrow Agent composition accessor.
- **Files modified:** prometheus_supervision_profile_service.h / .cc and prometheus_supervision_profile_service_factory.cc
- **Verification:** Direct composition compilation, sole-concrete-owner guards, focused tests, and the complete strengthened verifier pass.
- **Committed in:** nested 1e9f98949f; patch tracking b4ebad632

---

**Total deviations:** 2 auto-fixed (1 build preservation blocker, 1 missing critical composition seam).
**Impact on plan:** Both fixes were required to exercise the reviewed live path and legal composition boundary. The compatibility seam remains fail-closed, so Plan 12 semantics were not pulled forward.

## Issues Encountered

- The first direct composition compile exposed an invalid generic WeakPtr binding for a non-void readiness callback. It was replaced with an explicit weak lambda returning fixed sanitized not-ready state when the composition owner is gone.
- The test fixture initially used a result helper whose copy path was incompatible with the move-only route result. A direct one-shot callback preserved the production ownership contract.

## Test Evidence

- The required RED command selected one Supervision test and failed only through the named fake-dispatch assertion; it did not crash, fail source guards, or select an empty suite.
- The final exact gate selected and passed three PrometheusAgentServiceTest.Supervision* tests covering all five routes, invalid and absent dispatch, repeated clear, and late completion after destruction.
- The verifier directly compiled changed Agent service/session and main-extra-parts composition sources, linked the preserved focused binary, and passed exact binding, no-fallback, no-concrete-Agent-edge, GN ownership, sole-bridge, and teardown-order checks.
- Reviewed build metadata and libblink_modules artifacts remained byte-identical: .ninja_log eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce; .ninja_deps ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0; dylib 663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e; TOC bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b.
- Patches 0028 and 0029 have stable IDs 2a43e4ce6cca0fb4ebd173f777ce7856f1249838 and 41b4823b7084dd7439e5f603d9fd96638fced794, exactly matching ordered nested commits 481a7363c2 and 1e9f98949f.
- Root and nested git diff --check passed and both implementation repositories were clean before summary creation.

Human UAT was not run and is not claimed; Plan 12 owns real end-to-end browser semantics.

## User Setup Required

None. No credentials, external services, listeners, dashboards, or configuration are required.

## Next Phase Readiness

Plan 21-12 can replace the fail-closed compatibility stub with authoritative pairing/session/snapshot/diff/end semantics and prove both production gateway paths against the exact live service owner.

No blockers or threat flags remain. SUP-01, SUP-02, SUP-03, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: nested RED and GREEN commits 481a7363c2 and 1e9f98949f in ordered ancestry
- FOUND: nonempty matching exported patches 0028 and 0029 with exact stable identities
- FOUND: exact SessionBinding Browser/stable-tab canonicalization and browser-local dispatch for all five routes
- FOUND: Agent-only abstract dispatcher with no concrete supervision implementation dependency
- FOUND: sole dual-subsystem composition target with ordered dashboard and Agent unbind
- VERIFIED: intended one-test RED and three-test focused GREEN gates
- VERIFIED: direct composition compilation, GN layering, source privacy, teardown, diff, patch, metadata, and immutable-build-artifact guarantees
- VERIFIED: root and nested implementation repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
