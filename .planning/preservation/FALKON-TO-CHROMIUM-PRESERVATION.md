# Falkon to Chromium Preservation Dossier

**Created:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Purpose:** Preserve the product intent, design language, shipped v1 behavior, source reference, and asset inventory before retiring the Falkon/QtWebEngine implementation.

## Executive Decision

Falkon was a useful bootstrap shell, but it is no longer the right production base. Prometheus should migrate to upstream Chromium while keeping the full Prometheus product identity, FSB affiliation, DOM/native automation thesis, MCP contract, operator UI, supervision model, memory/vault/provider surfaces, compact chrome goals, themes, fonts, icons, and release discipline.

This is an engine/platform migration, not a product reset.

## Non-Negotiables To Preserve

- **Product name:** Prometheus.
- **Affiliation/tagline:** Powered by FSB.
- **Core value:** Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.
- **Control scope:** normal pages, browser-owned internal pages, settings, tabs, downloads, history, extension surfaces, and runtime/supervision state.
- **FSB compatibility:** existing FSB-style MCP clients should keep the manual action, read, runtime, memory/site-guide, vault, diagnostics, and visual-session contracts where practical.
- **Supervision:** visible human supervision, visible action state, audit logs, and safe remote pairing remain mandatory.
- **Secrets:** provider keys and vault secrets stay browser-native and must not cross MCP or remote-control transports.
- **Design language:** warm minimal operator UI, restrained black/paper surfaces, FSB orange accent, Poppins/Space Mono typography, Font Awesome Free icon subset, PM monogram, FSB assets, compact native browser chrome, side panel/control-panel split, and Prometheus start page.
- **Implementation philosophy:** native/browser-process ownership first; DOM/native inspection and verification are primary; screenshots are diagnostics/fallback only.
- **Safety boundary:** no stealth automation, no account-abuse workflow, no unaudited internal-page mutation.

## Source State Preserved Locally

The Falkon subtree is a nested git checkout, not tracked by the root repository as a submodule.

| Item | Value |
|------|-------|
| Nested repo path | `falkon/` |
| Upstream remote | `https://invent.kde.org/network/falkon.git` |
| Nested branch | `master` |
| Preserved HEAD | `b0521c9d37e7545c680b78dfcc24f777a984091c` |
| Ahead of upstream | 81 commits ahead of `origin/master` |
| Local bundle | `.context/falkon-preservation/falkon-prometheus-v1.bundle` |
| Patch series | `.context/falkon-preservation/patches/` |
| Active checkout status | already_removed — root `falkon/` must not be recreated as active source |

The preservation bundle was created before source removal planning:

```sh
git -C falkon bundle create ../.context/falkon-preservation/falkon-prometheus-v1.bundle --all
git -C falkon format-patch -o ../.context/falkon-preservation/patches origin/master..HEAD
```

To restore the reference later:

```sh
git clone .context/falkon-preservation/falkon-prometheus-v1.bundle falkon-restored
```

### Preservation Evidence Gate

- Expected preserved HEAD: b0521c9d37e7545c680b78dfcc24f777a984091c
- Expected patch count: 81
- Bundle path: .context/falkon-preservation/falkon-prometheus-v1.bundle
- Patch path: .context/falkon-preservation/patches/
- Restore check path pattern: .context/falkon-preservation/restore-check-*
- Active Falkon checkout status: already_removed
- Root git tracking rule: .context/ is ignored; preservation artifacts must not be committed to root git

Downstream developers run:

```sh
bash .planning/preservation/verify-preservation.sh
```

## Licensing Boundary

Falkon is GPLv3-derived. Chromium is BSD-style with many third-party licenses. The v2 migration must not casually copy Falkon GPL implementation code into the Chromium tree.

Default rule: preserve behavior, design, tests, protocol shapes, and asset provenance; do not copy GPL Falkon C++ implementation, Qt widget classes, QSS, packaging scripts, or inherited Falkon/KDE metadata into Chromium without explicit license review.

### Carry-forward classifications

| Material | Status | Rule |
|----------|--------|------|
| Behavior contracts and tool names | contract_only | Preserve expected behavior and protocol names; reimplement with Chromium-native owners. |
| Root `assets/` and `.planning/design/` assets | product_owned | Carry forward as Prometheus/FSB-owned assets when provenance notes stay attached. |
| Font Awesome, Poppins, and Space Mono | third_party_attribution_required | Carry forward only with required notices and bundled attribution intact. |
| Falkon C++/Qt/QSS/package metadata | reference_only | Use as reference evidence only, not as Chromium implementation source. |
| Any copied GPL implementation text | license_review_required | Do not move into Chromium without explicit license review and accepted obligations. |

Preserve these from Falkon as **reference material**:

- behavior contracts
- UI layouts
- design tokens
- asset lists
- test intent
- tool names and protocol shapes
- validation scripts and parity categories

Do not copy these without explicit license review:

- Falkon C++ implementation files
- Qt widget classes
- QSS files if treated as source derivative instead of design-token reference
- Falkon packaging scripts
- inherited Falkon/KDE/Qt-specific metadata

Safe carry-forward candidates:

- Prometheus/FSB-owned assets already under root `assets/` and design artifacts in `.planning/design/`.
- Font Awesome Free icons when attribution and CC BY 4.0 requirements are preserved.
- Poppins and Space Mono font files when SIL OFL notices remain bundled.
- Fresh Chromium-native implementations of equivalent behavior.

## Canonical Design Language

Source of truth:

- `.planning/design/DESIGN-REFERENCE.md`
- `.planning/design/prometheus-browser/prometheus/styles.css`
- `.planning/design/prometheus-brand/Prometheus Logo.html`
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`
- `.planning/phases/09-offline-font-awesome-free-icon-system-and-minimal-themes/09-UI-SPEC.md`
- `.planning/phases/10-new-tab-start-page/10-UI-SPEC.md`

### Palette

| Token | Dark | Light | Use |
|-------|------|-------|-----|
| accent | `#ff6b35` | `#ff6b35` | FSB orange, primary CTA, focus, active agent/supervision, logo |
| accent-2 | `#ff8c42` | `#ff8c42` | accent gradient end |
| bg-app | `#0d0a09` | `#e9e2da` | desktop/window backdrop |
| chrome | `#1d1816` | `#f3ede6` | toolbar and side panel |
| chrome-2 | `#181311` | `#ece4db` | panel/chrome gradient secondary |
| surface | `#141110` | `#fffdfb` | content/page surface |
| surface-2 | `#1d1816` | `#f8f4ef` | cards, tool rows, segmented tracks |
| surface-3 | `#26201d` | `#f1ebe4` | hover/elevated surfaces |
| tab-active | `#2a221e` | `#fffdfb` | active compact tab/address pill |
| text | `#f6efe9` | `#1f1a17` | primary text |
| text-2 | `#d2c1b4` | `#6a584d` | secondary text |
| text-3 | `#a99283` | `#8d7a6e` | tertiary/metadata text |

Accent use is intentionally sparse. Orange is for primary action, active automation, focus, selected state, supervised state, and the mark. It is not a general link color or broad decorative wash.

### Typography

- **Poppins**: display, wordmark, PM mark. Required weights: Thin 100, Light 300, ExtraBold 800, Black 900.
- **Space Mono**: version tags, section labels, URLs, logs, status metadata, pairing codes.
- **System UI**: body text, dense settings rows, browser UI copy.

The PM mark is weight-split, not a single text style:

- `P`: Poppins Thin 100.
- `M`: Poppins Black 900.
- version tag: `▽0.1` in Space Mono with wide tracking.

### UI Structure

- Compact unified browser bar: traffic lights, navigation, sidebar toggle, tab strip, right tools, FSB agent button, all tabs, theme/menu affordances.
- Active compact tab expands into the address/search field.
- Side panel is 320px and mode-driven: FSB Agent, Explorer, Tabs, Tools.
- Dense operator controls live on an internal FSB Control Panel page, not in the side panel.
- Start page contains hero PM mark, Prometheus wordmark, omnibox, Ask FSB handoff, favorites, and suggested automations.
- Avoid marketing-page composition inside the browser product. Prometheus should feel like a native tool and operator workstation, not a landing page.

## Asset Inventory To Preserve

### Root Repository Assets

These are already outside Falkon and must stay:

| Path | Role |
|------|------|
| `assets/prometheus.svg` | Legacy/canonical product mark source for external docs |
| `assets/prometheus-icon.svg` | README hero icon and product mark artifact |
| `assets/prometheus-wordmark.svg` | README dark-mode Prometheus wordmark artifact |
| `assets/prometheus-wordmark-light.svg` | README light-mode Prometheus wordmark artifact |
| `assets/fsb_logo_dark.png` | FSB logo on dark |
| `assets/fsb_logo_light.png` | FSB logo on light |
| `assets/fsb_logo_dark_footer.png` | Footer variant |
| `assets/fsb_logo_light_footer.png` | Footer variant |

### Planning Design Assets

| Path | Role |
|------|------|
| `.planning/design/prometheus-browser/prometheus/assets/fsb_icon.png` | FSB icon reference |
| `.planning/design/prometheus-browser/prometheus/assets/fsb_logo_dark.png` | FSB dark logo reference |
| `.planning/design/prometheus-browser/prometheus/assets/fsb_logo_light.png` | FSB light logo reference |
| `.planning/design/prometheus-browser/prometheus/styles.css` | canonical token source |
| `.planning/design/prometheus-browser/prometheus/SidePanel.jsx` | side panel behavior/layout reference |
| `.planning/design/prometheus-browser/prometheus/StartPage.jsx` | start page behavior/layout reference |
| `.planning/design/prometheus-browser/prometheus/app.jsx` | shell/chrome reference |
| `.planning/design/prometheus-browser/prometheus/tweaks-panel.jsx` | settings/tweak reference |

### Falkon-Derived Prometheus Assets

These are preserved in the bundle/patch series and should be reintroduced into Chromium only through a license-reviewed asset pipeline:

| Path | Role |
|------|------|
| `falkon/src/lib/data/assets/fsb_icon.png` | FSB icon in Qt resources |
| `falkon/src/lib/data/assets/fsb_logo_dark.png` | FSB logo for dark theme |
| `falkon/src/lib/data/assets/fsb_logo_light.png` | FSB logo for light theme |
| `falkon/src/lib/data/assets/pm_dark.png` | PM mark dark treatment |
| `falkon/src/lib/data/assets/pm_light.png` | PM mark light treatment |
| `falkon/src/lib/data/icons/prometheus.svg` | Prometheus runtime icon |
| `falkon/src/lib/data/icons/exeicons/prometheus.svg` | app icon SVG |
| `falkon/src/lib/data/icons/exeicons/prometheus.icns` | macOS app icon |
| `falkon/src/lib/data/icons/exeicons/prometheus-light.icns` | alternate macOS app icon |
| `falkon/linux/hicolor/sc-apps-prometheus.svg` | Linux icon |
| `falkon/src/lib/data/fonts/poppins/*.ttf` | Poppins offline font weights |
| `falkon/src/lib/data/fonts/poppins/OFL.txt` | Poppins license |
| `falkon/src/lib/data/fonts/spacemono/*.ttf` | Space Mono offline font |
| `falkon/src/lib/data/fonts/spacemono/OFL.txt` | Space Mono license |
| `falkon/src/lib/data/icons/fa/*.svg` | Font Awesome Free SVG subset |
| `falkon/themes/prometheus/*.qss` | warm dark/light/common theme reference |
| `falkon/src/lib/data/html/start.html` | implemented start page reference |

Font Awesome notes from v1:

- 69 unique glyphs were vendored.
- `arrow-down-to-line` was substituted with `arrow-down` where Free 6.x lacked the requested glyph.
- `sidebar-flip.svg` was a custom placeholder because the original glyph was Pro-only.
- Attribution comments must remain in every bundled SVG.

## Behavior Inventory To Rebuild On Chromium

### Native Agent Control

Current reference implementation:

- `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`
- `falkon/src/lib/agent/agentruntime.{h,cpp}`
- `falkon/tools/prometheus-mcp/server.mjs`
- `falkon/tools/prometheus-mcp/smoke.mjs`
- `falkon/autotests/agentcommandroutertest.*`

Chromium target:

- browser-process Prometheus service under a Chromium-native namespace, for example `chrome/browser/prometheus/`.
- tab/session identity keyed by stable `WebContents` identity, not mutable tab index.
- browser-owned authentication for MCP/native control, not caller-supplied labels.
- typed route dispatch for tabs, navigation, page reads, page mutations, internal surfaces, runtime tools, diagnostics, vault, memory, supervision.

### Page Understanding And Actions

Current contract to preserve:

- DOM snapshot with element refs, selectors, forms, ARIA labels, text, attributes.
- compact page snapshot for planning.
- visible text reads.
- JS execution with permission, audit, result, and verification state.
- click, type, key press, scroll, hover, select, clear, drag/drop where supported.
- wait-for-load, DOM stability, visible-state change, read-back verification.
- stuck/repeated action detection.

Chromium target:

- use `content::WebContents`, `RenderFrameHost`, browser-process routing, and renderer-side helpers where needed.
- prefer Chromium-native frame and accessibility plumbing where it gives stronger guarantees.
- use page-injected JS only as an explicit, audited adapter, not as the only architecture.

### MCP Compatibility

Current reference:

- FSB manual action tools.
- FSB read tools.
- visual-session fields: `visual_reason`, `client`, `is_final`.
- typed errors: `TAB_NOT_OWNED`, `AGENT_CAP_REACHED`, `TAB_INCOGNITO_NOT_SUPPORTED`, `TAB_OUT_OF_SCOPE`, `PERMISSION_BLOCKED`, `PROVIDER_NOT_CONFIGURED`.
- local stdio bridge to native router.

Chromium target:

- keep tool names stable unless a compatibility stub gives explicit migration guidance.
- preserve browser-controlled session identity and tab ownership.
- keep bridge dependency-light; use Node only for stdio/MCP glue if native route server remains simpler.

### FSB Runtime Surfaces

Reference surfaces:

- side panel: Task/Agent, Providers, Logs, Memory, Vault, later four modes: FSB Agent, Explorer, Tabs, Tools.
- FSB Control Panel page: Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix.

Chromium target:

- implement side panel using Chromium's native side panel/WebUI infrastructure or Views-backed browser UI.
- implement dense operator pages as `chrome://prometheus` / `chrome://prometheus-control` WebUI pages with browser-process backing.
- keep secrets in platform/browser secure storage and out of renderer/MCP transports.

### Compact Chrome And Tabs

Reference classes:

- `falkon/src/lib/tabwidget/compacttabstrip.*`
- `falkon/src/lib/tabwidget/compacttabdelegate.*`
- `falkon/src/lib/tabwidget/tabsearchpopup.*`
- `falkon/src/lib/tabwidget/tabgroupmodel.*`
- `falkon/src/lib/navigation/navigationbar.*`

Chromium target:

- port the behavior, not the Qt implementation.
- use Chromium Views/tab strip architecture where possible.
- preserve compact/separate layout choice, tab groups, tab search/overview, quick switch, close/restore, unload/suspend, duplicate, detach, owner/supervision badges, and health state.

### Start Page

Reference:

- `falkon/src/lib/data/html/start.html`
- `falkon/src/lib/agent/prometheusstartbridge.*`
- `.planning/phases/10-new-tab-start-page/10-UI-SPEC.md`

Chromium target:

- prefer a Prometheus-owned WebUI page, for example `chrome://prometheus-newtab`, then wire it as the default new tab surface.
- use WebUI browser/renderer communication instead of QWebChannel.
- seed Ask FSB into the Prometheus side panel from WebUI.
- keep favorites and suggested automations.

## Capability Migration Map

This map is the Chromium migration contract. Each row preserves user-visible or agent-visible behavior, identifies reference evidence only, assigns a future Chromium owner, and records the parity proof and license boundary. `license_review_required` remains the status for any implementation text copied from GPL Falkon material.

| Capability | v1 Behavior Contract | Falkon Reference | Chromium Owner | Parity Evidence | License / Attribution Note |
|------------|----------------------|------------------|----------------|-----------------|----------------------------|
| Product identity and Powered by FSB | Prometheus remains the product name, with Powered by FSB presented as the affiliation in app, window, first-run, and docs surfaces. | `.planning/PROJECT.md`; `.planning/phases/02-prometheus-product-identity-shell/`; `falkon/src/lib/data/icons/prometheus.svg` | Phase 13 Product Identity, Branding, and Legal Baseline | Release validation check for app identity, window title, first-run, docs, and legal/about strings. | product_owned plus required attribution |
| Legal/about/source guidance | Users can find required Chromium, third-party, Font Awesome, Poppins, Space Mono, and preserved source guidance without exposing Falkon as active product identity. | `.planning/phases/01-baseline-and-legal-inventory/`; `.planning/chromium/CHROMIUM-CHECKOUT.md`; `.context/falkon-preservation/patches/` | Phase 13 Product Identity, Branding, and Legal Baseline and Phase 24 Packaging, Release Validation, and Handoff | Release validation check covering about/legal notices, source guidance, and package contents. | third_party_attribution_required |
| Warm dark/light tokens and accent rules | Dark and light themes keep the warm browser chrome, sparse FSB orange accent, readable text hierarchy, and active/supervised state colors. | `.planning/design/DESIGN-REFERENCE.md`; `.planning/design/prometheus-browser/prometheus/styles.css`; `falkon/themes/prometheus/*.qss` | Phase 14 Asset and Design System Port | Manual visual UAT plus WebUI/native theme tests for dark, light, focus, hover, disabled, warning, and supervised states. | contract_only; QSS reference_only |
| PM mark, Prometheus wordmark, FSB assets, Poppins, Space Mono | Prometheus mark, wordmark, FSB assets, and offline typography render deterministically across dark/light product surfaces. | `assets/`; `.planning/design/prometheus-brand/Prometheus Logo.html`; `falkon/src/lib/data/fonts/`; `falkon/src/lib/data/assets/` | Phase 14 Asset and Design System Port | Asset validation script plus manual visual UAT for logos, font loading, text fit, and package attribution. | product_owned plus third_party_attribution_required |
| Font Awesome Free offline icon subset | Required operator and browser icons render offline from packaged resources with no network or host theme dependency. | `falkon/src/lib/data/icons/fa/*.svg`; `.planning/phases/09-offline-font-awesome-free-icon-system-and-minimal-themes/09-VERIFICATION.md` | Phase 14 Asset and Design System Port | Asset validation script plus manual visual UAT for icon presence, theming, sizing, and attribution comments. | third_party_attribution_required |
| Compact chrome, separate layout option, tab groups, overview/search, quick switch | Users can choose compact or separate chrome while keeping tab groups, search/overview, quick switch, close/restore, unload/suspend, duplicate, detach, and agent/supervision state. | `falkon/src/lib/tabwidget/compacttabstrip.*`; `compacttabdelegate.*`; `tabsearchpopup.*`; `tabgroupmodel.*`; `falkon/src/lib/navigation/navigationbar.*` | Phase 15 Chromium UI Shell, Compact Chrome, and Tab Model | Phase 15 automated evidence: `15-VALIDATION.md`, 11-patch export under `15-chromium-ui-shell-compact-chrome-and-tab-model/patches/`, `prometheus_unittests`, targeted `browser_tests`, compact 800px layout test, toolbar entrypoint test, tab-search bubble test, and tab-command tests. Desktop screenshot UAT remains manual because Conductor capture could not foreground/window-target the native app. | contract_only; Qt widgets reference_only |
| Side panel four modes: FSB Agent, Explorer, Tabs, Tools | The side panel remains a mode-driven operator surface for agent work, page exploration, tab state, and tools without becoming the dense control panel. | `.planning/design/prometheus-browser/prometheus/SidePanel.jsx`; `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`; Falkon sidebar patches | Phase 16 Prometheus WebUI Surfaces and New Tab | Phase 16 automated evidence: `16-VALIDATION.md`, `16-VERIFICATION.md`, exported patches under `16-prometheus-webui-surfaces-and-new-tab/patches/`, and `phase16-06-browser-tests.log` covering side-panel WebUI mode labels plus toolbar-opened WebUI content. Manual density/polish UAT remains open. | contract_only; Qt sidebar implementation reference_only |
| FSB Control Panel nine operator sections | The internal control panel preserves Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, and Parity Matrix. | `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`; `falkon/src/lib/agent/fsbcontrolpanelpage.*` | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | Phase 16 established the browser-backed nine-section shell. Phase 20 automated evidence in `20-VALIDATION.md` and `20-VERIFICATION.md` proves live task/provider/model/log/memory/guide/vault-metadata/settings workflows, native-only secret entry and use, responsive/keyboard behavior, and truthful Phase 21 supervision state. Human visual review remains the non-blocking Phase 24 ledger item. | contract_only; Qt implementation reference_only |
| Prometheus start page, favorites, suggested automations, Ask FSB handoff | New tabs show the Prometheus start page, favorites, suggested automations, and Ask FSB handoff that seeds the side panel without leaking prompts into URL/history. | `falkon/src/lib/data/html/start.html`; `falkon/src/lib/agent/prometheusstartbridge.*`; `.planning/phases/10-new-tab-start-page/10-UI-SPEC.md` | Phase 16 Prometheus WebUI Surfaces and New Tab | Phase 16 automated evidence: `16-VALIDATION.md`, `16-VERIFICATION.md`, exported patches under `16-prometheus-webui-surfaces-and-new-tab/patches/`, and `phase16-06-browser-tests.log` covering new-tab rendering and Ask FSB handoff without URL/history prompt leakage. Manual dark/light visual UAT remains open. | contract_only; QWebChannel implementation reference_only |
| Native agent command router, auth, route results, tab ownership | Agents authenticate through browser-owned sessions, receive structured route results, and control tabs/windows only within ownership and permission boundaries. | `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`; `falkon/autotests/agentcommandroutertest.*`; `.planning/phases/03-native-agent-control-spine/` | Phase 17 Native Agent Command Service and Tab Ownership | Phase 17 automated evidence: `17-VALIDATION.md`, `17-VERIFICATION.md`, six exported patches under `17-native-agent-command-service-and-tab-ownership/patches/`, `phase17-06-prometheus-unittests.log` covering route/session/ownership/audit unit tests, and `phase17-06-browser-tests.log` covering service route actions, profile-scoped window targeting, unsafe URL-scheme rejection, internal surface ownership, side-panel route, tab commands, ownership denial, and metadata-only audit behavior. Page DOM/action, MCP bridge, runtime/provider/vault, and supervision behavior remain owned by later phases. | contract_only; C++ Falkon implementation reference_only |
| DOM/page snapshots, text reads, audited JS, action verification | Agents can read DOM/page/text state, run permissioned audited JS, and mutate pages only with wait, stability, visible-change, and read-back verification. | `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`; `falkon/autotests/agentcommandroutertest.*`; `.planning/phases/03-native-agent-control-spine/` | Phase 18 Page Adapter, DOM Snapshot, and Action Verification | Browser tests against forms, frames, navigation, dynamic DOM, restricted targets, and action verification fixtures. | contract_only |
| MCP bridge tool names, visual-session fields, typed compatibility errors | Existing FSB-style MCP clients keep compatible manual/read/runtime tool names, visual-session fields, ownership errors, and explicit compatibility errors where behavior changes. | `falkon/tools/prometheus-mcp/server.mjs`; `falkon/tools/prometheus-mcp/smoke.mjs`; `.planning/phases/04-mcp-compatibility-and-multi-agent-control/` | Phase 19 MCP Bridge and Multi-Agent Runtime Compatibility and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | Phase 19 established the clean-room dependency-free bridge. Phase 20 promotes the closed inventory to 49 native, 12 aliases, 22 typed stubs, five Phase 21 names, and two removed names; 75 Node tests, native/browser integration, and the built-app external-stdio smoke prove runtime forwarding without an embedded engine. | contract_only; archived Node bridge reference_only; Chromium bridge clean-room implementation |
| Provider runtime, logs, diagnostics, memory/site guides, vault metadata | Runtime surfaces preserve provider configuration, task status, logs, diagnostics, memory/site-guide metadata, and vault metadata while keeping secrets hidden from docs, renderers, MCP, and tests. | `falkon/src/lib/agent/agentruntime.{h,cpp}`; `.planning/phases/05-fsb-runtime-parity-surfaces/`; `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md` | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | Phase 20 automated evidence covers the bounded native state machine, 32-case adversarial fake-provider corpus across four wire families, direct secure transport, OSCrypt-backed profile secrets, fresh vault confirmation and target revalidation, sanitized persistence/accounting, memory/site-guide CRUD, live WebUI/MCP workflows, and built-app external smoke. | contract_only; secrets must not be copied into docs or tests |
| Supervision, pairing, remote preview identity, audit state | Supervised sessions show visible state, pair safely with expiration/revocation, stream identity-bound preview data, and audit remote control actions. | `.planning/phases/06-supervision-packaging-and-release-hardening/`; PhantomStream reference notes in `.planning/PROJECT.md`; supervision UI references in phase 08 docs | Phase 21 Supervision, Pairing, and Remote Control | Phase 21 automated evidence in `21-VALIDATION.md` and `21-VERIFICATION.md` proves browser-owned one-use local pairing, multiple independent viewers, one controller, structured bounded baselines/diffs, exact session/tab/document sequencing, native confirmation, owner/vault preservation, visible native/WebUI state, metadata-only audit, and fail-closed lifecycle teardown. The 71-patch export replays exactly from the Phase 20 baseline. Subjective supervised-state visual UAT remains the non-blocking Phase 24 ledger item. | contract_only; archived Falkon/PhantomStream implementation reference_only; Chromium implementation clean-room |
| Extension surfaces and extension-vs-agent permission boundary | Chromium extension support remains separate from Prometheus agent authority, and extension surfaces require explicit read/mutate policy before agent access. | `.planning/PROJECT.md`; `.planning/ROADMAP.md` Phase 22; v1 extension-policy requirements | Phase 22 Chrome Extension Ecosystem and Policy | Extension policy tests across representative extension categories plus parity matrix row for extension-surface handling. | contract_only |
| Parity/security/de-Falkon release gates and packaging handoff | Release gates prove migrated v1/FSB parity, security review, visual quality, no active Falkon source, no unreviewed GPL-derived code, and coherent package handoff. | `.planning/STATE.md` deferred items; `.planning/phases/08-*/08-VERIFICATION.md`; `.planning/phases/09-*/09-VERIFICATION.md`; `.planning/phases/10-new-tab-start-page/10-VERIFICATION.md` | Phase 23 Migration Parity, Security Hardening, and De-Falkon Gate and Phase 24 Packaging, Release Validation, and Handoff | Parity matrix row, security review, de-Falkon static check, release validation check, and manual visual UAT ledger. | contract_only plus third_party_attribution_required |

## Deferred Visual Check Ledger

Allowed statuses: `carry_forward` means the check still needs Chromium-equivalent functional or automated evidence; `satisfied-by-Ph14-harness` means Phase 14 automated asset/token coverage satisfied the check; `retired` means the original Falkon-only surface is intentionally removed or superseded by a named later Chromium phase.

Human-review policy (2026-07-12): the 20 rows that remain `carry_forward` keep their named implementation owners and mandatory automated evidence. Any remaining human screenshot/UAT portion is consolidated into Phase 24 as one non-blocking release review. A skipped human review cannot satisfy a missing automated or functional gate, but it does not block the local validation package when those gates pass.

Phase 15 evidence note: compact chrome and advanced tab-management behavior now have Chromium-native automated coverage and exported patches. This satisfies the Phase 7 compact-chrome implementation carry-forward at the automated-test level. Desktop screenshot review is not marked complete; it is consolidated into the non-blocking Phase 24 release review.

Phase 16 evidence note: Prometheus WebUI hosts, start page handoff, side-panel shell, control-panel shell, packaged resource safety, and renderer-visible handoff safety now have Chromium-native automated coverage and a 9-patch export from `a4423116ff..HEAD`. This satisfies Phase 16 WebUI shell evidence at the automated-test level. Desktop visual review is consolidated into Phase 24 as non-blocking; later provider/vault/runtime functional checks remain mandatory.

Phase 17 evidence note: Native agent route schema, browser-issued sessions, reconnect/cap errors, tab ownership data, profile-scoped tab/window/navigation routes, internal Prometheus surface routes, unsafe URL-scheme rejection, typed errors, and metadata-only audit records now have Chromium-native automated coverage and a six-patch export from `b46e7a5d1e..HEAD`. This satisfies Phase 17 native route/session/ownership/audit evidence at the automated-test level, but it does not retire Phase 18 DOM/page action verification, Phase 19 MCP bridge compatibility, Phase 20 runtime/provider/vault data, or Phase 21 supervision/pairing checks.

Phase 19 evidence note: A dependency-free external stdio bridge, exact 90-name compatibility inventory, authenticated owner-only loopback descriptor/gateway, browser-issued profile sessions, stable tab ownership, exact-frame reads, optional visual metadata, truthful ten-component diagnostics, opaque resume/expiry/close behavior, and bounded retired-session cleanup now have Chromium-native automated coverage and a 19-patch export from `caae2f6a81..HEAD`. The live gate launches the built Prometheus app and separately spawned Prometheus-owned bridge under local test flags. No human UAT was run. This evidence does not mark Phase 20 runtime/provider/vault/memory/log data, Phase 21 supervision/pairing, or Phase 22 extension health ready.

Phase 20 evidence note: The regular-profile native runtime, bounded task/store/accounting state, four provider wire families, fixed/remote/local endpoint policy, OSCrypt-backed provider and vault secrets, per-use native confirmation, exact-origin memory/site guides, live side/control WebUI, and 31 promoted external MCP compatibility names now have automated evidence and an ordered 54-patch export with exact stable identities from `460caac2f9..HEAD`. Fresh closeout gates cover 208 Phase 20 native tests, 24 content/renderer tests, 84 Phase 17–19 native regressions, 37 Phase 20 browser tests, 83 Phase 17–19 browser regressions, 75 Node tests, the built-app external MCP smoke, and recursive security/preservation checks. Supervision/pairing remains Phase 21, extension policy remains Phase 22, parity/security remains Phase 23, and the consolidated human visual review remains non-blocking Phase 24 work. `human_uat: not_run`.

Phase 21 evidence note: Regular-profile browser-owned pairing, opaque dashboard
sessions, independent viewer cursors, a sole controller lease, APC-derived
baseline/diff capture, document epochs, bounded resync, five native MCP
compatibility routes, native tab/side-panel/Control Panel state, consequential
action confirmation, and metadata-only audit now have Chromium-native
automated coverage. Fresh closeout gates cover 189 Phase 21 native tests, 12
Blink renderer tests, 50 Phase 21 browser tests, 208 Phase 20 native
regressions, 84 Phase 17–19 native regressions, 21 Phase 20 content
regressions, three Phase 19 renderer security regressions, 37 Phase 20 browser
regressions, 83 Phase 17–19 browser regressions, 81 Node tests, the
54/12/22/0/2 catalog, and built-app multi-viewer/MCP smoke. Exactly 71 ordered
source-only patches replay from
`5632dcef07121bf4c3444cc2da13f222b6a61e91` to
`2c93cf8831c961f0a7d0c35909f0da89d02a0b59` with stable identities and
mutation rejection. Extension policy remains Phase 22 `not_ready`,
migration-wide parity/security remains Phase 23, and subjective desktop visual
review remains non-blocking Phase 24 work. `human_uat: not_run`.

| ID | Original Phase | Original Check | Chromium Owner | Status | Rationale / Future Evidence |
|----|----------------|----------------|----------------|--------|-----------------------------|
| VIS-08-01 | Phase 08 | Control panel window opens from router surface | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 automated browser tests verify the live control route and workflows; only consolidated Phase 24 visual review remains. |
| VIS-08-02 | Phase 08 | All nine section names visible in the section rail | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 automated tests cover all nine live sections and truthful later-phase states; only consolidated Phase 24 visual review remains. |
| VIS-08-03 | Phase 08 | Section switching navigates content pages | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 automated keyboard, rail/select, and responsive switching passes; only consolidated Phase 24 visual review remains. |
| VIS-08-04 | Phase 08 | 48px header band layout | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI screenshot/UAT at default control panel width. |
| VIS-08-05 | Phase 08 | Secret fields use password echo mode | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 proves secrets are entered only in native dialogs and values never render in WebUI; Phase 24 retains the visual dialog review. |
| VIS-08-06 | Phase 08 | Provider list shows key state metadata only | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 automated DOM/snapshot gates prove provider metadata-only rendering; Phase 24 retains the visual review. |
| VIS-08-07 | Phase 08 | Vault list shows metadata only | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 automated DOM/snapshot gates prove vault metadata-only rendering and native-only values; Phase 24 retains the visual review. |
| VIS-08-08 | Phase 08 | Parity Matrix section has Open Parity Matrix button and parsed table | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 23 Migration Parity, Security Hardening, and De-Falkon Gate | carry_forward | Re-run as Chromium WebUI parity-table evidence and Phase 23 parity gate. |
| VIS-08-09 | Phase 08 | No layout overlap at 320px | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI responsive screenshot/UAT at 320px. |
| VIS-08-10 | Phase 08 | Side panel four modes accessible via Ctrl+Shift+P | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as browser-process side panel handoff test. |
| VIS-09-01 | Phase 09 | Two-weight PM monogram rendering in sidebar header | Phase 14 Asset and Design System Port | satisfied-by-Ph14-harness | Covered by bundled Poppins asset packaging and manifest-resolution tests. |
| VIS-09-02 | Phase 09 | About dialog PrometheusMarkWidget(Large) at 128px | Phase 13 Product Identity, Branding, and Legal Baseline and Phase 14 Asset and Design System Port | carry_forward | Re-run as Chromium about/legal screenshot/UAT for PM mark and version tag. |
| VIS-09-03 | Phase 09 | Dark/light theme toggle without restart | Phase 14 Asset and Design System Port | satisfied-by-Ph14-harness | Covered by dark/light Prometheus token mixer tests and token gallery theme-change browsertest. |
| VIS-09-04 | Phase 09 | Accent swatch picker changes accent color immediately | Phase 14 Asset and Design System Port | carry_forward | Re-run as Chromium WebUI/theme token interaction test and visual UAT. |
| VIS-09-05 | Phase 09 | Toolbar icons are bundled FA vector glyphs, not platform-theme icons | Phase 14 Asset and Design System Port | satisfied-by-Ph14-harness | Covered by 72-action icon mapping tests and bundled FA SVG resource-resolution tests. |
| VIS-09-06 | Phase 09 | App icon shows canonical PM mark in Finder/Dock | Phase 13 Product Identity, Branding, and Legal Baseline and Phase 24 Packaging, Release Validation, and Handoff | carry_forward | Re-run as packaged-app icon inspection. |
| VIS-09-07 | Phase 09 | Font license OFL text accessible in about/legal surface | Phase 13 Product Identity, Branding, and Legal Baseline, Phase 14 Asset and Design System Port, and Phase 24 Packaging, Release Validation, and Handoff | satisfied-by-Ph14-harness | Covered by OFL/README.chromium/NOTICES asset-pipeline gate checks. |
| VIS-09-08 | Phase 09 | No network font requests during cold start | Phase 14 Asset and Design System Port and Phase 24 Packaging, Release Validation, and Handoff | satisfied-by-Ph14-harness | Covered by offline resource gate that flags load-bearing remote URL contexts. |
| VIS-10-01 | Phase 10 | Start page renders correctly in dark theme | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI screenshot/UAT in dark theme. |
| VIS-10-02 | Phase 10 | Ask FSB handoff — non-auto-submit | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Phase 20 verifies live prompt seeding, zero auto-submit, no URL/history leakage, and exact-window ownership; Phase 24 retains the visual review. |
| VIS-10-03 | Phase 10 | URL routing vs. agent routing | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Phase 16 verifies prompt handoff avoids URL/query/fragment transport; keep carry-forward for final user-visible navigation UAT. |
| VIS-10-04 | Phase 10 | Favorites grid — real bookmark data | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI bookmark data rendering and navigation UAT. |
| VIS-10-05 | Phase 10 | Suggestion card seeding | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium suggestion-card side panel seed test with no auto-submit. |
| VIS-10-06 | Phase 10 | Light theme rendering | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI screenshot/UAT in light theme. |
| VIS-10-07 | Phase 10 | Offline asset validation (DevTools) | Phase 14 Asset and Design System Port and Phase 16 Prometheus WebUI Surfaces and New Tab | satisfied-by-Ph14-harness | Covered by Phase 14 offline resource gate and full packaged resource-resolution tests; Phase 16 adds Prometheus WebUI resource scanning for remote URL/import/script/style regressions. |
| VIS-10-08 | Phase 10 | Responsive layout | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI responsive screenshot/UAT around the 720px breakpoint. |

## Chromium Architecture Targets

Official Chromium docs confirm the relevant primitives:

- Get/build flow: `depot_tools`, `fetch chromium`, `gn gen`, `autoninja -C out/Default chrome`.
- WebUI: `chrome://` pages are browser-backed UI with privileged bindings, data sources, and browser/renderer communication.
- WebUI resources can be iterated from disk with `optimize_webui = false`, `load_webui_from_disk = true`, and `--load-webui-from-disk`.
- Chromium UI development uses the Views/UI platform for native browser UI.

Suggested Chromium layout:

| Target area | Suggested location |
|-------------|--------------------|
| Browser-process agent service | `chrome/browser/prometheus/agent/` |
| Route schemas and result structs | `components/prometheus/` or `chrome/browser/prometheus/common/` |
| Native route server / auth | `chrome/browser/prometheus/server/` |
| MCP bridge packaging | `tools/prometheus-mcp/` or `chrome/tools/prometheus-mcp/` |
| Side panel WebUI resources | `chrome/browser/resources/prometheus_side_panel/` |
| Control panel WebUI resources | `chrome/browser/resources/prometheus_control/` |
| New tab WebUI resources | `chrome/browser/resources/prometheus_new_tab/` |
| WebUI controllers | `chrome/browser/ui/webui/prometheus/` |
| Views/browser chrome changes | `chrome/browser/ui/views/` with Prometheus-specific helpers isolated |
| Theme/assets | Chromium resource packs, `grit`, `.pak`, and license metadata |
| Browser tests | `chrome/browser/prometheus/*_browsertest.cc` |
| Unit tests | `components/prometheus/*_unittest.cc` and `chrome/browser/prometheus/*_unittest.cc` |

## What To Remove During The Source Wipe

Remove from the active source tree:

- `falkon/` source checkout.
- Falkon build artifacts under `falkon/build/`.
- Qt/Falkon-specific package scripts as active release machinery.
- Falkon-specific assumptions in README and planning docs once the Chromium baseline exists.

Do **not** remove:

- `.planning/`
- `.planning/design/`
- `.planning/preservation/`
- `.context/falkon-preservation/`
- `.context/fsb-reference/`
- root `assets/`
- v1 archived milestone docs

## Source Wipe And Freeze Checklist

| Item | Status | Evidence / Rule |
|------|--------|-----------------|
| `falkon/` | already_removed | Root active checkout is absent; restore only from .context/falkon-preservation/falkon-prometheus-v1.bundle. |
| `.context/falkon-preservation/falkon-prometheus-v1.bundle` | must_stay | Recoverable v1 source bundle; expected HEAD b0521c9d37e7545c680b78dfcc24f777a984091c. |
| `.context/falkon-preservation/patches/` | must_stay | 81-patch source-change series. |
| `.planning/`, `.planning/design/`, `.planning/preservation/`, archived milestone docs, and root `assets/` | must_stay | Planning context, product-owned design references, preservation records, v1 archive, and docs assets must remain available. |
| Falkon C++ files, Qt widget classes, QSS, package scripts, and Falkon/KDE metadata | reference_only | Use only as preserved reference evidence; do not copy into Chromium without explicit license review. |
| Chromium Views/WebUI/resources/services/tests | future_chromium_owned | Reimplement equivalent product contracts through Chromium-native owners, resource pipelines, and tests. |

The active Falkon checkout must not receive feature work or be recreated as a long-lived workspace.

## Migration Rule

Every Chromium phase must answer this before implementation:

1. What v1 behavior is being preserved?
2. Which Falkon file is only a reference?
3. Which Chromium subsystem owns the new implementation?
4. What is the test that proves parity?
5. What legal/license notice is required?

If those answers are missing, the phase is not ready to execute.
