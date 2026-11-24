---
phase: 22
slug: chrome-extension-ecosystem-and-policy
mapped: 2026-07-28
status: complete
---

# Phase 22 Codebase Patterns

Concrete implementation conventions for adding extension policy and
extension-surface routing without replacing Chromium's extension subsystem or
widening Prometheus authority.

## Architectural Placement

### Chromium keeps extension lifecycle ownership

- `chrome/browser/extensions/chrome_extension_system_factory.cc` constructs
  `ChromeExtensionSystem` with the existing keyed-service dependency graph.
- `chrome/browser/extensions/chrome_extension_system.{h,cc}` owns readiness,
  `ExtensionService`, install verification, component loading, service workers,
  user scripts, stores, and management policy.
- `extensions/browser/extension_registry.{h,cc}` is the authoritative installed
  and enabled extension identity source.
- `extensions/browser/extension_registry_factory.cc` redirects OTR registry
  access to the original context. Shared registry state therefore never proves
  that a particular extension surface belongs to the current context.
- `chrome/browser/ui/webui/extensions/extensions_ui.cc` and
  `chrome/browser/extensions/api/developer_private/developer_private_functions.cc`
  already implement `chrome://extensions`, developer mode, Load unpacked,
  reload, enable/disable, pack, update, and removal.

Phase 22 should observe and constrain this native machinery. It should not add
a second installer, duplicate the extension registry, bypass native
verification, or reimplement the extension manager in the Prometheus Control
Panel.

### Prometheus policy belongs in a regular-profile service

Existing factory patterns:

- `chrome/browser/prometheus/prometheus_agent_profile_service_factory.{h,cc}`
- `chrome/browser/prometheus/prometheus_runtime_profile_service_factory.{h,cc}`
- `chrome/browser/prometheus/prometheus_supervision_profile_service_factory.{h,cc}`

These use `ProfileKeyedServiceFactory`, declare browser-owned service
dependencies, and resolve work through a regular profile. Follow this shape for
`PrometheusExtensionPolicyService` and its factory. The factory should depend on
`ChromeExtensionSystemFactory` and `ExtensionRegistryFactory`, return no
independent OTR authority, and make Private policy an explicit value evaluated
against the exact current `BrowserContext`.

The service owns:

- closed grants: `Blocked`, `Read only`, `Interact`;
- separate requested regular and Private grants;
- bounded, generation-numbered local snapshots;
- `ExtensionRegistryObserver` lifecycle reconciliation;
- persisted ID-keyed choices with strict schema/count/string bounds;
- effective-grant calculation from readiness, installed/enabled state,
  ordinary incognito eligibility, context, and requested grant;
- sanitized local audit and external health projection.

Persist extension IDs, never `Extension*` pointers. Native incognito changes,
reload, disable, uninstall, and replacement can synchronously invalidate prior
objects. Re-query the registry after every mutation and before dispatch.

## Authority and Routing Seams

### Preserve the ordinary-page boundary

`chrome/browser/prometheus/prometheus_page_adapter.{h,cc}` intentionally keeps
`PrometheusPageAdapter::IsNormalPageUrl()` HTTP(S)-only. Content injected by an
extension into an HTTP(S) document is still ordinary page content. Do not widen
this method to accept `chrome-extension://`.

Introduce a distinct `PrometheusExtensionPageAdapter` and factor only the
already-bounded semantic read and typed element-action primitives that both
adapters can safely share. The extension adapter must have no callable path to
generic `execute_js`, raw DevTools protocol, background APIs, native messaging,
gateway credentials, vault authority, or policy mutation.

### Insert policy at the Agent service boundary

`chrome/browser/prometheus/prometheus_agent_service.cc` already performs
authenticated session touch, stable tab/window/profile resolution, ownership,
and document reconciliation before page adapter dispatch. Extension
classification belongs after those checks and before ordinary-page adapter
selection.

Recommended order:

1. authenticated Agent session;
2. stable browser/window/tab/profile and current document ownership;
3. committed primary-frame scheme and browser-owned extension ID;
4. exact registry installed/enabled state and `BrowserContext`;
5. positively proven visible surface;
6. fresh effective regular or Private grant;
7. closed read/action-family authorization;
8. existing document, confirmation, action, and verification checks;
9. repeat identity, generation, visibility, and grant checks at execution.

Never authorize from renderer-provided extension ID, URL, name, permission,
manifest field, DOM provenance, or a stale Control Panel snapshot.

### Resolve visible surfaces positively

Use these native anchors:

- `extensions/common/mojom/view_type.mojom`
- `extensions/browser/view_type_utils.cc`
- `extensions/browser/extension_web_contents_observer.cc`
- `extensions/browser/extension_host.{h,cc}`
- `extensions/browser/extension_host_registry.{h,cc}`
- `chrome/browser/ui/views/extensions/extension_popup.{h,cc}`
- `chrome/browser/ui/views/side_panel/extensions/extension_side_panel_coordinator.{h,cc}`

`PrometheusExtensionSurfaceResolver` should accept only:

- a visible top-level extension tab, including a proven options page;
- a currently shown extension popup owned by the resolved browser;
- a currently active extension side panel owned by the resolved browser/tab;
- an options guest only when its exact visible owning surface is proven.

Reject background pages/workers, offscreen documents, hidden hosts, DevTools,
unowned or hidden guests, wrong-profile/OTR contexts, disabled/terminated/
uninstalled IDs, uncommitted or mismatched origins, and ambiguous ownership.
Host registry membership or `ExtensionSystem::is_ready()` alone is not
authorization.

## Closed Data and Error Patterns

`chrome/browser/prometheus/prometheus_runtime_types.cc` demonstrates immutable
boundary clamping and closed dispatch decisions. New extension DTOs and enums
should follow this pattern: exhaustive switch handling, fixed maximum sizes,
stable machine-readable reason codes, and no ambient stringly-typed authority.

Required typed denials include:

- subsystem unavailable;
- non-user-visible context;
- extension not installed or enabled;
- blocked grant;
- read-only mutation denial;
- Private grant absent or ineligible;
- stale policy generation;
- arbitrary script unsupported.

External error/health output is bounded and inventory-free. Local UI may show a
bounded browser-owned label and ID suffix, but external MCP/gateway responses,
logs, audits, and accessibility announcements must not disclose full IDs,
installed rows, permissions, page content, form values, scripts, profile
paths, session material, or authority.

## Control Panel and Confirmation Patterns

Existing integration points:

- `chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc`
- `chrome/browser/ui/webui/prometheus/prometheus_web_ui.h`
- `chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.{h,cc}`
- `chrome/browser/resources/prometheus/prometheus_control_panel.html`
- `chrome/browser/resources/prometheus/prometheus_webui.js`
- `chrome/browser/resources/prometheus/prometheus_webui.css`
- `chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.{h,cc}`

`prometheus_web_ui.cc` already uses an ordinal plus snapshot generation for
browser-resolved mutations. Reuse it: JavaScript sends only ordinal,
generation, requested closed grant, and Private intent. Native code resolves
the current full ID before confirmation and again before mutation.

Place Extension Policy inside the existing `Permissions & Agents` section.
Keep the nine top-level Control Panel sections unchanged and link lifecycle
management to `chrome://extensions`.

`Interact` is an authority increase and uses a browser-owned modal. The safe
focused action is `Keep current access`; Escape/cancel preserves the current
grant. Downgrade and revoke may apply immediately. Every completion refreshes
the snapshot generation, reconciles removed/reordered rows, returns focus
safely, and clears stale errors.

Follow `22-UI-SPEC.md` exactly: local resources only, existing warm tokens,
4/8/16/24/32/48/64 spacing, 12/13/16/20 typography, 48px primary/safety
targets, system body font, 320/480/720/1024 layouts, 200% zoom, keyboard and
screen-reader states. In light mode use `#7a3215` for interaction text; reserve
`#ff6b35` for filled surfaces with `#1f1a17`.

## Health and Documentation Patterns

`chrome/browser/prometheus/prometheus_agent_gateway.cc` currently emits the
fixed extension `not_ready` health entry. Preserve the exact ten-component
health shape and replace only that component's live status with:

- `ready`, `degraded`, or `unavailable`;
- one stable bounded reason code;
- short bounded recovery text.

Existing assertions in
`prometheus_agent_gateway_unittest.cc` and
`prometheus_agent_gateway_browsertest.cc` are the regression pattern. Add
recursive sentinel scans for inventory, IDs, content, permissions, and
authority.

Documentation must distinguish source-proven native lifecycle, deterministic
MV3 fixture results, and live Web Store evidence. A Store URL/string is not an
install result. Store state is exactly `Verified live`, `Unavailable`, or
`Unverified`; only fresh matching built-app evidence may select the first.
Observe MV2 under unmodified pinned Chromium policy and never enable it merely
to make acceptance green.

## Test and Fixture Conventions

Use existing Chromium helpers:

- `extensions/test/TestExtensionDir` for generated unpacked MV3 fixtures;
- `ChromeTestExtensionLoader` for deterministic loads;
- `ExtensionTestMessageListener` for fixture handshakes;
- `InProcessBrowserTest` for real registry, surface, manager, profile, and
  visibility integration;
- existing Prometheus gtest/WebUI/browser/Node harnesses.

Own five small deterministic MV3 fixtures under a Prometheus-specific extension
test-data directory:

1. password-manager-like popup/options UI with synthetic values;
2. DNR ad blocker against the local embedded server;
3. productivity content script on an ordinary HTTP page;
4. side-panel/tooling extension;
5. unpacked service-worker developer workflow.

Each positive row needs a category-specific denial: no vault/session access,
manifest permission creates no Agent grant, injected DOM cannot assert
extension identity, inactive/hidden panel is denied, and background/offscreen
contexts never route.

Keep test names under stable `PrometheusExtensionPolicy*`,
`PrometheusExtensionSurface*`, `PrometheusExtension*`, and
`PrometheusWebUI*ExtensionPolicy*` prefixes so the verifier can list-guard
nonempty focused cohorts.

## Build, Commit, and Preservation Patterns

- Add new C++ sources/tests through
  `chrome/browser/prometheus/BUILD.gn` and the established browser-test source
  lists; update WebUI resources through
  `chrome/browser/resources/prometheus/BUILD.gn`.
- Build from `.context/chromium/src/out/Default`; do not introduce another
  output directory.
- Extend the Phase 21 Siso-query/direct-object compile and focused-link flow.
- Preserve `.ninja_log`, `.ninja_deps`, linked Blink artifacts, packaged
  resources, and unrelated generated outputs byte-for-byte unless a plan
  explicitly owns a reviewed change.
- Keep nested Chromium implementation commits atomic and ordered. Export each
  source-only commit into the root patch chain using the established
  preservation workflow; reject missing, empty, reordered, or mutated patches.
- Extend `.planning/chromium/verify-phase-22*.sh`; do not create a root
  `scripts/` convention.

## Likely File Ownership by Plan

- `22-01`: new extension policy service/factory/types/unit tests, prefs and
  `chrome/browser/prometheus/BUILD.gn`.
- `22-02`: new surface resolver and extension adapter/tests plus the narrow
  `PrometheusAgentService` routing integration.
- `22-03`: Control Panel native handler, runtime dialog, HTML/JS/CSS, WebUI and
  health unit/browser/Node tests.
- `22-04`: five owned MV3 fixture directories, lifecycle/surface browser tests,
  compatibility evidence generator, docs.
- `22-05`: authoritative verifier, built-app disposable-profile smoke, Store
  capability evidence, preservation ledger, validation and verification.

The planner may split these files further to avoid broad simultaneous
ownership, but dependencies remain policy model -> resolver/adapter -> UI and
fixtures -> built-app closeout.

## Anti-Patterns and Blocking Review Checks

- No extension permission, manifest permission, or extension code can create an
  Agent grant or obtain a session/bearer.
- No renderer/MCP-provided full ID, name, URL, generation bypass, or label is
  trusted for mutation.
- No generic `execute_js`, raw CDP, hidden host enumeration, background
  invocation, native-messaging bridge, or reverse extension-to-Agent route.
- No regular-to-Private implicit inheritance or cross-profile host acceptance.
- No authorization from DOM provenance, registry sharing, subsystem readiness,
  or a cached `Extension*` pointer.
- No installed inventory/content/permission data in external diagnostics,
  errors, logs, audits, compatibility output, or documentation.
- No Web Store/MV2/universal compatibility claim from static strings,
  developer-mode fixtures, test verification bypasses, or stale evidence.
- No React, remote assets, new package policy layer, custom installer, or
  alternate build/verification convention.

Every final plan must map its owned items to `T-22-01` through `T-22-10`, embed
a concrete `<threat_model>`, create retained RED fixtures before GREEN behavior,
and bind each task to a nonempty automated command from `22-VALIDATION.md`.
