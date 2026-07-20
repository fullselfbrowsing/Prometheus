---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
reviewed: 2026-07-19T03:29:55Z
depth: standard
files_reviewed: 89
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
  warning: 7
  info: 0
  total: 8
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-07-19T03:29:55Z
**Depth:** standard
**Files Reviewed:** 89
**Status:** issues_found

## Summary

Reviewed all 75 changed Chromium source, configuration, resource, data, and test files in the exact nested range `460caac2f9e7deecd9fa6294c41d13e5a6dd6115..5beb75dd920d020ba95f7c866f466167f085ff73`, plus all 14 root executable/product files changed in `b301f4f0e6371a96d896222f9fcc03843153c21b..42d3af90dd49dd4478d683f7a69784baba057826`. The review traced the runtime submission, provider, tool dispatch, task persistence, MCP gateway, vault, session-cap, memory, WebUI, and shutdown call chains.

The implementation has one Critical data-durability defect and seven Warning-level correctness or boundedness defects. The principal execution path admits tasks but never starts them; several latent provider-loop defects would then prevent successful execution even if a starter were added. Vault metadata is not durable despite its encrypted secret payload being persisted.

The phase plans, summaries, specifications, validation/verification evidence, preservation contract, and 42-patch ledger were inspected as review context and fidelity evidence. They are not counted again as source files. All 42 patches are ordered, non-empty, source-only, identify the exact corresponding commits, and have exact stable patch-content identity with those commits.

## Narrative Findings (AI reviewer)

The findings below are limited to behavior proven by current production call chains and persisted-state rules. Test-only seams were used to understand coverage but not treated as evidence that an otherwise disconnected production path works.

## Critical Issues

### CR-01: Vault metadata is lost on every browser restart

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc:345`

**Issue:** `CreateMetadata()` only inserts into the process-local `metadata_` map. The constructor at line 301 does not receive or hydrate from `PrefService`, and the only backing fields are the map and `next_metadata_id_` counter in `prometheus_vault_service.h:256-257`. In contrast, `PrometheusSecretStore` persists the encrypted payload keyed by the vault binding. Restarting the profile therefore recreates an empty vault catalog and resets ID generation while leaving encrypted ciphertext behind. Existing entries become undiscoverable and newly created IDs can reuse identifiers associated with orphaned secret records.

**Impact:** A normal browser restart makes saved vault entries inaccessible and risks confusing or replacing an orphaned encrypted binding. This is user-visible durable-data loss, not merely a missing convenience cache.

**Fix:** Store a versioned, bounded vault metadata catalog and stable next-ID value in profile preferences; hydrate and validate it in the service constructor; persist create/edit/delete mutations together with secret-store changes; and reconcile corrupt or orphaned records fail-closed. Add restart tests that create metadata plus a secret, reconstruct both services from the same prefs, and verify listing, use, deletion, and subsequent ID allocation.

## Warnings

### WR-01: Admitted runtime tasks never enter the execution loop

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:712`

**Issue:** `SubmitTask()` persists a queued task, inserts it into `tasks_`, and immediately returns. There is no production call that transitions the task to running or invokes a provider. Both the side-panel adapter and the MCP gateway stop after `SubmitTask()`, and `DispatchTool()` has no production caller. Even the provider completion branch at lines 1105-1120 returns a tool call without converting its arguments into a browser-owned route or continuing the bounded loop. The external integration browser test codifies the disconnected behavior by expecting `run_task` to remain queued, while provider tests exercise transport in isolation.

**Impact:** A task accepted through either user-facing surface remains queued indefinitely until cancellation or shutdown. Provider execution and browser tool use are unreachable in the shipped path.

**Fix:** Add a service-owned start/advance state machine invoked after durable admission. It must transition the persisted task to running, issue the initial provider request, validate and dispatch typed browser-owned tool calls, feed bounded tool results back to the provider, enforce generation/call/token/time caps, and finish exactly once. Add an end-to-end side-panel and MCP test that observes a real task progress from queued to a terminal success through the production adapters.

### WR-02: The generated provider tool schema is rejected by the provider codec

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:886`

**Issue:** The runtime creates a tool schema containing only `{ "type": "object" }`. `IsValidToolSchema()` in `prometheus_provider_codec.cc:95-103` explicitly requires `additionalProperties` to be `false`, so `EncodeRequest()` rejects this request before any provider network operation can begin. No production tool properties or required fields are supplied either.

**Impact:** Once the disconnected execution starter is repaired, every provider turn produced by `DispatchTool()` still fails locally as an invalid request rather than reaching the configured provider.

**Fix:** Define one closed schema per safe browser tool with explicit `properties`, `required`, and `additionalProperties: false`. Share those definitions with the typed dispatch parser so the advertised and enforced contracts cannot drift, and add a real transport test using the exact request produced by the runtime service.

### WR-03: Successful completion is persisted directly from the queued state

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:2182`

**Issue:** Provider and tool completions select `RuntimeTaskState::kSucceeded` at lines 2143-2148 and call the owned store's `FinishTaskOnce()` without first transitioning the stored task to running. The legal transition table in `prometheus_runtime_types.cc:269-277` deliberately permits `queued -> running` but not `queued -> succeeded`. Updating only the service's in-memory snapshot to running does not advance the store generation or persisted state. Unit tests using hooks without an owned store miss this failure.

**Impact:** A successful provider result is rejected as an invalid store mutation, leaving the durable task queued and preventing exactly-once success from being recorded.

**Fix:** Transition the owned store from queued to running before execution begins and copy the returned generation into the service record. Every later waiting/running/terminal transition must use the current store generation. Add a production-service test with real prefs and an owned store that drives provider completion and verifies the persisted terminal snapshot after service reconstruction.

### WR-04: Provider tool arguments are labeled validated without schema validation

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.cc:323`

**Issue:** `SetToolCall()` checks the call ID, advertised tool name, JSON serializability, and byte bound, then constructs `ValidatedToolCall`. It never compares `arguments` with the advertised closed schema: required properties, extra properties, value types, and nested bounds are all unchecked. `OnProviderTurnComplete()` later checks only that the name maps to a known safe tool.

**Impact:** A provider can return structurally invalid or over-permissive arguments that cross the provider trust boundary as a supposedly validated call. Once dispatch is connected, this can cause inconsistent route errors or allow future dispatchers to rely on a false validation guarantee.

**Fix:** Validate arguments against the exact advertised closed schema before constructing `ValidatedToolCall`, or parse directly into each browser route's typed parameter object with strict unknown-field rejection. Cover missing required fields, extra fields, wrong scalar types, oversized nested values, and valid boundary cases.

### WR-05: Asynchronous model discovery cannot be completed through MCP

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc:1090`

**Issue:** `DiscoverModels()` allocates an `operation_id` and stores asynchronous completion state in `discoveries_`, but the gateway response copies only `models` and `pending`. It drops the operation ID, and the MCP route catalog provides no status route that calls `GetDiscovery()`. Real URL loader discovery is asynchronous, so the initial gateway response commonly contains an empty list with `pending: true`; repeating the request creates a different operation instead of retrieving the completed one. The control-panel adapter does preserve and poll the operation ID, demonstrating the missing gateway half.

**Impact:** MCP clients cannot retrieve discovered models from an asynchronous provider and can only generate abandoned discovery records.

**Fix:** Either keep the HTTP response open within a bounded request deadline until discovery completes, or return the bounded operation ID and add an authenticated, caller-scoped discovery-status route. Test the gateway against an asynchronous fake URL loader and prove the client can retrieve the completed list without creating a second discovery.

### WR-06: Process-lifetime bookkeeping bypasses the runtime's bounded stores

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:700`

**Issue:** Every admitted task is retained in `tasks_` and every discovery in `discoveries_` for the life of the profile service; neither collection has an erase or cap path. This is independent of the persisted store's bounded eviction at `prometheus_runtime_store.cc:624-629`. The gateway likewise retains every task owner at `prometheus_agent_gateway.cc:988`, and confirmed-vault replay keys and audit records accumulate at `prometheus_agent_service.cc:537` and `:705`. Shutdown clears some collections, but ordinary terminal completion, task-store eviction, discovery retrieval, session closure, and audit rollover do not.

**Impact:** A long-lived authenticated client can make profile-owned state grow without bound and retain stale task/caller/replay bookkeeping after the corresponding bounded product records are gone. This violates the phase's bounded-store contract and eventually degrades a browser process that is intended to remain open for long periods.

**Fix:** Couple terminal task cleanup to persisted-store eviction while retaining only the bounded history needed by the UI; cap or expire completed discoveries; remove owner records on terminal/eviction/session closure; and use bounded replay/audit structures with explicit retention windows. Add stress tests that exceed every configured bound and assert stable collection sizes and correct behavior for retained entries.

### WR-07: `max_active_agents` blocks existing agents instead of new session admission

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc:2085`

**Issue:** `ValidateAuthority()` applies `EvaluateRuntimeAgentAdmission()` to every request and rejects when the current active-session count is greater than or equal to the configured cap. That means reaching the cap makes all already admitted agents unable to run runtime operations. Meanwhile, saving the policy at line 1710 only writes prefs; production code never calls `AgentSessionRegistry::SetMaxActiveAgents()`. `PrometheusAgentProfileService` constructs its registry with a separate default at `prometheus_agent_profile_service.cc:28-44`, so a lowered runtime cap does not reject new session creation at the actual admission boundary.

**Impact:** At the configured cap, valid existing agents are disabled; after lowering the setting, excess new sessions can still be created. The control panel therefore implements the opposite of the documented "reject only new admission without evicting active sessions" behavior.

**Fix:** Add a production setter on `PrometheusAgentProfileService` that forwards the clamped effective policy to `AgentSessionRegistry::SetMaxActiveAgents()`, invoke it during profile-service startup and after policy changes, and enforce the cap only in `CreateSession()`. Remove the active-count rejection from authority validation so existing valid sessions continue until closed or expired. Add gateway tests for creating up to the cap, rejecting the next session, lowering below the current count without eviction, preserving existing-session access, and admitting new work again after enough sessions close.

## False Positives Rejected

- **Aggregate native-test linker limitation:** The inability to produce or run the aggregate `prometheus_unittests` binary is the recorded unrelated linker limitation, not a Phase 20 defect or a passing result. The review relied on the authoritative targeted native/content evidence instead.
- **Intentional fail-closed security boundaries:** External MCP/provider mutation and secret-entry routes deliberately return local-UI/native-confirmation-required failures. Vault insertion revalidates the exact browser/frame/document binding after native confirmation, and provider secrets are not serialized through MCP. These denials are required security behavior, not missing functionality.
- **Provider redirect and timer lifetime concerns:** Provider redirects are explicitly rejected, and timer callbacks using `base::Unretained` are stopped by the owning shutdown/destructor paths on the same sequence. No reachable use-after-free was established.
- **Safe-title heuristics:** Titles are bounded UTF-8 metadata and WebUI writes them through `textContent`; no unsafe HTML or command sink was found. A stricter cosmetic title regex is not required by the current contract and was not reported.
- **Patch 0016 mail subject formatting:** Patch 0016 retains an older `[PATCH 16/16]` subject marker rather than the normalized `[PATCH]` marker. Its `From` commit identity and stable patch content match the corresponding commit exactly, so this presentation-only difference is not a source-fidelity defect.
- **Context-only whitespace:** Full-root `diff --check` observations are confined to archived mail-patch bodies and Markdown hard-breaks in context documents. The exact executable/product path set and the nested Chromium source range both pass `diff --check`.

## Scope and Patch Integrity

- Root pre-review state was clean at `42d3af90dd49dd4478d683f7a69784baba057826` on branch `chromium`; the authoritative root range contains 73 commits.
- Nested Chromium pre-review state was clean at the required head `5beb75dd920d020ba95f7c866f466167f085ff73` on branch `prometheus/phase-14-assets`; the authoritative nested range contains exactly 42 commits and the base is its ancestor.
- The 42 patch files are ordered, non-empty, and limited to the exact 75-file nested source/configuration/resource/data/test scope. Each patch's `From` SHA matches its corresponding commit, and every stable patch ID matches that commit's patch ID.
- Planning documents, summaries, verification evidence, preservation evidence, and the patch ledger were inspected for intended behavior and provenance without inflating `files_reviewed` or duplicating byte-equivalent patch bodies as source review entries.

## Verification

- Existing authoritative evidence records 294 targeted native/content unit tests, 36 Phase 20 browser tests, 82 browser regression tests, 74 Node tests, and passing built-app smoke, security, preservation, and 42-patch gates.
- Independently re-ran the root MCP Node suite: 74 of 74 tests passed.
- `git -C .context/chromium/src diff --check 460caac2f9e7deecd9fa6294c41d13e5a6dd6115..5beb75dd920d020ba95f7c866f466167f085ff73` passed.
- Root `git diff --check` passed when restricted to the exact 14 executable/product paths.
- JavaScript syntax, runtime JSON parsing, histogram XML parsing, shell syntax, and shell lint checks passed for the reviewed changed files.
- Static test inventory found no disabled, skipped, or assertion-free Phase 20 tests. The tests that use fake hooks were not allowed to substitute for missing production call-chain coverage in the findings above.

---

_Reviewed: 2026-07-19T03:29:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
