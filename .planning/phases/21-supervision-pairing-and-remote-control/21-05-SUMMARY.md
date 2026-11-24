---
phase: 21-supervision-pairing-and-remote-control
plan: 05
subsystem: supervision-profile-composition
tags: [chromium, cpp, supervision, keyed-service, profile, lifecycle, tdd]

requires:
  - phase: 21-04
    provides: Agent-owned observation leases and exact-target supervision lifecycle service
provides:
  - One regular-profile supervision keyed service composed over the exact profile's Agent service
  - Narrow Agent-profile observation forwarding with no second tab-data owner or authority mutator
  - Explicit keyed-service dependency plus weak callback invalidation across both teardown orders
  - Static architecture gates for sole Agent ownership and regular-profile-only composition
affects: [21-06, 21-07, 21-08, 21-09, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Profile keyed-service factories compose exact-profile dependencies and reject null, OTR, missing, and mismatched inputs
    - Supervision retains only a weak Agent-profile observation callback and move-only observation leases
    - Direct verification statically rejects any second tab-data lifecycle path outside PrometheusAgentService

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Compose supervision only through ProfileSelections::BuildForRegularProfile and an explicit dependency on PrometheusAgentProfileServiceFactory."
  - "Inject a weak, exact-profile observation callback rather than exposing PrometheusAgentService or any ownership mutator."
  - "Treat voluntary lease release as observer unregistration before deferred pruning, while Agent-first teardown notifies supervision and posts final observed-entry release."

patterns-established:
  - "Null, OTR, missing Agent service, and wrong-profile Agent service inputs all fail closed before supervision allocation."
  - "Supervision-first shutdown drops leases before Agent destruction; Agent-first shutdown invalidates weak forwarding and lease tokens before tab data is erased."
  - "Factory/profile focus filters must select nonempty cohorts, pass direct linking, and leave Ninja metadata byte-identical."

requirements-completed: []
requirements-progressed: [SUP-03, SUP-04, SUP-05]

duration: 1h28min
completed: 2026-07-21
---

# Phase 21 Plan 05: Regular-Profile Agent/Supervision Composition Summary

**Every regular profile now receives one supervision keyed service backed only by its exact Agent profile service's weak observation seam, with OTR and mismatched dependencies denied and both teardown orders proven safe.**

## Performance

- **Duration:** 1h28min
- **Started:** 2026-07-22T00:41:07Z
- **Completed:** 2026-07-22T02:08:54Z
- **Tasks:** 2
- **Files modified:** 13 including exported patches, planning state, and this summary

## Accomplishments

- Added `PrometheusAgentProfileService::ObserveOrCreateTabData` as the sole narrow profile-level forwarding seam to Agent-owned observation leases, without exposing the underlying service or any claim, detach, registry, or destruction authority.
- Added `PrometheusSupervisionProfileServiceFactory` using the repository's `base::NoDestructor`, `base::PassKey`, `ProfileKeyedServiceFactory`, and `ProfileSelections::BuildForRegularProfile()` pattern.
- Declared the Agent profile factory dependency before resolving the exact regular profile's Agent service, then injected only a weak forwarding callback into supervision.
- Rejected null profiles, OTR profiles, missing Agent services, and Agent services belonging to another profile before allocating supervision state.
- Covered regular construction, singleton factory identity, exact dependency, forwarding owner transitions, last release, detach, supervision-first teardown, Agent-first teardown, and harmless late lease destruction.
- Extended the direct verifier with ownership/dependency static guards and retained nonempty profile/factory cohorts while preserving both Ninja metadata files byte-for-byte.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify the Agent/supervision composition boundary** - nested `51a7295a5b`; patch tracking `77dcf5dbb`
2. **Task 2 (GREEN): Compose regular-profile supervision over Agent observation** - nested `e11d8fe928`; patch tracking `81de7b4b6`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h` / `.cc` - Narrow observation forwarding, test construction seam, and weak lifetime boundary.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_unittest.cc` - Four forwarding, transition, last-release, detach, and destruction fixtures.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.h` / `.cc` - Regular-profile-only keyed construction, explicit Agent dependency, exact-profile validation, and weak callback injection.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc` - Factory selection, dependency failure, exact-profile denial, and both service teardown orders.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Factory and Agent-profile unit registration plus direct-link dependencies.
- `.planning/chromium/verify-phase-21.sh` - Direct factory/profile compilation and static sole-owner/dependency guards.
- `patches/0011-test-21-05-specify-Agent-supervision-composition-bou.patch` - Exact exported RED contract commit.
- `patches/0012-feat-21-05-compose-regular-profile-supervision.patch` - Exact exported GREEN composition commit.

## Decisions Made

- The supervision factory is the only code allowed to discover and compose the Agent profile service. The supervision service itself has no Agent factory reference and receives no globally discoverable Agent pointer.
- Construction uses `ProfileSelections::BuildForRegularProfile()` and also rejects OTR explicitly at lookup and build boundaries. Missing or wrong-profile dependencies return null rather than creating partial authority.
- The forwarding callback captures `PrometheusAgentProfileService` through a weak pointer. Agent shutdown invalidates that pointer before its observation registry and tab data disappear, so later callback invocations and lease destructors fail closed.
- A voluntary final lease release unregisters that observer before deferred unowned pruning; it therefore receives no destruction notification. Destructive detach or Agent teardown invalidates live tokens first and does notify registered observers.
- Agent-first destruction schedules supervision's now-unused observed entry for sequence-safe release; tests drain the task environment before asserting final removal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced heavyweight profile fixtures with the repository's opaque-profile test seam**

- **Found during:** Task 1 RED gate
- **Issue:** Constructing `TestingProfile` inside the direct-linked focused binary eagerly required browser-test globals such as user-data paths, resource bundles, the content browser client, and App Service publishers that this verifier intentionally does not initialize.
- **Fix:** Added a test-only Agent profile constructor accepting an opaque non-null `Profile*` identity, retained production profile validation unchanged, and exercised exact/mismatched identities through factory test probes.
- **Files modified:** Agent profile service header/implementation and both profile-service unit suites.
- **Verification:** The accepted RED run selected eight tests and failed only intended ordinary GTest assertions; the final exact focus passed 8/8 without a crash or fatal initialization dependency.
- **Committed in:** `77dcf5dbb` (Task 1 patch tracking commit)

---

**Total deviations:** 1 auto-fixed blocking verification issue.
**Impact on plan:** The lightweight seam made the planned direct RED/GREEN tests executable without changing production construction, profile selection, or authority behavior.

## Issues Encountered

- The first GREEN run passed compilation and six of eight tests. Two assertions incorrectly expected a voluntarily released observer to receive destruction and expected an asynchronously posted Agent-first cleanup to have already run. Aligning those assertions with the established lease contract produced the final 8/8 and 68/68 passes without a production change.

## Test Evidence

- RED gate - the exact factory/profile filter selected 8 tests and failed only through the intended new GTest assertions; there were no crashes, fatals, or missing fixtures.
- GREEN gate - the same exact filter selected and passed 8/8 factory, forwarding, transition, release, detach, and teardown tests.
- Regression gate - all 68 retained supervision types, transport codec, projection, diff, complete profile-service, and Agent-profile forwarding tests passed together.
- Architecture gate - static checks require regular-profile selection, the explicit Agent factory dependency, exact `GetForProfile` resolution, Agent forwarding, and weak-pointer binding.
- Sole-owner gate - static checks reject `GetOrCreateForTab`, `EnsureTabData`, detach registration, owned tab-data storage, observation invalidation, and pruning paths from Agent profile, supervision, and composition factory sources while requiring them in `PrometheusAgentService`.
- Authority/privacy gate - composition sources expose observation only and contain no Agent claim or serialized page/credential authority; retained projection and transport privacy fixtures passed in the 68-test regression.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after both final runs.
- Patch identity - patches 0011 and 0012 have stable IDs `a4cfe25127204f7b636f89cddff514d066579b62` and `51a81fb617bd8a4cda87edf526ee14d4e5b75a39`, exactly matching their nested commits.
- Root and nested `git diff --check` - passed before documentation closeout; nested Chromium was clean after the GREEN commit.

Human UAT was not run and is not claimed; this plan establishes native profile composition and teardown safety with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-06 can add the Blink document supplement and bidirectional dirty-signal Mojo path on top of one safely composed regular-profile supervision owner without inventing another Agent tab-data lifetime.

No blockers or threat flags remain. SUP-03, SUP-04, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: all seven planned Chromium source/build artifacts plus verifier wiring
- FOUND: nested RED/GREEN commits `51a7295a5b` and `e11d8fe928`
- FOUND: matching non-empty exported patches `0011` and `0012` with exact stable identities
- VERIFIED: 8-test RED, 8-test GREEN, and 68-test combined regression; exact metadata hashes unchanged and authority/privacy searches clean
- VERIFIED: nested Chromium clean and root implementation commits recorded before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
