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
| Compact chrome, separate layout option, tab groups, overview/search, quick switch | Users can choose compact or separate chrome while keeping tab groups, search/overview, quick switch, close/restore, unload/suspend, duplicate, detach, and agent/supervision state. | `falkon/src/lib/tabwidget/compacttabstrip.*`; `compacttabdelegate.*`; `tabsearchpopup.*`; `tabgroupmodel.*`; `falkon/src/lib/navigation/navigationbar.*` | Phase 15 Chromium UI Shell, Compact Chrome, and Tab Model | Browser test and manual visual UAT across narrow, standard, and wide windows plus parity matrix row. | contract_only; Qt widgets reference_only |
| Side panel four modes: FSB Agent, Explorer, Tabs, Tools | The side panel remains a mode-driven operator surface for agent work, page exploration, tab state, and tools without becoming the dense control panel. | `.planning/design/prometheus-browser/prometheus/SidePanel.jsx`; `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`; Falkon sidebar patches | Phase 16 Prometheus WebUI Surfaces and New Tab | WebUI test plus manual visual UAT for mode switching, density, empty states, and browser-backed data. | contract_only; Qt sidebar implementation reference_only |
| FSB Control Panel nine operator sections | The internal control panel preserves Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, and Parity Matrix. | `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`; `falkon/src/lib/agent/fsbcontrolpanelpage.*` | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | WebUI test plus parity matrix row for all nine operator sections and data ownership. | contract_only; Qt implementation reference_only |
| Prometheus start page, favorites, suggested automations, Ask FSB handoff | New tabs show the Prometheus start page, favorites, suggested automations, and Ask FSB handoff that seeds the side panel without leaking prompts into URL/history. | `falkon/src/lib/data/html/start.html`; `falkon/src/lib/agent/prometheusstartbridge.*`; `.planning/phases/10-new-tab-start-page/10-UI-SPEC.md` | Phase 16 Prometheus WebUI Surfaces and New Tab | WebUI test plus manual visual UAT for new tab rendering, favorites, suggestions, and Ask FSB handoff. | contract_only; QWebChannel implementation reference_only |
| Native agent command router, auth, route results, tab ownership | Agents authenticate through browser-owned sessions, receive structured route results, and control tabs/windows only within ownership and permission boundaries. | `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`; `falkon/autotests/agentcommandroutertest.*`; `.planning/phases/03-native-agent-control-spine/` | Phase 17 Native Agent Command Service and Tab Ownership | Unit/browser tests for auth, tab ownership, route schemas, caps, typed errors, and audit records. | contract_only; C++ Falkon implementation reference_only |
| DOM/page snapshots, text reads, audited JS, action verification | Agents can read DOM/page/text state, run permissioned audited JS, and mutate pages only with wait, stability, visible-change, and read-back verification. | `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`; `falkon/autotests/agentcommandroutertest.*`; `.planning/phases/03-native-agent-control-spine/` | Phase 18 Page Adapter, DOM Snapshot, and Action Verification | Browser tests against forms, frames, navigation, dynamic DOM, restricted targets, and action verification fixtures. | contract_only |
| MCP bridge tool names, visual-session fields, typed compatibility errors | Existing FSB-style MCP clients keep compatible manual/read/runtime tool names, visual-session fields, ownership errors, and explicit compatibility errors where behavior changes. | `falkon/tools/prometheus-mcp/server.mjs`; `falkon/tools/prometheus-mcp/smoke.mjs`; `.planning/phases/04-mcp-compatibility-and-multi-agent-control/` | Phase 19 MCP Bridge and Multi-Agent Runtime Compatibility | MCP smoke test plus compatibility fixture coverage for schemas, visual fields, typed errors, caps, and reconnect handling. | contract_only; Node bridge reference_only unless reviewed |
| Provider runtime, logs, diagnostics, memory/site guides, vault metadata | Runtime surfaces preserve provider configuration, task status, logs, diagnostics, memory/site-guide metadata, and vault metadata while keeping secrets hidden from docs, renderers, MCP, and tests. | `falkon/src/lib/agent/agentruntime.{h,cpp}`; `.planning/phases/05-fsb-runtime-parity-surfaces/`; `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md` | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | Unit/WebUI tests for provider config, secret redaction, memory/site-guide CRUD, logs, runtime status, and control panel data. | contract_only; secrets must not be copied into docs or tests |
| Supervision, pairing, remote preview identity, audit state | Supervised sessions show visible state, pair safely with expiration/revocation, stream identity-bound preview data, and audit remote control actions. | `.planning/phases/06-supervision-packaging-and-release-hardening/`; PhantomStream reference notes in `.planning/PROJECT.md`; supervision UI references in phase 08 docs | Phase 21 Supervision, Pairing, and Remote Control | Browser/service tests for stale sessions, target mismatch, expiration, revocation, audit logs, and manual supervised-state visual UAT. | contract_only |
| Extension surfaces and extension-vs-agent permission boundary | Chromium extension support remains separate from Prometheus agent authority, and extension surfaces require explicit read/mutate policy before agent access. | `.planning/PROJECT.md`; `.planning/ROADMAP.md` Phase 22; v1 extension-policy requirements | Phase 22 Chrome Extension Ecosystem and Policy | Extension policy tests across representative extension categories plus parity matrix row for extension-surface handling. | contract_only |
| Parity/security/de-Falkon release gates and packaging handoff | Release gates prove migrated v1/FSB parity, security review, visual quality, no active Falkon source, no unreviewed GPL-derived code, and coherent package handoff. | `.planning/STATE.md` deferred items; `.planning/phases/08-*/08-VERIFICATION.md`; `.planning/phases/09-*/09-VERIFICATION.md`; `.planning/phases/10-new-tab-start-page/10-VERIFICATION.md` | Phase 23 Migration Parity, Security Hardening, and De-Falkon Gate and Phase 24 Packaging, Release Validation, and Handoff | Parity matrix row, security review, de-Falkon static check, release validation check, and manual visual UAT ledger. | contract_only plus third_party_attribution_required |

## Deferred Visual Check Ledger

Allowed statuses: `carry_forward` means the check remains required as Chromium-equivalent evidence; `retired` means the original Falkon-only surface is intentionally removed or superseded by a named later Chromium phase.

| ID | Original Phase | Original Check | Chromium Owner | Status | Rationale / Future Evidence |
|----|----------------|----------------|----------------|--------|-----------------------------|
| VIS-08-01 | Phase 08 | Control panel window opens from router surface | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium WebUI/browser-process control panel launch UAT. |
| VIS-08-02 | Phase 08 | All nine section names visible in the section rail | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium WebUI screenshot/UAT for all control panel sections. |
| VIS-08-03 | Phase 08 | Section switching navigates content pages | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium WebUI interaction test plus manual UAT. |
| VIS-08-04 | Phase 08 | 48px header band layout | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI screenshot/UAT at default control panel width. |
| VIS-08-05 | Phase 08 | Secret fields use password echo mode | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium WebUI secret-field visual check with redacted test values. |
| VIS-08-06 | Phase 08 | Provider list shows key state metadata only | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as provider metadata-only WebUI UAT with no raw key values rendered. |
| VIS-08-07 | Phase 08 | Vault list shows metadata only | Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as vault metadata-only WebUI UAT with no raw secret values rendered. |
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
| VIS-10-02 | Phase 10 | Ask FSB handoff — non-auto-submit | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium WebUI-to-side-panel handoff test with no auto-submit. |
| VIS-10-03 | Phase 10 | URL routing vs. agent routing | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI routing test for URL navigation versus agent prompt seeding. |
| VIS-10-04 | Phase 10 | Favorites grid — real bookmark data | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI bookmark data rendering and navigation UAT. |
| VIS-10-05 | Phase 10 | Suggestion card seeding | Phase 16 Prometheus WebUI Surfaces and New Tab and Phase 20 FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel | carry_forward | Re-run as Chromium suggestion-card side panel seed test with no auto-submit. |
| VIS-10-06 | Phase 10 | Light theme rendering | Phase 16 Prometheus WebUI Surfaces and New Tab | carry_forward | Re-run as Chromium WebUI screenshot/UAT in light theme. |
| VIS-10-07 | Phase 10 | Offline asset validation (DevTools) | Phase 14 Asset and Design System Port and Phase 16 Prometheus WebUI Surfaces and New Tab | satisfied-by-Ph14-harness | Covered by offline resource gate and full packaged resource-resolution tests. |
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
