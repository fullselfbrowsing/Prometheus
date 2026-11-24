# Phase 21: Supervision, Pairing, and Remote Control - Pattern Map

**Mapped:** 2026-07-21  
**Scope:** locked context and verified local research  
**Pattern families:** 5  
**File groups classified:** 34  
**Strong or partial analog coverage:** 32 / 34

This map is intentionally narrow. It assigns likely Phase 21 files to five
live Chromium/Prometheus patterns and records the two places where no live
implementation exists. Chromium paths are relative to
<code>.context/chromium/src/</code> unless otherwise noted.

## File Classification

| New/modified file or group | Role | Data flow | Closest live analog | Match |
|---|---|---|---|---|
| chrome/browser/prometheus/prometheus_supervision_types.{h,cc} | model | request-response + stream stamps | chrome/browser/prometheus/prometheus_agent_route.{h,cc} | role |
| chrome/browser/prometheus/prometheus_supervision_transport_codec.{h,cc} | codec | bounded request-response | chrome/browser/prometheus/prometheus_agent_transport_codec.{h,cc} | exact |
| chrome/browser/prometheus/prometheus_supervision_gateway_delegate.{h,cc}, or equivalent narrow interface | provider/delegate | request-response | chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.{h,cc} | role |
| chrome/browser/prometheus/prometheus_supervision_profile_service.{h,cc} | KeyedService | CRUD + lifecycle + streaming authority | chrome/browser/prometheus/prometheus_agent_profile_service.{h,cc} | exact |
| chrome/browser/prometheus/prometheus_supervision_profile_service_factory.{h,cc} | factory | profile-scoped construction | chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc | exact |
| chrome/browser/prometheus/prometheus_supervision_stream.{h,cc} | browser observer/service | event-driven streaming | components/optimization_guide/content/browser/page_content_metadata_observer.{h,cc} | role |
| chrome/browser/prometheus/prometheus_supervision_projection.{h,cc} | transform | APC to bounded safe tree | chrome/browser/prometheus/prometheus_page_snapshot.{h,cc} | role, with privacy override |
| chrome/browser/prometheus/prometheus_supervision_diff.{h,cc}, if split | transform/model | diff + ack + resync | none | new |
| chrome/common/prometheus_supervision.mojom, or prometheus_render_frame.mojom | IPC schema | associated pub-sub | chrome/common/prometheus_render_frame.mojom | role |
| chrome/renderer/prometheus_supervision_document_observer.{h,cc}, or prometheus_render_frame_observer.{h,cc} | renderer document observer | dirty/overflow events | Blink frame_metadata_observer_registry plus Prometheus render-frame observer | role |
| chrome/browser/prometheus/prometheus_agent_gateway.{h,cc} | gateway | authenticated request-response + bounded long poll | same file | exact modification |
| chrome/browser/prometheus/prometheus_agent_gateway_contract.cc | middleware/guard | HTTP validation | same file | exact modification |
| chrome/browser/prometheus/prometheus_agent_route.{h,cc} | route/model | closed enum conversion | same file | exact modification |
| chrome/browser/prometheus/prometheus_agent_transport_codec.{h,cc} | codec | MCP compatibility transport | same file | exact modification |
| chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc | composition root | dependency/factory wiring | same file | exact modification |
| chrome/browser/prometheus/prometheus_agent_tab_data.{h,cc} | tab-owned model | event-driven state | same file | exact modification |
| chrome/browser/prometheus/prometheus_tab_state.{h,cc} | sanitized DTO | browser-to-chrome projection | same file | exact modification |
| chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.{h,cc} | narrow UI provider | exact-target request-response + observer | same file | exact modification |
| chrome/browser/ui/webui/prometheus/prometheus_web_ui.{h,cc} | controller | WebUI request-response + observer push | same file | exact modification |
| chrome/browser/resources/prometheus/prometheus_control_panel.html | view | event-driven lifecycle UI | same file | exact modification |
| chrome/browser/resources/prometheus/prometheus_side_panel.html | view | selected-tab status/stop UI | same file | exact modification |
| chrome/browser/resources/prometheus/prometheus_webui.js | controller/component | WebUI message/render loop | same file | exact modification |
| chrome/browser/resources/prometheus/prometheus_webui.css | component/theme | visual state | same file | exact modification |
| chrome/browser/resources/prometheus/prometheus_resources.grdp and BUILD.gn | config | packaged file I/O | same files | exact modification |
| chrome/browser/ui/views/tabs/prometheus_tab_status_badge.{h,cc} | native component | state-to-view transform | same file | exact modification |
| chrome/browser/ui/views/tabs/tab.{h,cc} | native component/controller | observer-driven layout | TabIcon and AlertIndicatorButton in same files | partial |
| Prometheus/common/renderer/UI GN manifests | config | build graph | existing Prometheus source sets and test targets | exact |
| prometheus_supervision_*_unittest.cc and renderer/gateway tests | test | batch/unit | Agent transport and profile-service tests | role |
| chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc | browser/UI test | event-driven integration | same file | exact modification |
| real tab-strip Prometheus badge browser/view test | browser/view test | layout/accessibility | existing Tab tests; no badge integration test | partial |
| tools/prometheus-mcp/src/catalog.mjs | catalog/config | batch transform | Phase 20 promotion in same file | exact |
| tools/prometheus-mcp/src/tool-handler.mjs and diagnostics tests | middleware/controller | validated request-response | same file | exact modification |
| tools/prometheus-mcp/test/catalog.test.mjs, tools.test.mjs, native-client.test.mjs, smoke-client.mjs | test | batch + two-client integration | Phase 20 tests | exact |
| .planning/chromium/verify-phase-21.sh | verification config | batch/build/test/smoke | .planning/chromium/verify-phase-20.sh | exact |

## Pattern Family 1: Regular-Profile Authority and KeyedService Lifecycle

**Apply to:** supervision service/factory/types, Agent-session-loss observation,
and startup composition.

### Regular-profile factory and dependency direction

**Analog:** chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc
lines 15-36 and 59-72.

~~~cpp
PrometheusRuntimeProfileService*
PrometheusRuntimeProfileServiceFactory::GetForProfile(Profile* profile) {
  if (!profile || profile->IsOffTheRecord()) {
    return nullptr;
  }
  return static_cast<PrometheusRuntimeProfileService*>(
      GetInstance()->GetServiceForBrowserContext(profile, /*create=*/true));
}

PrometheusRuntimeProfileServiceFactory::PrometheusRuntimeProfileServiceFactory(
    base::PassKey<PrometheusRuntimeProfileServiceFactory>)
    : ProfileKeyedServiceFactory("PrometheusRuntimeProfileService",
                                 ProfileSelections::BuildForRegularProfile()) {
  DependsOn(PrometheusAgentProfileServiceFactory::GetInstance());
}
~~~

~~~cpp
Profile* const profile = Profile::FromBrowserContext(context);
if (!profile || profile->IsOffTheRecord()) {
  return nullptr;
}
PrometheusAgentProfileService* const agent_profile_service =
    PrometheusAgentProfileServiceFactory::GetForProfile(profile);
if (!agent_profile_service) {
  return nullptr;
}
return std::make_unique<PrometheusRuntimeProfileService>(
    profile, agent_profile_service);
~~~

Copy this direction exactly: supervision depends on Agent authority; Agent does
not depend on supervision. Build only for regular profiles and return null for
OTR rather than redirecting to an original profile.

### Sweep at every public boundary; one idempotent terminal transition

**Analog:** prometheus_agent_profile_service.cc lines 29-50 and 171-207.

~~~cpp
PrometheusAgentProfileService::PrometheusAgentProfileService(Profile* profile)
    : profile_(profile),
      sessions_(kDefaultMaxAgentSessions, kAgentReconnectGrace),
      now_callback_(base::BindRepeating(&base::Time::Now)) {
  CHECK(profile_);
  CHECK(!profile_->IsOffTheRecord());
}

AgentSessionResult PrometheusAgentProfileService::CreateSession(
    std::string display_label) {
  SweepExpiredSessions();
  return agent_service_.CreateSession(std::move(display_label));
}
~~~

~~~cpp
void PrometheusAgentProfileService::Shutdown() {
  if (shutdown_) {
    return;
  }
  shutdown_ = true;
  for (const std::string& session_id : sessions_.CloseAllSessions()) {
    agent_service_.ReleaseSessionOwnership(session_id);
    NotifySessionLost(session_id);
  }
  observers_.Clear();
}

void PrometheusAgentProfileService::SweepExpiredSessions() {
  for (const std::string& session_id : sessions_.ExpireSessions(Now())) {
    agent_service_.ReleaseSessionOwnership(session_id);
    NotifySessionLost(session_id);
  }
}
~~~

Use the checked-observer shape at prometheus_agent_profile_service.h:30-33,
but expose only sanitized state and terminal events. Pairing replacement,
redemption, expiry, revoke, owner loss, target close, Browser/profile loss, and
shutdown must funnel through one terminal method so each loss is observed once.

### Exact Browser guard before reusing Agent routes

**Analog:** prometheus_agent_profile_service.cc lines 117-129.

~~~cpp
if (!exact_browser || exact_browser->GetProfile() != profile_) {
  std::move(callback).Run(AgentRouteResult::Failure(
      AgentErrorCode::kInvalidTarget,
      "The local runtime target is not in this profile",
      "Return to the originating browser tab and retry"));
  return;
}
agent_service_.ExecuteRoute(exact_browser, request, std::move(callback));
~~~

This guard is necessary but not sufficient. Before dispatch and again in the
callback, supervision must compare the captured nonempty owner, stable tab,
controller lease, current epoch, and stream state. Current
PrometheusAgentTabData::CanControl accepts an unowned tab and ClaimIfUnowned
claims it (prometheus_agent_tab_data.cc:50-72); calling the dispatcher after
owner loss would silently reacquire authority.

### Composition root

**Analog:** prometheus_browser_main_extra_parts.cc lines 1297-1305.

~~~cpp
PrometheusAgentProfileServiceFactory::GetInstance();
PrometheusRuntimeProfileServiceFactory::GetInstance();
SetPrometheusSidePanelRuntimeFactory(
    base::BindRepeating(&CreateSidePanelRuntime));
SetPrometheusControlPanelRuntimeFactory(
    base::BindRepeating(&CreateControlPanelRuntime));
~~~

Initialize the supervision factory here and install only narrow gateway/UI
delegates. Lifecycle truth stays in the profile service.

## Pattern Family 2: Closed Codec and Authenticated Gateway Delegate

**Apply to:** supervision types/codec/delegate, gateway and contract changes,
five Agent/MCP routes, and transport tests.

### Preserve the existing HTTP perimeter

**Analog:** prometheus_agent_gateway_contract.cc lines 19-23 and 53-101.

~~~cpp
constexpr size_t kMaxRequestBytes = 1'048'576;
constexpr size_t kMaxInflightRequests = 16;
constexpr std::array<std::string_view, 6> kClosedPaths = {
    "/v1/session/create", "/v1/session/resume", "/v1/session/touch",
    "/v1/session/close",  "/v1/agent/command",  "/v1/health"};

bool HasValidBearer(std::string_view authorization, std::string_view bearer) {
  constexpr std::string_view kPrefix = "Bearer ";
  if (!authorization.starts_with(kPrefix)) {
    return false;
  }
  return crypto::SecureMemEqual(
      base::as_byte_span(authorization.substr(kPrefix.size())),
      base::as_byte_span(bearer));
}
~~~

~~~cpp
if (request.peer.address() != net::IPAddress::IPv4Localhost()) {
  return PrometheusAgentRequestRejection::kNonLoopbackPeer;
}
if (request.GetHeaderValue("host") != "127.0.0.1:" + std::to_string(port)) {
  return PrometheusAgentRequestRejection::kInvalidHost;
}
if (request.headers.contains("origin")) {
  return PrometheusAgentRequestRejection::kOriginForbidden;
}
~~~

Add only /v1/supervision. Preserve loopback, exact Host, Origin rejection,
constant-time bearer, POST JSON, 1 MiB body, 16 in-flight, timeout, WebSocket
rejection, and Cache-Control: no-store. Redemption requires both the descriptor
bearer and one-time code.

### Closed keys, bounded UTF-8, typed failures, bounded output

**Analog:** prometheus_agent_transport_codec.cc lines 27-88 and 636-779.

~~~cpp
bool HasOnlyKeys(const base::DictValue& value,
                 std::initializer_list<std::string_view> allowed) {
  for (const auto [key, ignored] : value) {
    static_cast<void>(ignored);
    if (std::find(allowed.begin(), allowed.end(), key) == allowed.end()) {
      return false;
    }
  }
  return true;
}

bool IsBoundedUtf8(const std::string& value,
                   size_t max_bytes,
                   bool allow_empty = true) {
  return (allow_empty || !value.empty()) && value.size() <= max_bytes &&
         base::IsStringUTF8(value);
}
~~~

~~~cpp
if (!HasOnlyKeys(*root,
                 {"route", "session_id", "target", "params", "visual"})) {
  return base::unexpected(InvalidRequest("Unknown top-level field"));
}
...
if (json->size() > kMaxOutputBytes) {
  return base::unexpected(RequestTooLarge("Serialized result exceeds 2 MiB"));
}
~~~

Give redeem, baseline, diff, ack, action, heartbeat, and end exact allowed-key
sets and a closed enum. Reject caller-selected profile, Browser, owner, tab
selector, controller, arbitrary route, and document authority. The browser
constructs any AgentRouteRequest internally from the captured owner and target.

### Thin gateway and cycle-breaking delegate

**Analog:** prometheus_agent_gateway.cc lines 1660-1705.

~~~cpp
auto request = ParseRuntimeTransportRequest(body);
if (!request.has_value()) {
  auto serialized = SerializeRuntimeTransportResult(request.error());
  std::move(callback).Run(net::HTTP_BAD_REQUEST, ...);
  return;
}
auto binding = session_bindings_.find(request->session_id);
const bool session_valid =
    binding != session_bindings_.end() && binding->second.profile;
RuntimeTransportResult result =
    DispatchAuthenticatedRuntimeRequestForTesting(
        *request, session_valid, caller_id, ...);
~~~

The dashboard table belongs in the supervision profile service, not gateway
session_bindings. The gateway holds only enough weak binding to call the exact
service on the UI sequence.

Use the factory-injection seam from prometheus_side_panel_runtime.cc:14-22 and
40-51 as the closest narrow-delegate pattern:

~~~cpp
PrometheusControlPanelRuntimeFactory& ControlRuntimeFactory() {
  static base::NoDestructor<PrometheusControlPanelRuntimeFactory> factory;
  return *factory;
}
...
return ControlRuntimeFactory().Run(exact_profile, exact_web_contents);
~~~

On shutdown follow prometheus_agent_gateway.cc:943-1002: invalidate weak
pointers before I/O stop, close authority, clear maps/trackers, delete only the
owned descriptor, and clear bearer material. Also cancel long polls and
invalidate all supervision generations before late callbacks can publish.

## Pattern Family 3: APC Projection plus Document-Lifetime Mojo Dirty Signals

**Apply to:** browser stream/projection/diff, Mojo, renderer document observer,
and privacy/stream/navigation tests.

The correct split is renderer dirty/overflow intent only; browser-owned epoch,
APC capture, privacy projection, normalized tree, sequence, queue, ack, resync.

### Browser observer across frame/document lifecycle

**Analog:** page_content_metadata_observer.cc lines 76-175.

~~~cpp
void PageContentMetadataObserver::RenderFrameCreated(
    content::RenderFrameHost* render_frame_host) {
  if (&render_frame_host->GetPage() != &web_contents()->GetPrimaryPage()) {
    return;
  }
  if (frame_data_.contains(render_frame_host) ||
      !render_frame_host->IsRenderFrameLive()) {
    return;
  }
  mojo::Remote<blink::mojom::FrameMetadataObserverRegistry> registry;
  render_frame_host->GetRemoteInterfaces()->GetInterface(
      registry.BindNewPipeAndPassReceiver());
}
~~~

~~~cpp
void PageContentMetadataObserver::PrimaryPageChanged(content::Page& page) {
  frame_data_.clear();
  UpdateFrameObservers();
  DispatchMetadata();
}
...
frame_data_.erase(render_frame_host);
RenderFrameCreated(render_frame_host);
~~~

Mirror primary-page filtering, live-frame checks, per-frame receiver ownership,
main-document reset, and subframe replacement. PrimaryPageChanged regenerates
the epoch, clears diffs, pauses actions, and requires a fresh acknowledged
baseline.

### Document supplement and associated Mojo

**Analog:** frame_metadata_observer_registry.h lines 34-69 and
frame_metadata_observer_registry.cc lines 138-186.

~~~cpp
class MODULES_EXPORT FrameMetadataObserverRegistry final
    : public GarbageCollected<FrameMetadataObserverRegistry>,
      public mojom::blink::FrameMetadataObserverRegistry,
      public Supplement<Document> {
 public:
  static FrameMetadataObserverRegistry* From(Document&);
  static void BindReceiver(LocalFrame* frame, ...);
  void Trace(Visitor* visitor) const override;
};
~~~

~~~cpp
auto& document = *frame->GetDocument();
auto* registry = FrameMetadataObserverRegistry::From(document);
if (!registry) {
  registry = MakeGarbageCollected<FrameMetadataObserverRegistry>(
      base::PassKey<FrameMetadataObserverRegistry>(), *frame);
  Supplement<Document>::ProvideTo(document, registry);
}
registry->Bind(std::move(receiver));
~~~

Use a document supplement so navigation destroys the producer naturally. Trace
all Mojo/member state and use the document task runner. The existing Prometheus
associated-interface seam is at prometheus_render_frame_observer.cc:43-50 and
122-130:

~~~cpp
render_frame->GetAssociatedInterfaceRegistry()
    ->AddInterface<chrome::mojom::PrometheusRenderFrame>(base::BindRepeating(
        &PrometheusRenderFrameObserver::OnRenderFrameObserverRequest,
        base::Unretained(this)));

void PrometheusRenderFrameObserver::OnDestruct() {
  delete this;
}
~~~

MutationObserver setup at frame_metadata_observer_registry.h:148-165 is the
closest producer pattern, but Phase 21 must never serialize MutationRecords.
Mojo carries only coalesced dirty or overflow; no values, target/session/
document identity, or sequence.

### APC capture and exact-document check

**Analog:** prometheus_page_adapter.cc lines 152-185.

~~~cpp
if (!IsNormalPageUrl(frame->GetLastCommittedURL())) {
  std::move(callback).Run(PermissionBlocked(...));
  return;
}
auto options = optimization_guide::ActionableAIPageContentOptions(
    /*on_critical_path=*/true);
options->include_same_site_only = true;
optimization_guide::GetAIPageContent(
    web_contents, std::move(options), ...);
~~~

AIPageContentResult maps serialized document tokens to WeakDocumentPtr
(page_content_proto_provider.h:103-121). Capture the expected weak primary
document plus session/target generation before each async APC call and reject
unless all remain current. Cross-site/fenced frames already become redacted
metadata (page_content_proto_provider.cc:611-630).

### Privacy override: do not copy Phase 18 input values

prometheus_page_snapshot.cc:210-228 currently copies every field value:

~~~cpp
if (attributes.attribute_type() ==
        optimization_guide::proto::CONTENT_ATTRIBUTE_FORM_CONTROL &&
    attributes.has_form_control_data()) {
  const auto& form_control = attributes.form_control_data();
  node.input_value =
      BoundUtf8(form_control.field_value(), kMaxInputValueBytes);
}
~~~

Supervision must structurally omit input_value for password, custom-password,
payment, OTP, and unknown-sensitive decisions. Enable APC redaction and fail
closed again in browser projection. Reuse document-token-plus-DOM-id refs
(prometheus_page_snapshot.cc:167-176), bounded text, restricted-frame metadata,
deterministic traversal caps, and omission for absent optional fields.

### No live analog: ordered diff/ack/resync

No current Prometheus code has a normalized-tree diff, independent per-viewer
ack cursor, bounded retained batches, or sequence-gap resync. Implement a new
closed state machine with insert_subtree, remove, replace_fields, and
reorder_children; browser-created epoch/sequence; duplicate/gap/out-of-order/
overflow/cap/navigation transition to needs_baseline; and action pause until
the new baseline is acknowledged.

## Pattern Family 4: Exact-Window WebUI Projection and Native Tab Badge

**Apply to:** side/control runtime interfaces and adapters, WebUI handlers and
resources, sanitized tab DTO, badge/Tab integration, browser/view tests.

### Narrow UI intent and sanitized observer DTO

**Analog:** prometheus_side_panel_runtime.h lines 26-58 and 109-152.

~~~cpp
class PrometheusSidePanelRuntime {
 public:
  using SnapshotCallback =
      base::RepeatingCallback<void(base::DictValue snapshot)>;
  virtual bool IsValid() const = 0;
  virtual void SetSnapshotCallback(SnapshotCallback callback) = 0;
  virtual base::DictValue GetSanitizedSnapshot() = 0;
  virtual void HandleTargetLost() = 0;
};
~~~

Extend this with sanitized selected-tab supervision state and StopControl.
Control-panel intents cover create/revoke/enable/stop/end. Do not expose profile,
Browser, owner session, dashboard session, controller lease, epoch, digest, or
raw code through getters.

### Exact binding and teardown

**Analog:** prometheus_web_ui.cc lines 955-995 and 1226-1245.

~~~cpp
if (candidate_profile && candidate_profile->IsRegularProfile() &&
    candidate_web_contents &&
    candidate_web_contents->GetBrowserContext() == candidate_profile) {
  runtime = prometheus::CreatePrometheusControlPanelRuntime(
      candidate_profile, candidate_web_contents);
}
const bool runtime_available =
    runtime && runtime->IsBoundTo(candidate_profile, candidate_web_contents);
~~~

~~~cpp
return profile_ && bound_web_contents_ && control_runtime_ &&
       profile_->IsRegularProfile() &&
       bound_web_contents_->GetBrowserContext() == profile_ &&
       control_runtime_->IsBoundTo(profile_, bound_web_contents_);
~~~

The native adapter repeats this guard and holds a weak service, exact profile/
WebContents/Browser, observer, and callback
(prometheus_browser_main_extra_parts.cc:703-746,1255-1272). Destruction stops
observing and invalidates weak callbacks.

### Fresh snapshot plus one-shot direct code result

**Analog:** prometheus_web_ui.cc lines 998-1000 and 1233-1250.

~~~cpp
void PrometheusControlPanelUI::HandleControlInitializeForWebUI() {
  SendFreshControlSnapshot();
}

void PrometheusControlPanelUI::SendControlSnapshot(base::DictValue snapshot) {
  web_ui()->CallJavascriptFunctionUnsafe(
      "prometheusControlReceiveSnapshot",
      base::Value(std::move(snapshot)));
}

void PrometheusControlPanelUI::SendControlOperation(
    base::DictValue operation) {
  web_ui()->CallJavascriptFunctionUnsafe(
      "prometheusControlReceiveOperation",
      base::Value(std::move(operation)));
}
~~~

Observer snapshots contain sanitized lifecycle state. The raw pairing code is
returned once through the direct create operation, rendered only in the
intentional sensitive subtree, and removed on reload, redemption, expiry,
cancel, loss, or next snapshot. Never place it in observer DTOs, URLs, history,
titles, accessibility, tooltips, diagnostics, logs, audit, or MCP.

Follow message validation at prometheus_web_ui.cc:637-666: exact argument
count/type and dict size, bounded enum/numeric/string values, safe recovery,
then one browser-owned intent. UI changes only after native success and a fresh
snapshot.

### Sanitized tab DTO must survive an unowned tab

Current prometheus_agent_tab_data.cc:105-115 returns early without an owner:

~~~cpp
PrometheusTabState state;
if (!HasOwner()) {
  return state;
}
state.owner_label = owner_label_;
state.automation_active = automation_active_;
state.supervision_active = supervision_active_;
~~~

Remove that coupling. Project only viewer count, safe trusted-client labels,
sole controller label/state, closed current-action category, and stream health.
Never include opaque IDs, epochs, code, content, selector, path, or secret.

### Existing badge plus live Tab construction/update/layout

**Badge:** prometheus_tab_status_badge.cc lines 91-124.

~~~cpp
owner_or_automation_badge_ = AddBadgeIcon(this);
supervision_badge_ = AddBadgeIcon(this);
health_badge_ = AddBadgeIcon(this);
...
GetViewAccessibility().SetName(BuildAccessibleName(state));
PreferredSizeChanged();
SchedulePaint();
~~~

**Tab analog:** tabs/tab.cc lines 244-267, 327-336, 400-510, and 1331-1383.

~~~cpp
icon_ = AddChildView(std::make_unique<TabIcon>());
alert_indicator_button_ =
    AddChildView(std::make_unique<AlertIndicatorButton>(this));
...
tab_data_observer_ = std::make_unique<tabs::TabDataObserver>(tab_interface);
tab_data_change_subscription_ =
    tab_data_observer_->RegisterTabDataChangedCallback(base::BindRepeating(
        &Tab::OnTabDataChanged, base::Unretained(this)));
~~~

Construct the Prometheus badge as a real Tab child, retain its pointer, assign
bounds/compression priority, reserve title width, refresh it when browser-owned
state changes, and invalidate layout/accessibility/tooltip. Alert-indicator
layout at tab.cc:462-510 is the closest geometry pattern.

No live Prometheus badge wiring exists today; repository references stop at its
own files and GN entry. A real-tab test must prove construction, invalidation,
slot priority, accessible-name order, severe compression, and no OTR bleed.

## Pattern Family 5: Node Catalog Promotion, Privacy, and Built-App Smoke

**Apply to:** catalog, handler/diagnostics, Node tests, two-client smoke, and
the Phase 21 verifier.

### Promote exactly five same-name empty-schema routes

Current catalog.mjs lines 318-407:

~~~js
const phase21Names = [
  'create_supervision_pairing',
  'start_supervision_session',
  'get_supervision_snapshot',
  'get_supervision_diff',
  'end_supervision_session',
];

for (const name of phase21Names) {
  catalog.push({
    name,
    inputSchema: emptySchema,
    disposition: 'later_phase',
    ownerPhase: 21,
  });
}
~~~

Follow Phase 20 at catalog.mjs:214-282 and 375-386: add all five to
nativeSchemas with emptySchema, delete the later-phase loop, and map each to its
same-name native route. Keep the 90-name union fixed and visual-session names
removed.

| disposition | required count |
|---|---:|
| native | 54 |
| alias | 12 |
| typed_stub | 22 |
| later_phase | 0 |
| removed | 2 |

### Preserve recursive result stripping; update diagnostics readiness

**Analog:** tool-handler.mjs lines 18-25 and 71-95.

~~~js
const DENIED_RESULT_FIELDS = new Set([
  'bearer',
  'instance_nonce',
  'profile_path',
  'session_id',
  'token',
  'visual_reason',
]);

const sanitizeResult = (value, depth = 0) => {
  if (depth > 32) throw new TypeError('Native result nesting is invalid.');
  if (Array.isArray(value)) {
    return value.map((item) => sanitizeResult(item, depth + 1));
  }
  if (!isRecord(value)) return value;
  const sanitized = {};
  for (const [key, item] of Object.entries(value)) {
    if (!DENIED_RESULT_FIELDS.has(key)) {
      sanitized[key] = sanitizeResult(item, depth + 1);
    }
  }
  return sanitized;
};
~~~

The five MCP routes are empty-schema caller-scoped operations. They never
return pairing code, dashboard session/lease, document token/epoch, bearer,
selector, or content. Expand denied keys defensively for the new identity
vocabulary. Remove supervision from LATER_DIAGNOSTICS after native readiness;
leave extensions at Phase 22 not_ready. Preserve handler order: advertised
lookup, local-disposition rejection, argument validation, fixed native route,
recursive sanitization, NATIVE_UNAVAILABLE on transport failure
(tool-handler.mjs:197-248).

### Exact counts, closed schemas, secret sentinels

**Analog:** catalog.test.mjs lines 186-240.

~~~js
const counts = Object.fromEntries(
  ['native', 'alias', 'typed_stub', 'later_phase', 'removed']
    .map((disposition) => [
      disposition,
      COMPATIBILITY_CATALOG
        .filter((entry) => entry.disposition === disposition).length,
    ]),
);
assert.deepEqual(counts, {
  native: 49,
  alias: 12,
  typed_stub: 22,
  later_phase: 5,
  removed: 2,
});
~~~

Update counts and assert exactly five promoted names, exact same-name routes,
empty recursively closed schemas, rejection of every extra/prototype/authority
field, and recursive stripping of every new secret/identity sentinel.

### Two independent built-app clients

**Analog:** smoke-client.mjs lines 793-807 and 1120-1165.

~~~js
primary = createBridge('primary smoke bridge');
await primary.initialize();
...
second = createBridge('second smoke bridge');
await second.initialize();
~~~

~~~js
const denied = await expectToolFailure(second, 'navigate', {
  tab_id: ownedTabId,
  url: fixtureUrl,
});
requireCondition(
  denied.error_code === 'TAB_NOT_OWNED',
  'Second session controlled another session\'s tab.',
);
~~~

Extend this pattern for multiple viewers, independent expiry/revoke, exactly
one controller conflict, view-only denial, navigation resync, stale/gapped
sequence rejection, revoke/close, and late queued action denial. Exercise the
dedicated endpoint with two authenticated clients while MCP results stay
secret-free.

Clone verify-phase-20.sh's exact gate at lines 733-758: focused native/browser/
renderer tests, Node TAP, exact inventory, static/privacy/resource scans,
built-app smoke, environment/GPL/artifact/preservation checks, source-only
patch identities, clean diffs, and byte-identical Ninja metadata.

## Shared Authority, Privacy, Error, and Test Patterns

### Browser-derived authority

- Profile service owns pairing digests, sessions, leases, target bindings,
  epochs, sequences, and generations.
- Gateway, renderer, WebUI, and MCP provide intent only.
- Retain weak exact Profile/Browser/WebContents and stable TabHandle; never
  resolve a replacement active tab after creation.
- Revalidate before dispatch and in every async callback.

The closest pinned binding is prometheus_agent_gateway.cc:1827-1855:

~~~cpp
SessionBinding binding{
    .profile = profile->GetWeakPtr(),
    .browser = target_browser ? target_browser->GetWeakPtr()
                              : base::WeakPtr<BrowserWindowInterface>(),
    .stable_tab_id = stable_tab_id,
    .caller_id = base::Uuid::GenerateRandomV4().AsLowercaseString(),
};
~~~

Phase 21 stores its stronger binding in the supervision service and captures the
nonempty Agent owner. Missing weak pointers are terminal, never a fallback cue.

### Secret/content boundary

- Keep only salted code digest, expiry, and bounded attempt count after the
  direct one-shot response.
- All authority is memory-only and absent from prefs/audit/log/diagnostics/
  observer DTO/accessibility/title/URL/history/MCP.
- Audit rows contain safe event type, label/category, time, outcome, recovery;
  never code, selector, value, content, token, or path.

### Typed errors

Reuse AgentRouteResult::Failure at prometheus_agent_route.cc:142-161. Add closed
supervision statuses for invalid/expired code, attempt cap, unknown session,
view-only denial, controller conflict, stale target/epoch, sequence gap,
resync required, target lost, request/result too large, and shutdown.

### Wave 0 tests

Use the helper pattern in prometheus_agent_transport_unittest.cc:18-29:

~~~cpp
void ExpectParseError(std::string_view json, AgentErrorCode code) {
  auto parsed = ParseAgentTransportRequest(json);
  ASSERT_FALSE(parsed.has_value());
  EXPECT_EQ(code, parsed.error().error_code);
}
~~~

Write RED tests first for one-use/TTL/attempt/OTR/terminal lifecycle; multiple
viewers/single controller; all codec/queue bounds; deterministic baseline/diff;
gap/out-of-order/overflow/navigation resync; restricted frames and structural
secret omission; view-only/owner/conflict/late-action denial; native
confirmation preservation; exact-window WebUI teardown and one-shot code
removal; real badge layout/accessibility and OTR isolation.

## No Close Analog

| Capability | Gap | Planner direction |
|---|---|---|
| structural diff/ack/resync | Phase 18 builds snapshots but has no ordered diff, per-viewer ack cursor, retained queue, or resync machine | Implement from verified research; reuse APC nodes, bounds, typed errors, and lifecycle generations only |
| live Prometheus badge integration | Badge compiles/renders itself, but no Tab constructs or updates it | Use Tab child/observer/layout/compression/accessibility patterns and prove in a real-tab test |

## Planner Guardrails

1. Land types, codec, privacy projection, and RED tests before service/gateway/UI
   readiness.
2. Keep gateway thin and renderer data-free; lifecycle/identity stay in the
   regular-profile service.
3. Do not reuse Phase 18 input_value projection without structural secret
   omission.
4. Do not call Agent dispatch after captured-owner loss.
5. Do not advertise UI/diagnostic readiness before native enforcement and
   teardown tests pass.
6. Keep transport, service, stream, control, chrome, WebUI, Node, and verifier
   commits independently reviewable.

## Metadata

**Search scope:** Prometheus browser services, gateway/codecs, APC/content
observers, WebUI/runtime adapters, native tabs, MCP catalog/handler/tests, and
Phase 20 verifier.  
**External packages:** none.  
**Deferred scope excluded:** LAN/public listeners, cloud relay/hosted dashboard,
extension policy, migration-wide audit, packaging, and human screenshot review.
