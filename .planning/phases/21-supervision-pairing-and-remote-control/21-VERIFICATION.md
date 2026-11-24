---
phase: 21-supervision-pairing-and-remote-control
verified: 2026-07-26T07:13:07Z
status: passed
score: "5/5 requirements; 26/26 plans verified"
human_uat: not_run
evidence_root_parent: 252a5ed815a5b554403b169cb5b90e812143efe8
nested_source_head: de937473bd1b5e99aec391ea003545ecd205e367
nested_source_tree: 97c4043b11ef760f3f03705a279641d4421ddf2f
deferred:
  - truth: "Subjective desktop hierarchy, motion, and polish review remains unperformed."
    addressed_in: "Phase 24"
  - truth: "Extension ecosystem policy and health remain not ready."
    addressed_in: "Phase 22"
---

# Phase 21: Supervision, Pairing, and Remote Control Verification Report

## Verification Result

Phase 21 is verified at the automated acceptance level. The no-argument
closeout command exits zero:

    bash .planning/chromium/verify-phase-21.sh

It list-guards every selected cohort, freezes exact counts, rebuilds the owned
focused targets without Ninja, runs serial browser cohorts with retry limit
zero, exercises the built Prometheus application, audits the production/test
boundary, replays the complete patch chain, checks reviewed artifact hashes,
and validates this report.

The reviewed implementation evidence parent is root
`252a5ed815a5b554403b169cb5b90e812143efe8`. It tracks the three
post-review blocker fixes, patches 0072–0074, and their frozen verifier
expectations. Nested Chromium is clean at
`de937473bd1b5e99aec391ea003545ecd205e367`, tree
`97c4043b11ef760f3f03705a279641d4421ddf2f`, based on fixed pre-Phase-21
commit `5632dcef07121bf4c3444cc2da13f222b6a61e91`.

Phase 22 remains `not_ready`; extension policy was neither implemented nor
claimed. Phase 23 parity/security and Phase 24 packaging/release scopes remain
open.

## Requirements

| Requirement | Status | Direct evidence |
|-------------|--------|-----------------|
| SUP-01 | SATISFIED | Native tab-badge, selected-tab side-panel, Control Panel, dialog, accessibility, exact-window, OTR, responsive, and resource fixtures are included in the 52/52 Phase 21 browser cohort. Display DTO and static privacy gates exclude authority fields. |
| SUP-02 | SATISFIED | Projection/diff/capture-hub native fixtures, 14 Blink supplement fixtures, live root-replacement recapture, browser navigation/resync fixtures, and built-app multi-consumer smoke cover bounded baselines, ordered diffs, independent cursors, dirty/overflow recapture, and full resync. |
| SUP-03 | SATISFIED | Service, codec, gateway, capture-hub, and browser fixtures reject stale or mismatched session, tab, owner, document epoch, sequence, snapshot generation, target, and late callback state. |
| SUP-04 | SATISFIED | Profile-service, gateway, Control Panel, and built-app fixtures cover one-use short-lived pairing, replacement, expiry, independent viewers, a sole controller, revoke, end, conflict, and metadata-only audit state. |
| SUP-05 | SATISFIED | Admission, Agent dispatch, native confirmation, owner-loss, view-only, internal-surface, consequential-action, vault-preservation, stop/revoke/expiry, and late-callback tests retain the existing Agent/page/vault authority boundaries. Production supervision code has no implicit ownership claim path. |

No SUP-01 through SUP-05 requirement is orphaned.

## Fresh Automated Evidence

The authoritative logs are under
`.context/chromium/src/out/Default/phase21-closeout/`.

| Cohort or gate | Exact result |
|----------------|--------------|
| Phase 21 native | 190/190 passed; fail 0; skip 0 |
| Phase 20 native regression | 208/208 passed; fail 0; skip 0 |
| Phase 17–19 native regression | 84/84 passed; fail 0; skip 0 |
| Phase 20 content regression | 21/21 passed; fail 0; skip 0 |
| Phase 21 browser | 52/52 passed; fail 0; skip 0; jobs 1; retries 0 |
| Phase 20 browser regression | 37/37 passed; fail 0; skip 0; jobs 1; retries 0 |
| Phase 17–19 browser regression | 83/83 passed; fail 0; skip 0; jobs 1; retries 0 |
| Phase 21 Blink renderer | 14/14 passed |
| Phase 19 renderer security regression | 3/3 passed |
| Complete Node TAP | 81/81 passed; fail 0; cancelled 0; skipped 0; todo 0 |
| Compatibility catalog | exactly 54 native / 12 alias / 22 typed stub / 0 later phase / 2 removed |
| Built application | exact `Prometheus MCP live smoke passed.` marker |
| Packaged WebUI | exact resource gate passed for 5 files |
| Environment and boundaries | Chromium environment, GPL guard, artifact isolation, static security, preservation, root/nested diff, and worktree checks passed |
| Patch series | 74/74 ordered, tracked, nonempty, source-only identities passed; valid body mutation rejected |

The Phase 19 renderer regression is an explicit security-focused trio:
`ElementReadDistinguishesEmptyAndAbsent`,
`ElementReadRejectsInvalidDisconnectedOrOtherDocumentReference`, and
`ElementReadRejectsOversizedValue`. Those cases preserve absent-value privacy,
exact-document isolation, and bounded reads. The older broad dispatcher filter
contains seven tests; this closeout does not misreport that broad filter as the
frozen trio.

The review-remediation tail adds three independent fail-closed proofs. An
in-flight dirty signal now queues a forced follow-up APC capture before
compatibility waiters are notified. Destructive Control Panel confirms carry
the browser-issued generation of the rendered snapshot, cancel when that
generation changes, and are rejected natively before ordinal resolution if
stale. The Blink supplement observes the `Document` subtree so root creation,
root replacement, and later mutations below the replacement all emit dirty
signals; the live capture-hub browser case proves those signals start new
browser captures and deliver updated diffs.

## Built-App and Test-Boundary Evidence

The built-app smoke launches the signed Prometheus application and a separate
dependency-free client fixture. Its assertions cover two independent dashboard
viewers, one independent MCP consumer sharing the browser-owned capture hub,
separate baseline/ack progress, a structural diff, navigation and retention-gap
resync, one controller with conflict denial, view-only mutation denial,
ordinary and consequential actions through the real native dialog path,
revoke/end/terminal behavior, and ordered shutdown. The five MCP supervision
commands retain empty caller schemas and do not carry dashboard authority.

Plans 23–25 add only a non-official disposable-runtime-test bootstrap,
conditional gateway contract, exact browser-composition binding, and
after-widget dialog response seam. Static and negative fixtures require the
existing authenticated loopback perimeter, exact runtime-test switches,
official-build denial, a disposable regular profile, a no-follow owner-only
closed-schema file, two consumed-before-return slots, exact
profile/browser/tab/origin/document/current-owner continuity, one-shot dialog
matching, secure buffer clearing, and early teardown. An absent dispatcher
returns 404; ordinary and official launches do not bind the route. No read,
health, diagnostic, log, audit, snapshot, WebUI, MCP, or catalog surface exposes
the test handoff.

The production secret scan requires all six intended production path groups:
the Node source and bin directories, browser Prometheus source, packaged
Prometheus resources, and both Blink supervision supplement source files. It
accepts only a clean no-match status, rejects detected secret-shaped literals,
and fails on a scan execution or missing-path error. Isolated probes also prove
that the ordinary `task-region__heading` identifier is not a secret match. The
closeout document gate uses an explicit required-file failure for a missing
verification report.

## Decision Traceability

| Decision | Verified implementation/evidence |
|----------|----------------------------------|
| D-01 | Pairing remains behind the existing authenticated IPv4 loopback gateway; static scope guards reject LAN/cloud/hosted-dashboard additions. |
| D-02 | Regular-profile one-use pairing is bound to exact browser-owned authority; credentials are structurally absent from persistence and routine surfaces. |
| D-03 | Typed create, redeem, expire, revoke, and end transitions do not reacquire a replacement target. |
| D-04 | OTR, profile shutdown, target close, and authority loss terminate affected state exactly once. |
| D-05 | Each consumer begins with a bounded DOM-native baseline and then ordered structural diffs, not image/video transport. |
| D-06 | Browser-owned target, owner, document epoch, sequence, and generation gates protect every stream and action transition. |
| D-07 | Navigation, gaps, duplicates, stale epochs, and mismatches require a fresh baseline instead of best-effort application. |
| D-08 | Phase 18 APC structure and live frame/document validation are reused; sensitive values and restricted-frame content fail closed. |
| D-09 | Fixed node, byte, operation, history, queue, waiter, consumer, audit, attempt, and lifetime caps force typed overflow/resync. |
| D-10 | Redemption starts view-only; control requires a fresh local browser-owned approval for the exact pairing and target. |
| D-11 | Remote ordinary actions use the existing typed Agent action route and verification engine; there is no parallel action engine. |
| D-12 | Vault use remains on its separate native confirmation and post-approval revalidation path; a controller lease cannot bypass it. |
| D-13 | Stop, expiry, revoke, owner loss, navigation authority loss, close, and shutdown invalidate queued and late work. |
| D-14 | Multiple viewer records keep independent expiry, cursor, wait, retry, revoke, and end state. |
| D-15 | One controller lease is admitted per tab; competing requests receive a typed conflict. |
| D-16 | Sanitized snapshots expose bounded viewer/controller labels and status while omitting codes, sessions, owners, epochs, and page content. |
| D-17 | Live state reaches native tab chrome and the persistent side-panel strip with immediate stop/end/manage intents. |
| D-18 | The existing Control Panel section owns target, pairing, viewer/controller, stream, audit, revoke, end, error, and recovery lifecycle UI. |
| D-19 | Pairing characters exist only in the one-shot intentional Control Panel result and private transient DOM state, then are erased. |
| D-20 | WebUI consumes fresh closed browser snapshots; destructive confirms add only a browser-issued freshness generation to their ordinal, while native row bindings remain the sole target authority. |
| D-21 | Exactly five supervision names are native, argument-free compatibility routes; catalog totals remain 54/12/22/0/2. |
| D-22 | Supervision readiness comes from the live exact-window native binding; extension diagnostics stay Phase 22 `not_ready`. |
| D-23 | Retained native, Blink, browser, Node, and built-app cohorts cover lifecycle, concurrency, identity, privacy, confirmation, UI, and transport behavior. |

## Threat Disposition

| Threat | Status | Verified mitigation |
|--------|--------|---------------------|
| T-21-01 | MITIGATED | Digest/opaque authority retention, one-shot intentional presentation, recursive DTO/DOM/output/document scans, and metadata-only routine surfaces prevent credential exposure. |
| T-21-02 | MITIGATED | Weak exact Browser/tab/document bindings plus epoch, sequence, generation, stale-target, navigation, and late-callback tests reject retargeting. |
| T-21-03 | MITIGATED | Remote control requires the captured nonempty unchanged Agent owner before grant, dispatch, and completion; the production implicit-claim scan has zero matches. |
| T-21-04 | MITIGATED | APC projection and browser scrubbing structurally omit sensitive values; renderer invalidation carries no page content; exact redaction/privacy regressions pass. |
| T-21-05 | MITIGATED | One controller, generation-fenced admission/callbacks, invalidation-first teardown, pending cancellation, and replay/race fixtures reject post-terminal mutation. |
| T-21-06 | MITIGATED | Fixed bounds cover codes, attempts, TTLs, consumers, queues, waits, trees, diffs, bytes, audit rows, payloads, and inflight work; overflow forces resync. |
| T-21-07 | MITIGATED | Regular-profile factories, exact-window resolution, OTR/cross-profile/cross-window denials, loopback-only transport, and non-official test gating fail closed. |
| T-21-08 | MITIGATED | Native badge, side strip, Control Panel, actual dialogs, stop/end controls, fresh snapshots, focus/a11y, theme, and four-width automated fixtures prevent false or hidden state. |

## Plan and Summary Coverage

All 26 plan files have matching summaries after this closeout.

| Plan | Verified contribution |
|------|-----------------------|
| 21-01 | Closed bounded supervision types and verifier scaffold |
| 21-02 | Closed transport codec and privacy contract |
| 21-03 | Deterministic baseline, diff, sequence, and resync model |
| 21-04 | Pairing, viewer, controller, audit, and owner-observation lifecycle |
| 21-05 | Regular-profile keyed service composition and teardown |
| 21-06 | Content-free Blink dirty/overflow supplement and Mojo lifecycle |
| 21-07 | Sole browser-owned capture hub and APC authority |
| 21-08 | Independent exact-target dashboard consumers and long polls |
| 21-09 | Authenticated gateway abstract dispatcher and cancellation |
| 21-10 | Five closed Agent route/result contracts |
| 21-11 | Exact-browser Agent dispatch and top-level composition |
| 21-12 | Independent Agent-compatibility shared-hub consumer |
| 21-13 | Five Node promotions and frozen catalog partition |
| 21-14 | Existing Agent action-engine reuse and admission fencing |
| 21-15 | Native control/action confirmation and fresh revalidation |
| 21-16 | Sanitized browser-owned tab-state projection |
| 21-17 | Native tab badge, accessibility, and layout preservation |
| 21-18 | Exact-tab side-panel runtime and zero-identity lifecycle intents |
| 21-19 | Persistent responsive side-panel supervision strip |
| 21-20 | Control Panel snapshot, targets, and one-shot create result |
| 21-21 | Control Panel observation, lifecycle actions, and code erasure |
| 21-22 | Responsive accessible Supervision & Pairing UI |
| 21-23 | Gated two-slot test bootstrap and conditional contract path |
| 21-24 | Sole exact-browser test-handoff composition binding |
| 21-25 | Real-dialog built-app two-viewer/MCP smoke and teardown |
| 21-26 | Exact closeout matrix, regression recovery, 74-patch replay, and evidence |

## Artifact and Key-Link Audit

| From | To | Evidence |
|------|----|----------|
| Blink supplement | browser capture hub | Dirty/overflow Mojo lifecycle tests; static guard permits browser capture ownership only in the hub. |
| Capture hub | APC projection/diff history | One exact-document tree/history owner with independent consumer cursors and resync. |
| Profile service | Agent-owned tab observation | Immutable captured owner, exact-target teardown, and no implicit claim. |
| Gateway and Agent routes | top-level browser composition | Dependency-neutral callback seams; concrete regular-profile services resolve only in main extra parts. |
| Side panel and Control Panel | browser-owned snapshots/intents | Closed field allowlists, exact-window handlers, zero-argument side-panel intents, generation-bound destructive Control Panel confirms, and fresh post-mutation reads. |
| Action controller | existing Agent dispatcher and native dialogs | Exact browser/tab/frame/document/owner/controller checks before and after approval. |
| `verify-phase-21.sh` | `tools/prometheus-mcp/smoke-browser.sh` | Built application plus separate client process is a mandatory exact-marker gate. |
| This report | `verify-phase-21.sh` | Requirement, D-01 through D-23, T-21-01 through T-21-08, summary-count, and documentation-privacy guards. |

No declared Phase 21 implementation artifact or key link was found missing.

## Patch and Artifact Integrity

The patch directory contains exactly the contiguous sequence `0001` through
`0074`. It exports every and only nested commit after
`5632dcef07121bf4c3444cc2da13f222b6a61e91`, replays to tree
`97c4043b11ef760f3f03705a279641d4421ddf2f`, contains no generated build
artifact, and has a stable patch identity matching its source commit.

The closeout recovery tail is:

| Patch | Nested commit | Stable patch ID | Purpose |
|-------|---------------|-----------------|---------|
| 0069 | `92f9dd513a2916aaf3f3f84995656c214a483ecd` | `cf5655face8d49eedb87ae679da3d3e0f2348576` | Synchronize the real side-panel title fixture |
| 0070 | `78f29006479d22867231f61c70b7bfd37fe90639` | `5f5afc4946bdb7c13ce4d3355e6b490b2b417338` | Assert view-only client-label privacy |
| 0071 | `2c93cf8831c961f0a7d0c35909f0da89d02a0b59` | `299bfd27a00247b1c77e48c22bb60b2d46c791f0` | Return a Boolean from the Control Panel content-boundary predicate |
| 0072 | `0c8599e1ab77d3e501175b4bc8375db3acdd3a22` | `e9549479c7d3bc00d9e2962fc9b1ab2bc4d8719d` | Queue a forced follow-up capture for dirty signals received during APC capture |
| 0073 | `3ea941de9a2b71b261f2bb49846a9e54136e2f49` | `a5c8723fc5b8f9d7b5fae9541f1a1d5fb1286c64` | Bind destructive confirmations to the rendered snapshot generation |
| 0074 | `de937473bd1b5e99aec391ea003545ecd205e367` | `1b8a9f7232d815cdf0f38094751a935d92cce604` | Observe document root creation/replacement and prove live recapture |

A syntactically valid mutation of patch 0074 produced a different stable
identity and was rejected. The nested worktree is clean.

Reviewed artifacts remain byte-identical:

| Artifact | SHA-256 |
|----------|---------|
| `.ninja_log` | `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce` |
| `.ninja_deps` | `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` |
| `libblink_modules.dylib` | `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e` |
| `libblink_modules.dylib.TOC` | `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b` |
| framework `resources.pak` | `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff` |

## Recovery and Disconfirmation

- The original three closeout corrections changed tests only: side-panel title
  synchronization, structural omission of `client_label` for view-only state,
  and Boolean extraction for a content-boundary predicate.
- Post-review patches 0072–0074 intentionally changed product source and
  regression coverage. They close the in-flight recapture race, stale
  destructive-row confirmation race, and document-root lifecycle observation
  gap without widening renderer identity, WebUI authority, or capture
  ownership.
- Stale Phase 20 vault and Phase 17–19 browser fixture objects caused process
  crashes against newer owners. The verifier now exact-compiles their owning
  fixture objects; the complete 37/37 and 83/83 cohorts pass.
- The aggregate component-build `prometheus_unittests` linker closure is
  NOT_RUN and is not claimed as passing. Its unrelated Chromium component-link
  symbols are outside the owned focused target. Every Phase 21 native object
  and its direct focused binary link passes. No browser-test aggregate
  limitation is claimed.
- No live service, cloud relay, external network, real secret, LAN listener,
  WebSocket supervision transport, screenshot/video stream, QR flow, hosted
  dashboard, remote asset, or external UI package was used or added.
- `human_uat: not_run`. The automated 320/480/720/1024-width, zoom, theme,
  keyboard, focus, live-region, and accessibility fixtures pass; subjective
  desktop hierarchy, motion, and polish remain the consolidated non-blocking
  Phase 24 review and cannot replace a failed automated gate.

## Gaps Summary

No actionable Phase 21 requirement, threat, artifact, key link, test cohort,
patch identity, or blocking human check remains. Extension policy remains
Phase 22 `not_ready`; migration-wide parity/security and release packaging
remain Phases 23 and 24.

---

_Verified: 2026-07-26T07:13:07Z_
