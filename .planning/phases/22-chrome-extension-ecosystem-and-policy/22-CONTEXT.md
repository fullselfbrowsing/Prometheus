# Phase 22: Chrome Extension Ecosystem and Policy - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 22 makes the pinned Chromium extension subsystem a truthful, testable
Prometheus capability. It owns the supported install and management flow,
extension-surface classification, per-extension Agent policy, operator controls,
sanitized diagnostics, compatibility fixtures, and documentation of Chromium,
Chrome Web Store, Google-service, Manifest, and Private-mode limitations.

The phase may expose visible user-facing extension tabs, popups, options pages,
and side panels to the existing browser-owned Agent route service only after an
explicit Prometheus grant. It does not create an extension-to-Agent bridge,
grant background or hidden extension contexts to Agents, bypass Chromium
signature or Manifest policy, build a custom store/updater, promise universal
Chrome compatibility, add enterprise policy templates, or perform final public
release packaging. Cross-capability security/parity remains Phase 23, and final
packaging/release handoff remains Phase 24.

</domain>

<decisions>
## Implementation Decisions

### Installation and Management
- Preserve Chromium's native extensions toolbar and `chrome://extensions` as
  the primary management surfaces. Guarantee and document the developer-mode
  `Load unpacked` path rather than building a parallel Prometheus installer.
- Treat direct Chrome Web Store installation as capability-gated. Claim or
  expose it as supported only after a live built-app test succeeds; otherwise
  replace misleading store affordances with an exact limitation and the
  documented developer/sideload recovery path.
- Use Chromium's native CRX, signature verification, installation, and update
  mechanisms wherever the pinned build supports them. Never weaken install
  verification. Unpacked developer extensions use the native manual reload
  workflow.
- Preserve Chromium's per-extension Private-mode opt-in for ordinary extension
  execution, but keep Prometheus Agent access as a separate explicit grant.
  Private eligibility must never copy, infer, or automatically enable an Agent
  grant.

### Agent Permission Boundary
- Classify `chrome-extension://` targets as a distinct extension surface before
  page routing. Resolve the exact extension identity from Chromium's
  browser-owned registry, never from renderer data, a route parameter, a
  display label, or another caller claim.
- Provide local-UI-only per-extension Agent levels: `Blocked` by default,
  `Read only`, or `Interact`. `Interact` permits only closed typed actions and
  still enforces session, ownership, target, document, confirmation, and
  verification policy. Arbitrary `execute_js` remains blocked on extension
  surfaces.
- Make only visible user-facing extension tabs, popups, options pages, and side
  panels eligible for policy-controlled access. Background/service workers,
  offscreen documents, hidden hosts, and DevTools internals remain outside the
  Agent route surface.
- Chrome extension permissions never confer Prometheus authority. Extension
  code cannot obtain Agent sessions, gateway bearer material, vault authority,
  internal-surface permission, or control grants. Content-script-injected DOM
  on an ordinary page remains untrusted page content and cannot become an
  authorization signal or bypass existing origin, frame, vault, or
  confirmation checks.

### Operator Controls and Diagnostics
- Add Extension Policy controls within the existing Control Panel
  `Permissions & Agents` section and link to Chromium's native
  `chrome://extensions` manager. Do not create a duplicate manager or a tenth
  top-level Control Panel section.
- Agent-grant changes are local-UI-only. Escalating an extension to `Interact`
  requires explicit confirmation; reducing or revoking access takes effect
  immediately. Bind every change to the exact browser-owned extension ID and a
  fresh snapshot generation so stale rows cannot mutate a replacement entry.
- External MCP diagnostics expose only bounded extension-subsystem status,
  reason, and recovery guidance. The local Control Panel may show safe,
  browser-owned metadata such as bounded name, ID suffix, source, enabled
  state, Private eligibility, and current Agent grant; it must not expose
  extension page content or authority material.
- Return stable typed extension-policy errors with actionable recovery instead
  of silently falling through to the normal-page or internal-page adapter.
  Audit only the extension ID, route, grant transition, result, and timing;
  never audit extension-page content, form values, scripts, or gateway
  authority.

### Compatibility and Verification
- Cover the five required categories with deterministic, project-owned
  unpacked Manifest V3 fixtures: password-manager-like UI, ad blocking,
  productivity/content scripts, side-panel/tooling, and developer workflows.
  Optional real-world smoke tests may use version-pinned extensions, but cannot
  depend on accounts, real secrets, the network, or mutable store availability
  for acceptance.
- Treat Manifest V3 as the verified baseline. Report Manifest V2 exactly as
  supported, degraded, or blocked by the pinned Chromium revision; do not add a
  Prometheus override around upstream deprecation or security policy.
- Maintain a category compatibility matrix with `Verified`, `Degraded`, or
  `Unsupported`, recording the exact Chromium/Prometheus build, extension
  version or fixture identity, install source, behaviors exercised, and known
  limitations. Five representative successes must not be generalized into a
  universal "Chrome-compatible" claim.
- The phase closeout must prove live subsystem health; install, manage, reload,
  disable, remove, and Private-mode behavior; per-extension grant enforcement;
  extension-to-Agent isolation; all five category fixtures; typed diagnostics;
  and a built-application smoke. The gate must fail if Web Store support is
  claimed without direct live evidence.

### the agent's Discretion
- Exact C++ service and file names, pref names, bounded collection sizes,
  extension-policy error enum names, Control Panel row layout, confirmation
  wording, and fixture implementation details are at the agent's discretion.
- The planner may choose whether extension policy is owned by a new
  regular-profile keyed service or a narrowly separated dependency of the
  existing Agent/runtime profile services, provided Chromium's extension
  registry remains the identity source and the Agent service remains the sole
  route authority.
- The exact Web Store capability probe and optional real-world extension set
  are discretionary, but no unsupported external service may become a required
  acceptance dependency.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- The pinned desktop build already compiles Chromium's extension core:
  `ChromeExtensionSystemFactory` creates the profile extension system, and the
  native `chrome://extensions` WebUI provides developer mode, loading,
  inspection, reload, enable/disable, and removal affordances.
- `PrometheusAgentService` already owns authenticated route dispatch, stable tab
  ownership, typed errors, audit completion, and exact Browser/tab resolution.
- `PrometheusPageAdapter` has a clear `IsNormalPageUrl()` HTTP(S)-only boundary;
  extension targets can be intercepted and routed through a separate adapter
  without weakening normal-page policy.
- `RuntimePolicy` and its closed dispatch decisions already enforce
  internal-surface, background-action, ownership, telemetry, and native-vault
  boundaries.
- `BuildPrometheusGatewayHealthForTesting()` already emits an `extensions`
  diagnostic component as `not_ready`, giving Phase 22 a stable key to promote
  from live sanitized state.

### Established Patterns
- Browser-owned registries and stable handles are authoritative; mutable row
  ordinals, labels, URLs, renderer fields, and caller input are never identity
  or permission.
- Sensitive settings mutate only through local browser UI, use fresh
  generation-bound snapshots, and fail closed on stale or missing authority.
- MCP and WebUI receive closed, bounded, structurally safe DTOs. Diagnostics and
  audit records remain content-free and carry recovery guidance.
- Regular profiles own long-lived services; off-the-record behavior is explicit
  and cannot inherit authority silently.
- Chromium source changes stay in `.context/chromium/src`, are committed in the
  nested checkout, exported as stable ordered patches, and verified from root
  planning scripts.

### Integration Points
- Add extension classification before `PrometheusAgentService` delegates
  page routes to `PrometheusPageAdapter`; never expand
  `IsNormalPageUrl()` to accept extension schemes.
- Resolve installed/enabled state and browser-owned identity from Chromium's
  extension system/registry in a regular-profile policy owner.
- Project safe policy rows into the Control Panel
  `Permissions & Agents` section and keep extension lifecycle management linked
  to `chrome://extensions`.
- Replace the fixed gateway `extensions: not_ready` entry with live sanitized
  readiness while preserving the existing ten-component diagnostic contract.
- Extend focused unit, browser, WebUI, Node/MCP, built-app, patch-replay,
  preservation, and static-boundary gates rather than creating an unrelated
  verification stack.

</code_context>

<specifics>
## Specific Ideas

- The user-facing Agent grant vocabulary is exactly `Blocked`, `Read only`, and
  `Interact`, with `Blocked` as the default.
- A Chrome Web Store link must never imply successful installation support when
  the current unbranded Chromium build has not proved it live.
- Compatibility evidence should look like a precise laboratory matrix, not a
  marketing claim: exact fixture/version, exact behavior, exact limitation.
- Representative tests use disposable profiles and synthetic data; a
  password-manager-like fixture never handles real credentials.

</specifics>

<deferred>
## Deferred Ideas

- A custom Prometheus extension store, installer, updater, or Manifest V2
  compatibility fork.
- Any extension-to-Agent native messaging bridge or permission mapping.
- Enterprise extension/Agent policy templates (FUT-05).
- Universal compatibility claims, store-publishing guarantees, account-backed
  extension tests, and public signed/notarized distribution.
- Cross-capability security/parity consolidation in Phase 23 and final package
  validation/handoff in Phase 24.

</deferred>
