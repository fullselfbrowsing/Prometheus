---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
fixed_at: 2026-07-20T13:12:53-05:00
review_path: .planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-07-20T13:12:53-05:00
**Source review:** `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-02: Automatic fallback dispatches after authority revocation

**Status:** fixed: requires human verification
**Files modified:** `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `f7318871dba9b8ac836b1bfe4f7af8f0a31a8052`; root patch export `3802eb975d31d0390393b42acb869fe0561b97e2`
**Patch:** `0053-fix-20-cr-02-revalidate-automatic-provider-fallback.patch`; SHA-256 `4b216044085cc64c9dac1a0a0c119b780966d9570b3330d387814bfe87bb8282`
**Applied fix:** Automatic initial-turn fallback now carries and verifies the durable task generation immediately before every retry transport. It rereads effective policy, revalidates the live browser-issued authority/session, reruns task admission and dispatch, rechecks prompt/turn/token/duration limits, recomputes the remaining output budget, and requires exact equality with the current provider configuration before any raw prompt can reach the next provider. Authority loss takes the exactly-once session-loss terminal path.
**Verification:** Three production-shaped regressions defer provider A and then independently revoke the session while tightening policy, tighten the live prompt limit, or replace fallback configuration. Each proves that provider B receives no request/raw prompt and that the task terminates once. Exact direct compiles passed; the three focused tests passed `3/3`; the full runtime-profile suite passed `49/49` at the finding checkpoint.

### WR-10: MCP close and expiry bypass runtime session-loss cleanup

**Status:** fixed: requires human verification
**Files modified:** `prometheus_agent_profile_service.cc`, `prometheus_agent_profile_service.h`, `prometheus_agent_session.cc`, `prometheus_agent_session.h`, `prometheus_agent_session_unittest.cc`, `prometheus_mcp_integration_browsertest.cc`, `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `5632dcef07121bf4c3444cc2da13f222b6a61e91`; root patch export `f7556357d140e193701b9eef9b44ed2d0a74a600`
**Patch:** `0054-fix-20-wr-10-connect-session-loss-to-runtime-cleanup.patch`; SHA-256 `488b36f9770ed977787fbb57a4bb4834510730ba6d0153667680bd08c88a9480`
**Applied fix:** The profile-owned Agent authority now emits one checked lifecycle notification after successful public close, expiry sweep, and profile shutdown. The production runtime observes that boundary only after full construction and unsubscribes before shutdown. Runtime-owned close is separate from already-closed loss cleanup: the former removes registry authority and performs the paired ownership release once, while the latter only cancels matching provider work/tasks, invalidates local principals, and erases runtime registration. Reentrant session validation copies authority and revalidates principal state after notification, avoiding circular close/release and stale-pointer access.
**Verification:** Native coverage drains all registry sessions once and exercises deferred provider cancellation, duplicate loss, late callback, principal invalidation, zero live registration, zero recursive close/release, and exactly-one terminal. A production MCP browser fixture covers create→submit→explicit close, duplicate close, expiry through gateway pruning, duplicate invalid-binding cleanup, and gateway shutdown. Focused native tests passed `2/2`; the focused production MCP test passed `1/1`; related profile/MCP browser coverage passed `8/8`; combined Agent-session/runtime-profile suites passed `67/67`.

## Verification and Closeout

- Exact actual-root command `bash .planning/chromium/verify-phase-20.sh` exited 0.
- Fresh results: Phase 20 native `208/208`; content/renderer `24/24`; Phase 17-19 native regressions `84/84`; Phase 20 browser `37/37`; Phase 17-19 browser regressions `83/83`; Node `75/75` with fail/cancelled/skipped/TODO all zero; built-app external MCP smoke passed.
- All 54 ordered Chromium patches have exact stable body identity with the 54-commit nested baseline range; the deterministic valid-mutation self-test fails closed.
- Verification/docs/preservation counts were synchronized in root commit `8c94c1670bd8de7312c2c0e831b089f256720c58`.
- Reviewed build metadata remained byte-identical: `.ninja_log` SHA-256 `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` SHA-256 `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Live branches remain `chromium` at `8c94c1670bd8de7312c2c0e831b089f256720c58` and `prometheus/phase-14-assets` at `5632dcef07121bf4c3444cc2da13f222b6a61e91`.
- Isolated worktrees, temporary branches, custom focused binaries, and the recovery sentinel were removed without reset, force, or branch rename.

## Skipped Issues

None.

---

_Fixed: 2026-07-20T13:12:53-05:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
