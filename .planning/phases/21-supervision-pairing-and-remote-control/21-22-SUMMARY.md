---
phase: 21-supervision-pairing-and-remote-control
plan: 22
subsystem: chromium-control-panel-supervision-ui
tags: [chromium, webui, supervision, pairing, accessibility, responsive, privacy, tdd]

requires:
  - phase: 21-21
    provides: Exact lifecycle actions, fresh snapshots, and terminal presentation erasure
  - phase: 21-20
    provides: Sanitized exact-window snapshots and direct one-shot pairing creation result
provides:
  - Complete responsive Supervision and Pairing Control Panel lifecycle UI
  - Private module-only pairing presentation with explicit copy, announcement, and erasure boundaries
  - Ordinal-only actions, safe-focus confirmations, connected/recent/audit rendering, and local permission truth
  - Closed renderer DTO normalization plus packaged-asset, responsive, accessibility, and privacy regressions
affects: [21-23, 21-24, 21-25, 21-26, phase-24-review]

tech-stack:
  added: []
  patterns:
    - Closed renderer-side snapshot normalization before any supervision state is retained
    - One intentional sensitive text node backed by closure-private pairing presentation state
    - Sanitized-label WeakMap focus continuity without session, lease, owner, or epoch authority

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep the formatted pairing code only in closure-private module state and one intentional sensitive text node; erase both on every terminal, clear, or reload boundary."
  - "Normalize every fresh native supervision snapshot through an explicit closed whitelist before retaining it in the renderer."
  - "Send only fresh row ordinals in lifecycle messages and correlate focus restoration by bounded sanitized labels, never by renderer-retained authority."
  - "Use the contract's 60/40 split at 1024 CSS pixels and above, then stack to one pane below it without changing semantic reading order."

patterns-established:
  - "Closed DTO boundary: projection retains only explicitly bounded display fields and discards unknown top-level or row fields recursively."
  - "Safe focus: confirmation cancel returns to the invoking control when it still represents the same sanitized display row; otherwise focus moves to a safe surviving heading."
  - "Responsive supervision: semantic order stays summary, target, pairing, stream, connected, recent, audit at every tested width and zoom."

requirements-completed: [SUP-01, SUP-03, SUP-04, SUP-05]

duration: 1h48min
completed: 2026-07-24
---

# Phase 21 Plan 22: Responsive Control Panel Supervision UI Summary

**The Control Panel now presents the complete supervision and pairing lifecycle with private one-shot code handling, fresh ordinal actions, safe confirmations, and verified responsive behavior from 320 through 1024 CSS pixels and 200-percent zoom.**

## Performance

- **Duration:** 1h48min
- **Started:** 2026-07-24T18:46:20Z
- **Completed:** 2026-07-24T20:34:27Z
- **Tasks:** 3
- **Files modified:** 6 source, test, and verifier files; 3 ordered patch exports

## Accomplishments

- Replaced the supervision placeholder with the exact semantic order: state summary, target selector, pairing code, stream controls, connected clients, recent activity, and audit trail.
- Rendered truthful empty, code-active, redeemed, expired, locked, replaced, not-ready, target-gone, and off-the-record states from fresh native snapshots and direct one-shot create results.
- Kept the formatted code in closure-private module state and one intentional sensitive node, copied it only after an explicit user action, announced bounded outcomes, and erased it on all terminal boundaries.
- Added explicit create, replace, cancel, enable, stop, retry, revoke, and end actions using fresh ordinal-only messages and safe-focus confirmation dialogs without optimistic authority changes.
- Added connected/controller/viewer rows, current-action and stream state, recent activity, bounded audit rendering, a global supervision chip, and invariant `Available locally` permissions copy.
- Added a closed snapshot normalization boundary that whitelists and bounds every retained display field while dropping forged pairing, session, lease, owner, epoch, and unknown data.
- Implemented the contract's 60/40 two-pane layout at 1024 CSS pixels and above, a semantic one-pane stack below it, light-theme token swaps, reduced-motion preservation, and keyboard-visible controls.
- Added retained browser coverage for lifecycle copy, actions and focus, privacy and resource boundaries, four contract widths, and 200-percent zoom, plus packaged HTML/JS/CSS resource coverage.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Freeze the supervision lifecycle, exact copy, focus, privacy, and responsive contract** — nested `e7f9e8f865`, root `9ed2495ca` plus patch-export repair `2c1afe868`, patch `0057`
2. **Task 2 (GREEN): Render the complete Control Panel supervision lifecycle** — nested `c6a7b7dac6`, root `37f44e778`, patch `0058`
3. **Task 3 (GREEN): Harden renderer privacy, packaged resources, and responsive behavior** — nested `34784fe9b8`, root `790007dd8`, patch `0059`

## Files Created/Modified

- `prometheus_control_panel.html` — Semantic supervision scaffold, global state chip, lifecycle regions, intentional sensitive code node, and three confirmation dialogs.
- `prometheus_webui.js` — Closure-private pairing presentation, closed snapshot normalization, full rendering, explicit actions, copy timing, terminal erasure, and safe focus continuity.
- `prometheus_webui.css` — Responsive 60/40 and one-pane layouts, pairing-code treatment, dialog styling, light-theme tokens, and reduced-motion-safe presentation.
- `prometheus_asset_resource_unittest.cc` — Packaged-resource coverage for the Control Panel HTML, JavaScript, and CSS in addition to the existing icons.
- `prometheus_web_ui_browsertest.cc` — Four retained end-to-end supervision UI tests and updated legacy placeholder expectations.
- `.planning/chromium/verify-phase-21.sh` — Exact RED allowlist plus static resource, privacy, responsive, and lifecycle UI guards.
- `patches/0057` through `0059` — Stable ordered nested Chromium patch exports.

## Decisions Made

- The raw formatted code is presentation state, not snapshot state. Only the direct create result may populate it, and no native snapshot, audit row, action row, or retained renderer object may reconstruct or carry it.
- Native snapshots are treated as untrusted input at the UI boundary. The renderer rebuilds a closed DTO with explicit bounds before assigning `controlSnapshot`, so unexpected authority-shaped fields are discarded rather than merely hidden during rendering.
- Row ordinals are resolved afresh from the current rendered snapshot for every message. A closure-private WeakMap may retain only a bounded sanitized label for focus continuity when rows shift.
- Destructive revoke and end actions require exact confirmation dialogs. Cancel restores the invoking control only when it still represents the same safe display row; mutation and stale-row paths land on a safe surviving heading.
- The visual split is a 60/40 layout only when the viewport is at least 1024 CSS pixels. The same semantic DOM stacks below that breakpoint, including when browser zoom reduces the effective CSS viewport.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added a closed renderer snapshot-normalization boundary**

- **Found during:** Task 3 privacy hardening
- **Issue:** Native snapshots were already sanitized, but directly retaining the callback object would allow an injected or malformed payload to leave unknown authority-shaped fields in renderer memory.
- **Fix:** Added an explicit bounded whitelist for the complete supervision snapshot and every nested row before assignment to private renderer state.
- **Files modified:** `prometheus_webui.js`, `prometheus_web_ui_browsertest.cc`, `.planning/chromium/verify-phase-21.sh`
- **Verification:** The privacy test injected snapshot and top-level pairing codes plus forged session, lease, owner, and epoch fields and proved none were retained or rendered.
- **Committed in:** `34784fe9b8`

**2. [Rule 2 - Missing Critical] Expanded the packaged-asset resource gate**

- **Found during:** Task 3 resource-boundary review
- **Issue:** The existing asset test covered icons but did not directly prove that the Control Panel HTML, JavaScript, and CSS remained present in the packaged resource bundle.
- **Fix:** Added all three WebUI resources to the existing dev-surface packaged-resource test.
- **Files modified:** `prometheus_asset_resource_unittest.cc`
- **Verification:** All four `PrometheusAssetResourceTest.*` cases passed against the reviewed build output.
- **Committed in:** `34784fe9b8`

---

**Total deviations:** 2 auto-fixed (2 missing critical privacy/regression guards).
**Impact on plan:** Both changes strengthen the declared privacy and packaged-resource acceptance criteria without adding product scope or renderer authority.

## Issues Encountered

- The first root export of patch `0057` was empty because the export command ran in the root repository while shell redirection had already truncated the target. The valid nested commit was untouched; a separate non-amended repair commit regenerated the exact export and the final file is byte-identical to a fresh `git format-patch`.
- Initial GREEN runs exposed ordinary accessibility and state-transition mismatches in label structure, redeemed-action placement, dialog gating, removed-row focus, and off-the-record visibility. Each was corrected before the focused GREEN gate.
- The asynchronous real create callback could arrive after a synthetic lifecycle result in one browser test. Waiting for the real loading click to settle before injecting the synthetic result made the test exercise the intended one-shot ordering.

## Test Evidence

- Task 1 RED selected exactly 4 `ControlSupervision*` browser tests and failed only their four named unimplemented assertions, with no crash or fatal output.
- Task 2 selected and passed the 3 lifecycle, actions/focus, and privacy/resource browser tests.
- The final browser gate selected all 4 retained `ControlSupervision*` tests and passed lifecycle states, exact copy success/failure and timing, explicit actions, safe focus, closed DTO privacy, off-the-record behavior, packaged-resource visibility, widths 320/480/720/1024, and 200-percent zoom.
- The final asset gate selected and passed all 4 `PrometheusAssetResourceTest.*` cases.
- Root and nested `git diff --check` passed.
- Reviewed hashes stayed byte-identical: `.ninja_log` `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`, `.ninja_deps` `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`, Blink dylib `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`, Blink TOC `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`, and framework `resources.pak` `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`.
- Patch SHA-256 values are `339b117b4afe8e354dfd07275d36995c6a01c1ab727d767c846959febecd1c8d` for `0057`, `b20745932e3639c0338a16ec5f2f2261c91f354b36f1d16d7742cf359749916e` for `0058`, and `151b7f6873c91548cc0313f9846c69cd2141a5de78672cdb4274c63f818227a8` for `0059`; each is byte-identical to a fresh export of its nested commit.
- Applying `0057–0059` in order to nested base `26272ff410` produced an exact tree match with nested Chromium HEAD `34784fe9b8`.

## User Setup Required

None. No credentials, packages, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-23 can add the Settings supervision policy and limit controls against a complete, private, responsive Control Panel lifecycle UI.

No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `e7f9e8f865`, `c6a7b7dac6`, and `34784fe9b8`
- FOUND: root task commits `9ed2495ca`, `2c1afe868`, `37f44e778`, and `790007dd8`
- FOUND: ordered patches `0057`, `0058`, and `0059`
- VERIFIED: exact 4-test RED, 3-test intermediate GREEN, final 4-test supervision browser gate, and final 4-test packaged-asset gate
- VERIFIED: private code lifetime, explicit clipboard use, closed renderer DTOs, ordinal-only actions, safe focus, terminal erasure, semantic order, OTR closure, four widths, 200-percent zoom, unchanged reviewed metadata, patch identity, and exact patch replay

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
