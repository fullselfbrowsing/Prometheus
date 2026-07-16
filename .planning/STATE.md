---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 20
current_phase_name: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
current_plan: 7
status: executing
stopped_at: Completed 20-06-PLAN.md
last_updated: "2026-07-16T09:46:47.502Z"
last_activity: 2026-07-16
progress:
  total_phases: 14
  completed_phases: 9
  total_plans: 66
  completed_plans: 58
  percent: 88
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-13)

**Core value:** Agents get fast, precise, auditable whole-browser control
through DOM/native structure rather than screenshots or extension injection.

**Current focus:** Execute Phase 20 Plan 7 of 14: closed non-official provider
bootstrap plus regular-profile runtime assembly, private local principal, safe
tool loop, fallback, cancellation, and evaluation seam.

**Product boundary:** Claude Code, Cursor, Codex, and similar tools remain
external MCP clients. Prometheus has no bundled agent CLI/runtime, embedded
terminal, alternate engine, prompt provisioner, or `CLAUDE.md` provisioning.

## Current Position

Phase: 20 (FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel) — EXECUTING
Plan: 7 of 14
**Current Phase:** 20
**Current Phase Name:** FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
**Total Phases:** 14
**Completed Phases:** 9
**Current Plan:** 7
**Total Plans in Phase:** 14
**Status:** Ready to execute
**Progress:** [█████████░] 88%
**Last Activity:** 2026-07-16
**Last Activity Description:** Completed Phase 20 Plan 6 safe-title persistence and closed native policy/session-cap primitives

Milestone work is 58 of 66 plans complete (88%); cumulative project work is
109 of 117 existing plans summarized (93%).

## Latest Evidence

- Phase 20 Plan 6: all 5 SafeTitle and 21 policy/session focused tests pass;
  the complete native `prometheus_unittests` regression is 226/226 green.

- Phase 20 Plan 5: all 17 codec, 12 transport, and 11 registry tests pass;
  the complete native `prometheus_unittests` regression is 214/214 green.

- Phase 19 verified all seven MCP requirements at nested Chromium HEAD
  `460caac2f9e7deecd9fa6294c41d13e5a6dd6115`.

- Fresh gates: 64 Node, 34 focused native, 7 renderer, 32 Phase 19 browser,
  and 53 Phase 17/18 regression tests plus the built-app stdio smoke.

- Phase 20 Plan 4: 11 encrypted-secret and 10 provider-registry tests pass;
  the complete native `prometheus_unittests` regression is 184/184 green.

- Phase 20 Plan 3: all 12 memory-store and 13 foundation tests pass; memory
  ownership is opaque and guides are bounded to exact canonical HTTP(S) origins.

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
| 20 | Persist only domain-separated caller hashes for memory ownership; never expose raw caller or gateway authority IDs. |
| 20 | Bind guides to canonical HTTP(S) origins and revalidate the current committed document before every apply. |
| 20 | Bind encrypted envelopes to record ID, secret kind, owner kind, and the complete canonical endpoint or site URL. |
| 20 | Keep known providers on fixed HTTPS endpoints and permit HTTP only for explicit local kinds accepted by `net::IsLocalhost`. |
| 20 | Keep exactly three native provider wire families behind one bounded provider-neutral DTO; compatible provider kinds select their family only through registry metadata. |
| 20 | Check discovery capability before any secret read, then re-resolve provider metadata, registry URL, and exact secret binding immediately before every authenticated send. |
| 20 | Provider requests use transient network isolation with omitted credentials and cookies, terminal redirects, bounded buffering, loader-owned cancellation, and no automatic transport retry. |
| 20 | Derive safe_title before task creation so the runtime store never accepts or persists the raw prompt. |
| 20 | Evaluate admission, dispatch, ownership, vault, and telemetry through fresh closed effective-policy decisions. |
| 20 | Lowered task or Agent caps reject only new admission and never evict active work or ownership. |

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 20 P05 | 55min | 3 tasks | 15 files |
| Phase 20 P06 | 25min | 2 tasks | 17 files |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-16T09:46:47.499Z
**Stopped At:** Completed 20-06-PLAN.md
**Resume File:** None

## Operator Next Step

Execute Phase 20 Plan 7, then continue Plans 8-14 with mandatory automated
gates. Do not run human UAT.
