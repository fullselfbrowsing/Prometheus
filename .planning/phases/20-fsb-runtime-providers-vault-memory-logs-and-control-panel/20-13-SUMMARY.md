---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 13
subsystem: ui
tags: [chromium, webui, memory, site-guides, vault, secure-storage, settings, accessibility]

requires:
  - phase: 20-04
    provides: OSCrypt-backed provider and vault secret storage
  - phase: 20-06
    provides: closed effective-policy and session-cap primitives
  - phase: 20-07
    provides: regular-profile runtime enforcement and exact-Browser authority
  - phase: 20-08
    provides: vault metadata and private confirmed insertion
  - phase: 20-12
    provides: exact-profile live control-panel bridge and operator workflow patterns
provides:
  - Complete bounded Memory, Site Guide, and Vault metadata CRUD in the control panel
  - Exact-window native provider-secret, vault-secret, and vault-use dialogs
  - Effective native Permissions and Settings mutation with locked-invariant rendering
  - Automated responsive, keyboard, accessibility, disclosure, and packaged-resource gates for all nine sections
affects: [20-10, 20-14, fsb-control-panel, provider-configuration, vault, runtime-policy]

tech-stack:
  added: []
  patterns:
    - Send only validated safe identifiers and intent from WebUI before entering native secret dialogs
    - Reconcile every mutation from a fresh effective native aggregate snapshot
    - Revalidate exact Browser, profile, document, origin, ownership, and destination immediately before vault use
    - Keep native-only and later-phase invariants disabled and truthful in renderer state

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc

key-decisions:
  - "Keep secret bytes entirely in browser-owned Views and native services; WebUI sends only IDs, replacement intent, and bounded non-secret settings."
  - "Require exact fresh current-document and canonical-origin validation for guide apply and vault use instead of trusting renderer state."
  - "Render requested policy only after the native service persists, clamps, and returns its effective snapshot."
  - "Expose supervision as disabled Not ready state and keep ownership, native-only vault transport, and per-use confirmation immutable."

patterns-established:
  - "Safe control CRUD: C++ validates bounded records and destructive intent, mutates the native store, then returns a fresh sanitized snapshot."
  - "Native secret handoff: exact local control launches modal Views and returns status plus metadata only."
  - "Disclosure-complete testing: responsive, keyboard, DOM, native snapshot, prefs, logs, accessibility, and packaged-resource scans share exact sentinels."

requirements-completed: [FSB-03, FSB-04, FSB-06, FSB-07, FSB-08]

duration: 2h 1m
completed: 2026-07-18
---

# Phase 20 Plan 13: Complete Control Workflows and Native Secrets Summary

**All nine control-panel sections now provide live bounded workflows, while provider and vault secrets remain exact-window native-only and every displayed setting comes from enforced native policy.**

## Performance

- **Duration:** 2h 1m
- **Started:** 2026-07-18T14:54:03Z
- **Completed:** 2026-07-18T16:55:11Z
- **Tasks:** 3
- **Nested Chromium files modified:** 18 distinct paths
- **Ordered exported patches:** 5 (`0032` through `0036`)

## Accomplishments

- Completed memory save/edit/share/search/delete, site-guide save/edit/search/exact-origin apply/delete, and vault metadata create/edit/delete/use-status workflows with bounded C++ validation, deterministic eviction, typed recovery, and fresh aggregate snapshots.
- Added modal browser-owned provider-secret entry, vault-secret entry, and vault-use confirmation bound to the exact control-panel Browser; secret values never enter HTML, `chrome.send`, `base::Value`, clipboard, logs, or accessibility output.
- Bound Permissions & Agents and Settings to persisted effective native policy, including internal-surface access, background actions, task and Agent caps, telemetry, and immutable ownership/vault/supervision boundaries.
- Preserved external MCP denial for provider mutation and native dialog launch with `LOCAL_UI_REQUIRED` and zero state change.
- Closed exact responsive, 200%-zoom-equivalent, keyboard-only, focus-return, accessibility, destructive-copy, reduced-motion, state-preservation, secret-disclosure, and packaged-resource gates across all nine sections.

## Task Commits

Every Chromium commit was exported immediately as an ordered non-empty patch and tracked in a separate root commit:

1. **Task 1 RED: Specify memory, guide, and vault workflows** — `796cbb2d82` (`0032-test-20-13-specify-memory-guide-and-vault-control-workflows.patch`); root tracker `c28790a19`
2. **Task 1 GREEN: Complete memory, guide, and vault metadata controls** — `56915e6ab0` (`0033-feat-20-13-complete-memory-guide-and-vault-metadata-controls.patch`); root tracker `3507425ba`
3. **Task 2 RED: Specify native secrets and effective settings** — `9713b5d9f2` (`0034-test-20-13-specify-native-secrets-and-effective-sett.patch`); root tracker `d2d95dd14`
4. **Task 2 GREEN: Add native secrets and enforced settings** — `d1e0c63a80` (`0035-feat-20-13-add-native-secrets-and-enforced-settings.patch`); root tracker `758428180`
5. **Task 3: Close control-panel disclosure gates** — `701786004a` (`0036-feat-20-13-close-control-panel-disclosure-gates.patch`); root tracker `ee1618dc3`

## Automated Verification

- Task 1's serial Memory, Guide, and VaultMetadata browser filter passed `3/3`, covering complete CRUD, share/search bounds, deterministic eviction, exact fresh-document guide apply, and metadata-only vault rendering.
- Task 2's NativeSecret, Settings, and Permissions browser cases, four native policy cases, and eleven secret-store cases passed `18/18` total.
- The final complete browser filter selected and passed `23/23`: 18 `PrometheusControlPanelBrowserTest` cases plus five `PrometheusVaultConfirmationBrowserTest` cases, serially in 55 seconds.
- The final complete native filter selected and passed `125/125`: 95 Runtime, 12 Memory, seven VaultService, and eleven SecretStore cases in 18 seconds.
- Automated journeys exercised all nine sections at 320, 480, 720, and 1024 CSS pixels and 200% browser zoom, including rail/select adaptation, list/detail grids, reachable 48px actions, exact labels, focus, and no page/control clipping.
- `node --check`, focused production and browser-test translation-unit compiles, exact GRIT resource generation, resource repack, Framework copy, exact test-name guards, reverse patch application, and nested `git diff --check` all passed.
- Recursive assertions found no exact secret, ciphertext, authorization, prompt, page, session, profile, or approval sentinels in native snapshots, DOM, events, errors, prefs fixtures, logs, or accessibility output.
- Packaged sources contained no React, shadcn, remote asset, terminal/engine/client launch, prompt provisioner, or `CLAUDE.md`; supervision remained exactly `Not ready` and parity data was unchanged.
- No human UAT was run; visual review remains intentionally deferred to the non-blocking Phase 24 release review.

## Decisions Made

- Native dialogs own password controls and asynchronous encryption lifetime. Renderer callbacks receive only saved, cancelled, or typed-failure status followed by fresh safe metadata.
- Provider removal and all memory, guide, vault, and log destruction use the common confirmation modal with exact object-specific copy and focus restoration.
- Vault-use confirmation names the safe entry metadata, exact origin, target tab, owner, destination count, and truthful supervision state before fresh native revalidation and private insertion.
- Settings forms submit only five bounded mutable fields. Locked ownership, native-only vault transport, per-use confirmation, and unavailable supervision never become renderer-controlled policy.
- Dynamic operator data remains `textContent`-only, and hidden record-ID inputs are excluded from interactive accessibility-label requirements while remaining absent from the tab order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Provider ID validation pattern was invalid under modern HTML pattern semantics**
- **Found during:** Task 3 focused browser gate
- **Issue:** An unescaped hyphen in the provider ID character class produced a renderer console validation error under Unicode `v`-mode pattern parsing.
- **Fix:** Escaped the hyphen while preserving the same ASCII provider-ID contract.
- **Files modified:** `prometheus_control_panel.html`
- **Verification:** The focused provider keyboard/destructive-copy cases and final `23/23` browser run passed without the pattern error.
- **Committed in:** `701786004a`

**2. [Rule 1 - Test bug] Accessibility label assertion treated hidden record IDs as interactive inputs**
- **Found during:** Task 3 complete browser filter
- **Issue:** The generic selector included hidden native record-ID fields, which are intentionally non-interactive and have no visible form label.
- **Fix:** Restricted the assertion to non-hidden inputs while retaining label, description, focus, keyboard, and protected-password checks for actual controls.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** The focused accessibility case and final `23/23` browser run passed.
- **Committed in:** `701786004a`

**Total deviations:** 2 auto-fixed Rule 1 bugs. Neither changed scope or weakened the native authority and disclosure contracts.

## Issues Encountered

- The mixed Ninja/Siso output graph was intentionally not cleaned or regenerated. Validation used exact persisted Siso compile/resource commands and an exact browser-test link so unrelated stale generated state remained untouched.
- The standalone `prometheus_unittests` executable was absent from the mixed output. The complete owned unit object set was linked into `browser_tests` for the required native filter.
- Two first-pass runtime bootstrap cases exposed stale unit objects compiled before the current provider header. Recompiling the eight owned Runtime, Memory, Vault, and SecretStore unit objects removed the ABI mismatch; the complete rerun passed `125/125`.
- Pre-run `.ninja_log` and `.ninja_deps` were restored after validation; the short Siso run log was retained separately for diagnostics.

## User Setup Required

None. Local execution continues to require an already-running configured loopback server; Prometheus does not download or launch an engine.

## Next Phase Readiness

- Plan 20-10 can now promote the external MCP catalog over the completed native routes while preserving local-only provider secret mutation.
- Plan 20-14 can run the final 32-case integration corpus and Phase 20 evidence closeout after Plan 20-10.
- No known blocker remains.

## Self-Check: PASSED

- All five nested Chromium commits have ordered non-empty patches with exact `From` identities, reverse-apply cleanly, and have separate root tracker commits.
- Nested Chromium is clean at `701786004a`; the root patch ledger is clean at `ee1618dc3` aside from the pre-existing active-plan state update and this summary.
- Final automated gates passed `23/23` browser and `125/125` native cases; no human UAT was run or claimed.
- Requirements completed by this plan are exactly `FSB-03`, `FSB-04`, `FSB-06`, `FSB-07`, and `FSB-08`.

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-18*
