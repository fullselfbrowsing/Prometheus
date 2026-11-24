---
phase: "19"
name: "mcp-bridge-and-multi-agent-runtime-compatibility"
created: 2026-07-12
mode: autonomous
---

# Phase 19: MCP Bridge and Multi-Agent Runtime Compatibility — Context

## Phase Boundary

Phase 19 makes the Phase 17/18 Chromium browser-process service reachable from
external MCP clients. It owns a browser-authenticated local route endpoint, a
Prometheus-owned stdio MCP bridge, stable tool schemas and aliases, typed
compatibility stubs, visual-session field preservation, multi-agent lifecycle,
and layered diagnostics.

Claude Code, Cursor, Codex, VS Code, and similar tools remain external clients.
Prometheus must not bundle or host a third-party agent CLI, an in-browser
terminal, an alternate agent engine, a CLI-specific system prompt, or an engine
selector. The Prometheus-owned MCP adapter is transport glue, not an embedded
agent runtime.

Provider-backed tasks, provider/vault secrets, memory/site-guide persistence,
operator logs, and live control-panel data remain Phase 20. Supervision and
pairing remain Phase 21. Extension execution/policy remains Phase 22. Phase 19
may expose these later-owned names as explicit compatibility stubs, but it must
not claim the underlying capability is ready.

## Decisions

### External MCP Process

- The MCP server is a small dependency-free Node 20+ stdio program owned by
  Prometheus. It is launched by an external MCP host and never launches or
  embeds the host, Claude Code, or any other agent CLI.
- Standard MCP stdio uses one UTF-8 JSON-RPC message per newline. Stdout is
  protocol-only; all diagnostics go to stderr.
- Preserve the archived v1 `Content-Length` framing as an input/output
  compatibility mode selected by the first request. New clients use the
  standards-compliant newline mode.
- Support `initialize`, `notifications/initialized`, `ping`, `tools/list`,
  `tools/call`, cancellation, EOF, and graceful shutdown. Negotiate supported
  protocol versions rather than hard-coding the archived `2024-11-05` value.
- Tool failures are MCP tool results with `isError: true`, serialized text, and
  matching `structuredContent`; malformed protocol requests remain JSON-RPC
  errors.

### Browser-Owned Route Endpoint

- Keep authorization and execution in the Chromium browser process. The Node
  bridge may translate schemas and aliases, but it cannot decide tab ownership,
  internal-page permissions, JavaScript permission, or frame policy.
- Add a versioned native HTTP route endpoint on an ephemeral IPv4 loopback port
  only. Reject non-loopback `Host`, any browser `Origin`, unsupported methods,
  wrong content type, oversized bodies, and every unauthenticated request,
  including health/diagnostics.
- Generate a fresh high-entropy bearer token in the browser. Publish endpoint
  URL, token, protocol version, PID, and instance nonce through an atomic
  owner-only endpoint descriptor. Never return the token from `/health`, place
  it on a command line, log it, or copy it into route/audit results.
- Allow an explicit descriptor-file override for tests and custom user-data
  layouts. Normal macOS discovery uses the per-user runtime/temp directory, so
  the bridge does not guess a Chromium-versus-Prometheus profile directory.
- Normal Prometheus launches start the endpoint. Browser tests opt in
  explicitly so unrelated Chromium suites do not contend for ports or files.
- Keep the listener on a dedicated IO sequence and post route work to the UI
  sequence. Bound request size, concurrency, and completion time; shutdown must
  invalidate pending callbacks exactly once and remove only its own descriptor.

### Profile, Session, and Ownership Lifetime

- Make the long-lived agent service/profile registry profile-keyed before
  exposing it over transport. A session created against one regular profile
  must never become authority for another profile or an off-the-record profile.
- Each stdio bridge process obtains one opaque browser-issued session during
  MCP initialization. Client labels are bounded display metadata only. The
  bridge heartbeat keeps that session live; production reconnect grace is 10
  seconds after the last heartbeat.
- Keep the opaque session id in bridge memory and reuse it across transient
  native requests. An explicit environment-provided resume id may reconnect an
  external process within the browser's grace window; a label alone never
  resumes or authorizes a session.
- Graceful bridge shutdown closes the session and releases its owned tabs.
  Expired sessions must also release stale ownership before another live
  session is denied. Abrupt bridge loss retains the session only for the bounded
  reconnect grace.
- Preserve the default concurrent-agent cap, `AGENT_CAP_REACHED`,
  `TAB_NOT_OWNED`, `TAB_OUT_OF_SCOPE`, and other stable typed errors through the
  native endpoint and MCP result without string-only inference.
- Explicit `tab_id`/window targets use stable browser-issued handles. Safe page
  and navigation routes may target owned background tabs without activating
  them; foreground-only operations stay explicit.
- Accept compatibility target spellings `tab_id`, `tabId`, and `tabIndex`.
  Stable handles win; a mutable index is resolved only at call time, and
  conflicting forms return `INVALID_TARGET`.

### Tool Catalog and Schema Compatibility

- Treat the preserved 46-name v1 bridge catalog and the current FSB reference
  registry as contract inputs, not source to copy. Maintain one data-driven
  Prometheus catalog for tool names, JSON Schemas, aliases, native routes, and
  compatibility status. Every name in their 90-name union must have exactly
  one explicit disposition: native, alias, typed stub, later-phase owner, or
  removed. Zero names may be silently unmapped.
- Map the native Phase 17/18 names directly where possible. Preserve common
  legacy aliases such as `new_tab` -> `open_tab`, `switch_tab` ->
  `activate_tab`, `type` -> `type_text`, `select` -> `select_option`, and
  `refresh` -> `reload` without weakening validation.
- `open_tab`/`new_tab` accept an explicit foreground flag and default to a
  background tab. Only `switch_tab`/`activate_tab` foregrounds a target by
  definition.
- Implement `get_text` and `get_attribute` as bounded, read-only, exact-frame
  element reads behind the same fresh-ref and frame-policy boundary as page
  actions. Do not synthesize these reads through caller-visible arbitrary
  JavaScript.
- Expose coordinate and changed/removed mutation names with accurate schemas.
  If Chromium does not yet have a safe implementation, return a stable typed
  compatibility result with replacement tools and migration guidance; never
  silently omit the name or pretend success.
- Expose Phase 20/21-owned runtime, provider, vault, memory, site-guide, log,
  and supervision names as `NOT_READY` compatibility stubs carrying their owner
  phase and recovery guidance. Phase 20 may replace these entries in place.
- Coerce finite numeric strings only for schema fields declared numeric, since
  existing external hosts may stringify numbers. Reject empty strings,
  non-finite values, fractional integers, and out-of-range values.
- Apply deterministic bounds to names, strings, arrays, scripts, URLs,
  selectors, refs, diagnostics, and output. Reject unknown properties for
  security-sensitive tools even if the archived bridge accepted arbitrary
  objects.

### Visual-Session Compatibility

- Action tools accept the exact optional fields `visual_reason`, `client`, and
  `is_final`. Preserve them through aliasing and the native request envelope.
- These fields are presentation metadata, never identity or authorization.
  Normalize known FSB badge labels and reject a supplied spoofed/unknown badge
  with `BADGE_NOT_ALLOWED`; callers from newer MCP hosts may omit the optional
  bundle and receive a safe generic external-client label.
- Do not copy `visual_reason` into the audit log, changed-state strings, error
  text, endpoint descriptor, or stderr. Native results may report only bounded
  compatibility metadata needed to prove preservation.
- Read-only tools do not require visual fields. Existing callers that include
  them may be accepted where harmless, but they cannot change authorization.

### Diagnostics

- Provide a native health document and MCP `diagnostics` tool with stable
  component keys for browser, bridge/server, active tab, content/page adapter,
  internal adapter, WebUI adapter, vault, provider, supervision, and extension
  system.
- Report `ready`, `degraded`, `not_ready`, or `unavailable` truthfully, with a
  bounded reason and next action. Later-phase components remain `not_ready`
  rather than making Phase 19 fail or claiming parity.
- Health responses expose no bearer token, page text, URLs beyond explicitly
  safe page type metadata, profile filesystem path, provider secret, vault
  data, or script content.

### Verification

- Build contract/codec/session/endpoint unit tests before browser integration.
- Add browser tests for real endpoint auth, profile scope, ownership, cap,
  reconnect/expiry cleanup, background targeting, page reads, visual metadata,
  typed denials, and diagnostic layers.
- Add Node tests for standard newline framing, archived `Content-Length`
  framing, lifecycle, tool lists/schemas, aliases, numeric coercion, visual
  fields, cancellations, native error mapping, compatibility stubs, stdout
  cleanliness, and bounded malformed input.
- Add an automated smoke that launches the built Prometheus browser with a
  temporary endpoint descriptor, starts the external stdio bridge, performs
  MCP initialize/list/call, and exercises at least a tab route, a real page
  read, a typed compatibility error, and diagnostics.
- Human UAT is not part of Phase 19. Builds and automated unit/browser/smoke,
  security, preservation, artifact-isolation, and diff gates remain mandatory.

## Discretion Areas

- Exact C++ class names, source-set splits, endpoint paths, and compact JSON
  field layout may vary if the locked security and compatibility behavior is
  preserved.
- The planner may split the catalog into generated/static modules and may use
  the Chromium-vendored Node launcher for tests, but production must not require
  a package install at runtime.
- Compatibility stubs may use one shared error code plus stable per-tool owner
  metadata, or a small closed family of codes, as long as clients receive
  deterministic migration guidance.
- The planner may add a dedicated Phase 19 validation target if that produces a
  cleaner fast feedback loop than expanding the existing unit target.

## Canonical References

- `.planning/ROADMAP.md` Phase 19 and `.planning/REQUIREMENTS.md` MCP-01 through
  MCP-07.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`, especially MCP
  compatibility, route authority, secrets, and the migration evidence row.
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-CONTEXT.md`
  and Phase 17 summaries for sessions, stable tab ownership, profile scoping,
  route results, and audit policy.
- `.planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-VERIFICATION.md`
  for the verified page/frame/action boundary Phase 19 must call rather than
  bypass.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_*`,
  `prometheus_page_*`, and `chrome/common/prometheus_render_frame.mojom`.
- Preserved v1 bridge files in `.context/falkon-preservation/falkon-prometheus-v1.bundle`
  and the read-only `.context/fsb-reference/mcp/` contract/test sources.
- Official MCP specification: `https://modelcontextprotocol.io/specification/2025-11-25/`.

## Deferred Ideas

- Do not add embedded Claude/agent execution, a terminal, engine selection,
  CLAUDE.md provisioning, or agent-CLI lifecycle management in any phase.
- Provider-backed task execution and full runtime tools are Phase 20.
- Native vault/provider secrets and autofill confirmation are Phase 20 and must
  never be implemented in Node transport code.
- Live visual-session supervision, pairing, remote snapshots/diffs, and remote
  control are Phase 21.
- Extension runtime health becomes live in Phase 22; Phase 19 reports its
  current not-ready state only.
- Public signing/notarization and final client setup packaging are Phase 24.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
