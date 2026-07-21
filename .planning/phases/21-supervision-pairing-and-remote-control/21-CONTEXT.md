# Phase 21: Supervision, Pairing, and Remote Control - Context

**Gathered:** 2026-07-21
**Status:** Ready for UI contract, research, and planning
**Mode:** Autonomous smart discussion with explicit user acceptance

<domain>
## Phase Boundary

Phase 21 makes Chromium Prometheus visibly supervisable. It adds a
regular-profile browser-owned pairing/session service, an identity-bound
DOM-native supervision stream, guarded remote page control, live supervision
state in browser chrome and the existing side/control WebUI, metadata-only
audit records, and promotion of the five preserved supervision MCP names.

Pairing is local-first and uses the existing authenticated owner-only loopback
gateway. This phase does not add a LAN listener, public inbound endpoint, cloud
relay, hosted fleet/control plane, video or screenshot streaming, a separately
hosted dashboard product, or secret transport. It does not weaken Phase 17 tab
ownership, Phase 18 exact document/frame targeting, Phase 20 native vault
confirmation, or regular-profile-only service ownership.

Extension policy, migration-wide parity/security, packaging, and consolidated
human visual review remain Phases 22 through 24. Automated native, browser,
transport, resource, privacy, and stale-target gates are mandatory here.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- A paired tab can have several human observers, but the browser always names
  one controller at most; `View only` is the obvious default state.
- A sequence gap should feel like a recoverable stream resync, not a partially
  applied or visually plausible-but-wrong DOM.
- The operator should be able to identify who is watching, who can control,
  what action is active, when access expires, and how to stop it without opening
  diagnostics or interpreting opaque IDs.
- Preserve the PhantomStream thesis—DOM-native structure and reverse mapping—
  while implementing it cleanly on Chromium primitives rather than copying the
  archived GPL/Falkon implementation.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and security contracts
- `.planning/ROADMAP.md` Phase 21 — goal, success criteria, and planned work.
- `.planning/REQUIREMENTS.md` SUP-01 through SUP-05 — required observable
  supervision, pairing, identity, and control behavior.
- `.planning/PROJECT.md` — PhantomStream reference architecture, external MCP
  boundary, supervised/auditable product thesis, and hosted-fleet exclusion.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` — clean-room
  behavior mapping, secrets boundary, UI identity, and Phase 21 evidence target.
- `.planning/phases/06-supervision-packaging-and-release-hardening/06-01-SUMMARY.md`
  and `06-02-SUMMARY.md` — observable v1 snapshot/diff and pairing outcomes;
  behavior reference only, not reusable implementation.

### Authority, page, transport, and runtime foundations
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-CONTEXT.md`
  and `17-VERIFICATION.md` — browser-issued sessions, stable tab ownership,
  metadata-only audit, and visible tab state.
- `.planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md`
  and `18-VERIFICATION.md` — structured page snapshots, exact frame/document
  targeting, verified actions, waits, and restricted-surface policy.
- `.planning/phases/19-mcp-bridge-and-multi-agent-runtime-compatibility/19-CONTEXT.md`
  and `19-VERIFICATION.md` — owner-only loopback gateway, descriptors, session
  lifecycle, closed schemas, multi-client behavior, and supervision stubs.
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-CONTEXT.md`
  and `20-VERIFICATION.md` — exact-window principal, runtime policy, native-only
  vault confirmation, bounded stores, diagnostics, and current not-ready seam.

### Visual and interaction system
- `.planning/design/DESIGN-REFERENCE.md` — canonical warm tokens, typography,
  spacing, status, focus, and sparse accent rules.
- `.planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/15-UI-SPEC.md`
  — compact native chrome and tab-state interaction contract.
- `.planning/phases/16-prometheus-webui-surfaces-and-new-tab/16-UI-SPEC.md`
  — existing side/control WebUI ownership, responsive layout, and resources.
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-UI-SPEC.md`
  — side/control information architecture, sanitized native snapshot pattern,
  and the exact Phase 21 placeholder to replace.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PrometheusAgentProfileService` and `PrometheusAgentGateway` already own
  regular-profile sessions, the authenticated loopback gateway, diagnostics,
  bounded transport, close/expiry hooks, and typed route dispatch.
- `PrometheusAgentTabData` already stores the browser-owned owner label,
  automation flag, supervision flag, and tab health used by native/WebUI tab
  state.
- `PrometheusPageAdapter`, `prometheus_page_snapshot.*`, and the page action
  helpers already provide structured nodes, document-scoped refs, restricted
  frame handling, exact live target validation, and verified actions.
- The Phase 20 runtime service supplies exact-window Browser/tab principals,
  native confirmation, sanitized logs, and bounded observer/snapshot patterns.

### Established Patterns
- Browser process is authoritative; renderer/WebUI/MCP payloads express intent
  and never supply identity or secret-bearing authority.
- Route codecs use closed field sets, bounded strings/lists, typed errors, and
  metadata-only audits. Profile service lifecycle is the cancellation boundary.
- WebUI resources are packaged, dependency-free HTML/CSS/JavaScript using the
  Phase 14 design tokens and `textContent`; remote assets and a second design
  system are prohibited.

### Integration Points
- Add the supervision service beneath `chrome/browser/prometheus/`, owned by the
  regular-profile service/factory graph and exposed to the gateway through a
  narrow delegate to avoid target cycles.
- Promote the five catalog entries in `tools/prometheus-mcp/src/catalog.mjs`
  and route them through the existing gateway/transport codec.
- Extend `prometheus_web_ui.*`, `prometheus_control_panel.html`, the shared
  Prometheus WebUI JS/CSS, and the existing native tab/chrome state adapter.
- Replace only the `supervision=not_ready` diagnostic and immutable Phase 20
  policy placeholder when the live service is operable; preserve all other ten
  diagnostic keys and Phase 22 extension status.

</code_context>

<deferred>
## Deferred Ideas

- LAN discovery/listeners, public inbound connectivity, cloud relay/sync, a
  hosted dashboard, and fleet control — a future milestone after local control
  and supervision are validated.
- Extension-page supervision and extension permission policy — Phase 22.
- Migration-wide security/parity audit — Phase 23.
- Human desktop screenshot review, packaging, and release handoff — Phase 24.
- Video/screenshot streaming as the primary supervision architecture — not
  planned; DOM-native structure remains the product decision.

</deferred>

---

*Phase: 21-supervision-pairing-and-remote-control*
*Context gathered: 2026-07-21*
