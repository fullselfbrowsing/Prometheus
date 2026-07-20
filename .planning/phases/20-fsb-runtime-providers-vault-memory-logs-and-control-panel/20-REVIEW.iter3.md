---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
reviewed: 2026-07-20T16:02:47Z
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
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-07-20T16:02:47Z
**Depth:** standard
**Files Reviewed:** 92
**Status:** issues_found

## Summary

Reviewed all 78 changed Chromium source, configuration, resource, data, and test files in the exact nested range `460caac2f9e7deecd9fa6294c41d13e5a6dd6115..9c9d8d424c7d88b318807df77603afa8c7f2b8d7`, plus all 14 root executable/product files changed in `b301f4f0e6371a96d896222f9fcc03843153c21b..b376806c0668f861b93d14f09111583187374ffd`.

The previous Critical and six of seven previous Warnings are closed. The prior bounded-bookkeeping Warning is only partially closed: the fixed task, discovery, gateway-owner, replay, and audit structures are bounded, but released side-panel session identifiers still accumulate for the profile lifetime. A second Warning affects the authoritative patch verifier: it trusts the mail-patch `From` header and parseable diff shape without proving that the body is the claimed commit.

No Critical issues remain. The review found two Warning-level robustness defects.

## Narrative Findings (AI reviewer)

The findings below are based on current production call chains and executable verifier behavior. Planning prose, summaries, review history, and patch-mail bodies were used as context but were excluded as findings. The two root verification scripts are included because they are executable product-closeout gates in the explicitly supplied review scope.

## Critical Issues

None.

## Warnings

### WR-08: Released side-panel session tombstones grow for the profile lifetime

**File:** `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h:529`

**Issue:** `PrometheusRuntimeProfileService` stores every released Agent session ID in the unbounded `released_sessions_` set. Destroying a `LocalRuntimePrincipal` calls `ReleasePrincipal()` (`prometheus_runtime_profile_service.cc:305-308`), which calls `ReleaseSessionOnce()` (`:2577-2585`); that method inserts the ID and never removes it (`:2553-2564`). Session-loss and shutdown paths also insert through the same helper (`:2226-2238` and `:2336-2355`). The only erase occurs when a new principal receives the same ID (`:458-469`), but production creates every session with a new `base::UnguessableToken` (`prometheus_agent_session.cc:55-66`), so normal side-panel reopen cycles do not reclaim prior entries. Existing service tests conceal the growth by returning the constant fake ID `browser-issued-session` (`prometheus_runtime_profile_service_unittest.cc:112-123`).

**Impact:** Repeatedly opening and closing side panels leaves one stale opaque identifier per principal for as long as the profile service lives. This leaves the Phase 20 bounded-retention contract incomplete and permits process-owned bookkeeping to grow independently of the bounded runtime/task stores.

**Fix:** Make release idempotence local to the lifetime that can issue duplicate releases (for example, principal/session ownership state), or prune tombstones against a deliberately bounded retained-session structure. Add a production-shaped test whose session factory returns unique IDs, create and release more sessions than the selected bound, and assert both stable bookkeeping size and exactly-once close/ownership release.

### WR-09: The patch gate does not verify patch-content identity

**File:** `.planning/chromium/verify-phase-20.sh:442-471`

**Issue:** `verify_patches()` checks patch count and ordering, then accepts a patch when its first line claims the expected commit SHA, its paths do not match a build-artifact regex, and `git apply --stat` can parse it. The `From` line is ordinary editable text, and `--stat` neither compares the patch body with the commit nor checks out/apply-validates the claimed commit delta. A different parseable source diff can therefore retain the expected header and pass this authoritative one-to-one export gate.

**Impact:** A stale, truncated, or modified patch body can be reported as an exact export of its named commit. That weakens the preservation and offline-replay guarantee even though the current ledger is intact.

**Fix:** Compare stable patch identities for every pair, failing unless `git patch-id --stable < "$patch"` equals the stable patch ID of the corresponding commit diff (for example, `git show --pretty=format: --binary "$commit" | git patch-id --stable`). Keep the existing ordering and artifact checks, and optionally add `git apply --check` in a clean baseline worktree when replay applicability must also be proven.

## Remediation Re-review

| Prior finding | Result | Re-review evidence |
|---|---|---|
| CR-01 vault metadata restart durability | Closed | The vault loads a versioned, bounded pref catalog, reconciles secret records, persists create/update/delete/secret mutations, and preserves unrelated pref data. Restart, monotonic-ID, use/delete, and corrupt-orphan tests cover the path. Fix `707575f` / patch `0043`. |
| WR-01 admitted tasks never start | Closed | Production hooks enable auto-start; `SubmitTask()` calls `StartTask()`; the service transitions durable state to running and drives the bounded provider/tool loop. Test-only fixtures are the only callers that disable auto-start. Fix `e2918d9` / patch `0044`, with the queued-state fixture isolated in patch `0051`. |
| WR-02 generated provider schema rejected | Closed | The shared runtime tool contract emits nine closed schemas with explicit properties, required fields, and `additionalProperties: false`; the provider codec accepts that exact contract. Fix `e58b29b` / patch `0045`. |
| WR-03 completion persisted from queued | Closed | `StartTask()` advances the owned store from queued to running and propagates the new generation; terminal transitions use current durable state. Restart coverage verifies generation 2 and success. Fix `5f6fc3b` / patch `0046`. |
| WR-04 tool arguments not schema-validated | Closed | The provider codec recursively validates arguments against the advertised closed schema before constructing `ValidatedToolCall`, and the runtime performs a second typed parse at dispatch. Fix `e74b8d6` / patch `0047`. |
| WR-05 asynchronous discovery unreachable over MCP | Closed | The transport exposes mutually exclusive provider/operation IDs; the gateway preserves the operation ID, scopes polling ownership by session and caller, and erases terminal operations. The MCP catalog and smoke client expose and exercise polling. Fix `c8fe8ea` / patch `0048`. |
| WR-06 unbounded process bookkeeping | Partially closed | Task, discovery, gateway-owner, replay, and audit retention are now bounded and reconciled. The separate `released_sessions_` lifetime set remains unbounded, reported above as WR-08. Fix `405d955` / patch `0049`. |
| WR-07 agent cap enforced at wrong boundary | Closed | Effective prefs initialize the session registry cap, policy changes update it, and admission is enforced by `AgentSessionRegistry` without rejecting existing sessions at runtime authority validation. Fix `d36944b` / patch `0050`. |

Root-side remediation and final smoke refinements are present in `215919f`, `655b270`, and `b376806`.

## False Positives Rejected

- **Queued task fixture:** `SetAutoStartTasksForTesting(false)` is used only by two browser-test fixtures. The production constructor enables auto-start, so the old disconnected-execution finding is closed.
- **Tool-schema drift:** Schema generation and runtime parsing now share `prometheus_runtime_tool_contract.cc/.h`, and the provider codec validates nested values against the advertised schema. The former rejected-schema and unvalidated-arguments findings do not survive the current code.
- **Asynchronous discovery leakage:** Terminal polling removes both the underlying discovery and caller/session ownership record; pending ownership is scoped, and admission/retention is bounded. The former MCP discovery finding is closed.
- **Current patch corruption:** Independent stable patch-ID comparison confirms that all 51 current patch bodies exactly match their corresponding commits. WR-09 concerns what the executable gate proves, not a mismatch in the present ledger.
- **Aggregate test closure:** The aggregate `prometheus_unittests` binary remains recorded as not run because of the unrelated component-build link limitation. It is neither treated as a Phase 20 source defect nor represented as passing.
- **Intentional trust-boundary denials:** External MCP/provider mutation and secret-entry routes remain fail-closed behind local UI/native confirmation. These denials are required security behavior.

## Scope and Patch Integrity

- Root HEAD matched the required `b376806c0668f861b93d14f09111583187374ffd`. Before this report was written, the only root worktree entries were the three explicitly preserved untracked review artifacts: `20-REVIEW.iter2.md`, `20-REVIEW-FIX.iter2.md`, and `20-REVIEW-FIX.md`.
- Nested Chromium HEAD matched the required `9c9d8d424c7d88b318807df77603afa8c7f2b8d7`, the baseline `460caac2f9e7deecd9fa6294c41d13e5a6dd6115` is its ancestor, and the nested worktree was clean.
- The authoritative nested range contains 51 commits and 51 ordered patch files. Independent comparison confirmed every first-line commit identity and every stable patch ID, including final patch `0051`.
- Planning specifications, plans, summaries, verification evidence, preservation evidence, prior review artifacts, and patch-mail bodies were inspected for intent, remediation, and provenance without being counted as source. Only the two explicitly scoped executable `.planning/chromium/*.sh` gates are included in the 92 reviewed files.

## Verification

- Independently ran the root MCP suite: 75 of 75 Node tests passed with zero failures, cancellations, skips, or todos.
- Independently verified stable patch-content identity for all 51 nested commit/patch pairs.
- `git diff --check` passed for the exact 78-file nested range and for the exact 14 root executable/product paths.
- Shell syntax checks passed for both root verification scripts and the built-browser smoke script; `node --check` passed for the reviewed JavaScript modules and tests.
- Existing authoritative evidence records 202 Phase 20 native unit tests, 24 focused content/renderer unit tests, 84 native regression tests, 36 Phase 20 browser tests, 83 browser regression tests, 75 Node tests, and a passing built-app smoke run.
- Human UAT is still recorded as not run. The aggregate `prometheus_unittests` target is also not run for the documented unrelated component-build link-closure limitation.

## Residual Risks

The remaining human-UAT and aggregate-test gaps reduce independent end-user and aggregate-link confidence but do not establish additional source findings. The built-app smoke intentionally exercises submit/status/cancel against a delayed provider response; successful provider/tool-loop completion is instead covered by the focused native and browser corpus.

---

_Reviewed: 2026-07-20T16:02:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
