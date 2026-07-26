---
phase: "21-supervision-pairing-and-remote-control"
status: "issues_found"
depth: "standard"
reviewed_at: "2026-07-26"
files_reviewed: 88
counts:
  blocker: 3
  critical: 0
  warning: 0
  info: 0
  total: 3
---

# Phase 21 Code Review

Phase 21 has three release-blocking correctness defects. Two can cause an
authorized supervision operation to use stale or incorrect state, and one can
leave the renderer-to-browser capture stream stale indefinitely.

## Narrative Findings (AI reviewer)

### CR-01 — Dirty notifications are lost while a capture is in flight (Blocker)

**Evidence**

- `prometheus_supervision_document_supplement.cc:140-175` forwards renderer
  mutation notifications to the browser capture hub.
- `prometheus_supervision_capture_hub.cc:778-789` handles a dirty frame by
  calling `RequestCapture(overflow)`.
- `prometheus_supervision_capture_hub.cc:830-857` sets
  `force_baseline_after_capture_ |= force_baseline`, then returns immediately
  when `capture_in_flight_` is true. An ordinary dirty notification passes
  `false`, so it leaves no record that another capture is required. Even the
  overflow bit is folded into the already-running capture rather than queued
  for a subsequent snapshot.
- `prometheus_supervision_capture_hub.cc:945-1020` clears the in-flight state
  and processes the completed result, but never starts a follow-up capture for
  mutations received after the completed snapshot was taken.
- `prometheus_supervision_capture_hub_unittest.cc:124-146` sends two dirty
  notifications while one capture is pending, but completes that pending
  capture with a synthetic already-changed baseline. It does not model the
  production race in which the second mutation occurs after the asynchronous
  snapshot has already been taken.

**Impact**

A DOM mutation that occurs after snapshot collection begins but before its
callback completes can be omitted from both the supervision stream and action
authority. If no later mutation occurs, the session remains stale
indefinitely.

**Required remediation**

Record a separate `capture_requested_while_in_flight_`/dirty flag. After the
current callback finishes, immediately request another capture when that flag
is set, carrying overflow/forced-baseline state into the new capture. Add a
test whose first result represents the pre-mutation snapshot and whose queued
follow-up result contains the mutation.

### CR-02 — Destructive confirmations can execute against a different row (Blocker)

**Evidence**

- `prometheus_webui.js:2151-2166` stores a pending revoke as
  `{kind: 'revoke', ordinal, trigger}` while showing the current row label.
- `prometheus_webui.js:2174-2189` likewise stores only the selected target
  ordinal for end-supervision confirmation while showing the current target
  title.
- `prometheus_webui.js:2971-3008` submits the stored ordinal when the user
  confirms replace, revoke, or end.
- `prometheus_webui.js:2504-2529` rerenders the control snapshot whenever a new
  snapshot arrives, but does not cancel the open dialog or rebind it to an
  immutable identity.
- `prometheus_browser_main_extra_parts.cc:1081-1110` rebuilds the sanitized
  snapshot for each request.
- `prometheus_browser_main_extra_parts.cc:1746-1753` clears both ordinal-binding
  vectors and increments the generation on every rebuild.
- Target bindings are rebuilt from current tab order at
  `prometheus_browser_main_extra_parts.cc:1765-1806`. Connected rows and their
  bindings are reordered after sorting at
  `prometheus_browser_main_extra_parts.cc:1892-1903`.
- `prometheus_browser_main_extra_parts.cc:1682-1720` resolves only the submitted
  ordinal against the current vectors. Freshness checks therefore validate
  whichever row currently occupies that position, not the row named in the
  confirmation dialog. The destructive handlers use that current binding at
  `prometheus_browser_main_extra_parts.cc:1486-1576`.
- `prometheus_web_ui_browsertest.cc:5528-5589` exercises confirmation dialogs
  without injecting a snapshot reorder while a dialog is open.

**Impact**

For example, a user can open “Revoke Review console” for ordinal 1, receive a
snapshot that moves another session into ordinal 1, and then revoke the other
session by confirming the unchanged dialog. A tab reorder creates the same
failure mode for end-supervision and can terminate control of the wrong tab.

**Required remediation**

Bind confirmation to immutable browser-side identity. At minimum, submit the
snapshot generation with the ordinal and reject confirmation after any
generation change. Prefer an opaque, one-use native confirmation binding to
the exact dashboard session or tab handle. Cancel or visibly refresh open
dialogs when their bound identity becomes invalid. Add browser tests that
reorder connected rows and tabs between opening and confirming each destructive
dialog.

### CR-03 — The renderer stops observing after root creation or replacement (Blocker)

**Evidence**

- `prometheus_supervision_document_supplement.cc:102-113` calls
  `ObserveDocument()` once when supervision is enabled.
- `prometheus_supervision_document_supplement.cc:124-137` returns when
  `documentElement()` is absent; otherwise it observes only that current root
  element. There is no lifecycle retry and no reattachment path for a later
  root.
- `prometheus_supervision_document_supplement_unittest.cc:52-55` creates an
  HTML/body root before enabling supervision. The supplement tests mutate
  inside that root and do not cover root creation or replacement.
- `prometheus_supervision_capture_hub.cc:687-722` starts a document epoch,
  binds current frames, and requests the initial capture;
  `prometheus_supervision_capture_hub.cc:735-775` performs frame binding; and
  the frame entry calls renderer `Enable()` at
  `prometheus_supervision_capture_hub.cc:155-172`.

**Impact**

If `Enable()` reaches a slowly constructed committed document before its root
exists, no observer is installed. If script later replaces
`document.documentElement`, the replacement occurs outside the old root and
subsequent mutations happen below an unobserved node. In either case, no dirty
notification requests a new capture, so an empty or obsolete capture can
remain authoritative indefinitely.

**Required remediation**

Observe the `Document` for root insertion/replacement, or use a document
lifecycle hook that reliably retries and reattaches to the current root. Add
tests for enable-before-root-creation and full `documentElement` replacement,
including proof that later mutations trigger a new browser capture.

## Validation performed

- `node --test tools/prometheus-mcp/test/catalog.test.mjs tools/prometheus-mcp/test/errors.test.mjs tools/prometheus-mcp/test/smoke.test.mjs`
  — 31/31 tests passed.
- `node --check` passed for `catalog.mjs`, `tool-handler.mjs`,
  `fixture-server.mjs`, `smoke-client.mjs`, and `smoke.test.mjs`.
- `bash -n tools/prometheus-mcp/smoke-browser.sh` passed.
- `git diff --check b0fc..HEAD` passed for the requested Phase 21 paths.
- A Chromium build and live browser smoke run were not performed during this
  standard-depth review.

## Review scope

The review was limited to the 88 explicitly requested files:

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
