---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 20
current_phase_name: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
current_plan: 9
status: executing
stopped_at: Completed 20-08-PLAN.md
last_updated: "2026-07-16T15:23:22-05:00"
last_activity: 2026-07-16
progress:
  total_phases: 14
  completed_phases: 9
  total_plans: 66
  completed_plans: 60
  percent: 91
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-13)

**Core value:** Agents get fast, precise, auditable whole-browser control
through DOM/native structure rather than screenshots or extension injection.

**Current focus:** Execute Phase 20 Plan 9 of 14: expose the 27 closed runtime
commands through the authenticated native gateway without weakening exact
Browser, secret, or caller authority.

**Product boundary:** Claude Code, Cursor, Codex, and similar tools remain
external MCP clients. Prometheus has no bundled agent CLI/runtime, embedded
terminal, alternate engine, prompt provisioner, or `CLAUDE.md` provisioning.

## Current Position

Phase: 20 (FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel) — EXECUTING
Plan: 9 of 14
**Current Phase:** 20
**Current Phase Name:** FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
**Total Phases:** 14
**Completed Phases:** 9
**Current Plan:** 9
**Total Plans in Phase:** 14
**Status:** Ready to execute
**Progress:** [█████████░] 91%
**Last Activity:** 2026-07-16
**Last Activity Description:** Completed Phase 20 Plan 8 native vault metadata, private exact-window insertion authority, and fail-closed confirmation races

Milestone work is 60 of 66 plans complete (91%); cumulative project work is
111 of 117 existing plans summarized (95%).

## Latest Evidence

- Phase 20 Plan 8: exact list guards select 7 Vault, 5 confirmed-Agent, 11
  SecretStore, and 5 browser cases; focused units are 23/23 green and serial
  exact-window browser confirmation is 5/5 green.

- Phase 20 Plan 7: exact combined Runtime, Store, Codec, Transport, Registry,
  Agent-session, and Bootstrap regression is 121/121 green; the executor runs
  exactly 20 closed-schema adversarial evaluation cases.

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
| 20 | Keep local runtime authority in a private move-only exact-Browser/tab principal and never serialize prompt or authority identifiers. |
| 20 | Retry only typed pre-mutation provider failures in registry order while preserving the exact bounded request and requiring unchanged current provider configuration. |
| 20 | Generation-fence every asynchronous continuation, revalidate fresh policy and authority, and retain known usage while leaving unavailable cost unknown. |
| 20 | Keep confirmed vault insertion as a move-only C++-only Agent authority method with no Agent/runtime route, transport schema, catalog entry, or model tool. |
| 20 | Bind vault confirmation to the exact Browser/profile/window/tab/owner/origin/frame/document/refs/focus and revalidate before decrypt, before insertion, and before every typed field. |
| 20 | Give MCP only a short-lived one-use identical-retry approval; no approval token or secret crosses the response. |

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 20 P05 | 55min | 3 tasks | 15 files |
| Phase 20 P06 | 25min | 2 tasks | 17 files |
| Phase 20 P07 | 9h11min | 4 tasks | 19 files |
| Phase 20 P08 | 1h16min | 3 tasks | 18 files |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-16T15:23:22-05:00
**Stopped At:** Completed 20-08-PLAN.md
**Resume File:** None

## Operator Next Step

Execute Phase 20 Plan 9, then continue Plans 10-14 with mandatory automated
gates. Do not run human UAT.
