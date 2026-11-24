---
phase: 18
slug: page-adapter-dom-snapshot-and-action-verification
status: passed
score: "8/8 requirements verified"
verified: 2026-07-12
chromium_head: caae2f6a810255b78ec2c3599071149003e43df9
human_uat: not_run
manual_dependency: none
gaps_closed: [GAP-18-01, GAP-18-02]
---

# Phase 18 Verification

## Result

Phase 18 passed automated verification at nested Chromium HEAD
`caae2f6a810255b78ec2c3599071149003e43df9`.

The implementation verifies authorized bounded page reads, full and compact
APC snapshots, permissioned isolated-world JavaScript with browser-owned
mutation read-back, safe renderer actions, post-mutation settlement, compact
change reports, repeated-action detection, exact same-origin child-document
targeting, restricted-frame denials, and typed unsafe-action failures.

No human UAT was run or is required for Phase 18. The separate human visual
review remains a non-blocking Phase 24 release check.

## Prior Gap Closure

### GAP-18-01: JavaScript mutation read-back — CLOSED

The renderer no longer accepts or ignores an `expects_mutation` flag.
`PrometheusPageJsExecutor` now owns the complete verification chain:

1. Resolve and retain the exact target as `WeakDocumentPtr` plus its browser
   document token.
2. Capture a bounded APC projection for that document only and retain only its
   SHA-256 fingerprint.
3. Execute the isolated-world script exactly once.
4. Wait through `PrometheusPageWaiter` with bounded timeout/target-gone
   handling.
5. Revalidate the same live document, capture the same bounded projection,
   and compare fingerprints.
6. Return `js_mutation_verified`, or an explicit typed
   `no_verified_change`, timeout, stale-target, or read-back failure.

The script value remains in `AgentPageResult`; scripts, APC projections, hash
values, and page content never enter the change report or audit record.
`DocumentProjectionExcludesOtherFrames` proves parent/sibling churn cannot
verify a child-frame mutation.

Runtime evidence covers verified main- and child-document mutation, explicit
no-change, script timeout, permission/internal-page denial, script failure,
and mutation-enabled stale navigation. The independent rerun repeated the
high-risk child-document mutation and explicit no-change cases successfully.

### GAP-18-02: restricted-frame runtime evidence — CLOSED

The `*Prometheus*Frame*` inventory now contains eight runtime tests:

- same-origin child read succeeds;
- cross-origin and sandboxed children return `FRAME_RESTRICTED`;
- fenced and prerendered frames return `FRAME_RESTRICTED`;
- detached and crashed targets return `STALE_TARGET`;
- same-frame navigation during execute-js returns a stale failure.

Denial tests assert the exact typed error, absent page payload, empty changed
state, no restricted content in messages, and matching content-free audit
records. The independent rerun repeated cross-origin and sandbox denial cases
successfully.

## Requirement Coverage

| Requirement | Status | Independent evidence |
|-------------|--------|----------------------|
| PAGE-01 | VERIFIED | `read_page` follows Phase 17 session/profile/target/ownership validation, resolves a live HTTP(S) frame, uses `GetInnerText`, and applies deterministic UTF-8 bounds. Normal, ownership-denied, internal-page, same-origin-frame, and restricted/stale cases are automated. |
| PAGE-02 | VERIFIED | APC full snapshots expose document-scoped refs, frame token, selector hint, tag/role/name/text, form state, and actionability fields. Node/byte bounds, exact ref resolution, popup-token confusion, and redacted iframe handling are unit-tested. |
| PAGE-03 | VERIFIED | Compact APC filtering retains actionable/form/anchor/heading/landmark/restricted nodes, reports omissions, and remains valid JSON under node and byte bounds. Compact-vs-full browser coverage passes. |
| PAGE-04 | VERIFIED | Explicit permission and normal-page gates precede isolated-world execution. Values/errors are bounded. Declared mutations use exact-document baseline, settlement, and APC read-back; change, no-change, timeout, and stale outcomes are explicit and content-safe. |
| PAGE-05 | VERIFIED | Click, type, clear, select, scroll, hover, and named-key routes dispatch through public Blink APIs after fresh browser-side ref validation. Enter uses RawKeyDown/Char/KeyUp. Drag is typed unsupported and file drop is unconditionally denied. |
| PAGE-06 | VERIFIED | Page actions and declared JavaScript mutations use `PrometheusPageWaiter`/`PageSettledMonitor`, independent timeout, target-gone handling, and post-settlement verification rather than fixed sleeps. |
| PAGE-07 | VERIFIED | Reports are bounded structured JSON with stable state/ref/verification fields. History is bounded to a last-10 detection window, 50 entries per target, and 256 LRU target keys; the third identical resolved action is denied before renderer IPC. |
| PAGE-08 | VERIFIED | Public snapshot document tokens support exact same-origin child targeting. Cross-origin, sandboxed, fenced, prerendered, detached, crashed, stale, and foreign-document cases are explicit, automated, no-fallback failures. |

## Security and Lifecycle Findings

| Check | Result | Evidence |
|-------|--------|----------|
| Fresh ref prefix equals APC document | PASS | `ResolveSnapshotNodeRef` requires the returned `DocumentIdentifier` token to equal the ref prefix; `RejectsForgedTokenForPopupNodeId` passes. |
| Public same-origin child targeting | PASS | Snapshot refs expose the child token; `ResolveFrame` maps it inside the owned WebContents; exact child action and read tests pass without requiring public callers to know internal RFH IDs. |
| Exact requested document | PASS | Action and mutating-JS operations use `WeakDocumentPtr`, APC document maps, token-to-RFH lookup, WebContents membership, and repeated active/live checks across async boundaries. |
| No raw RFH across async work | PASS | In-flight operations retain weak page/document identity, Mojo remotes, waiter, bounded fingerprints, and callbacks; no raw RFH is an operation member. |
| Exactly-once completion | PASS | Adapter-owned ref-counted action/JS operations converge on guarded completion paths; adapter teardown cancels both operation sets safely. Late callback and renderer-failure tests pass. |
| Request/resource bounds | PASS | Script/ref/text/selector/name/option/key, snapshot traversal/node/byte, fallback, report, fingerprint, history-entry, per-target, and global-history bounds are explicit and tested. Each JS verification stage is time-bounded. |
| Content-free reports/history/audit | PASS | Reports expose stable booleans/state only; action fingerprints are route plus validated ref; JS fingerprints never leave memory; audit records exclude scripts, text, DOM/APC, selectors, file tokens, and returned values. |
| Third repeat before IPC | PASS | History runs after fresh exact-frame resolution and before Mojo binding; the third identical action returns `REPEATED_ACTION` without renderer dispatch. |
| Drag/drop safety | PASS | Drag performs no partial IPC. `drop_file` denies empty and non-empty token lists without reading, opening, logging, fingerprinting, or reporting token values. |
| Real renderer input | PASS | Mouse/widget input, form value APIs, selection, scrolling, and named keys use public Blink APIs. Enter form submission passes with the full character sequence. |

## Gate Evidence

| Gate | Command | Result |
|------|---------|--------|
| Build | `AI_AGENT=1 ../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests prometheus_action_dispatcher_unittests` | PASS; no work, exit 0 (independently rerun) |
| Browser-side units | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPage*:*PrometheusAgent*'` | PASS; 67/67 (independently rerun) |
| Renderer units | `./out/Default/prometheus_action_dispatcher_unittests --gtest_filter='PrometheusActionDispatcherTest.*'` | PASS; 2/2 (independently rerun) |
| Full focused browser regression | `./out/Default/browser_tests --gtest_filter='*Prometheus*Page*:*PrometheusAgentService*' --test-launcher-jobs=1` | PASS; 37/37 at remediation HEAD |
| Execute-js browser gate | `./out/Default/browser_tests --gtest_filter='*Prometheus*ExecuteJs*' --test-launcher-jobs=1` | PASS; 9/9 at remediation HEAD; inventory independently confirmed |
| Frame-policy browser gate | `./out/Default/browser_tests --gtest_filter='*Prometheus*Frame*' --test-launcher-jobs=1` | PASS; 8/8 at remediation HEAD; inventory independently confirmed |
| High-risk independent browser rerun | child mutation, explicit no-change, cross-origin denial, sandbox denial | PASS; 4/4 |
| Chromium environment | `bash .planning/chromium/check-chromium-env.sh` | PASS (independently rerun) |
| GPL guard | `bash .planning/chromium/check-falkon-gpl-guard.sh` | PASS (independently rerun) |
| Artifact isolation | `bash .planning/chromium/verify-artifact-isolation.sh` | PASS (independently rerun) |
| Preservation | `bash .planning/preservation/verify-preservation.sh` | PASS (independently rerun) |
| Diff checks | root and nested Chromium `git diff --check` | PASS (independently rerun) |

The browser tests emit known non-fatal Chromium process-cleanup messages; all
selected tests passed and commands exited 0.

## Manual Verification

None. All Phase 18 acceptance behavior has automated evidence. Human visual
UAT and screenshots are intentionally deferred to Phase 24 and cannot block
this phase or the local validation package.

## Final Status

`status: passed`

All eight PAGE requirements are satisfied at Chromium HEAD `caae2f6a81` with
no manual acceptance dependency. Phase 18 may be marked complete and Phase 19
may become current.
