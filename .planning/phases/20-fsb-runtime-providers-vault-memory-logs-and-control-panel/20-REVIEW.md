---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
reviewed: 2026-07-20T17:08:18Z
depth: standard
files_reviewed: 92
files_reviewed_list:
  - .context/chromium/src/chrome/browser/BUILD.gn
  - .context/chromium/src/chrome/browser/prefs/BUILD.gn
  - .context/chromium/src/chrome/browser/prefs/browser_prefs.cc
  - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_browsertest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_mcp_integration_browsertest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_memory_store_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_factory.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_test_bootstrap_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_tool_contract.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_tool_contract.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store_unittest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_confirmation_browsertest.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc
  - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.h
  - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service_unittest.cc
  - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
  - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
  - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
  - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
  - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
  - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
  - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h
  - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.cc
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_tab_control_web_ui.cc
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
  - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
  - .context/chromium/src/chrome/test/BUILD.gn
  - .context/chromium/src/chrome/test/data/prometheus/runtime/runtime_eval_cases.json
  - .context/chromium/src/tools/metrics/histograms/metadata/page/histograms.xml
  - .context/chromium/src/tools/metrics/histograms/metadata/ui/histograms.xml
  - .planning/chromium/verify-phase-20.sh
  - .planning/chromium/verify-prometheus-webui-resources.sh
  - README.md
  - tools/prometheus-mcp/smoke-browser.sh
  - tools/prometheus-mcp/src/catalog.mjs
  - tools/prometheus-mcp/src/schema.mjs
  - tools/prometheus-mcp/src/tool-handler.mjs
  - tools/prometheus-mcp/test/catalog.test.mjs
  - tools/prometheus-mcp/test/diagnostics.test.mjs
  - tools/prometheus-mcp/test/errors.test.mjs
  - tools/prometheus-mcp/test/fixture-server.mjs
  - tools/prometheus-mcp/test/smoke-client.mjs
  - tools/prometheus-mcp/test/smoke.test.mjs
  - tools/prometheus-mcp/test/tools.test.mjs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-07-20T17:08:18Z
**Depth:** standard
**Files Reviewed:** 92
**Status:** issues_found

## Summary

Reviewed the current contents of all 78 Chromium source, configuration, resource, data, and test files in `460caac2f9e7deecd9fa6294c41d13e5a6dd6115..c5453efdc54ea313cb5bc08c84ed09a78a83f8fd` and all 14 root executable/product files through `e8e7f7824a9c702f0d1ad842739a56f6631199dd`. The iteration-2 remediation changed three nested runtime files and the root Phase 20 verifier inside that stable 92-file scope.

WR-09 is closed: all 52 exported patches now require stable body identity with their corresponding commits, and the verifier proves that a valid, applicable mutation is rejected. WR-08 is closed for the direct side-panel principal teardown exercised by the new test, but the new live-session structure remains disconnected from real MCP close and expiry events.

The review found one Critical authorization defect and one Warning-level lifecycle defect. In combination, closing or expiring an MCP session does not cancel its runtime task, and a retryable first-provider failure can issue a new fallback request containing the retained raw prompt without revalidating that session or current policy.

## Narrative Findings (AI reviewer)

The findings below are based on production call chains, not the passing test result alone. Planning prose, summaries, review history, and patch-mail bodies were used only as intent and provenance context. The executable root verification scripts remain part of the explicitly supplied product-closeout scope.

## Critical Issues

### CR-02: Automatic fallback dispatches after authority revocation

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:826-858`

**Issue:** `OnAutomaticProviderTurnComplete()` handles a retryable initial-provider failure before reaching `OnProviderTurnComplete()`. It refreshes provider metadata and directly invokes the next provider, reusing the retained `ProviderTurnRequest` and its raw `user_text`, but it does not call `ValidateAuthority()` or re-read the current runtime policy and limits. The authority check occurs only after the fallback branch is skipped or the fallback itself completes (`:1267-1277`). This differs from the manual tool-continuation chain, which validates authority and policy before evaluating its retry branch (`:1098-1105`).

The omission is reachable through normal production behavior: explicit MCP close removes the Agent session but does not notify the runtime (WR-10 below), and session expiry can likewise occur while a provider request is in flight. If provider A then returns a retryable network/server failure, the runtime sends the prompt to provider B after the browser-issued authority has been revoked.

**Impact:** A closed or expired session can initiate a new external provider request, disclose the retained prompt to a second provider, and incur work or cost after revocation. This is an authorization-boundary bypass, even though later tool dispatch is revalidated.

**Fix:** Route every provider invocation, including initial retry/fallback, through one guarded advance function that reads current policy, enforces current turn/token/duration limits, and validates the task's Agent session immediately before transport dispatch. On revocation, cancel/finish the task and retire its runtime session registration without invoking another provider. Add a deferred auto-start test that invalidates the session and tightens policy before completing provider A with a retryable failure; assert exactly one provider request, no fallback prompt transmission, provider cancellation/terminal state, and exactly-once completion.

## Warnings

### WR-10: MCP close and expiry bypass runtime session-loss cleanup

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:1921-1927`

**Issue:** Successful task admission registers its Agent session in `PrometheusRuntimeProfileService::active_sessions_` (`prometheus_runtime_profile_service.cc:675-676`), and `HandleAgentSessionLost()` is the method that cancels matching tasks, retires principals, and erases that registration (`:2228-2240`). No production code calls it. Explicit gateway close only calls `PrometheusAgentProfileService::CloseSession()` and erases gateway discovery/task trackers and the binding (`prometheus_agent_gateway.cc:1921-1927`). Gateway shutdown and pruning have the same disconnect (`:955-967` and `:1114-1127`), while expired Agent sessions only release AgentService ownership (`prometheus_agent_profile_service.cc:163-166`).

The new regression invokes `HandleAgentSessionLost()` manually after principal teardown, so it proves duplicate handling inside the runtime but not integration with the real close/expiry producers.

**Impact:** Runtime tasks and in-flight provider operations are not synchronously cancelled when their MCP authority closes or expires. Each accepted then externally closed/expired session can also remain in `active_sessions_` for the profile lifetime, recreating unbounded stale bookkeeping outside the direct side-panel path fixed by WR-08. The delayed cancellation also makes CR-02 reachable through the public session-close route.

**Fix:** Centralize Agent-session lifecycle notification in `PrometheusAgentProfileService` or add an observer that informs `PrometheusRuntimeProfileService` on explicit close, expiry, gateway pruning, and shutdown. Separate “session already closed” cleanup from “runtime owns the close” so cancellation and active-registration erasure occur exactly once without double-closing AgentService state. Add a browser integration test that creates an MCP session, submits a deferred provider task, closes and separately expires the session, and asserts immediate provider cancellation, terminal task state, zero runtime live registrations, and bounded behavior across churn beyond the retained-task limit.

## Remediation Re-review

| Finding | Result | Current evidence |
|---|---|---|
| Prior CR-01 vault metadata restart durability | Closed | The versioned bounded catalog persists and reloads metadata, reconciles secrets, preserves unrelated pref data, and has restart/use/delete/monotonic-ID/corruption coverage. |
| Prior WR-01 task execution disconnect | Closed, with CR-02 newly found | Production admission starts the durable provider/tool loop. The new review found that its initial fallback branch alone bypasses resume revalidation. |
| Prior WR-02 generated schema rejection | Closed | The shared nine-tool contract emits closed schemas accepted by the codec. |
| Prior WR-03 queued-to-terminal persistence | Closed | Start advances the durable store to running and propagates its generation before terminal completion. |
| Prior WR-04 provider argument validation | Closed | Recursive schema validation precedes `ValidatedToolCall`, with a second typed runtime parse. |
| Prior WR-05 asynchronous MCP discovery | Closed | Operation IDs, caller/session ownership, polling, and terminal cleanup are connected and bounded. |
| Prior WR-06 unbounded bookkeeping | Partially closed | Task, discovery, gateway-owner, replay, and audit collections are bounded. Runtime live-session cleanup remains disconnected for MCP close/expiry, reported as WR-10. |
| Prior WR-07 agent-cap boundary | Closed | Effective policy updates the registry admission cap without disabling existing sessions. |
| Prior WR-08 released-session tombstones | Partially closed | Direct principal teardown now erases unique live IDs before invoking close/release. Accepted MCP session registrations do not receive real close/expiry notification, so the broader lifetime-retention issue remains as WR-10. Fix `c5453efd` / patch `0052`. |
| Prior WR-09 patch-content identity | Closed | Every pair is stable-ID compared, malformed/multiple identities fail closed, and an applicable mutated patch is required to be rejected. Fix `e8e7f782`. |

## False Positives Rejected

- **WR-09 mutation gate:** The self-test mutation remains a syntactically valid patch and applies to the claimed commit parent through an isolated index before identity rejection. It is not a test that passes merely because the mutation is malformed.
- **Current patch ledger:** All 52 current patch/commit pairs pass exact stable-ID comparison. No present patch corruption was found.
- **Direct side-panel churn:** Unique side-panel principal creation and teardown now keeps runtime live-session bookkeeping at one and returns it to zero. WR-10 concerns production MCP close/expiry integration, not that corrected path.
- **Late provider success:** Normal non-retry completion reaches `ValidateAuthority()` before result/tool processing. CR-02 is limited to the earlier automatic retry branch.
- **Aggregate test closure:** The aggregate `prometheus_unittests` edge remains explicitly not run because of its unrelated component-build dependency closure. It is not represented as a passing gate or a Phase 20 finding.
- **Intentional external denials:** MCP/provider secret mutation and vault entry remain fail-closed behind local UI or native confirmation; these denials are required boundaries.

## Scope and Patch Integrity

- Root HEAD matched `e8e7f7824a9c702f0d1ad842739a56f6631199dd`. Before this report was overwritten, the root worktree contained only the existing current review modification and the preserved `20-REVIEW*.iter2/iter3.md` and `20-REVIEW-FIX*.md` artifacts; no product file was modified.
- Nested Chromium HEAD matched `c5453efdc54ea313cb5bc08c84ed09a78a83f8fd`, the exact baseline is its ancestor, and the nested worktree was clean.
- The nested range contains exactly 52 commits and changes exactly the same 78 scoped nested files. The root product/executable scope remains the same 14 paths.
- The 52 ordered patches are non-empty, source-only, have the exact corresponding `From` commit, and have matching stable patch IDs. Patch `0052` has the recorded SHA-256 `e9b8285847f4c74bf9ea85f61083de7955774f1f184ffdb9dc267b05194be7eb`.
- Planning specifications, summaries, evidence, prior review/fix artifacts, and patch-mail bodies were inspected without being counted as source. Only the two explicitly scoped executable `.planning/chromium/*.sh` gates are included in the 92-file count.

## Verification

- Independently ran `bash .planning/chromium/verify-phase-20.sh --patches-only`: all 52 real identities passed and the applicable mutation was rejected.
- Independently reran the root MCP suite: 75 of 75 Node tests passed with zero failures, cancellations, skips, or todos.
- Shell syntax checks passed for both root verification scripts and the built-browser smoke script; `node --check` passed for the reviewed JavaScript modules and tests.
- `git diff --check` passed for the exact 78-file nested range and exact 14 root executable/product paths.
- Current authoritative full-gate evidence records 203 Phase 20 native tests, 24 content/renderer tests, 84 native regressions, 36 Phase 20 browser tests, 83 browser regressions, 75 Node tests, passing built-app smoke, 52 stable patch identities, valid-mutation rejection, and byte-identical reviewed build metadata.
- Passing tests do not cover automatic fallback after authority loss or an accepted MCP runtime task followed by public close/expiry; the existing session-churn test does not submit runtime work.

## Residual Risks

Human UAT remains recorded as not run, and the aggregate `prometheus_unittests` target remains unrun for the documented unrelated component-build link limitation. Those gaps reduce independent visual and aggregate-link confidence but do not account for the two source findings above.

---

_Reviewed: 2026-07-20T17:08:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
