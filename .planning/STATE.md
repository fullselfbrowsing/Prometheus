---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Chromium Engine Migration
current_phase: 21
current_phase_name: Supervision, Pairing, and Remote Control
current_plan: 19
status: ready
stopped_at: Completed 21-18-PLAN.md
last_updated: "2026-07-24T13:21:13.377Z"
last_activity: 2026-07-24
progress:
  total_phases: 14
  completed_phases: 10
  total_plans: 92
  completed_plans: 84
  percent: 91
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
Plan: 19 of 26
**Current Phase:** 21
**Current Phase Name:** Supervision, Pairing, and Remote Control
**Total Phases:** 14
**Completed Phases:** 10
**Current Plan:** 19
**Total Plans in Phase:** 26
**Status:** Ready to execute
**Progress:** [█████████░] 91%
**Last Activity:** 2026-07-24
**Last Activity Description:** Completed Plan 21-18 — sanitized exact-tab
side-panel supervision runtime with zero-authority stop, end, and same-window
management actions.

Milestone work is 84 of 92 existing plans complete (91%); cumulative project
work is 135 of 144 existing plans summarized (94%).

## Latest Evidence

- Phase 21 Plan 18: the intended 2-test RED gate, 4-test exact state/action
  GREEN gate, isolated bulk-end/teardown regression, and final 5-test runtime
  suite pass with strict zero-authority messages, fresh exact-tab resolution,
  bounded browser-owned labels, all-viewer end, reload-safe callbacks, stable
  patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 17: all 8 badge browser tests and both actual compact-layout
  browser tests pass with exact icon/name priority, complete accessibility
  under visual compression, real-tab lifecycle/isolation, invariant native
  geometry, stable patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 16: the intended 8-test RED gate, matching 8-test GREEN gate,
  final 15-test tab-state regression, and 3-test real service-path regression
  pass with a structurally authority-free DTO, exact observed-lease
  publication before downstream observers, coherent lifecycle clears, stable
  patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 15: the intended 3-test browser RED gate, 3-test enable-service
  GREEN gate, 2-test enable-browser gate, final 4-test native-dialog browser
  gate, 5-test controller/vault gate, and 5-test profile-action regression pass
  with safe-default native consent, fresh exact authority revalidation, sole
  typed Agent dispatch, vault non-bypass, stable patch identity, and
  byte-identical reviewed build artifacts.

- Phase 21 Plan 14: the intended 29-test RED gate, 3-test ordinary-action
  GREEN gate, final 34-test controller/profile gate, and 7-test Agent
  regression pass with exact Browser/tab/frame dispatch, immutable owner and
  acknowledged-stamp admission, one confirmation slot, lifecycle-first
  cancellation, metadata-only audit, stable patch identity, and byte-identical
  reviewed build artifacts.

- Phase 21 Plan 13: the 7-test exact Node GREEN gate and complete 80-test MCP
  regression pass with a 54/12/22/0/2 catalog, five deeply empty native
  supervision schemas, authority-free forwarding/results, live supervision
  health, retained extension deferral, and unchanged nested Chromium tree.

- Phase 21 Plan 12: the exact 2-test mixed live-browser gate and final 14-test
  service/codec regression pass with five real shared-hub compatibility
  semantics, independent dashboard/Agent progress, production dual binding and
  unbind, stable patch identity, and byte-identical reviewed build artifacts.

- Phase 21 Plan 11: the intended one-test RED and three-test exact Agent
  supervision GREEN gates pass with all five routes pinned to the authenticated
  Browser/stable tab, one Agent-only abstract seam, sole top-level concrete
  composition, ordered dual unbind, stable patch identity, and byte-identical
  reviewed build artifacts.

- Phase 21 Plan 10: the 8-test exact supervision codec gate and 48-test Agent
  route/transport/runtime regression pass with exactly five empty-schema
  native identities, bounded deterministic safe-APC result variants,
  recursive privacy rejection, stable patch identity, and byte-identical
  reviewed build artifacts.

- Phase 21 Plan 9: the exact 8-test supervision gateway unit and 5-test live
  browser gates plus broader 24-test unit and 14-test browser regressions pass
  with one authenticated loopback path, dependency-neutral dispatch,
  cancel-on-terminal lifecycle, sanitized readiness, stable patch identity,
  and byte-identical reviewed build artifacts.

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
- [Phase 21]: Own the abstract supervision gateway seam as a complete value callback bundle. — Plan 11 can install and clear it without a raw implementation lifetime or a concrete service edge in the gateway.
- [Phase 21]: Reuse each live gateway request ID as its opaque supervision cancellation token. — The token identifies transport lifetime only and carries no profile, target, viewer, session, or renderer authority.
- [Phase 21]: Erase pending supervision state before delivery or external cancellation. — Synchronous cancellation and late dispatcher results then become harmless no-ops and cannot double-complete or reach stopped I/O.
- [Phase 21]: Project supervision health only from bounded content-screened readiness metadata. — Invalid, missing, credential-bearing, authority-bearing, selector-bearing, or content-bearing diagnostics collapse to fixed not-ready text.
- [Phase 21]: Keep all five Agent supervision compatibility routes caller-scoped and argument-free. — Browser-owned dispatch derives target, stream, document, pairing, and controller authority; callers retain only the authenticated Agent session envelope.
- [Phase 21]: Require an exact route-to-success-payload match and reject empty baseline or diff stand-ins. — The transport codec projects supplied semantics only and cannot invent a plausible stream outcome.
- [Phase 21]: Serialize only bounded coherent safe-APC topology and fixed markers, with sensitive and authority sentinels rejected before JSON output. — Compatibility output stays deterministic, secret-free, identity-free, and structurally distinct from dashboard authority transport.
- [Phase 21]: Keep concrete supervision dispatch out of Plan 21-10 and make existing switches fail explicitly for the five new enum values. — Plan 21-11 owns abstract dispatch composition; explicit fixed failures preserve compileability without crossing the service boundary early.
- [Phase 21]: Canonicalize all five supervision routes from the authenticated SessionBinding. — The gateway rejects caller target scope and enters Agent service through the exact live Browser and stable tab.
- [Phase 21]: Keep Agent and gateway code limited to neutral supervision callbacks. — The top-level browser composition is the only owner allowed to resolve concrete regular-profile supervision services.
- [Phase 21]: Clear dashboard work before Agent dispatch and gateway shutdown. — Ordered cancellation and repeated harmless unbind prevent late work from crossing teardown.
- [Phase 21]: Leave compatibility semantics typed not-ready until Plan 21-12. — Plan 21-11 proves exact dispatch and ownership without inventing pairing or stream success.
- [Phase 21]: Attach MCP compatibility only as `kAgentCompatibility` on the exact dashboard capture hub. — One renderer/APC/tree/history authority serves both consumers while their tokens, cursors, waits, and end state remain independent.
- [Phase 21]: Treat successful closed-codec serialization as the Agent cursor commit boundary. — Rejected baseline or diff output remains unacknowledged and readable for safe resynchronization.
- [Phase 21]: Return Agent no-change only after a fresh validated read sees no batch and the shared hub is settled. — Compatibility cannot manufacture an empty result while capture work or a baseline is pending.
- [Phase 21]: End composition-owned dashboard sessions after cancelling waits and before clearing Agent dispatch. — Ordered dual unbind releases dashboard resources, completes pending transport exactly once, and makes later paths fail safely.
- [Phase 21]: Keep the 90-name MCP union fixed while promoting exactly five supervision dispositions to native. — Public tool identity remains stable while only browser-backed availability changes.
- [Phase 21]: Forward supervision through the existing empty native command envelope and keep target, stream, code, cursor, and controller authority browser-owned. — The authenticated Agent binding already pins exact scope, so Node must not synthesize a second authority surface.
- [Phase 21]: Apply recursive authority-field defense only to supervision results and pass through live supervision readiness while extensions remain Phase 22 not-ready. — This protects supervision credentials without removing legitimate content from ordinary page tools or weakening the extension boundary.
- [Phase 21]: Classify seven implemented typed page actions as ordinary and hold drag, drop, and navigation in one consequential confirmation slot. — The ordinary path reuses working Agent verification semantics while Plan 15 owns native allow-once consent for consequential work.
- [Phase 21]: Require immutable nonempty redemption-owner equality plus the live controller lease and current acknowledged hub stamp before every remote action. — Supervision must never claim an unowned tab, adopt a replacement owner, or mutate from a stale dashboard view.
- [Phase 21]: Keep supervision action results and audit content-free while dispatching only through exact-browser Agent routes. — Typed codes and metadata preserve operator visibility without leaking raw refs, text, options, URLs, or Agent page payloads.
- [Phase 21]: Keep supervision dialog models sanitized and dependency-neutral while the profile service and action controller retain every authority check. — Views may return only approved or denied and cannot create a controller or dispatch an action itself.
- [Phase 21]: Treat native approval as visible intent rather than authority and revalidate the exact session, target, immutable owner, controller lease, expiry, document, sequence, and generation afterward. — Safe focus, Escape, close, stale callbacks, and lifecycle loss all deny without mutation.
- [Phase 21]: Bind consequential consent directly to one pending action ID and leave vault-shaped work on its separate native confirmation path. — A dashboard cannot pre-approve a later action or reuse supervision control to bypass vault policy.
- [Phase 21]: Project browser chrome supervision only from the authoritative sanitized service snapshot through the exact Agent-owned tab-data lease, with authority fields structurally absent. — One display-only whole-value replacement keeps eligible unowned viewing visible, clears controller/action state coherently before observers render it, and prevents chrome surfaces from inventing a second target, owner, or credential authority.
- [Phase 21]: Compress native tab badge visuals in supervision, active-Agent, health, then idle-owner priority while preserving the complete sanitized accessible name. — Display compression must never hide semantic supervision truth from assistive technology.
- [Phase 21]: Allocate the native badge only from spare title width before the existing alert/close controls. — Supervision changes cannot move or cover the close target, change tab height, or alter active-address geometry.
- [Phase 21]: Keep side-panel supervision available independently of task-principal acquisition. — Task actions remain unavailable without a principal while the persistent exact-tab supervision strip continues to reflect browser-owned state.
- [Phase 21]: Route stop, manage, and end as zero-identity selected-tab intents into the authoritative profile service. — WebUI never retains dashboard sessions, controller leases, tab IDs, or any other mutation authority.
- [Phase 21]: Gate native side-panel snapshots until the current WebUI document explicitly initializes. — Reload, destruction, and late service notifications cannot call JavaScript across document lifetimes.

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
| Phase 21 P09 | 55min | 3 tasks | 14 files |
| Phase 21 P10 | 50min | 2 tasks | 13 files |
| Phase 21 P11 | 57min | 3 tasks | 18 files |
| Phase 21 P12 | 1h51min | 3 tasks | 18 files |
| Phase 21 P13 | 10min | 2 tasks | 9 files |
| Phase 21 P14 | 80min | 3 tasks | 12 files |
| Phase 21 P15 | 87min | 3 tasks | 15 files |
| Phase 21 P16 | 1h7min | 3 tasks | 10 files |
| Phase 21 P17 | 1h45min | 3 tasks | 11 files |
| Phase 21 P18 | 1h49min | 3 tasks | 9 files |

## Blockers and Deferred Items

- Blockers: none.
- Human desktop visual review: deferred to the non-blocking Phase 24 release review.
- UI audit carry-forward: add `Review in Prometheus` for waiting confirmation,
  add a browser-owned `Use in Current Tab` vault action, keep the vault secret
  dialog open on encryption failure, complete task/log/header/permission detail
  models, and normalize light/accent/type/spacing tokens before release.

- Signed/notarized public distribution: beyond the local v2.0 validation package.

## Session

**Last Date:** 2026-07-24T13:21:13.373Z
**Stopped At:** Completed 21-18-PLAN.md
**Resume File:** None

## Operator Next Step

Execute `21-19-PLAN.md` to render the persistent responsive supervision strip
from the closed exact-tab runtime and its zero-argument native actions.
