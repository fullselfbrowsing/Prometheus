---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
fixed_at: 2026-07-20T10:38:38-05:00
review_path: .planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-07-20T10:38:38-05:00
**Source review:** `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 8
- Fixed: 8
- Skipped: 0

## Fixed Issues

### CR-01: Vault metadata is lost on every browser restart

**Status:** fixed: requires human verification
**Files modified:** `prometheus_runtime_profile_service.cc`, `prometheus_vault_confirmation_browsertest.cc`, `prometheus_vault_service.cc`, `prometheus_vault_service.h`, `prometheus_vault_service_unittest.cc`
**Commits:** Chromium `707575f3c1a8743b0eeecb90a925b05e069edcbe`; root patch export `3118e910b995081632497dbf2e7864f4a67a5459`
**Applied fix:** Added a versioned, bounded profile-pref catalog for vault metadata and its next stable ID; hydrated and validated it on construction; persisted create, edit, and delete changes with secret-store rollback; and reconciled corrupt or orphaned records fail-closed. Restart tests cover listing, use, deletion, and non-reused ID allocation.
**Verification:** `PrometheusVaultServiceTest.*`, the Phase 20 native gate, and the vault confirmation browser fixtures pass in the exact closeout command.

### WR-01: Admitted runtime tasks never enter the execution loop

**Status:** fixed: requires human verification
**Files modified:** `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `e2918d9001150d8d6fae481c491fcee28e33a841`; root patch export `280e460eb51fe33b2617c252d9431d28f46261a8`
**Applied fix:** Connected durable task admission to a service-owned automatic provider/tool state machine. It moves admitted work to running, executes bounded provider turns and browser-owned tool calls, enforces turn/token/time limits, cancels in-flight work, and finishes exactly once. Production auto-start remains enabled; browser fixtures that specifically assert queued state use an explicit test-only seam.
**Verification:** Runtime profile unit coverage, production-adapter browser coverage, and the external built-app MCP smoke all pass. The live smoke observes a genuinely running task before exercising cancellation.

### WR-02: The generated provider tool schema is rejected by the provider codec

**Status:** fixed: requires human verification
**Files modified:** `BUILD.gn`, `prometheus_provider_transport_unittest.cc`, `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_tool_contract.cc`, `prometheus_runtime_tool_contract.h`
**Commits:** Chromium `e58b29b0e0602ab18cb881f03470dd7376559099`; root patch export `05f3165b79ad8214a1f8f70d60519d72ab9d1719`
**Applied fix:** Introduced one shared nine-tool contract that produces the exact closed provider schemas and parses the same bounded arguments for browser dispatch, removing the advertised/enforced schema drift.
**Verification:** Provider codec/transport tests, runtime profile tests, and the live fixture's exact nine-schema contract check pass.

### WR-03: Successful completion is persisted directly from the queued state

**Status:** fixed: requires human verification
**Files modified:** `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `5f6fc3b70b3e9ea43a9c7ecace368b8472baaf1a`; root patch export `86ff80a44c61893da192e4c3badd1a057346f2bb`
**Applied fix:** Persists the legal queued-to-running transition before execution and carries the current store generation through every later transition and exactly-once terminal write.
**Verification:** Owned-store reconstruction and completion tests pass within the 202/202 Phase 20 native gate.

### WR-04: Provider tool arguments are labeled validated without schema validation

**Status:** fixed: requires human verification
**Files modified:** `prometheus_provider_codec.cc`, `prometheus_provider_codec_unittest.cc`
**Commits:** Chromium `e74b8d647f4a6a03f5f50d733071560e466c9907`; root patch export `37ad20022b799656d045977d040edc9101148da3`
**Applied fix:** Validates returned tool-call arguments recursively against the advertised closed schema, including required and unknown fields, primitive types, numeric/string bounds, and prototype-key rejection, before constructing a validated call.
**Verification:** Valid/invalid provider argument matrices and the full provider codec suite pass.

### WR-05: Asynchronous model discovery cannot be completed through MCP

**Status:** fixed: requires human verification
**Files modified:** `prometheus_agent_gateway.cc`, `prometheus_agent_gateway.h`, `prometheus_agent_gateway_unittest.cc`, `prometheus_runtime_transport_codec.cc`, `prometheus_runtime_transport_codec.h`, `prometheus_runtime_transport_codec_unittest.cc`, `tools/prometheus-mcp/src/catalog.mjs`, `catalog.test.mjs`, `smoke-client.mjs`, `tools.test.mjs`
**Commits:** Chromium `c8fe8eac0477d4a2a6dd716aad728881a2b0484b`; root integration/export `01ecd8c8faa6162c737f9bf52d8c019d4adbf4d8`
**Applied fix:** Added a bounded discovery-operation identifier and polling form to the native route and MCP schema, preserving caller ownership while exposing pending, completed, and typed failure states without leaking provider internals.
**Verification:** Gateway/codec tests, browser MCP workflows, and Node catalog/tool/live-smoke coverage pass.

### WR-06: Process-lifetime bookkeeping bypasses the runtime's bounded stores

**Status:** fixed: requires human verification
**Files modified:** `prometheus_agent_gateway.cc`, `prometheus_agent_gateway.h`, `prometheus_agent_gateway_unittest.cc`, `prometheus_agent_service.cc`, `prometheus_agent_service.h`, `prometheus_agent_service_unittest.cc`, `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `405d955e204db6866d356f09eff1f7ab82049e1a`; root patch export `f7b2c7e481eda3aad9f9b10e106a0bd648536460`
**Applied fix:** Bounded gateway operation/task ownership and agent-service bookkeeping, evicted terminal/expired entries deterministically, cleaned state on session close and shutdown, and added overflow/reclamation tests.
**Verification:** Capacity, cleanup, shutdown, and regression suites pass in the native and browser gates.

### WR-07: `max_active_agents` blocks existing agents instead of new session admission

**Status:** fixed: requires human verification
**Files modified:** `BUILD.gn`, `prometheus_agent_gateway_browsertest.cc`, `prometheus_agent_profile_service.cc`, `prometheus_agent_profile_service.h`, `prometheus_agent_profile_service_browsertest.cc`, `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `d36944b935e8e8ba8eed624a9b0287a1667e713b`; root patch export `a8e29cb116451253e05eeea4ae7981a111b7a003`
**Applied fix:** Moved the active-agent cap to atomic session admission, permits already-admitted agents to continue within their authority, releases capacity on close/expiry, and tests concurrent admission plus reclamation through production profile/gateway paths.
**Verification:** Runtime admission unit tests and gateway/profile browser tests pass serially.

## Verification and Follow-up Hardening

- Chromium test-fixture follow-up `9c9d8d424c7d88b318807df77603afa8c7f2b8d7` is exported as patch `0051`; it keeps production auto-start enabled while queued-state-only browser fixtures opt out explicitly.
- Root commits `215919f4450307bd1919ddfd86cf601b42cda559` and `655b270c18d20eeb8b1676e534b6ae43027d2b5c` replace unsafe raw Ninja verification with exact Siso-queried direct compilation, preserve reviewed build metadata, and record the current test counts.
- Root commit `b376806c0668f861b93d14f09111583187374ffd` updates the live provider fixture to validate all nine production tool schemas and holds a valid response long enough to exercise cancellation after automatic task start.
- Exact command `bash .planning/chromium/verify-phase-20.sh` exited 0 from the actual workspace.
- Fresh results: native `202/202`; content/renderer `24/24`; prior native regressions `84/84`; Phase 20 browser `36/36`; prior browser regressions `83/83`; Node `75/75` with fail/cancelled/skipped/TODO all zero; built-app MCP smoke passed.
- All 51 ordered Chromium patches validate for the exact nested baseline range.
- Reviewed build metadata remained byte-identical: `.ninja_log` SHA-256 `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` SHA-256 `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.

## Skipped Issues

None.

---

_Fixed: 2026-07-20T10:38:38-05:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
