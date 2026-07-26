# Roadmap: Prometheus v2.0 Chromium Engine Migration

## Milestones

- Complete **v1.0 MVP** — Phases 1-10 (shipped 2026-06-17; archived under `.planning/milestones/`)
- Active **v2.0 Chromium Engine Migration** — Phases 11-24

## v2.0 Chromium Engine Migration

**Status:** In progress — Phase 21 is complete; Phase 22 remains planned and `not_ready`.

## Milestone Thesis

Prometheus keeps its product, design, and agent-native control thesis, but retires Falkon/QtWebEngine as the production base. v2.0 starts by preserving the v1 source reference and design/behavior decisions, then removes the active Falkon tree, checks out Chromium, establishes a reproducible Chromium baseline, and rebuilds Prometheus on Chromium-native primitives: Views/browser UI, WebUI, browser-process services, WebContents/RenderFrameHost/page adapters, local MCP bridge, extension support, secure runtime storage, supervision, and release validation.

## Active Phases

- [x] **Phase 11: Preservation Contract and Falkon Freeze** — Save every v1 decision, behavior, asset, test, source reference, and legal boundary before removing the active Falkon tree. (completed 2026-06-23)
- [x] **Phase 12: Chromium Checkout, Build, and Patch Discipline** — Bring in upstream Chromium with depot_tools, build it cleanly on macOS, and establish source/layout rules that keep the root repo clean. (completed 2026-06-24)
- [x] **Phase 13: Product Identity, Branding, and Legal Baseline** — Turn the Chromium baseline into a Prometheus-owned app identity with correct attribution and no unwanted Chrome/Chromium/Falkon/KDE-facing product surfaces. (completed 2026-06-24)
- [x] **Phase 14: Asset and Design System Port** — Port warm tokens, PM/FSB assets, Poppins, Space Mono, Font Awesome, dark/light themes, and visual state rules into Chromium resources. (completed 2026-07-07)
- [x] **Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model** — Rebuild the compact browser chrome and advanced tab workflows using Chromium-native UI architecture. (completed 2026-07-07)
- [x] **Phase 16: Prometheus WebUI Surfaces and New Tab** — Build Prometheus start page, side panel surfaces, and FSB Control Panel as Chromium WebUI/browser-backed surfaces. (completed 2026-07-07)
- [x] **Phase 17: Native Agent Command Service and Tab Ownership** — Rebuild the core native command router as a Chromium browser-process service with authenticated sessions and stable tab ownership. (completed 2026-07-07)
- [x] **Phase 18: Page Adapter, DOM Snapshot, and Action Verification** — Rebuild page reads, DOM snapshots, JS execution, action tools, waits, and verification on Chromium WebContents/frame primitives. (completed 2026-07-12)
- [x] **Phase 19: MCP Bridge and Multi-Agent Runtime Compatibility** — Reconnect existing FSB-style MCP clients to the Chromium-native service with multi-agent policy and typed compatibility errors. (completed 2026-07-13)
- [x] **Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel** — Restore provider-backed tasks, logs, memory/site guides, vault boundaries, diagnostics, and dense operator controls. (completed 2026-07-20)
- [x] **Phase 21: Supervision, Pairing, and Remote Control** — Rebuild PhantomStream-style supervision and safe dashboard pairing on Chromium sessions. (completed 2026-07-25)
- [ ] **Phase 22: Chrome Extension Ecosystem and Policy** — Preserve or enable Chromium extension support while separating extension permissions from Prometheus agent permissions.
- [ ] **Phase 23: Migration Parity, Security Hardening, and De-Falkon Gate** — Prove v1/FSB parity, complete security review, retire Falkon assumptions, and fail the build on unreviewed legacy dependencies.
- [ ] **Phase 24: Packaging, Release Validation, and Handoff** — Produce a reproducible macOS validation package with Chromium-based Prometheus identity, legal notices, docs, validation script, and next-milestone handoff.

## Phase Details

### Phase 11: Preservation Contract and Falkon Freeze

**Goal:** Make source removal recoverable and make the migration contract explicit.

**Requirements:** PRES-01, PRES-02, PRES-03, PRES-04, PRES-05, PRES-06, PRES-07

**Plans:** 3/3 plans complete

Plans:

- [x] 11-01-PLAN.md — Create the preservation evidence gate and canonical dossier evidence/license boundary.
- [x] 11-02-PLAN.md — Complete the capability-first Falkon-to-Chromium migration map and verifier invariants.
- [x] 11-03-PLAN.md — Add the deferred visual-check ledger, freeze checklist, and stale-doc cleanup gate.

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

**Plans:** 4/4 plans complete

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

**Plans:** 4/4 plans complete

Plans:

- [x] 13-01-PLAN.md — Author Prometheus smoke-launch gate and GPL Falkon source guard script
- [x] 13-02-PLAN.md — Author NOTICES.md, product identity inventory, legal notice inventory, and README update
- [x] 13-03-PLAN.md — Apply BRANDING and GRD string patches to Chromium tree; rebuild Prometheus.app
- [x] 13-04-PLAN.md — Run identity smoke gate, human visual verification, and phase handoff docs

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

**Plans:** 8/8 plans complete

Plans:
**Wave 1**

- [x] 14-01-PLAN.md — Wave 0: Phase 14 branch, test scaffold (RED stubs), verify-asset-pipeline.sh, convert-fa-icons.sh
- [x] 14-02-PLAN.md — Declare kColorPrometheus* ids in COMMON_CHROME_COLOR_IDS; register mixer last in AddChromeColorMixers
- [x] 14-04-PLAN.md — Vendor font/FA license metadata; source Poppins/SpaceMono/mark assets; write prometheus_fonts.css

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 14-03-PLAN.md — Fill warm dark/light palette + accent derivations in prometheus_color_mixer.cc (token tests GREEN)
- [x] 14-05-PLAN.md — Run FA icon conversion; declare prometheus_vector_icons GN target; write PrometheusAction resolver

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 14-06-PLAN.md — Write prometheus_resources.grd; wire pak into browser bundle; IDR resource tests GREEN

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 14-07-PLAN.md — Build chrome://prometheus-theme-preview WebUI dev surface + PrometheusTokenGalleryView

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 14-08-PLAN.md — Full gate run; tag VIS satisfied-by-Ph14-harness; export Phase 14 patches

### Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model

**Goal:** Rebuild the compact browser shell and advanced tab behavior on Chromium-native UI.

**Requirements:** UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-07

**Plans:** 6/6 plans complete

**Success criteria:**

1. Compact chrome places tabs in the toolbar and makes the active tab address/search field.
2. Separate/conventional layout remains available.
3. Tab groups, overview/search, quick switch, close/restore, unload/suspend, duplicate, detach, and reorder paths work.
4. Agent ownership, automation, supervision, tab health, audio/private/security, and extension state are visible without clutter.
5. Automated geometry, reachability, keyboard, and platform-behavior gates pass; human desktop screenshot UAT is consolidated into Phase 24 as non-blocking review.

**Planned work:**

- Map Falkon compact-tab concepts to Chromium Views/tab-strip architecture.
- Add Prometheus chrome mode preference.
- Add side panel toggle and FSB action button.
- Add agent/supervision badges fed by the later agent service with temporary stub state.
- Add focused visual tests/screenshots once UI exists.

### Phase 16: Prometheus WebUI Surfaces and New Tab

**Goal:** Build browser-backed Prometheus WebUI pages for start, side panel, and control center.

**Requirements:** WEBUI-01, WEBUI-02, WEBUI-03, WEBUI-04, WEBUI-05, WEBUI-06, WEBUI-07

**Plans:** 6/6 plans complete

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

**Plans:** 6/6 plans complete

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

**Plans:** 8/8 plans complete

Plans:

- [x] 18-01-PLAN.md — Extend page-route contracts and harden content-safe audit metadata.
- [x] 18-02-PLAN.md — Add deterministic page-adapter fixtures and browser-test harness.
- [x] 18-03-PLAN.md — Implement frame policy and `read_page` over Chromium text extraction.
- [x] 18-04-PLAN.md — Add the permissioned renderer/Mojo JavaScript execution seam.
- [x] 18-05-PLAN.md — Build bounded DOM and compact snapshots from Annotated Page Content.
- [x] 18-06-PLAN.md — Add renderer-side safe page actions and ref resolution.
- [x] 18-07-PLAN.md — Add page-settle waiting and repeated-action detection.
- [x] 18-08-PLAN.md — Wire action routes, verification reports, and typed drag/file-drop denials.

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

**Plans:** 7/7 plans complete

Plans:

- [x] 19-01-PLAN.md — Freeze the clean-room 90-name compatibility catalog, schemas, typed errors, and Wave 0 fixtures.
- [x] 19-02-PLAN.md — Add closed native route/result contracts and a strict bounded JSON transport codec.
- [x] 19-03-PLAN.md — Add regular-profile keyed session lifetime, opaque resume, cap, expiry, and ownership cleanup.
- [x] 19-04-PLAN.md — Add structured/background tab compatibility, safe internal surfaces, and exact-frame element reads.
- [x] 19-05-PLAN.md — Add the authenticated loopback gateway, secure descriptor, and browser-process lifetime wiring.
- [x] 19-06-PLAN.md — Implement the dependency-free external stdio MCP bridge and all manifest-backed tool behavior.
- [x] 19-07-PLAN.md — Run live browser-to-stdio smoke, full automated gates, patch export, and truthful documentation closeout.

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

**Plans:** 14/14 plans complete

Plans:

- [x] 20-01-PLAN.md — Define closed native runtime contracts, profile prefs, limits, and effective policy.
- [x] 20-02-PLAN.md — Implement bounded task, log, action, diagnostic, outcome, and usage persistence.
- [x] 20-03-PLAN.md — Implement bounded memory and exact-origin site-guide CRUD/search/apply.
- [x] 20-04-PLAN.md — Add OSCrypt-backed exact-origin secret storage and the provider registry.
- [x] 20-05-PLAN.md — Add three strict provider codec families and secure cancellable network transport.
- [x] 20-06-PLAN.md — Add safe-title persistence plus native policy and Agent-session-cap primitives.
- [x] 20-07-PLAN.md — Own the closed non-official provider bootstrap and assemble the regular-profile runtime, private local principal, safe tool loop, fallback, cancellation, and evaluation seam.
- [x] 20-08-PLAN.md — Add vault metadata, private Agent-authority insertion, and fail-closed fresh target confirmation.
- [x] 20-09-PLAN.md — Expose 27 closed runtime commands through the authenticated native gateway.
- [x] 20-10-PLAN.md — Promote all 31 Phase 20 MCP names to 27 native routes plus four aliases and prove built-app external smoke.
- [x] 20-11-PLAN.md — Migrate to exact-window side-panel ownership and wire the live task UI.
- [x] 20-12-PLAN.md — Populate live control-panel Tasks, Providers & Models, and Logs & Diagnostics.
- [x] 20-13-PLAN.md — Complete Memory, Site Guides, Vault, Settings, and exact-window native secret dialogs.
- [x] 20-14-PLAN.md — Run the 32-case integration corpus, full gates, patch export, and evidence closeout.

**Success criteria:**

1. User can submit tasks from the side panel in Auto, Provider, or Local mode; tasks submitted by external MCP clients run in the same native runtime and appear with MCP-driven provenance, never as an embedded engine.
2. Provider configuration supports OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, hosted/routed/local/custom endpoints, and fallback order.
3. Secrets never display after save and never cross MCP/remote transports.
4. Logs, diagnostics, metrics, token/cost accounting, memory, site guides, and vault metadata are visible in the control panel.
5. Settings expose enforced internal-surface permissions, caps, ownership, background actions, telemetry, and vault boundaries while supervision pairing remains truthfully `Not ready` for Phase 21.

**Planned work:**

- Build runtime model/service.
- Add secure storage adapter for provider/vault secrets.
- Wire side panel task composer to runtime service.
- Populate control panel sections.
- Add tests for provider config, secret redaction, memory/site-guide CRUD, logs, and runtime status.

### Phase 21: Supervision, Pairing, and Remote Control

**Goal:** Rebuild DOM-native supervision and safe dashboard pairing on Chromium sessions.

**Requirements:** SUP-01, SUP-02, SUP-03, SUP-04, SUP-05

**Plans:** 26/26 plans complete

Plans:
**Wave 1**

- [x] 21-01-PLAN.md — Freeze closed native supervision types and the focused verification scaffold.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 21-02-PLAN.md — Define the bounded dashboard supervision wire codec and privacy contract.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 21-03-PLAN.md — Implement the transport-independent DOM baseline, diff, sequence, and resync model.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 21-04-PLAN.md — Build pairing, viewer, controller, and Agent-owned tab-observation lifecycles.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 21-05-PLAN.md — Bind supervision safely to regular-profile Agent authority and teardown ordering.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 21-06-PLAN.md — Add the Blink document supplement and bidirectional dirty-signal Mojo path.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 21-07-PLAN.md — Create the sole browser-owned capture hub shared by all supervision consumers.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 21-08-PLAN.md — Attach independent dashboard viewers to exact-target capture-hub streams.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 21-09-PLAN.md — Add an abstract supervision dispatcher to the authenticated loopback gateway.

**Wave 10** *(blocked on Wave 9 completion)*

- [x] 21-10-PLAN.md — Promote the five closed supervision commands into the native route contract.

**Wave 11** *(blocked on Wave 10 completion)*

- [x] 21-11-PLAN.md — Wire the five commands through exact-browser Agent dispatch and composition.

**Wave 12** *(blocked on Wave 11 completion)*

- [x] 21-12-PLAN.md — Implement MCP supervision semantics as an independent shared-hub consumer.

**Wave 13** *(blocked on Wave 12 completion)*

- [x] 21-13-PLAN.md — Promote the five supervision tools in the dependency-free Node catalog.

**Wave 14** *(blocked on Wave 13 completion)*

- [x] 21-14-PLAN.md — Route remote control through the existing typed Agent action engine.

**Wave 15** *(blocked on Wave 14 completion)*

- [x] 21-15-PLAN.md — Add native consent and revalidation for control and consequential actions.

**Wave 16** *(blocked on Wave 15 completion)*

- [x] 21-16-PLAN.md — Project sanitized supervision state into browser-owned tab state.

**Wave 17** *(blocked on Wave 16 completion)*

- [x] 21-17-PLAN.md — Wire the existing native tab badge to live supervision state.

**Wave 18** *(blocked on Wave 17 completion)*

- [x] 21-18-PLAN.md — Add exact-tab native runtime and stop actions for the side-panel strip.

**Wave 19** *(blocked on Wave 18 completion)*

- [x] 21-19-PLAN.md — Render the persistent responsive supervision strip in the side panel.

**Wave 20** *(blocked on Wave 19 completion)*

- [x] 21-20-PLAN.md — Add strict Control Panel snapshots and one-shot pairing creation.

**Wave 21** *(blocked on Wave 20 completion)*

- [x] 21-21-PLAN.md — Complete Control Panel lifecycle actions, observation, and code erasure.

**Wave 22** *(blocked on Wave 21 completion)*

- [x] 21-22-PLAN.md — Finish the responsive Supervision & Pairing Control Panel UI.

**Wave 23** *(blocked on Wave 22 completion)*

- [x] 21-23-PLAN.md — Add the gated two-slot smoke bootstrap and conditional gateway contract path.

**Wave 24** *(blocked on Wave 23 completion)*

- [x] 21-24-PLAN.md — Bind the test handoff only from browser composition with fail-closed teardown.

**Wave 25** *(blocked on Wave 24 completion)*

- [x] 21-25-PLAN.md — Prove native dialogs and two-viewer/MCP supervision in the built app.

**Wave 26** *(blocked on Wave 25 completion)*

- [x] 21-26-PLAN.md — Run exact verification, export ordered patches, and publish closeout evidence.

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
3. Automated visual, layout, resource, and packaging verification covers chrome, side panel, control panel, start page, themes, fonts, icons, extension surfaces, and macOS packaging.
4. Build or validation fails on active `falkon/`, Qt/Falkon build script dependency, Falkon product strings in primary UI, or unreviewed GPL-derived source.
5. Migration blockers are either fixed or explicitly carried to v2.1.

**Planned work:**

- Build new `FSB-PARITY.md` for Chromium.
- Port release validation checks and add de-Falkon static checks.
- Run code review/security review.
- Assemble automated visual/layout evidence for all major surfaces and carry remaining human screenshot review to Phase 24 as non-blocking.
- Remove or quarantine leftover legacy assumptions.

### Phase 24: Packaging, Release Validation, and Handoff

**Goal:** Produce a coherent Chromium-based Prometheus validation package and next-step handoff.

**Requirements:** REL-01, REL-04, REL-05, REL-06

**Success criteria:**

1. macOS package builds reproducibly with Prometheus identity and required notices.
2. Package includes source/license guidance and excludes Falkon product artifacts.
3. Release validation script passes build, smoke, chrome, WebUI, MCP, agent control, page adapters, extension support, security, branding, assets, legal notices, and parity gates.
4. README and handoff docs explain Chromium base, revision, supported platforms, known limitations, extension support, MCP setup, and safety model.
5. v2.1 backlog is explicit: Linux/Windows, Lattice, hosted/fleet control, notarization/update channel, enterprise policy.
6. Remaining human visual UAT is offered as a consolidated, non-blocking release review; skipping screenshots does not block the local validation package when automated gates pass.

**Planned work:**

- Package Chromium-based app as Prometheus for local macOS validation.
- Add release docs and source guidance.
- Run all validation gates.
- Offer the consolidated human visual review and record it as passed, skipped, or findings-reported without making it a packaging gate.
- Resolve or explicitly disposition the Phase 20 UI audit carry-forward:
  waiting-confirmation review, current-tab vault use, transactional vault-save
  failure handling, control-panel detail/filter gaps, and token normalization.

- Archive v2.0 milestone artifacts.
- Prepare next milestone candidates.

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 11. Preservation Contract and Falkon Freeze | v2.0 | 3/3 | Complete   | 2026-06-23 |
| 12. Chromium Checkout, Build, and Patch Discipline | v2.0 | 4/4 | Complete    | 2026-06-24 |
| 13. Product Identity, Branding, and Legal Baseline | v2.0 | 4/4 | Complete    | 2026-06-24 |
| 14. Asset and Design System Port | v2.0 | 8/8 | Complete    | 2026-07-07 |
| 15. Chromium UI Shell, Compact Chrome, and Tab Model | v2.0 | 6/6 | Complete   | 2026-07-07 |
| 16. Prometheus WebUI Surfaces and New Tab | v2.0 | 6/6 | Complete | 2026-07-07 |
| 17. Native Agent Command Service and Tab Ownership | v2.0 | 6/6 | Complete | 2026-07-07 |
| 18. Page Adapter, DOM Snapshot, and Action Verification | v2.0 | 8/8 | Complete    | 2026-07-12 |
| 19. MCP Bridge and Multi-Agent Runtime Compatibility | v2.0 | 7/7 | Complete    | 2026-07-13 |
| 20. FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | v2.0 | 14/14 | Complete    | 2026-07-20 |
| 21. Supervision, Pairing, and Remote Control | v2.0 | 26/26 | Complete | 2026-07-25 |
| 22. Chrome Extension Ecosystem and Policy | v2.0 | 0 | Planned | — |
| 23. Migration Parity, Security Hardening, and De-Falkon Gate | v2.0 | 0 | Planned | — |
| 24. Packaging, Release Validation, and Handoff | v2.0 | 0 | Planned | — |

**Totals:** 14 phases, 11 complete; 92 of 92 existing v2.0 plans summarized.
Phase 21 is complete. Phase 22 remains planned and `not_ready`.

## Future Work Beyond Current Milestone

- Linux and Windows Chromium-based builds after macOS-first validation.
- Lattice integration if it materially simplifies provider routing, receipts, policy, or agent runtime.
- Hosted/fleet control after local Chromium control and supervision are stable.
- Signed/notarized public release and automatic update channel.
- Enterprise policy templates.
