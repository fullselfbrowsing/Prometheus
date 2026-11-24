---
phase: 19
slug: mcp-bridge-and-multi-agent-runtime-compatibility
mapped: 2026-07-12
---

# Phase 19 Pattern Map

## Ownership and Repository Boundaries

| Artifact | Owner | Commit boundary |
|----------|-------|-----------------|
| Chromium service, codec, gateway, Mojo, C++ tests | `.context/chromium/src` | Nested Chromium commit per task; export patches in final plan. |
| External clean-room MCP adapter and Node tests | root `tools/prometheus-mcp/` | Root repository commit per task. |
| Plans, validation, summaries, verification, preservation evidence | root `.planning/` | Root planning commits. |

Do not put production Node code in the preserved bundle or
`.context/fsb-reference`; those sources are contract-only and have incompatible
GPL/BUSL implementation licenses. Do not add a third-party agent executable,
terminal, runtime engine, CLAUDE.md provisioner, or engine-selection surface.

## Profile-Keyed Service Pattern

Closest analog:

- `chrome/browser/actor/actor_keyed_service_factory.{h,cc}`
- `chrome/browser/profiles/profile_keyed_service_factory.h`

The actor factory establishes the exact regular-profile pattern:

```cpp
ActorKeyedServiceFactory::ActorKeyedServiceFactory(...)
    : ProfileKeyedServiceFactory(
          "ActorKeyedService",
          ProfileSelections::BuildForRegularProfile()) {}

ActorKeyedService* ActorKeyedServiceFactory::GetActorKeyedService(
    content::BrowserContext* context) {
  return static_cast<ActorKeyedService*>(
      GetInstance()->GetServiceForBrowserContext(context, true));
}
```

Phase 19 should create a Prometheus factory with the same
`ProfileSelections::BuildForRegularProfile()` boundary. Its service owns the
`AgentSessionRegistry` before constructing `PrometheusAgentService`, avoiding
the current test-only raw injection. `ServiceIsCreatedWithBrowserContext()` may
return true if gateway health must see all loaded regular profiles; otherwise
the gateway can create lazily when selecting the initial profile.

Session-to-profile routing must store a browser-owned association when the
session is minted. Later route calls resolve a browser through:

- `chrome/browser/ui/browser_window/public/profile_browser_collection.h`
- `ProfileBrowserCollection::GetForProfile(profile)->FindTabbedBrowser()` or
  `GetLastActiveBrowser()`

Never select a new last-active profile after session creation.

## Browser Main Lifetime Pattern

Closest analogs:

- `chrome/browser/chrome_browser_main_extra_parts.h`
- `chrome/browser/chrome_browser_main.cc` (`ChromeBrowserMainParts::AddParts`)
- `chrome/browser/ui/views/chrome_browser_main_extra_parts_views.{h,cc}`

Add a Prometheus extra part from `CreateBrowserMainParts()` for desktop builds.
Start after profile/browser facilities are available (`PostBrowserStart` or a
late `PostProfileInit` handoff), and destroy the gateway in
`PostMainMessageLoopRun` before threads and profiles disappear. Pass the
`is_integration_test` bit so normal browser tests skip startup unless the
Prometheus gateway switch is explicitly present.

The extra part owns the one process-global gateway. Avoid an immortal global or
`base::Unretained` callback back to a destroyed browser part.

## IO/Main-Sequence HTTP Server Pattern

Closest analog:

- `components/ui_devtools/devtools_server.{h,cc}`
- `content/browser/devtools/devtools_http_handler.{h,cc}` for response helpers
- `chrome/browser/devtools/remote_debugging_server.cc` for ephemeral port
  bootstrap

`UiDevToolsServer` has the required lifetime split:

- main-sequence owner with `base::WeakPtrFactory`;
- nested `IOThreadData : net::HttpServer::Delegate` used only on an IO task
  runner;
- `net::TCPServerSocket` listening on
  `net::IPAddress::IPv4Localhost()` and port `0`;
- `net::HttpServer` owned/destroyed on the IO sequence;
- IO callbacks post to main through the owner's weak pointer;
- owner destructor uses `DeleteSoon` for the IO object.

Use `net::HttpServer::SendResponse`/`Send200` with an explicit network traffic
annotation. Phase 19 adds stricter request gates before posting to UI:

- peer/Host loopback;
- no `Origin` header;
- bearer on every path;
- closed method/path/content-type set;
- bounded body and in-flight count.

The gateway response callback needs its own one-shot request object so timeout,
browser shutdown, endpoint shutdown, page completion, and connection close
cannot respond twice.

## Endpoint Descriptor Pattern

Closest analogs:

- `components/ui_devtools/devtools_server.cc` writes an ephemeral active port
  from a background `MayBlock` task.
- `chrome/browser/devtools/remote_debugging_server.cc` uses a well-known active
  port file to bootstrap external clients.
- `base::ImportantFileWriter::WriteFileAtomically`,
  `base::SetPosixFilePermissions`, and `base::DeleteFile` provide the required
  file primitives.

Phase 19 must improve on the devtools file pattern:

1. Generate token and instance nonce on the browser main sequence.
2. Serialize a bounded descriptor containing version, `http://127.0.0.1:PORT`,
   PID, nonce, and bearer.
3. Atomically write on a `MayBlock` sequence and set POSIX mode `0600`.
4. Publish readiness to main only after permission setting succeeds.
5. On shutdown, reread/compare the nonce before deletion so an old process
   cannot remove a newer instance's descriptor.

Never emit the token from health, stderr, audit, route results, or command-line
switches.

## Typed JSON Codec Pattern

Closest local contract:

- `chrome/browser/prometheus/prometheus_agent_route.{h,cc}`
- `chrome/browser/prometheus/prometheus_agent_route_unittest.cc`

Chromium primitives:

- `base::JSONReader::Read` / `base::JSONWriter::Write`
- `base::Value::Dict::FindString`, `FindInt`, `FindDict`, and `FindList`
- `base::expected<T, AgentRouteResult>` or an equivalent typed parse result

Keep raw JSON out of `PrometheusAgentService`. A dedicated transport codec
parses the closed native envelope into `AgentRouteRequest`, enforces all bounds,
and serializes `AgentRouteResult`. The Node catalog resolves MCP aliases; the
C++ codec accepts only canonical route strings.

Plain-data additions belong in `prometheus_agent_route.h` so transport, service,
tests, and later Phase 20 adapters share one contract:

- `AgentVisualContext`
- `AgentTabMetadata` / `AgentWindowMetadata`
- `AgentDiagnosticComponent`
- explicit `foreground` request preference
- element attribute name/read result

Page content remains inside `AgentPageResult`; audit records continue to carry
only closed metadata.

## Session and Ownership Cleanup Pattern

Existing sources:

- `prometheus_agent_session.{h,cc}`
- `prometheus_agent_tab_data.{h,cc}`
- `prometheus_agent_service.{h,cc}`

The registry already generates opaque IDs with `base::UnguessableToken` and
supports cap/touch/expiry. Extend it with an explicit resume/touch result and a
way to surface expired IDs. The service then releases every tab whose
`owner_session_id()` matches a graceful close or expired owner before a new
session is denied.

Do not resume by display label. Production uses a 10-second grace plus bridge
heartbeat. Tests should inject `NowCallback` rather than sleep.

## Exact-Frame Element Read Pattern

Closest implementation chain:

- `prometheus_page_action_dispatcher.{h,cc}` — fresh APC, exact document, live
  frame, selector/ref resolution, retained operation
- `prometheus_page_snapshot.{h,cc}` — `ResolveSnapshotNodeRef`
- `chrome/common/prometheus_render_frame.mojom`
- `chrome/renderer/prometheus_render_frame_observer.{h,cc}`
- `chrome/renderer/prometheus_action_dispatcher.{h,cc}` — renderer DOM-node
  resolution bound to the exact frame

Add a read-only Mojo result with bounded text/attribute value and an explicit
attribute-presence bit. The browser must perform fresh APC/exact-document
resolution before binding the associated interface. The renderer may use
`WebNode::FromDomNodeId`, `WebNode::TextContent`, and `WebElement::GetAttribute`
only after connected/exact-frame checks. No caller JavaScript, mutation,
sibling-frame fallback, or raw renderer error propagation.

## Background Tab Pattern

Existing service target resolution already accepts stable `TabHandle` and does
not activate explicit page targets. Change only the open route:

- `TabListInterface::OpenTab(url, index, foreground)` already accepts a
  foreground boolean.
- Add an optional request flag defaulting false for MCP calls.
- Keep `kActivateTab` as the only alias whose contract necessarily foregrounds.

Structured list results should derive live metadata from `TabListInterface`,
`tabs::TabInterface`, and its `WebContents`, and must not reuse mutable indices
as identity.

## Node MCP Adapter Pattern

Production location: `tools/prometheus-mcp/` in the root repository.

Use Node 20 built-ins only:

- stream buffer/newline parser plus a first-message `Content-Length` legacy
  parser;
- `fetch` + `AbortController` for bounded native requests;
- `fs/promises` and `os.tmpdir()` for descriptor discovery;
- `node:test` and `node:assert/strict` for fixtures;
- `child_process.spawn` only in the smoke harness to launch Prometheus and the
  Prometheus-owned bridge, never a third-party agent CLI.

Modules should keep protocol, catalog, schema normalization, native client, and
server orchestration separate. `server.mjs` writes protocol JSON only to
stdout; logs use `console.error`/stderr. Tool failures return `isError: true`
plus identical serialized text and `structuredContent`.

The manifest test owns literal frozen-46/current-59 name fixtures and asserts a
90-name union with exactly one disposition per name. Do not import or execute
the GPL/BUSL reference at production/test runtime.

## Build and Test Wiring

- Add Prometheus C++ source sets/tests in
  `chrome/browser/prometheus/BUILD.gn`.
- Add browser-test sources/deps through
  `chrome/browser/ui/views/prometheus/BUILD.gn` and the existing
  `browser_tests` inclusion path.
- Extend `chrome/common:mojo_bindings` and renderer build sources only for the
  bounded element-read Mojo addition.
- Link the production profile service/gateway/extra part from a normal desktop
  browser target, not just the Prometheus browser-test source set.
- Node tests run from root and must not create `node_modules`.
- The final live smoke uses an isolated user-data directory, explicit endpoint
  descriptor, local fixture HTTP server, and deterministic teardown.

## Anti-Patterns to Reject

- Fetching a bearer from unauthenticated `/health` as the archived bridge did.
- Trusting MCP `client`, display labels, tab indices, URLs, refs, or route names
  as authority.
- Starting a listener on `0.0.0.0`, accepting browser Origin/CORS, or exposing
  token/profile paths in diagnostics.
- Reimplementing page policy in Node or using arbitrary JavaScript to fake
  `get_text`/`get_attribute`.
- Returning empty success from later-phase/removed tools.
- Copying preserved GPL/BUSL source or long tool descriptions.
- Spawning/embedding Claude Code, Codex, Cursor, another agent CLI, a terminal,
  or an alternate engine.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
