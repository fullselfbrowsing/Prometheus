# Finding: extension service worker renderer permanently stranded outside ProcessMap, then killed as a bad IPC sender

Status: reported, not fixed. Filed as a product defect against upstream Chromium.
Prepared: 2026-07-30.

This document is written to be filable upstream as is. It deliberately avoids any reference to
the harness that discovered it; the defect is reachable by a user of a stock Chromium build and
the repro below does not depend on any test infrastructure.

---

## Affected revision

| Field | Value |
| --- | --- |
| Chromium commit | `0e8499df5172f55d0d29e2b92ef7e6a704529578` |
| Commit position | `refs/heads/main@{#1648468}` |
| Commit subject | `[Vertical Tabs] Implement Touch Handler` |
| Commit date | 2026-06-17 |
| `chrome/VERSION` | `151.0.7898.0` |
| Platform observed | macOS, arm64, debug build with DCHECKs enabled |

How the revision was determined: the checkout pins this commit as its baseline, and
`git merge-base --is-ancestor 0e8499df5172f55d0d29e2b92ef7e6a704529578 HEAD` confirms every
local commit sits on top of it. `git diff --name-only <baseline>..HEAD` reports **zero** modified
files under `extensions/` and **zero** under `content/`. The only modified file anywhere under
`chrome/browser/extensions/` is
`chrome/browser/extensions/api/developer_private/developer_private_functions.cc`, whose single
local change is confined to `DeveloperPrivateLoadUnpackedFunction::ShowSelectFileDialog()` and
touches no enable, disable, process, or event routing path. **Every source file named in the
mechanism below is unmodified upstream code.**

---

## Summary

Disabling an extension while its background service worker renderer is still launching causes
that renderer to be replaced by a fresh process which is never recorded in `ProcessMap`. There is
no code path that repairs the omission when the extension is later re-enabled. When the stranded
renderer finishes launching and its service worker registers event listeners, the browser fails
the process authorization check and terminates the renderer for a bad IPC message, reporting the
*extension ID* as unauthorized. The extension ID is not the mismatched party; the process is.

The user visible result is that a legitimate extension's background service worker is destroyed
as though the renderer were hostile.

---

## Repro, in product terms

1. Load an unpacked extension whose background context is a service worker (Manifest V3) from
   `chrome://extensions` with developer mode on.
2. Click **Reload** on that extension's card.
3. While the extension's service worker is still starting, toggle the extension **off** using the
   card's enable toggle. On the machine measured here the window is roughly 560 ms wide, starting
   at the moment the reload activates the extension. It is wider on slower or colder machines,
   and wider still on first activation after a cold start.
4. Toggle the extension back **on**.

Observed: within roughly 25 ms of the replacement renderer completing its launch, the browser logs

```
Terminating render process for bad Mojo message: Received bad user message:
Tried to manipulate an event listener for an unauthorized extension ID.
Terminating renderer for bad IPC message, reason 123
```

and kills that renderer. `reason 123` is `content::bad_message::RPH_MOJO_PROCESS_ERROR`
(`content/browser/bad_message.h:150`), which is the generic wrapper content applies when a Mojo
interface implementation reports a bad message; the specific cause is the string above, from
`extensions/browser/event_router.cc:94`.

Expected: re-enabling an extension should restore a working background context. Nothing the user
did was abusive, and no renderer lied about anything.

Step 3 is the only timing sensitive step. It does not require unusual speed: a developer
iterating on an extension routinely reloads and then toggles.

---

## Mechanism

### 1. The activating renderer is aborted mid launch

The reload activates the extension and its background service worker begins starting in a fresh
renderer. That renderer *is* inserted into `ProcessMap`, because it was created while the
extension was enabled.

The disable arrives before that renderer finishes launching. The in flight service worker start is
aborted and the process exits normally.

### 2. The replacement renderer is allocated while the extension is disabled

The service worker context immediately requests a replacement renderer. In the measured runs this
happened roughly 1 ms after the aborted process exited, and roughly 13 ms *before* the user
re-enabled the extension. So the replacement is allocated during the disabled interval.

`ProcessMap` population happens in exactly one place:

`chrome/browser/extensions/chrome_content_browser_client_extensions_part.cc`

```cpp
void ChromeContentBrowserClientExtensionsPart::SiteInstanceGotProcessAndSite(   // :752
    SiteInstance* site_instance) {
  BrowserContext* context = site_instance->GetProcess()->GetBrowserContext();
  ...
  const Extension* extension = GetEnabledExtensionFromSecurityPrincipal(       // :762
      context, site_instance->GetSecurityPrincipal());
  if (!extension) {
    return;                                                                    // :765
  }
  ...
  ProcessMap::Get(context)->Insert(extension->id(),                            // :802
                                   site_instance->GetProcess()->GetID());
}
```

The lookup helper is `GetEnabledExtensionFromSecurityPrincipal()` (same file, `:113`). It resolves
against **enabled** extensions only. During the disabled interval it returns null, so the function
returns at `:765` and `ProcessMap::Insert()` is never reached for this process.

### 3. The omission is permanent, not transient

This is the crux, and it is what makes the defect a defect rather than a momentary inconsistency.

`ProcessMap::Insert()` (declared `extensions/browser/process_map.h`, defined
`extensions/browser/process_map.cc:89`) has **exactly one production call site**: the `:802` line
quoted above. Verified by enumerating every non test translation unit that includes
`extensions/browser/process_map.h` and grepping each for `->Insert(`; the only hit in the entire
tree is `chrome_content_browser_client_extensions_part.cc:802`. The remaining `Insert(` matches
under `extensions/` are `ExtensionSet::Insert` on registry and renderer registry containers, which
are unrelated containers.

`ProcessMap::Remove()` likewise has exactly one production call site,
`chrome/browser/extensions/extension_service.cc:869`, inside `RenderProcessHostDestroyed()`.

`SiteInstanceGotProcessAndSite()` is a one shot notification fired when a `SiteInstance` acquires
its process and site. It is not re-run when an extension's enabled state changes. Enabling an
extension does not walk existing `RenderProcessHost`s and retroactively insert them.

Therefore: **once a renderer is allocated for an extension during a disabled interval, that process
is absent from `ProcessMap` for the remainder of its lifetime**, and the only thing that clears the
inconsistency is the process dying.

### 4. Re-enabling removes the suppression that was hiding the mismatch

While the extension is disabled, listener registration messages are dropped quietly and
deliberately:

`extensions/browser/event_router.cc`

```cpp
bool EventRouter::ShouldIgnoreListenerMessageForUnloadedExtension(   // :389
    const ExtensionId& extension_id) const {
  return !extension_id.empty() && !IsExtensionEnabled(extension_id);
}
```

Both validators consult it first and return false without reporting a bad message, with an explicit
comment that this scenario can legitimately happen:

```cpp
bool EventRouter::ValidateMainThreadListenerOwner(...) {              // :425
  if (listener_owner.is_extension_id()) {
    ...
    // Return false to indicate the message shouldn't be processed, but don't
    // report it as a bad message -- this scenario can legitimately happen.
    if (ShouldIgnoreListenerMessageForUnloadedExtension(extension_id)) {  // :433
      return false;
    }
    const bool is_authorized =
        require_extension_process
            ? IsProcessAuthorizedForExtensionProcessListener(...)      // :442
            : IsProcessAuthorizedForMainThreadExtensionListener(...);
    if (!is_authorized) {
      receivers_.ReportBadMessage(kEventListenerWithUnauthorizedExtensionID);  // :447
      return false;
    }
    return true;
  }
  ...
}

bool EventRouter::ValidateServiceWorkerListenerForExtension(...) {     // :467
  ...
  if (ShouldIgnoreListenerMessageForUnloadedExtension(extension_id)) { // :476
    return false;
  }
  ...
  if (!IsProcessAuthorizedForExtensionProcessListener(extension_id, process)) {  // :489
    receivers_.ReportBadMessage(kEventListenerWithUnauthorizedExtensionID);      // :490
    return false;
  }
  ...
}
```

Once the user re-enables the extension, `ShouldIgnoreListenerMessageForUnloadedExtension()` returns
false, so the suppression no longer applies and control reaches the authorization check.

### 5. The authorization check fails on the process, and the renderer is killed

```cpp
bool EventRouter::IsProcessAuthorizedForExtensionProcessListener(   // :408
    const ExtensionId& extension_id,
    RenderProcessHost& process) const {
  return ProcessMap::Get(browser_context_)
      ->Contains(extension_id, process.GetID());
}
```

This is a lookup on the pair `(extension_id, process_id)`. The stranded process is not in
`ProcessMap` at all, so `Contains()` is false, `ReportBadMessage()` fires, and content terminates
the renderer.

### Why the process, not the extension, is the mismatched party

The reported message is `kEventListenerWithUnauthorizedExtensionID` — "Tried to manipulate an event
listener for an **unauthorized extension ID**." That attribution is wrong in this scenario, and the
wrongness is the reason this is worth fixing rather than tolerating:

- The extension ID is a genuine, installed, currently **enabled** extension. It passed
  `ShouldIgnoreListenerMessageForUnloadedExtension()` precisely *because* it is enabled.
- In `ValidateServiceWorkerListenerForExtension()` the same message is only reached after the
  worker scope URL has already been checked same origin with the extension ID
  (`Extension::CreateOriginFromExtensionId(extension_id).IsSameOriginWith(worker_scope_url)`,
  `:480`). So the renderer's claim about *which* extension it is speaking for is corroborated.
- The renderer is the extension's own service worker renderer, running the extension's own script.
  It reported nothing false about itself.
- The only failing term is `ProcessMap::Contains(extension_id, process.GetID())`, and it fails
  because of a browser side bookkeeping gap created by step 2 and made permanent by step 3.

A bad message report is a security signal: it asserts the renderer sent something a correct
renderer could not have sent, and it is answered with process termination. Here the renderer is
correct and the browser's own map is stale. Attributing this to the extension ID sends
investigators toward the wrong half of the pair.

---

## Measurements

All timings below are **direct observations from instrumented runs on a single machine** (macOS,
arm64, debug build with DCHECKs enabled, no artificial load). They are illustrative of the scale of
the window, not a claim about any other configuration. Two independent runs are shown because the
window width is the load bearing quantity.

Instrumentation used: a `RenderProcessHostCreationObserver` and `RenderProcessHostObserver` logging
each renderer's create, ready, and exit, together with the enabled unpacked extension set at
creation time and each renderer's `ProcessMap` attribution.

Extension renderer launch duration, measured create to ready:

| Run | Renderer | Launch duration |
| --- | --- | --- |
| 1 | activating renderer | 566.9 ms |
| 1 | replacement renderer | 559.8 ms |
| 2 | activating renderer | 561.4 ms |
| 2 | replacement renderer | 566.9 ms |

So the vulnerable window is roughly **560 to 567 ms** on this machine. Any disable landing inside it
reproduces the sequence.

Sequence timings:

| Interval | Run 1 | Run 2 |
| --- | --- | --- |
| Disable landed before the activating renderer became ready | 171.2 ms early | 172.9 ms early |
| Replacement renderer created after aborted renderer exited | 0.9 ms | 1.0 ms |
| Replacement renderer created before the re-enable | 13.0 ms before | 12.6 ms before |
| Bad message reported after replacement renderer became ready | 22.0 ms | 24.4 ms |

Two facts that close off the obvious alternative explanations, both directly observed in run 2:

- At the replacement renderer's creation the enabled unpacked extension set was logged as `<none>`.
  The extension was genuinely not enabled at that instant; this is not inferred from timing.
- That same renderer was subsequently observed hosting the extension's service worker
  (`service worker started, script chrome-extension://<id>/service_worker.js`, same process). So the
  killed process is the extension's own background context, not an unrelated process.

The replacement renderer was logged as absent from `ProcessMap` at every subsequent snapshot, while
a different renderer created later in the same run *while the extension was enabled* was inserted
normally. That contrast is the clearest single piece of evidence: same run, same extension, two
processes, and only the one created during the disabled interval is missing.

### Observed versus inferred

Observed directly:
- The bad message, the termination, and `reason 123`.
- The replacement renderer's creation during the disabled interval, with an empty enabled set.
- The replacement renderer hosting the extension's service worker.
- The replacement renderer's continued absence from `ProcessMap` after re-enabling.
- All timings in the tables above.

Inferred from source reading rather than observed at runtime:
- That `SiteInstanceGotProcessAndSite()` returned at `:765` specifically because
  `GetEnabledExtensionFromSecurityPrincipal()` yielded null. This follows from the empty enabled set
  at creation plus the single insert call site, but no breakpoint was placed on that early return.
- That no other code path could have inserted the process. This rests on the call site enumeration
  described in section 3, which is a static argument.

### Termination status is not deterministic

Worth flagging for anyone writing a regression test. The killed renderer's reported termination
status differed between two runs of the identical binary along the identical path:

- One run: `status=0` (`TERMINATION_STATUS_NORMAL_TERMINATION`), `exit_code=0`.
- Another run: `status=2` (`TERMINATION_STATUS_PROCESS_WAS_KILLED`), `exit_code=3`
  (`RESULT_CODE_KILLED_BAD_MESSAGE`).

`RenderProcessHostImpl::ShutdownForBadMessage()` routes through the ordinary
`Shutdown(RESULT_CODE_KILLED_BAD_MESSAGE)` path, and which of the two statuses is observed appears
to depend on whether the process had already begun exiting. Any assertion keyed on termination
status alone will be flaky; assert on the bad message itself.

---

## Suggested directions

Not implemented here, and offered only as starting points for someone who owns this code.

1. **Repair on enable.** When an extension transitions to enabled, walk existing `RenderProcessHost`s
   whose `SiteInstance` security principal resolves to that extension and insert them into
   `ProcessMap`. This directly removes the permanence in step 3.
2. **Do not strand the replacement.** Prevent the service worker context from allocating a
   replacement renderer for an extension that is in the middle of being disabled, or tear the
   replacement down as part of the disable.
3. **Do not attribute to the extension ID.** Independently of the fix chosen, the message reported
   when only `ProcessMap::Contains()` fails should name the process authorization gap rather than
   the extension ID, so this class of browser side staleness is not mistaken for a lying renderer.

Option 3 is worth doing regardless, because it improves triage for any other route to the same
mismatch.

---

## Why this was not fixed here

Every fix direction above modifies extension process model code with security relevant behavior:
`ProcessMap` membership is a privilege grant, and a renderer's presence in it is what authorizes it
to speak for an extension. Adding retroactive inserts without a full audit of the enable path risks
inserting a process that should not be privileged, which would be a strictly worse defect than the
one being fixed. That audit is out of scope for the work that discovered this.

The workaround adopted locally is to avoid entering the window at all, by confirming an extension's
activation has genuinely settled before disabling it. This closes nothing upstream: a real user
performing the sequence in step 3 remains exposed. It is recorded here so that no one mistakes the
absence of local symptoms for the defect having been fixed.
