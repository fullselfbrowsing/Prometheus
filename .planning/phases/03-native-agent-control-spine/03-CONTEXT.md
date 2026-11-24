# Phase 3: Native Agent Control Spine - Context

**Gathered:** 2026-06-16
**Status:** Ready for execution

<domain>
## Phase Boundary

Phase 3 adds the browser-native control layer that later phases can expose through MCP and richer FSB tooling. The scope is a local, typed, audited command spine that can drive tabs/pages and one browser-owned surface. It is not the full MCP bridge or multi-agent policy layer; those remain Phase 4.

</domain>

<decisions>
## Implementation Decisions

- Add a disabled-by-default loopback JSON command server enabled with `PROMETHEUS_AGENT_PORT`.
- Keep the public protocol small and structured: `POST /agent/command` with `tool`, optional `id`, and optional `params`.
- Return a normalized envelope with `ok`, `id`, `tool`, `result` or typed `error`, and an audit marker.
- Write command audit entries as JSONL under the active profile/config path.
- Use existing native APIs: `MainApplication::windows()`, `BrowserWindow::tabWidget()`, `TabbedWebView`, `WebPage::execJavaScript()`, and the existing Preferences dialog.
- Keep MCP-specific schemas, ownership, concurrency, visual sessions, and remote pairing out of this phase.

</decisions>

<code_context>
## Existing Code Insights

- `MainApplication` owns startup, windows, profiles, and app lifetime.
- `BrowserWindow` exposes `tabWidget()`, `weView()`, and current tab helpers.
- `TabWidget` exposes tab count/current index, `webTab(index)`, `addView`, and `setCurrentIndex`.
- `WebTab` exposes `webView()`, `url()`, `title()`, loading/pinned state, and native load/reload methods.
- `WebPage::execJavaScript` already offers synchronous JS readback with a timeout.
- Preferences can be opened natively by constructing `Preferences(BrowserWindow*)`.

</code_context>

<verification>
## Verification Strategy

- Build after adding the router/server.
- Add a smoke helper that launches Prometheus with `PROMETHEUS_AGENT_PORT`, waits for `/health`, runs tab/navigation/read/JS/internal/error commands, and exits cleanly.
- Confirm audit JSONL is written.
- Preserve the Phase 2 browser smoke test.

</verification>
