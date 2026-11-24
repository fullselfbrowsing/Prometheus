---
phase: 21-supervision-pairing-and-remote-control
plan: 09
subsystem: browser-supervision-gateway
tags: [chromium, browser, loopback, gateway, supervision, cancellation, health, privacy, tdd]

requires:
  - phase: 21-08
    provides: Exact-target profile-owned dashboard sessions and bounded capture-hub baseline/diff/ack/wait/cancel APIs
provides:
  - One closed authenticated `/v1/supervision` path on the existing IPv4 loopback Agent gateway
  - Dependency-neutral seven-operation dispatch, result, readiness, and cancellation callback bundle
  - Gateway-owned exactly-once completion with timeout, disconnect, unbind, destruction, and shutdown cancellation
  - Bounded content-screened supervision readiness in the existing ten-component health document
affects: [21-10, 21-11, 21-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Browser composition installs a value-owned callback bundle while the gateway retains no concrete supervision service, profile, target, capture, or renderer edge
    - The live HTTP request ID is also the opaque cancel-one token; pending response ownership stays in one gateway map and every terminal path erases it before invoking external cancellation
    - Dashboard transport failures are serialized only through the dedicated Plan 02 codec with fixed bounded fallback errors

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.h
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Represent the abstract supervision gateway seam as a complete value-owned callback bundle so Plan 11 can bind and clear it without a raw interface lifetime."
  - "Use each nonzero live gateway request ID as the opaque cancellation token and retain only expected operation plus one ResponseCallback in gateway state."
  - "Erase pending state before cancel, unbind, shutdown, or result delivery so synchronous and late dispatcher callbacks cannot double-complete or reach stopped I/O."
  - "Accept readiness only when both fixed diagnostic strings are bounded UTF-8, single-line, and free of credential, authority, selector, or page-content markers; otherwise publish a fixed not-ready component."

patterns-established:
  - "`/v1/supervision` parses before generic session handling and invokes only the installed dependency-neutral dispatch callback for redeem, baseline, diff, ack, action, heartbeat, or end."
  - "Absent or incomplete bundles fail closed with typed `UNAVAILABLE`; mismatched, oversized, or unsafe dispatcher output becomes a fixed typed transport failure."
  - "IO timeout and peer close post opaque cancellation to the UI sequence; unbind and shutdown cancel every retained token before invoking the bundle shutdown closure."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-03, SUP-05]

duration: 55min
completed: 2026-07-22
---

# Phase 21 Plan 09: Authenticated Supervision Gateway Summary

**The existing authenticated IPv4 loopback Agent gateway now carries all seven dashboard supervision operations through one dependency-neutral callback bundle, with typed fail-closed responses, cancellation on every transport terminal path, and sanitized health readiness.**

## Performance

- **Duration:** 55min
- **Started:** 2026-07-22T07:49:50Z
- **Completed:** 2026-07-22T08:45:00Z
- **Tasks:** 3
- **Files modified:** 14 including exported patches, planning state, and this summary

## Accomplishments

- Added `/v1/supervision` as the seventh and only new closed path on `PrometheusAgentGateway`; the existing exact Host, IPv4 loopback, no-Origin, constant-time bearer, POST/JSON, size, inflight, timeout, secure-header, and descriptor perimeter remains authoritative.
- Moved the request rejection and one-shot contract into a dependency-neutral gateway header and defined bounded request, result, readiness, cancellation-token, and callback-bundle types with no concrete profile service, Browser, capture hub, WebContents, renderer, or Mojo authority.
- Parsed redeem, baseline, diff, ack, action, heartbeat, and end with the existing Plan 02 supervision codec and forwarded each exact DTO once through the installed fake dispatcher. Malformed input, absent/cleared dispatchers, operation mismatch, and unsafe serialization return typed bounded errors.
- Made the gateway own one pending response per opaque request token. HTTP timeout, peer disconnect, dispatcher replacement, explicit unbind, gateway shutdown, and destruction cancel retained work; late results see no pending entry and cannot complete twice or reach stopped I/O.
- Published supervision health only from the installed bundle's sanitized readiness callback. Missing, cleared, empty, oversized, multiline, credential-bearing, authority-bearing, selector-bearing, or content-bearing diagnostics collapse to fixed `not_ready`; Phase 22 extension readiness remains unchanged.
- Extended direct verification to compile the exact gateway production, unit, and browser objects and reject any concrete supervision service, factory, capture, renderer, or document dependency in the gateway layer.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Extend the real gateway contract with one closed supervision path** - nested `92a213d21b`; patch tracking `771411050`
2. **Task 2 (GREEN): Dispatch all seven operations through the abstract gateway seam** - nested `9789dc9256`; patch tracking `dab3a2aab`
3. **Task 3 (GREEN): Cancel long polls on gateway/dispatcher loss and publish sanitized readiness** - nested `0ac00e13ab`; patch tracking `bd2ed3588`

## Files Created/Modified

- `prometheus_agent_gateway_contract.h` / `.cc` - Closed request perimeter, one-shot helper, dependency-neutral supervision DTOs/callback bundle, and the sole `/v1/supervision` path registration.
- `prometheus_agent_gateway.h` / `.cc` - Strict supervision dispatch, pending completion ownership, typed serialization fallback, transport cancellation, ordered unbind/shutdown, and readiness projection.
- `prometheus_agent_gateway_unittest.cc` - Closed perimeter, all-seven exact DTO forwarding, malformed/absent/mismatch behavior, unbind/shutdown late-result suppression, and readiness privacy coverage.
- `prometheus_agent_gateway_browsertest.cc` - Real authenticated loopback dispatch, perimeter, timeout, disconnect, unbind, shutdown, secure headers, and health transition coverage.
- Browser `BUILD.gn` - Contract and supervision codec dependencies in the existing gateway targets; no parallel listener or concrete supervision edge.
- `.planning/chromium/verify-phase-21.sh` - Exact source-object/browser-object compilation and gateway layering/cancellation/readiness guards.
- `patches/0023-test-21-09-specify-closed-supervision-gateway-contra.patch` - Exact exported RED contract commit.
- `patches/0024-feat-21-09-dispatch-supervision-through-abstract-gat.patch` - Exact exported seven-operation dispatch commit.
- `patches/0025-fix-21-09-cancel-supervision-waits-and-publish-readi.patch` - Exact exported lifecycle/readiness commit.

## Decisions Made

- The gateway owns the callback bundle by value rather than retaining a virtual/raw implementation pointer. This gives Plan 11 one explicit install/clear boundary and makes old-bundle cancellation and shutdown deterministic.
- Cancellation tokens identify only transport lifetime. Live requests reuse the gateway's nonzero request ID; direct tests use a disjoint high-bit sequence. Neither form carries profile, target, viewer, stream, session, pairing, or renderer authority.
- Pending state stores only the expected operation and one response callback. Result delivery checks the operation, erases first, then serializes; cancellation paths move or erase the map before calling external callbacks so reentrancy is harmless.
- Dispatcher loss completes pending live work with a typed unavailable result when I/O is still usable. Gateway shutdown marks I/O as shutting down first, cancels and invalidates callbacks, then lets the existing I/O stop path send its bounded 503 terminal response.
- Readiness remains metadata-only and cannot expand the ten-key health schema. The gateway accepts only short fixed single-line diagnostics and otherwise substitutes fixed content-free recovery text.

## Deviations from Plan

None - the plan's abstract callback-bundle, sole-listener, strict-codec, cancellation, readiness, architecture-guard, unit, and live-browser requirements were implemented as specified. The existing Views browser-test target already registered the gateway fixture, so no additional Views BUILD edit was necessary.

## Issues Encountered

- The initial RED extraction left the one-shot declaration in the old header while its implementation moved with the contract source. Moving the declaration into the new contract header restored the intended dependency boundary before the RED checkpoint was committed.
- One GREEN test over-specified `INVALID_REQUEST` for a legacy forbidden-field shape. It was corrected to assert the closed typed-error invariant (`ok=false` and non-`NONE`) while the codec remains authoritative over the exact rejection class.

## Test Evidence

- Task 1 RED gate selected 2 runnable supervision-contract tests and failed only through the intended ordinary GTest assertions; no crash, fatal process exit, or source-guard failure occurred.
- Task 2 GREEN gate selected and passed 5 supervision gateway unit tests and 2 live loopback browser tests, covering all seven operations, exact DTO variants/tokens, malformed input, absent/cleared dispatcher, perimeter rejection, and secure headers.
- Task 3 GREEN gate selected and passed 8 supervision gateway unit tests and 5 live browser tests, covering pending data completion, timeout, disconnect, unbind, shutdown, late-result suppression, readiness transitions, and privacy fallback.
- Broader regression selected and passed all 24 `PrometheusAgentGatewayTest.*` unit tests and all 14 `PrometheusAgentGatewayBrowserTest.*` live browser tests, preserving session, runtime, Agent command, health, descriptor, inflight, timeout, disconnect, and shutdown behavior.
- Every focused run passed exact gateway contract, ownership, capture-hub, concrete-dependency, and source guards. Exact production/unit/browser objects compiled through the audited commands.
- `.ninja_log` stayed `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` stayed `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`; reviewed `libblink_modules.dylib` stayed `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; its TOC stayed `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patches 0023, 0024, and 0025 have stable IDs `779801c10e5a8cf76b7c34b79ae0b707880b8097`, `9e9c52ac1e194bba2ea9dbdbca9474e7b648c5f5`, and `fe5a4ab9729710eaa47e98443489b11ee339ce12`, exactly matching their nested commits and ordered ancestry.
- Root and nested `git diff --check` passed, and both implementation repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan adds a local authenticated transport seam whose acceptance is fully automated.

## User Setup Required

None. No credentials, external services, listeners, cloud relays, or configuration are required.

## Next Phase Readiness

Plan 21-10 can add the five empty-schema Agent compatibility supervision commands independently of dashboard transport. Plan 21-11 can then bind this dashboard callback bundle in `PrometheusBrowserMainExtraParts`, resolving concrete regular-profile supervision services only at the legal composition root.

No blockers or threat flags remain. SUP-01, SUP-02, SUP-03, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: one `/v1/supervision` path in the existing authenticated loopback gateway and no second listener/server/gateway
- FOUND: dependency-neutral dispatch, cancel-one, sanitized-readiness, and shutdown callbacks with no concrete supervision service/capture/renderer dependency
- FOUND: nested commits `92a213d21b`, `9789dc9256`, and `0ac00e13ab`
- FOUND: matching non-empty exported patches 0023 through 0025 with exact stable identities and ordered ancestry
- VERIFIED: 2-test RED, 8-test focused unit, 5-test focused live-browser, 24-test broader unit, and 14-test broader live-browser gates
- VERIFIED: malformed/absent/mismatch, timeout/disconnect/unbind/shutdown, late completion, health privacy, secure headers, exact-source, and immutable-build-artifact guarantees
- VERIFIED: root and nested implementation repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
