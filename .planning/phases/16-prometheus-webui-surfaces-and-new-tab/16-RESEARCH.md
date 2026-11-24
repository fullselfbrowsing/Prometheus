# Phase 16 Research - Prometheus WebUI Surfaces and New Tab

**Created:** 2026-07-07
**Status:** Ready for planning

## Local Chromium Findings

### Prometheus WebUI Precedent

Phase 14 added `chrome://prometheus-theme-preview`:

- Controller/config:
  `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.{h,cc}`
- GN target:
  `.context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn`
- Registration:
  `.context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc`
- Resources:
  `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grd`
  and `.grdp`

Reusable pattern:

- `content::DefaultWebUIConfig`
- `content::WebUIController`
- `content::WebUIDataSource::CreateAndAdd(profile, host)`
- `SetDefaultResource(IDR_...)`
- `AddResourcePath(path, IDR_...)`
- generated includes from `chrome/grit/prometheus_resources.h`

Important caveat:

- Phase 14 preview is dev-only and gated by `DCHECK_IS_ON()` plus UNKNOWN
  channel. Phase 16 product surfaces must not inherit that guard.

### Side Panel Hosting

Chromium side panel entries can host WebUI content through:

- `chrome/browser/ui/views/side_panel/side_panel_web_ui_view.h`
- `SidePanelWebUIViewT<T>`
- `WebUIContentsWrapperT<T>`

Local examples:

- History side panel:
  `chrome/browser/ui/views/side_panel/history/history_side_panel_coordinator.cc`
- Bookmarks side panel:
  `chrome/browser/ui/views/side_panel/bookmarks/bookmarks_side_panel_coordinator.cc`

Phase 15 currently registers a Prometheus placeholder view from
`ToolbarView` using `SidePanelEntry::Id::kAssistant`. Phase 16 should replace
the placeholder factory with a WebUI-backed view while preserving the stable
toolbar button and test accessors.

### Browser Tests

Existing test patterns:

- Navigation tests use `ui_test_utils::NavigateToURL(browser(), GURL(...))`
  and inspect `browser()->tab_strip_model()->GetActiveWebContents()`.
- WebUI creation is asserted with `web_contents->GetWebUI()`.
- DOM/string checks can use `content::EvalJs` or title checks after navigation.
- Side-panel browser tests can use toolbar button test APIs and
  `SidePanelCoordinator`/`SidePanelUI` visibility checks.

### Resource and Security Gates

Phase 14 already has resource tests and offline verification logic that can be
extended:

- `chrome/browser/prometheus/prometheus_asset_resource_unittest.cc`
- `.planning/chromium/verify-asset-pipeline.sh`

Phase 16 needs a narrower WebUI resource scanner for new HTML/CSS/JS:

- flag `http://`, `https://`, `fonts.googleapis`, `@import`
- flag external `src=` and `href=`
- allow comments/provenance URLs only if not load-bearing
- assert no prompt fixture appears in URLs during Ask FSB tests

## Implementation Implications

- A single controller file can declare three `DefaultWebUIConfig` classes and
  three controllers, but separate files may keep compilation units clearer.
- A shared resource helper should map common CSS, JS, icons, and brand assets so
  new hosts do not duplicate 72 icon mappings by hand if not needed.
- Start-page Ask FSB handoff should be browser-process state, not URL state.
  A small `chrome/browser/prometheus/prometheus_side_panel_handoff` helper can
  store/consume a pending prompt per profile or browser until Phase 17/20 owns
  the real runtime.
- Side-panel WebUI can initially consume safe stub data from its controller.
  Live bookmarks/history/tabs are allowed only when browser-process handlers are
  explicit and tested.
- Control panel shell should render all section names and empty states now, with
  real provider/vault/runtime sections deferred to Phase 20.

## Risks

| Risk | Mitigation |
|------|------------|
| WebUI renders blank due to missing resource path | Browser tests navigate each host and assert required DOM labels. |
| Prompt leaks into URL/history | Handoff stores prompt in browser-process state and tests assert URL does not contain sample prompt. |
| Side panel placeholder remains wired | Browser test opens Prometheus toolbar button and asserts side-panel content is Prometheus WebUI. |
| Secret-like data in renderer fixtures | Keep Phase 16 data metadata-only and add resource scans for known secret/prompt fixtures. |
| Native screenshots still blocked | Use DOM/layout assertions and keep human visual UAT carried forward. |
