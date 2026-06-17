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

The preservation bundle was created before source removal planning:

```sh
git -C falkon bundle create ../.context/falkon-preservation/falkon-prometheus-v1.bundle --all
git -C falkon format-patch -o ../.context/falkon-preservation/patches origin/master..HEAD
```

To restore the reference later:

```sh
git clone .context/falkon-preservation/falkon-prometheus-v1.bundle falkon-restored
```

## Licensing Boundary

Falkon is GPLv3-derived. Chromium is BSD-style with many third-party licenses. The v2 migration must not casually copy Falkon GPL implementation code into the Chromium tree.

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
| `assets/prometheus.svg` | Product mark for README and external docs |
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

## Migration Rule

Every Chromium phase must answer this before implementation:

1. What v1 behavior is being preserved?
2. Which Falkon file is only a reference?
3. Which Chromium subsystem owns the new implementation?
4. What is the test that proves parity?
5. What legal/license notice is required?

If those answers are missing, the phase is not ready to execute.
