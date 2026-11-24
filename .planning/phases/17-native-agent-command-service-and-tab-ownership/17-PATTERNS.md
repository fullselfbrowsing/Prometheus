---
phase: 17-native-agent-command-service-and-tab-ownership
created: 2026-07-07
status: complete
---

# Phase 17 Pattern Map

## Files To Create

| Planned file | Role | Closest analog |
|--------------|------|----------------|
| `chrome/browser/prometheus/prometheus_agent_route.{h,cc}` | Route names, target structs, typed result/error helpers | `prometheus_tab_commands.{h,cc}` source-set style; Chromium enum/string helpers in local helpers. |
| `chrome/browser/prometheus/prometheus_agent_route_unittest.cc` | Pure route/result tests | `prometheus_tab_state_unittest.cc`, `prometheus_webui_unittest.cc`. |
| `chrome/browser/prometheus/prometheus_agent_session.{h,cc}` | Browser-issued session registry, caps, expiry/reconnect policy | Smaller Prometheus-owned analog to `actor_keyed_service.h` session/task ownership. |
| `chrome/browser/prometheus/prometheus_agent_session_unittest.cc` | Session/cap/label tests | `prometheus_tab_state_unittest.cc`. |
| `chrome/browser/prometheus/prometheus_agent_tab_data.{h,cc}` | Browser-owned ownership data attached to tabs | `actor_tab_data.h` uses tab-attached data; `PrometheusTabState` is current consumer. |
| `chrome/browser/prometheus/prometheus_agent_tab_data_unittest.cc` | Ownership policy tests | `prometheus_tab_state_unittest.cc`. |
| `chrome/browser/prometheus/prometheus_agent_service.{h,cc}` | Route service facade, target resolution, tab/window/navigation actions | `prometheus_tab_commands.cc`, `TabListInterface`, `BrowserWindowInterface`. |
| `chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` | Real browser action and ownership tests | `prometheus_tab_commands_browsertest.cc`, `prometheus_web_ui_browsertest.cc`. |
| `chrome/browser/prometheus/prometheus_agent_audit.{h,cc}` | Minimal route audit records/ring buffer | Prometheus-owned data helpers; avoid raw payload logging. |

## Files To Modify

| Existing file | Planned change | Pattern/constraint |
|---------------|----------------|--------------------|
| `chrome/browser/prometheus/BUILD.gn` | Add new source sets, unit-test sources, and browser-test source wiring where needed. | Keep focused source sets like `prometheus_tab_state` and `prometheus_tab_commands`. |
| `chrome/browser/prometheus/prometheus_tab_state.{h,cc}` | Read browser-owned agent tab data and expose owner/automation/health state. | Preserve safe default and no caller-label trust invariant. |
| `chrome/test/BUILD.gn` or relevant browser-test GN target | Add `prometheus_agent_service_browsertest.cc` if browser tests require explicit registration. | Follow existing Prometheus browser-test registrations from Phases 15/16. |

## Data Flow

1. Caller creates or resumes a browser-issued session through the session registry.
2. Caller submits a typed `PrometheusAgentRouteRequest`.
3. Route service validates session, route name, target selector, action scope,
   and ownership.
4. Target resolver maps browser/window/tab identifiers to
   `BrowserWindowInterface`, `TabListInterface`, and `tabs::TabInterface`.
5. Service performs a browser-owned action or returns a typed denial.
6. Ownership data updates through `PrometheusAgentTabData`.
7. `PrometheusTabState` reflects browser-owned owner/automation/health state.
8. Route result and audit record return only allowlisted metadata.

## Implementation Pitfalls

- Do not use tab index as durable identity.
- Do not cache raw `WebContents*` across actions.
- Do not trust caller labels as identity.
- Do not log raw prompts, page text, provider keys, vault values, or full route
  payloads.
- Do not implement Phase 18 page actions in Phase 17.
- Do not copy GPL Falkon router implementation; preserve behavior contracts only.

## Verification Anchors

- Unit tests should run in `prometheus_unittests`.
- Browser tests should use `InProcessBrowserTest`.
- Final plan should run the root Chromium env/GPL/isolation gates and export a
  Phase 17 patch series.
