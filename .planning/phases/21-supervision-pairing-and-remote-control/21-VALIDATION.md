---
phase: 21
slug: supervision-pairing-and-remote-control
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-21
verified: 2026-07-26T04:36:30Z
---

# Phase 21 — Validation Strategy

Automated validation contract for Chromium-native supervision, local dashboard
pairing, ordered DOM snapshot/diff streams, exclusive remote-control authority,
visible operator state, and preservation of Agent ownership/vault/confirmation
boundaries. Human desktop screenshot review remains a non-blocking Phase 24
release activity and cannot replace any Phase 21 gate.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | Chromium GTest, renderer/content tests, `InProcessBrowserTest`, Views/browser tests, Node 20 `node:test`, and shell/static evidence. |
| **Native build pattern** | Extend the Phase 20 exact Siso-command/direct-object compile and focused-link strategy. Do not invoke Ninja or mutate reviewed `.ninja_log`/`.ninja_deps`; do not claim the unrelated aggregate `prometheus_unittests` link limitation as passed. |
| **Native unit targets** | New supervision type/service/projection/diff/codec units plus Agent session/service/gateway/tab-state regressions in the existing Prometheus test graph. |
| **Renderer/content targets** | A document-lifetime dirty/overflow observer and Mojo lifecycle tests, plus APC snapshot/document-token/redaction regressions. |
| **Browser targets** | Real tab-badge integration, selected-tab side-panel status/stop, Control Panel lifecycle, native confirmation, gateway/MCP integration, multi-window/OTR, accessibility, responsive, resource, and privacy suites. |
| **Node tests** | `tools/prometheus-mcp/test/*.test.mjs`, extended for the five native supervision names, exact catalog counts, empty/closed schemas, secret-free results, and diagnostics. |
| **Quick Node command** | `node --test tools/prometheus-mcp/test/catalog.test.mjs tools/prometheus-mcp/test/tools.test.mjs tools/prometheus-mcp/test/diagnostics.test.mjs tools/prometheus-mcp/test/errors.test.mjs` |
| **Quick native command after first focused link** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='PrometheusSupervision*:*PrometheusAgentGateway*:*PrometheusAgentTabData*:*PrometheusTabState*' --test-launcher-jobs=1 --test-launcher-retry-limit=0` |
| **Focused browser command** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*Prometheus*Supervision*:*Prometheus*Pairing*:*Prometheus*RemoteControl*:*Prometheus*WebUI*' --test-launcher-jobs=1 --test-launcher-retry-limit=0` |
| **Full phase command** | `bash .planning/chromium/verify-phase-21.sh`; evolve the Phase 20 verifier to compile every owned object, relink the app/focused test binaries, preserve Ninja metadata, list-guard every suite, run Phase 21 and Phase 17–20 regressions, run complete Node TAP and built-app two-client smoke, and enforce security/resource/preservation/patch/diff gates. |

## Sampling Rate

- After each RED/GREEN task, run the narrowest owning unit/renderer/Node test
  and `git diff --check` in the root and nested Chromium repositories.
- After each plan, run the full affected Phase 21 subset and all directly
  touched Phase 17–20 regression suites; export a non-empty root patch for each
  nested source commit.
- No three consecutive implementation commits may land without a fresh
  automated result. Test names must be list-guarded before execution so an
  empty filter cannot pass.
- After each execution wave, run all implemented Phase 21 native/browser/Node
  filters serially where browser/profile state is shared.
- Before verification, run the full fail-fast Phase 21 command from a clean
  captured metadata baseline. No live dashboard service, cloud relay, API key,
  real vault secret, external network, human screenshot, or manual UAT is
  required.
- Maximum feedback latency for a focused test after the first direct build is
  120 seconds; long direct compile/link work belongs at plan/wave boundaries.

## Requirement Verification Map

| Requirement | Planned behavior | Threat refs | Minimum automated evidence | Status |
|-------------|------------------|-------------|----------------------------|--------|
| SUP-01 | The actual tab strip, selected-tab side panel, Control Panel, and accessible names show browser-proven Agent/viewer/controller/action state without secret or opaque authority material. | T-21-01, T-21-07, T-21-08 | Real-tab Views/browser tests, side-panel exact-tab tests, Control Panel observer tests, accessibility/geometry/theme/OTR/resource gates. | passed |
| SUP-02 | Each viewer receives one strict APC-derived baseline and ordered bounded structural diffs; renderer dirty/overflow signals trigger browser recapture, deterministic diff, or full resync. | T-21-04, T-21-06 | Projection/redaction units, diff property fixtures, document-observer lifecycle tests, navigation/backpressure/resync browser tests. | passed |
| SUP-03 | Browser-stamped session/tab/owner/document-epoch/sequence identity rejects unknown, stale, duplicate, out-of-order, gapped, mismatched, or late messages and callbacks. | T-21-02, T-21-05 | Service/codec/gateway units plus navigation, target replacement, queued callback, and two-client mismatch browser/smoke tests. | passed |
| SUP-04 | One-time local pairing supports visible code/expiry/redeem/revoke/end/audit state, multiple independent viewers, and exactly one controller. | T-21-01, T-21-05, T-21-06, T-21-07 | Digest/TTL/attempt/replacement units, gateway endpoint tests, complete Control Panel lifecycle tests, and built-app multi-client smoke. | passed |
| SUP-05 | View-only never mutates; control requires local approval and unchanged nonempty Agent ownership; existing internal-surface policy, exact frame/document validation, consequential confirmation, and native vault confirmation remain authoritative. | T-21-02, T-21-03, T-21-05, T-21-08 | Admission/dispatcher/confirmation units and browser tests for owner loss, implicit-claim denial, view-only denial, policy/vault preservation, stop/revoke/expiry, and late action rejection. | passed |

## Threat References

| Ref | Threat | Mandatory mitigation and blocking gate |
|-----|--------|----------------------------------------|
| T-21-01 | Pairing code, dashboard session, controller lease, or gateway bearer leaks through prefs, logs, audits, WebUI snapshots, MCP, URLs, history, accessibility, tooltips, or clipboard. | Store only bounded in-memory digest/opaque authority; return raw code once to the intentional local UI; recursive exact-sentinel scans across every serialization boundary. Any leak blocks completion. |
| T-21-02 | A stale session, document callback, sequence, or target silently binds to another document/tab/window. | Weak exact Browser/tab/document bindings, browser-assigned epoch/sequence/generation, no fallback reacquisition, and stale/mismatch/late-callback tests. Any wrong-target effect blocks completion. |
| T-21-03 | Remote control calls the existing dispatcher after owner loss and implicitly claims an unowned tab. | Permit view-only on an eligible unowned page, but require a captured nonempty unchanged Agent owner before control grant, dispatch, and callback; assert owner-loss/empty-owner denial before `EnsureCanControl`. |
| T-21-04 | DOM streaming exposes password, payment, OTP, unknown-sensitive values, restricted-frame content, selectors, or raw mutation records. | APC redaction options plus stricter browser projection that structurally omits sensitive values and fails unknown decisions closed; renderer emits dirty/overflow only. Exact sentinel leakage blocks completion. |
| T-21-05 | Concurrent controllers or queued actions survive stop, revoke, expiry, owner loss, navigation, or shutdown. | One controller lease, generation-fenced admission/callbacks, invalidate before notification, exactly-once terminal transitions, and race tests. Any post-invalidation mutation blocks completion. |
| T-21-06 | Unbounded viewers, codes, queues, diffs, long polls, attempts, audit events, or payloads exhaust browser resources. | Fixed caps/TTLs/attempts/bytes/ops/batches/inflight/timeouts, deterministic pruning, overflow-to-resync, and bound tests at/over every limit. |
| T-21-07 | Regular-profile pairing appears or operates in OTR or another profile/window. | Regular-profile factory selection, exact-window WebUI binding, absent OTR handlers/badges, teardown tests, and cross-profile/window isolation browser coverage. |
| T-21-08 | UI claims view/control/action state before native authority, hides an active controller, or removes the immediate stop path. | Render only fresh service snapshots, no optimistic grant, stable exact copy, persistent selected-tab stop/end controls, focus/a11y tests, and authority-loss truth tests. |

Security enforcement is enabled at ASVS level 1 and blocks on high severity.
Each PLAN.md must include a `<threat_model>` covering the threats it owns.

## RED Fixture Ownership (No Separate Wave 0 Plan)

No independent setup plan is needed. The first task that owns each seam must
create compileable RED fixtures, list-guard the exact tests, prove the expected
failure, and then implement GREEN behavior in the same bounded plan.

- [x] Closed types/codec task — pairing/session/stream/action enums, field
  bounds, serialization privacy, legal lifecycle, and exact allowed-key tests.
- [x] Profile service task — one-use digest redemption, replacement, attempts,
  TTL, independent viewers, sole controller, stop/revoke/end, Agent owner loss,
  tab/Browser/profile shutdown, OTR denial, and exactly-once observers.
- [x] Projection/diff task — deterministic strict baseline, insert/remove/
  update/reorder, independent cursors, duplicate/gap/out-of-order/overflow,
  epoch replacement, restricted frames, and password/payment/OTP/unknown
  structural redaction.
- [x] Renderer/content task — document-lifetime observer binding, coalesced
  dirty signal, bounded overflow, navigation teardown, and stale remote tests.
- [x] Gateway/MCP task — closed local endpoint operations, auth/Host/Origin/
  method/content-type/body/inflight bounds, five native empty schemas,
  54/12/22/0/2 counts, secret-free compatibility results, and ten-key health.
- [x] Remote action task — view-only/empty-owner/owner-mismatch/controller/
  paused-epoch denials, ordinary allowlist, consequential confirmation, vault
  preservation, and late callback invalidation.
- [x] Native/WebUI task — real badge construction/invalidation, selected-tab
  side strip, one-shot code DOM removal, full state/copy matrix, responsive
  widths, theme/OTR, focus/live-region, malformed-message, and privacy scans.
- [x] Closeout task — built-app two-client fixture for multiple viewers,
  single-controller conflict, baseline/diff/navigation resync, stop/revoke/
  expiry, late-action denial, complete regressions, and patch identity.

## Per-Task Verification Contract

The planner binds final task IDs to these mandatory automated checks. Every
task `<verify>` must contain an `<automated>` command and must name the exact
suite or static gate it owns.

| Concern | RED/GREEN automated evidence |
|---------|------------------------------|
| Contracts and lifecycle | Non-empty `PrometheusSupervisionTypesTest.*`, `PrometheusSupervisionTransportCodecTest.*`, and `PrometheusSupervisionProfileServiceTest.*` filters. |
| Structured stream | Non-empty projection/diff suites plus renderer/content observer lifecycle filters; exact sensitive sentinel absence. |
| Gateway and compatibility | Agent gateway/unit/browser tests; exact five-name promotion and complete Node suite with zero fail/cancel/skip/todo. |
| Remote control | Service/action-admission tests plus real browser confirmation, ownership, internal-surface, vault, stop/revoke/late-action cases. |
| Visible state | Real tab-strip Views/browser suite, side-panel exact-window suite, complete Control Panel lifecycle/a11y/responsive/resource suite. |
| Integration and regressions | Built Prometheus app with two independent local clients plus all Phase 17–20 owned native/browser/Node regressions. |
| Artifact integrity | Environment, direct compile/link, Ninja metadata hashes, preservation/GPL, source-only patch identities, root/nested diff, and `git diff --check`. |

## Final Gate Checklist

- [x] every new/modified native, renderer, content, Views, and browser object
  compiles through exact queried commands; app and focused test binaries link;
  reviewed Ninja metadata remains byte-identical
- [x] Phase 21 service/codec/projection/diff/action native suites are non-empty
  and green
- [x] document-observer/content/renderer suites are non-empty and green across
  dirty, overflow, navigation, teardown, and stale callback cases
- [x] real badge, selected-tab side panel, Control Panel, confirmation, pairing,
  stream, and remote-control browser suites pass serially with zero retries
- [x] complete Node TAP passes with five native supervision names and exact
  `54 native / 12 alias / 22 typed stub / 0 later phase / 2 removed` inventory
- [x] built-app two-client smoke proves multiple viewers, one controller,
  view-only denial, navigation resync, conflict, stop, revoke, expiry, and late
  action rejection over the existing authenticated loopback gateway
- [x] Phase 17–20 native, browser, transport, WebUI, vault, and Node regression
  suites pass
- [x] recursive secret/page/authority privacy scans pass with exact sentinels
  absent from all prohibited boundaries and code present only in the one-shot
  intentional UI response
- [x] OTR/cross-profile/cross-window, target mismatch, owner loss, tab close,
  Browser/profile shutdown, and callback-race gates fail closed exactly once
- [x] responsive 320/480/720/1024, dark/light, keyboard/focus/live-region,
  packaged resource, and no-remote-resource automated checks pass
- [x] no LAN/cloud/WebSocket/video/QR/external-package/remote-asset scope enters
  source or resources
- [x] preservation, GPL boundary, artifact isolation, stable patch-body
  identity, mutation self-test, root/nested diff, and `git diff --check` pass
- [x] human visual UAT is recorded `not_run` and routed to the non-blocking
  Phase 24 release review without a pass claim

## Executed Closeout Evidence

The sole closeout command is:

    bash .planning/chromium/verify-phase-21.sh

Fresh list-guarded results recorded under
`.context/chromium/src/out/Default/phase21-closeout/` are:

| Cohort or gate | Result |
|----------------|--------|
| Phase 21 native | 189/189 passed; fail 0; skip 0 |
| Phase 20 native regression | 208/208 passed; fail 0; skip 0 |
| Phase 17–19 native regression | 84/84 passed; fail 0; skip 0 |
| Phase 20 content regression | 21/21 passed; fail 0; skip 0 |
| Phase 21 browser | 50/50 passed serially with retry limit zero |
| Phase 20 browser regression | 37/37 passed serially with retry limit zero |
| Phase 17–19 browser regression | 83/83 passed serially with retry limit zero |
| Phase 21 Blink renderer | 12/12 passed |
| Phase 19 renderer security regression | 3/3 passed |
| Complete Node TAP | 81/81 passed; fail/cancelled/skipped/todo all zero |
| Compatibility catalog | exactly 54 native / 12 alias / 22 typed stub / 0 later phase / 2 removed |
| Built application smoke | exact `Prometheus MCP live smoke passed.` marker |
| Patch chain | 71/71 ordered, nonempty, source-only patches with stable identities; valid body mutation rejected |
| Environment and preservation | environment, GPL, artifact isolation, five packaged WebUI resources, preservation, root/nested diff, and byte-preservation gates passed |

The production secret scan now requires all six browser/Blink source paths and
treats only ripgrep status 1 as a clean result; status 0 and execution errors
fail. Isolated probes proved clean-source status, detection of a synthetic
secret-shaped token, rejection of a missing source, and no false match on the
ordinary `task-region__heading` identifier. The document gate now reports a
missing `21-VERIFICATION.md` through `require_file` instead of exiting
silently. The final integrated run re-executes both gates with this ledger and
the verification report present.

Reviewed artifact SHA-256 values are unchanged before and after every complete
or focused execution:

- `.ninja_log`: `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`
- `.ninja_deps`: `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`
- `libblink_modules.dylib`: `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`
- `libblink_modules.dylib.TOC`: `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`
- framework `resources.pak`: `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`

## Manual-Only Verifications

None for Phase 21 acceptance. Human desktop hierarchy, animation feel, and
subjective polish remain Phase 24 non-blocking review items. They cannot waive
functional, security, accessibility, responsive, or privacy automation.

## Validation Sign-Off

- [x] All five requirements map to automated evidence.
- [x] Security threats have fail-closed automated gates.
- [x] Every planned concern has a RED fixture owner and bounded feedback path.
- [x] No watch-mode command, external service, live secret, or human action is
  required for acceptance.
- [x] Sampling continuity prevents three consecutive unverified task commits.
- [x] `nyquist_compliant: true` and `wave_0_complete: true` are set after every
  owning RED fixture and its retained GREEN gate passed.

**Approval:** automated validation passed; subjective human visual UAT remains
`not_run` and non-blocking Phase 24 work

---
*Phase: 21-supervision-pairing-and-remote-control*
