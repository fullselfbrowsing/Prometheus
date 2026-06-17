# Roadmap: Prometheus v2.0 Chromium Engine Migration

## Milestones

- Complete **v1.0 MVP** — Phases 1-10 (shipped 2026-06-17; archived under `.planning/milestones/`)
- Active **v2.0 Chromium Engine Migration** — Phases 11-24

## Milestone Thesis

Prometheus keeps its product, design, and agent-native control thesis, but retires Falkon/QtWebEngine as the production base. v2.0 starts by preserving the v1 source reference and design/behavior decisions, then removes the active Falkon tree, checks out Chromium, establishes a reproducible Chromium baseline, and rebuilds Prometheus on Chromium-native primitives: Views/browser UI, WebUI, browser-process services, WebContents/RenderFrameHost/page adapters, local MCP bridge, extension support, secure runtime storage, supervision, and release validation.

## Active Phases

- [ ] **Phase 11: Preservation Contract and Falkon Freeze** — Save every v1 decision, behavior, asset, test, source reference, and legal boundary before removing the active Falkon tree.
- [ ] **Phase 12: Chromium Checkout, Build, and Patch Discipline** — Bring in upstream Chromium with depot_tools, build it cleanly on macOS, and establish source/layout rules that keep the root repo clean.
- [ ] **Phase 13: Product Identity, Branding, and Legal Baseline** — Turn the Chromium baseline into a Prometheus-owned app identity with correct attribution and no unwanted Chrome/Chromium/Falkon/KDE-facing product surfaces.
- [ ] **Phase 14: Asset and Design System Port** — Port warm tokens, PM/FSB assets, Poppins, Space Mono, Font Awesome, dark/light themes, and visual state rules into Chromium resources.
- [ ] **Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model** — Rebuild the compact browser chrome and advanced tab workflows using Chromium-native UI architecture.
- [ ] **Phase 16: Prometheus WebUI Surfaces and New Tab** — Build Prometheus start page, side panel surfaces, and FSB Control Panel as Chromium WebUI/browser-backed surfaces.
- [ ] **Phase 17: Native Agent Command Service and Tab Ownership** — Rebuild the core native command router as a Chromium browser-process service with authenticated sessions and stable tab ownership.
- [ ] **Phase 18: Page Adapter, DOM Snapshot, and Action Verification** — Rebuild page reads, DOM snapshots, JS execution, action tools, waits, and verification on Chromium WebContents/frame primitives.
- [ ] **Phase 19: MCP Bridge and Multi-Agent Runtime Compatibility** — Reconnect existing FSB-style MCP clients to the Chromium-native service with multi-agent policy and typed compatibility errors.
- [ ] **Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel** — Restore provider-backed tasks, logs, memory/site guides, vault boundaries, diagnostics, and dense operator controls.
- [ ] **Phase 21: Supervision, Pairing, and Remote Control** — Rebuild PhantomStream-style supervision and safe dashboard pairing on Chromium sessions.
- [ ] **Phase 22: Chrome Extension Ecosystem and Policy** — Preserve or enable Chromium extension support while separating extension permissions from Prometheus agent permissions.
- [ ] **Phase 23: Migration Parity, Security Hardening, and De-Falkon Gate** — Prove v1/FSB parity, complete security review, retire Falkon assumptions, and fail the build on unreviewed legacy dependencies.
- [ ] **Phase 24: Packaging, Release Validation, and Handoff** — Produce a reproducible macOS validation package with Chromium-based Prometheus identity, legal notices, docs, validation script, and next-milestone handoff.

## Phase Details

### Phase 11: Preservation Contract and Falkon Freeze

**Goal:** Make source removal recoverable and make the migration contract explicit.

**Requirements:** PRES-01, PRES-02, PRES-03, PRES-04, PRES-05, PRES-06, PRES-07

**Success criteria:**

1. `.context/falkon-preservation/falkon-prometheus-v1.bundle` restores the full Falkon-based v1 reference.
2. Patch series from upstream Falkon to Prometheus v1 is available under `.context/falkon-preservation/patches/`.
3. `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` captures decisions, assets, design tokens, behavior contracts, source references, and license boundaries.
4. Source wipe checklist says exactly what can be removed and what must stay.
5. v1 deferred human-visual checks are tagged for Chromium replacement or retirement.

**Planned work:**

- Verify nested Falkon HEAD and remote.
- Bundle nested repo and format patch series.
- Inventory assets, themes, fonts, icons, HTML surfaces, C++ services, MCP scripts, smoke tests, UI specs, and parity matrix.
- Add a GPL-to-Chromium license boundary note.
- Freeze `falkon/` as reference-only; no further feature work lands there.

### Phase 12: Chromium Checkout, Build, and Patch Discipline

**Goal:** Establish a clean upstream Chromium baseline that builds locally and can survive rebases.

**Requirements:** CHROM-01, CHROM-02, CHROM-03, CHROM-04, CHROM-05, CHROM-06, CHROM-07, CHROM-08

**Success criteria:**

1. Chromium source exists in an agreed source location and records an exact revision.
2. `gn gen out/Default` succeeds with documented args.
3. `autoninja -C out/Default chrome` succeeds on macOS.
4. Unmodified Chromium launches before Prometheus patches are introduced.
5. Root git ignores or isolates `.gclient`, Chromium source, `out/`, depot_tools, and generated artifacts according to the chosen layout.

**Planned work:**

- Install or locate `depot_tools`.
- Use official Chromium checkout flow (`fetch chromium`; shallow/no-history if selected).
- Exclude Chromium checkout from accidental root commits.
- Add `.context` notes for local disk/time expectations.
- Create run/build scripts that can be called from Conductor without relying on interactive shell state.

### Phase 13: Product Identity, Branding, and Legal Baseline

**Goal:** Make the Chromium app identify as Prometheus while preserving required attribution.

**Requirements:** BRAND-01, BRAND-02, BRAND-03, BRAND-04, BRAND-05, BRAND-06, BRAND-07

**Success criteria:**

1. App name, window title, app icon, bundle/profile identity, docs, and first-run/about surfaces use Prometheus.
2. "Powered by FSB" appears in the agreed product surfaces.
3. Chromium/Chrome branding is removed from product-facing surfaces where allowed by Chromium license and trademark constraints.
4. Legal/about surface includes Chromium and third-party notices, plus Font Awesome/Poppins/Space Mono notices when assets are bundled.
5. No GPL Falkon source is copied into the Chromium implementation without explicit review.

**Planned work:**

- Identify Chromium branding surfaces and product constants.
- Apply Prometheus app metadata and icon wiring.
- Create legal notices page/surface.
- Update README architecture language from Falkon/QtWebEngine to Chromium.
- Add a product identity inventory equivalent to the v1 Falkon inventory.

### Phase 14: Asset and Design System Port

**Goal:** Make Chromium-based Prometheus visually match the canonical warm design system.

**Requirements:** DESIGN-01, DESIGN-02, DESIGN-03, DESIGN-04, DESIGN-05, DESIGN-06, DESIGN-07

**Success criteria:**

1. Dark and light token sets render in Chromium WebUI and native UI surfaces.
2. Poppins and Space Mono load offline or through a deterministic packaged resource path.
3. Font Awesome Free subset is packaged with attribution and no network dependency.
4. PM mark, Prometheus wordmark, and FSB logos render correctly on dark/light surfaces.
5. Visual checks cover fonts, icons, text fit, focus, hover, disabled, warning, private, active-agent, and supervised states.

**Planned work:**

- Convert QSS token decisions to Chromium CSS variables and Views/theme constants.
- Create Chromium resource entries for assets and fonts.
- Port icon resolver concept to Chromium resource IDs and helper APIs.
- Add asset/license validation script.
- Preserve accent swatches: FSB Orange, Indigo, Teal, Rose.

### Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model

**Goal:** Rebuild the compact browser shell and advanced tab behavior on Chromium-native UI.

**Requirements:** UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-07

**Success criteria:**

1. Compact chrome places tabs in the toolbar and makes the active tab address/search field.
2. Separate/conventional layout remains available.
3. Tab groups, overview/search, quick switch, close/restore, unload/suspend, duplicate, detach, and reorder paths work.
4. Agent ownership, automation, supervision, tab health, audio/private/security, and extension state are visible without clutter.
5. macOS visual and keyboard behavior are acceptable across narrow, standard, and wide windows.

**Planned work:**

- Map Falkon compact-tab concepts to Chromium Views/tab-strip architecture.
- Add Prometheus chrome mode preference.
- Add side panel toggle and FSB action button.
- Add agent/supervision badges fed by the later agent service with temporary stub state.
- Add focused visual tests/screenshots once UI exists.

### Phase 16: Prometheus WebUI Surfaces and New Tab

**Goal:** Build browser-backed Prometheus WebUI pages for start, side panel, and control center.

**Requirements:** WEBUI-01, WEBUI-02, WEBUI-03, WEBUI-04, WEBUI-05, WEBUI-06, WEBUI-07

**Success criteria:**

1. `chrome://prometheus-newtab` or equivalent renders the Prometheus start page.
2. Ask FSB seeds the side panel without placing prompt content in URLs/history.
3. Internal FSB Control Panel WebUI includes the nine operator sections.
4. WebUI pages use browser-process data sources and Mojo/chrome-send style communication where appropriate.
5. WebUI pages load no remote resources and do not expose secrets to renderers.

**Planned work:**

- Register Prometheus WebUI hosts/controllers.
- Create WebUI resource targets and GRIT packaging.
- Port start page HTML/CSS behavior to Chromium WebUI.
- Build side panel shell with FSB Agent, Explorer, Tabs, Tools modes.
- Build control panel shell with Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix.
- Enable fast WebUI iteration docs using Chromium's `load_webui_from_disk` mode if practical.

### Phase 17: Native Agent Command Service and Tab Ownership

**Goal:** Rebuild Prometheus native routing inside Chromium's browser process.

**Requirements:** AGENT-01, AGENT-02, AGENT-03, AGENT-04, AGENT-05, AGENT-06, AGENT-07, AGENT-08

**Success criteria:**

1. Native service validates route input and returns structured route results.
2. Agent can list and control tabs/windows through Chromium browser-owned APIs.
3. Agent sessions are authenticated and browser-assigned.
4. Tab ownership is keyed by stable WebContents/tab identity.
5. Internal surfaces are behind explicit adapters and permission policies.
6. Typed errors and recovery guidance match FSB/Prometheus expectations.

**Planned work:**

- Create Prometheus browser-process service and route schema.
- Add route auth/session registry.
- Add tab registry and ownership enforcement.
- Add basic route logging/audit record.
- Add unit/browser tests for auth, ownership, caps, and typed errors.

### Phase 18: Page Adapter, DOM Snapshot, and Action Verification

**Goal:** Restore page understanding and actions on Chromium content primitives.

**Requirements:** PAGE-01, PAGE-02, PAGE-03, PAGE-04, PAGE-05, PAGE-06, PAGE-07, PAGE-08

**Success criteria:**

1. Page text, DOM snapshot, and compact snapshot routes work on normal pages.
2. JS execution route is permissioned, audited, result-capturing, and read-back verified.
3. Page action routes support click/type/key/scroll/hover/select/clear/drag/drop where safe.
4. Mutating actions wait for load/stability/visible change and return change reports.
5. Cross-origin, sandbox, restricted, and unsupported target failures are explicit.

**Planned work:**

- Implement WebContents/frame targeting.
- Add renderer helper where needed for DOM snapshots and element refs.
- Implement action verification and wait logic.
- Add stuck/repeated action detection.
- Add tests against local fixtures with forms, frames, navigation, and dynamic DOM changes.

### Phase 19: MCP Bridge and Multi-Agent Runtime Compatibility

**Goal:** Make existing FSB-style MCP clients drive the Chromium-native service.

**Requirements:** MCP-01, MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MCP-07

**Success criteria:**

1. Local stdio MCP bridge connects to Chromium-based Prometheus.
2. Manual/read/runtime tools expose compatible names and schemas.
3. Visual-session fields are accepted and preserved.
4. Multi-agent ownership, caps, reconnect grace, and background tab routing are enforced.
5. Diagnostics report health for browser, bridge, tab, page adapter, internal adapter, WebUI adapter, vault, provider, supervision, and extensions.

**Planned work:**

- Port or rewrite the dependency-light Node MCP bridge.
- Map MCP tools to Chromium route server.
- Add compatibility stubs for changed/unsupported tools.
- Add smoke tests equivalent to `smoke-mcp-bridge.sh` and FSB reference tests.
- Add diagnostics endpoint and output shape.

### Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel

**Goal:** Restore user-facing FSB runtime functionality inside Chromium-based Prometheus.

**Requirements:** FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, FSB-07, FSB-08

**Success criteria:**

1. User can run tasks from side panel with provider/local/MCP execution modes.
2. Provider configuration supports OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, hosted/routed/local/custom endpoints, and fallback order.
3. Secrets never display after save and never cross MCP/remote transports.
4. Logs, diagnostics, metrics, token/cost accounting, memory, site guides, and vault metadata are visible in the control panel.
5. Settings expose internal-surface permissions, caps, ownership, background actions, telemetry, vault boundaries, and supervision pairing.

**Planned work:**

- Build runtime model/service.
- Add secure storage adapter for provider/vault secrets.
- Wire side panel task composer to runtime service.
- Populate control panel sections.
- Add tests for provider config, secret redaction, memory/site-guide CRUD, logs, and runtime status.

### Phase 21: Supervision, Pairing, and Remote Control

**Goal:** Rebuild DOM-native supervision and safe dashboard pairing on Chromium sessions.

**Requirements:** SUP-01, SUP-02, SUP-03, SUP-04, SUP-05

**Success criteria:**

1. Browser shows visible active-agent and supervised-action state.
2. Supervision stream emits structured snapshots/diffs or equivalent data with session identity.
3. Dashboard pairing has visible state, expiration, revocation, audit logs, and target validation.
4. Remote control honors ownership, permission, vault, and confirmation boundaries.
5. Stale or mismatched supervision messages cannot affect the wrong tab.

**Planned work:**

- Port PhantomStream-style DOM snapshot/diff concepts to Chromium.
- Add pairing/session model.
- Add remote-control route gates.
- Add visual supervised-state badges in chrome and side panel.
- Add tests for stale sessions, target mismatch, expiration, and revocation.

### Phase 22: Chrome Extension Ecosystem and Policy

**Goal:** Use Chromium's extension ecosystem without giving extensions Prometheus agent privileges by accident.

**Requirements:** EXT-01, EXT-02, EXT-03, EXT-04, EXT-05, EXT-06

**Success criteria:**

1. Chromium extension system is enabled or intentionally scoped with documented limitations.
2. User can install/manage compatible extensions through an approved flow or documented developer/sideload path.
3. Extension permissions are separate from agent permissions.
4. Agent routing detects extension surfaces and applies explicit policy before reading or mutating.
5. Representative extensions are tested across password manager, ad blocker, productivity/content script, side panel/tooling, and developer extension categories.

**Planned work:**

- Inventory Chromium extension features available in the chosen build.
- Decide install/store/sideload/developer flow.
- Add extension-surface policy to agent router.
- Add diagnostics for extension subsystem.
- Document disabled Google-service or store limitations.

### Phase 23: Migration Parity, Security Hardening, and De-Falkon Gate

**Goal:** Prove that Chromium Prometheus meets or consciously retires v1 behavior and is safe enough for a validation package.

**Requirements:** REL-01, REL-02, REL-03, REL-04, REL-07

**Success criteria:**

1. Parity matrix maps every v1 capability and FSB category to Missing, Partial, Parity, Better, Blocked, or Verified.
2. Security review covers route auth, tab ownership, JS execution, internal WebUI mutation, extension boundaries, vault, provider secrets, remote pairing, logs, and telemetry.
3. Visual verification covers chrome, side panel, control panel, start page, themes, fonts, icons, extension surfaces, and macOS packaging.
4. Build or validation fails on active `falkon/`, Qt/Falkon build script dependency, Falkon product strings in primary UI, or unreviewed GPL-derived source.
5. Migration blockers are either fixed or explicitly carried to v2.1.

**Planned work:**

- Build new `FSB-PARITY.md` for Chromium.
- Port release validation checks and add de-Falkon static checks.
- Run code review/security review.
- Run visual UAT for all major surfaces.
- Remove or quarantine leftover legacy assumptions.

### Phase 24: Packaging, Release Validation, and Handoff

**Goal:** Produce a coherent Chromium-based Prometheus validation package and next-step handoff.

**Requirements:** REL-01, REL-05, REL-06

**Success criteria:**

1. macOS package builds reproducibly with Prometheus identity and required notices.
2. Package includes source/license guidance and excludes Falkon product artifacts.
3. Release validation script passes build, smoke, chrome, WebUI, MCP, agent control, page adapters, extension support, security, branding, assets, legal notices, and parity gates.
4. README and handoff docs explain Chromium base, revision, supported platforms, known limitations, extension support, MCP setup, and safety model.
5. v2.1 backlog is explicit: Linux/Windows, Lattice, hosted/fleet control, notarization/update channel, enterprise policy.

**Planned work:**

- Package Chromium-based app as Prometheus for local macOS validation.
- Add release docs and source guidance.
- Run all validation gates.
- Archive v2.0 milestone artifacts.
- Prepare next milestone candidates.

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 11. Preservation Contract and Falkon Freeze | v2.0 | PRES-01..PRES-07 | Planned | — |
| 12. Chromium Checkout, Build, and Patch Discipline | v2.0 | CHROM-01..CHROM-08 | Planned | — |
| 13. Product Identity, Branding, and Legal Baseline | v2.0 | BRAND-01..BRAND-07 | Planned | — |
| 14. Asset and Design System Port | v2.0 | DESIGN-01..DESIGN-07 | Planned | — |
| 15. Chromium UI Shell, Compact Chrome, and Tab Model | v2.0 | UX-01..UX-07 | Planned | — |
| 16. Prometheus WebUI Surfaces and New Tab | v2.0 | WEBUI-01..WEBUI-07 | Planned | — |
| 17. Native Agent Command Service and Tab Ownership | v2.0 | AGENT-01..AGENT-08 | Planned | — |
| 18. Page Adapter, DOM Snapshot, and Action Verification | v2.0 | PAGE-01..PAGE-08 | Planned | — |
| 19. MCP Bridge and Multi-Agent Runtime Compatibility | v2.0 | MCP-01..MCP-07 | Planned | — |
| 20. FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | v2.0 | FSB-01..FSB-08 | Planned | — |
| 21. Supervision, Pairing, and Remote Control | v2.0 | SUP-01..SUP-05 | Planned | — |
| 22. Chrome Extension Ecosystem and Policy | v2.0 | EXT-01..EXT-06 | Planned | — |
| 23. Migration Parity, Security Hardening, and De-Falkon Gate | v2.0 | REL-01, REL-02, REL-03, REL-04, REL-07 | Planned | — |
| 24. Packaging, Release Validation, and Handoff | v2.0 | REL-01, REL-05, REL-06 | Planned | — |

**Totals:** 14 phases, 92 requirements planned, 0 complete.

## Deferred Beyond v2.0

- Linux and Windows Chromium-based builds after macOS-first validation.
- Lattice integration if it materially simplifies provider routing, receipts, policy, or agent runtime.
- Hosted/fleet control after local Chromium control and supervision are stable.
- Signed/notarized public release and automatic update channel.
- Enterprise policy templates.
