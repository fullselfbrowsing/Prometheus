# Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel - Context

**Gathered:** 2026-07-13
**Status:** Ready for research, AI/UI contracts, and planning
**Mode:** Autonomous smart-discuss defaults accepted

<domain>
## Phase Boundary

Phase 20 adds the browser-owned FSB runtime behind the Prometheus side panel,
control panel, and external MCP bridge. It owns the profile-keyed task state
machine, direct provider HTTP adapters, secure provider/vault storage, bounded
runtime history and metrics, memory/site-guide primitives, vault confirmation
flows, sanitized WebUI handlers, and Phase 20 MCP compatibility routes.

The runtime is native Chromium product code. It is not a host for Claude Code or
any other third-party agent executable. Prometheus must not bundle or launch an
agent CLI, terminal, shell, alternate engine, prompt provisioner, or
`CLAUDE.md` workflow. Claude Code, Cursor, Codex, and similar tools remain
external stdio MCP clients of the Phase 19 bridge.

Phase 20 does not implement dashboard pairing, remote supervision transport,
extension parity, packaging, or release UAT. Those remain Phases 21 through 24.
Human visual UAT is deferred to Phase 24 and is non-blocking; automated unit,
browser, resource, security, and compatibility gates remain mandatory.

</domain>

<decisions>
## Implementation Decisions

### Native Runtime Ownership
- Add a regular-profile-only `PrometheusRuntimeProfileService`, following the
  existing `PrometheusAgentProfileServiceFactory` pattern and depending on that
  service for authority, ownership, and route dispatch.
- The runtime service is the single source of truth for tasks, provider
  metadata, logs/metrics, memory, site guides, vault metadata, and Phase 20
  settings. WebUI and MCP are adapters; neither owns runtime state or secrets.
- Reject off-the-record profiles. Clamp all configured caps and collection
  sizes. Use deterministic FIFO/LRU eviction and closed enums for state, mode,
  action kind, and error kind.
- Use a closed task state machine:
  `queued -> running -> waiting_confirmation -> succeeded | failed | cancelled`.
  Cancellation, timeout, profile shutdown, and provider failure must complete a
  task callback exactly once.

### Execution Routes and Submission Provenance
- `provider`: a direct browser-process HTTPS call to a configured model followed
  by a bounded native tool-call loop. Model-selected actions may invoke only the
  existing typed Prometheus route catalog and must pass the Phase 17 ownership,
  permission, cap, and internal-surface checks.
- `local`: the same native loop against an explicitly configured loopback
  OpenAI-compatible endpoint such as LM Studio. This is the offline path; it
  does not spawn or manage a local model process.
- External MCP provenance: an external MCP client submits or cancels a task
  through the Phase 19 bridge, but Auto/Provider/Local selection still resolves
  to hosted, routed, or local execution in the same native runtime and authority
  model. MCP is an origin/adapter, never an execution mode or embedded engine.
- Provider output is untrusted. Validate response shape, tool name, arguments,
  turn count, byte count, and token/cost budgets before dispatch. Never execute
  arbitrary shell commands, filesystem access, or unconstrained JavaScript.

### Provider Registry and Networking
- Implement three native adapter families: OpenAI-compatible (OpenAI, xAI,
  OpenRouter, LM Studio, and custom), Anthropic Messages, and Gemini content
  generation. Provider kind, route class (`hosted`, `routed`, `local`,
  `custom`), model, enabled state, endpoint metadata, and fallback rank are
  persisted separately from credentials.
- Hosted providers use fixed canonical HTTPS origins. Custom remote endpoints
  require HTTPS. Plain HTTP is permitted only for explicit local mode and an
  exact loopback/localhost URL. Reject userinfo, fragments, embedded
  credentials, query-based secrets, unsafe schemes, and ambiguous origins.
- Use the regular profile browser-process URL loader factory with omitted
  cookies/credentials, no referrer, disabled cache, bounded request/response
  sizes, hard timeout, and redirect rejection whenever authorization is
  present. Destruction of the request object is cancellation.
- Fallback is deterministic and bounded. Retry/fallback only for typed network,
  throttling, and server failures; never for authentication, policy, malformed
  request, invalid output, or user cancellation. Never reuse one provider's
  credential for another provider or a changed origin.
- Model IDs are configuration, not a baked-in promise. Discover/list models
  where a provider supports it and allow a bounded validated manual model ID.

### Secret Storage and Vault Boundary
- Use Chromium `OSCryptAsync` from the browser process behind an injectable
  `PrometheusSecretStore` interface. Production stores versioned encrypted
  envelopes; tests use a fake encryptor and never touch the real Keychain.
- An encrypted envelope binds record ID, secret kind, and exact endpoint/site
  origin. Decrypted fields must match metadata before use. Changing an endpoint
  or origin invalidates the prior secret and requires native re-entry.
- If encryption is unavailable, save fails closed and preserves the previous
  ciphertext. Transient decryption failure does not erase stored data. Honor
  Chromium re-encryption requests.
- Plain prefs and all renderer/MCP responses contain only metadata and
  `secret_configured`; never plaintext, ciphertext, suffixes, authorization
  headers, or decrypted provider errors.
- Secret entry and vault insertion are browser-owned native Views flows. WebUI
  may request that a native dialog open, but secret values never enter WebUI
  JavaScript. MCP schemas reject secret-like fields.
- Every autofill-like vault use requires a fresh visible confirmation. Capture
  the profile, active browser/tab, exact origin, ownership, frame/document
  identity, and target before prompting; revalidate all of them after approval
  and before decrypting/inserting. Return only typed status.

### Persistence, Logs, Memory, and Site Guides
- Persist bounded structured task records, safe result text, action history,
  diagnostics, and numeric metrics through profile-owned storage. Metrics use
  integer token counts, duration, action count, and cost microunits.
- Runtime logs are content-free structured events. Never log prompts, page
  content, provider request/response bodies, raw endpoints with query data,
  selectors, typed text, JavaScript, local paths, secrets, or ciphertext.
- Provider result text is a separate bounded user-visible field. Before it is
  persisted or rendered, redact any exact active credential echoed by an
  upstream response and discard the raw response buffer.
- Memory and site guides support save, list, retrieve, search/apply, update, and
  delete behind fixed count/byte caps. Site guides bind to canonical exact
  origins and cannot apply cross-origin.
- Vault lists expose metadata only: stable ID, label, kind, bound origin, and
  updated time. Payment/credential values are never listable or retrievable.

### Side Panel and Control Panel
- Preserve the Phase 14/16 Prometheus token system and packaged WebUI resources;
  do not add React, shadcn, remote assets, or a second design system.
- The side panel FSB Agent mode gains a task composer, execution-mode/provider
  selection, progress/state timeline, cancel action, bounded final result, and
  actionable failure recovery. It remains the compact everyday surface.
- The control panel remains the dense operator surface. Populate Tasks,
  Providers & Models, Permissions & Agents, Vault, Memory & Site Guides, and
  Logs & Diagnostics from live sanitized runtime data. Keep Phase 21
  Supervision & Pairing explicitly `Not ready` and preserve Phase 19 MCP status.
- Browser-process handlers validate message names, IDs, enums, lengths, URLs,
  and numeric bounds. They return fresh snapshots after mutations. Secret
  fields are structurally absent, not merely blank or visually hidden.
- Destructive actions use specific confirmation copy. Accessibility, keyboard
  reachability, narrow side-panel layout, and responsive control-panel layout
  are automated acceptance criteria.

### Settings and Enforcement
- Settings for internal-surface permissions, agent caps, ownership/background
  actions, telemetry, vault boundaries, and supervision state reflect native
  enforcement rather than decorative UI.
- Agent caps clamp to the existing supported range. Background actions and
  internal-surface access are checked at dispatch time. Telemetry-off prevents
  emission at the source. Sensitive permission changes are local-UI-only.
- Supervision pairing is a truthful read-only `Not ready` state until Phase 21.
  Phase 20 must not invent pairing tokens, remote control, or a fake connected
  state.

### Verification Priorities
- Write RED tests before implementation for state transitions, cancellation,
  fallback rules, endpoint validation, encrypted persistence, redaction,
  bounded stores, exact-origin site guides/vault, native confirmation
  revalidation, and every enforcement setting.
- Use injected fake URL loaders and fake encryption. Assert cookies/credentials
  omitted, cache disabled, redirects rejected, responses bounded, and active
  secrets absent from prefs, WebUI, MCP, logs, audits, and errors.
- Add WebUI browser tests for live task/provider/log/memory/vault metadata,
  malformed message rejection, responsive reachability, and offline resources.
- Add MCP integration coverage for all Phase 20 native/alias routes and explicit
  rejection of `secret`, `api_key`, `password`, payment values, and
  authorization fields.
- Run static boundary audits for process spawning, terminal/engine UI,
  third-party runtimes, secret-bearing logs, remote WebUI resources, and
  plaintext secret prefs. Do not run human UAT in this phase.

### Agent's Discretion
- Exact class/file names, persistence schema version, collection caps, and plan
  decomposition may vary if the locked security and compatibility contracts
  remain testable.
- Streaming provider responses may be staged behind a buffered first version if
  the UI still reports truthful progress and cancellation and all size/time
  limits hold.
- A browser-owned native secret dialog can be implemented in the final Phase 20
  plan if earlier plans use an injected secret-entry callback; WebUI must never
  temporarily accept secret text.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and preserved contracts
- `.planning/ROADMAP.md` Phase 20 and `.planning/REQUIREMENTS.md` FSB-01 through
  FSB-08.
- `.planning/PROJECT.md` and `.planning/MILESTONES.md` for the external-MCP-only
  boundary and current milestone position.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` for clean-room
  behavior mappings; archived Falkon/GPL source remains reference-only.
- `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md` and
  `05-VERIFICATION.md` for observable v1 runtime contracts, not implementation
  copying.
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`
  for the side/control split, section names, states, and safe copy.

### Existing Chromium implementation anchors
- `.context/chromium/src/chrome/browser/prometheus/` for Phase 17 through 19
  route authority, profile service, audit, page adapters, and MCP gateway.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.{h,cc}`
  for side/control browser-process handlers.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html`,
  `prometheus_control_panel.html`, `prometheus_webui.js`, and
  `prometheus_webui.css` for the existing Phase 16 shells and tokens.
- `.context/chromium/src/components/os_crypt/async/` and
  `chrome/browser/net/profile_network_context_service.cc` for Chromium-managed
  encryption and encrypted-pref patterns.
- `.context/chromium/src/chrome/browser/ui/views/login_view.cc` and the pinned
  browser-owned confirmation/dialog patterns for native password entry.

### Provider protocol sources
- Official OpenAI Responses API, Anthropic Messages API, Gemini content API,
  xAI inference API, OpenRouter API, and LM Studio OpenAI-compatible API docs.
  Pin request/response contracts in tests; do not import provider SDK runtimes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PrometheusAgentProfileService` already centralizes regular-profile session,
  ownership, audit, route, and MCP gateway behavior.
- The Phase 19 compatibility catalog already classifies every known tool and
  exposes typed dispatch seams for Phase 20 promotions.
- Phase 16 already packages the side/control WebUI and Phase 14 tokens without
  remote resources.
- Existing audit/action history stores demonstrate bounded structured records;
  the new runtime store should follow that content-free discipline.

### Integration Points
- Runtime service depends on agent profile service; agent profile service and
  gateway receive sanitized runtime delegates to avoid a dependency cycle.
- WebUI handlers ask the runtime service for sanitized snapshots and invoke
  validated mutation commands.
- Provider adapters use the regular profile URL loader factory and a test
  factory injection seam.
- Phase 20 MCP routes promote the catalog entries currently marked
  `later_phase` and reuse the Phase 19 schema/error/ownership envelope.

</code_context>

<specifics>
## Specific Ideas

- A successful task should visibly identify its execution mode and provider,
  show progress without fake percentages, and end with a bounded result plus
  action count/token/cost metadata.
- Provider configuration should feel like an operator registry: kind, route,
  endpoint, model, health, secret status, enabled state, and fallback order.
- “Secret saved” means a native browser dialog encrypted it successfully; the
  control panel never shows the value again.
- Local mode means connecting to an already-running loopback model endpoint,
  not silently downloading or spawning a model runtime.

</specifics>

<deferred>
## Deferred Ideas

- Pairing codes, dashboard transport, live supervision snapshots/diffs, and
  remote control - Phase 21.
- Extension protocol/API parity and extension panels - Phase 22.
- Product packaging polish and multi-machine install validation - Phase 23.
- Consolidated human visual review and release validation package - Phase 24;
  human screenshots remain non-blocking.
- Any embedded terminal, bundled Claude/agent CLI, alternate engine selector,
  prompt provisioner, or `CLAUDE.md` provisioning - explicitly out of scope for
  the project, not deferred.

</deferred>
