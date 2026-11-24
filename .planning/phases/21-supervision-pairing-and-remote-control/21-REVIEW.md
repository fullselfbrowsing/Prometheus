---
phase: "21-supervision-pairing-and-remote-control"
status: "clean"
depth: "standard"
reviewed_at: "2026-07-26T10:59:55-05:00"
files_reviewed: 88
counts:
  blocker: 0
  critical: 0
  warning: 0
  info: 0
  total: 0
---

# Phase 21 Code Review

The bounded iteration-2 re-review is clean. All three iteration-1 blockers are
resolved in current source, their fixes preserve the surrounding authority and
lifecycle invariants, and the standard-depth pass found no new concrete
correctness, security, or code-quality issue in the authoritative 88-file
scope.

## Prior Finding Resolution

### CR-01 — Resolved: dirty captures are queued while a snapshot is in flight

- `PrometheusSupervisionCaptureHub::RequestCapture()` records both queued work
  and any queued forced-baseline requirement when a capture is already in
  flight.
- Capture completion snapshots and clears that queued state, processes the
  completed result, and starts the queued follow-up capture before evaluating
  diff waiters. Because the follow-up is already marked in flight,
  compatibility consumers cannot receive a false `kNoChange` result between
  the pre-mutation result and the queued capture.
- Intermediate authoritative diffs remain available in sequence, while
  dashboard and compatibility consumers retain independent cursors. Overflow
  state is ORed across coalesced requests and transferred only to the queued
  capture.
- Stop and document-epoch transitions clear both queue flags, so an obsolete
  capture cannot leak work into a replacement document.
- `DirtyAfterSnapshotStartsQueuesFollowUpCapture` models the original race
  directly: the first callback returns the pre-mutation baseline, both
  consumers remain blocked from a false no-change result, and the queued
  callback delivers the later mutation to both independent cursors.

### CR-02 — Resolved: destructive confirmations are generation-bound

- Every native control snapshot receives a fresh opaque
  `base::UnguessableToken` generation. Target and connected-row bindings retain
  that exact generation together with their weak tab, stable handle, dashboard
  session, and authority generation.
- Replace-pairing, revoke-session, and end-target messages carry the displayed
  snapshot generation. The WebUI accepts only the bounded 32-hex token shape,
  stores it with the pending dialog, and cancels the dialog without submitting
  when a newly rendered snapshot changes the generation.
- The browser message parser independently deserializes the token and enforces
  exact arity, ordinal bounds, and the required confirmation boolean.
- The concrete native runtime rejects an empty, forged, or stale generation
  before resolving an ordinal. Resolution then rechecks the bound generation,
  weak tab, stable handle, live tab membership, target eligibility, selected
  target, and dashboard authority freshness as applicable.
- Sending the operation result also builds a fresh snapshot, rotating the
  generation after an accepted or rejected attempt.
- `SupervisionRuntimeDestructiveActionsRejectStaleSnapshotGeneration`
  exercises tab and connected-row reordering for replace, revoke, and end, and
  proves each stale operation fails closed without affecting either the
  originally displayed row or the row newly occupying that ordinal.
  `ControlSupervisionActionsFocusAndStatePreservation` covers dialog
  cancellation and suppression of stale submissions for all three actions.

### CR-03 — Resolved: observation follows document-root lifecycle changes

- The Blink supplement now observes the `Document` node with child-list,
  attribute, character-data, and subtree coverage. Root insertion, root
  replacement, and later descendant mutations therefore remain within the
  same document-scoped observer.
- The renderer still sends only the bounded dirty/overflow enum over Mojo; no
  mutation content crosses the renderer boundary.
- Existing disable, disconnect, context-destruction, debounce, and overflow
  cleanup remains intact.
- `EnableBeforeDocumentElementCreationObservesLaterRoot` and
  `DocumentElementReplacementObservesNewRootMutations` cover both lifecycle
  edges in Blink. `DocumentElementReplacementKeepsRealCaptureLive` proves the
  replacement and a later descendant mutation each drive a real browser
  capture and deliver updated diffs.

## Standard-Depth Re-review

The exact scope contains 63,352 lines across the 88 requested files, with no
missing path. Sixteen scoped files changed after the iteration-1 review; those
changes are limited to the three remediations and the deterministic live-smoke
ordering/isolation updates. The remaining 72 files are unchanged from the
iteration-1 reviewed baseline and were rechecked for their interactions with
the new state.

The pass covered:

- supervision DTO validation, bounds, enum conversion, transport codecs,
  projection, diff generation, retained-history behavior, and per-consumer
  cursor ownership;
- profile-service lifecycle, viewer/controller authority, capture-hub
  ownership, long-poll completion, shutdown, and remote-action revalidation;
- gateway contracts, loopback request parsing, route dispatch, compatibility
  aliases, error sanitization, and MCP closed schemas;
- native control-row construction, tab identity/freshness checks, browser
  message parsing, WebUI normalization, dialog state, and focus preservation;
- renderer binding, document-scoped Mojo lifetime, mutation debounce/overflow,
  root lifecycle handling, and browser capture integration;
- runtime dialogs, tab supervision state/badge presentation, resource wiring,
  build targets, bootstrap boundaries, and live-smoke sequencing.

No evidence-backed issue remained after those checks.

## Validation

- Fresh `git diff --check` passed for all 16 in-scope files changed since the
  iteration-1 baseline.
- Fresh syntax checks passed for `prometheus_webui.js`, all scoped MCP
  JavaScript modules/tests, and `smoke-browser.sh`.
- Fresh Node TAP:
  `node --test tools/prometheus-mcp/test/catalog.test.mjs
  tools/prometheus-mcp/test/errors.test.mjs
  tools/prometheus-mcp/test/smoke.test.mjs` — 31/31 passed.
- Fresh focused content binary — 28/28 action-dispatcher, provider-transport,
  and supervision tab-state tests passed.
- Fresh direct browser execution passed
  `SupervisionRuntimeDestructiveActionsRejectStaleSnapshotGeneration` and
  `DocumentElementReplacementKeepsRealCaptureLive`.
- The current-source focused browser evidence records
  `ControlSupervisionActionsFocusAndStatePreservation` passing, including all
  stale-dialog assertions. A raw direct invocation selected the intentionally
  restored framework resource pack rather than the focused current-source
  pack and failed its precondition because that older pack lacked the callback;
  it did not exercise the reviewed JavaScript and is not a source failure. No
  resource was modified during this review.
- Existing full-verifier evidence was inspected only as corroboration: it
  records the new queued-capture unit test, both new Blink lifecycle tests,
  the stale-generation browser test, the stale-dialog browser test, and the
  real root-replacement capture test passing in their current-source cohorts.

## Findings

None.

## Review Scope

The re-review was limited to these 88 authoritative files:

1. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.h`
2. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types.cc`
3. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_types_unittest.cc`
4. `.context/chromium/src/chrome/browser/prometheus/BUILD.gn`
5. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.h`
6. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec.cc`
7. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_transport_codec_unittest.cc`
8. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.h`
9. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection.cc`
10. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_projection_unittest.cc`
11. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.h`
12. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff.cc`
13. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_diff_unittest.cc`
14. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h`
15. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc`
16. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc`
17. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h`
18. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc`
19. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h`
20. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc`
21. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc`
22. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_unittest.cc`
23. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.h`
24. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.cc`
25. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h`
26. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc`
27. `.context/chromium/src/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom`
28. `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.h`
29. `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.cc`
30. `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement_unittest.cc`
31. `.context/chromium/src/third_party/blink/public/mojom/BUILD.gn`
32. `.context/chromium/src/third_party/blink/renderer/modules/content_extraction/BUILD.gn`
33. `.context/chromium/src/third_party/blink/renderer/modules/BUILD.gn`
34. `.context/chromium/src/third_party/blink/renderer/modules/modules_initializer.cc`
35. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.h`
36. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc`
37. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_unittest.cc`
38. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc`
39. `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn`
40. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.h`
41. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc`
42. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h`
43. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc`
44. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc`
45. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc`
46. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec_unittest.cc`
47. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h`
48. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc`
49. `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc`
50. `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc`
51. `.context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc`
52. `tools/prometheus-mcp/src/catalog.mjs`
53. `tools/prometheus-mcp/src/tool-handler.mjs`
54. `tools/prometheus-mcp/test/catalog.test.mjs`
55. `tools/prometheus-mcp/test/errors.test.mjs`
56. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.h`
57. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.cc`
58. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller_unittest.cc`
59. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_confirmation_browsertest.cc`
60. `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h`
61. `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc`
62. `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h`
63. `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc`
64. `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_tab_supervision_badge_browsertest.cc`
65. `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.h`
66. `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.cc`
67. `.context/chromium/src/chrome/browser/ui/views/tabs/tab.h`
68. `.context/chromium/src/chrome/browser/ui/views/tabs/tab.cc`
69. `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_compact_chrome_browsertest.cc`
70. `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h`
71. `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc`
72. `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h`
73. `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc`
74. `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc`
75. `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html`
76. `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js`
77. `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css`
78. `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html`
79. `.context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc`
80. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.h`
81. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.cc`
82. `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap_unittest.cc`
83. `.context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.h`
84. `.context/chromium/src/chrome/browser/prometheus/prometheus_mcp_integration_browsertest.cc`
85. `tools/prometheus-mcp/smoke-browser.sh`
86. `tools/prometheus-mcp/test/fixture-server.mjs`
87. `tools/prometheus-mcp/test/smoke-client.mjs`
88. `tools/prometheus-mcp/test/smoke.test.mjs`
