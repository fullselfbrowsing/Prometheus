---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 20
current_phase_name: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
current_plan: 0
status: planning
stopped_at: Phase 19 complete; Phase 20 ready for discussion and planning
last_updated: "2026-07-13T11:43:33.200Z"
last_activity: 2026-07-13
progress:
  total_phases: 14
  completed_phases: 9
  total_plans: 52
  completed_plans: 52
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-13)

**Core value:** Agents get fast, precise, auditable whole-browser control
through DOM/native structure rather than screenshots or extension injection.

**Current focus:** Build the browser-owned FSB runtime, providers, secure vault,
memory/site guides, logs, diagnostics, and live control-panel data in Phase 20.

**Product boundary:** Claude Code, Cursor, Codex, and similar tools remain
external MCP clients. Prometheus has no bundled agent CLI/runtime, embedded
terminal, alternate engine, prompt provisioner, or `CLAUDE.md` provisioning.

## Current Position

**Current Phase:** 20
**Current Phase Name:** FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
**Total Phases:** 14
**Completed Phases:** 9
**Current Plan:** 0
**Total Plans in Phase:** 0
**Status:** Ready to plan
**Progress:** 64%
**Last Activity:** 2026-07-13
**Last Activity Description:** Phase 19 verified and complete; Phase 20 is unplanned.

Planned v2.0 work is 52 of 52 existing plans summarized (100%); cumulative
project work is 103 of 103 existing plans summarized.

## Latest Evidence

- Phase 19 verified all seven MCP requirements at nested Chromium HEAD
  `460caac2f9e7deecd9fa6294c41d13e5a6dd6115`.
- Fresh gates: 64 Node, 34 focused native, 7 renderer, 32 Phase 19 browser,
  and 53 Phase 17/18 regression tests plus the built-app stdio smoke.
- Compatibility inventory: 90/90 names with 22 native, 8 aliases, 22 typed
  stubs, 36 later-phase names, and 2 removed names.
- Human UAT was not run; remaining visual review stays non-blocking in Phase 24.

## Decisions

| Phase | Decision |
|-------|----------|
| Milestone | Keep all agent CLIs external through stdio MCP. |
| 17 | Browser-issued profile sessions own stable tab identities. |
| 18 | Browser-owned permission, frame, wait, verification, and audit checks remain authoritative. |
| 18 | Page content stays in bounded results and out of audit metadata. |
| 19 | Reimplement compatibility clean-room from observable contracts and official MCP behavior. |
| 19 | Retired sessions and gateway bindings are erased; opaque resume is valid only inside the ten-second grace. |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-13
**Stopped At:** Phase 19 complete; Phase 20 ready for discussion and planning
**Resume File:** None

## Operator Next Step

Run autonomous Phase 20 discussion/research/planning, then execute its plans
with automated gates. Do not run human UAT.
