---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 21
current_phase_name: Supervision, Pairing, and Remote Control
current_plan: 2
status: executing
stopped_at: Completed 21-01-PLAN.md
last_updated: "2026-07-21T22:14:13.117Z"
last_activity: 2026-07-21
progress:
  total_phases: 14
  completed_phases: 10
  total_plans: 92
  completed_plans: 67
  percent: 71
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-13)

**Core value:** Agents get fast, precise, auditable whole-browser control
through DOM/native structure rather than screenshots or extension injection.

**Current focus:** Execute Phase 21 supervision, pairing, and remote control on
the verified Chromium-native runtime and session authority model.

**Product boundary:** Claude Code, Cursor, Codex, and similar tools remain
external MCP clients. Prometheus has no bundled agent CLI/runtime, embedded
terminal, alternate engine, prompt provisioner, or `CLAUDE.md` provisioning.

## Current Position

Phase: 21 (Supervision, Pairing, and Remote Control) — EXECUTING
Plan: 2 of 26
**Current Phase:** 21
**Current Phase Name:** Supervision, Pairing, and Remote Control
**Total Phases:** 14
**Completed Phases:** 10
**Current Plan:** 2
**Total Plans in Phase:** 26
**Status:** Ready to execute
**Progress:** [███████░░░] 73%
**Last Activity:** 2026-07-21
**Last Activity Description:** Completed Plan 21-01 — closed native supervision
types, privacy-safe DTOs, and the metadata-preserving focused verifier.

Milestone work is 67 of 92 existing plans complete (73%); cumulative project
work is 118 of 143 existing plans summarized (83%).

## Latest Evidence

- Phase 21 Plan 1: the direct verifier selects 13 supervision contract tests;
  all pass with byte-identical Ninja metadata after exhaustive transition,
  bounds, checked-identity, privacy-sentinel, and serialization coverage.

- Phase 20 final closeout: the exact verifier passes 208/208 Phase 20 native,
  24/24 content/renderer, 84/84 native regression, 37/37 Phase 20 browser,
  83/83 browser regression, and 75/75 Node tests plus built-app MCP smoke,
  security/preservation, and 54/54 stable patch-identity gates.

- Phase 20 code review: three automated review/fix iterations resolved two
  critical and ten warning findings, including restart-safe vault metadata,
  production task execution, guarded provider fallback, bounded bookkeeping,
  agent-cap admission, and close/expiry/shutdown runtime cleanup.

- Phase 20 UI audit: code/evidence score 12/24. Functional/security acceptance
  remains passed; missing foreground confirmation affordances, transactional
  vault-save behavior, control-panel information architecture, token cleanup,
  and subjective desktop polish are explicit non-blocking carry-forward work.

- Phase 20 Plan 10: the complete Node suite passes 74/74, focused runtime
  promotion gates pass 37/37, and the rebuilt app passes the deterministic
  two-client external MCP smoke. The aggregate `prometheus_unittests` target
  remains unable to link because of unrelated unresolved Chrome symbols.

- Phase 20 Plan 13: the complete control-panel and vault browser gate passes
  23/23 serially, and the complete Runtime/Memory/Vault/Secret native gate
  passes 125/125 with responsive, keyboard, policy, and disclosure coverage.

- Phase 20 Plan 12: exact list guard selects 11 control-panel cases; the full
  serial suite passes 11/11, including 320/480/720/1024 responsive, keyboard,
  OTR, malformed-message, and recursive content/secret privacy coverage.

- Phase 20 Plan 11: exact Runtime and AskFsb guards pass 2/2; the complete
  WebUI foundation list guard passes 10/10 serially, including real 300px and
  320px responsive, exact-window lifecycle, restart, and privacy coverage.

- Phase 20 Plan 9: exact guards select 8 runtime-codec, 13 gateway, and 16
  existing Agent-transport cases; the combined regression is 37/37 green and
  the real native health endpoint returns exactly ten sanitized components.

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
| 20 | Keep the 27 native runtime commands in a separate closed codec and derive profile, Browser, tab, and caller only from a browser-issued session binding. |
| 20 | Deny external provider mutation at both the gateway and runtime service while preserving bounded read-only config, discovery, and diagnostics. |
| 20 | Let RuntimeProfileService own the shared vault/secret state and publish exact ten-key health from live sanitized provider/vault owners. |
| 20 | Break the WebUI/runtime target cycle with an opaque side-panel runtime factory and keep concrete exact-window principal acquisition in browser main extra parts. |
| 20 | Bind control-panel mutation authority to one exact regular Profile/WebContents and keep external MCP provider mutation denied. |
| 20 | Publish native control-runtime availability as module-safe load-time data so OTR stays handler-free without renderer initialization. |
| 20 | Keep secret bytes entirely in browser-owned Views and native services; WebUI sends only safe IDs, intent, and bounded non-secret settings. |
| 20 | Require exact fresh document, origin, Browser, ownership, and destination revalidation for guide apply and vault use. |
| 20 | Render mutable policy only from the persisted and clamped effective native snapshot. |
| 20 | Keep ownership, native-only vault transport, per-use confirmation, and unavailable supervision immutable and truthful. |
| 20 | Keep `set_provider_config` manifest-native for compatibility but return `LOCAL_UI_REQUIRED` before reading raw arguments. |
| 20 | Use params-only bodies for all 27 runtime-codec routes; page-action routes retain target/params/visual. |
| 20 | Seed built smoke only through the closed native test bootstrap with a canonical disposable path, mode-0600 metadata file, and loopback fixture. |
| 20 | Bind both independent smoke clients while the fresh regular browser and active tab are known available so task authority is deterministic. |
| 20 | Revalidate generation, live authority, current policy and limits, and exact provider configuration immediately before every automatic fallback send. |
| 20 | Treat profile-service close, expiry, and shutdown as the authoritative session-loss boundary that synchronously cancels matching runtime work exactly once. |
| 20 | Require stable patch-body identity for every exported Chromium commit and prove the gate rejects a parent-applicable mutation. |
| 21 | Keep session, document epoch, controller lease, and generation authority in browser-only memory types with no prefs or `base::Value` serializer; sanitized projections structurally cannot carry authority. |
| 21 | Carry stable tab identity as a positive `int32_t` in the standalone contract and resolve it only inside the owning browser service. |

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 20 P05 | 55min | 3 tasks | 15 files |
| Phase 20 P06 | 25min | 2 tasks | 17 files |
| Phase 20 P07 | 9h11min | 4 tasks | 19 files |
| Phase 20 P08 | 1h16min | 3 tasks | 18 files |
| Phase 20 P09 | 2h | 3 tasks | 20 files |
| Phase 20 P11 | 1h58min | 3 tasks | 18 files |
| Phase 20 P12 | 2h4min | 3 tasks | 20 files |
| Phase 20 P13 | 2h 1m | 3 tasks | 18 files |
| Phase 20 P10 | 3h47m | 3 tasks | 11 files |
| Phase 20 P14 | 5h45m | 2 tasks | 21 files |
| Phase 21 P01 | 41min | 3 tasks | 8 files |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- UI audit carry-forward: add `Review in Prometheus` for waiting confirmation,
  add a browser-owned `Use in Current Tab` vault action, keep the vault secret
  dialog open on encryption failure, complete task/log/header/permission detail
  models, and normalize light/accent/type/spacing tokens before release.

- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-21T22:14:13.111Z
**Stopped At:** Completed 21-01-PLAN.md
**Resume File:** None

## Operator Next Step

Execute `21-02-PLAN.md` to define the bounded dashboard supervision wire codec
and its privacy contract on top of the closed native types.
