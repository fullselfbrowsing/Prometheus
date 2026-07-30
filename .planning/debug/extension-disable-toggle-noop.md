---
status: awaiting_human_verify
trigger: Phase 22 Plan 22-05 Task 2 — real DOM click on the chrome://extensions item card #enableToggle reports "clicked" but no ExtensionRegistryObserver::OnExtensionUnloaded is ever observed, stalling PrometheusExtensionSmokeController at the kReloaded stage
created: 2026-07-30T08:54:53Z
updated: 2026-07-30T09:30:00Z
phase: 22-chrome-extension-ecosystem-and-policy
plan: 22-05
---

# Debug Session: extension-disable-toggle-noop

## Symptoms

**Expected behavior**
`PrometheusExtensionSmokeController::ClickDisableToggle()` injects a real DOM click on the
extension item card's `#enableToggle` inside `chrome://extensions`. That click should invoke
`chrome.management.setEnabled(id, false)`, which unloads the extension, which fires
`ExtensionRegistryObserver::OnExtensionUnloaded` — letting the smoke controller advance past
the `kReloaded` stage into the disable / enable / local policy matrix / options routing /
remove stages.

**Actual behavior**
The injected script reports `"clicked"` — it verifies the toggle is neither hidden nor
disabled before dispatching. No matching `OnExtensionUnloaded` is ever observed within the
bounded wait window. The controller stalls at `kReloaded`. Every stage after `kReloaded` is
implemented but consequently unverified.

**Error messages**
No crash and no surfaced JS exception. The only failure signal is the bounded-wait timeout.

**Timeline**
New code, never worked. Introduced during Phase 22 Plan 22-05 Task 2 (2026-07-29 / 07-30).
Everything up to and including `kReloaded` (native Load-Unpacked through a one-shot chooser,
real `UnpackedInstaller` install, inspect probe, real unload+load reload cycle) does work
reliably and is verified.

**Reproduction**
```bash
bash .planning/chromium/verify-phase-22-extension-smoke.sh --focused
```

## Eliminated

- hypothesis: Click-event mechanics are wrong (event type, target, dispatch path)
  evidence: The identical injection path successfully drives the developer-mode toggle in the
  same page, in the same controller, earlier in the same run.

- hypothesis: The toggle is disabled or hidden at click time, so the click is a no-op
  evidence: The injected script explicitly checks for hidden and disabled state and only
  reports `"clicked"` after both checks pass.

- hypothesis: The `management` API is unavailable to the `chrome://extensions` WebUI context
  evidence: Confirmed allowlisted for that context in
  `extensions/common/api/_api_features.json`.

## Evidence

- timestamp: 2026-07-30T09:20:00Z
  checked: `chrome/browser/resources/extensions/item.ts` `onEnableToggleChange_()` and
    `service.ts` `setItemEnabled()`
  found: The change handler is
    `this.delegate.setItemEnabled(this.data.id, this.$.enableToggle.checked)` followed by
    `this.$.enableToggle.checked = this.isEnabled_()`. `Service.setItemEnabled()` is
    `chrome.management.setEnabled(id, isEnabled).catch(_ => {})` — errors are silently
    swallowed by design.
  implication: The *direction* of the call is taken from the toggle's own post-flip
    `checked` value, not from an explicit "disable" intent. If `checked` was already
    `false` when the click landed, the click sends `setEnabled(id, true)`. And any
    rejection is invisible.

- timestamp: 2026-07-30T09:22:00Z
  checked: `ui/webui/resources/cr_elements/cr_toggle/cr_toggle.ts`
  found: `cr-toggle` binds its `click` listener in `firstUpdated()`, and `onClick_` calls
    `toggleState_(false)`, which sets `this.checked = !this.checked` **synchronously**, then
    `await this.updateComplete` and only then `this.fire('change', this.checked)`.
  implication: (a) A programmatic `.click()` does drive the toggle — no pointer sequence
    needed, confirming the already-eliminated "click mechanics" hypothesis. (b) The `change`
    handler, and therefore the whole `chrome.management.setEnabled` call, runs in a
    microtask **after** `toggle.click()` returns. The injected script's `"clicked"` return
    value therefore carries no information at all about whether `setEnabled` ran, what
    argument it got, or whether it threw. Any exception in `onEnableToggleChange_` becomes a
    silent unhandled rejection.
  implication2: `checked` read synchronously right after `.click()` is exactly the value the
    later `change` handler will pass to `setItemEnabled`.

- timestamp: 2026-07-30T09:26:00Z
  checked: `chrome/browser/resources/extensions/item_util.ts`
    (`isEnabled`, `userCanChangeEnablement`, `getEnableControl`)
  found: `isEnabled(state)` is true only for `ENABLED`/`TERMINATED`; `DISABLED` → false.
    `userCanChangeEnablement` does **not** consult `disableReasons.reloading`, and
    `getEnableControl` returns `ENABLE_TOGGLE` for anything that is not terminated and not
    a corrupt install.
  implication: An item whose WebUI-side `data.state` is momentarily `DISABLED` because of a
    reload still renders a **visible, non-disabled** `#enableToggle` — it just renders it
    `checked=false`. The controller's existing `hidden_toggle`/`disabled_toggle` retry loop
    cannot detect that case, so the script legitimately reports `"clicked"`.

- timestamp: 2026-07-30T09:30:00Z
  checked: `prometheus_extension_smoke_controller.cc` `OnExtensionLoaded()` reload branch
  found: `ClickDisableToggle()` is invoked **synchronously inside the browser-side
    `ExtensionRegistryObserver::OnExtensionLoaded` callback** for the reload's load half.
    There is no wait for the WebUI's `developerPrivate.onItemStateChanged` round trip to
    re-render the card as enabled, unlike the `PollItemRendered()` step that deviation #3 of
    22-05-SUMMARY.md had to add for exactly this class of lag after install.
  implication: This is the same "native registry event and WebUI re-render are independent
    round trips" bug family that was already found twice in this file. Prime hypothesis.

- timestamp: 2026-07-30T09:34:00Z
  checked: `prometheus_extension_smoke_browsertest.cc`
    `FullLifecycleInstallsInspectsAndReloads`
  found: The test's `RunUntil` predicate is `stage >= kReloaded` and it calls
    `controller->Shutdown()` immediately afterwards. `stage_` is set to `kReloaded`
    on the same line that then calls `ClickDisableToggle()`.
  implication: The current test tears the controller down almost immediately after the
    disable click is issued. The existing binary cannot observe the disable outcome at all;
    any instrumentation run must first extend the wait predicate past `kReloaded`.

- timestamp: 2026-07-30T09:09:24Z
  checked: Instrumented run of `PrometheusExtensionSmokeControllerBrowserTest.
    FullLifecycleInstallsInspectsAndReloads` (log
    `out/Default/phase22-extension-smoke/test.log`, lines 325-336). The disable/enable click
    script was made to return a diagnostic dict and the registry observer callbacks were
    made to log; the browsertest was extended to run to a terminal outcome.
  found: |
    HYPOTHESIS CONFIRMED. First disable-click attempt, executed 4.5 ms after the reload's
    native `OnExtensionLoaded`:
      {"expect":true,"checked_before":false,"hidden":false,"disabled":false,
       "state":"DISABLED","reasons":{... "reloading":true ...},"mgmt":"function"}
    So at click time the card was rendering the reload's *unload* half: `data.state` was
    still `DISABLED` with `disableReasons.reloading === true`, while the toggle itself was
    visible, not disabled, and `checked === false`. `chrome.management.setEnabled` was
    present and callable (`mgmt: "function"`), and no renderer error was recorded
    (`diag: "none"`).
    The retry 204 ms later saw `{"state":"ENABLED","checked_before":true,
    "checked_after":false,"status":"clicked"}` and the matching
    `OnExtensionUnloaded reason=1 pending=3` was observed 0.9 ms later — stage advanced to
    `kDisabled`.
    The enable stage showed the exact mirror image: attempt 1 saw
    `{"expect":false,"checked_before":true,"state":"ENABLED"}`, the retry saw
    `{"state":"DISABLED","checked_before":false,"checked_after":true,"status":"clicked"}`
    and the matching `OnExtensionLoaded` was observed — stage advanced to `kEnabled`.
  implication: |
    The old code clicked a toggle whose rendered `checked` was `false` while the extension
    was natively enabled. `cr-toggle` flipped it to `true`, `extensions-item` then called
    `chrome.management.setEnabled(id, /*enabled=*/true)` on an extension that was already
    enabled — which `ManagementSetEnabledFunction` answers successfully while taking neither
    the enable nor the disable branch, so no registry transition and no
    `OnExtensionUnloaded` ever occurred. The click genuinely happened; it simply asked for
    the state the extension was already in. Same for the enable stage in reverse.

- timestamp: 2026-07-30T09:15:46Z
  checked: `PrometheusExtensionPolicyService::SetRequestedGrantForExtension()` /
    `BuildInventory()` and `ExtensionRegistrar::ActivateExtension()`
  found: `BuildInventory()` sets `entry.ready = registry_->ready_extensions().Contains(id)`
    and the mutation refuses with `kInactiveExtension` unless `inventory[ordinal].ready`.
    `ExtensionRegistrar::ActivateExtension()` calls `registry_->TriggerOnLoaded(extension)`
    (which is our `OnExtensionLoaded` callback) and only *afterwards*
    `registry_->AddReady(extension)` / `TriggerOnReady(extension)`.
  implication: Calling `ExercisePolicyGrants()` synchronously inside `OnExtensionLoaded`
    always observes `ready == false`, so the first grant mutation is guaranteed to be
    refused. Also means `policy_default_blocked_` was passing for the wrong reason:
    `GetEffectiveGrant()` clamps to `kBlocked` for a not-ready extension regardless of the
    stored choice. Same root-cause family (act inside a notification, before the subsystem
    you then query has caught up).

- timestamp: 2026-07-30T09:15:46Z
  checked: Second instrumented run after adding the bounded `PollExtensionReady()` wait
  found: |
    `PDIAG policy read_only ordinal=1 generation=14 rows=2 default_blocked=1 result=0`
    `PDIAG policy interact generation=15 read_only_applied=1 result=0`
    (`result=0` = `kApplied`). Both grant mutations applied, the effective-grant reads
    matched, and the flow reached `kPolicyExercised` and then
    `kOptionsRoutingChecked` (`options routing
    url=chrome-extension://.../options.html visibility=2 crashed=0`).
  implication: The policy-readiness fix is correct and the policy/options stages work.

- timestamp: 2026-07-30T09:15:46Z
  checked: Same run, remaining log (test.log:337-395)
  found: |
    Two further, previously unreachable defects are now exposed, both distinct from the
    reported bug:
    (1) `ERROR:render_process_host_impl.cc: Terminating render process for bad Mojo message:
        Received bad user message: Tried to manipulate an event listener for an unauthorized
        extension ID.` / `bad_message.cc: reason 123`, 0.35 s after the re-enable and
        0.35 s after `OpenOptionsTab()` was issued. `NoRendererCrashesAssertion` fails the
        test on this independently of the controller's own stage. The killed process was not
        the options tab's (`crashed=0`, URL committed). `EventRouter::
        ValidateMainThreadListenerOwner()` only reports this bad message when the extension
        *is* enabled but the sending process is not authorized for it
        (`ShouldIgnoreListenerMessageForUnloadedExtension()` suppresses it otherwise), i.e. a
        stale extension renderer surviving the ~200 ms reload/disable/enable churn.
    (2) `PDIAG remove click result="clicked"` then, exactly 20 s later,
        `PDIAG Fail stage=options_routing_checked reason=remove_not_observed_timeout`. The
        `remove_confirmation_dialog_not_found` path did *not* fire, so
        `TryAcceptVisibleBrowserOwnedDialog()` did find and accept a visible
        browser-owned dialog, yet no `OnExtensionUninstalled` ever arrived. Note
        `Service.deleteItem()` swallows `chrome.runtime.lastError`, so a rejected
        `chrome.management.uninstall()` is silent — the same observability gap that hid the
        original bug.
  implication: Out of scope for this session's reported symptom, but both must be
    root-caused before Plan 22-05 Task 2 can claim `kComplete`. Reported as findings.

- timestamp: 2026-07-30T09:09:24Z
  checked: First instrumented run, `PDIAG Fail` / `PDIAG terminal` lines (test.log:334, 336)
  found: With the toggle stages fixed the controller now advances
    `kReloaded -> kDisabled -> kEnabled` and then fails at a **different, newly reachable**
    stage: `PDIAG Fail stage=enabled reason=policy_read_only_mutation_denied`, logged 35 us
    after the enable's `OnExtensionLoaded` (i.e. synchronously inside that notification).
    `policy_row_not_found` did *not* fire, so the row and ordinal were found;
    `PrometheusExtensionPolicyService::SetRequestedGrantForExtension()` itself returned
    something other than `kApplied`.
  implication: The reported disable-toggle bug is resolved. A separate downstream defect in
    the policy stage is now exposed and must be root-caused for the plan to progress.

## Current Focus

hypothesis: |
  CONFIRMED (see Evidence 09:09:24). Original hypothesis, now established by observation:
  when the reload's native `OnExtensionLoaded` fires, the chrome://extensions WebUI has not
  yet processed the matching `developerPrivate.onItemStateChanged` round trip, so the item
  card's `data.state` is still `DISABLED` from the reload's unload half. The card therefore
  renders `#enableToggle` visible and enabled but with `checked === false`. The injected
  click flips it to `true`, so `onEnableToggleChange_` calls
  `chrome.management.setEnabled(id, true)` on an extension that is already enabled — a
  silent no-op that produces no `OnExtensionUnloaded`, hence the stall.
test: |
  DONE. Instrumented build (disable/enable click script returning a diagnostic dict, registry
  observer logging, browsertest extended to a terminal outcome), then a clean fix-only build
  verified by `bash .planning/chromium/verify-phase-22-extension-smoke.sh --focused`.
expecting: |
  Predicted `checked_before === false` / `state === "DISABLED"` on the first attempt.
  Observed exactly that. Alternative branch (`checked_before === true` with the disable still
  dropped, which would have implicated the browser-side management/registrar path) was ruled
  out by the same run.
next_action: |
  Awaiting human confirmation. Nothing is committed yet: the fix sits uncommitted in the
  nested Chromium worktree (3 modified files) and this debug file is untracked in the root
  repo. On confirmation, commit both and archive this session.

reasoning_checkpoint:
  hypothesis: |
    The controller clicks `#enableToggle` synchronously inside the browser-side
    `ExtensionRegistryObserver` notification, before chrome://extensions has processed its own
    `developerPrivate.onItemStateChanged` round trip. The card therefore still renders the
    pre-transition `checked` value while being neither hidden nor disabled, so the click flips
    the toggle the wrong way and `extensions-item` asks
    `chrome.management.setEnabled(id, <state the extension is already in>)`, which succeeds
    without any registry transition.
  confirming_evidence:
    - "Direct observation: first disable click (4.5 ms after the reload's OnExtensionLoaded)
       reported `state:\"DISABLED\", disableReasons.reloading:true, hidden:false,
       disabled:false, checked_before:false` while the native registry had the extension
       enabled."
    - "`chrome.management.setEnabled` was present and callable (`mgmt:\"function\"`) and no
       renderer error was captured (`diag:\"none\"`), eliminating an unavailable-API or
       thrown-exception explanation."
    - "Retry 204 ms later observed `state:\"ENABLED\", checked_before:true` and the matching
       `OnExtensionUnloaded reason=1 pending=3` arrived 0.9 ms after the click."
    - "The enable stage reproduced the exact mirror image, so the mechanism is direction-
       symmetric rather than a one-off."
    - "Source confirmation: `item.ts::onEnableToggleChange_()` passes
       `this.$.enableToggle.checked` (post-flip) to `setItemEnabled`, and
       `service.ts::setItemEnabled()` calls `chrome.management.setEnabled(id, isEnabled)` with
       `.catch(_ => {})`; `cr_toggle.ts::toggleState_()` fires `change` only after
       `await this.updateComplete`, so the injected script's `\"clicked\"` return value is
       emitted before any of that runs."
  falsification_test: |
    A first-attempt observation of `checked_before === true` / `state === "ENABLED"` together
    with a still-missing `OnExtensionUnloaded` would have disproven this and moved the
    investigation to the browser-side management/registrar path. That was designed into the
    same experiment and did not occur.
  fix_rationale: |
    The fix makes the click conditional on the toggle's rendered `checked` value matching the
    native state the controller just observed, and folds the mismatch into the existing
    bounded retry loop as `toggle_state_not_settled`. It addresses the cause (acting on a
    stale WebUI render) rather than the symptom (the missing unload), it does not weaken or
    bypass any verification path, and a permanent mismatch now produces an explicit
    `disable_click_failed:toggle_state_not_settled` failure instead of a silent 20 s stall.
  blind_spots: |
    - The retained assertion boundary is `kEnabled`; the `PollExtensionReady()` policy fix was
      observed working in the instrumented run but is not covered by a retained assertion,
      because driving past `kPolicyExercised` trips the two unrelated defects recorded above.
    - Everything is verified inside the synthesized `prometheus_extension_smoke_tests` binary,
      not against the packaged `Prometheus.app` (that smoke script still does not exist).
    - Timing margins are wide (204 ms observed against a 10 s bounded retry) but were measured
      on one machine only.

## Resolution

root_cause: |
  `PrometheusExtensionSmokeController` issued the `#enableToggle` click synchronously from
  inside the browser-side `ExtensionRegistryObserver` callback for the preceding transition,
  so chrome://extensions had not yet processed its own independent
  `developerPrivate.onItemStateChanged` round trip. The item card still rendered the previous
  state — `data.state == "DISABLED"` with `disableReasons.reloading == true` after the reload
  — and that stale render is neither `hidden` nor `disabled` (`userCanChangeEnablement()`
  ignores `reloading`, `getEnableControl()` still returns `ENABLE_TOGGLE`), so the controller's
  hidden/disabled pre-checks passed and it clicked a toggle whose `checked` was `false`.
  `cr-toggle` flipped `checked` to `true` and `extensions-item::onEnableToggleChange_()` then
  called `chrome.management.setEnabled(id, /*enabled=*/true)` on an extension that was already
  enabled. `ManagementSetEnabledFunction` takes neither the enable nor the disable branch in
  that case, so it succeeds with no registry mutation: no `OnExtensionUnloaded`, and the
  bounded wait expired. The click really happened — it just requested the state the extension
  was already in. Two properties kept this invisible: `cr-toggle::toggleState_()` fires
  `change` only after `await this.updateComplete`, so the injected script returns `"clicked"`
  before the API call is even made; and `Service.setItemEnabled()` ends in `.catch(_ => {})`.
fix: |
  1. `EnableToggleClickScript()` now takes `expect_checked` and returns the new retryable
     status `toggle_state_not_settled` when `!!toggle.checked !== expect_checked`, instead of
     clicking. `ClickDisableToggle()` passes `expect_checked=true` (a load was just observed),
     `ClickEnableToggle()` passes `false`. Both `OnDisableClickIssued()`/`OnEnableClickIssued()`
     treat the new status like the existing `hidden_toggle`/`disabled_toggle` transients and
     retry within the existing `kToggleActionableTimeout` (10 s) window.
  2. Same-root-cause fix for the newly reachable policy stage: `ExercisePolicyGrants()` is no
     longer called from inside `OnExtensionLoaded`. A new bounded `PollExtensionReady()` waits
     for `ExtensionSystem::is_ready()` and `ExtensionRegistry::ready_extensions().Contains(id)`
     first, because `ExtensionRegistrar::ActivateExtension()` calls `AddReady()` only *after*
     the `TriggerOnLoaded()` observer loop, and every `PrometheusExtensionPolicyService`
     decision is gated on `ready` (mutations return `kInactiveExtension`, effective grants
     clamp to `kBlocked`).
  3. Latent-bug guard directly protecting the new retry loop: `pending_wait_generation_` is now
     retired at each point where a pending transition is satisfied, so a satisfied stage's
     still-queued timeout task can no longer fire against the next stage and fail the smoke
     under the previous stage's reason.
  4. `FullLifecycleInstallsInspectsAndReloads` now asserts `>= kEnabled` instead of
     `>= kReloaded`, with the comment updated to name the two remaining unresolved defects.
  No verification path was weakened: no MV2 enablement, no install-verification bypass, no
  `accept_dialog_for_testing_`, no direct installer/registrar mutation. The script's static
  no-bypass guards still pass.
verification: |
  `bash .planning/chromium/verify-phase-22-extension-smoke.sh --focused` → exit 0,
  "selected 26 bootstrap unit, 2 developer-private caller, and 4 controller browser test(s)",
  "focused suite passed with zero retry, skip, or failure", `SUCCESS: all tests passed.`
  Reviewed `.ninja_log`/`.ninja_deps` SHA-256 unchanged before/after.
  Stability: `FullLifecycleInstallsInspectsAndReloads` run 13 more times directly against the
  built binary — 11 passes; the 2 failures are both pre-existing environment flakes already
  documented in 22-05-SUMMARY.md item 6 and both occur outside the test body
  (`ChromeBrowserMainPartsMac::PreEarlyInitialization()` →
  `base::mac::WasLaunchedAsLoginItemRestoreState()` → LaunchServices `BUS_ADRALN` during
  browser startup; and the pre-existing `DCHECK failed: ptr_.` at
  `PrometheusBrowserMainExtraParts::PostMainMessageLoopRun()`'s first line during
  browser-process shutdown). No run ever failed with "never reached kEnabled".
files_changed:
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_browsertest.cc

## Findings Handed Back (NOT fixed here — separate defects)

1. **Renderer terminated for a bad Mojo message during the options stage.**
   `Terminating render process for bad Mojo message: Received bad user message: Tried to
   manipulate an event listener for an unauthorized extension ID.` (`bad_message` reason 123),
   0.35 s after the re-enable and 0.35 s after `OpenOptionsTab()`. The options tab itself was
   fine (`crashed=0`, URL committed), so a different process was killed.
   `EventRouter::ValidateMainThreadListenerOwner()` emits this only when the extension *is*
   enabled but the sending process is not authorized for it
   (`ShouldIgnoreListenerMessageForUnloadedExtension()` suppresses it otherwise) — consistent
   with a stale extension renderer / service-worker process surviving the ~200 ms
   reload→disable→enable churn. `NoRendererCrashesAssertion` fails the browser test on this
   regardless of controller state, so no assertion can be raised past `kEnabled` until it is
   resolved. Related churn signal in the same logs:
   `service_worker_task_queue.cc:1007 Failed to unregister service worker ... error status
   was: 2`.
2. **`remove_not_observed_timeout`.** The `#removeButton` click reports `"clicked"` and
   `TryAcceptVisibleBrowserOwnedDialog()` does find and accept a visible browser-owned dialog
   (the `remove_confirmation_dialog_not_found` path never fires), yet no
   `OnExtensionUninstalled` arrives within 20 s. Note `Service.deleteItem()` swallows
   `chrome.runtime.lastError`, the same observability gap that hid the original bug — worth
   instrumenting the same way. Also worth checking whether the accepted dialog was actually
   the uninstall confirmation and whether `chrome.management.uninstall()` needs a user gesture
   that `RenderFrameHost::ExecuteJavaScript()` does not convey.
3. **`policy_default_blocked_` was a false positive before fix 2.** `GetEffectiveGrant()`
   clamps to `kBlocked` for a not-yet-ready extension, so the "default is Blocked" assertion
   passed for the wrong reason. With `PollExtensionReady()` in place it is now meaningful, but
   the stage has no retained assertion yet.
4. **No patch export needed yet.** `.planning/phases/22-.../patches/` stops at
   `0016-fix-22-04-...`; both existing 22-05 nested commits are also unexported. Task 3 exports
   everything after the frozen baseline, so this fix's commit will be picked up there.

## Relevant Files

- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.h`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_browsertest.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap.cc`
- `.planning/chromium/verify-phase-22-extension-smoke.sh`
