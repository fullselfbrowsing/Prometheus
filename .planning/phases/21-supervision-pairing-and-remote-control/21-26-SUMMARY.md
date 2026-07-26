---
phase: 21-supervision-pairing-and-remote-control
plan: 26
subsystem: verification-and-closeout
tags: [chromium, supervision, verification, regressions, patches, preservation]

requires:
  - phase: 21-25
    provides: Built-app two-viewer/MCP supervision and native-dialog proof
provides:
  - One exact no-argument Phase 21 closeout verifier
  - Fresh exact Phase 21 and Phase 17–20 regression evidence
  - Complete ordered 74-patch replay and stable-identity proof
  - Requirement, decision, threat, preservation, validation, and UAT closeout
affects: [phase-22-boundary, phase-23-parity, phase-24-release-review]

tech-stack:
  added: []
  patterns:
    - Direct exact-object rebuild and focused linking without Ninja metadata mutation
    - Frozen list-first cohort counts with serial zero-retry browser execution
    - Fail-closed static scans with explicit missing-path and tool-status handling
    - Ordered patch replay plus stable patch identity and valid-mutation rejection

key-files:
  created:
    - .planning/phases/21-supervision-pairing-and-remote-control/21-VERIFICATION.md
    - .planning/phases/21-supervision-pairing-and-remote-control/21-26-SUMMARY.md
  modified:
    - .planning/chromium/verify-phase-21.sh
    - .planning/phases/21-supervision-pairing-and-remote-control/21-VALIDATION.md
    - .planning/design/prometheus-browser/README.md
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md

key-decisions:
  - "Freeze the Phase 19 renderer regression as three explicitly named privacy, exact-document, and bounds cases instead of treating a seven-test broad filter as the required trio."
  - "Exact-compile every legacy browser fixture owned by a frozen regression cohort so stale test objects cannot masquerade as product regressions."
  - "Scan production source collections recursively for implicit Agent claims so test-only setup calls stay visible to positive fixture guards but outside the production denial."
  - "Require every production secret-scan path and distinguish clean no-match from scan execution failure."
  - "Queue a forced follow-up capture when document dirtiness arrives during an APC snapshot, before notifying compatibility waiters."
  - "Bind every destructive Control Panel confirmation to the browser-issued generation of the rendered snapshot and fail closed after reordering."
  - "Observe the Document subtree so root creation and replacement remain visible to the sole browser-owned capture hub."
  - "Record human visual UAT as not run and preserve Phase 22 extension readiness as not ready."

requirements-completed: [SUP-01, SUP-02, SUP-03, SUP-04, SUP-05]

duration: not-recorded
completed: 2026-07-26
---

# Phase 21 Plan 26: Exact Verification and Closeout Summary

**Phase 21 now has one reproducible automated closeout gate, exact regression
and artifact evidence, a complete 74-patch export, and truthful Phase 22–24
handoff boundaries.**

## Accomplishments

- Froze nonempty exact cohorts at 190 Phase 21 native, 14 Phase 21 Blink
  renderer, 52 Phase 21 browser, 208 Phase 20 native, 84 Phase 17–19 native,
  21 Phase 20 content, 3 Phase 19 renderer, 37 Phase 20 browser, 83 Phase
  17–19 browser, and 81 Node tests.
- Rebuilt every owned production/test object needed by those cohorts, linked
  focused native/content/browser/renderer targets directly, and retained
  byte-identical Ninja metadata, reviewed Blink libraries, and application
  framework resources.
- Recovered the full browser regression matrix by rebuilding stale vault,
  profile/service, page-adapter, and tab-command fixture objects; all 37 Phase
  20 and 83 Phase 17–19 browser fixtures now pass serially with no retry.
- Corrected three closeout-only nested test fixtures: side-panel title
  synchronization, view-only client-label structural privacy, and a Boolean
  Control Panel content-boundary predicate.
- Closed all three post-review blockers with retained regressions: dirty
  signals received during APC capture force a follow-up capture; replace,
  revoke, and end confirmations are generation-bound across row/tab reorder;
  and document-root creation/replacement remains observed through to real
  browser recapture.
- Hardened production implicit-claim and secret scans. The secret scan now
  requires all intended browser/Blink paths and fails on tool or missing-path
  errors; the closeout-document gate reports a missing verification file
  explicitly.
- Replayed exactly 74 tracked nonempty source-only patches from the fixed
  baseline to nested HEAD, compared every stable patch identity, reproduced
  the exact nested tree, and rejected a valid mutated patch body.
- Published the validation, verification, preservation, design, roadmap,
  requirement, and state ledgers with `human_uat: not_run`, Phase 22
  `not_ready`, and Phase 23/24 still open.

## Exact Evidence

| Gate | Result |
|------|--------|
| Phase 21 native / Blink renderer / browser | 190/190, 14/14, 52/52 |
| Phase 20 native / content / browser regression | 208/208, 21/21, 37/37 |
| Phase 17–19 native / renderer / browser regression | 84/84, 3/3, 83/83 |
| Node TAP | 81/81; fail/cancelled/skipped/todo all zero |
| Catalog | 54 native / 12 alias / 22 typed stub / 0 later phase / 2 removed |
| Built app | exact live-smoke success marker |
| Patch chain | 74/74 ordered source-only identities; mutation rejected |
| Preservation | environment, GPL, artifact isolation, WebUI resources, preservation, diff, clean-worktree, and five byte hashes pass |

Evidence logs are stored under
`.context/chromium/src/out/Default/phase21-closeout/`.

## Recovery Commits

Outer verifier recovery commits before the atomic evidence commit:

1. `525ead488` — freeze the exact Phase 21 closeout gate
2. `795e9603f` — close Phase 20 browser regressions
3. `57f664a05` — rebuild complete legacy browser fixtures
4. `179353a02` — freeze exact renderer regressions
5. `964a814bb` — accept the exact batched renderer result
6. `47387294c` — scope the implicit-claim guard to production

Post-review root tracking commits:

1. `b18c15f50` — track the queued capture follow-up and 190-test native count
2. `38ac9c8d7` — track generation-bound confirmations and 51-test browser count
3. `252a5ed81` — track document-root lifecycle coverage and final 14/52 counts

Nested Chromium closeout and review corrections:

1. `92f9dd513a2916aaf3f3f84995656c214a483ecd` — patch 0069, side-panel title fixture
2. `78f29006479d22867231f61c70b7bfd37fe90639` — patch 0070, view-only label privacy
3. `2c93cf8831c961f0a7d0c35909f0da89d02a0b59` — patch 0071, Boolean content-boundary predicate
4. `0c8599e1ab77d3e501175b4bc8375db3acdd3a22` — patch 0072, queued dirty-capture follow-up
5. `3ea941de9a2b71b261f2bb49846a9e54136e2f49` — patch 0073, generation-bound destructive confirms
6. `de937473bd1b5e99aec391ea003545ecd205e367` — patch 0074, document-root lifecycle observation

The first three nested corrections changed tests only. Patches 0072–0074
intentionally changed product source and tests to close the review blockers.

## Deviations and Findings

- The frozen Phase 19 renderer count was three, but the historical broad
  dispatcher filter selects seven. The closeout now names the exact three
  security regressions rather than making a false broad-count claim.
- Phase 20 vault and Phase 17–19 browser crashes were stale test-object ABI
  failures, not product-source failures. Directly rebuilding all owned fixture
  objects removed the crashes and the complete frozen cohorts passed.
- The original implicit-claim scan expanded explicit test files before glob
  exclusions could apply. Recursive directory scanning now excludes test
  sources while a separate positive fixture guard proves denial coverage
  remains present.
- A first hardened secret expression matched a substring of an ordinary CSS
  identifier. A token-boundary expression preserves real detection without the
  false positive.
- The unrelated aggregate component-build `prometheus_unittests` link remains
  not run and is not a pass claim. All owned direct focused targets pass; there
  is no browser-test aggregate limitation.

## Final State

- Requirements SUP-01 through SUP-05: complete
- Plans and summaries: 26/26
- Nested source: clean at
  `de937473bd1b5e99aec391ea003545ecd205e367`, tree
  `97c4043b11ef760f3f03705a279641d4421ddf2f`
- Ordered patches: 74
- Human visual UAT: not run; non-blocking Phase 24 review
- Phase 22 extension diagnostics: `not_ready`

---

*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-26*
