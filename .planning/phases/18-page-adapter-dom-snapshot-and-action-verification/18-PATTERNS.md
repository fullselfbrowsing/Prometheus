# Phase 18: Page Adapter, DOM Snapshot, and Action Verification - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 17 proposed new/modified files or classes
**Analogs found:** 15 / 17
**Project instructions:** No root `CLAUDE.md`; no `.claude/skills/` or `.agents/skills/` directories found.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `chrome/browser/prometheus/prometheus_agent_route.{h,cc}` | route/schema | request-response | `chrome/browser/prometheus/prometheus_agent_route.{h,cc}` | exact extension |
| `chrome/browser/prometheus/prometheus_agent_service.{h,cc}` | service/controller | request-response | `chrome/browser/prometheus/prometheus_agent_service.{h,cc}` | exact extension |
| `chrome/browser/prometheus/prometheus_agent_audit.{h,cc}` | utility/logging | event-driven metadata | `chrome/browser/prometheus/prometheus_agent_audit.{h,cc}` | exact extension |
| `chrome/browser/prometheus/prometheus_page_adapter.{h,cc}` | service/facade | request-response | `prometheus_agent_service.cc`, `actor/tools/load_and_extract_content_tool.cc`, `actor/tools/page_tool.cc` | role-match |
| `chrome/browser/prometheus/prometheus_page_snapshot.{h,cc}` | utility/transform | transform | `components/optimization_guide/content/browser/page_content_proto_provider.*`, `page_content_proto_util.*` | exact substrate |
| `chrome/browser/prometheus/prometheus_page_action.{h,cc}` | service/utility | request-response + event-driven | `chrome/browser/actor/tools/page_tool.*`, action request classes | role-match |
| `chrome/browser/prometheus/prometheus_page_waiter.{h,cc}` | utility/service | event-driven wait | `chrome/browser/actor/tools/observation_delay_controller.*`, `PageSettledMonitor` | role-match |
| `chrome/browser/prometheus/prometheus_page_error.{h,cc}` | utility | transform | route error helpers in `prometheus_agent_service.cc` and `prometheus_agent_route.cc` | exact style |
| `chrome/common/chrome_render_frame.mojom` or a new Prometheus renderer mojom | IPC config | request-response renderer IPC | actor methods in `chrome/common/chrome_render_frame.mojom` | role-match |
| `chrome/browser/prometheus/prometheus_page_adapter_unittest.cc` | test | request-response + transform | `prometheus_agent_route_unittest.cc`, `prometheus_agent_audit_unittest.cc`, `prometheus_agent_tab_data_unittest.cc` | role-match |
| `chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc` | test | transform | `prometheus_agent_route_unittest.cc`, optimization guide node utilities | partial |
| `chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` or extensions to `prometheus_agent_service_browsertest.cc` | test | browser request-response | `prometheus_agent_service_browsertest.cc`, actor page tool browser tests | exact test style |
| `chrome/test/data/prometheus/page_adapter/*.html` | test fixture | file-I/O | `chrome/test/data/actor/*.html` | role-match |
| `chrome/browser/prometheus/BUILD.gn` | config | build graph | existing Prometheus source sets and `prometheus_unittests` | exact extension |
| `chrome/browser/ui/views/prometheus/BUILD.gn` | config/test wiring | build graph | existing Prometheus `browser_tests` source set | exact extension |
| `chrome/test/BUILD.gn` | config/test wiring | build graph | existing dependency on `//chrome/browser/ui/views/prometheus:browser_tests` | already wired |
| `chrome/browser/prometheus/prometheus_page_drop_file_policy.*` if file drops are kept in scope | policy/utility | file-I/O | none found | no direct analog |

## Pattern Assignments

### `prometheus_agent_route.{h,cc}` (route/schema, request-response)

**Analog:** `chrome/browser/prometheus/prometheus_agent_route.{h,cc}`

**Imports and type style** (`prometheus_agent_route.h` lines 8-15):

```cpp
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "base/time/time.h"
#include "components/tabs/public/tab_interface.h"
#include "url/gurl.h"
```

**Enum/request/result pattern** (`prometheus_agent_route.h` lines 19-35, 62-92):

```cpp
enum class AgentRouteName {
  kListTabs,
  kListWindows,
  kOpenTab,
  ...
  kUnsupportedPageAction,
};

struct AgentRouteRequest {
  AgentRouteName route_name = AgentRouteName::kUnsupportedPageAction;
  std::string session_id;
  AgentTarget target;
  std::optional<GURL> url;
};

struct AgentRouteResult {
  static AgentRouteResult Success(std::vector<std::string> changed_state);
  static AgentRouteResult Failure(AgentErrorCode error_code,
                                  std::string message,
                                  std::string recovery);
  bool ok = false;
  AgentErrorCode error_code = AgentErrorCode::kNone;
  std::string message;
  std::string recovery;
  base::TimeDelta elapsed;
  std::vector<std::string> changed_state;
  AgentTarget target;
};
```

**Route string table pattern** (`prometheus_agent_route.cc` lines 18-35, 78-95):

```cpp
constexpr RouteNameEntry kRouteNameEntries[] = {
    {"list_tabs", AgentRouteName::kListTabs},
    ...
    {"unsupported_page_action", AgentRouteName::kUnsupportedPageAction},
};

std::optional<AgentRouteName> AgentRouteNameFromString(
    std::string_view route_name) {
  for (const auto& entry : kRouteNameEntries) {
    if (entry.name == route_name) {
      return entry.route_name;
    }
  }
  return std::nullopt;
}
```

**Apply to Phase 18:**

- Add enum/string entries for `read_page`, `get_dom_snapshot`, `get_page_snapshot`, `execute_js`, `click`, `type_text`, `press_key`, `scroll`, `hover`, `select_option`, `clear`, `drag`, and `drop_file` if implemented.
- Add bounded page payload fields to `AgentRouteRequest`/`AgentRouteResult` rather than overloading `changed_state`.
- Keep failure style as `AgentErrorCode` plus human message plus recovery string.

### `prometheus_agent_service.{h,cc}` (service/controller, request-response)

**Analog:** `chrome/browser/prometheus/prometheus_agent_service.{h,cc}`

**Service imports** (`prometheus_agent_service.cc` lines 12-31):

```cpp
#include "base/callback_list.h"
#include "base/check.h"
#include "base/functional/bind.h"
#include "chrome/browser/prometheus/prometheus_agent_tab_data.h"
#include "chrome/browser/prometheus/prometheus_tab_commands.h"
#include "chrome/browser/tab_list/tab_list_interface.h"
#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"
#include "content/public/browser/navigation_controller.h"
#include "content/public/browser/web_contents.h"
#include "url/gurl.h"
```

**Auth/session gate** (`prometheus_agent_service.cc` lines 145-164):

```cpp
AgentRouteResult PrometheusAgentService::ExecuteRoute(
    BrowserWindowInterface* browser,
    const AgentRouteRequest& request) {
  const base::Time timestamp = Now();
  const base::TimeTicks started_at = base::TimeTicks::Now();
  AgentSessionResult session_result =
      session_registry_->ValidateSession(request.session_id, timestamp);
  if (!session_result.route_result.ok) {
    return FinishRoute(request, timestamp, started_at,
                       session_result.route_result);
  }

  AgentRouteResult touch_result =
      session_registry_->TouchSession(request.session_id, Now());
  if (!touch_result.ok) {
    return FinishRoute(request, timestamp, started_at, touch_result);
  }
```

**Target and ownership gate** (`prometheus_agent_service.cc` lines 247-271):

```cpp
case AgentRouteName::kNavigate: {
  AgentRouteResult resolved_result = ResolveTarget(
      browser, request.target, /*require_tab=*/true, &resolved);
  if (!resolved_result.ok) {
    return FinishRoute(request, timestamp, started_at, resolved_result);
  }
  if (!request.url.has_value() ||
      !IsAllowedAgentNavigationUrl(*request.url)) {
    return FinishRoute(
        request, timestamp, started_at,
        PermissionBlocked("URL scheme is not allowed for agent navigation",
                          "Use http, https, about:blank, or an explicit "
                          "Prometheus surface route"));
  }
  AgentRouteResult control =
      EnsureCanControl(resolved.tab, *session_result.session);
  if (!control.ok) {
    return FinishRoute(request, timestamp, started_at, control);
  }
  content::NavigationController::LoadURLParams params(*request.url);
  resolved.tab->GetContents()->GetController().LoadURLWithParams(
      std::move(params));
```

**Target resolution pattern** (`prometheus_agent_service.cc` lines 400-472):

```cpp
AgentRouteResult PrometheusAgentService::ResolveTarget(
    BrowserWindowInterface* browser,
    const AgentTarget& target,
    bool require_tab,
    ResolvedTarget* resolved) {
  if (!browser) {
    return InvalidTarget("Missing browser target");
  }
  ...
  if (!IsNullTabHandle(target.tab_handle)) {
    tab = target.tab_handle.Get();
    if (!tab) {
      return StaleTarget("Requested tab handle no longer exists");
    }
    tab_index = tab_list->GetIndexOfTab(target.tab_handle);
    if (tab_index == -1) {
      return StaleTarget("Requested tab is not in the target browser");
    }
  } else if (require_tab) {
    tab = tab_list->GetActiveTab();
    if (!tab) {
      return StaleTarget("Target browser has no active tab");
    }
  }
  resolved->browser = browser;
  resolved->tab_list = tab_list;
  resolved->tab = tab;
  resolved->tab_index = tab_index;
  return AgentRouteResult::Success({});
}
```

**Finish/audit pattern** (`prometheus_agent_service.cc` lines 581-613):

```cpp
AgentRouteResult PrometheusAgentService::FinishRoute(
    const AgentRouteRequest& request,
    base::Time timestamp,
    base::TimeTicks started_at,
    AgentRouteResult result) {
  result.elapsed = base::TimeTicks::Now() - started_at;
  RecordAudit(request, result, timestamp);
  return result;
}

void PrometheusAgentService::RecordAudit(const AgentRouteRequest& request,
                                         const AgentRouteResult& result,
                                         base::Time timestamp) {
  AgentRouteAuditRecord record;
  record.route_name = request.route_name;
  record.session_id = request.session_id;
  ...
  record.changed_state = result.changed_state;
  record.timestamp = timestamp;
  audit_log_.Append(std::move(record));
}
```

**Apply to Phase 18:**

- Dispatch page routes only after the same session, target, profile, and ownership gates.
- Resolve `content::WebContents*` from `ResolvedTarget.tab->GetContents()` inside the page route path and do not cache it across calls.
- Keep content payloads in route result fields, never in `changed_state`.

### `prometheus_agent_audit.{h,cc}` (utility/logging, event-driven metadata)

**Analog:** `chrome/browser/prometheus/prometheus_agent_audit.{h,cc}`

**Audit record shape** (`prometheus_agent_audit.h` lines 19-37):

```cpp
struct AgentRouteAuditRecord {
  AgentRouteName route_name = AgentRouteName::kUnsupportedPageAction;
  std::string session_id;
  std::optional<int32_t> browser_session_id;
  std::optional<int32_t> window_session_id;
  std::optional<int32_t> tab_handle;
  AgentErrorCode error_code = AgentErrorCode::kNone;
  base::TimeDelta elapsed;
  std::vector<std::string> changed_state;
  base::Time timestamp;
};

bool IsAgentRouteAuditMetadataSafe(std::string_view value);
bool IsAgentRouteAuditRecordSafe(const AgentRouteAuditRecord& record);
```

**Unsafe metadata filter** (`prometheus_agent_audit.cc` lines 17-19, 40-64):

```cpp
constexpr auto kDisallowedAuditMetadataTerms =
    std::to_array<std::string_view>({"prompt", "secret", "page_text", "vault",
                                     "provider_key", "raw_url", "dom_text"});

bool IsAgentRouteAuditRecordSafe(const AgentRouteAuditRecord& record) {
  if (!IsAgentRouteAuditMetadataSafe(
          AgentRouteNameToString(record.route_name))) {
    return false;
  }
  ...
  for (const std::string& changed_state : record.changed_state) {
    if (!IsAgentRouteAuditMetadataSafe(changed_state)) {
      return false;
    }
  }
  return true;
}

bool AgentRouteAuditLog::Append(AgentRouteAuditRecord record) {
  if (!IsAgentRouteAuditRecordSafe(record)) {
    return false;
  }
```

**Test pattern** (`prometheus_agent_audit_unittest.cc` lines 14-25, 52-60):

```cpp
TEST_F(PrometheusAgentAuditTest, RejectsUnsafeMetadataTerms) {
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("prompt"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("contains_secret"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("page_text"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("vault"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("provider_key"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("raw_url"));
  EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("dom_text"));

  EXPECT_TRUE(IsAgentRouteAuditMetadataSafe("tab_opened"));
}

TEST_F(PrometheusAgentAuditTest, RejectsUnsafeChangedStateValues) {
  AgentRouteAuditLog log(4);
  AgentRouteAuditRecord record;
  record.route_name = AgentRouteName::kUnsupportedPageAction;
  record.changed_state = {"prompt:do-not-store"};
  EXPECT_FALSE(log.Append(record));
}
```

**Apply to Phase 18:**

- Add tests for page-route audit terms such as `script`, `selector`, `typed_text`, `file_path`, `dom_snapshot`, and raw page snippets if the planner extends the deny list.
- Prefer safe constants like `visible_text_returned`, `snapshot_returned`, `element_clicked`, `navigation_observed`, `value_changed`, `verification_timeout`, and `stuck_action_detected`.

### `prometheus_page_adapter.{h,cc}` (service/facade, request-response)

**Primary analogs:**

- Route authority: `chrome/browser/prometheus/prometheus_agent_service.cc`
- Page content extraction sequencing: `chrome/browser/actor/tools/load_and_extract_content_tool.cc`
- Renderer action invocation: `chrome/browser/actor/tools/page_tool.cc`

**Recommended public shape:** model after current Prometheus classes: small header, `namespace prometheus`, non-copyable class, browser-owned callbacks, `base::WeakPtrFactory`.

**Page read analog** (`inner_text.h` lines 33-60):

```cpp
// Requests the inner-text for the specified `host` as well as all local
// same-origin iframes. The returned inner-text contains the combined inner-text
// of all suitable iframes.
//
// NOTE: This function services the request as soon as called, it does not wait
// for the page to finish loading.
//
// IMPORTANT: The inner-text retrieved by this function is untrustworthy and
// should not be processed in the browser process.
void GetInnerText(content::RenderFrameHost& host,
                  std::optional<int> node_id,
                  InnerTextCallback callback);
```

**Page content extraction analog** (`load_and_extract_content_tool.cc` lines 453-485):

```cpp
void LoadAndExtractContentTool::OnTabObservationDelayComplete(
    size_t index,
    PerTabResultCode result_code) {
  ...
  tabs::TabInterface* tab = per_tab_state.tab_handle.Get();
  if (!tab) {
    per_tab_state.result_code = PerTabResultCode::kTabWentAway;
    per_url_completion_closure_.Run();
    return;
  }

  optimization_guide::GetAIPageContent(
      tab->GetContents(),
      optimization_guide::DefaultAIPageContentOptions(
          /*on_critical_path=*/true),
      base::BindOnce(&LoadAndExtractContentTool::OnGotAIPageContent,
                     weak_ptr_factory_.GetWeakPtr(), index));
}
```

**Apply to Phase 18:**

- Let `PrometheusAgentService` own authority and call `PrometheusPageAdapter` only after validation.
- Adapter should accept already-resolved browser/tab context and return an `AgentRouteResult`.
- Adapter should bound result payloads deterministically and include truncation/omission metadata.
- Do not put page text into browser logs, audit records, WebUI URLs, or crash strings.

### `prometheus_page_snapshot.{h,cc}` (utility/transform, transform)

**Analog:** `components/optimization_guide/content/browser/page_content_proto_provider.*` and `page_content_proto_util.*`

**APC result shape** (`page_content_proto_provider.h` lines 103-132):

```cpp
struct AIPageContentResult {
  optimization_guide::proto::AnnotatedPageContent proto;
  blink::mojom::PageMetadataPtr metadata;
  base::flat_map<std::string, content::WeakDocumentPtr> document_identifiers;
  std::vector<gfx::Rect> visible_bounding_boxes_for_redaction;
};

using AIPageContentResultOrError =
    base::expected<AIPageContentResult, std::string>;
using OnAIPageContentDone =
    base::OnceCallback<void(AIPageContentResultOrError)>;
void GetAIPageContent(content::WebContents* web_contents,
                      blink::mojom::AIPageContentOptionsPtr options,
                      OnAIPageContentDone done_callback);
```

**Actionable snapshot option** (`page_content_proto_provider.cc` lines 563-568):

```cpp
blink::mojom::AIPageContentOptionsPtr ActionableAIPageContentOptions(
    bool on_critical_path) {
  auto options = blink::mojom::AIPageContentOptions::New();
  options->mode = blink::mojom::AIPageContentMode::kActionableElements;
  options->on_critical_path = on_critical_path;
  return options;
}
```

**Main-frame liveness and frame iteration** (`page_content_proto_provider.cc` lines 571-668):

```cpp
void GetAIPageContent(content::WebContents* web_contents,
                      blink::mojom::AIPageContentOptionsPtr options,
                      OnAIPageContentDone done_callback) {
  DCHECK(web_contents);
  DCHECK(web_contents->GetPrimaryMainFrame());

  if (!web_contents->GetPrimaryMainFrame()->IsRenderFrameLive()) {
    std::move(done_callback).Run(base::unexpected("Main frame not live"));
    return;
  }
  ...
  web_contents->GetPrimaryMainFrame()->ForEachRenderFrameHost(
      [&](content::RenderFrameHost* rfh) {
        if (!rfh->IsRenderFrameLive()) {
          return;
        }
        ...
        if (options->include_same_site_only &&
            (!net::SchemefulSite::IsSameSite(top_level_origin, frame_origin) ||
             rfh->IsFencedFrameRoot())) {
          (*timeout_helper->raw_page_content_map())[frame_token] =
              blink::mojom::RedactedFrameMetadata::New(
                  blink::mojom::RedactedFrameMetadata_Reason::kCrossSite);
          return;
        }
        ...
        rfh->GetRemoteInterfaces()->GetInterface(
            agent.BindNewPipeAndPassReceiver());
        agent_ptr->GetAIPageContent(...);
      });
```

**Node/ref lookup analog** (`page_content_proto_util.h` lines 137-173):

```cpp
std::optional<optimization_guide::TargetNodeInfo> FindNodeAtPoint(
    const optimization_guide::proto::AnnotatedPageContent&
        annotated_page_content,
    const gfx::Point& coordinate);

std::optional<optimization_guide::TargetNodeInfo> FindNodeWithID(
    const optimization_guide::proto::AnnotatedPageContent&
        annotated_page_content,
    const std::string_view document_identifier,
    const int dom_node_id);

content::RenderFrameHost* GetRenderFrameForDocumentIdentifier(
    content::WebContents& web_contents,
    std::string_view target_document_token);
```

**Implementation ref pattern** (`page_content_proto_util.cc` lines 1859-1914):

```cpp
std::optional<TargetNodeInfo> FindNodeWithID(
    const proto::AnnotatedPageContent& annotated_page_content,
    const std::string_view document_identifier,
    const int content_node_id) {
  ...
  return FindNodeWithIDRecursive(annotated_page_content.root_node(),
                                 main_frame_doc_id, document_identifier,
                                 content_node_id);
}

content::RenderFrameHost* GetRenderFrameForDocumentIdentifier(
    content::WebContents& web_contents,
    std::string_view target_document_token) {
  content::RenderFrameHost* render_frame = nullptr;
  web_contents.ForEachRenderFrameHostWithAction(
      [&target_document_token, &render_frame](content::RenderFrameHost* rfh) {
        if (!rfh->IsActive()) {
          return content::RenderFrameHost::FrameIterationAction::kSkipChildren;
        }
        auto* user_data =
            DocumentIdentifierUserData::GetForCurrentDocument(rfh);
        if (user_data &&
            user_data->serialized_token() == target_document_token) {
          render_frame = rfh;
          return content::RenderFrameHost::FrameIterationAction::kStop;
        }
        return content::RenderFrameHost::FrameIterationAction::kContinue;
      });
  return render_frame;
}
```

**Apply to Phase 18:**

- Element refs should be per-snapshot and include at minimum document token plus DOM node id, with optional snapshot id/schema version.
- Full snapshot should be a bounded transform from APC. Compact snapshot should filter to actionable/form/navigation-visible nodes and report omitted counts.
- Treat APC content as renderer-supplied/untrusted; use browser identity primitives for authority.

### `prometheus_page_action.{h,cc}` (service/utility, request-response + event-driven)

**Analog:** `chrome/browser/actor/tools/page_tool.*` and action request classes.

**Action request analogs:**

- Click: `click_tool_request.h` lines 17-49
- Type: `type_tool_request.h` lines 17-60
- Hover/move: `move_mouse_tool_request.h` lines 17-33
- Select: `select_tool_request.h` lines 18-41
- Scroll: `scroll_tool_request.h` lines 17-45 and `scroll_to_tool_request.h` lines 17-33
- Drag: `drag_and_release_tool_request.h` lines 17-42

**Renderer page tool pattern** (`page_tool.h` lines 32-47, 97-103):

```cpp
// A page tool is any tool implemented in the renderer by ToolExecutor. This
// class is shared by multiple tools and serves to implement the mojo shuttling
// of the request to the renderer.
class PageTool : public Tool {
 public:
  void Validate(ToolCallback callback) override;
  mojom::ActionResultPtr TimeOfUseValidation(
      const optimization_guide::proto::AnnotatedPageContent* last_observation)
      override;
  void Invoke(ToolCallback callback) override;
  ...
 private:
  content::WeakDocumentPtr target_document_;
  mojom::ObservedToolTargetPtr observed_target_;
```

**Time-of-use validation pattern** (`page_tool.cc` lines 374-425):

```cpp
mojom::ActionResultPtr PageTool::TimeOfUseValidation(
    const AnnotatedPageContent* last_observation) {
  TabInterface* tab = request_->GetTabHandle().Get();
  if (!tab) {
    return MakeResult(mojom::ActionResultCode::kTabWentAway);
  }

  RenderFrameHost* frame =
      FindTargetLocalRootFrame(request_->GetTabHandle(), request_->GetTarget());
  if (!frame) {
    return MakeResult(mojom::ActionResultCode::kFrameWentAway);
  }
  ...
  mojom::ActionResultPtr observation_result =
      ComputeObservedTargetAndValidateFrame(last_observation, frame);
  if (!IsOk(*observation_result)) {
    return observation_result;
  }

  has_completed_time_of_use_ = true;
  target_document_ = frame->GetWeakDocumentPtr();
  return MakeOkResult();
}
```

**Renderer invocation and navigation race pattern** (`page_tool.cc` lines 540-603):

```cpp
void PageTool::Invoke(ToolCallback callback) {
  CHECK(GetFrame());
  RenderFrameHost& frame = *GetFrame();
  invoke_callback_ = std::move(callback);

  frame.GetRemoteAssociatedInterfaces()->GetInterface(&chrome_render_frame_);

  frame_change_observer_ = std::make_unique<RenderFrameChangeObserver>(
      frame,
      base::BindOnce(&PageTool::OnRenderFrameHostChanged,
                     weak_ptr_factory_.GetWeakPtr()),
      base::BindOnce(&PageTool::OnRenderFrameGone,
                     weak_ptr_factory_.GetWeakPtr()));

  timeout_timer_.Start(
      FROM_HERE, features::kGlicActorPageToolTimeout.Get(),
      base::BindOnce(&PageTool::OnTimeout, weak_ptr_factory_.GetWeakPtr()));

  auto invocation = CreateToolInvocation(frame);
  chrome_render_frame_->InvokeTool(
      std::move(invocation), base::BindOnce(&PageTool::FinishInvoke,
                                            weak_ptr_factory_.GetWeakPtr()));
}
```

**Coordinate/OOPIF pattern** (`page_tool.cc` lines 514-529):

```cpp
// If that frame is in a different widget (e.g. an OOPIF), we must transform
// the root DIP point into that frame's view coordinate space.
if (std::holds_alternative<gfx::Point>(request_->GetTarget())) {
  PageTarget transformed_target =
      gfx::ToRoundedPoint(frame.GetView()->TransformRootPointToViewCoordSpace(
          gfx::PointF(std::get<gfx::Point>(request_->GetTarget()))));
  invocation->target = ToMojo(transformed_target);
} else {
  invocation->target = ToMojo(request_->GetTarget());
}
```

**Apply to Phase 18:**

- Prefer DOM/document refs over blind coordinates.
- Re-resolve refs at action time from current snapshot/APC and fail typed stale-target if not found.
- Action outputs should be compact change reports, not full page dumps.
- `drop_file` has no direct safe analog in inspected actor tools; start with typed denial unless a browser-approved file policy is chosen.

### `prometheus_page_waiter.{h,cc}` (utility/service, event-driven wait)

**Analogs:** `PageSettledMonitor` and actor `ObservationDelayController`.

**Page settled definition** (`page_settled_monitor.h` lines 32-44, 85-91, 135-141):

```cpp
// Observes a WebContents and determines when the page has "settled".
// A page is considered settled when:
// 1. It has reached "stability" (network and main thread idle, plus optional
//    paint stability).
// 2. Loading has finished (if it was loading).
// 3. A visual state update has occurred.
// 4. (Optional) An LCP has been detected or a timeout has passed.
class PageSettledMonitor : public content::WebContentsObserver {
 public:
  struct PageStabilityConfig {
    bool supports_paint_stability = false;
    base::TimeDelta start_delay;
  };
  PageSettledMonitor(content::RenderFrameHost* target_frame,
                     std::unique_ptr<Delegate> delegate);
  void Wait(content::WebContents* web_contents, ReadyCallback callback);
```

**Actor wrapper pattern** (`observation_delay_controller.cc` lines 147-170, 190-210):

```cpp
ObservationDelayController::ObservationDelayController(
    content::RenderFrameHost& target_frame,
    TaskId task_id,
    AggregatedJournal& journal,
    PageStabilityConfig page_stability_config)
    : content::WebContentsObserver(
          WebContents::FromRenderFrameHost(&target_frame)),
      journal_(journal),
      task_id_(task_id) {
  CHECK(web_contents());
  page_settled_monitor_ =
      std::make_unique<page_content_annotations::PageSettledMonitor>(
          &target_frame, std::make_unique<PageSettledMonitorDelegate>(
                             *this, task_id, std::move(page_stability_config)));
}

void ObservationDelayController::Wait(tabs::TabInterface& target_tab,
                                      ReadyCallback callback) {
  CHECK_EQ(state_, State::kInitial);
  ready_callback_ = std::move(callback);
  WebContents* web_contents = target_tab.GetContents();
  WebContentsObserver::Observe(web_contents);
  page_settled_monitor_->Wait(
      web_contents, base::BindOnce(&ObservationDelayController::OnPageSettled,
                                   weak_ptr_factory_.GetWeakPtr()));
}
```

**Navigation restart pattern** (`load_and_extract_content_tool.cc` lines 227-250):

```cpp
void LoadAndExtractContentTool::TabObservationDelayer::
    OnObservationDelayComplete(ObservationDelayController::Result result) {
  switch (result) {
    case ObservationDelayController::Result::kOk:
      std::move(callback_).Run(PerTabResultCode::kOk);
      return;
    case ObservationDelayController::Result::kPageNavigated: {
      if (tabs::TabInterface* tab =
              tabs::TabInterface::GetFromContents(web_contents())) {
        size_t last_navigation_count =
            observation_delay_controller_->NavigationCount();
        observation_delay_controller_ =
            std::make_unique<ObservationDelayController>(
                *tab->GetContents()->GetPrimaryMainFrame(), task_id_, journal_,
                page_stability_config_);
        observation_delay_controller_->SetNavigationCount(
            last_navigation_count + 1);
        observation_delay_controller_->Wait(*tab, ...);
```

**Apply to Phase 18:**

- Wait after mutating actions for load/stability/visual/value/focus/scroll outcomes.
- Return explicit timeout or no-verified-change instead of retrying indefinitely.
- Keep wait state and action fingerprints by session/tab/action, not by raw pointers.

### Renderer Mojo seam (`chrome_render_frame.mojom` or new Prometheus mojom)

**Analog:** actor methods in `chrome/common/chrome_render_frame.mojom`.

**Existing actor renderer IPC pattern** (`chrome_render_frame.mojom` lines 102-136):

```mojom
// Creates and validates the tool based on the request.
InitializeTool(actor.mojom.ToolInvocation request)
    => (actor.mojom.InitializeToolResult result);

// Requires InitializeTool to be called first.
// Performs a second validation check to ensure the tool's target is still
// valid, then executes the tool.
ExecuteTool(actor.mojom.TaskId task_id)
    => (actor.mojom.ActionResult result);

// Requests invoking of a tool from the actor automation framework.
InvokeTool(actor.mojom.ToolInvocation request)
    => (actor.mojom.ActionResult result);

CancelTool(actor.mojom.TaskId task_id);
```

**Script/navigation result pattern** (`chrome_render_frame.mojom` lines 138-155):

```mojom
// ScriptTool executed on a Document using InvokeTool can result in a
// same-origin cross-document navigation such that the tool result is
// available on the new Document.
GetCrossDocumentScriptToolResult(
    mojo_base.mojom.UnguessableToken execution_id) => (string result);
```

**Normal-page JS anti-pattern source** (`render_frame_host.h` lines 581-599):

```cpp
// This is the default API to run JavaScript in this frame. This API can only
// be called on chrome:// or devtools:// URLs.
virtual void ExecuteJavaScript(const std::u16string& javascript,
                               JavaScriptResultCallback callback) = 0;

// This runs the JavaScript, but without restrictions. ... THIS IS
// ONLY FOR TESTS.
virtual void ExecuteJavaScriptForTests(const std::u16string& javascript,
                                       JavaScriptResultCallback callback,
                                       int32_t world_id) = 0;
```

**Apply to Phase 18:**

- Do not implement normal-page `execute_js` with production `RenderFrameHost::ExecuteJavaScript`.
- Either add a Prometheus-specific renderer interface or justify direct actor tool reuse after checking actor/Glic feature layering.
- Keep JS route explicit, permissioned, bounded, and audited as metadata only.

### Unit tests (`prometheus_page_adapter_unittest.cc`, `prometheus_page_snapshot_unittest.cc`)

**Analogs:** `prometheus_agent_route_unittest.cc`, `prometheus_agent_audit_unittest.cc`, `prometheus_agent_tab_data_unittest.cc`.

**Route test style** (`prometheus_agent_route_unittest.cc` lines 16-35, 71-90):

```cpp
TEST(PrometheusAgentRouteTest, ParsesKnownRouteStrings) {
  EXPECT_EQ(AgentRouteName::kListTabs,
            *AgentRouteNameFromString("list_tabs"));
  EXPECT_EQ(AgentRouteName::kNavigate, *AgentRouteNameFromString("navigate"));
}

TEST(PrometheusAgentRouteTest, RejectsUnknownRouteStrings) {
  EXPECT_EQ(std::nullopt, AgentRouteNameFromString("read_dom"));
  EXPECT_EQ(std::nullopt, AgentRouteNameFromString("click"));
}

TEST(PrometheusAgentRouteTest, FailureResultCarriesStableErrorAndRecovery) {
  AgentRouteResult result = AgentRouteResult::Failure(
      AgentErrorCode::kTabNotOwned, "Tab owned by another session",
      "Switch sessions or choose an unowned tab");
  EXPECT_FALSE(result.ok);
  EXPECT_EQ(AgentErrorCode::kTabNotOwned, result.error_code);
}
```

**Mock tab/user-data style** (`prometheus_agent_tab_data_unittest.cc` lines 20-40, 43-57):

```cpp
class PrometheusAgentTabDataTest : public testing::Test {
 protected:
  void SetUp() override {
    ON_CALL(tab_, GetUnownedUserDataHost()).WillByDefault(ReturnRef(host_));
  }

  ui::UnownedUserDataHost host_;
  tabs::MockTabInterface tab_;
};

TEST_F(PrometheusAgentTabDataTest, UnownedTabCanBeClaimedAndControlled) {
  std::unique_ptr<PrometheusAgentTabData> data =
      PrometheusAgentTabData::ForTabForTesting(&tab_);
  AgentRouteResult claim = data->ClaimIfUnowned("session-a", "Agent A");
  EXPECT_TRUE(claim.ok);
}
```

**Apply to Phase 18 unit tests:**

- Pure route/schema tests: parse new route strings and reject old unsupported placeholders.
- Snapshot tests: truncation, omitted counts, ref encoding/decoding, selector bounds, compact filtering.
- Error tests: typed mapping for stale frame, restricted frame, invalid ref, unsupported action, permission blocked.
- Action-history tests: repeated/stuck fingerprint detection without page content in the fingerprint string.
- Audit tests: page payloads are absent from audit changed-state.

### Browser tests and fixtures

**Analog:** `prometheus_agent_service_browsertest.cc` plus actor action browser tests.

**Prometheus browser-test fixture style** (`prometheus_agent_service_browsertest.cc` lines 5-33, 75-115):

```cpp
#include "chrome/browser/prometheus/prometheus_agent_service.h"
#include "base/test/run_until.h"
#include "chrome/browser/prometheus/prometheus_agent_audit.h"
#include "chrome/browser/prometheus/prometheus_agent_tab_data.h"
#include "chrome/test/base/in_process_browser_test.h"
#include "content/public/test/browser_test.h"
#include "content/public/test/browser_test_utils.h"
#include "content/public/test/test_navigation_observer.h"

class PrometheusAgentServiceBrowserTest : public InProcessBrowserTest {
 public:
  std::string CreateSession(const std::string& display_label) {
    AgentSessionResult result = service_.CreateSession(display_label);
    EXPECT_TRUE(result.route_result.ok) << result.route_result.message;
    return result.session->id;
  }

  AgentRouteRequest Request(AgentRouteName route_name,
                            std::string_view session_id) {
    AgentRouteRequest request;
    request.route_name = route_name;
    request.session_id = std::string(session_id);
    return request;
  }

  AgentRouteResult Execute(const AgentRouteRequest& request) {
    return service_.ExecuteRoute(browser(), request);
  }
```

**Navigation observer pattern** (`prometheus_agent_service_browsertest.cc` lines 289-313):

```cpp
ASSERT_TRUE(embedded_test_server()->Start());
const GURL url1 = embedded_test_server()->GetURL("/title1.html");
...
content::TestNavigationObserver navigate1_observer(target_tab->GetContents());
AgentRouteResult navigate1_result = Execute(navigate1);
ASSERT_TRUE(navigate1_result.ok) << navigate1_result.message;
EXPECT_TRUE(HasChangedState(navigate1_result, "navigation_started"));
navigate1_observer.Wait();
EXPECT_EQ(url1, target_tab->GetContents()->GetLastCommittedURL());
```

**Audit-safe page route test pattern** (`prometheus_agent_service_browsertest.cc` lines 501-522):

```cpp
AgentRouteResult result =
    Execute(Request(AgentRouteName::kUnsupportedPageAction, session_id));
EXPECT_FALSE(result.ok);
EXPECT_EQ(AgentErrorCode::kUnsupportedRoute, result.error_code);

const std::vector<AgentRouteAuditRecord> records =
    service().audit_log_for_testing().GetRecentRecordsForTesting();
const AgentRouteAuditRecord& record = records.back();
EXPECT_TRUE(IsAgentRouteAuditRecordSafe(record));
EXPECT_FALSE(IsAgentRouteAuditMetadataSafe("page_text"));
```

**Actor action browser-test style** (`click_tool_browsertest.cc` lines 94-138):

```cpp
const GURL url =
    embedded_test_server()->GetURL("/actor/page_with_clickable_element.html");
ASSERT_TRUE(content::NavigateToURL(web_contents(), url));

std::optional<int> button_id =
    GetDOMNodeId(*main_frame(), "button#clickable");
ASSERT_TRUE(button_id);

std::unique_ptr<ToolRequest> action =
    MakeClickRequest(*main_frame(), button_id.value());
ActResultFuture result;
actor_task().Act(ToRequestList(action), result.GetCallback());
ExpectOkResult(result);
EXPECT_EQ(true, EvalJs(web_contents(), "button_clicked"));
```

**Fixture analog:** `chrome/test/data/actor/page_with_clickable_element.html` includes actionable buttons, disabled controls, offscreen elements, checkbox labels, and event logs. `chrome/test/data/actor/script_tool.html` provides script-tool success behavior.

**Apply to Phase 18 browser tests:**

- Put Phase 18 fixtures under `chrome/test/data/prometheus/page_adapter/`.
- Use `embedded_test_server()` for normal fixtures and `embedded_https_test_server()` or host resolver rules for cross-origin/OOPIF denial cases.
- Use `content::EvalJs`, `GetDOMNodeId`, `WaitForLoadStop`, and navigation observers in tests only.
- Keep tests route-level: create browser-issued session, claim/open target tab, execute Phase 18 route, assert route payload, changed-state constants, audit safety, and page result.

### GN wiring

**Unit source-set pattern** (`chrome/browser/prometheus/BUILD.gn` lines 128-149, 152-199):

```gn
source_set("prometheus_agent_service") {
  sources = [
    "prometheus_agent_service.cc",
    "prometheus_agent_service.h",
  ]

  deps = [
    ":prometheus_agent_audit",
    ":prometheus_agent_route",
    ":prometheus_agent_session",
    ":prometheus_agent_tab_data",
    "//content/public/browser",
    "//url",
  ]
}

test("prometheus_unittests") {
  sources = [
    "prometheus_action_unittest.cc",
    "prometheus_agent_audit_unittest.cc",
    ...
  ]
  deps = [
    ":prometheus_agent_route",
    ":prometheus_agent_service",
    "//content/test:run_all_unittests",
    "//testing/gtest",
  ]
}
```

**Browser-test registration pattern** (`chrome/browser/ui/views/prometheus/BUILD.gn` lines 52-88):

```gn
source_set("browser_tests") {
  testonly = true
  defines = [ "HAS_OUT_OF_PROC_TEST_RUNNER" ]
  sources = [
    "../../../prometheus/prometheus_agent_service_browsertest.cc",
    ...
  ]

  deps = [
    "//base/test:test_support",
    "//chrome/browser/prometheus:prometheus_agent_route",
    "//chrome/browser/prometheus:prometheus_agent_service",
    "//chrome/test:test_support",
    "//content/public/browser",
    "//content/test:test_support",
    "//url",
  ]
}
```

**Chrome test target already pulls the Prometheus browser-test source set** (`chrome/test/BUILD.gn` lines 2687-2689):

```gn
# Pulls prometheus_token_gallery_browsertest.cc from the Chrome-owned
# Prometheus gallery target.
"//chrome/browser/ui/views/prometheus:browser_tests",
```

**Apply to Phase 18:**

- Add a `source_set("prometheus_page_adapter")` under `chrome/browser/prometheus/BUILD.gn`.
- Add dependencies for `//content/public/browser`, `//components/content_extraction/content/browser`, `//components/optimization_guide/content/browser`, `//components/page_content_annotations/content/browser`, `//components/tabs:public`, `//url`, and any Mojo target chosen for renderer IPC.
- Add unit test sources to `prometheus_unittests`.
- Add browser test source to `chrome/browser/ui/views/prometheus/BUILD.gn`; `chrome/test/BUILD.gn` likely needs no Phase 18 edit because it already includes that source set.

## Shared Patterns

### Session And Ownership

**Source:** `prometheus_agent_session.cc` lines 53-84 and `prometheus_agent_tab_data.cc` lines 59-73, 110-114.
**Apply to:** All page routes.

```cpp
AgentSessionResult AgentSessionRegistry::CreateSession(
    std::string display_label,
    base::Time now) {
  ...
  session.id = base::UnguessableToken::Create().ToString();
  session.display_label = SanitizeDisplayLabel(display_label);
  session.active = true;
  ...
}

AgentRouteResult PrometheusAgentTabData::ClaimIfUnowned(
    std::string_view session_id,
    std::string owner_label) {
  if (session_id.empty()) {
    return AgentRouteResult::Failure(
        AgentErrorCode::kUnauthorized, "Missing agent session",
        "Create a browser-issued agent session before claiming a tab");
  }
  if (HasOwner() && owner_session_id_ != session_id) {
    return TabNotOwnedFailure();
  }
  owner_session_id_ = std::string(session_id);
  return AgentRouteResult::Success({"tab_claimed"});
}
```

### Frame Identity And Lifetime

**Source:** `content/public/browser/web_contents.h` lines 504-509, 555-578; `render_frame_host.h` lines 262-270, 663-666, 761-776, 1108-1112.
**Apply to:** Frame target resolution, snapshots, JS, and actions.

```cpp
// Returns the primary main frame for the currently active page.
virtual RenderFrameHost* GetPrimaryMainFrame() = 0;

// NOTE: This is generally unsafe to use. A frame's RenderFrameHost may
// change over its lifetime, such as during cross-process navigation (and
// thus privilege change).
virtual RenderFrameHost* UnsafeFindFrameByFrameTreeNodeId(
    FrameTreeNodeId frame_tree_node_id) = 0;

// Returns whether the RenderFrame in the renderer process has been created
// and still has a connection.
virtual bool IsRenderFrameLive() = 0;

// Returns true if the document hosted in this RenderFrameHost is committed
// and lives inside a page presented to the user.
virtual bool IsActive() const = 0;

virtual WeakDocumentPtr GetWeakDocumentPtr() = 0;
```

### Snapshot Refs

**Source:** `page_content_proto_provider.h` lines 43-63 and `page_content_proto_util.cc` lines 1895-1914.
**Apply to:** `PrometheusPageRef`, snapshot result schema, action re-resolution.

```cpp
class DocumentIdentifierUserData
    : public content::DocumentUserData<DocumentIdentifierUserData> {
 public:
  const base::UnguessableToken& token() const { return token_; }
  std::string serialized_token() const { return serialized_token_; }
};
```

Use document token + DOM node id as the base ref. Do not promise refs survive navigation, process swaps, frame detach, or DOM replacement.

### Content-Free Audit

**Source:** `prometheus_agent_service.cc` lines 591-613; `prometheus_agent_audit.cc` lines 17-19, 40-64.
**Apply to:** All routes, especially `read_page`, snapshots, `execute_js`, `type_text`, and file/drop routes.

Safe changed-state examples: `visible_text_returned`, `snapshot_returned`, `compact_snapshot_returned`, `js_executed`, `element_clicked`, `text_typed`, `key_pressed`, `scrolled`, `hovered`, `option_selected`, `input_cleared`, `drag_completed`, `file_drop_denied`, `verification_timeout`, `stuck_action_detected`.

Unsafe changed-state examples: selector strings, page snippets, typed text, JS source, JS result, file paths, raw URLs, prompt text, secrets, vault values, provider keys.

### Test-Only APIs Stay In Tests

**Source:** `render_frame_host.h` lines 581-599; `prometheus_agent_service_browsertest.cc` lines 24-30; actor browser tests.
**Apply to:** Production adapter vs browser tests.

- Production code must not include `content/public/test/browser_test_utils.h`.
- Browser tests may use `content::EvalJs`, `content::ExecJs`, `content::GetDOMNodeId`, `content::NavigateToURL`, `content::WaitForLoadStop`, and `content::TestNavigationObserver`.

## Risky Anti-Patterns To Avoid

| Anti-pattern | Why It Is Risky | Evidence |
|--------------|-----------------|----------|
| Calling `RenderFrameHost::ExecuteJavaScript` on HTTP/HTTPS pages in production | Header restricts it to `chrome://` or `devtools://`; unrestricted variants are test-only | `content/public/browser/render_frame_host.h` lines 581-599 |
| Storing raw `RenderFrameHost*` or raw `WebContents*` across actions | Navigation, BFCache, prerender, deletion, and privilege changes invalidate assumptions | `web_contents.h` lines 399-419, 555-578; `render_frame_host.h` lines 1108-1112 |
| Using `UnsafeFindFrameByFrameTreeNodeId` as authority | Chromium warns RFH may change during cross-process navigation and privilege changes | `web_contents.h` lines 555-563 |
| Traversing all `WebContents` frames for visible page state | Includes BFCache/prerender/pending deletion frames; primary page should start from primary main frame | `web_contents.h` lines 565-578 |
| Treating selectors/refs as durable or authoritative | Phase 18 requires per-snapshot/per-frame refs and time-of-use revalidation | `18-CONTEXT.md` D-07, D-17; `page_tool.cc` lines 374-425 |
| Writing page content, scripts, selectors, typed text, or file paths to audit | Existing audit persists `changed_state`; unsafe terms are explicitly rejected | `prometheus_agent_audit.cc` lines 17-19, 40-64 |
| Blind coordinate clicks without OOPIF/device-scale handling | Actor code has explicit widget/local-root transforms and scale conversion | `page_tool.cc` lines 514-529; `page_target_util.cc` lines 150-176 |
| Arbitrary `drop_file` from caller-supplied paths | Phase 18 forbids reading arbitrary local files from untrusted input; no safe local analog found | `18-CONTEXT.md` D-23; actor tools scan found no direct file-drop action analog |
| Directly depending on actor/Glic stack without a layering decision | Actor tools are a strong pattern, but tied to actor task/journal/features | `chrome/browser/actor/README.md` lines 1-55; actor source imports feature/task/journal classes |

## No Direct Analog Found

| File/Class | Role | Data Flow | Reason |
|------------|------|-----------|--------|
| `drop_file` route / `prometheus_page_drop_file_policy.*` | policy/utility | file-I/O | Actor tools have action analogs for click/type/scroll/select/hover/drag, but no inspected safe route for arbitrary file drop. First implementation should return typed denial or require explicit browser-approved fixture/path policy. |
| `press_key` route | action utility | event-driven | Actor `TypeToolRequest` covers text typing and Enter-after-typing, but no direct generic key press request class was found. Implement separately with tests or return typed unsupported for unsafe keys. |
| `clear` route | action utility | request-response | Actor `TypeToolRequest::Mode::kReplace` can replace text, but a dedicated clear-input route needs its own validation/read-back tests. |

## Metadata

**Analog search scope:** `.context/chromium/src/chrome/browser/prometheus/`, `.context/chromium/src/chrome/browser/ui/views/prometheus/`, `.context/chromium/src/chrome/browser/actor/tools/`, `chrome/test/data/actor/`, `components/content_extraction/content/browser/inner_text.h`, `components/optimization_guide/content/browser/page_content_proto_provider.*`, `components/optimization_guide/content/browser/page_content_proto_util.*`, `components/page_content_annotations/content/browser/page_settled_monitor.h`, `content/public/browser/web_contents.h`, `content/public/browser/render_frame_host.h`, and `chrome/common/chrome_render_frame.mojom`.

**Files scanned:** Prometheus and Views source lists, actor tools source list, actor fixture list, and targeted line reads from the source files cited above.

**Pattern extraction date:** 2026-07-07

**Planner guidance:** Keep Phase 18 under `chrome/browser/prometheus/` for browser-process service/schema logic; use `chrome/browser/ui/views/prometheus/BUILD.gn` only for browser-test inclusion; update `ROADMAP.md` only through the normal Phase 18 progress workflow.
