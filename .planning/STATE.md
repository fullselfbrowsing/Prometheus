---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 21
current_phase_name: Supervision, Pairing, and Remote Control
current_plan: 9
status: executing
stopped_at: Completed 21-08-PLAN.md
last_updated: "2026-07-22T07:43:47.723Z"
last_activity: 2026-07-22
progress:
  total_phases: 14
  completed_phases: 10
  total_plans: 92
  completed_plans: 74
  percent: 80
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
Plan: 9 of 26
**Current Phase:** 21
**Current Phase Name:** Supervision, Pairing, and Remote Control
**Total Phases:** 14
**Completed Phases:** 10
**Current Plan:** 9
**Total Plans in Phase:** 26
**Status:** Ready to execute
**Progress:** [████████░░] 80%
**Last Activity:** 2026-07-22
**Last Activity Description:** Completed Plan 21-08 — exact-target dashboard
hub attachment, opaque consumer and wait tokens, independent delivery/lifecycle,
and real two-viewer renderer fanout.

Milestone work is 74 of 92 existing plans complete (80%); cumulative project
work is 125 of 144 existing plans summarized (87%).

## Latest Evidence

- Phase 21 Plan 8: the exact 5-test long-poll, 45-test combined native, and
  2-test real-browser gates pass with one exact-target hub, independent opaque
  consumers/waits, coherent lifecycle teardown, privacy/ownership audits,
  stable patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 7: the exact 6-test real-browser, 27-test combined native, and
  12-test Blink gates pass with one renderer binding/APC capture per dirty
  epoch, independent bounded consumer state, secret-redaction and ownership
  audits, stable patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 6: the exact 12-test Blink lifecycle gate and retained 68-test
  supervision regression pass with generated-Mojo and renderer-initializer
  compile proof, source privacy guards, stable patch identity, and byte-identical
  Ninja metadata.

- Phase 21 Plan 5: the exact 8-test factory/profile gate and combined 68-test
  supervision regression pass with sole-Agent ownership guards, exact-profile
  dependency injection, stable patch identity, and byte-identical Ninja metadata.

- Phase 21 Plan 4: all 18 supervision lifecycle and 5 Agent observation tests
  pass with exact target/owner authority, bounded authority-free audit, stable
  patch identity, and byte-identical Ninja metadata.

- Phase 21 Plan 3: all 16 projection/diff fixtures and the combined 42-test
  supervision regression pass with strict APC privacy, canonical structural
  operations, independent viewer cursors, and atomic resynchronization.

- Phase 21 Plan 2: all 13 transport codec tests and the combined 26-test
  codec/types regression pass with exact operation/action schemas, recursive
  authority rejection, sanitized compatibility output, and byte-identical
  Ninja metadata.

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
| 21 | Parse each of the seven supervision operations into a distinct typed variant and reject unknown, prototype, identity, authority, route, script, vault, secret, and stale-shape fields before dispatch. |
| 21 | Project dashboard session, document epoch, and sequence only through the authenticated dashboard serializer; rebuild compatibility output from sanitized metadata with no authority path. |
| 21 | Normalize the one-time pairing code only for redemption, derive the client label through the native safe-label projector, and keep malformed-input errors fixed and non-echoing. |

- [Phase 21]: Project form values only when APC explicitly marks them safe and the control is independently neither password, payment, nor OTP; absent and future redaction decisions fail closed. — Supervision must structurally omit secrets before serialization, and a plausible truncated or ambiguously redacted baseline must never appear authoritative.
- [Phase 21]: Keep stream authority outside diff JSON and require a fresh acknowledged baseline after any malformed tree, reparenting ambiguity, authority mismatch, sequence discontinuity, wrap, or resource-cap overflow. — Canonical bounded structural operations stay transport-independent while per-viewer cursor failure remains atomic and cannot create partial authoritative state.
- [Phase 21]: Capture the current Agent owner exactly once at redemption, including empty, and terminalize on every later owner transition instead of adopting a replacement owner. — Immutable redemption authority prevents replacement-owner takeover and keeps control fail-closed.
- [Phase 21]: Keep PrometheusAgentService as the sole creator, registrar, owner, detach observer, and destroyer of tab authority data; supervision receives only a coalesced move-only observation lease. — One lifetime owner avoids duplicate registration, observer-list violations, and use-after-free across detach and shutdown.
- [Phase 21]: Retain only salted pairing-code digests and expose only bounded newest-first metadata through supervision snapshots and audit. — Raw credentials and browser authority remain memory-only and structurally absent from routine surfaces.
- [Phase 21]: Compose supervision only through the exact regular profile Agent keyed service and inject a weak observation callback. — Explicit factory dependency and fail-closed null, OTR, missing, and mismatched checks preserve one tab-data owner across teardown.
- [Phase 21]: Emit only kDirty or kOverflow from a document-scoped Blink Supplement while browser code retains capture, identity, sequence, and fan-out authority. — Content-free invalidation wakes APC recapture without creating a renderer serializer or second authority owner.
- [Phase 21]: Reduce MutationObserver delivery only through a fixed record-count ceiling and one 50 ms timer, with every Mojo and document teardown path converging on Disable. — Bounded coalescing and idempotent cleanup prevent content inspection, callback amplification, and late cross-document signals.
- [Phase 21]: Make one WebContents-scoped capture hub the sole owner of renderer Mojo endpoints, APC calls, safe trees, document epochs, and retained batches; downstream dashboard and Agent-compatible consumers receive only opaque IDs and stamped safe values. — One browser authority prevents duplicate observers, capture amplification, and renderer handles from leaking into delivery surfaces.
- [Phase 21]: Retain one bounded baseline/diff history per document while keeping cursor, ack, expiry, revoke, lag, and resync state consumer-local. — Consumers can progress independently without duplicating trees or allowing one slow or invalid consumer to advance another.
- [Phase 21]: Scrub bounded raw form values from canonical and accessibility-derived APC fields before projection. — Password, payment, and OTP values stay absent even when optional APC redaction features are disabled or duplicate content into structural labels.
- [Phase 21]: Ignore speculative frame creation and generation-fence deferred subframe recovery. — Committed navigation and disconnect ordering converge on one fail-closed epoch transition without duplicate enable or capture work.
- [Phase 21]: Attach a redeemed dashboard to the one exact-target capture hub before consuming its pairing, then retain only the opaque consumer token beside service-owned authority. — Partial setup cannot burn a one-time code, and no dashboard record can acquire renderer or capture ownership.
- [Phase 21]: Split long-poll ownership between one content-free hub readiness callback and one service-owned dashboard completion guarded by an opaque wait token. — Cancellation, shutdown, and teardown remain bounded and win even after readiness has been queued.
- [Phase 21]: Terminalize every same-target viewer coherently on exact target or immutable owner loss while keeping ack, wait, cancel, lag, resync, expiry, revoke, and end consumer-local. — Authority loss cannot leave a sibling viewer live, and ordinary viewer progress cannot affect another cursor.

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
| Phase 21 P02 | 33min | 2 tasks | 8 files |
| Phase 21 P03 | 38min | 3 tasks | 12 files |
| Phase 21 P04 | 42min | 3 tasks | 14 files |
| Phase 21 P05 | 1h28min | 2 tasks | 13 files |
| Phase 21 P06 | 56min | 3 tasks | 15 files |
| Phase 21 P07 | 2h52min | 3 tasks | 13 files |
| Phase 21 P08 | 1h18min | 3 tasks | 17 files |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- UI audit carry-forward: add `Review in Prometheus` for waiting confirmation,
  add a browser-owned `Use in Current Tab` vault action, keep the vault secret
  dialog open on encryption failure, complete task/log/header/permission detail
  models, and normalize light/accent/type/spacing tokens before release.

- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-22T07:43:47.719Z
**Stopped At:** Completed 21-08-PLAN.md
**Resume File:** None

## Operator Next Step

Execute `21-09-PLAN.md` to add the abstract supervision dispatcher to the
authenticated loopback gateway while retaining opaque service authority.
