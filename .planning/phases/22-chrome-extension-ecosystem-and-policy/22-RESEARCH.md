# Phase 22 Research: Chrome Extension Ecosystem and Policy

**Phase:** 22  
**Date:** 2026-07-28  
**Status:** Ready for planning  
**Research mode:** Pinned local source only; no network, build, or test execution  
**Baseline:** nested Chromium `de937473bd` (`151.0.7898.0`), clean tracked checkout

<user_constraints>

## User Constraints (verbatim from CONTEXT.md)

### Installation and Management
- Preserve Chromium's native extensions toolbar and `chrome://extensions` as
  the primary management surfaces. Guarantee and document the developer-mode
  `Load unpacked` path rather than building a parallel Prometheus installer.
- Treat direct Chrome Web Store installation as capability-gated. Claim or
  expose it as supported only after a live built-app test succeeds; otherwise
  replace misleading store affordances with an exact limitation and the
  documented developer/sideload recovery path.
- Use Chromium's native CRX, signature verification, installation, and update
  mechanisms wherever the pinned build supports them. Never weaken install
  verification. Unpacked developer extensions use the native manual reload
  workflow.
- Preserve Chromium's per-extension Private-mode opt-in for ordinary extension
  execution, but keep Prometheus Agent access as a separate explicit grant.
  Private eligibility must never copy, infer, or automatically enable an Agent
  grant.

### Agent Permission Boundary
- Classify `chrome-extension://` targets as a distinct extension surface before
  page routing. Resolve the exact extension identity from Chromium's
  browser-owned registry, never from renderer data, a route parameter, a
  display label, or another caller claim.
- Provide local-UI-only per-extension Agent levels: `Blocked` by default,
  `Read only`, or `Interact`. `Interact` permits only closed typed actions and
  still enforces session, ownership, target, document, confirmation, and
  verification policy. Arbitrary `execute_js` remains blocked on extension
  surfaces.
- Make only visible user-facing extension tabs, popups, options pages, and side
  panels eligible for policy-controlled access. Background/service workers,
  offscreen documents, hidden hosts, and DevTools internals remain outside the
  Agent route surface.
- Chrome extension permissions never confer Prometheus authority. Extension
  code cannot obtain Agent sessions, gateway bearer material, vault authority,
  internal-surface permission, or control grants. Content-script-injected DOM
  on an ordinary page remains untrusted page content and cannot become an
  authorization signal or bypass existing origin, frame, vault, or
  confirmation checks.

### Operator Controls and Diagnostics
- Add Extension Policy controls within the existing Control Panel
  `Permissions & Agents` section and link to Chromium's native
  `chrome://extensions` manager. Do not create a duplicate manager or a tenth
  top-level Control Panel section.
- Agent-grant changes are local-UI-only. Escalating an extension to `Interact`
  requires explicit confirmation; reducing or revoking access takes effect
  immediately. Bind every change to the exact browser-owned extension ID and a
  fresh snapshot generation so stale rows cannot mutate a replacement entry.
- External MCP diagnostics expose only bounded extension-subsystem status,
  reason, and recovery guidance. The local Control Panel may show safe,
  browser-owned metadata such as bounded name, ID suffix, source, enabled
  state, Private eligibility, and current Agent grant; it must not expose
  extension page content or authority material.
- Return stable typed extension-policy errors with actionable recovery instead
  of silently falling through to the normal-page or internal-page adapter.
  Audit only the extension ID, route, grant transition, result, and timing;
  never audit extension-page content, form values, scripts, or gateway
  authority.

### Compatibility and Verification
- Cover the five required categories with deterministic, project-owned
  unpacked Manifest V3 fixtures: password-manager-like UI, ad blocking,
  productivity/content scripts, side-panel/tooling, and developer workflows.
  Optional real-world smoke tests may use version-pinned extensions, but cannot
  depend on accounts, real secrets, the network, or mutable store availability
  for acceptance.
- Treat Manifest V3 as the verified baseline. Report Manifest V2 exactly as
  supported, degraded, or blocked by the pinned Chromium revision; do not add a
  Prometheus override around upstream deprecation or security policy.
- Maintain a category compatibility matrix with `Verified`, `Degraded`, or
  `Unsupported`, recording the exact Chromium/Prometheus build, extension
  version or fixture identity, install source, behaviors exercised, and known
  limitations. Five representative successes must not be generalized into a
  universal "Chrome-compatible" claim.
- The phase closeout must prove live subsystem health; install, manage, reload,
  disable, remove, and Private-mode behavior; per-extension grant enforcement;
  extension-to-Agent isolation; all five category fixtures; typed diagnostics;
  and a built-application smoke. The gate must fail if Web Store support is
  claimed without direct live evidence.

### the agent's Discretion
- Exact C++ service and file names, pref names, bounded collection sizes,
  extension-policy error enum names, Control Panel row layout, confirmation
  wording, and fixture implementation details are at the agent's discretion.
- The planner may choose whether extension policy is owned by a new
  regular-profile keyed service or a narrowly separated dependency of the
  existing Agent/runtime profile services, provided Chromium's extension
  registry remains the identity source and the Agent service remains the sole
  route authority.
- The exact Web Store capability probe and optional real-world extension set
  are discretionary, but no unsupported external service may become a required
  acceptance dependency.

### Deferred Ideas
- A custom Prometheus extension store, installer, updater, or Manifest V2
  compatibility fork.
- Any extension-to-Agent native messaging bridge or permission mapping.
- Enterprise extension/Agent policy templates (FUT-05).
- Universal compatibility claims, store-publishing guarantees, account-backed
  extension tests, and public signed/notarized distribution.
- Cross-capability security/parity consolidation in Phase 23 and final package
  validation/handoff in Phase 24.

</user_constraints>

## Executive Finding

Phase 22 should be an authorization and evidence layer around Chromium's
already-live extension subsystem, not a second extension platform. The pinned
tree already owns install state, extension identity, lifecycle, incognito
eligibility, visible extension hosts, and `chrome://extensions`. Prometheus
should add one regular-profile policy owner, one extension-specific route
adapter, bounded Control Panel projection, live health projection, and
deterministic compatibility evidence. [SRC-01][SRC-02][SRC-03]

The most important architectural rule is to leave
`PrometheusPageAdapter::IsNormalPageUrl()` HTTP(S)-only. Classification must
happen before page-adapter dispatch; `chrome-extension://` must enter a
fail-closed extension route whose identity is reconstructed from the committed
browser frame and `ExtensionRegistry`, not accepted from a route or renderer.
[SRC-08][SRC-10]

No source observation proves that direct Chrome Web Store installation works in
the unbranded built application. The existing WebUI contains store URLs and
labels, but an affordance is not capability evidence. Keep the claim
`Unverified` until a release-built, disposable-profile, live installation probe
succeeds without test bypasses; otherwise present the exact limitation and
`Load unpacked` recovery. [SRC-04][CONTEXT]

## Requirement Coverage

| ID | Planning implication | Primary evidence |
|---|---|---|
| EXT-01 | Preserve the live native extension system and prove its health in the built app without replacing Chromium ownership. | [REQ][SRC-01][SRC-02][SRC-12] |
| EXT-02 | Preserve native install/manage/reload/disable/remove flows and guarantee the documented developer-mode path; capability-gate direct Store claims. | [REQ][SRC-04][SRC-05] |
| EXT-03 | Add generation-bound per-extension `Blocked`/`Read only`/`Interact` policy, separate Private grants, and a hard reverse extension-to-Agent boundary. | [REQ][UI][SRC-01][SRC-03][SRC-09] |
| EXT-04 | Add distinct browser-owned extension-surface classification, visible-context eligibility, typed denials, and arbitrary-script exclusion before page routing. | [REQ][SRC-06][SRC-07][SRC-08][SRC-10] |
| EXT-05 | Ship five owned MV3 category fixtures and an exact narrow compatibility matrix with deterministic positive and isolation evidence. | [REQ][CONTEXT][SRC-13] |
| EXT-06 | Replace fixed `extensions: not_ready` with bounded live status/recovery and document unverified Store, Google-service, Manifest, and other intentional limitations truthfully. | [REQ][CONTEXT][SRC-04][SRC-12] |

## Pinned Baseline and Standard Stack

- Nested source revision: `de937473bd1b5e99aec391ea003545ecd205e367`;
  short revision `de937473bd`. [LOCAL-GIT]
- `chrome/VERSION` reports Chromium `151.0.7898.0`. [LOCAL-SOURCE]
- The tracked nested checkout was clean at research time. [LOCAL-GIT]
- Extensions are compiled and initialized through
  `ChromeExtensionSystemFactory`, `ChromeExtensionSystem::Shared`, and
  `ExtensionService`; no new third-party dependency is indicated. [SRC-01]
- Installed extension identity and state are already held by
  `ExtensionRegistry`; regular and off-the-record contexts share that registry.
  [SRC-02]
- Native Chromium WebUI/Views, existing Prometheus C++ services, gtest/browser
  tests, WebUI tests, and root verification scripts are the standard stack.
  Do not add React, remote resources, a custom installer, or a package-level
  policy library. [UI][CONTEXT]
- Package/version research is not applicable: this is pinned C++ integration,
  not a dependency-selection phase. [LOCAL-SOURCE]

## Exact Source Anchors

### Chromium extension ownership

- `chrome/browser/extensions/chrome_extension_system_factory.cc:50-83` —
  shared factory dependencies and original-profile redirection. [SRC-01]
- `chrome/browser/extensions/chrome_extension_system_factory.cc:98-142` —
  per-`BrowserContext` `ChromeExtensionSystem` construction. [SRC-01]
- `chrome/browser/extensions/chrome_extension_system.h:44-83` — shared versus
  incognito-local services, readiness, service, policy, and stores. [SRC-01]
- `chrome/browser/extensions/chrome_extension_system.cc:215-305` — native
  verifier, service worker, user script, `ExtensionService`, install verifier,
  component loader, and management-policy initialization. [SRC-01]
- `chrome/browser/extensions/chrome_extension_system.cc:384-405` — regular
  profile initializes shared state. [SRC-01]
- `extensions/browser/extension_registry.h:33-80` and
  `extensions/browser/extension_registry.cc:27-45,99-162` — authoritative
  installed sets, ID lookup, and lifecycle events. [SRC-02]
- `extensions/browser/extension_registry_factory.cc:17-49` — incognito registry
  redirects to the original context. [SRC-02]
- `extensions/browser/extension_util.cc:83-158` — ordinary extension incognito
  eligibility/enabled/cross-incognito semantics. [SRC-03]
- `chrome/browser/extensions/extension_util.cc:185-250` — native mutation may
  reload an enabled extension and invalidate the prior extension pointer.
  [SRC-03]

### Native lifecycle manager

- `chrome/browser/ui/webui/extensions/extensions_ui.cc:83-89,110-182` —
  `chrome://extensions` resources and localized management strings. [SRC-04]
- `chrome/browser/ui/webui/extensions/extensions_ui.cc:220-410` — reload,
  remove, source, developer mode, Load unpacked, pack, and update labels.
  [SRC-04]
- `chrome/browser/ui/webui/extensions/extensions_ui.cc:445-475` — store/docs
  URLs and developer-mode load-time values; presence does not prove store
  installation. [SRC-04]
- `chrome/browser/ui/webui/extensions/extensions_ui.cc:492-495,519-544` —
  upstream MV2 notice wiring and `chrome://extensions` configuration. [SRC-04]
- `chrome/browser/extensions/api/developer_private/developer_private_functions.cc:611-653`
  — WebUI/user-gesture checks and incognito reload pointer hazard. [SRC-05]
- `.../developer_private_functions.cc:729-826,840-970` — reload and native
  developer-mode/policy-gated `UnpackedInstaller` path. [SRC-05]
- `.../developer_private_functions.cc:1667-1748` — native removal policy,
  confirmation, revalidation, and uninstall. [SRC-05]

### Surface identity and visibility

- `extensions/common/mojom/view_type.mojom:16-40` — closed view taxonomy:
  background, guest, popup, tab contents, offscreen, side panel, DevTools.
  [SRC-06]
- `extensions/browser/view_type_utils.cc:37-61` — browser-side view type attached
  to `WebContents`/frame; guest views are distinct. [SRC-06]
- `extensions/browser/extension_web_contents_observer.cc:327-360` —
  frame-derived ID, enabled-registry lookup, and committed-origin verification.
  [SRC-07]
- `extensions/browser/extension_host.cc:132-180,317-320` — host construction
  for background/offscreen/popup/side-panel types and navigation restrictions.
  [SRC-07]
- `extensions/browser/extension_host_registry.h:90-133` and
  `extension_host_registry.cc:49-58,157-178` — host lookup is shared across
  regular/incognito, so callers must check the host's `BrowserContext`.
  [SRC-07]
- `chrome/browser/ui/views/extensions/extension_popup.h:38-74,122-143` —
  popup visibility is owned by browser Views state. [SRC-08]
- `chrome/browser/ui/views/side_panel/extensions/extension_side_panel_coordinator.h:40-115,129-169`
  — side-panel browser/tab association and active-state ownership. [SRC-08]

### Prometheus authority and diagnostics

- `chrome/browser/prometheus/prometheus_agent_service.cc:1398-1441` — existing
  page route performs session touch, exact tab resolution, and ownership claim
  before adapter dispatch. [SRC-09]
- `chrome/browser/prometheus/prometheus_agent_service.cc:1457-1580` — stable
  browser/window/tab/profile reconciliation and control attachment. [SRC-09]
- `chrome/browser/prometheus/prometheus_page_adapter.cc:510-556` — normal pages
  are HTTP(S)-only and arbitrary script execution has its own guarded seam.
  [SRC-10]
- `chrome/browser/prometheus/prometheus_agent_profile_service_factory.cc:14-51`
  and `runtime_profile_service_factory.cc:15-72` — established
  regular-profile-only keyed-service pattern. [SRC-11]
- `chrome/browser/prometheus/prometheus_runtime_types.cc:319-329,390-405` —
  immutable
  boundary clamping and closed dispatch decisions. [SRC-11]
- `chrome/browser/prometheus/prometheus_agent_gateway.cc:661-727` — exact
  health builder currently emits fixed `extensions: not_ready`. [SRC-12]
- `chrome/browser/prometheus/prometheus_agent_gateway.cc:1930-1952` — live
  `/v1/health` resolves a regular profile and runtime state. [SRC-12]
- `chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc:1248-1290`
  and `prometheus_agent_gateway_browsertest.cc:848-890` — ten-key, bounded,
  sanitized health contract. [SRC-12]
- `chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc:799-823` —
  existing ordinal + snapshot-generation + confirmation mutation pattern.
  [SRC-14]
- `chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc:1304-1317` —
  existing Control Panel UI/controller integration point. [SRC-14]

## Recommended Architecture

1. Add a regular-profile `PrometheusExtensionPolicyService` (preferred over
   expanding runtime policy state) with `ExtensionRegistryFactory` and
   `ChromeExtensionSystemFactory` dependencies. It owns grants, bounded
   snapshots, registry observation, readiness, and safe audit projection.
2. Store grants keyed only by full browser-owned extension ID. Keep two explicit
   values: regular grant and Private grant. Defaults are both `Blocked`;
   Private cannot exceed regular and is effective only while native ordinary
   incognito eligibility is true.
3. On registry removal, immediately revoke persisted grants. On disable,
   termination, blocklist, or subsystem-not-ready, retain only the user choice
   needed for recovery but make effective access `Blocked`; never route.
4. Add `PrometheusExtensionSurfaceResolver` at the Agent service boundary.
   Resolve the committed primary frame, scheme, verified extension identity,
   registry state, `BrowserContext`, view type, and owning visible browser UI.
5. Eligible mapping is closed: visible extension `kTabContents` (including
   options pages), shown `kExtensionPopup`, and active
   `kExtensionSidePanel`. Treat `kExtensionGuest` as eligible only when its
   owning visible options surface is positively proven.
6. Explicitly reject background page/service worker, `kOffscreenDocument`,
   hidden `ExtensionHost`, `kDeveloperTools`, non-primary hidden guests,
   disabled/terminated/uninstalled IDs, mismatched profile, and ambiguous
   ownership.
7. Introduce `PrometheusExtensionPageAdapter`; do not change
   `PrometheusPageAdapter::IsNormalPageUrl()`. Reuse bounded DOM snapshot and
   typed element-action primitives only after separating them from the
   HTTP(S)-scheme decision.
8. `Read only` may expose only the already-bounded semantic read operations.
   `Interact` adds a closed allowlist of typed element actions. No extension
   route reaches `execute_js`, raw DevTools protocol, background invocation, or
   caller-provided script.
9. Enforcement order should be: authenticated session → stable target/profile
   ownership → browser-owned surface and ID → installed/enabled/visible state
   → effective regular/Private grant → action family → existing document,
   confirmation, and verification policy.
10. Re-resolve identity, generation, enabled state, context, visibility, and
    grant at action execution; never authorize from the Control Panel snapshot.
11. Add typed outcomes for at least: subsystem unavailable, non-user-visible
    context, extension not installed/enabled, blocked grant, read-only denial,
    Private grant absent/ineligible, stale policy snapshot, and arbitrary
    script unsupported.
12. Promote the existing health key without changing key count. Project only
    `ready|degraded|unavailable`, a stable reason code, and short recovery text;
    never list installed extension names/IDs through MCP.

## Control Panel Contract

- Insert one Extension Policy subsection inside `Permissions & Agents`; retain
  the existing top-level navigation count and link lifecycle work to
  `chrome://extensions`. [UI]
- Snapshot rows may contain only bounded browser-owned name, enabled/state,
  install source, manifest version, ID suffix, ordinary Private eligibility,
  regular grant, Private grant, ordinal, and generation. [UI]
- The renderer sends ordinal, generation, requested grant, and Private intent;
  native code resolves the exact ID. Do not send or trust a full ID back from
  JavaScript for mutation. [UI]
- `Interact` opens a browser-owned confirmation with safe default; downgrade or
  revoke applies immediately. Any mutation refreshes generation and clears
  stale rows. [UI]
- Show loading, empty, unavailable, stale, and mutation-error states without
  retaining obsolete controls. Use the generic extension glyph and local
  resources only. [UI]
- Preserve keyboard access, focus return after confirmation, status semantics,
  contrast, 200% zoom, and 320/480/720/1024-width behavior. [UI]
- Show the five compatibility categories as bounded local parity rows with
  `Verified`, `Degraded`, or `Unsupported`; do not expose an inventory through
  MCP. [UI][CONTEXT]

## Reuse / Avoid

**Reuse:** `ExtensionRegistry` events and ID lookup; extension WebContents
verification; native view types; popup/side-panel ownership state; native
`chrome://extensions`; regular-profile keyed-service construction; Agent
session/target ownership; snapshot-generation WebUI mutations; health
sanitization; Chromium browser-test fixture helpers. [SRC-01..SRC-14]

**Avoid:** accepting extension ID/name/URL from renderer or MCP; enumerating all
`ExtensionHostRegistry` hosts as visible; using `ExtensionSystem::is_ready()` as
an authorization decision; widening the HTTP(S) page adapter; granting from
manifest permissions; copying regular grants into Private; logging page
content; invoking developer-private test bypasses; adding MV2 overrides; or
claiming Web Store support from a visible link. [CONTEXT][SRC-02][SRC-05][SRC-07]

## Unbranded Chromium, Web Store, and Manifest Truth Boundary

- The pinned unbranded build demonstrably has the native manager, extension
  system, verifier path, and unpacked loader. Those are source-supported claims.
  [SRC-01][SRC-04][SRC-05]
- Store strings/URLs in `ExtensionsUI` prove only an affordance. Authentication,
  service availability, CRX acquisition, signature acceptance, and successful
  install must be observed in the actual release component build. [SRC-04]
- The Web Store capability result must be one of `Verified live`,
  `Unavailable`, or `Unverified`; only the first may present a supported
  installation claim. The other states show a precise reason and `Load
  unpacked` recovery. [CONTEXT]
- The live probe must use a disposable profile, a version-pinned benign
  extension, native install UI, no verification bypass, and recorded build ID,
  time, result, and sanitized failure category. Network/store state may not gate
  deterministic acceptance. [CONTEXT]
- MV3 is the acceptance baseline. Run an MV2 fixture only to report what the
  pinned build actually does. Never use the browser-test MV2 enabler or suppress
  upstream deprecation to turn the result green. [SRC-04][SRC-13]

## Deterministic Fixture Matrix

| Category | Owned MV3 fixture | Behaviors that must be proven | Negative/isolation proof |
|---|---|---|---|
| Password-manager-like UI | Popup/options form using synthetic values only | load, popup/options visibility, bounded read, typed fill/click under Interact | no real credential, no vault/session/gateway access; execute_js denied |
| Ad blocking | `declarativeNetRequest` static ruleset against local test server | ruleset loads, deterministic request blocked, disable/reload/remove behavior | manifest permission does not create Agent grant |
| Productivity/content scripts | MV3 content script mutating a local ordinary HTTP page | content injection works; normal page remains normal-page routed | injected DOM is untrusted and cannot assert extension authority |
| Side-panel/tooling | MV3 `sidePanel` fixture with visible panel and typed controls | active visible side panel can be read/interacted with by grant | hidden/inactive panel, DevTools, and offscreen document denied |
| Developer workflows | Unpacked service-worker fixture with options plus controlled edit | Load unpacked, inspect, manual reload, disable/enable, remove | background worker/offscreen context never Agent-routable |

Use `extensions/test/TestExtensionDir` for generated unpacked fixtures,
`ChromeTestExtensionLoader` for deterministic loads, and
`ExtensionTestMessageListener` for handshakes. Ensure acceptance coverage does
not inherit test helpers' default install-verification bypass. [SRC-13]

Record for every matrix row: exact Prometheus build, Chromium revision, fixture
name/hash/version, install source, regular/Private mode, actions exercised,
result, limitation, and evidence artifact. Five green fixtures justify only
those rows, not universal compatibility. [CONTEXT]

## Pitfalls That Must Become Plan Checks

1. Registry sharing can leak an incognito host into a regular-profile query;
   compare the resolved host/frame `BrowserContext` on every route. [SRC-02][SRC-07]
2. Native incognito mutation can synchronously reload an extension and
   invalidate pointers; retain IDs, then re-query the registry. [SRC-03][SRC-05]
3. `ExtensionHostRegistry` includes hidden/background/offscreen hosts; registry
   membership is not visibility. Require owning Browser/Views proof. [SRC-07][SRC-08]
4. A tab with content-script DOM is still an HTTP(S) page. Scheme plus verified
   frame origin—not DOM provenance—selects the adapter. [CONTEXT][SRC-10]
5. A full extension ID in a WebUI row can become a confused-deputy mutation
   input. Use ordinal + generation, then resolve native identity. [UI][SRC-14]
6. Persisted choice and effective permission are different during disable,
   uninstall, Private ineligibility, or subsystem failure; fail closed.
7. `Read only` must deny every mutating typed action, not merely hide controls.
8. Generic page scripting is an attractive shortcut; a compile/static gate
   should prove the extension adapter cannot call `execute_js`.
9. Web Store URLs, successful unpacked loading, or test-only CRX installation
   cannot substantiate direct live Store support.
10. Browser tests that bypass verification or enable MV2 are useful unit
    scaffolding but invalid release evidence. [SRC-05][SRC-13]

## Staged Plan Decomposition

### Plan 22-01 — Policy model and registry truth
- Add regular-profile policy service, grant enums/prefs, registry observation,
  separate Private state, bounded snapshots, typed reason codes, and unit tests.
- Define immediate revoke and stale-generation semantics before UI work.

### Plan 22-02 — Surface resolver and route enforcement
- Add committed-frame/registry identity resolution and closed visible-surface
  classification.
- Insert extension dispatch before normal-page dispatch; add dedicated adapter,
  read/interact action matrix, execute_js denial, audit redaction, and browser
  tests for every negative context.

### Plan 22-03 — Local operator UI and health
- Add Extension Policy subsection and native confirmation/mutation handlers.
- Link `chrome://extensions`; preserve native lifecycle manager.
- Replace fixed health placeholder with bounded live status while retaining the
  ten-component external contract and no-inventory rule.

### Plan 22-04 — Fixtures and compatibility truth
- Add the five owned MV3 fixtures and deterministic local-server/browser tests.
- Add Private-mode, reverse-isolation, MV2 observation, lifecycle, and exact
  matrix generation. Document supported/degraded/unsupported narrowly.

### Plan 22-05 — Built application and closeout
- Exercise developer-mode Load unpacked and all lifecycle operations in the
  release component build with a disposable profile.
- Run the capability-gated Web Store probe and ensure unsupported/unverified
  UI copy is selected unless direct evidence succeeds.
- Run focused, aggregate, patch replay/preservation, static-boundary, docs, and
  artifact-freshness gates.

Plans 22-01 and fixture skeleton work may proceed in parallel; 22-02 depends on
the policy model; 22-03 depends on stable snapshot/error DTOs; 22-04 depends on
route enforcement; 22-05 depends on all prior plans.

## Validation Architecture

### Test layers

| Layer | Required coverage | Proposed target/filter |
|---|---|---|
| C++ unit | grant lattice, Private non-inheritance, snapshot generations, registry transitions, health sanitization | `prometheus_unittests --gtest_filter=PrometheusExtensionPolicy*:*PrometheusGatewayHealth*` |
| Browser integration | exact ID, surface visibility, route matrix, lifecycle, Private contexts, reverse isolation | `browser_tests --gtest_filter=PrometheusExtension*` |
| Existing Chromium manager | native lifecycle and developer-mode behavior remain intact | `browser_tests --gtest_filter=ExtensionSettings*` |
| WebUI | rows, states, confirmation, stale mutation, accessibility, responsive behavior | Prometheus WebUI test target/suite with `ExtensionPolicy` filter |
| Node/MCP | typed errors; ten health keys; bounded reason/recovery; no inventory/content | existing Agent Gateway Node suite plus extension-policy cases |
| Built app | component-release lifecycle and optional live Store capability probe | disposable-profile scripted/manual smoke with captured evidence |
| Static/preservation | HTTP(S) boundary unchanged; no execute_js/authority bridge; patch series clean | phase root scripts and nested patch replay |

### Focused developer commands

Run from `.context/chromium/src` after generating/building the existing
Prometheus output directory:

```bash
autoninja -C out/Default prometheus_unittests browser_tests chrome
out/Default/prometheus_unittests \
  --gtest_filter='PrometheusExtensionPolicy*:*PrometheusGatewayHealth*'
out/Default/browser_tests \
  --gtest_filter='PrometheusExtension*'
out/Default/browser_tests \
  --gtest_filter='ExtensionSettings*'
```

The planner should bind the WebUI and Node commands to the repository's
existing Prometheus targets rather than inventing a second runner. Following
the Phase 20/21 planning-owned harness convention, the phase should add these
entry points under `.planning/chromium/`:

```bash
.planning/chromium/verify-phase-22-extension-policy.sh --focused
.planning/chromium/verify-phase-22-extension-fixtures.sh --focused
.planning/chromium/verify-phase-22-webui.sh --focused
.planning/chromium/verify-phase-22-mcp.sh --focused
```

### Mandatory deterministic fixture runs

```bash
.planning/chromium/verify-phase-22-extension-fixtures.sh --category password-manager
.planning/chromium/verify-phase-22-extension-fixtures.sh --category ad-blocking
.planning/chromium/verify-phase-22-extension-fixtures.sh --category productivity
.planning/chromium/verify-phase-22-extension-fixtures.sh --category side-panel
.planning/chromium/verify-phase-22-extension-fixtures.sh --category developer-workflow
```

Each category command must create a disposable profile, install its owned MV3
fixture, use only local deterministic endpoints/data, exercise its positive
behavior, exercise its category-specific negative boundary, and emit one
machine-readable compatibility row.

### Final phase commands

```bash
.planning/chromium/verify-phase-22-extension-policy.sh
.planning/chromium/verify-phase-22-extension-fixtures.sh
.planning/chromium/verify-phase-22-webui.sh
.planning/chromium/verify-phase-22-mcp.sh
.planning/chromium/verify-phase-22-built-app.sh
.planning/chromium/verify-phase-22-preservation.sh
.planning/chromium/verify-phase-22-patch-replay.sh
.planning/chromium/verify-phase-22.sh
```

`verify-phase-22.sh` must fail unless:

- the extension system is live and the external health object still has exactly
  ten bounded components;
- install, manage, reload, disable/enable, remove, and ordinary Private
  eligibility are proven;
- Blocked, Read only, Interact, downgrade, revoke, stale generation, and
  separate Private grants are proven;
- visible tab/options/popup/side-panel cases pass and background worker,
  offscreen, hidden host, DevTools, and wrong-profile cases fail typed;
- arbitrary extension-surface script execution and reverse extension-to-Agent
  access are denied;
- all five fixture rows exist with exact build/fixture/source/behavior/limit
  fields and allowed status vocabulary;
- MV2 is reported from the unmodified pinned policy;
- built-app smoke evidence is fresh;
- any supported Web Store claim has matching successful live evidence, while a
  failed/unrun probe selects explicit unverified/unavailable copy;
- nested source is represented by the ordered patch series and replay/preservation
  checks pass.

### Manual visual/accessibility checks

- Inspect Extension Policy at widths 320, 480, 720, and 1024 CSS pixels and at
  200% zoom.
- Traverse rows, grant controls, manager link, confirmation,
  `Keep current access`, and focus return using keyboard only.
- Verify screen-reader names/state, visible focus, status semantics, contrast,
  text wrapping, disabled-state explanation, loading/error clearing, and no
  horizontal loss of controls.
- Capture built-app screenshots for ready, empty, unavailable, blocked,
  read-only, Interact confirmation, stale-row error, and all five matrix states.

## Open Planning Choices

- Policy persistence may use a dedicated pref dictionary or a narrow existing
  Prometheus pref namespace; prefer the representation with schema validation,
  bounded entries, and clean uninstall revocation.
- Options pages can appear as top-level extension tabs or embedded guests.
  Eligibility must be expressed as positive owning-surface proofs, not an
  over-broad `ViewType` allowlist.
- Decide exact row and diagnostic bounds during planning, then test truncation
  and serialization limits.
- A real-world extension smoke is optional and non-gating. The five owned
  fixtures plus built-app lifecycle are the deterministic acceptance basis.

## Source Index

- `[CONTEXT]` —
  `.planning/phases/22-chrome-extension-ecosystem-and-policy/22-CONTEXT.md`
- `[UI]` —
  `.planning/phases/22-chrome-extension-ecosystem-and-policy/22-UI-SPEC.md`
- `[REQ]` — `.planning/REQUIREMENTS.md` (`EXT-01` through `EXT-06`)
- `[LOCAL-GIT]` — nested Chromium `git rev-parse`, `git describe`, and status
  inspected 2026-07-28.
- `[LOCAL-SOURCE]` — `.context/chromium/src/chrome/VERSION` and pinned tree.
- `[SRC-01]` — Chrome extension system factory/system implementation.
- `[SRC-02]` — extensions `ExtensionRegistry` and factory.
- `[SRC-03]` — incognito extension utilities.
- `[SRC-04]` — native Extensions WebUI.
- `[SRC-05]` — `developer_private` lifecycle functions and settings tests.
- `[SRC-06]` — extension `ViewType` and view-type utilities.
- `[SRC-07]` — extension WebContents observer, hosts, and host registry.
- `[SRC-08]` — popup and side-panel Views ownership.
- `[SRC-09]` — `PrometheusAgentService`.
- `[SRC-10]` — `PrometheusPageAdapter`.
- `[SRC-11]` — Prometheus keyed-service factories and runtime policy.
- `[SRC-12]` — Agent Gateway health implementation/tests.
- `[SRC-13]` — `ChromeTestExtensionLoader`, `TestExtensionDir`,
  `ExtensionTestMessageListener`, DNR/content-script/side-panel tests.
- `[SRC-14]` — Prometheus Control Panel WebUI handlers.

## Research Confidence

**High:** native subsystem/lifecycle ownership, registry identity, profile
sharing, incognito reload hazard, view taxonomy, Prometheus HTTP(S) boundary,
gateway placeholder/ten-key contract, and viable Chromium fixture helpers.

**Medium:** the narrow visible-options-guest resolver shape and exact policy
pref layout; these are implementation choices that require focused tests.

**Intentionally unknown until live evidence:** direct Chrome Web Store install
in the unbranded release component build and current MV2 runtime outcome.
Neither may be promoted from source inference to a compatibility claim.
