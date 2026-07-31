---
status: awaiting_human_verify
trigger: Phase 22 Plan 22-05 Task 2 — real DOM click on the chrome://extensions item card #enableToggle reports "clicked" but no ExtensionRegistryObserver::OnExtensionUnloaded is ever observed, stalling PrometheusExtensionSmokeController at the kReloaded stage
created: 2026-07-30T08:54:53Z
updated: 2026-07-31T01:40:34Z
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

## Evidence (continued — downstream defects)

- timestamp: 2026-07-30T07:45:08Z
  checked: |
    Instrumented build 1 (`/tmp/pdiag-run1.log`). Added: a test-side
    `RenderProcessHostCreationObserver`/`RenderProcessHostObserver` tracer logging every
    renderer's create/ready/exit(status,exit_code)/destroy; controller-side `PDIAG procs[...]`
    snapshots at each stage listing every `RenderProcessHost` with its `ProcessMap` extension
    mapping plus `ProcessManager::GetServiceWorkersForExtension()` /
    `GetRenderFrameHostsForExtension()`; `TryAcceptVisibleBrowserOwnedDialog()` logging every
    visible browser-owned widget's `Widget::GetName()`/`GetWindowTitle()`; a diagnostic second
    `chrome.management.uninstall()` call whose rejection is stashed on `window` and read back;
    and the browsertest predicate extended from `>= kEnabled` to a terminal outcome.
  found: |
    DEFECT 2 ROOT CAUSE CONFIRMED, verbatim:
      `PDIAG uninstall_probe=rejected:chrome.management.uninstall requires a user gesture.`
    (repeated on every 200 ms poll). That is `keys::kGestureNeededForUninstallError` from
    `ManagementUninstallFunctionBase::Uninstall()`:
      `if (show_confirm_dialog && !user_gesture()) return RespondNow(Error(kGestureNeeded...));`
    `Service.deleteItem()` calls `chrome.management.uninstall(id, {showConfirmDialog:true})`,
    and for a WebUI caller `extension()` is null so `self_uninstall` is false and
    `show_confirm_dialog |= !self_uninstall` forces it true. The uninstall therefore never
    starts at all.
    Also: ZERO `PDIAG owned_widget` lines were emitted across the whole 10 s dialog poll, so no
    visible browser-owned widget existed at any point — the uninstall confirmation dialog was
    never created (consistent with the API rejecting before `UninstallFunctionDelegate()`), and
    the previous session's "a visible browser-owned dialog was accepted" observation did not
    reproduce.
  implication: |
    `RenderFrameHost::ExecuteJavaScript()` conveys no user activation, so the injected
    `button.click()` produces an untrusted click with no transient activation. The gesture gate
    is an anti-abuse gate on the API, not the user-consent gate (the confirmation dialog is the
    consent gate). A faithful fix must make the click a real user-activated click rather than
    fabricate the activation signal.

- timestamp: 2026-07-30T07:45:08Z
  checked: Same run — renderer process lifecycle around the bad Mojo message
  found: |
    DEFECT 1 LEADING THEORY DISPROVEN. The killed renderer is NOT a stale pre-disable process.
    Timeline (all 0730/0744xx):
      56.369760 rph_created id=10
      56.559032 procs[reloaded]      rph=10 live pm=ohbeakalcafjdggcmdohgkgannopghdg
      56.765536 procs[disabled]      rph=10 live pm=ohbeakal...  (extension now unloaded)
      56.936697 rph_ready id=10      <- the old extension process only finished launching here
      56.957864 rph_exited id=10 status=0 exit_code=0 ; 56.957966 rph_destroyed id=10
      56.958753 rph_created id=11    <- 0.8 ms after 10 died, 13 ms BEFORE the re-enable
      56.971765 procs[enabled]       rph=11 live pm=-      (extension re-enabled here)
      57.172482 procs[ready]         rph=11 live pm=-
      57.172592 procs[policy_exercised] rph=11 live pm=-
      57.183284 rph_created id=12 ; 57.193352 procs[options_tab_opened] rph=12 pm=ohbeakal...,
                                                                        rph=11 pm=-
      57.518602 rph_ready id=11      <- 560 ms launch
      57.540644 Terminating render process for bad Mojo message: ... unauthorized extension ID
      57.540804 bad_message.cc reason 123 (= RPH_MOJO_PROCESS_ERROR)
      57.901456 rph_exited id=11 status=0 exit_code=0 ; 57.901530 rph_destroyed id=11
      57.954732 procs[options_routing_checked] rph=12 pm=ohbeakal...,
                frame_rph=12:url=chrome-extension://.../options.html  (rph=11 gone)
    So the killed process is rph=11, created during the re-enable churn and NEVER present in
    `ProcessMap` at any snapshot, while the options tab's process rph=12 WAS inserted normally.
    `ProcessMap::Insert()` has exactly one caller,
    `ChromeContentBrowserClientExtensionsPart::SiteInstanceGotProcessAndSite()`, which returns
    early without inserting when `GetEnabledExtensionFromSecurityPrincipal()` finds no *enabled*
    extension; `ProcessMap::Remove()` has exactly one caller,
    `ExtensionService::RenderProcessHostDestroyed()`. There is no retroactive insert when an
    extension later becomes enabled.
  implication: |
    Mechanism is the mirror image of the assumed one: a *fresh* renderer for the re-enabled
    extension was allocated while the extension was still disabled, so it never entered
    ProcessMap; by the time it finished launching and registered its listener the extension was
    enabled again, so `ShouldIgnoreListenerMessageForUnloadedExtension()` no longer suppressed
    the message and `IsProcessAuthorizedForExtensionProcessListener()` failed. Still to confirm:
    that rph=11 hosts the extension's service worker, and that the extension was genuinely not
    in `enabled_extensions()` at rph=11's creation.

- timestamp: 2026-07-30T07:45:08Z
  checked: |
    Whether defect 1 actually fails the browser test, as the previous session asserted
    ("`NoRendererCrashesAssertion` fails the browser test regardless of controller state").
  found: |
    IT DOES NOT. The instrumented run exited 0 and reported
    `[       OK ] PrometheusExtensionSmokeControllerBrowserTest.FullLifecycleInstalls
    InspectsAndReloads (13496 ms)` with the bad Mojo message present in the same log. Reading
    `content/public/test/no_renderer_crashes_assertion.cc`, `RenderProcessExited()` returns
    early ("Not a crash") for `TERMINATION_STATUS_LAUNCH_FAILED`,
    `TERMINATION_STATUS_NORMAL_TERMINATION` and `TERMINATION_STATUS_STILL_RUNNING`. rph=11
    exited with `status=0` (= `TERMINATION_STATUS_NORMAL_TERMINATION`) `exit_code=0`, because
    `RenderProcessHostImpl::ShutdownForBadMessage()` goes through the ordinary
    `Shutdown(RESULT_CODE_KILLED_BAD_MESSAGE)` path. The verify script's own crash-line rejection
    regex (`segmentation fault|received signal|check failed|fatal error|addresssanitizer|
    CRASHED\)|test timed out|\(TIMEOUT\)`) also does not match either bad-message log line.
  implication: |
    The previous session's gating claim was an inference, not an observation, and it is wrong.
    Defect 1 does not block reaching `kComplete`; defect 2 is the only actual blocker. Defect 1
    is still a real finding that must be characterised honestly rather than ignored, because a
    renderer being killed for a bad IPC during the smoke is a genuine defect signal.

- timestamp: 2026-07-30T07:57:07Z
  checked: |
    Instrumented build 2 (`/tmp/pdiag-run2.log`) — same instrumentation as build 1, run again.
    Read specifically to re-test the immediately preceding entry's claim that defect 1 does
    not fail the browser test.
  found: |
    THAT CLAIM IS WRONG, AND THE RUN-1 OBSERVATION IT RESTED ON WAS THE UNLUCKY SAMPLE.
    Run 2 ends:
      `../../content/public/test/no_renderer_crashes_assertion.cc:102: Failure`
      `Unexpected termination of a renderer process; status: 2, exit_code: 3`
      `[  FAILED  ] PrometheusExtensionSmokeControllerBrowserTest.
       FullLifecycleInstallsInspectsAndReloads (3936 ms)`
    status=2 is `TERMINATION_STATUS_PROCESS_WAS_KILLED` and exit_code=3 is
    `RESULT_CODE_KILLED_BAD_MESSAGE`. Confirmed against source: the switch in
    `no_renderer_crashes_assertion.cc` early-returns only for `LAUNCH_FAILED`,
    `NORMAL_TERMINATION` and `STILL_RUNNING`; status=2 falls to `default: break` and FAILs.
    Note the controller itself reached the end in this run too
    (`PDIAG Complete`, `PDIAG terminal stage=complete outcome=1`) — the test failed purely on
    the crash assertion, exactly as the original session claimed.
    The same run also settles the two facts the previous entry left open:
      `PDIAG rph_created id=11 enabled_unpacked: <none>` — the enabled-extension set was
      genuinely empty at rph=11's creation.
      `PDIAG sw_started version=0 rph=11 script=chrome-extension://ohbeakal.../
       service_worker.js` — rph=11 did host the extension's service worker.
  implication: |
    Defect 1's termination status is not deterministic: run 1 reported status=0/exit_code=0
    (test passed), run 2 reported status=2/exit_code=3 (test failed) from the identical
    binary and identical code path. So defect 1 IS a gating failure, intermittently — which
    is worse than a deterministic one, because it makes the smoke flaky rather than red.
    The withdrawal of the gating claim in the 07:45:08Z entry above is itself withdrawn; the
    original session's assertion was right. Generalising "does not fail" from a single
    passing sample was the error.

- timestamp: 2026-07-30T08:02:25Z
  checked: |
    Instrumented build 3 (`/tmp/pdiag-run3.log`) — instrumentation plus both candidate fixes
    (the activation-settled wait before the disable click, and the real-mouse-event remove
    click).
  found: |
    Clean green, and every step of the predicted mechanism visible:
      `PDIAG procs[activation_settled] rph=13:live:pm=ohbeakal... sw_rph=13:ver=1:thr=1`
      `PDIAG procs[disabled] ...` 3.5 ms later — the disable now lands on a settled process
      `PDIAG rph_created id=14 enabled_unpacked: unpacked=ohbeakal...` — the replacement
        renderer is now created while the extension is ENABLED
      `PDIAG procs[ready] rph=14:live:pm=ohbeakal...` — and is therefore in ProcessMap
      NO bad Mojo message anywhere in the run, and no crash assertion.
    Remove stage, same run:
      `PDIAG remove_point status=ok x=456 y=387 hit=removeButton`
      `PDIAG child_widget name=ExtensionUninstallDialog visible=0`   (dialog created)
      `PDIAG owned_widget name=ExtensionUninstallDialog title=Remove "Prometheus Developer
       Workflow Fixture"? is_dialog=1 modal=0`                       (dialog shown, real title)
      `PDIAG accepting uninstall confirmation dialog`
      `PDIAG Complete` / `PDIAG terminal stage=complete outcome=1`
      `[       OK ] ...FullLifecycleInstallsInspectsAndReloads (5503 ms)`
  implication: |
    Both candidate fixes are confirmed effective by direct observation, and the user-consent
    gate is confirmed genuinely exercised rather than bypassed: the real uninstall dialog is
    created, becomes visible with its real "Remove ...?" title, and is accepted through
    `DialogDelegate::AcceptDialog()`. The gesture gate and the consent gate are distinct, and
    only the gesture gate was ever the blocker.

- timestamp: 2026-07-30T08:02:25Z
  checked: |
    Every mechanism claim asserted in the uncommitted code's comments, read against real
    source in this checkout rather than taken on trust.
  found: |
    All verified:
      `ProcessMap::Insert()` — exactly one production caller,
        `chrome_content_browser_client_extensions_part.cc:802`, inside
        `SiteInstanceGotProcessAndSite()`, which returns at :764 when
        `GetEnabledExtensionFromSecurityPrincipal()` yields null. No retroactive insert exists.
      `ProcessMap::Remove()` — exactly one production caller,
        `extension_service.cc:869` (`RenderProcessHostDestroyed`).
      `EventRouter::ValidateServiceWorkerListenerForExtension()` — suppresses via
        `ShouldIgnoreListenerMessageForUnloadedExtension()` only while the extension is
        disabled, then requires `IsProcessAuthorizedForExtensionProcessListener()` =
        `ProcessMap::Contains(id, pid)`, reporting
        `kEventListenerWithUnauthorizedExtensionID` on failure. Exact message match.
      `management_api.cc:741-745` — `show_confirm_dialog |= !self_uninstall;` then
        `if (show_confirm_dialog && !user_gesture()) return
        RespondNow(Error(kGestureNeededForUninstallError));`
      `extension_uninstall_dialog_impl.cc:75` — `dialog_builder.SetInternalName(
        "ExtensionUninstallDialog")`, so the widget-name match is real (and empirically
        confirmed by the `owned_widget name=ExtensionUninstallDialog` line above).
      `RenderWidgetHostImpl::ForwardMouseEvent()` — this IS the real macOS input entry point:
        `RenderWidgetHostViewCocoa` (real NSEvent) -> `_hostHelper->ForwardMouseEvent()` ->
        `RenderWidgetHostViewMac::ForwardMouseEvent()` (:2079) -> `host()->ForwardMouseEvent()`.
      `content::RenderFrameHost` exposes NO production `ExecuteJavaScriptWithUserGesture()` —
        only `ExecuteJavaScriptWithUserGestureForTests()` (`render_frame_host.h:606`), which
        the verify script's own static guard already rejects by name.
  implication: |
    The lead recorded in `defect_2.leads(a)` — "there is a distinct
    `ExecuteJavaScriptWithUserGesture()`; must judge whether using it is legitimate" — is moot.
    No such production API exists, and the test-only spelling is explicitly forbidden by the
    verify script's no-bypass guard. Real synthesized input was not merely the better choice,
    it was the only non-bypassing one available.

- timestamp: 2026-07-30T08:02:25Z
  checked: |
    Build provenance of the uncommitted working tree, via file mtimes against the built
    binary and the verify script's own logs.
  found: |
    `out/Default/prometheus_extension_smoke_tests` mtime 08:02:10, but
    `prometheus_extension_smoke_controller.cc` 08:05:55, `BUILD.gn` 08:07:09 and
    `prometheus_extension_smoke_browsertest.cc` 08:08:17. `phase22-extension-smoke/build.log`
    and `static-guard.log` are both 0 bytes, created 08:08.
    All `PDIAG`/tracer/`owned_widget`/uninstall-probe instrumentation is absent from the
    working tree (`grep` over `chrome/browser/prometheus/` returns nothing).
  implication: |
    The uncommitted code is the stripped, fix-only descendant of run 3's instrumented tree.
    It was WRITTEN but NEVER BUILT and NEVER RUN — a verify run was started at 08:08 and died
    before producing any output. So run 3's green belongs to the instrumented ancestor, not to
    this tree. Nothing here may be treated as verified until this exact tree builds and passes.
    Newly written and entirely unproven in any run: the browsertest's result-record field
    assertions, and the widget-name gate in
    `TryAcceptVisibleUninstallConfirmationDialog()`.

- timestamp: 2026-07-30T14:45:00Z
  checked: |
    Built the previously-never-built working tree and ran the focused verify script, then —
    because defect 1 was known to manifest INTERMITTENTLY — ran
    `FullLifecycleInstallsInspectsAndReloads` 12 times directly against the built binary
    rather than trusting the single green.
  found: |
    THE ACTIVATION-SETTLED WAIT DOES NOT CLOSE DEFECT 1. A single verify run passed
    (`[ OK ] ... (5718 ms)`, 31/32, with only the documented Mojo-thread SIGSEGV env flake on
    the unrelated `EarlyShutdownTerminalizesWithoutCrashing`, which passed 8/8 in isolation).
    But the 12-run stability sweep gave:
      `RESULT: pass=4 fail=8 badmessage=10 of 12`
    The bad Mojo message still appears in 10 of 12 runs, and 8 of 12 runs FAIL on
    `no_renderer_crashes_assertion.cc:102 ... status: 2, exit_code: 3`. A second full verify
    run also failed on this test (`EXIT_CODE=1`).
  implication: |
    Two things follow. First, run 3's green and the first verify green were lucky samples;
    the previous session's conclusion that both defects were "root-caused and fixed" rested on
    single observations of an intermittent failure — the same generalise-from-one-sample error
    that produced the retracted gating claim earlier in this file. Second, the predicate itself
    is too weak: `RenderProcessHost::IsReady()` means the process launched and its channel
    connected, which says nothing about whether the background service worker finished
    starting inside it. Since the window being closed is precisely an in-flight service-worker
    start being aborted by the disable, the predicate must observe the worker, not the process.

- timestamp: 2026-07-30T14:52:00Z
  checked: |
    Strengthened `ExtensionActivationSettled()` to additionally require a genuinely started
    service worker: `ProcessManager::GetServiceWorkersForExtension(id)` non-empty, with every
    returned `WorkerId`'s host live, `IsReady()`, and ProcessMap-attributed to the extension.
    `ProcessManager` registers a `WorkerId` only once the worker has actually started, so this
    is a direct observation of the state the old predicate merely inferred.
  found: |
    DECISIVE. Same 12-run sweep, rebuilt binary:
      `RESULT: pass=11 fail=1 badmessage=0 of 12`
    The bad Mojo message went from 10/12 to 0/12 and the defect's own failure signature
    (`no_renderer_crashes_assertion.cc:102 ... status: 2, exit_code: 3`) disappeared entirely.
    The single remaining failure is `Received signal 10 BUS_ADRALN` on a `base::Thread` inside
    `SequenceManagerImpl::GetNextDelayedWakeUpWithOption()` — the documented environment-flake
    family (outside the test body, in base/mojo infrastructure, non-reproducing in isolation),
    not the defect.
  implication: |
    Confirms the diagnosis that the first predicate was measuring the wrong thing: process
    readiness, not worker readiness. It also confirms the mechanism itself — the vulnerable
    window really is an in-flight service-worker start being aborted by the disable, because
    waiting specifically for the worker to have started is what closed it.
    This remains a precondition check on observable state, not a sleep, so it does not change
    the judgement that defect 1 is an upstream product defect being AVOIDED rather than fixed.
    A real user performing the same sequence is still exposed; only this smoke stops hitting it.

- timestamp: 2026-07-31T01:40:00Z
  checked: |
    THE HARDENING SWEEP the human required before trusting the `kComplete` boundary.
    110 runs total against the ALREADY-BUILT binary, no rebuild at any point during any arm.
    Build provenance established BEFORE iteration 1: `siso ninja -n` reported
    `Build Succeeded: 0 steps`, and both repos were clean, so the binary postdates every
    committed source. Harness: `/tmp/sweep-22-05/run-sweep.sh`, per-run logs retained under
    `/tmp/sweep-22-05/{main,main2,comparison,postrevert}/`.
    Four arms:
      main       n=30  extension smoke, `kComplete` boundary
      main2      n=30  identical, to sharpen the flow-internal rate estimate
      comparison n=30  `SafeBrowsingBlockingPageRealTimeUrlCheckTest.
                       EnterpriseRealTimeUrlCheck_NoWarning` -- same binary, same browser
                       startup/shutdown, ZERO contact with extensions. The independence arm.
      postrevert n=20  extension smoke, `kEnabled` boundary, after the revert
  found: |
    main:       pass=27/30. Failures: 2x infra crash, 1x extension-flow failure.
    main2:      pass=30/30. Every tracked signature 0/30.
    comparison: pass=25/30. FIVE crashes across FOUR distinct signatures, all outside any
                test body.
    postrevert: pass=20/20. Every tracked signature 0/20.

    Combined main arms at the `kComplete` boundary: pass=57/60.
      flow-attributable failures : 1/60  (`remove_confirmation_dialog_not_found`,
                                          terminal stage `options_routing_checked`)
      infrastructure failures    : 2/60  (browser shutdown DCHECK, see below)
      DEFECT 1 bad Mojo message  : 0/60
      DEFECT 1 gating signature
        (`no_renderer_crashes_assertion.cc:102 status: 2, exit_code: 3`) : 0/60
  implication: |
    Defect 1's avoidance is now confirmed at 0/60 rather than 0/12. The
    started-service-worker predicate holds. That claim no longer rests on a small sample.

- timestamp: 2026-07-31T01:40:00Z
  checked: |
    CRASH CHARACTERIZATION BY OBSERVATION. The human lifted the "do not chase the sporadic
    memory-corruption-shaped crashes" constraint for this sweep, on the grounds that
    22-05-SUMMARY.md item 6 itself calls them "not proven benign" and the prior briefing had
    propagated that as if settled. Each failure was bucketed by full stack signature rather
    than lumped into "environment".
  found: |
    Of the three signatures named in the briefing:

    (a) Mojo `ReceiverSetState`         -- 0/110. DID NOT REPRODUCE AT ALL.
    (b) base sequence manager           -- 1/30 comparison, 0/60 main.
    (c) `ref_counted.h` DCHECK          -- 1/30 comparison, 0/60 main.

    (b) and (c) ARE THE SAME CRASH, not two families. One stack:
      `FATAL:base/memory/ref_counted.h:235] DCHECK failed: !ref_count_.IsZero().`
      `RefCountedThreadSafeBase::Release()` <- `~BindStateHolder()` <- `~PendingTask()`
      <- `IntrusiveHeap<...>::~IntrusiveHeap()` <- `TaskQueueImpl::UnregisterTaskQueue()`
      <- `SequenceManagerImpl::UnregisterTaskQueueImpl()` <- `~BrowserTaskQueues()`
      <- `~BrowserUIThreadScheduler()` <- `BrowserTaskExecutor::Shutdown()`
      <- `ContentMainRunnerImpl::Shutdown()`
    i.e. browser task queues torn down with tasks still queued; destroying those pending
    tasks releases a BindState whose refcount is already zero. Pure shutdown teardown.

    Two more signatures the briefing did not list:

    (d) `FATAL:base/memory/weak_ptr.h:408] DCHECK failed: ptr_.`
        at `prometheus::PrometheusBrowserMainExtraParts::PostMainMessageLoopRun()`
        <- `ChromeBrowserMainParts::PostMainMessageLoopRun()`
        <- `BrowserMainLoop::ShutdownThreadsAndCleanUp()`.
        Rate: 2/30 main, 0/30 main2, 2/30 COMPARISON, 0/20 postrevert.
        This is NOT environment and NOT upstream -- it is Prometheus's own code. The first
        statement of that function is `weak_ptr_factory_.InvalidateWeakPtrs()`, and
        `weak_ptr.h:407-410` is `void InvalidateWeakPtrs() { DCHECK(ptr_); ... }`. Only
        `InvalidateWeakPtrsAndDoom()` ever zeroes `ptr_`, and grep confirms that spelling
        appears NOWHERE in `prometheus_browser_main_extra_parts.{cc,h}`. So `ptr_` reading
        zero is consistent with the factory's storage no longer being valid at that point.
        Characterized only -- deliberately NOT root-caused; Phase 22 does not own it.

    (e) `Received signal 11 SEGV_ACCERR` in Cocoa view teardown:
        crash-core `ZombieDealloc()` <- `-[__NSArrayM dealloc]` <- `-[NSView _finalize]`
        <- `-[BaseView dealloc]` <- `-[BridgedContentView dealloc]`. 1/30 comparison.
        Plus one `SEGV_ACCERR` at `BrowserMainLoop::CreateMainMessageLoop()` -- a STARTUP
        crash, 1/30 comparison, which never reaches any test body at all.

    Also: the previously documented LaunchServices `BUS_ADRALN` startup crash
    (`WasLaunchedAsLoginItemRestoreState`) was 0/110. Did not reproduce either.
  implication: |
    CORRELATION QUESTION ANSWERED, and the answer is INDEPENDENCE -- established by
    observation rather than inherited:
      1. The shared bucket (d) occurs at 2/30 in the extension arm and 2/30 in an arm that
         never touches extensions. Identical rate, zero extension involvement.
      2. Total infrastructure crash rate is HIGHER in the arm with no extension contact
         (5/30) than in the extension arms (2/60).
      3. Every infrastructure crash in every arm sits on the browser-process startup or
         shutdown path, OUTSIDE any test body. There is therefore no controller stage to
         correlate them with -- they do not occur during the flow at all. That is a stronger
         result than "they scatter uniformly across stages".
    HONEST LIMIT: at n=30 per arm, 2/30 versus 5/30 is not a statistically meaningful
    difference and is not claimed as one. The robust claim is qualitative: these crashes
    demonstrably occur with zero extension involvement, so they cannot be attributed to the
    extension flow.
    CORRECTION TO THE INHERITED RECORD: (a) and the `BUS_ADRALN` family were NOT observed at
    all here, so this sweep does not characterize them -- "not observed in 110 runs" is the
    honest statement, NOT "benign". And (d) was previously filed as a pre-existing
    environment flake; it is in fact Prometheus-owned code.

- timestamp: 2026-07-31T01:40:00Z
  checked: |
    The single extension-flow failure (main arm run 17, `/tmp/sweep-22-05/main/run-17.log`),
    read against the controller source rather than assumed.
  found: |
    Terminal record, verbatim:
      `{"background_denied":true,"inspected":true,"options_routing_visible":true,
        "outcome":"failed","policy_default_blocked":true,"policy_interact_applied":true,
        "policy_read_only_applied":true,"reason":"remove_confirmation_dialog_not_found",
        "reload_transitions_seen":1,"schema_version":1,"stage":"options_routing_checked"}`
    Run duration 16.3 s against a 6.7 s median -- consistent with `kRemoveConfirmationTimeout`
    (10 s, controller.cc:71) expiring. `remove_button_not_actionable` did NOT fire in any of
    the 110 runs, so the point resolved with `status:"ok"` and the real mouse click WAS
    dispatched; the confirmation dialog simply never appeared.
    Structural cause, from source: `RemoveButtonPointScript()` hit-tests the resolved point
    IN THE RENDERER (`item.shadowRoot.elementFromPoint(x,y)!==button` ->
    `button_not_hittable`, controller.cc:409-410). The point is then returned to the browser
    process and the click is dispatched later by `DispatchRealMouseClick()`
    (controller.cc:1370). Check and use are in different processes at different times, so a
    card re-layout in that interval lands the click off the button, no
    `chrome.management.uninstall()` runs, no `ExtensionUninstallDialog` widget is created,
    and the poll expires with exactly the observed reason.
  implication: |
    This is a HARNESS race (time of check versus time of use on the click point), not a
    product defect. Stated as source-supported reasoning, NOT direct observation: this build
    carries no instrumentation, so the re-layout itself was not witnessed.
    Decisive for the boundary decision: stage `options_routing_checked` is PAST `kEnabled`,
    so this run is green at the `kEnabled` boundary and red at `kComplete`. The raise is what
    converts it from pass to fail. This is squarely the "failures that touch the flow" case,
    not the "provably independent" case.

## Current Focus

<!-- ORIGINAL BUG: RESOLVED, verified, and committed (nested dc4fd00d3e, root 40243e4b5).
     Human verify came back "confirmed fixed — option 2, commit + chase defects".
     The session now continues on the two downstream defects that fix exposed. -->

<!-- RECONCILED 2026-07-30 (resumed session). This block previously contradicted the
     `## Evidence (continued)` entries in the same file; both were partly wrong. Corrected
     against /tmp/pdiag-run2.log and /tmp/pdiag-run3.log, which no prior entry had read. -->

active_defect: none — both root-caused; both human checkpoint decisions now executed

next_action: |
  Human verification of the two executed decisions. Nothing is in flight.
  Decision 1 (upstream report) is DONE: see
  `.planning/phases/22-chrome-extension-ecosystem-and-policy/22-FINDING-processmap-race.md`.
  Decision 2 (harden first) is DONE and went against the stated preference: the sweep did not
  hold, so the assertion boundary was reverted from `kComplete` to `kEnabled`.
  Plan 22-05 remains PARTIAL — Tasks 3 (authoritative verify gate) and 4 (closeout evidence)
  are unstarted and this session does not touch them.

decision_1_executed:
  instruction: "REQUIRE UPSTREAM REPORT — filable Chromium bug, do not attempt the product fix."
  status: DONE
  document: .planning/phases/22-chrome-extension-ecosystem-and-policy/22-FINDING-processmap-race.md
  pinned_revision: |
    Determined exactly, not approximated. `.planning/chromium/CHROMIUM-CHECKOUT.md` pins
    `0e8499df5172f55d0d29e2b92ef7e6a704529578`; `git log -1` on that commit yields
    `Cr-Commit-Position: refs/heads/main@{#1648468}` (subject "[Vertical Tabs] Implement Touch
    Handler", dated 2026-06-17), and `chrome/VERSION` is 151.0.7898.0.
    `git merge-base --is-ancestor <baseline> HEAD` confirms every local commit sits on top.
  unmodified_upstream_confirmed: |
    `git diff --name-only <baseline>..HEAD` reports ZERO changed files under `extensions/` and
    ZERO under `content/`. The only touched file under `chrome/browser/extensions/` is
    `api/developer_private/developer_private_functions.cc`, whose sole change is a 21-line
    addition inside `DeveloperPrivateLoadUnpackedFunction::ShowSelectFileDialog()` — the load
    chooser caller — touching no enable, disable, process, or event routing path.
    So every file named in the reported mechanism is unmodified upstream code.
  citations_reverified: |
    Every source citation in the finding was re-derived in this checkout rather than copied:
      `ProcessMap::Insert()` — ONE production call site, verified rigorously by enumerating
        every non-test translation unit that includes `extensions/browser/process_map.h` and
        grepping each for `->Insert(`. Single hit:
        `chrome_content_browser_client_extensions_part.cc:802`. The early return is `:765`,
        guarded by `GetEnabledExtensionFromSecurityPrincipal()` at `:762` (helper at `:113`).
      `ProcessMap::Remove()` — ONE production call site, `extension_service.cc:869`.
      `ShouldIgnoreListenerMessageForUnloadedExtension()` `event_router.cc:389`;
        `IsProcessAuthorizedForExtensionProcessListener()` `:408`;
        `ValidateMainThreadListenerOwner()` `:425` reporting at `:447`;
        `ValidateServiceWorkerListenerForExtension()` `:467` reporting at `:490`;
        message string `kEventListenerWithUnauthorizedExtensionID` at `:94`.
      `bad_message` reason 123 = `content::bad_message::RPH_MOJO_PROCESS_ERROR`
        (`content/browser/bad_message.h:150`) — the generic content-side wrapper for "a Mojo
        interface reported a bad message", NOT an extensions-specific code. The finding says so
        explicitly rather than implying 123 names this bug.
  measurement_honesty: |
    The briefing's "562 ms" was replaced with the actual measured spread rather than carried
    forward. Recomputed from `/tmp/pdiag-run{1,2}.log`: four extension-renderer launches
    (create -> ready) of 566.9, 559.8, 561.4 and 566.9 ms, so the window is reported as
    "roughly 560 to 567 ms on this machine", explicitly flagged as one machine, debug build.
    The finding carries an explicit observed-versus-inferred split.
  product_fix_attempted: false

decision_2_executed:
  instruction: "KEEP kComplete, BUT HARDEN FIRST — 25-30 runs; if it does not hold, revert to kEnabled and say so plainly."
  status: DONE — sweep did NOT hold; boundary REVERTED to `kEnabled`.
  threshold_stated_before_applying: |
    Stated first, then applied, as instructed.
    Task 3 freezes this as an AUTHORITATIVE gate, and the defining property of an authoritative
    gate is that red means the product is broken. So the bar is: ZERO observed failures
    attributable to the extension flow itself across the sweep.
    Infrastructure crashes proven to occur without the flow are excluded from that criterion —
    not because they are acceptable, but because they occur at browser startup/shutdown
    regardless of which stage the assertion names, so they affect `kEnabled` and `kComplete`
    identically and cannot discriminate between the two boundaries.
    Why zero and not "low": a known false-positive source trains a gate's consumers to rerun on
    red, and once that habit exists the gate no longer gates. Here the false positive would
    report a HARNESS bug as a product failure, which inverts the gate's meaning entirely.
  applied: |
    Flow-attributable failures: 1/60 (1.7%). Nonzero, so the bar is not met.
    Which of the human's two cases this is: the MIXED case, resolved toward "touches the flow".
    The 2/60 infrastructure failures are provably independent (same bucket, same 2/30 rate, in
    an arm with zero extension contact). But the 1/60 is `remove_confirmation_dialog_not_found`
    at stage `options_routing_checked` — which is PAST `kEnabled`. The run is green at
    `kEnabled` and red at `kComplete`. The boundary raise is what creates the flake, so the
    flake is not incidental to the decision; it is the decision's direct consequence.
  call: |
    Do NOT freeze `kComplete`. Reverted the assertion boundary to `kEnabled`.
    Not kept on a hoped-for explanation: the remove race has a concrete, source-supported
    mechanism (renderer-side hit test, browser-side click, different processes, different
    times), and it is a harness bug that can be closed — but it is not closed today, and this
    session was not authorized to close it.
  what_the_revert_costs: |
    Stated plainly. The revert restores the exact previously COMMITTED and previously VERIFIED
    shape from `dc4fd00d3e` — `RunUntil(stage >= kEnabled)`, `EXPECT_FALSE(id.empty())`,
    `Shutdown()`. Because that shape shuts the controller down at the boundary, and because
    `Shutdown()` terminalizes the record as `failed`, the terminal result-record assertions
    (`stage=="complete"`, `outcome=="succeeded"`, `reason=="ok"`, `schema_version`,
    `reload_transitions_seen`, `inspected`, the three `policy_*` fields,
    `options_routing_visible`, `background_denied`) are ALL lost. That is real coverage loss and
    is not minimised here.
    What is NOT lost: the controller still RUNS the entire flow on every run. The policy matrix,
    options routing, the real remove click, and the real uninstall consent dialog are all still
    exercised end to end — only the assertion stops earlier.
  recommended_target_for_task_3: |
    The data supports `kOptionsRoutingChecked` rather than either extreme: every one of the 60
    main-arm runs reached at least that stage (59 reached `kComplete`, 1 stopped exactly there).
    A boundary of `kOptionsRoutingChecked` plus the record-field assertions that are established
    by then would recover nearly all the lost coverage at an observed 60/60.
    Deliberately NOT done here: the human's authorized fallback was `kEnabled`, and choosing a
    third boundary is a judgement they should make with these numbers in front of them rather
    than one this session should take unilaterally.
    The clean path to a legitimate `kComplete` is to close the click race first — re-verify the
    hit test at dispatch time, or retry the click while the dialog poll runs — then re-sweep.
  post_revert_verification: |
    `bash .planning/chromium/verify-phase-22-extension-smoke.sh --focused` -> green:
    "controller/bootstrap static no-bypass guards passed", "selected 26 bootstrap unit, 2
    developer-private caller, and 4 controller browser test(s)", "focused suite passed with zero
    retry, skip, or failure", `SUCCESS: all tests passed.` (32/32).
    `.ninja_log` / `.ninja_deps` SHA-256 identical before and after.
    Then a 20-run confirmation sweep on the reverted binary: pass=20/20, with
    `unauthorized extension ID`, `weak_ptr.h:408`, `ref_counted.h:235`,
    `remove_confirmation_dialog_not_found`, `SEGV` and `BUS_ADRALN` all 0/20.

retained_observability_decision: |
  Deliberate. All `PDIAG`/tracer/`owned_widget`/uninstall-probe instrumentation was stripped
  before commit — none of it remains. But the fix itself deliberately KEEPS new named failure
  reasons rather than reducing everything to a timeout, because this file has now recorded
  three separate bugs (the original toggle no-op, the policy readiness refusal, and the remove
  gesture rejection) that all hid behind a swallowed error and surfaced only as a silent
  bounded-wait expiry. The retained reasons are
  `extension_activation_not_settled_timeout`, `remove_button_not_actionable:<shape>`
  (`missing_item` / `missing_button` / `button_not_actionable` / `button_not_laid_out` /
  `button_off_screen` / `button_not_hittable`), `manager_widget_unavailable`, and the existing
  `remove_confirmation_dialog_not_found` — which is now reachable rather than dead, since the
  dialog is matched by widget name. Each converts a previously silent 20 s stall into a
  message naming the exact shape that never resolved. That is the observability gap this
  session kept paying for; closing it is worth the code.

defect_1:
  summary: |
    A renderer is terminated for a bad Mojo message — "Tried to manipulate an event listener
    for an unauthorized extension ID." (`bad_message` reason 123) — shortly after the
    re-enable transition. Gating status: CONFIRMED gating, but INTERMITTENTLY. Run 2 failed on
    `no_renderer_crashes_assertion.cc:102` with `status: 2, exit_code: 3`; run 1 saw the same
    bad message but `status=0/exit_code=0` and passed. Same binary, same code path.
  hypothesis: |
    CONFIRMED BY DIRECT OBSERVATION. The original session's "stale pre-disable renderer"
    theory is DISPROVEN — the mechanism is its mirror image:
      1. The reload activates the extension; its background service worker begins starting in
         a fresh renderer, which IS inserted into ProcessMap (created while enabled).
      2. The disable click lands BEFORE that renderer finishes launching (measured: 173 ms
         early, against a 562 ms launch), aborting the in-flight service-worker start.
      3. That renderer exits; the service-worker context immediately starts a REPLACEMENT
         renderer — while the extension is still disabled.
      4. `SiteInstanceGotProcessAndSite()` returns early without `ProcessMap::Insert()`
         because `GetEnabledExtensionFromSecurityPrincipal()` finds no *enabled* extension.
      5. The extension is re-enabled ~12 ms later. Nothing inserts retroactively:
         `ProcessMap::Insert()` has exactly one caller and it is never re-run.
      6. The stranded renderer finishes launching, its service worker registers listeners,
         `ShouldIgnoreListenerMessageForUnloadedExtension()` no longer suppresses (enabled
         again), `IsProcessAuthorizedForExtensionProcessListener()` fails, bad message, kill.
    Confirmed at every step: `rph_created id=11 enabled_unpacked: <none>` (empty enabled set
    at creation), `sw_started version=0 rph=11 script=.../service_worker.js` (it did host the
    service worker), `pm=-` at every later snapshot (never in ProcessMap).
  critical_judgement_required: |
    ANSWERED: (b) — a genuine product defect, NOT a harness pacing artifact.
    Reasoning. Every link in the chain is ordinary product code reached by an ordinary
    sequence of user actions. The controller's only contribution is choosing an unlucky
    moment to disable; it does nothing a user cannot do. The vulnerable window is the whole
    extension-renderer launch — 562 ms measured on this machine, longer on slower or colder
    ones — which is comfortably human-reachable: reload an unpacked extension, then toggle it
    off before its service worker has finished starting. The resulting ProcessMap omission is
    permanent for that process's lifetime, with no self-healing path, and the user-visible
    consequence is the browser killing that extension's background service worker as if it
    were hostile. A "fresh renderer never entered ProcessMap and there is no retroactive
    insert" mechanism is product-shaped, not pacing-shaped.
    Therefore `PollExtensionActivationSettled()` is explicitly NOT claimed as a fix for this.
    Per the honesty gate, it is reported as a product finding and left open upstream.
  activation_wait_justification: |
    The wait is retained, but justified on different grounds than "the harness was too fast":
    the smoke's contract is install/inspect/reload/disable/enable/policy/options/remove, and a
    correct driver of that contract should disable an extension whose activation it has
    actually confirmed rather than one caught mid-activation. Waiting for a settled
    precondition is right regardless of the upstream bug, and it keeps this smoke scoped to
    its own contract instead of silently doubling as a flaky regression test for an unrelated
    upstream race. Note this is a precondition check on observable state, not a sleep.
    This framing is written into the code comments so the distinction survives the session.
  status: root-caused; avoided in-harness; reported upstream as a product finding, NOT fixed
  avoidance_took_two_attempts: |
    Worth recording, because the first attempt looked convincing and was not.
    Attempt 1 waited for `ExtensionRegistry` readiness plus every ProcessMap-attributed
    `RenderProcessHost` being `IsReady()`. It passed the single instrumented run and the first
    full verify run, and its code comment asserted "no bad message occurs". A 12-run sweep
    then showed the bad message in 10/12 and outright failure in 8/12. `IsReady()` means the
    process launched and its channel connected — it does not mean the background service
    worker inside it has finished starting, which is the actual thing the disable was
    interrupting. The predicate was measuring a proxy, not the mechanism.
    Attempt 2 additionally requires `ProcessManager::GetServiceWorkersForExtension(id)` to be
    non-empty with every returned `WorkerId`'s host live, ready, and ProcessMap-attributed.
    `ProcessManager` registers a `WorkerId` only once the worker has actually started, so this
    observes the worker directly. 12-run sweep: bad message 0/12, failures 1/12 (unrelated
    BUS_ADRALN environment flake).
    Lesson, and it is the same one this file has now recorded three times: a single green
    against an intermittent failure proves nothing. Every claim about this defect that rested
    on one sample has been overturned by a sweep.

defect_2:
  summary: |
    `remove_not_observed_timeout`. The `#removeButton` click reports `"clicked"` yet no
    `OnExtensionUninstalled` arrives within 20 s.
  status: ROOT CAUSE CONFIRMED and FIXED (fix pending verification of this exact tree)
  root_cause: |
    Verbatim, from the diagnostic probe in run 1:
      `PDIAG uninstall_probe=rejected:chrome.management.uninstall requires a user gesture.`
    That is `keys::kGestureNeededForUninstallError`. `management_api.cc:741-745`:
    `show_confirm_dialog |= !self_uninstall;` then
    `if (show_confirm_dialog && !user_gesture()) return RespondNow(Error(...));`.
    `Service.deleteItem()` calls `chrome.management.uninstall(id, {showConfirmDialog:true})`;
    for a chrome://extensions WebUI caller `extension()` is null, so `self_uninstall` is false
    and the confirm-dialog flag is forced on unconditionally. `ExecuteJavaScript()` conveys no
    user activation, so the injected `button.click()` was untrusted, the uninstall never
    started, and `Service.deleteItem()`'s bare `.catch(_ => {})` swallowed the rejection — the
    identical observability gap that hid the original bug.
  correction_to_prior_leads: |
    Lead (a) is settled but its premise was wrong: there is NO production
    `RenderFrameHost::ExecuteJavaScriptWithUserGesture()`. Only
    `ExecuteJavaScriptWithUserGestureForTests()` exists (`render_frame_host.h:606`), and the
    verify script's own static no-bypass guard rejects that spelling by name. So the choice
    was never "fabricate activation vs. not" — fabricating it was already forbidden.
    Lead (b)'s premise was also wrong, and this matters: the earlier session's report that
    `TryAcceptVisibleBrowserOwnedDialog()` "did find and accept a visible browser-owned
    dialog" DID NOT REPRODUCE. Run 1 emitted ZERO `owned_widget` lines across the whole 10 s
    poll — no confirmation dialog was ever created, exactly as expected when the API rejects
    before `UninstallFunctionDelegate()`. The original inference came from
    `remove_confirmation_dialog_not_found` not firing, which was a misread of a code path that
    simply never reached its failure branch.
  critical_judgement_required: |
    ANSWERED: synthesizing real user input IS legitimate here; fabricating the activation bit
    would NOT have been.
    The two gates are distinct. The gesture gate is an ANTI-ABUSE gate — it stops a caller
    invoking the uninstall flow unattended. The user-CONSENT gate is the native
    `ExtensionUninstallDialog` ("Remove <name>?"), which must still be shown and accepted.
    The fix satisfies the anti-abuse gate the same way a real user does: by actually clicking.
    `RenderWidgetHost::ForwardMouseEvent()` is not a test shim — it is literally the function
    the real macOS input stack calls (`RenderWidgetHostViewCocoa` receives the NSEvent ->
    `_hostHelper->ForwardMouseEvent()` -> `RenderWidgetHostViewMac::ForwardMouseEvent()` ->
    `host()->ForwardMouseEvent()`). Blink then derives transient activation from that trusted
    input event via `EventHandler` -> `LocalFrame::NotifyUserActivation()`. Nothing is told to
    pretend an interaction happened; one actually does.
    CONSENT GATE CONFIRMED STILL EXERCISED, not bypassed (run 3, direct observation): the real
    dialog is created (`child_widget name=ExtensionUninstallDialog`), becomes visible with its
    real title (`owned_widget name=ExtensionUninstallDialog title=Remove "Prometheus Developer
    Workflow Fixture"?`), and is accepted through `DialogDelegate::AcceptDialog()` — the same
    call its own OK button issues. The uninstall only completes after that acceptance.
  strengthening: |
    The dialog search was also tightened rather than loosened: it now requires
    `Widget::GetName() == "ExtensionUninstallDialog"` (published by
    `extension_uninstall_dialog_impl.cc:75` `SetInternalName(...)`) instead of accepting the
    first visible browser-owned `DialogDelegate`. A browser window legitimately owns other
    dialog widgets, so the old predicate could have accepted the wrong one and reported a
    success that uninstalled nothing. That is now an explicit
    `remove_confirmation_dialog_not_found` failure instead of a silent false positive.
    Also hardened: the resolved click point is hit-tested
    (`item.shadowRoot.elementFromPoint(x,y) !== button` -> `button_not_hittable`) before any
    real mouse event is sent, so a mis-resolved point can never silently click another
    control; and the transition timeout is armed synchronously immediately before the click
    rather than in a completion callback, so it cannot race the registry notification.

original_bug_hypothesis: |
  CONFIRMED (see Evidence 09:09:24). Original hypothesis, now established by observation:
  when the reload's native `OnExtensionLoaded` fires, the chrome://extensions WebUI has not
  yet processed the matching `developerPrivate.onItemStateChanged` round trip, so the item
  card's `data.state` is still `DISABLED` from the reload's unload half. The card therefore
  renders `#enableToggle` visible and enabled but with `checked === false`. The injected
  click flips it to `true`, so `onEnableToggleChange_` calls
  `chrome.management.setEnabled(id, true)` on an extension that is already enabled — a
  silent no-op that produces no `OnExtensionUnloaded`, hence the stall.
original_bug_test: |
  DONE. Instrumented build (disable/enable click script returning a diagnostic dict, registry
  observer logging, browsertest extended to a terminal outcome), then a clean fix-only build
  verified by `bash .planning/chromium/verify-phase-22-extension-smoke.sh --focused`.
original_bug_expecting: |
  Predicted `checked_before === false` / `state === "DISABLED"` on the first attempt.
  Observed exactly that. Alternative branch (`checked_before === true` with the disable still
  dropped, which would have implicated the browser-side management/registrar path) was ruled
  out by the same run.
original_bug_outcome: |
  COMMITTED. Human verify confirmed. Nested Chromium repo commit `dc4fd00d3e`
  "fix(22-05): drive the extension enable toggle only from settled WebUI state" (3 files);
  root repo commit `40243e4b5` "docs(22-05): record extension-disable-toggle-noop debug
  session". Plan 22-05 deliberately NOT marked complete; Tasks 3 and 4 remain unstarted.

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
  Stability, SUPERSEDED AND RE-MEASURED (2026-07-31). The earlier claim here — 13 runs, 11
  passes, "2 failures are both pre-existing environment flakes already documented in
  22-05-SUMMARY.md item 6" — is withdrawn on two counts. It rested on a small sample, and it
  inherited the "environment flake" label rather than testing it; one of those two signatures
  is Prometheus's own shutdown code (Findings item 6) and the other did not reproduce at all in
  110 runs.
  Re-measured across 110 runs against the built binary, no rebuild mid-sweep:
    extension smoke @ kComplete : pass 57/60  (flow 1/60, infrastructure 2/60)
    extension smoke @ kEnabled  : pass 20/20  (every tracked signature 0/20)
    unrelated browsertest,
      zero extension contact    : pass 25/30  (5 crashes, 4 distinct signatures, all outside
                                               any test body)
  Defect 1's bad Mojo message and its `no_renderer_crashes_assertion.cc:102 status: 2,
  exit_code: 3` gating signature were both 0/60 in the extension arms. No run ever failed with
  "never reached kEnabled". Per-run logs retained under `/tmp/sweep-22-05/`.
files_changed:
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_browsertest.cc

## Findings Handed Back (NOT fixed here — separate defects)

<!-- Items 1 and 2 REWRITTEN 2026-07-30 (resumed session). Both previously carried claims
     that direct observation has since overturned; the superseded text is preserved inline so
     the correction is auditable. -->

1. **UPSTREAM CHROMIUM PRODUCT DEFECT — extension service-worker renderer permanently
   stranded outside `ProcessMap`, then killed for a bad Mojo message.** ROOT-CAUSED. NOT
   FIXED, and deliberately so: it is a real product race, not a harness artifact, and the
   smoke only avoids it.
   **FILABLE REPORT WRITTEN (2026-07-31):**
   `.planning/phases/22-chrome-extension-ecosystem-and-policy/22-FINDING-processmap-race.md`
   — written to be filed upstream as is: user-visible repro first, then the mechanism, with
   the pinned revision (`0e8499df5172f55d0d29e2b92ef7e6a704529578`,
   `refs/heads/main@{#1648468}`, 151.0.7898.0), the single-caller analysis proving the
   `ProcessMap` omission is permanent rather than transient, the `bad_message` reason 123
   attribution, an explicit argument for why the PROCESS and not the extension is the
   mismatched party, measured timings with their one-machine caveat, and an
   observed-versus-inferred split. No Prometheus jargon, no plan or task numbers, and the
   repro does not depend on the smoke controller existing.
   Avoidance confirmed at **0/60** in the hardening sweep (was 0/12).
   *Mechanism.* Disabling an extension while its background service-worker renderer is still
   launching aborts that start. The service-worker context immediately spawns a replacement
   renderer; if that happens while the extension is disabled,
   `ChromeContentBrowserClientExtensionsPart::SiteInstanceGotProcessAndSite()` returns early
   without `ProcessMap::Insert()` (`GetEnabledExtensionFromSecurityPrincipal()` finds no
   *enabled* extension). `ProcessMap::Insert()` has exactly one caller and is never re-run, so
   re-enabling the extension does not repair the omission — the process is stranded for life.
   When it finishes launching and its worker registers listeners,
   `ShouldIgnoreListenerMessageForUnloadedExtension()` no longer suppresses (enabled again),
   `IsProcessAuthorizedForExtensionProcessListener()` fails, and the browser kills the
   renderer: `kEventListenerWithUnauthorizedExtensionID`, `bad_message` reason 123.
   *User impact.* Reachable by a developer who reloads an unpacked extension and toggles it
   off before its service worker finishes starting — a 562 ms window as measured here, wider
   on slower or colder machines. The extension's background worker is then destroyed as if it
   were hostile.
   *Gating status — CORRECTED TWICE.* Original session: "fails the test regardless of
   controller state" (inferred). First resumed session: "IT DOES NOT [fail]" (generalised from
   run 1's `status=0/exit_code=0` pass). Both wrong as stated. Truth: it fails
   INTERMITTENTLY. Run 2 failed with `no_renderer_crashes_assertion.cc:102 ... status: 2,
   exit_code: 3`; run 1 passed with the same bad message. Same binary, same path. So the
   original session was substantively right, and the danger is flakiness, not a stable red.
   *Superseded text:* the earlier "consistent with a stale extension renderer / service-worker
   process surviving the churn" theory is DISPROVEN — the killed process is not stale, it is
   fresher than the transition, created 13 ms *before* the re-enable.
   Related churn signal, unchanged: `service_worker_task_queue.cc:1007 Failed to unregister
   service worker ... error status was: 2`.

2. **`remove_not_observed_timeout` — ROOT-CAUSED AND FIXED** (moved out of "not fixed here";
   retained in this list only because the correction is load-bearing).
   *Root cause.* `chrome.management.uninstall()` with `showConfirmDialog` requires user
   activation (`management_api.cc:743`), which `ExecuteJavaScript()` does not convey. The
   injected click was untrusted, the uninstall never started, and `Service.deleteItem()`'s
   bare `.catch(_ => {})` swallowed the rejection. Captured verbatim by probe:
   `uninstall_probe=rejected:chrome.management.uninstall requires a user gesture.`
   *Superseded observation — important.* The earlier claim that
   `TryAcceptVisibleBrowserOwnedDialog()` "does find and accept a visible browser-owned
   dialog" DID NOT REPRODUCE. Run 1 emitted ZERO `owned_widget` lines across the full 10 s
   poll: no dialog was ever created, which is exactly right for an API that rejects before
   `UninstallFunctionDelegate()`. The original claim was inferred from
   `remove_confirmation_dialog_not_found` not firing — a misread of a branch that was simply
   never reached. Nothing was accepting the wrong dialog; nothing was accepting any dialog.
   *Superseded lead.* "There is a distinct `ExecuteJavaScriptWithUserGesture()`" — there is
   not, as a production API. Only `ExecuteJavaScriptWithUserGestureForTests()` exists, and the
   verify script's own no-bypass guard rejects that spelling by name.
3. **`policy_default_blocked_` was a false positive before fix 2.** `GetEffectiveGrant()`
   clamps to `kBlocked` for a not-yet-ready extension, so the "default is Blocked" assertion
   passed for the wrong reason. With `PollExtensionReady()` in place it is now meaningful, but
   the stage has no retained assertion yet.
4. **No patch export needed yet.** `.planning/phases/22-.../patches/` stops at
   `0016-fix-22-04-...`; the existing 22-05 nested commits are also unexported. Task 3 exports
   everything after the frozen baseline, so these commits will be picked up there.

5. **NEW — HARNESS RACE in the remove click (time of check versus time of use).** Observed
   1/60 in the hardening sweep as `remove_confirmation_dialog_not_found` at terminal stage
   `options_routing_checked`. `RemoveButtonPointScript()` hit-tests the resolved click point in
   the RENDERER (`item.shadowRoot.elementFromPoint(x,y)!==button`, controller.cc:409-410); the
   point then travels to the browser process and `DispatchRealMouseClick()` sends the click
   later (controller.cc:1370). A card re-layout in that interval lands the click off the button,
   so no `chrome.management.uninstall()` runs, no `ExtensionUninstallDialog` is created, and the
   10 s `kRemoveConfirmationTimeout` poll expires. `remove_button_not_actionable` never fired in
   any of the 110 runs, confirming the point always resolved `ok` and the click was always sent.
   This is the sole reason the `kComplete` boundary was not frozen. Suggested direction for
   Task 3: re-verify the hit test at dispatch time, or keep re-clicking while the dialog poll
   runs. NOT fixed here — closing it needs a rebuild and a fresh sweep, and this session was
   scoped to the two checkpoint decisions.
   Note the retained named failure reasons paid for themselves here: this surfaced as
   `remove_confirmation_dialog_not_found` rather than as a silent 20 s stall.

6. **NEW — `PrometheusBrowserMainExtraParts::PostMainMessageLoopRun()` DCHECKs on shutdown, and
   it is OURS, not the environment.** `FATAL:base/memory/weak_ptr.h:408] DCHECK failed: ptr_.`
   at that function's first statement, `weak_ptr_factory_.InvalidateWeakPtrs()`
   (`prometheus_browser_main_extra_parts.cc:3231-3232`). `weak_ptr.h:407-410` is
   `void InvalidateWeakPtrs() { DCHECK(ptr_); ... }`, and only `InvalidateWeakPtrsAndDoom()`
   ever zeroes `ptr_` — a spelling that appears nowhere in that file. So `ptr_` reading zero is
   consistent with the factory's storage no longer being valid at that point.
   Rate: 2/30 main, 0/30 main2, **2/30 in the comparison arm that never touches extensions**,
   0/20 post-revert. **CORRECTION TO THE INHERITED RECORD:** 22-05-SUMMARY.md item 6 files this
   as a pre-existing environment flake. It is not environmental — it is Prometheus-owned code
   crashing the browser process at shutdown, and it fails any browsertest in this binary
   regardless of subject. It IS independent of the extension flow. Characterized only;
   deliberately not root-caused, as Phase 22 does not own it.

7. **NEW — the "memory-corruption-shaped" crash list in 22-05-SUMMARY.md item 6 needs
   correcting.** Measured across 110 runs:
   - "base sequence manager" and "`ref_counted.h` DCHECK" are **one crash, not two**: a single
     stack, `RefCountedThreadSafeBase::Release()` <- `~BindStateHolder()` <- `~PendingTask()`
     <- `TaskQueueImpl::UnregisterTaskQueue()` <- `~BrowserTaskQueues()` <-
     `BrowserTaskExecutor::Shutdown()` <- `ContentMainRunnerImpl::Shutdown()`. Browser task
     queues torn down with tasks still queued. 1/30 comparison arm, 0/60 extension arms.
   - Mojo `ReceiverSetState`: **0/110, did not reproduce.** The honest statement is "not
     observed in 110 runs", NOT "benign" — this sweep does not characterize it.
   - LaunchServices `BUS_ADRALN` startup crash: **0/110, did not reproduce.** Same caveat.
   - Previously undocumented: `SEGV_ACCERR` in Cocoa view teardown (crash-core `ZombieDealloc`
     <- `-[NSView _finalize]` <- `-[BridgedContentView dealloc]`), 1/30 comparison; and
     `SEGV_ACCERR` at `BrowserMainLoop::CreateMainMessageLoop()`, a startup crash that never
     reaches a test body, 1/30 comparison.
   All of them sit on the browser-process startup or shutdown path, outside any test body.

## Downstream Defect Resolution (second session)

defect_2_resolution:
  root_cause: |
    `chrome.management.uninstall()` with `showConfirmDialog` requires user activation
    (`management_api.cc:743`), which `RenderFrameHost::ExecuteJavaScript()` does not convey.
    For a chrome://extensions caller `extension()` is null, so `self_uninstall` is false and
    `show_confirm_dialog |= !self_uninstall` forces the flag on unconditionally — the WebUI
    remove path can never avoid the gate. The injected `button.click()` was therefore an
    untrusted click, the uninstall never started, and `Service.deleteItem()`'s bare
    `.catch(_ => {})` swallowed the rejection.
  fix: |
    `RemoveClickScript()` -> `RemoveButtonPointScript()`: resolves `#removeButton` to a real
    viewport point, scrolls it into view, rejects a zero-size or off-screen rect, and
    hit-tests the resolved point (`shadowRoot.elementFromPoint(x,y) !== button` ->
    `button_not_hittable`) so a mis-resolved point can never silently click another control.
    `DispatchRealMouseClick()` then sends kMouseMove/kMouseDown/kMouseUp through
    `RenderWidgetHost::ForwardMouseEvent()` — the same function the real macOS input stack
    calls. Every not-yet-actionable shape is a bounded transient retried within
    `kRemoveButtonActionableTimeout`, failing explicitly by name if permanent.
    `TryAcceptVisibleBrowserOwnedDialog()` -> `TryAcceptVisibleUninstallConfirmationDialog()`,
    now requiring `Widget::GetName() == "ExtensionUninstallDialog"` instead of accepting the
    first visible browser-owned dialog.
  verification: |
    Real dialog observed created, shown with its real "Remove ...?" title, and accepted via
    `DialogDelegate::AcceptDialog()`; `OnExtensionUninstalled` then arrives and the controller
    reaches `kComplete`. Consent gate exercised, not bypassed.

defect_1_resolution:
  root_cause: |
    Upstream Chromium race. Disabling an extension while its background service-worker
    renderer is still starting aborts that start; the replacement renderer is allocated while
    the extension is disabled, so `SiteInstanceGotProcessAndSite()` returns before
    `ProcessMap::Insert()`. Nothing inserts retroactively, so re-enabling leaves the process
    permanently unmapped; when its worker registers listeners the browser kills it for
    `kEventListenerWithUnauthorizedExtensionID` (`bad_message` 123).
  disposition: NOT FIXED — avoided in-harness, reported as an upstream product finding.
  avoidance: |
    `PollExtensionActivationSettled()` gates the disable click on
    `ExtensionActivationSettled()`, which requires registry readiness, a ProcessMap-attributed
    and ready process, AND a genuinely started service worker via
    `ProcessManager::GetServiceWorkersForExtension()`. Bounded at
    `kActivationSettledTimeout` (15 s), failing explicitly as
    `extension_activation_not_settled_timeout` rather than hanging.
  verification: |
    12-run sweeps of `FullLifecycleInstallsInspectsAndReloads` against the built binary:
      process-readiness predicate only : pass=4  fail=8 badmessage=10 of 12
      + started-service-worker required: pass=11 fail=1 badmessage=0  of 12
    The one remaining failure is a `BUS_ADRALN` environment flake on a `base::Thread`, of the
    family already documented in 22-05-SUMMARY.md item 6.

no_verification_path_weakened: |
  Confirmed. The script's static no-bypass guards pass. No MV2 enablement, no
  install-verification bypass, no `accept_dialog_for_testing_`, no direct installer/registrar
  mutation, no command-line extension loading. Notably `ExecuteJavaScriptWithUserGesture()`
  does not exist as a production API — only `ExecuteJavaScriptWithUserGestureForTests()`,
  which the guard rejects by name — so the gesture was satisfied with real input rather than
  a fabricated activation bit. Two paths were made STRICTER: the uninstall dialog must now
  match by widget name, and the remove point must hit-test to the remove button.

## Relevant Files

- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.h`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_browsertest.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap.cc`
- `.planning/chromium/verify-phase-22-extension-smoke.sh`
