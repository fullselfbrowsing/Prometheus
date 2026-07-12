---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 07
subsystem: browser-page-verification
tags: [chromium, cpp, page-settlement, webcontents-lifecycle, action-history]

# Dependency graph
requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 04
    provides: Permissioned asynchronous page execution and exact-once operation ownership patterns
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 05
    provides: Document-scoped element refs and bounded page-result contracts
provides:
  - One-shot always-asynchronous post-action settlement waits over PageSettledMonitor
  - Typed timeout and target-gone outcomes with exact-once lifecycle handling
  - Bounded per-session and per-tab repeated-action fingerprint detection
  - Focused mock-time unit coverage and actor-independent GN targets
affects: [18-08, PAGE-06, PAGE-07, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Wait completion transfers monitor ownership to a posted task so callbacks are always asynchronous and the monitor cannot self-delete on its ready stack.
    - Repeated-action history uses a last-10 detection window, 50-entry per-target storage, and 256-key LRU ceiling.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_waiter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_waiter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_waiter_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_history.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_history.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_history_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "PrometheusPageWaiter is explicitly one-shot; callers retain each waiter through its posted completion callback."
  - "The waiter observes WebContents separately, never retains a RenderFrameHost, and reports destruction during a pending wait as target_gone."
  - "Prometheus's independent 8-second timer starts before the default delegate's 10-second component timeout, so the typed timeout wins under the concrete default configuration."
  - "Plan 18-08 owns mapping the history helper's bool result to AgentErrorCode::kRepeatedAction; the storage helper has no route-layer dependency."

patterns-established:
  - "Async completion funnel: settled, timeout, missing target, and target destruction all invalidate late callbacks and post exactly one result."
  - "Fingerprint contract: stable action-kind plus resolved ref only, capped at 512 bytes; never request text, key, option, JavaScript, selector, or file data."

requirements-completed: []
requirements-progressed: [PAGE-06, PAGE-07]

# Metrics
duration: 16min
completed: 2026-07-12
---

# Phase 18 Plan 07: Page Settlement and Repeated-Action Detection Summary

**Added lifecycle-safe bounded page-settlement waits and content-free repeated-action detection, ready for Plan 18-08 route wiring.**

## Performance

- **Duration:** 16min
- **Started:** 2026-07-12T14:25:57Z
- **Completed:** 2026-07-12T14:42:25Z
- **Tasks:** 3 completed
- **Files created/modified:** 7

## Accomplishments

- Wrapped Chromium's `PageSettledMonitor` with its concrete default `Delegate`, an independent 8-second cap, and no actor dependency.
- Made every waiter result asynchronous and exactly once, including a missing target at entry, `WebContents` destruction during the wait, timeout, and late monitor callbacks.
- Avoided stale frame use by resolving `WebContents` once at entry, never retaining the `RenderFrameHost`, and observing target lifetime separately.
- Added repeated-action detection for the third or later identical content-free fingerprint within the latest 10 actions for one session and tab.
- Bounded memory to 50 actions per target, 512 bytes per fingerprint, and 256 least-recently-used session/tab keys.

## Task Commits

Each TDD step was committed atomically inside the nested `.context/chromium/src` checkout:

1. **Task 1 RED: Specify page-waiter lifecycle behavior** - `aedef02ca9` (test)
2. **Task 1 GREEN: Add bounded page settlement waiter and GN target** - `1bf1b5556a` (feat)
3. **Task 2 RED: Specify repeated-action history behavior** - `71fd5fee26` (test)
4. **Task 2 GREEN / Task 3 wiring: Add bounded action history and unit target wiring** - `fb79a2452a` (feat)
5. **Lifecycle safety fix: Defer monitor destruction past its ready callback stack** - `4a16569a51` (fix)

**Plan metadata:** this root planning commit

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_waiter.h/.cc` - One-shot waiter, independent timeout, `WebContents` destruction observation, and posted exact-once completion.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_waiter_unittest.cc` - Four mock-time tests covering settled, timeout, missing target, destruction during wait, and late callbacks.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_history.h/.cc` - Per-session/tab last-10 detector with bounded entry, fingerprint, and key storage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_history_unittest.cc` - Six tests covering repeat threshold, isolation, detection window, storage caps, LRU key bound, and reset.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Actor-independent waiter/history source sets and focused unit-test wiring.

## Decisions Made

- The waiter is one-shot by contract and rejects a second `Wait`; this prevents a late callback from one action being attributed to another.
- The caller must retain the waiter through completion. Plan 18-08's asynchronous action operation will provide that ownership.
- `PageSettledMonitor::ReadyCallback` does not distinguish its internal timeout. With the required default concrete delegate, its default timeout is 10 seconds; the independently scheduled Prometheus timer fires at 8 seconds and invalidates the later result-less callback.
- History returns `bool` rather than depending on route types. Plan 18-08 performs the typed `kRepeatedAction` mapping at the caller boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Lifecycle correctness] Detect target destruction throughout the wait**
- **Found during:** Task 1 preflight against actual `WebContentsObserver` semantics
- **Issue:** The plan pseudocode checked only for a missing `WebContents` at entry, which could leave destruction during a pending wait mislabeled or delayed until another callback.
- **Fix:** Made the waiter a separate `WebContentsObserver` and funneled `WebContentsDestroyed` through the exact-once `target_gone` completion path without retaining or dereferencing a stale frame.
- **Files modified:** `prometheus_page_waiter.h/.cc`, `prometheus_page_waiter_unittest.cc`
- **Verification:** `TargetDestroyedDuringWaitCompletesExactlyOnce` passed with mock time; late ready and timeout callbacks remained inert.
- **Committed in:** `1bf1b5556a`

**2. [Rule 1 - Reentrancy safety] Avoid deleting PageSettledMonitor from its own callback stack**
- **Found during:** Final Task 1 callback-stack review
- **Issue:** `PageSettledMonitor::MoveToState(kDone)` invokes the ready closure inline; resetting the owned monitor inside `OnSettled` would delete it while its member function was still active.
- **Fix:** Moved monitor ownership into the posted delivery task, which destroys the monitor only after the ready callback unwinds and before notifying the external caller.
- **Files modified:** `prometheus_page_waiter.h/.cc`, `prometheus_page_waiter_unittest.cc`
- **Verification:** Rebuilt the unit target and passed all 10 focused tests after the fix.
- **Committed in:** `4a16569a51`

**3. [Rule 2 - Resource bound] Bound the session/tab key map itself**
- **Found during:** Task 2 threat-model review
- **Issue:** A 50-entry cap per key still allowed the number of historical session/tab keys to grow without limit in a long-lived service.
- **Fix:** Added a 256-key least-recently-used ceiling while preserving the required 50-entry per-key cap and last-10 detection window.
- **Files modified:** `prometheus_page_action_history.h/.cc`, `prometheus_page_action_history_unittest.cc`
- **Verification:** `TargetKeyMapIsGloballyBounded` and `PerTargetHistoryIsCappedAtFifty` passed.
- **Committed in:** `fb79a2452a`

---

**Total deviations:** 3 auto-fixed (2 lifecycle correctness, 1 missing resource bound).
**Impact on plan:** The fixes close destruction, reentrancy, and long-lived memory risks without adding actor, MCP, runtime, terminal, bundled CLI, or alternate-engine dependencies.

## Issues Encountered

None unresolved. The monitor self-deletion risk was found during final review and corrected before metadata completion.

## Verification

- `../../depot_tools/autoninja -C out/Default prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageWaiter*:*PrometheusPageActionHistory*'` - passed, 10/10 (4 waiter + 6 history).
- Direct-source and resolved GN dependency scans - passed; no `//chrome/browser/actor` dependency.
- Plan key links - passed, 2/2 (`PageSettledMonitor` default delegate and Plan 18-08 `kRepeatedAction` caller contract).
- Scoped committed-range `git diff --check` - passed.
- Chromium environment, Falkon GPL guard, artifact isolation, and preservation verification - passed.
- Nested Chromium working tree - clean after all five source/test commits.

## User Setup Required

None - no external service configuration or human UAT required.

## Next Phase Readiness

Plan 18-08 can retain one waiter per asynchronous action operation, map timeout/target-gone results into action verification reports, and map `RecordAndCheck == true` to `AgentErrorCode::kRepeatedAction`. PAGE-06 and PAGE-07 remain open until full Phase 18 verification; this plan records progress only.

## Self-Check: PASSED

- FOUND: all six created waiter/history files and the modified GN target.
- FOUND: five nested Chromium commits from `aedef02ca9` through `4a16569a51`.
- PASSED: unit build, 10 focused tests, actor dependency scans, 2/2 key links, diff checks, and four inherited root gates.
- CLEAN: nested Chromium working tree before root metadata creation.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
