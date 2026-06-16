---
phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
fixed_at: 2026-06-16T21:33:03Z
review_path: .planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 07: Code Review Fix Report

**Fixed at:** 2026-06-16T21:33:03Z
**Source review:** `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Local Agent Endpoint Accepts Unauthenticated Commands

**Status:** fixed
**Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`, `falkon/src/lib/agent/agentcommandrouter.h`, `falkon/autotests/agentcommandroutertest.cpp`, `falkon/autotests/agentcommandroutertest.h`, `falkon/tools/fsb-baseline/smoke-compact-tabs.sh`, `falkon/tools/fsb-baseline/smoke-agent-control.sh`, `falkon/tools/prometheus-mcp/server.mjs`
**Commit:** `1d9e42295`, `79de37c50`
**Applied fix:** Added health-issued bearer authorization tokens, required authorization for `/agent/command`, rejected unauthenticated preflight requests, removed wildcard CORS from JSON responses, and updated smoke/MCP callers and tests to use the token.

### CR-02: Caller-Controlled Client Label Spoofs Agent Identity

**Status:** fixed: requires human verification
**Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`, `falkon/autotests/agentcommandroutertest.cpp`, `falkon/autotests/agentcommandroutertest.h`
**Commit:** `c56992c84`
**Applied fix:** Changed agent identity allocation to use the authenticated session key injected by the router transport; `client` remains display metadata. Added regression coverage proving reused client labels do not bypass ownership across sessions.

### CR-03: Ownership and Supervision State Is Keyed to Unstable Tab Indices

**Status:** fixed: requires human verification
**Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`, `falkon/src/lib/agent/agentcommandrouter.h`, `falkon/autotests/agentcommandroutertest.cpp`, `falkon/autotests/agentcommandroutertest.h`
**Commit:** `cb7362169`
**Applied fix:** Added stable per-tab IDs in `WebTab::sessionData()`, keyed ownership/supervision/chrome state by those IDs, resolved current indices only for reads/signals, and cleaned state when tabs are destroyed. Added behavior coverage for reorder, close-before-owned-tab, supervision, and detach.

### WR-01: Active Automation Badge Never Clears After Successful Actions

**Status:** fixed: requires human verification
**Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`, `falkon/autotests/agentcommandroutertest.cpp`, `falkon/autotests/agentcommandroutertest.h`
**Commit:** `9c2c43d7d`
**Applied fix:** Kept last tool/reason metadata after successful commands but stopped marking completed actions as active automation. Added behavior coverage for successful command final state.

### WR-02: Agent Read/Ownership Tests Assert Tokens Instead of Behavior

**Status:** fixed
**Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`, `falkon/autotests/agentcommandroutertest.cpp`
**Commit:** `ad4fd5b54`
**Applied fix:** Replaced source-token checks with QTest behavior coverage that creates a grouped, owned tab and asserts `list_tabs` returns group and agent-state fields. Adjusted `tabInfo()` so list output keeps chrome state from the router handling the command.

---

_Fixed: 2026-06-16T21:33:03Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
