---
phase: 22-chrome-extension-ecosystem-and-policy
reviewed: 2026-08-10T06:36:17Z
depth: standard
files_reviewed: 91
files_reviewed_list:
  - chrome/browser/extensions/api/developer_private/developer_private_api_unittest.cc
  - chrome/browser/extensions/api/developer_private/developer_private_functions.cc
  - chrome/browser/prefs/browser_prefs.cc
  - chrome/browser/profiles/BUILD.gn
  - chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc
  - chrome/browser/prometheus/BUILD.gn
  - chrome/browser/prometheus/prometheus_agent_audit.cc
  - chrome/browser/prometheus/prometheus_agent_audit.h
  - chrome/browser/prometheus/prometheus_agent_audit_unittest.cc
  - chrome/browser/prometheus/prometheus_agent_gateway.cc
  - chrome/browser/prometheus/prometheus_agent_gateway.h
  - chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc
  - chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc
  - chrome/browser/prometheus/prometheus_agent_profile_service.cc
  - chrome/browser/prometheus/prometheus_agent_profile_service.h
  - chrome/browser/prometheus/prometheus_agent_route.cc
  - chrome/browser/prometheus/prometheus_agent_route.h
  - chrome/browser/prometheus/prometheus_agent_route_unittest.cc
  - chrome/browser/prometheus/prometheus_agent_service.cc
  - chrome/browser/prometheus/prometheus_agent_service.h
  - chrome/browser/prometheus/prometheus_agent_service_unittest.cc
  - chrome/browser/prometheus/prometheus_agent_transport_codec.cc
  - chrome/browser/prometheus/prometheus_agent_transport_codec_unittest.cc
  - chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
  - chrome/browser/prometheus/prometheus_browser_main_extra_parts.h
  - chrome/browser/prometheus/prometheus_extension_agent_browsertest.cc
  - chrome/browser/prometheus/prometheus_extension_compatibility_catalog.cc
  - chrome/browser/prometheus/prometheus_extension_compatibility_catalog.h
  - chrome/browser/prometheus/prometheus_extension_compatibility_catalog_unittest.cc
  - chrome/browser/prometheus/prometheus_extension_fixtures_browsertest.cc
  - chrome/browser/prometheus/prometheus_extension_page_adapter.cc
  - chrome/browser/prometheus/prometheus_extension_page_adapter.h
  - chrome/browser/prometheus/prometheus_extension_page_adapter_unittest.cc
  - chrome/browser/prometheus/prometheus_extension_policy_prefs.cc
  - chrome/browser/prometheus/prometheus_extension_policy_prefs.h
  - chrome/browser/prometheus/prometheus_extension_policy_service.cc
  - chrome/browser/prometheus/prometheus_extension_policy_service.h
  - chrome/browser/prometheus/prometheus_extension_policy_service_factory.cc
  - chrome/browser/prometheus/prometheus_extension_policy_service_factory.h
  - chrome/browser/prometheus/prometheus_extension_policy_service_unittest.cc
  - chrome/browser/prometheus/prometheus_extension_policy_types.cc
  - chrome/browser/prometheus/prometheus_extension_policy_types.h
  - chrome/browser/prometheus/prometheus_extension_smoke_bootstrap.cc
  - chrome/browser/prometheus/prometheus_extension_smoke_bootstrap.h
  - chrome/browser/prometheus/prometheus_extension_smoke_bootstrap_unittest.cc
  - chrome/browser/prometheus/prometheus_extension_smoke_browsertest.cc
  - chrome/browser/prometheus/prometheus_extension_smoke_controller.cc
  - chrome/browser/prometheus/prometheus_extension_smoke_controller.h
  - chrome/browser/prometheus/prometheus_extension_surface_browsertest.cc
  - chrome/browser/prometheus/prometheus_extension_surface_resolver.cc
  - chrome/browser/prometheus/prometheus_extension_surface_resolver.h
  - chrome/browser/prometheus/prometheus_extension_surface_resolver_unittest.cc
  - chrome/browser/prometheus/prometheus_page_action_dispatcher.cc
  - chrome/browser/prometheus/prometheus_page_action_dispatcher.h
  - chrome/browser/prometheus/prometheus_page_element_reader.cc
  - chrome/browser/prometheus/prometheus_page_element_reader.h
  - chrome/browser/resources/prometheus/prometheus_control_panel.html
  - chrome/browser/resources/prometheus/prometheus_webui.css
  - chrome/browser/resources/prometheus/prometheus_webui.js
  - chrome/browser/ui/views/extensions/extension_popup.cc
  - chrome/browser/ui/views/extensions/extension_popup.h
  - chrome/browser/ui/views/prometheus/BUILD.gn
  - chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
  - chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h
  - chrome/browser/ui/views/side_panel/extensions/extension_side_panel_coordinator.cc
  - chrome/browser/ui/views/side_panel/extensions/extension_side_panel_coordinator.h
  - chrome/browser/ui/views/side_panel/extensions/extension_side_panel_manager.cc
  - chrome/browser/ui/views/side_panel/extensions/extension_side_panel_manager.h
  - chrome/browser/ui/webui/prometheus/BUILD.gn
  - chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
  - chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
  - chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
  - chrome/test/data/prometheus/extensions/ad_blocker/manifest.json
  - chrome/test/data/prometheus/extensions/ad_blocker/rules.json
  - chrome/test/data/prometheus/extensions/developer_workflow/manifest.json
  - chrome/test/data/prometheus/extensions/developer_workflow/options.html
  - chrome/test/data/prometheus/extensions/developer_workflow/options.js
  - chrome/test/data/prometheus/extensions/developer_workflow/service_worker.js
  - chrome/test/data/prometheus/extensions/mv2_observation/background.js
  - chrome/test/data/prometheus/extensions/mv2_observation/manifest.json
  - chrome/test/data/prometheus/extensions/password_manager_like/manifest.json
  - chrome/test/data/prometheus/extensions/password_manager_like/options.html
  - chrome/test/data/prometheus/extensions/password_manager_like/options.js
  - chrome/test/data/prometheus/extensions/password_manager_like/popup.html
  - chrome/test/data/prometheus/extensions/password_manager_like/popup.js
  - chrome/test/data/prometheus/extensions/productivity_content_script/content.js
  - chrome/test/data/prometheus/extensions/productivity_content_script/manifest.json
  - chrome/test/data/prometheus/extensions/side_panel_tooling/manifest.json
  - chrome/test/data/prometheus/extensions/side_panel_tooling/side_panel.html
  - chrome/test/data/prometheus/extensions/side_panel_tooling/side_panel.js
  - .planning/chromium/verify-phase-22.sh
findings:
  critical: 5
  warning: 4
  info: 0
  total: 9
status: issues_found
---

# Phase 22: Code Review Report

**Reviewed:** 2026-08-10T06:36:17Z
**Depth:** standard
**Files Reviewed:** 91
**Status:** issues_found

## Summary

The extension policy implementation has strong fail-closed primitives, but the submitted phase is not ready to ship. Five defects affect target correctness, security confirmation, privacy, or result-file integrity. Four additional defects make the acceptance evidence materially less reliable than its reported green status: several browser tests assert synthetic booleans instead of exercising the browser-owned route, the packaged smoke publishes inferred successes, the compatibility metadata shown in product is stale, and the authoritative gate treats an old verification document as live regression execution.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01 (BLOCKER): Embedded options guests can never reach the resolver

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_resolver.cc:161-180`

**Issue:** With no popup/side-panel selector, `SelectCandidates()` adds only `anchor_tab->GetContents()`. An embedded `ExtensionOptionsGuest` is a separate guest `WebContents` owned by the `chrome://extensions` tab, not the tab's top-level `WebContents`. Consequently, the later `kOptionsGuest` validation at lines 333-346 is unreachable for a real embedded options page. The unit test at `prometheus_extension_surface_resolver_unittest.cc:88-93` passes a hand-built evidence struct and therefore does not expose the dead production path. The advertised visible-options-guest route always resolves the owner tab instead and fails as a non-extension target.

**Fix:** When the anchor is the extensions manager and no selector is present, enumerate attached `ExtensionOptionsGuest` instances owned by `anchor_tab->GetContents()`, retain exactly one visible primary guest, and add its guest `WebContents` as the candidate. Add an in-process browser test that opens a real embedded options page and calls `Resolve()`; also test zero, multiple, hidden, detached, and wrong-owner guests.

#### CR-02 (BLOCKER): `extension_surface` is accepted on tab-management routes and then ignored

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc:1231-1308`

**Related:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc:1177-1194`

**Issue:** `ParseTarget()` validates the selector's spelling and stable `tab_id`, but parsing never checks whether the selected route is an extension-page route. A request such as `close_tab` with `{"tab_id":7,"extension_surface":"popup"}` is accepted. `ExecuteRoute()` then ignores `extension_surface` and closes tab 7. The same mismatch affects activation, navigation, reload, history, duplication, move, listing, and internal-surface routes. A caller that explicitly targeted a popup or side panel can therefore mutate or destroy the anchor tab instead.

**Fix:** After parsing the route and target, reject `extension_surface` unless `route_name` belongs to the closed extension page read/interaction family. Add codec and service tests for every non-page family, including a regression that proves `close_tab` returns `INVALID_TARGET` and leaves the anchor tab open.

#### CR-03 (BLOCKER): The smoke result writer can clobber an existing file or follow a raced symlink

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap.cc:422-436`

**Related:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc:1663-1701`

**Issue:** Bootstrap accepts any existing non-symlink result path and checks it only with `lstat`. `WriteResult()` later opens that path with `FLAG_CREATE_ALWAYS | FLAG_WRITE`, without `FLAG_NO_FOLLOW` or exclusive creation. It will truncate an existing user file, and a path swapped to a symlink after validation is followed at open time. It also marks the result written before serialization/open succeeds and ignores the write and chmod return values, so a short or failed write becomes an unrecoverable missing/corrupt terminal record. This violates the claimed exclusive 0600 result-file boundary and creates a concrete data-loss race.

**Fix:** Require the result path to be absent under the already-verified owner-only disposable directory, then create it atomically with exclusive/no-follow flags and mode 0600. Verify the opened descriptor with `fstat`, require `WriteAtCurrentPosAndCheck()`, and set `result_written_` only after the durable complete write succeeds. Add tests for a pre-existing regular file, symlink substitution between validation and open, short write, chmod failure, and retry after write failure.

#### CR-04 (BLOCKER): Chooser mismatch diagnostics disclose complete caller URLs

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc:604-621`

**Issue:** The global one-shot chooser factory can observe an unrelated chooser while installed. On a mismatch it logs both `caller->spec()` and the expected full URL. Caller URLs may contain sensitive paths, query parameters, or fragments. This directly contradicts the phase's content-free/no-full-URL logging boundary. The fact that the path is restricted to a non-official smoke does not make browser logs a safe sink for arbitrary user navigation data.

**Fix:** Log only closed booleans and non-sensitive categories, for example `has_caller`, `caller_origin_matches`, and `expected_origin_matches`. Never serialize the URL, path, query, or fragment. Add a test with a sentinel query secret and assert it is absent from captured logs.

#### CR-05 (BLOCKER): The Interact confirmation does not present a trustworthy extension identity

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h:83-86`

**Related:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc:409-427`

**Issue:** The native escalation dialog receives and displays only `extension_name`. Extension names are attacker-controlled manifest metadata; duplicate names are allowed, and `IsSafeDisplayText()` rejects only ASCII control bytes, not Unicode bidirectional/isolate controls. A malicious extension can therefore present the same or a visually reordered name as another installed extension, while the modal omits the browser-owned ID suffix and source that could disambiguate it. The user cannot verify which exact extension is receiving the `Interact` grant at the security decision point.

**Fix:** Extend the browser-owned dialog model with the validated six-character ID suffix and a closed install-source value, render both separately from the untrusted name, and strip or safely isolate bidi formatting characters in the display label. Add tests with duplicate names and bidi-control payloads and assert that the immutable suffix/source remain visible in the modal title/body.

### Warnings

#### WR-01 (WARNING): Compatibility and routing browser tests report behaviors they never exercise

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_fixtures_browsertest.cc:102-140`

**Related:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_agent_browsertest.cc:14-45`; `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_browsertest.cc:14-36`

**Issue:** The password-manager fixture navigates directly to an options URL and calls `EvaluateAdmissionForTesting()` on synthetic defaults; it does not open a popup, route through `PrometheusAgentService`, perform a bounded DOM read, or dispatch an Interact action. The side-panel fixture similarly opens `side_panel.html` as a normal tab and classifies a hand-authored evidence struct (lines 206-241). The developer fixture declares background denial by classifying another hand-authored struct (lines 285-290). The dedicated extension-agent and surface “browser tests” mostly assert `*ImplementedForTesting()` returns true. These tests can remain green if the real resolver, policy integration, or dispatch path is disconnected—as CR-01 demonstrates—while the compatibility catalog labels the behaviors Verified.

**Fix:** Replace marker and synthetic-classification assertions with real browser flows: open the action popup and extension side panel through native UI, call `Resolve()` and the Agent service with a live session/tab handle, mutate grants through the local UI confirmation path, exercise actual reads/actions, and probe real typed denials. Generate each compatibility row only from the corresponding observed results.

#### WR-02 (WARNING): The packaged smoke publishes inferred policy/routing success as observed evidence

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_smoke_controller.cc:1276-1419`

**Issue:** `ExercisePolicyGrants()` mutates the service directly, including `Interact`, bypassing the Control Panel and native confirmation. The options stage merely checks that an options tab is active before setting `options_routing_visible_ = true`, and sets `background_denied_ = true` “by construction” without issuing any route. `WriteResult()` then exports all three values as passing evidence. The built-app smoke therefore remains green if the local confirmation bridge, extension resolver, Agent adapter, or typed background denial is broken.

**Fix:** Drive grant changes through the real local Control Panel and accept the real safe-default modal; issue authenticated Agent requests to the live options surface and a real unsupported background/hidden target; set result flags only from the returned typed outcomes. Keep direct service mutation only in unit tests that explicitly label the narrower contract.

#### WR-03 (WARNING): Product compatibility metadata is stale even when generated evidence claims the current head

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/chrome/browser/prometheus/prometheus_extension_compatibility_catalog.cc:20-32`

**Issue:** The compiled catalog displayed by the Control Panel hard-codes Chromium revision `cdaff22b49` and verification time `2026-07-29T14:56:28Z`, while the reviewed source and freshly generated `22-COMPATIBILITY.json` identify head `d76947ab3ef99ff929978fb4d3a057e476b06591`. The fixture verifier checks only manifest hashes against the compiled catalog and independently stamps JSON with current `HEAD`; it never cross-checks the catalog revision/time. Local UI and machine evidence can therefore make contradictory “exact build/revision” claims while all gates pass.

**Fix:** Generate the compiled catalog metadata and JSON from one fresh fixture-run record, or make the catalog omit revision/time and reference the generated evidence artifact. Add a verifier assertion that every compiled row's revision, build, timestamp, and result agree with the current evidence record before publishing it.

#### WR-04 (WARNING): The authoritative Phase 22 gate substitutes a stale document for live Phase 17-21 regressions

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.planning/chromium/verify-phase-22.sh:145-174`

**Related:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/.planning/chromium/verify-phase-22.sh:330-340`

**Issue:** The script runs only the Phase 21 Node cohort and then declares every Phase 17-21 native, renderer, and browser regression passed by grepping fixed strings from the old `21-VERIFICATION.md`. A stale or copied document cannot detect a regression introduced by Phase 22, so the authoritative closeout can print a green “Phase 17-21 frozen regression record” without executing any of those binaries against the reviewed source.

**Fix:** Invoke the live Phase 21 authoritative regression script (or its exact native/renderer/browser commands) at the reviewed head, validate fresh list/run logs and exact counts, and fail on retries, skips, or stale log timestamps. Historical verification text may remain provenance, but must not satisfy the current regression gate.

---

_Reviewed: 2026-08-10T06:36:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
