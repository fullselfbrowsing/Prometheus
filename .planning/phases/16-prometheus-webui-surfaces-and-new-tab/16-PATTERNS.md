# Phase 16 Patterns

## WebUI Controllers

- Put Prometheus WebUI controllers/configs under
  `chrome/browser/ui/webui/prometheus/`.
- Include generated Prometheus resources via `chrome/grit/prometheus_resources.h`.
- Register product WebUI configs in `chrome_web_ui_configs.cc` without the
  Phase 14 dev-only guard.
- Use explicit `AddResourcePath` for every referenced resource.

## Resources

- Put WebUI HTML/CSS/JS under `chrome/browser/resources/prometheus/`.
- Add every Phase 16 resource to `prometheus_resources.grdp`.
- Reuse Phase 14 fonts/icons/assets; do not create a second asset pipeline.
- Add resource tests whenever new IDRs are added.

## Side Panel

- Reuse Phase 15 toolbar buttons and accessibility labels.
- Replace placeholder side-panel view with a `SidePanelWebUIViewT`-style hosted
  WebUI view.
- Avoid URL query strings for prompt seed. Use browser-process handoff state.

## Browser Tests

- Prefer browser tests for host navigation, side-panel opening, prompt leakage,
  and required DOM labels.
- Use `content::EvalJs` for DOM presence and URL checks.
- Keep tests focused and filtered with `*PrometheusWebUI*`,
  `*PrometheusNewTab*`, `*PrometheusSidePanel*`, and
  `*PrometheusControlPanel*`.

## Security

- Renderer messages are untrusted.
- Secrets and provider keys never appear in fixture resources.
- Prompt strings never enter URLs, fragments, history, console logs, or resource
  names.
- Remote resource scans run before phase close.
