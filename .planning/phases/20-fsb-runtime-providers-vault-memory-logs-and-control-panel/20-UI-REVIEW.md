# Phase 20 — UI Review

**Audited:** 2026-07-20

**Baseline:** approved `20-UI-SPEC.md`

**Screenshots:** not captured. These are native `chrome://` WebUI and Views surfaces, no Playwright MCP was available, and no usable 200-response dev server was present (`localhost:3000` returned 401; `5173` and `8080` were unavailable). This is therefore a code-and-automated-evidence audit, not a rendered desktop visual approval.

**Disposition:** **UI contract blockers found.** This does not overturn Phase 20's recorded runtime/security verification; it identifies foreground actions and design-contract behavior that the existing functional gates do not assert.

Severity follows the UI-auditor contract:

- **BLOCKER** — breaks a promised user flow or accompanies a 1/4 pillar; fix before shipping the Phase 20 UI as contract-complete.
- **WARNING** — partial contract conformance or visual/interaction debt; fix recommended, with subjective polish allowed to remain in the non-blocking Phase 24 review.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Canonical empty, boundary, supervision, and destructive copy is strong, but several required action labels/status phrases and currency rendering are absent or changed. |
| 2. Visuals | 2/4 | Responsive structure and accessible hierarchy exist, but the control panel is a card grid rather than the specified list/detail surface, and terminal failure/cancellation rails visually read as 100% complete. |
| 3. Color | 2/4 | The dark palette starts from the approved tokens, but the light palette is not implemented and accent is applied broadly to control actions, statuses, badges, and result decoration. |
| 4. Typography | 2/4 | Weight usage is restrained, but packaged Poppins/Space Mono are absent, 11px is introduced, and display/heading roles and line heights diverge from the four-role contract. |
| 5. Spacing | 2/4 | Breakpoints and 48px targets are well covered, but 35 spacing declarations use values outside the no-exceptions 4/8/16/24/32/48/64 scale. |
| 6. Experience Design | 1/4 | `Review in Prometheus` and `Use in Current Tab` have no usable UI path, while the vault secret dialog closes before encryption success/failure is known. |

**Overall: 12/24**

---

## Top 3 Priority Fixes

1. **BLOCKER — complete the foreground confirmation flows** — a task paused in `waiting_confirmation` exposes only cancellation, and a vault entry cannot initiate the required current-tab use flow — add `Review in Prometheus` and `Use in Current Tab`, wire each through a bounded browser-owned handler/runtime method, and cover the exact visible/native confirmation path in browser tests.
2. **BLOCKER — make vault secret saving transactional in the dialog** — the current dialog clears fields, invokes its reply, and closes before encryption reports success or failure — match the provider dialog's pending state: disable fields/buttons, remain open, close only after success, and restore focus with the canonical failure copy on failure.
3. **WARNING — finish the operational control-panel model, then normalize its tokens** — users lack the specified task filters/detail, semantic log filters/detail, diagnostics refresh, four live header chips, and permission rows; the surface also violates light-theme, accent, font, and spacing rules — implement the missing information architecture first, then consolidate the shared CSS against the approved token tables.

---

## Blocking Contract Violations

### B1. Waiting confirmation has no review action

The contract requires `Review in Prometheus` plus `Cancel Task` for `waiting_confirmation` (`20-UI-SPEC.md:251-260`). `renderRuntimeTask()` renders the state label, progress rail, timeline, recovery text, and then only one non-terminal action: `Cancel Task` (`prometheus_webui.js:280-369`). The all-state browser fixture checks the label and progress semantics but does not require a review control (`prometheus_web_ui_browsertest.cc:3077-3163`). A user can see that confirmation is needed but cannot proceed from the promised side-panel surface.

### B2. The vault foreground workflow is incomplete

The contract names `Use in Current Tab` as a vault-row action and requires a fresh browser-owned confirmation for every use (`20-UI-SPEC.md:431-458`). The implemented row exposes only `Edit Metadata`, `Save Secret`/`Replace Secret`, and `Delete Entry` (`prometheus_webui.js:1126-1169`). There is no corresponding control-runtime method (`prometheus_side_panel_runtime.h:111-152`) or registered WebUI message (`prometheus_web_ui.cc:142-243`). The backend does have a correctly named native `Confirm Vault Use` dialog (`prometheus_runtime_dialogs.cc:414-439`) and fail-closed service tests (`prometheus_vault_confirmation_browsertest.cc:297-334`), but the Phase 20 control panel cannot reach it.

The same foreground workflow also violates the secret-save transaction contract. The provider dialog correctly disables its controls, waits for the save completion, stays open on failure, and restores focus (`prometheus_runtime_dialogs.cc:176-215`). The vault dialog instead clears fields, invokes the native-entry reply, and returns `true` immediately (`prometheus_runtime_dialogs.cc:335-352`); it cannot display encryption failure without losing the entered values. The current browser test opens and cancels that dialog but never exercises an accept/failure result (`prometheus_web_ui_browsertest.cc:2371-2414`).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**What works:** The primary `Run Task` label and task empty state are exact (`prometheus_side_panel.html:68-71`, `:114-117`). The side-panel and control-panel cancellation copy is canonical (`prometheus_side_panel.html:161-174`; `prometheus_control_panel.html:468-483`), as is the external MCP boundary notice (`prometheus_control_panel.html:179-188`) and the Phase 21 supervision not-ready copy (`prometheus_control_panel.html:449-456`). Error states also reuse the canonical refresh-diagnostics sentence (`prometheus_webui.js:661-677`, `:1377-1389`).

**WARNING — required operational labels drift or disappear:**

- Provider and vault forms say `Save metadata`, not `Save Provider` or the context-specific vault action (`prometheus_control_panel.html:108-170`, `:267-291`).
- The page-wide task button says only `Refresh`, while MCP and Logs expose no visible `Refresh Diagnostics` action (`prometheus_control_panel.html:73-93`, `:179-189`, `:418-448`).
- Known side-panel cost is rendered as `0.0000 cost`, and control-panel cost as raw `microunits`, rather than currency; unknown control-panel cost says `Not reported` instead of `Cost unavailable` (`prometheus_webui.js:220-231`, `:600-609`, `:1412-1424`; contract at `20-UI-SPEC.md:264-273`).
- The required four header phrases are replaced with generic lowercase runtime/provider strings (`prometheus_control_panel.html:18-20`; `prometheus_webui.js:1459-1468`; contract at `20-UI-SPEC.md:285-290`).
- Successful mutations broadcast the generic `Native change saved` to every operation region, which obscures the object and action that completed (`prometheus_webui.js:1496-1513`).

These are notable traceability and feedback gaps, but the canonical high-risk destructive/security copy that is implemented is clear and direct.

### Pillar 2: Visuals (2/4)

**What works:** The side panel has a coherent single-column task/composer hierarchy, with labeled modes, task region, progress, result, and full-width actions (`prometheus_side_panel.html:20-118`). Both surfaces retain stable framed regions, visible headings, readable metadata groups, and responsive collapse rules. Automated browser checks cover the control panel at 320/480/720/1024px plus 200% zoom, clipping, reachability, labels, and 48px targets (`prometheus_web_ui_browsertest.cc:955-1097`). Side-panel checks cover its 300px floor and 320px target (`prometheus_web_ui_browsertest.cc:2788-2956`).

**WARNING — the wide control-panel focal model does not match the spec:** Every task, provider, vault record, memory, guide, log row, form, and metric is styled as an independent bordered card (`prometheus_webui.css:801-819`). Tasks render as a flat stack of cards with all metadata expanded (`prometheus_webui.js:570-687`), not a bounded selected list plus `Progress`, `Final result`, `Metrics`, `Action history`, and `Runtime events` detail pane (`20-UI-SPEC.md:320-328`). This creates the decorative-dashboard treatment the contract explicitly rejects (`20-UI-SPEC.md:285-313`).

**WARNING — terminal rails communicate the wrong visual state:** `succeeded`, `failed`, and `cancelled` all receive a full-width accent progress fill (`prometheus_webui.css:507-532`), and browser tests explicitly accept `aria-valuenow="100"` for all three (`prometheus_web_ui_browsertest.cc:3144-3163`). Failure and cancellation therefore resemble successful completion instead of a stopped terminal outcome.

`needs_human_review: true` — Wide-desktop hierarchy, card density, content scanning, truncation, and native-dialog composition cannot be approved from source. They remain part of the explicitly deferred Phase 24 screenshot/polish review (`20-VERIFICATION.md:20-23`, `:221-227`).

### Pillar 3: Color (2/4)

**What works:** The root dark tokens match the approved dominant, secondary, tertiary, text, accent, healthy, and warning colors (`prometheus_webui.css:5-26`; contract at `20-UI-SPEC.md:134-151`). Focus rings use the required accent (`prometheus_webui.css:126-130`, `:1007-1019`), and text labels accompany visible statuses.

**WARNING — the light theme is declared but not implemented:** `color-scheme: dark light` is set, but every surface/text variable remains the dark value and there is no light-theme or `prefers-color-scheme` override (`prometheus_webui.css:5-34`). The approved light 60/30/10 palette therefore has no path (`20-UI-SPEC.md:136-151`).

**WARNING — accent exceeds its reserved 10% role:** The shared `.primary` rule paints any primary-class action orange (`prometheus_webui.css:116-124`), and nine control-panel actions use that class in addition to `Run Task` (`prometheus_control_panel.html:103-167`, `:247-288`, `:320-409`). Accent is also used for every task-state label, all control badges, and result borders (`prometheus_webui.css:500-505`, `:847-885`), even though the contract excludes ordinary secondary actions, status chips, and card decoration (`20-UI-SPEC.md:153-166`).

**WARNING — destructive color is off-token:** Dark destructive controls use translucent `rgb(210, 71, 54)` surfaces with `#ffb4a8` text rather than the declared dark `#ff6666` destructive token (`prometheus_webui.css:438-454`).

`needs_human_review: true` — Actual dark-theme text/focus contrast and native Views theme rendering need screenshot or in-app inspection. The missing light theme and accent overuse are source-proven and do not depend on human judgment.

### Pillar 4: Typography (2/4)

**What works:** Explicit weights remain limited to the allowed 800 emphasis plus inherited 400 body weight; buttons and selected navigation use strong emphasis. The CSS has no negative letter spacing or viewport-scaled type.

**WARNING — required packaged families are absent:** The stylesheet defines only `system-ui` and `ui-monospace`; it has no `@font-face`, Poppins, or Space Mono reference (`prometheus_webui.css:5-27`, `:263-271`, `:738-742`, `:941-945`). The `Prometheus` brand is also 16px system text rather than the sole 20px Poppins display role (`prometheus_webui.css:83-86`; contract at `20-UI-SPEC.md:115-130`).

**WARNING — size and role inventory exceeds the contract:** CSS uses five distinct sizes: 11px (4 declarations), 12px (10), 13px (6), 16px (6), and 20px (2). The 11px status/badge/detail/metric labels are forbidden (`prometheus_webui.css:738-742`, `:847-854`, `:870-877`, `:981-984`). Conversely, each control-panel section `h1` is 20px, even though 20px is reserved for the product surface title and section headings are 16px (`prometheus_webui.css:693-704`).

**WARNING — line-height roles are not enforced:** The display/heading/body/metadata 24/20/20/16px line-height table is not implemented globally; examples use unitless `1.2` and `1` (`prometheus_webui.css:246-250`, `:263-271`).

### Pillar 5: Spacing (2/4)

**What works:** Primary surfaces use the approved 16px/24px padding, controls generally preserve the 48px minimum target, and the responsive breakpoints match the 720px and 1024px contract (`prometheus_webui.css:57-70`, `:1047-1120`). Browser tests verify target height, overflow, and reachability at the contract widths and zoom (`prometheus_web_ui_browsertest.cc:955-1097`, `:2868-2940`).

**WARNING — 35 declarations violate the no-exceptions spacing scale:** The CSS uses 1, 3, 6, 9, 10, 12, 14, 18, and 20px for margin, padding, or gap even though the only permitted values are 4/8/16/24/32/48/64 (`20-UI-SPEC.md:83-100`). Representative examples include:

- 6px search padding, 12px grid gap, and 14px tile padding (`prometheus_webui.css:94-104`, `:139-158`);
- 6px rail gaps and 10px rail/select insets (`prometheus_webui.css:641-680`);
- 18px heading separation and 10/12px security/table insets (`prometheus_webui.css:693-730`);
- 12/14px card grids/insets, 1px detail gaps, 9px row insets, and 14px action/form separation (`prometheus_webui.css:801-899`, `:947-953`);
- 12px mobile panel/page padding (`prometheus_webui.css:1073-1091`).

This is pervasive token drift, not a single inherited exception, so the pillar cannot score as substantially conformant despite good minimum target geometry.

### Pillar 6: Experience Design (1/4)

The blocker findings B1 and B2 prevent promised task completion, so this pillar is necessarily 1/4.

**What works:** The implementation has unusually strong automated safety coverage for what is present:

- renderer-visible task/provider/vault/log DTOs stay bounded and secret-free (`prometheus_web_ui_browsertest.cc:2073-2185`, `:2212-2300`);
- navigation landmarks, labels, live regions, reduced-motion behavior, keyboard rail movement, focus rings, and focus restoration are exercised (`prometheus_web_ui_browsertest.cc:1301-1461`, `:2788-2956`);
- loading, empty, ready, degraded, and recoverable-error snapshots are covered (`prometheus_web_ui_browsertest.cc:1378-1444`);
- the current verification record reports 56/56 must-haves, 37 Phase 20 browser fixtures, native/Node/regression gates, and no runtime/security regressions (`20-VERIFICATION.md:1-39`, `:95-110`).

**WARNING — major operational surfaces are partial even beyond the blockers:**

- Tasks provide search only; there are no `All`, `Queued`, `Active`, `Needs confirmation`, `Complete`, `Failed`, or `Cancelled` filters, selection model, or consolidated detail pane (`prometheus_control_panel.html:73-93`; `prometheus_webui.js:642-687`).
- Logs expose record-class values `All records`, `Events`, `Actions`, `Diagnostics` plus exact Task ID, rather than the required semantic filter set; rows cannot be selected into a key/value detail pane, and `Refresh Diagnostics` is absent (`prometheus_control_panel.html:418-448`; `prometheus_webui.js:1324-1425`).
- The header has two generic statuses rather than live `Runtime`, `MCP`, `Agents`, and `Vault` chips (`prometheus_control_panel.html:18-20`; `prometheus_webui.js:1459-1468`).
- Permissions show effective settings and summary metrics, but not the required per-surface rows with mode, actor scope, audit state, and last-changed time (`prometheus_control_panel.html:190-251`; contract at `20-UI-SPEC.md:407-429`).
- Provider kind includes `Hosted`, `Routed`, and `Local` as kinds in addition to the seven-kind closed list, and the required saved-key endpoint-change confirmation is not represented in the WebUI/native message surface (`prometheus_control_panel.html:119-139`; `prometheus_webui.js:1718-1735`; contract at `20-UI-SPEC.md:334-366`).
- The global renderer state models loading/empty/degraded/error, but individual sections do not each implement the required permission-blocked state (`prometheus_webui.js:642-687`, `:1358-1425`; contract at `20-UI-SPEC.md:294-302`).

The automated gates prove that the implemented controls are responsive, keyboard-reachable, and secure; they do not prove that the omitted controls exist. That distinction is why this code-only UI review can find blocker-class contract gaps without alleging failure of the already-passed backend/security suite.

---

## Human-Judgment Items

The following are explicitly `needs_human_review: true` and remain non-blocking to Phase 20's recorded acceptance because `20-VERIFICATION.md:225-236` defers subjective desktop screenshot/polish review to Phase 24:

1. Wide desktop visual hierarchy and whether the flat card stack creates excessive density or weak selected-record focus.
2. Dark-theme contrast, accent proportion, native Views theming, destructive emphasis, and focus-ring visibility in the packaged app.
3. Long task/provider/origin/log wrapping and truncation with realistic data at 320px, 720px, 1024px, and wide desktop sizes.
4. Native provider/vault dialog composition, initial focus order, keyboard escape behavior, error reflow, and trigger-focus return under real encryption failure.
5. Brand feel and legibility after Poppins/Space Mono and the light-theme tokens are actually packaged and applied.

No screenshot, paid-provider, or real-Keychain walkthrough is claimed by this review.

---

## Files Audited

- `/Users/lakshman/.codex/get-shit-done/references/ui-brand.md`
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-UI-SPEC.md`
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-CONTEXT.md`
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-VERIFICATION.md`
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-01-PLAN.md` through `20-14-PLAN.md`
- `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-01-SUMMARY.md` through `20-14-SUMMARY.md`
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html`
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html`
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js`
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc`
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.h`
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.cc`
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.h`
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc`
- `.context/chromium/src/chrome/browser/prometheus/prometheus_vault_confirmation_browsertest.cc`

Registry audit was skipped: the approved contract uses native packaged HTML/CSS/Views, explicitly has no shadcn dependency, and lists no third-party registry blocks (`20-UI-SPEC.md:63-79`).
