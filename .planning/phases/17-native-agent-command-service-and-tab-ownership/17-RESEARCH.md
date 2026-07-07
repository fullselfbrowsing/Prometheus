---
phase: 17-native-agent-command-service-and-tab-ownership
researched: 2026-07-07
status: complete
sources: [local-chromium-source, planning-context]
---

# Phase 17 Research: Native Agent Command Service and Tab Ownership

## Research Question

What does the planner need to know to implement a Chromium-native Prometheus
agent command service with authenticated sessions, stable tab ownership, typed
route results, and browser-owned tab/window actions?

## Standard Stack

| Concern | Recommended primitive | Evidence |
|---------|-----------------------|----------|
| Browser-process service | Prometheus-owned C++ source sets under `chrome/browser/prometheus/` | Existing `prometheus_tab_state`, `prometheus_tab_commands`, `prometheus_ask_fsb_handoff` source sets. |
| Session registry | Profile-scoped service object or facade stored in browser-owned C++ state | `ActorKeyedService` uses profile-keyed lifetime; Phase 17 can implement smaller Prometheus-owned equivalent. |
| Stable tab identity | `tabs::TabInterface::GetHandle()` / `tabs::TabHandle` | `components/tabs/public/tab_interface.h` documents tab handles and warns not to cache `WebContents*` for durable identity. |
| Tab operations | `TabListInterface` and existing `PrometheusTabCommands` helper | `chrome/browser/tab_list/tab_list_interface.h` exposes handle-based open/activate/close/move/duplicate/group APIs. |
| Browser/window context | `BrowserWindowInterface` | Provides profile, window session id, tab strip model, and side-panel feature access. |
| Ownership state | Prometheus tab-attached data feeding `PrometheusTabState` | Current tests prove safe defaults and no caller-label trust. |
| Internal surfaces | Phase 16 WebUI URLs plus side panel infrastructure | `prometheus_web_ui_browsertest.cc`, `prometheus_side_panel_helper.cc`, `SidePanelUIProvider`. |
| Verification | `prometheus_unittests` plus focused `browser_tests` | Phases 15/16 established this pattern. |

## Relevant Local Patterns

### `PrometheusTabState`

Current files:

- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc`

The seam already exposes `owner_label`, `automation_active`,
`supervision_active`, and `health`. It currently returns safe defaults and has a
test proving caller-provided user data cannot inject an owner label. Phase 17
should extend this by reading browser-owned ownership/session data.

### `PrometheusTabCommands`

Current files:

- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.h`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands_browsertest.cc`

This helper already wraps Chromium tab commands for duplicate, move-to-window,
context-menu close/pin/mute/group commands, and unsupported unload. Phase 17
can call it from route service actions where index-based commands are still the
lowest-friction API, but target resolution should prefer stable handles.

### `TabInterface` And `TabListInterface`

Relevant files:

- `.context/chromium/src/components/tabs/public/tab_interface.h`
- `.context/chromium/src/chrome/browser/tab_list/tab_list_interface.h`
- `.context/chromium/src/chrome/browser/ui/tabs/tab_model.h`

`TabInterface` provides `GetHandle()`, lifecycle callbacks, title/URL access,
profile access, modal state, and `GetContents()` when actual content is needed.
The header explicitly warns that `WebContents` can be replaced on discard and
that durable callers should hold a tab reference/handle instead.

`TabListInterface` exposes handle-based operations for active tab, open,
activate, insert, discard, duplicate, close, move, group, ungroup, and
window-to-window moves. Its static `From(BrowserWindowInterface*)` reads from
the browser window's `UnownedUserDataHost`, which fits the existing Chromium
feature attachment pattern.

### Upstream Actor Code

Relevant files:

- `.context/chromium/src/chrome/browser/actor/actor_keyed_service.h`
- `.context/chromium/src/chrome/browser/actor/actor_tab_data.h`

The upstream actor code is useful as a local Chromium pattern for profile-keyed
task service lifetime, actor/task state, `tabs::TabInterface` usage, and
tab-attached data. It is not the product contract for Prometheus; Phase 17
should borrow structural patterns only where they fit Prometheus's route/result
and FSB compatibility requirements.

## Proposed Plan Decomposition

1. Route schema and typed result spine.
2. Browser-owned session registry with caps and reconnect/expiry errors.
3. Stable tab ownership data and `PrometheusTabState` integration.
4. Route service target resolver plus tab/window/navigation actions.
5. Internal surface adapters and audit records.
6. Full gate run and patch export.

This keeps each plan small enough to build/test independently while preserving
the dependency order: types -> sessions -> ownership -> actions -> audit/adapters.

## Validation Architecture

### Automated Unit Tests

- Route name parsing and serialization reject unknown routes.
- Error codes serialize to stable FSB-compatible strings.
- Route result factories include success/failure, recovery text, target fields,
  timing fields, and changed-state arrays without secret/prompt fields.
- Session registry creates opaque browser-issued sessions, rejects unknown or
  expired sessions, enforces caps, and treats display labels as metadata only.
- Ownership policy allows owner actions, optionally claims unowned tabs, denies
  cross-session control, and returns `TAB_NOT_OWNED`.
- `PrometheusTabState` reads only browser-owned ownership state and keeps safe
  defaults for tabs with no ownership data.

### Automated Browser Tests

- Route service lists tabs and returns stable handles/state for at least three
  tabs.
- Two sessions cannot control the same owned tab.
- Open, activate, navigate, reload, back, forward, close, and duplicate routes
  mutate the intended tab/window and report changed state.
- Internal surface routes can open/focus `chrome://prometheus-newtab/` and
  `chrome://prometheus-control-panel/`; side panel open/focus uses the existing
  side-panel entry infrastructure.
- Unsupported Phase 18 page actions return `UNSUPPORTED_ROUTE` or
  `TAB_OUT_OF_SCOPE`, not silent success.

### Static/Root Gates

- `../../depot_tools/autoninja -C out/Default prometheus_unittests browser_tests`
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'`
- `./out/Default/browser_tests --gtest_filter='*PrometheusAgent*:*PrometheusTabCommands*'`
- `bash .planning/chromium/check-chromium-env.sh`
- `bash .planning/chromium/check-falkon-gpl-guard.sh`
- `bash .planning/chromium/verify-artifact-isolation.sh`
- `git -C .context/chromium/src diff --check`
- `git diff --check`
- patch export from Phase 16 tip through Chromium HEAD.

## Security Notes

- Threat: caller-provided session/client labels spoof ownership.
  Mitigation: browser-issued opaque session IDs authorize all actions; labels are
  metadata only.
- Threat: mutable tab indices cause a route to affect the wrong tab.
  Mitigation: resolve to `tabs::TabHandle` / `TabInterface` and re-check before
  mutation.
- Threat: cross-agent control of a tab.
  Mitigation: browser-owned tab data plus deny-by-default ownership checks.
- Threat: audit/result logs leak prompts, provider secrets, vault values, page
  text, or raw private browsing data.
  Mitigation: route results and audit records use allowlisted metadata fields.
- Threat: page action routes are accidentally implemented before Phase 18's
  verification model.
  Mitigation: return typed unsupported/out-of-scope errors for page mutation and
  DOM read routes in Phase 17.

## Open Questions For Planner

- Whether to create a profile-keyed service immediately or a smaller facade with
  a clear later migration path.
- Whether to use `TabListInterface` exclusively for tab actions or keep a small
  bridge to `PrometheusTabCommands` where context-menu commands are already
  tested.
- Whether side-panel opening belongs in the route service now or should be
  represented as an internal-surface route that returns unsupported until a
  minimal adapter is cheap to test.

## Research Complete

The phase is ready for planning.
