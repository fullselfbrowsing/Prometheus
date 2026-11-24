---
phase: 21
slug: supervision-pairing-and-remote-control
status: complete
researched: 2026-07-21
confidence: high
---

# Phase 21 Research: Supervision, Pairing, and Remote Control

<user_constraints>
## User Constraints (Locked)

### Local-First Pairing and Trust
- **D-01:** Pair dashboards only through the existing authenticated loopback
  gateway and browser-issued descriptor. Do not open a LAN socket or add a
  cloud/sync relay in Phase 21.
- **D-02:** A regular-profile browser process creates a short-lived, one-time
  pairing code. Redemption produces an opaque dashboard session bound to the
  exact profile, Browser, stable tab, current owner, and pairing target; raw
  pairing credentials never enter prefs, logs, audits, URLs, or WebUI history.
- **D-03:** Pairing creation, redemption, expiry, revocation, and close are
  browser-authoritative lifecycle transitions with typed failures. New pairing
  state cannot silently reacquire a replacement Browser/tab after its authority
  is lost.
- **D-04:** Off-the-record profiles fail closed. Profile shutdown, target-tab
  close, or authority loss ends affected pairing and control state exactly once.

### Identity-Bound Structured Supervision
- **D-05:** Start each live view with one bounded DOM-native baseline snapshot,
  followed by ordered structural mutation diffs. Do not use a video stream,
  screenshot loop, or repeated unstructured HTML dumps as the primary model.
- **D-06:** Every baseline, diff, acknowledgement, and remote-control request is
  stamped with the opaque supervision session, stable tab target, exact live
  document/navigation epoch, and monotonic sequence information. Identity is
  browser-derived rather than caller-selected.
- **D-07:** Navigation or document replacement starts a new document epoch and
  requires a fresh baseline. Sequence gaps, duplicate/out-of-order messages,
  stale epochs, unknown sessions, and target mismatches are rejected; the
  consumer must resynchronize from a fresh baseline rather than applying a
  best-effort diff.
- **D-08:** Reuse Phase 18 structured snapshot semantics and live document/frame
  validation. Password, credential, payment-like, and other secret field values
  are structurally absent or redacted before serialization. Restricted frame
  boundaries stay restricted, and audit/log stores remain content-free.
- **D-09:** Bound node counts, bytes, diff operations, queued events, sequence
  retention, and session lifetime. Backpressure or overflow closes the diff gap
  and forces a baseline resync; it never permits unbounded buffering.

### View-First Remote Control
- **D-10:** Every redeemed dashboard begins view-only. Remote control requires a
  fresh explicit `Enable control` action in browser-owned Prometheus UI for that
  exact pairing and target; pairing alone never grants mutation authority.
- **D-11:** Once enabled, ordinary remote page actions reuse the existing typed
  Phase 17/18 route dispatcher and its current ownership, permission, live
  frame/document, actionability, verification, and metadata-only audit checks.
  Phase 21 must not create a parallel remote action engine.
- **D-12:** Vault use remains native-only and always requires the existing fresh
  browser confirmation and post-approval revalidation. Privileged internal
  surfaces and consequential operations retain or add browser-native
  confirmation according to existing policy; neither pairing nor a control
  lease can pre-authorize them.
- **D-13:** Expiry, revocation, ownership loss, target close, profile shutdown,
  or explicit `Stop control` immediately invalidates the control lease. Queued
  and late requests revalidate current authority at execution time and fail
  closed after invalidation.

### Viewer and Controller Concurrency
- **D-14:** One tab may have multiple independently expiring and revocable
  view-only supervision sessions.
- **D-15:** Exactly one remote-control lease may be active for a tab at a time.
  Competing enable/control requests receive a typed conflict and cannot steal or
  replace the current controller implicitly.
- **D-16:** Browser UI and sanitized diagnostics show the active viewer count,
  trusted-client labels, and sole controller label/status without exposing
  session IDs, codes, bearer material, profile paths, page content, or secrets.

### Visible State and Operator Control
- **D-17:** Supervision is never notification-only. The browser shows compact,
  persistent trusted-client, active-agent, supervised-action, and controller
  state in the existing chrome/tab state system; the side panel shows current
  activity and an immediately reachable stop action.
- **D-18:** The existing Control Panel `Supervision & Pairing` section becomes
  the dense lifecycle surface: create code, copy code, target, expiry/countdown,
  viewer/controller identities, control state, revoke/end controls, recent
  metadata-only audit events, empty/error/expired states, and recovery copy.
- **D-19:** Pairing codes are shown only in the intentional Control Panel flow,
  never in compact chrome, tab labels, diagnostics exports, logs, or routine
  announcements. Prometheus orange remains a sparse active/supervised accent,
  not a broad decorative fill.
- **D-20:** UI state is rendered only from fresh browser-owned snapshots and
  observer events. Renderer messages may express intent but cannot provide
  profile, Browser, tab, owner, session, controller, sequence, or document
  identity.

### Compatibility and Verification
- **D-21:** Promote exactly `create_supervision_pairing`,
  `start_supervision_session`, `get_supervision_snapshot`,
  `get_supervision_diff`, and `end_supervision_session` from Phase 19
  later-phase errors to closed native routes. Keep all schemas bounded and
  secret-free; legacy visual-session names remain intentionally removed.
- **D-22:** Supervision diagnostics become ready only from the live native
  service and exact-window authority. Extension diagnostics remain Phase 22
  `not_ready`.
- **D-23:** Tests must cover one-time redemption, TTL/expiry, independent
  revocation, multiple viewers, single-controller conflict, owner loss,
  tab/profile shutdown, navigation epoch changes, stale/gapped/out-of-order
  diffs, exact target mismatch, secret redaction, view-only denial, confirmation
  preservation, UI reachability, and built-app two-client transport behavior.

### the agent's Discretion
- Exact C++ class/file split and whether the service observes page changes
  directly or through a small renderer/Mojo producer, provided all identity,
  process, and boundedness contracts remain testable.
- Exact short TTLs, collection caps, diff operation vocabulary, heartbeat
  cadence, and resync batching within the locked short-lived/bounded model.
- Exact safe trusted-client label derivation and visual icon choice within the
  existing Prometheus tokens and offline Font Awesome asset system.
- Exact classification table for ordinary versus consequential remote actions,
  provided existing ownership/internal-surface/vault requirements are never
  weakened and ambiguous sensitive actions fail closed.

### Deferred Ideas

- LAN discovery/listeners, public inbound connectivity, cloud relay/sync, a
  hosted dashboard, and fleet control — a future milestone after local control
  and supervision are validated.
- Extension-page supervision and extension permission policy — Phase 22.
- Migration-wide security/parity audit — Phase 23.
- Human desktop screenshot review, packaging, and release handoff — Phase 24.
- Video/screenshot streaming as the primary supervision architecture — not
  planned; DOM-native structure remains the product decision.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Requirement | Research support |
|----|-------------|------------------|
| SUP-01 | Browser shows visible trusted-client, active-agent, and supervised-action state while external clients control the browser. | Extend the browser-owned tab DTO and wire the already compiled badge into the real `Tab`; add a selected-tab status strip through the existing side-panel runtime adapter. |
| SUP-02 | Browser can stream DOM-native snapshots/diffs or equivalent structured supervision data for live supervised sessions. | Reuse APC-based Phase 18 projection for baselines; renderer emits only bounded dirty signals and the browser recaptures, sanitizes, and computes ordered structural diffs. |
| SUP-03 | Supervision messages carry session identity so stale snapshots, diffs, or remote-control actions cannot affect the wrong tab/session. | A new regular-profile service owns opaque sessions and binds them to exact Browser, stable tab, captured owner, current document token/epoch, and browser-assigned sequences. |
| SUP-04 | Browser supports safe remote-control pairing with visible pairing state, expiration, revocation, audit logs, and target validation. | Add an in-memory one-time-code/session state machine plus a closed endpoint on the existing authenticated loopback gateway and sanitized WebUI snapshots/one-shot create response. |
| SUP-05 | Remote control honors tab ownership, internal-surface permissions, vault boundaries, and user-visible confirmation requirements. | Revalidate the captured owner/target/epoch/controller lease immediately before routing ordinary actions through `ExecuteBrowserLocalRoute`; retain dedicated native confirmations and the existing vault path. |
</phase_requirements>

## Executive Summary

Phase 21 should add one new regular-profile `PrometheusSupervisionProfileService`
and factory, dependent on `PrometheusAgentProfileServiceFactory`. The service—not
the renderer, WebUI, Node bridge, or dashboard—must own pairing digests,
dashboard sessions, viewer/controller leases, exact target bindings, document
epochs, stream sequences, bounded audit metadata, and terminal lifecycle.
[VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc:30-48`]

Use the existing authenticated IPv4-loopback gateway and descriptor. Add one
closed supervision command endpoint (bounded POST/long-poll is sufficient; the
gateway deliberately rejects WebSocket upgrades), then delegate every parsed
operation to the profile service on the UI sequence. Do not add another listener
or dashboard server. [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc:19-101`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:656-815`]

For the stream, use Phase 18 APC projection as the single semantic and privacy
source. A small document-lifetime Blink/Mojo observer should report only
“document changed/overflow” signals; the browser coalesces those signals,
recaptures a sanitized APC tree, and computes structural diffs from its prior
normalized tree. This avoids a second raw-DOM serializer and prevents renderer
mutation records or field values from becoming authority or transport data.
[VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc:152-185`, `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/frame_metadata_observer_registry.h:34-219`]

The highest implementation risks are: silently rebinding a dead target,
letting the current page dispatcher claim an unowned tab after captured-owner
loss, leaking pairing/session material through observer snapshots or MCP,
serializing secret form values, accepting stale asynchronous APC/action results,
and assuming the existing tab badge is already live. The plan should lead with
closed contracts and RED tests for these failures.

## Confirmed Current State and Reusable Seams

### Profile ownership and lifecycle

- `PrometheusAgentProfileService` is a `KeyedService` that owns the Agent session
  registry and service, exposes an Agent-session-loss observer, sweeps expiration
  at public entrypoints, and performs idempotent shutdown/release. It is the
  correct authority dependency, not the owner of dashboard sessions.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h:25-82`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc:181-208`]
- Both existing factories select only regular profiles, and the runtime factory
  depends on the Agent factory. Mirror that pattern for a separate supervision
  factory to avoid Agent/runtime/supervision target cycles.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_factory.cc:27-42`, `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc:30-48`]
- `PrometheusAgentTabData` exposes the current owner session and label, while
  `CanControl()` tests exact ownership. Capture that owner at pairing/redemption
  and compare it before every controlled action. Do this before calling the
  existing dispatcher because `EnsureCanControl()` intentionally claims an
  unowned tab; supervision must not reacquire after owner loss.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h:34-49`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc:1212-1219`]
- `ExecuteBrowserLocalRoute()` preserves an exact Browser/profile boundary and
  the page route itself validates/touches the Agent session, resolves the target,
  enforces ownership, then invokes the existing page adapter and audit finish
  path. This is the ordinary-action reuse seam.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc:117-130`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc:1047-1099`]

### Gateway and transport

- The gateway listens on an ephemeral IPv4 localhost port, writes the
  owner-only descriptor only after successful listen, uses bearer authentication
  with constant-time comparison, rejects Origin/invalid Host/non-loopback peers,
  caps bodies at 1 MiB and in-flight requests at 16, and returns `no-store` JSON.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:296-305`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:656-681`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc:19-101`]
- Gateway session bindings already retain weak exact Profile and Browser pointers,
  a stable tab id, and a browser-derived caller id. Supervision needs its own
  dashboard-session table in the profile service; it must not overload the Agent
  session registry, whose cap, reconnect, and ownership-release lifecycle differs.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:1827-1857`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h`]
- Gateway shutdown closes bound Agent sessions, clears bindings/trackers, stops
  the listener, deletes only its owned descriptor, and clears bearer/nonce.
  Register supervision shutdown/revocation in the same terminal sequence.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:943-1002`]
- Health has exactly ten ordered components; only `supervision` should become
  service-derived ready/degraded/unavailable. `extensions` stays `not_ready`.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:575-630`]

### Structured page data and mutation observation

- Phase 18 requests actionable APC on normal HTTP(S) pages with same-site-only
  frame inclusion. Cross-site/fenced frames become redacted frame metadata.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc:152-185`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc:611-630`]
- `AIPageContentResult` maps serialized document tokens to
  `content::WeakDocumentPtr`; the token is document-lifetime
  `DocumentUserData` backed by an unguessable token. Use this map to reject an
  APC callback if its primary document is no longer current.
  [VERIFIED: codebase — `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h:43-63`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h:103-121`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc:683-704`]
- Current snapshot refs already combine document token and DOM node id, and
  default full snapshots are 500 nodes/200,000 chars. Reuse the normalized-node
  representation/caps rather than emitting HTML.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc:35-39`, `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc:167-176`, `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc:36-37`]
- The current projection unconditionally copies form `field_value` into
  `input_value`; supervision must use a stricter projection that omits the key
  for password, custom-password, payment, OTP, and unknown-sensitive decisions.
  Empty or masked strings are not sufficient structural redaction.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc:210-228`, `.context/chromium/src/components/optimization_guide/proto/features/common_quality_data.proto:2539-2575`]
- Enable APC password/custom-masking, payment, and OTP redaction options, then
  fail closed again in the supervision projection. Chromium can clear known
  sensitive values during conversion, but its generic helper deliberately
  defaults unknown enum values to non-redaction; supervision should instead
  omit values for any decision other than explicitly safe/no-redaction.
  [VERIFIED: codebase — `.context/chromium/src/third_party/blink/public/mojom/content_extraction/ai_page_content.mojom:684-733`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.cc:195-220`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.cc:761-777`]
- Chromium already has a document supplement that uses Blink
  `MutationObserver`, document-lifetime Mojo receiver/remote sets, and a browser
  `WebContentsObserver` that recreates frame observers across navigation. Use
  this pattern for a bounded dirty notification; do not inject page JavaScript
  or serialize raw `MutationRecord` content.
  [VERIFIED: codebase — `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/frame_metadata_observer_registry.h:34-219`, `.context/chromium/src/components/optimization_guide/content/browser/page_content_metadata_observer.cc:63-190`]

### UI and native chrome

- The control panel already has a regular-profile, exact-WebContents runtime
  adapter, browser-owned observer snapshots, closed WebUI message parsing, and
  weak teardown. Extend the narrow runtime interface with supervision mutations
  and a one-shot create-code result; keep the regular observer DTO code-free.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc:930-990`, `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h:89-154`]
- The side panel is exactly four modes and the runtime snapshot callback is
  already browser-owned. Add the selected-tab supervision strip to that snapshot
  and an exact-target `StopControl()` method; do not create a fifth mode.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html:20-158`, `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h:26-55`]
- `PrometheusTabStatusBadge` is compiled and implements three fixed 12px icon
  slots, but repository-wide references show no construction/use outside its
  own files. A Phase 21 task must wire it into real `Tab` layout/update
  invalidation and test that integration; editing the badge alone will not make
  supervision visible.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/ui/BUILD.gn:4638-4639`, `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.cc:91-125`]
- `PrometheusTabState` currently has only an owner label and three booleans/
  health fields, while `ToTabState()` returns early when there is no owner.
  Extend the sanitized DTO for viewer count, controller label/state, closed
  action category, and supervision stream state; make view-only state visible
  even on an otherwise unowned tab while never adding opaque identifiers.
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h:14-29`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc:97-115`]

## Recommended Architecture

### 1. Service and authority graph

Add these responsibilities (exact file split remains discretionary):

| Owner | Responsibilities | Must not own |
|-------|------------------|--------------|
| `PrometheusSupervisionProfileService` | pending code digests; dashboard/viewer sessions; controller leases; exact Browser/tab/owner/document binding; stream state; expiry timers; metadata audit; sanitized observers; action admission | WebUI DOM, raw secrets, a second page-action engine |
| `PrometheusSupervisionProfileServiceFactory` | regular-profile selection; dependency on Agent factory | OTR redirection/fallback |
| per-target `WebContentsObserver`/stream | current document token/epoch; dirty debounce; APC recapture; normalized baseline/diff queue | profile/session/controller identity from renderer |
| gateway supervision delegate/codec | bounded JSON parsing/serialization; authenticated endpoint; UI-sequence dispatch | lifecycle truth or implicit target selection |
| Control/side runtime adapters | exact-surface binding; sanitized DTOs; local user intents | authority reconstruction from renderer fields |
| Blink/Mojo producer | document-local bounded dirty/overflow notification | node values, caller identity, sequence, session, target |

Factory startup should be explicit beside Agent/runtime factory initialization
in `PrometheusAgentGateway`; shutdown should invalidate all service weak pointers,
leases, pending callbacks, codes, sessions, streams, and observers before any
late completion can publish. [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:834-842`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc:181-208`]

### 2. Pairing/session state machine

Use in-memory-only records and browser-created tokens. A recommended flow is:

```text
idle -> pending_code -> redeemed_view_only -> live_view
          | expired/cancelled       | expired/revoked/authority_lost -> ended
          |                         `-> controller (one per tab)
          `-> redeemed exactly once       | stop/expiry/loss -> view_only/ended
```

Implementation guidance:

- use the UI-approved five-minute, 8-character ambiguity-safe code; keep only a
  salted digest plus expiry/attempt count after returning the raw code once to
  the exact Control Panel handler;
- one pending code per exact target; replacement invalidates the old digest
  before generating a new code;
- require descriptor bearer authentication plus the code for redemption,
  constant-time digest comparison, per-code/global attempt caps, and one-shot
  atomic consume;
- issue a fresh `base::UnguessableToken` dashboard session, bind weak exact
  Profile/Browser plus stable `tabs::TabHandle`, captured owner session id/label,
  safe client label, expiry, and independent viewer state;
- tab close, owner-session loss, Browser/profile loss, or unsupported navigation
  terminates affected records exactly once; no lookup by “current active tab”
  after creation;
- multiple viewer sessions may share one per-tab stream baseline/cache, but
  acknowledgements, expiry, delivery cursor, and revocation remain per session;
- use one tab-keyed controller lease containing the winning dashboard session;
  grant only after a native foreground dialog and a second full authority check.

Do not persist pending codes, dashboard sessions, controller leases, document
epochs, or stream cursors. Metadata audit rows may be retained only within the
bounded content-free store approved by the UI contract.

### 3. Baseline, diff, sequence, and resync

Recommended browser-owned protocol:

```cpp
struct StreamStamp {
  UnguessableToken supervision_session;  // transport only; never UI/log/MCP
  int32_t stable_tab_id;                  // compare to bound record
  UnguessableToken document_epoch;        // regenerated by browser
  uint64_t sequence;                      // browser assigned, checked overflow
};
```

1. On redemption/start, validate exact target and capture its current primary
   `WeakDocumentPtr`; perform one strict APC capture.
2. Normalize into stable document-scoped refs and safe fields, apply node/byte
   caps, then publish baseline sequence 1 with a browser-created epoch.
3. Renderer dirty notifications carry no data. Debounce/coalesce and recapture
   APC; if the captured `WeakDocumentPtr` is no longer current, discard it.
4. Diff browser-owned normalized trees with a closed vocabulary such as
   `insert_subtree`, `remove`, `replace_fields`, and `reorder_children`.
5. Enqueue only bounded batches. An overflow, cap violation, sequence wrap,
   missing ack, or document change clears queued diffs and enters
   `needs_baseline`; actions are paused until the new baseline is acknowledged.
6. `PrimaryPageChanged` always creates a new epoch. Same-document changes may
   remain in the current epoch, but still arrive through normal dirty/diff flow.

Concrete starting caps are planner-safe defaults, not new product locks: reuse
500 nodes/200 KiB baseline, cap one diff at 128 operations/64 KiB, retain at
most 32 batches/256 KiB per session, debounce dirty signals around 50 ms, and
use bounded long-poll rather than unbounded push. Expose caps as constants with
test overrides; any exceeded cap produces typed resync, never truncation that
looks authoritative.

### 4. Gateway and MCP compatibility

Add a single closed `/v1/supervision` POST path to the existing request
validator. Its closed operation enum can cover `redeem`, `baseline`, `diff`,
`ack`, `action`, `heartbeat`, and `end`; each operation has an exact allowed-key
set, bounded strings/lists, and a bounded result. All calls revalidate the
dashboard session and compare browser-derived target/epoch/sequence fields.
Do not accept profile path, Browser identity, owner id, tab selector, document
token, controller id, or arbitrary route names from the dashboard.

Promote the five MCP names without changing the 90-name union. The safest
compatibility contract is to retain their current empty schema and use the
already authenticated Agent gateway session plus its pinned Browser/tab as
implicit identity. Pairing creation may make a code available only in the local
Control Panel and return secret-free state; no MCP result may contain the code,
dashboard session, lease, document token, or epoch. Start/snapshot/diff/end can
operate on a single caller-scoped compatibility stream keyed internally by the
Agent session. This keeps all five routes real/native while keeping dashboard
credentials on the dedicated supervision transport. [VERIFIED: codebase —
`tools/prometheus-mcp/src/catalog.mjs:319-410`, `tools/prometheus-mcp/src/tool-handler.mjs:14-27`]

After promotion, catalog disposition counts should be 54 native, 12 alias, 22
typed stub, 0 later-phase, and 2 removed. Update Node argument/forwarding/privacy
tests and built-app smoke; leave `start_visual_session` and
`end_visual_session` removed. [VERIFIED: codebase —
`tools/prometheus-mcp/test/catalog.test.mjs:374-399`,
`tools/prometheus-mcp/src/catalog.mjs:319-410`]

### 5. Remote control and confirmations

Keep a closed ordinary allowlist mapped to existing route enums (click, type,
key, scroll, hover, select, clear, and policy-approved navigation). Before
dispatch and again in the async callback, verify:

```text
service live -> dashboard session live -> exact Browser/tab live
-> captured Agent owner still live and unchanged -> controller lease current
-> stream live/current epoch/acked baseline -> route allowed
-> existing Agent dispatcher -> post-result authority still current
```

Never call the dispatcher after owner loss: it would otherwise be allowed to
claim an unowned tab. Construct the `AgentRouteRequest` inside the browser using
the captured owner Agent session and exact target; do not copy caller identity
fields from JSON. Consequential or ambiguous actions require a dedicated native
window-modal confirmation with safe initial focus, Escape cancellation, and
fresh revalidation. Vault continues through its existing native-only confirmed
insertion binding and cannot be represented as an ordinary remote action.
[VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h:83-123`, `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc:132-147`]

## What Not to Hand-Roll

- Do not create a TCP/WebSocket/LAN listener; extend the current loopback
  gateway and its request validator.
- Do not create a parallel DOM serializer or action engine; reuse strict APC
  projection and Agent routes.
- Do not inject page JavaScript/`MutationObserver`; use a Blink document
  supplement/Mojo dirty signal pattern.
- Do not store raw pairing codes, dashboard sessions, controller ids, epochs,
  selectors, or page content in prefs/audit/logs/WebUI observer DTOs.
- Do not trust renderer countdowns, target fields, labels, sequences, or action
  outcomes; renderer/WebUI are intent-only.
- Do not reuse generic runtime confirmation blindly: Phase 21 requires a safe
  cancel-focused control dialog and exact target/client copy.
- Do not assume the compiled badge is integrated; wire it into actual tab
  construction/layout and state invalidation.
- Do not add React, a registry dependency, remote assets, a QR library, or any
  external package. Package legitimacy gate: not applicable; no external
  packages are permitted.

## Common Pitfalls

| Pitfall | Failure mode | Required prevention |
|---------|--------------|---------------------|
| Active-tab fallback after loss | A session silently controls another tab/window | Store weak exact Browser + stable handle; terminal failure on loss |
| Calling Agent route after owner loss | `ClaimIfUnowned()` gives remote control a new owner | Compare captured nonempty owner before dispatch and callback |
| Treating renderer mutation as a diff | Content/secret leakage and caller-chosen identity | Renderer emits dirty/overflow only; browser recaptures and stamps |
| Accepting old APC callback | Baseline/diff from prior document | Capture/check `WeakDocumentPtr`, epoch, session generation |
| Empty-string redaction | Secret key still exists or future enum leaks | Structurally omit sensitive values; unknown decision fails closed |
| Shared cursor for viewers | One viewer's lag/revoke corrupts another | Shared normalized tree, independent per-session ack/queue/expiry |
| Unbounded long poll/queue | Memory/connection exhaustion | Existing inflight cap plus per-session bytes/ops/batches and timeout |
| Code in observer snapshot | Code reappears on refresh/history/generic read | Raw code only direct create response; sensitive region exclusion |
| Optimistic UI grant | UI says controller before native dialog/recheck | Render only fresh service snapshots after committed transition |
| Badge-only change | Tests pass locally but no visible tab state | Real `Tab` integration browser test and geometry/accessibility checks |

## Validation Architecture

### Wave 0 contract tests (write RED first)

- service unit tests: one-use digest redemption, replacement, five-minute
  expiry, invalid-attempt cap, independent viewer expiry/revoke, one controller
  conflict, stop-to-view-only, owner loss, tab close, Browser/profile shutdown,
  OTR denial, exactly-once terminal observers;
- codec/gateway tests: closed paths/fields, bearer/Host/Origin/method/content
  type/size/inflight rules, unknown operation, stale session/epoch/sequence,
  target mismatch, result-size bounds, shutdown cancellation;
- projection/diff tests: deterministic baseline/diff, insert/remove/update/
  reorder, duplicate/gap/out-of-order/overflow resync, new-document epoch,
  restricted frames, password/custom-password/payment/OTP/unknown redaction;
- action admission tests: view-only denial, owner mismatch, controller conflict,
  paused/resync denial, late queued action invalidation, existing dispatcher and
  confirmation/vault preservation.

### Native/browser/UI tests

- add service/codec/projection cases to the existing
  `chrome/browser/prometheus:prometheus_unittests` target;
  [VERIFIED: codebase — `.context/chromium/src/chrome/browser/prometheus/BUILD.gn:502-565`]
- add renderer document-observer tests beside the existing Prometheus renderer
  test target, including navigation teardown and signal coalescing;
  [VERIFIED: codebase — `.context/chromium/src/chrome/renderer/BUILD.gn:419-423`]
- extend `prometheus_web_ui_browsertest.cc` for every approved Control Panel
  state, one-time code DOM removal, exact binding/refresh teardown, side-panel
  strip/stop, focus, responsive widths, themes, packaged resources, and privacy
  recursive scans;
- add a real tab-strip browser/view test proving badge construction, update
  invalidation, slot priority, accessible-name order, severe compression, and
  no OTR bleed;
- extend `tools/prometheus-mcp` tests for five native empty schemas, 54/12/22/0/2
  counts, secret-result stripping, diagnostics, and visual-name removal;
- clone/evolve `.planning/chromium/verify-phase-20.sh` into a Phase 21 gate that
  builds/runs focused native tests, `browser_tests`, Node TAP, packaged-resource
  scans, and a built-app two-client loopback smoke with multiple viewers,
  single-controller conflict, navigation resync, revoke, and late-action denial.

### Requirement evidence map

| Requirement | Minimum passing evidence |
|-------------|--------------------------|
| SUP-01 | real-tab badge + accessible name + side-panel exact-tab browser tests |
| SUP-02 | APC privacy projection + mutation signal + baseline/diff/resync browser tests |
| SUP-03 | session/tab/epoch/sequence mismatch and async stale-callback tests |
| SUP-04 | one-time/TTL/revoke/multi-viewer UI + gateway two-client smoke |
| SUP-05 | view-only/owner/policy/internal/vault/consequence/late-request tests |

## Security Review Checklist

- All pairing/session/lease/epoch authority is browser-created, memory-only, and
  absent from prefs, logs, audits, diagnostics, WebUI observer state, MCP, URLs,
  history, titles, accessibility, and tooltips.
- Raw pairing code appears only in the direct successful Control Panel response,
  is cleared on reload/redeem/expire/cancel/loss, and its DOM subtree is marked
  structurally sensitive to internal page readers/supervision.
- Dashboard endpoint requires the existing descriptor bearer; redemption also
  requires the short-lived one-time code and bounded attempt handling.
- Every async callback carries/checks a service/session/target/document
  generation; stop/revoke/shutdown invalidates generations before callbacks.
- Remote action type is a closed enum; arbitrary JS, URLs outside existing
  policy, selector/content logging, vault values, and internal surface mutation
  never ride the supervision transport.
- Diagnostics reports ready only when the regular-profile service and exact
  window authority are live; extension stays Phase 22 `not_ready`.

## Planning Decomposition

Recommended dependency order:

1. closed supervision types/codecs, privacy projection, and Wave 0 RED tests;
2. regular-profile service/factory, pairing/session/controller lifecycle, audit;
3. document observer dirty signal, APC baseline/diff/epoch/resync pipeline;
4. gateway delegate/endpoint and five MCP route promotion;
5. control action admission, dispatcher reuse, native confirmations;
6. sanitized tab DTO, real badge wiring, side-panel strip;
7. Control Panel lifecycle UI and sensitive one-shot code response;
8. browser/resource/privacy tests, built-app two-client smoke, Phase 21 verifier.

Keep transport, service, stream, remote action, and UI commits independently
reviewable; do not let UI readiness land before native enforcement and tests.

## Assumptions and Open Questions

- **Recommended interpretation:** the five MCP compatibility routes remain
  empty-schema, caller-scoped native operations, while dashboard credentials use
  the dedicated loopback supervision endpoint. This is the only interpretation
  that simultaneously honors D-21 and the UI contract forbidding codes and
  dashboard credentials in MCP payloads. Freeze this contract in the first plan.
- **Recommended policy:** view-only pairing may observe an otherwise eligible
  unowned normal page, but `Enable control` requires a live nonempty Agent owner
  equal to the owner captured at redemption. It must never claim ownership.
- **Recommended mutation design:** emit dirty/overflow only from Blink and
  derive diffs from recaptured APC. Direct raw-MutationRecord diffing is possible
  but increases privacy/semantic duplication and is not recommended.
- Exact TTL after redemption, heartbeat interval, queue caps, diff vocabulary,
  and ordinary/consequential table remain explicitly delegated by D-09 and the
  agent-discretion block; expose them as tested constants.

## Sources

All findings are from the pinned local Chromium checkout and project artifacts;
no external package or web source was required.

Primary implementation sources:

- `.planning/phases/21-supervision-pairing-and-remote-control/21-CONTEXT.md`
- `.planning/phases/21-supervision-pairing-and-remote-control/21-UI-SPEC.md`
- `.planning/REQUIREMENTS.md` (`SUP-01` through `SUP-05`)
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.*`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway*`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.*`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.*`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.*`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.*`
- `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.*`
- `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/frame_metadata_observer_registry.*`
- `.context/chromium/src/components/optimization_guide/content/browser/page_content_metadata_observer.*`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.*`
- `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.*`
- `tools/prometheus-mcp/src/catalog.mjs` and `tools/prometheus-mcp/src/tool-handler.mjs`

## Research Metadata

- **Date:** 2026-07-21
- **Confidence:** High for code ownership, transport, lifecycle, APC/redaction,
  WebUI, and badge findings; medium-high for the recommended dirty-signal/diff
  design because the locked context intentionally leaves that split open.
- **Package legitimacy gate:** Not applicable; no external packages are
  permitted or needed.
- **Runtime state inventory:** Not required; this phase adds a new bounded,
  non-persisted lifecycle rather than renaming or migrating persisted state.
