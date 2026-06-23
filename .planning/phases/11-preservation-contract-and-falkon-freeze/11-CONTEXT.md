# Phase 11: Preservation Contract and Falkon Freeze - Context

**Gathered:** 2026-06-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 makes the Falkon-based Prometheus v1 reference recoverable and turns the v1 product/design/behavior record into an explicit migration contract. It verifies the preservation bundle and patch series, canonicalizes the preservation dossier, records what was removed or must stay, tags deferred v1 visual checks for Chromium replacement or retirement, and defines the license boundary for later Chromium work.

This phase does not implement Chromium product features, port UI code, or continue work in the active Falkon tree. Falkon is reference material only.

</domain>

<decisions>
## Implementation Decisions

### Preservation Artifact Contract
- **D-01:** Treat `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` as the canonical preservation dossier. Phase 11 should update, normalize, and complete it rather than create a parallel document.
- **D-02:** Verify recoverability with evidence: restore or inspect `.context/falkon-preservation/falkon-prometheus-v1.bundle`, confirm preserved HEAD `b0521c9d37e7545c680b78dfcc24f777a984091c`, and confirm the patch series contains the expected 81 patches.
- **D-03:** Do not recreate a long-lived active `falkon/` working tree. If a restore clone is needed, use a temporary or clearly named reference-only location under `.context/` and remove it or mark it read-only/reference-only after verification.
- **D-04:** Record that the active `falkon/` checkout has already been removed and reconcile any stale docs that still describe it as active.

### Migration Map Shape
- **D-05:** Build the migration map by capability and requirement first, with source/patch references only where they clarify behavior, assets, tests, or legal boundaries. Avoid a line-by-line Falkon implementation inventory unless needed for a specific high-risk surface.
- **D-06:** Every mapped item should answer: v1 behavior to preserve, Falkon reference source or patch reference, Chromium owner/future phase, parity test or validation evidence, and license/attribution note.
- **D-07:** Preserve contracts, not implementation. Patch subjects and file paths can guide planning, but downstream agents must reimplement on Chromium-native primitives.

### License Boundary
- **D-08:** Keep a strict default: no GPL Falkon C++ implementation, Qt widget classes, QSS, packaging scripts, or metadata should be copied into Chromium without explicit license review.
- **D-09:** Product-owned/root assets and planning design artifacts can be carried forward when provenance and license notes are clear. Falkon-derived bundled assets must be reintroduced only through a license-reviewed asset pipeline.
- **D-10:** Font Awesome, Poppins, Space Mono, PM/Prometheus, and FSB assets must retain their attribution/license requirements when ported.

### Deferred Visual Verification
- **D-11:** The 26 human-needed v1 checks from Phases 08, 09, and 10 should be tagged in Phase 11 as Chromium-equivalent checks unless the underlying surface no longer exists.
- **D-12:** Retire a visual check only with a written rationale that names the removed Falkon-only surface and the later Chromium phase that supersedes or intentionally drops it.
- **D-13:** Carry forward checks for the side panel/control panel, icon/font/theme rendering, offline asset behavior, and start page into the relevant Chromium phases instead of treating v1 static verification as enough.

### Freeze/Wipe Checklist
- **D-14:** The source wipe checklist should distinguish "already removed", "must stay", "reference-only", and "future Chromium-owned" items.
- **D-15:** `.planning/`, `.planning/design/`, `.planning/preservation/`, `.context/falkon-preservation/`, root `assets/`, and archived milestone docs must remain available.
- **D-16:** Phase 11 should note stale state from prior handoff: `.planning/STATE.md` still refers to a detached build session, while current local evidence shows no active `screen` session and `.context/chromium-build-screen.log` says the build finished successfully.

### the agent's Discretion
- Exact manifest/checklist format, temporary restore-check directory name, and script names are at the agent's discretion.
- The planner may choose whether the bundle/patch checks are implemented as shell, Node, or documented commands, as long as the evidence is reproducible and does not depend on an active Falkon tree.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Phase 11 goal, success criteria, and planned preservation work.
- `.planning/REQUIREMENTS.md` — PRES-01 through PRES-07 define the phase requirements.
- `.planning/PROJECT.md` — product identity, core value, v2 migration constraints, and locked project decisions.
- `.planning/MILESTONES.md` — v2.0 scope, primary artifacts, and v1.0 closeout/deferred items.
- `.planning/STATE.md` — accumulated decisions and stale/current handoff notes that planning must reconcile.

### Preservation Artifacts
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` — canonical preservation dossier to complete and normalize.
- `.context/falkon-preservation/falkon-prometheus-v1.bundle` — recoverable Falkon/Prometheus v1 reference bundle.
- `.context/falkon-preservation/patches/` — 81-patch series from upstream Falkon to Prometheus v1.
- `.planning/chromium/CHROMIUM-CHECKOUT.md` — records the source wipe, bundle verification, active Falkon removal, Chromium checkout, and build handoff.

### Design And Product Contracts
- `.planning/design/DESIGN-REFERENCE.md` — canonical Prometheus design language.
- `.planning/design/prometheus-browser/prometheus/app.jsx` — browser shell/chrome reference.
- `.planning/design/prometheus-browser/prometheus/SidePanel.jsx` — side panel layout and behavior reference.
- `.planning/design/prometheus-browser/prometheus/StartPage.jsx` — start page layout and behavior reference.
- `.planning/design/prometheus-browser/prometheus/styles.css` — warm token source and component styles.
- `.planning/design/prometheus-brand/Prometheus Logo.html` — PM mark, wordmark, palette, and brand construction.

### Prior Phase Contracts
- `.planning/phases/01-baseline-and-legal-inventory/01-CONTEXT.md` — baseline/legal inventory scope.
- `.planning/phases/02-prometheus-product-identity-shell/02-CONTEXT.md` — Prometheus identity and rebrand boundary.
- `.planning/phases/03-native-agent-control-spine/03-CONTEXT.md` — native command router contract.
- `.planning/phases/04-mcp-compatibility-and-multi-agent-control/04-CONTEXT.md` — MCP and multi-agent contract.
- `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md` — native runtime, provider, memory, vault contract.
- `.planning/phases/06-supervision-packaging-and-release-hardening/06-CONTEXT.md` — supervision and release validation contract.
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-CONTEXT.md` — compact chrome and tab management contract.
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md` — side panel/control panel split and parity matrix decisions.
- `.planning/phases/09-offline-font-awesome-free-icon-system-and-minimal-themes/09-CONTEXT.md` — offline font/icon/theme decisions.
- `.planning/phases/10-new-tab-start-page/10-CONTEXT.md` — start page decisions.

### Deferred Verification Inputs
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-VERIFICATION.md` — 10 human-needed control panel/side panel checks.
- `.planning/phases/09-offline-font-awesome-free-icon-system-and-minimal-themes/09-VERIFICATION.md` — 8 human-needed icon/font/theme checks.
- `.planning/phases/10-new-tab-start-page/10-VERIFICATION.md` — 8 human-needed start page checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`: already captures non-negotiables, source state, license boundary, design language, asset inventory, behavior inventory, Chromium targets, and source wipe rules. Phase 11 should finish and correct it.
- `.context/falkon-preservation/falkon-prometheus-v1.bundle`: local source recovery artifact.
- `.context/falkon-preservation/patches/`: patch subjects provide a high-signal capability inventory for compact chrome, FSB parity, offline assets, start page, branding, and visual polish.
- `.planning/design/` and root `assets/`: product-owned design references and assets that should survive the source wipe.
- Phase 08/09/10 verification reports: authoritative list of deferred human-visible checks to tag for Chromium replacement or retirement.

### Established Patterns
- Planning artifacts separate product decisions from implementation plans. CONTEXT.md should lock decisions; PLAN.md should choose commands/files.
- Prior verification reports use frontmatter status plus structured observable truths and human-needed checks. Reuse that style for any Phase 11 preservation verification report.
- Heavy browser source lives outside the root planning repo. `.context/` is ignored, and the root repo should not commit Chromium, Falkon restore clones, build outputs, or generated caches.
- Prior phases favor scriptable gates with exact paths and commands. Phase 11 preservation checks should be repeatable and fail with clear remediation.

### Integration Points
- `.planning/preservation/` is the right home for the canonical dossier and any source wipe checklist.
- `.context/falkon-preservation/` is the right home for the bundle, patch series, and any temporary restore-check output.
- Later Chromium phases should consume the migration map before planning: Phase 12 for source/build discipline, Phase 13 for branding/legal, Phase 14 for design/assets, Phase 15 for chrome/tabs, Phase 16 for WebUI/new tab, Phase 17-21 for agent/MCP/runtime/supervision, Phase 23 for parity/security/de-Falkon gates, and Phase 24 for packaging handoff.

</code_context>

<specifics>
## Specific Ideas

- Use a practical "capability map plus source references" instead of a massive per-line Falkon inventory.
- Make the preservation dossier the single place downstream agents consult for what to preserve, what to avoid copying, and where each contract moves in Chromium.
- Explicitly call out stale handoff state so Phase 11/12 planning does not assume a detached build is still running.
- Use temporary restore checks only as evidence; do not reintroduce an active Falkon development tree.

</specifics>

<deferred>
## Deferred Ideas

- Launching and validating the unmodified Chromium app belongs to Phase 12.
- Public notarization and updater work remain out of scope for v2 local validation until later release phases.
- Full Chromium feature implementation belongs to Phases 13-24; Phase 11 only preserves and maps contracts.

</deferred>

---

*Phase: 11-preservation-contract-and-falkon-freeze*
*Context gathered: 2026-06-23*
