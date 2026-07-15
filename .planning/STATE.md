---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 20
current_phase_name: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
current_plan: 3
status: executing
stopped_at: Completed 20-02-PLAN.md; 20-03 ready
last_updated: "2026-07-15T19:00:54.521Z"
last_activity: 2026-07-15
progress:
  total_phases: 14
  completed_phases: 9
  total_plans: 66
  completed_plans: 54
  percent: 82
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-13)

**Core value:** Agents get fast, precise, auditable whole-browser control
through DOM/native structure rather than screenshots or extension injection.

**Current focus:** Execute Phase 20 Plan 3 of 14: bounded profile memory and
exact-origin site-guide CRUD, search, and apply.

**Product boundary:** Claude Code, Cursor, Codex, and similar tools remain
external MCP clients. Prometheus has no bundled agent CLI/runtime, embedded
terminal, alternate engine, prompt provisioner, or `CLAUDE.md` provisioning.

## Current Position

Phase: 20 (FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel) — EXECUTING
Plan: 3 of 14
**Current Phase:** 20
**Current Phase Name:** FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
**Total Phases:** 14
**Completed Phases:** 9
**Current Plan:** 3
**Total Plans in Phase:** 14
**Status:** Ready to execute
**Progress:** [████████░░] 82%
**Last Activity:** 2026-07-15
**Last Activity Description:** Phase 20 planning complete — 14 plans ready

Milestone work is 54 of 66 plans complete (82%); cumulative project work is
105 of 117 existing plans summarized (90%).

## Latest Evidence

- Phase 19 verified all seven MCP requirements at nested Chromium HEAD
  `460caac2f9e7deecd9fa6294c41d13e5a6dd6115`.

- Fresh gates: 64 Node, 34 focused native, 7 renderer, 32 Phase 19 browser,
  and 53 Phase 17/18 regression tests plus the built-app stdio smoke.

- Phase 20 Plan 2: all 12 store and 13 foundation tests pass; task state,
  structured evidence, safe results, usage, races, and restart repair are bounded.

- Phase 20 Plan 1: 13/13 runtime contract/policy tests pass; prefs are local,
  non-syncable, versioned, clamped, and native-boundary locked.

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
| 20 | Keep MCP as provenance only; execution remains Auto/Provider/Local over native Hosted/Routed/Local routes. |
| 20 | Persist tasks through generation-fenced exactly-once mutations with LRU task and FIFO record bounds. |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-13T20:56:13.105Z
**Stopped At:** Completed 20-02-PLAN.md; 20-03 ready
**Resume File:** None

## Operator Next Step

Execute Phase 20 Plan 3, then continue Waves 4-14 with mandatory automated
gates. Do not run human UAT.
