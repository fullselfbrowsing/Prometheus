---
phase: 9
slug: offline-font-awesome-free-icon-system-and-minimal-themes
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-17
---

# Phase 9 — UI Design Contract
## Offline Font Awesome Free Icon System and Minimal Themes

> Visual and interaction contract for the Prometheus native Qt6/Falkon desktop browser.
> This is a C++ Qt phase — no React, no shadcn. The design/prometheus-browser prototype
> is the look-and-behavior target only. This spec translates canonical design decisions
> into implementable Qt/QSS/C++ contracts.
>
> Source authority: `.planning/design/DESIGN-REFERENCE.md` and
> `.planning/design/prometheus-browser/prometheus/styles.css` WIN over any other document.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native Qt6 / QSS) |
| Preset | not applicable |
| Component library | Qt Widgets + QSS (no third-party widget toolkit) |
| Icon library | Font Awesome Free 6.x — offline SVG subset bundled as Qt resources |
| Fonts (display) | Poppins (bundled offline, weights 100/300/800/900) |
| Fonts (mono) | Space Mono (bundled offline, weight 400) |
| Fonts (body/UI) | System UI stack: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", system-ui, sans-serif |

This phase ships no network-loaded assets. Every icon, font, and logo asset must be
present at build time inside Qt resource files.

---

## Spacing Scale

All values are multiples of 4 px. QSS uses these values directly.

| Token | Value | QSS Usage |
|-------|-------|-----------|
| xs | 4px | Icon gaps, inline button padding, hairline offsets |
| sm | 8px | Compact element spacing, pill padding vertical, tab close button padding |
| md | 12px | Default element padding (side panel rows: 9px vertical, 8px horizontal — see exceptions) |
| base | 16px | Standard section padding, composer internal padding |
| lg | 24px | Section header spacing, panel head padding-top |
| xl | 32px | Major layout gaps |
| 2xl | 48px | Page-level hero top padding |
| 3xl | 64px | Start page top inset |

Exceptions:
- Icon-only toolbar buttons: 30x30 px clickable area (not a 4-multiple; needed for macOS
  traffic-light row alignment and touch-target compliance at 30 px minimum).
- Panel row padding: 9px vertical, 8px horizontal (spec from prototype — preserves row
  density; executor must not round to 8/8).
- Panel head padding: 14px top, 14px sides, 10px bottom.
- Chip padding: 6px vertical, 11px horizontal (pill radius applied).
- Composer: 8px top/bottom/right, 14px left.
- Segmented switch pill: 3px outer padding, 30px button height, 7px inner radius.

---

## Typography

Prometheus uses three font families with strict role separation.

### Family declarations (QSS @font-face or QFontDatabase::addApplicationFont)

```
Display / wordmark:   Poppins     — weights 100 (Thin), 300 (Light), 800 (ExtraBold), 900 (Black)
Mono / labels / URLs: Space Mono  — weight 400 (Regular)
Body / UI prose:      system-ui stack (no bundled file; relies on OS)
```

### Size and weight scale

| Role | Family | Size | Weight | Line Height | QSS Class / Context |
|------|--------|------|--------|-------------|----------------------|
| Display hero (start page h1) | Poppins | 34px | 600 (SemiBold) | 1.2 | `.pm-hero h1` |
| Wordmark (panel) | Poppins | 14.5px | 600 (SemiBold) | 1.2 | `.pm-wordmark` |
| Wordmark (lockup large) | Poppins | 34px | 300 + 800 split | 1.2 | `.namelock .word` |
| Body (panel rows, messages) | system-ui | 13px | 400 (Regular) | 1.45 | `.pm-msg`, `.pm-row-title` |
| Body (tab title, URL) | system-ui | 12.5px | 500 (Medium) | 1.4 | `.pm-tab-title`, `.pm-url` |
| Label (section headers) | Space Mono | 10px | 400 | 1.3 | `.pm-sec-label` |
| Label (version tag) | Space Mono | 9.5px | 400 | 1.2 | `.pm-ver` |
| Caption (sub-rows, URLs) | Space Mono | 11px | 400 | 1.3 | `.pm-row-sub` |
| Caption (AI label badge) | Space Mono | 9px | 400 | 1.0 | `.ai-label` |
| Status pill | system-ui | 10px | 600 (SemiBold) | 1.0 | `.pm-status` |
| Omnibox input | system-ui | 15px | 400 | 1.0 | `.pm-omni input` |

Letter spacing rules (applied via QSS `letter-spacing` or Qt `QFont::setLetterSpacing`):
- Section labels: +0.08em
- Status pill: +0.06em
- AI label badge: +0.06em
- Version tag `▽0.1`: +0.45em (Space Mono)
- Wordmark `.pm-wordmark`: -0.02em

### Logo weight split (PM monogram)

The "PM" wordmark is NOT a single weight string. It is always rendered as two spans:
- `P` — Poppins weight 100 (Thin)
- `M` — Poppins weight 900 (Black)

This is the defining characteristic of the brand mark. Any rendering that uses a
uniform weight is incorrect.

The `▽0.1` version tag beneath uses Space Mono Regular 400, sized at 12% of the
letters' font size (e.g. if letters are at 26px, tag is ~3.1px — scale to minimum
readable; see logo size rules in Logo section below).

---

## Color — Warm Dark Theme

All values extracted verbatim from `styles.css` `[data-theme="dark"]`.

| Token | Hex | QSS Property Usage |
|-------|-----|---------------------|
| `--bg-app` | `#0d0a09` | Desktop behind window; `QMainWindow` background |
| `--chrome` | `#1d1816` | Toolbar, side panel body; `QToolBar`, `.pm-panel` background |
| `--chrome-2` | `#181311` | Chrome gradient end; panel body `background-color` |
| `--surface` | `#141110` | Page and content area; `QWebEngineView` wrapper |
| `--surface-2` | `#1d1816` | Card backgrounds, segmented switch track, tool rows |
| `--surface-3` | `#26201d` | Elevated card / hover surface |
| `--tab-active` | `#2a221e` | Active tab pill background |
| `--tab-idle` | transparent | Idle tab pill background |
| `--tab-hover` | `rgba(255,241,232,0.06)` | Tab/row hover state |
| `--text` | `#f6efe9` | Primary text |
| `--text-2` | `#d2c1b4` | Secondary text (labels, panel meta) |
| `--text-3` | `#a99283` | Tertiary text (sub-labels, section headers, placeholders) |
| `--border` | `rgba(255,241,232,0.10)` | Default border, dividers |
| `--border-2` | `rgba(255,241,232,0.18)` | Emphasis border, focused inputs, toolbar separators |
| `--hairline` | `rgba(255,241,232,0.06)` | Subtle panel/chrome dividers |
| `--accent` | `#ff6b35` | FSB orange — primary accent (see reserved list below) |
| `--accent-2` | `#ff8c42` | Accent gradient end |
| `--accent-soft` | `color-mix(#ff6b35 12%, transparent)` | Icon bg on tool cards; approximate: `rgba(255,107,53,0.12)` |
| `--accent-soft-2` | `color-mix(#ff6b35 18%, transparent)` | Composer ring, active segment; approximate: `rgba(255,107,53,0.18)` |
| `--accent-glow` | `color-mix(#ff6b35 24%, transparent)` | Send button glow; approximate: `rgba(255,107,53,0.24)` |

## Color — Warm Light Theme

All values extracted verbatim from `styles.css` `[data-theme="light"]`.

| Token | Hex | QSS Property Usage |
|-------|-----|---------------------|
| `--bg-app` | `#e9e2da` | Desktop behind window |
| `--chrome` | `#f3ede6` | Toolbar, nav bar |
| `--chrome-2` | `#ece4db` | Panel body, gradient end |
| `--surface` | `#fffdfb` | Page content area |
| `--surface-2` | `#f8f4ef` | Card surfaces, segmented switch track |
| `--surface-3` | `#f1ebe4` | Elevated hover surface |
| `--tab-active` | `#fffdfb` | Active tab pill |
| `--tab-idle` | transparent | Idle tab pill |
| `--tab-hover` | `rgba(41,29,20,0.05)` | Tab/row hover |
| `--text` | `#1f1a17` | Primary text |
| `--text-2` | `#6a584d` | Secondary text |
| `--text-3` | `#8d7a6e` | Tertiary text |
| `--border` | `rgba(41,29,20,0.10)` | Default border |
| `--border-2` | `rgba(41,29,20,0.16)` | Emphasis border |
| `--hairline` | `rgba(41,29,20,0.08)` | Panel dividers |
| `--accent` | `#ff6b35` | FSB orange — same value in both themes |
| `--accent-2` | `#ff8c42` | Accent gradient end — same in both themes |

Both themes share identical accent values. Switching theme is a pure surface/text token
swap via a `data-theme` attribute equivalent in Qt (a theme name property on the root
`QApplication` style sheet or a reloadable QSS file).

## Accent Reserved List (10% rule)

Accent (`#ff6b35` / gradient to `#ff8c42`) is reserved for ONLY these elements:

1. Active tab pill border and glow
2. Active segment in the side panel mode segmented switch
3. FSB Agent status pill text, dot, and background
4. Primary CTA buttons (send message, Ask FSB, primary action in control panel)
5. Active pinned tab border and glow
6. Composer input ring (focus state border + outer glow)
7. Tool card icon background (soft) and icon color
8. Agent status dot pulse animation
9. Chip hover border color
10. Selection highlight (text selection background)
11. Focus ring on keyboard-navigated interactive elements (4px accent-soft-2 ring)
12. Logo mark background gradient (app icon, panel mark, start page hero mark)
13. FSB suggestions card hover border
14. Link color on internal pages (about, first-run)

Everything else uses surface, border, and text tokens.

## State Colors

| State | Token / Value | Applied To |
|-------|---------------|------------|
| Focus | 4px ring `rgba(255,107,53,0.18)` | All keyboard-focused interactive elements |
| Hover | `--tab-hover` (per theme) | Buttons, rows, tabs, chips |
| Active (pressed) | `transform: scale(0.94)` + no color change | Icon buttons; `scale(0.9)` on send/omni ask |
| Disabled | `opacity: 0.35`, `pointer-events: none` | Navigation back/forward when unavailable |
| Warning | `#febc2e` (macOS yellow system color) | Non-critical warnings, tab audio indicator |
| Destructive | `#ff5f57` (macOS red; also used for traffic light close dot) | Destructive actions, error states |
| Supervised action | Accent `#ff6b35` pill with "SUPERVISED" label text | Any agent-executed action notification |
| Private browsing | `#181311` (chrome-2) + dashed `--border-2` treatment | Private window chrome differentiation |
| Working (agent) | Accent dot pulse animation (`.pm-status .pdot`) | Agent status pill while task is running |

---

## Theme Implementation Contract (Qt/QSS)

### File layout

```
falkon/src/lib/themes/prometheus/
  prometheus-dark.qss    — warm dark token values
  prometheus-light.qss   — warm light token values
  prometheus-common.qss  — structure rules shared by both (spacing, radii, selectors)
```

The executor applies one of `prometheus-dark.qss` or `prometheus-light.qss` at
runtime by calling `qApp->setStyleSheet(...)` when the user toggles themes.

### Border radii (declared once in common, not overridden per theme)

| Token | Value | Applied To |
|-------|-------|------------|
| `--r-sm` | 8px | Icon buttons, tab close buttons |
| `--r-md` | 12px | Panel rows, tool cards, message bubbles |
| `--r-lg` | 18px | Large cards, favorites tiles, FSB strip |
| `--r-pill` | 9999px | Tab pills, chips, status pills, send button, omnibox |

### Chrome height and panel width (structural constants)

| Property | Value |
|----------|-------|
| `--chrome-h` | 50px |
| `--panel-w` | 320px |
| Panel collapse | width animates to 0px over 260ms cubic-bezier(0.4, 0, 0.2, 1) + opacity fades |

### Accent tweak (THEME-02 requirement)

The accent color is overridable via a curated swatch picker in Settings. When the user
selects an alternate accent, only `--accent` and `--accent-2` are replaced. All
accent-derived soft/glow values recompute from those two roots. The executor must
implement accent replacement as a simple QSS token substitution, not hard-coded hex.

Curated accent swatches (the only options; no free hex entry in v1):
- FSB Orange (default): `#ff6b35` / `#ff8c42`
- Indigo: `#6366f1` / `#818cf8`
- Teal: `#14b8a6` / `#2dd4bf`
- Rose: `#f43f5e` / `#fb7185`

---

## Icon System

### Library

Font Awesome Free 6.x. License: SVG icons CC BY 4.0, web fonts SIL OFL 1.1, code MIT.
Attribution comment must be preserved in every bundled SVG file header.

Required attribution comment in each SVG:
```
<!-- Font Awesome Free 6.x — https://fontawesome.com — CC BY 4.0 -->
```

### Delivery format

Offline SVG files bundled as Qt resources in `falkon/src/lib/data/icons.qrc` under the
prefix `:/icons/fa/`. Each file is named `{icon-name}.svg` exactly matching the FA name
without the `fa-` prefix (e.g. `bolt.svg`, `compass.svg`).

Executor must NOT use Font Awesome web font, JS kit, or CDN delivery. SVG inline
rendering via `QIcon` from resource paths only.

### Curated subset — named glyphs from the design

The following glyphs are explicitly named in the prototype and design reference. These
are the primary subset. All are from FA Free solid (`fas`) unless noted.

| FA Glyph | Resource Path | Used In |
|----------|--------------|---------|
| `fa-bolt` | `:/icons/fa/bolt.svg` | Agent mode tab icon, FSB agent indicator, "Working" state |
| `fa-compass` | `:/icons/fa/compass.svg` | Explorer mode tab icon, navigation discovery |
| `fa-layer-group` | `:/icons/fa/layer-group.svg` | Tabs mode tab icon, tab group indicator |
| `fa-wand-magic-sparkles` | `:/icons/fa/wand-magic-sparkles.svg` | Tools mode tab icon, FSB "on this page" actions |
| `fa-book-open` | `:/icons/fa/book-open.svg` | Reader mode toggle, reading list |
| `fa-highlighter` | `:/icons/fa/highlighter.svg` | Highlight annotation chip |

### Full action-to-glyph map (central resolver contract)

The central `PrometheusIconResolver` class (new in Phase 9) maps every named action in
the primary UI to a deterministic bundled icon. This map is the ONLY place icon
selection decisions live. All callers use `PrometheusIconResolver::icon(ActionId)`.

#### Browser navigation actions

| ActionId | FA Glyph | Resource Path | Fallback (QIcon::fromTheme) |
|----------|----------|---------------|------------------------------|
| `nav-back` | `fa-arrow-left` | `:/icons/fa/arrow-left.svg` | `go-previous` |
| `nav-forward` | `fa-arrow-right` | `:/icons/fa/arrow-right.svg` | `go-next` |
| `nav-reload` | `fa-rotate-right` | `:/icons/fa/rotate-right.svg` | `view-refresh` |
| `nav-stop` | `fa-xmark` | `:/icons/fa/xmark.svg` | `process-stop` |
| `nav-home` | `fa-house` | `:/icons/fa/house.svg` | `go-home` |
| `nav-new-tab` | `fa-plus` | `:/icons/fa/plus.svg` | `list-add` |
| `nav-close-tab` | `fa-xmark` | `:/icons/fa/xmark.svg` | `window-close` |
| `nav-search` | `fa-magnifying-glass` | `:/icons/fa/magnifying-glass.svg` | `edit-find` |
| `nav-lock-secure` | `fa-lock` | `:/icons/fa/lock.svg` | `security-medium` |
| `nav-lock-insecure` | `fa-lock-open` | `:/icons/fa/lock-open.svg` | `security-low` |
| `nav-share` | `fa-arrow-up-from-bracket` | `:/icons/fa/arrow-up-from-bracket.svg` | `document-share` |
| `nav-downloads` | `fa-arrow-down-to-line` | `:/icons/fa/arrow-down-to-line.svg` | `emblem-downloads` |
| `nav-bookmarks` | `fa-star` | `:/icons/fa/star.svg` | `bookmark-new` |
| `nav-bookmark-add` | `fa-star` | `:/icons/fa/star.svg` | `bookmark-new` |
| `nav-bookmark-remove` | `fa-star-half-stroke` | `:/icons/fa/star-half-stroke.svg` | `edit-delete` |

#### Agent actions

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `agent-fsb` | `fa-bolt` | `:/icons/fa/bolt.svg` | none (must always resolve) |
| `agent-ready` | `fa-circle-check` | `:/icons/fa/circle-check.svg` | none |
| `agent-working` | `fa-bolt` | `:/icons/fa/bolt.svg` | none |
| `agent-mic` | `fa-microphone` | `:/icons/fa/microphone.svg` | `audio-input-microphone` |
| `agent-send` | `fa-arrow-up` | `:/icons/fa/arrow-up.svg` | none |
| `agent-stop-task` | `fa-stop` | `:/icons/fa/stop.svg` | `process-stop` |
| `agent-summarize` | `fa-wand-magic-sparkles` | `:/icons/fa/wand-magic-sparkles.svg` | none |
| `agent-extract` | `fa-table` | `:/icons/fa/table.svg` | none |
| `agent-translate` | `fa-language` | `:/icons/fa/language.svg` | none |
| `agent-find-prices` | `fa-tag` | `:/icons/fa/tag.svg` | none |

#### MCP actions

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `mcp-connected` | `fa-plug` | `:/icons/fa/plug.svg` | none |
| `mcp-disconnected` | `fa-plug-circle-xmark` | `:/icons/fa/plug-circle-xmark.svg` | none |
| `mcp-tool` | `fa-wrench` | `:/icons/fa/wrench.svg` | none |
| `mcp-status-ok` | `fa-circle-check` | `:/icons/fa/circle-check.svg` | none |
| `mcp-status-error` | `fa-circle-xmark` | `:/icons/fa/circle-xmark.svg` | none |
| `mcp-status-warn` | `fa-triangle-exclamation` | `:/icons/fa/triangle-exclamation.svg` | none |

#### Provider actions

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `provider-add` | `fa-circle-plus` | `:/icons/fa/circle-plus.svg` | `list-add` |
| `provider-remove` | `fa-circle-minus` | `:/icons/fa/circle-minus.svg` | `list-remove` |
| `provider-model` | `fa-microchip` | `:/icons/fa/microchip.svg` | none |
| `provider-key` | `fa-key` | `:/icons/fa/key.svg` | none |
| `provider-endpoint` | `fa-server` | `:/icons/fa/server.svg` | none |

#### Vault actions

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `vault-open` | `fa-vault` | `:/icons/fa/vault.svg` | none |
| `vault-lock` | `fa-lock` | `:/icons/fa/lock.svg` | none |
| `vault-unlock` | `fa-lock-open` | `:/icons/fa/lock-open.svg` | none |
| `vault-secret-add` | `fa-user-secret` | `:/icons/fa/user-secret.svg` | none |
| `vault-secret-remove` | `fa-circle-minus` | `:/icons/fa/circle-minus.svg` | `list-remove` |

#### Diagnostics / supervision

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `diag-log` | `fa-scroll` | `:/icons/fa/scroll.svg` | none |
| `diag-health` | `fa-heart-pulse` | `:/icons/fa/heart-pulse.svg` | none |
| `diag-error` | `fa-circle-xmark` | `:/icons/fa/circle-xmark.svg` | `dialog-error` |
| `diag-warning` | `fa-triangle-exclamation` | `:/icons/fa/triangle-exclamation.svg` | `dialog-warning` |
| `supervision-badge` | `fa-eye` | `:/icons/fa/eye.svg` | none |
| `supervision-pair` | `fa-link` | `:/icons/fa/link.svg` | none |
| `supervision-unpair` | `fa-link-slash` | `:/icons/fa/link-slash.svg` | none |

#### Tab actions

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `tab-all` | `fa-table-cells-large` | `:/icons/fa/table-cells-large.svg` | `view-list-icons` |
| `tab-overview` | `fa-layer-group` | `:/icons/fa/layer-group.svg` | `view-list-icons` |
| `tab-pin` | `fa-thumbtack` | `:/icons/fa/thumbtack.svg` | none |
| `tab-mute` | `fa-volume-xmark` | `:/icons/fa/volume-xmark.svg` | `audio-volume-muted` |
| `tab-unmute` | `fa-volume-high` | `:/icons/fa/volume-high.svg` | `audio-volume-high` |
| `tab-private` | `fa-user-secret` | `:/icons/fa/user-secret.svg` | none |
| `tab-group` | `fa-layer-group` | `:/icons/fa/layer-group.svg` | none |

#### Page tool actions (Tools mode)

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `tool-reader` | `fa-book-open` | `:/icons/fa/book-open.svg` | none |
| `tool-focus` | `fa-highlighter` | `:/icons/fa/highlighter.svg` | none |
| `tool-force-dark` | `fa-moon` | `:/icons/fa/moon.svg` | none |
| `tool-annotate-highlight` | `fa-highlighter` | `:/icons/fa/highlighter.svg` | none |
| `tool-annotate-draw` | `fa-pen` | `:/icons/fa/pen.svg` | none |
| `tool-annotate-note` | `fa-note-sticky` | `:/icons/fa/note-sticky.svg` | none |
| `tool-annotate-snapshot` | `fa-camera` | `:/icons/fa/camera.svg` | none |
| `tool-annotate-copy` | `fa-link` | `:/icons/fa/link.svg` | `edit-copy` |

#### Settings and utility

| ActionId | FA Glyph | Resource Path | Fallback |
|----------|----------|---------------|---------|
| `settings-general` | `fa-sliders` | `:/icons/fa/sliders.svg` | `preferences-system` |
| `settings-appearance` | `fa-palette` | `:/icons/fa/palette.svg` | `preferences-desktop-theme` |
| `settings-privacy` | `fa-shield` | `:/icons/fa/shield.svg` | `preferences-system-privacy` |
| `settings-permissions` | `fa-circle-nodes` | `:/icons/fa/circle-nodes.svg` | none |
| `settings-shortcuts` | `fa-keyboard` | `:/icons/fa/keyboard.svg` | `preferences-desktop-keyboard` |
| `settings-extensions` | `fa-puzzle-piece` | `:/icons/fa/puzzle-piece.svg` | `applications-system` |
| `settings-downloads` | `fa-arrow-down-to-line` | `:/icons/fa/arrow-down-to-line.svg` | `folder-downloads` |
| `utility-copy` | `fa-copy` | `:/icons/fa/copy.svg` | `edit-copy` |
| `utility-paste` | `fa-paste` | `:/icons/fa/paste.svg` | `edit-paste` |
| `utility-cut` | `fa-scissors` | `:/icons/fa/scissors.svg` | `edit-cut` |
| `utility-undo` | `fa-rotate-left` | `:/icons/fa/rotate-left.svg` | `edit-undo` |
| `utility-redo` | `fa-rotate-right` | `:/icons/fa/rotate-right.svg` | `edit-redo` |
| `utility-delete` | `fa-trash` | `:/icons/fa/trash.svg` | `edit-delete` |
| `utility-select-all` | `fa-check-double` | `:/icons/fa/check-double.svg` | `edit-select-all` |
| `utility-info` | `fa-circle-info` | `:/icons/fa/circle-info.svg` | `dialog-information` |
| `utility-question` | `fa-circle-question` | `:/icons/fa/circle-question.svg` | `dialog-question` |
| `utility-close` | `fa-xmark` | `:/icons/fa/xmark.svg` | `dialog-close` |
| `utility-new-folder` | `fa-folder-plus` | `:/icons/fa/folder-plus.svg` | `folder-new` |
| `utility-theme-toggle` | `fa-circle-half-stroke` | `:/icons/fa/circle-half-stroke.svg` | none |
| `utility-menu` | `fa-bars` | `:/icons/fa/bars.svg` | none |
| `utility-sidebar-toggle` | `fa-sidebar-flip` | `:/icons/fa/sidebar-flip.svg` | none |

### QIcon::fromTheme fallback contract

The `PrometheusIconResolver::icon(ActionId)` method implements this exact logic:

```
1. Attempt to load from Qt resource path (e.g. ":/icons/fa/bolt.svg")
2. If resource load fails: attempt QIcon::fromTheme(fallback_theme_name, QIcon())
3. If both fail: return a 1x1 transparent placeholder AND emit a
   qWarning("PrometheusIconResolver: missing icon for action %s", actionId)
   so release validation catches it.
```

Step 3 must never silently return a broken icon. The warning is consumed by the
ICON-04 release gate.

### Icon rendering sizes

All FA SVG icons are rendered at these sizes via `QIcon::pixmap(size, size)`:

| Context | Size | Notes |
|---------|------|-------|
| Toolbar icon buttons | 16px | Inside 30x30 button area |
| Side panel mode tabs | 14px | Inside 30px segmented button |
| Tool card icons | 14px | Inside 32x32 accent-soft pill |
| Chip icons | 11px | Inline with 12px chip text |
| Tab audio/mute indicator | 10px | Overlaid on tab favicon |
| Panel mark (logo area) | 12px | Only if FA glyphs used; logo mark uses Poppins not FA |
| Menu items | 16px | Context menu, application menu |
| Preferences panel categories | 22px | Preferences category list |
| Status bar | 16px | Status bar plugin icons |

SVG icons must render crisply at all sizes. Executor must test at 1x and 2x display
scale (HiDPI). Use `QIcon::addFile` with explicit size variants if Qt does not
auto-scale SVG to target size correctly.

---

## Font Bundling Contract

### Required font files

All font files are bundled as Qt resources under `:/fonts/`.

```
:/fonts/poppins/Poppins-Thin.ttf          (weight 100)
:/fonts/poppins/Poppins-Light.ttf         (weight 300)
:/fonts/poppins/Poppins-ExtraBold.ttf     (weight 800)
:/fonts/poppins/Poppins-Black.ttf         (weight 900)
:/fonts/spacemono/SpaceMono-Regular.ttf   (weight 400)
```

Italic variants are NOT required for Phase 9.

### Registration

All fonts must be registered via `QFontDatabase::addApplicationFont` at application
startup before any UI is displayed. The application startup sequence must:

1. Register all five font files
2. Verify each registration returns a non-negative ID
3. If any registration fails: log `qWarning("PromethusFontLoader: failed to load %s")` and
   continue (fall back to system font for that weight rather than crashing)

### Prohibition on network loading

No `@import url(...)`, no `fonts.googleapis.com`, no `gstatic.com` requests.
The FONT-01 release gate validates that no DNS requests for font CDNs are made during
a cold-start smoke test.

### License attribution

Both font licenses must be present in the binary's legal/about surface and in the
source tree:

- Poppins: SIL Open Font License 1.1 — `licenses/Poppins-OFL.txt`
- Space Mono: SIL Open Font License 1.1 — `licenses/SpaceMono-OFL.txt`

---

## Logo Contract

### PM monogram construction

The PM mark is NOT a bitmap image. It is a native Qt widget (`PrometheusMarkWidget`)
that renders two `QLabel` or `QPainter` text draws side by side:

```
[P]  — Poppins Thin 100, --text color
[M]  — Poppins Black 900, --text color
[▽0.1]  — Space Mono Regular 400, --text-3 color, displayed only above 28px lockup height
```

The `▽` character is U+25BD (WHITE DOWN-POINTING SMALL TRIANGLE). It is NOT the letter
"v". Space Mono includes this glyph. Tracking on the version tag: 0.45em.

### Logo size rules

| Lockup height | What to show |
|---------------|-------------|
| >= 28px | Full PM + `▽0.1` version tag |
| 24–27px | PM letters only, no version tag |
| < 24px | `M` counter only (Black 900, no thin P) |

### Clear space rule

Keep clear space of exactly one `M` height on all four sides of the lockup. No other
content, border, or background element may enter this zone.

### Wordmark construction

The full Prometheus wordmark is a single text element with two weight spans:

```
Pro     — Poppins Light 300, --text color
metheus — Poppins ExtraBold 800, --accent color (#ff6b35)
```

No underline. No additional punctuation between weight segments. The two spans are
rendered adjacent with no letter-spacing break between them.

Tagline below the wordmark: `agentic browser · by FSB`
- Font: Space Mono Regular 400
- Size: 11px
- Color: `--text-dim` / `--text-3`
- Letter spacing: +0.06em

### Color treatments

| Treatment | Background | Mark color |
|-----------|-----------|------------|
| On ink (dark theme) | `#141110` | `#f6efe9` (--text) |
| On paper (light theme) | `#fffdfb` | `#1f1a17` (--text) |
| On accent gradient | `linear-gradient(135deg, #ff6b35, #ff8c42)` | `#ffffff` |

### Placement per surface

| Surface | Mark | Wordmark | Tagline | Size |
|---------|------|----------|---------|------|
| Side panel header | Yes (26x26 rounded-square widget, accent gradient bg) | Yes (14.5px SemiBold) | No | Panel mark: 12px letter-size |
| Start page hero | Yes (64x64 rounded-square, accent gradient bg, border-radius 18px) | Yes (34px, 300+800 split) | `agentic browser · by FSB` | 26px letter-size |
| About / first-run | Yes (128px app icon size) | Yes (large) | `agentic browser · by FSB` + version | 52px letter-size |
| App icon (macOS .icns / .png) | Yes | No | No | 128px / 80px / 48px targets |
| Window title | Text only: "Prometheus" | No | No | System font |

### App icon sizes

App icon uses a rounded square at 24% corner radius with the orange gradient background.
Required export sizes for macOS icns: 128px, 80px (2x of 40px), 48px (2x of 24px).
Below 48px, omit the version tag. Below 24px, render `M` only.

### FSB logo assets (existing)

The real FSB wordmark logos in `prometheus-browser/prometheus/assets/` are used as-is
in surfaces that show the FSB affiliation mark:

| Asset | Use |
|-------|-----|
| `fsb_logo_dark.png` | FSB wordmark on dark backgrounds |
| `fsb_logo_light.png` | FSB wordmark on light backgrounds |
| `fsb_icon.png` | FSB icon in compact contexts |

These are bundled to `:/assets/fsb_logo_dark.png`, `:/assets/fsb_logo_light.png`,
`:/assets/fsb_icon.png` in the Qt resource system. The theme-appropriate variant is
selected at runtime.

---

## Copywriting Contract

### Accent / theme controls

| Element | Copy |
|---------|------|
| Theme toggle tooltip (dark active) | Switch to light theme |
| Theme toggle tooltip (light active) | Switch to dark theme |
| Accent swatch label | Accent color |
| Accent swatch: FSB Orange | FSB Orange |
| Accent swatch: Indigo | Indigo |
| Accent swatch: Teal | Teal |
| Accent swatch: Rose | Rose |

### Icon and font error states (developer-facing, not end-user UI)

These appear only in developer/diagnostic logs — not in end-user UI.

| Condition | Message |
|-----------|---------|
| Missing bundled icon | `PrometheusIconResolver: missing icon for action {actionId} — release gate will fail` |
| Font load failure | `PromethusFontLoader: failed to load {fontFile} — falling back to system font for weight {weight}` |

### Logo / brand surfaces (end-user copy)

| Element | Copy |
|---------|------|
| Side panel brand wordmark | Prometheus |
| Side panel version tag | `▽0.1` (Space Mono, literal string) |
| About page tagline | agentic browser · by FSB |
| First-run page tagline | agentic browser · by FSB |
| Window title bar | Prometheus |

### Empty states (icon system not loaded / theme error)

These are internal fallback notices that should never reach a shipped build but must
exist for graceful degradation:

| Element | Copy |
|---------|------|
| Icon missing placeholder tooltip | Icon unavailable |
| Theme load failure notification | Could not load theme — using system default |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Font Awesome Free | Offline SVG subset (no CDN) | not required — offline files only; CC BY 4.0 attribution in SVG headers required |
| Google Fonts (Poppins, Space Mono) | NOT used | BLOCKED — no network font loading permitted (FONT-01) |

No shadcn, no third-party registries. This is a native Qt phase.

---

## Verification Checklist (ICON-04 / Release Gate)

The release validation for Phase 9 FAILS if any of the following are true.

### Icon checks

- [ ] Any action in the `PrometheusIconResolver` action-to-glyph map returns a null
  `QIcon` (i.e. both resource load and fromTheme fallback fail)
- [ ] Any SVG in `:/icons/fa/` is missing the required CC BY 4.0 attribution comment
- [ ] Any icon is loaded from an HTTP/HTTPS URL at runtime (check via network interceptor
  smoke test)
- [ ] Any primary UI `QIcon::fromTheme(name)` call site has no bundled resource fallback
  AND the name is in the primary icon set (navigator, side panel, tool cards)
- [ ] Icons appear illegible (less than 8px effective rendered size) at any declared usage
- [ ] Dark and light themes show different icon SVG files for the same action (the SVG
  color must adapt via QSS `color` injection, not different files)

### Font checks

- [ ] Any of the five required font files fails `QFontDatabase::addApplicationFont` during
  startup smoke test
- [ ] Poppins or Space Mono appears to be loaded from network (DNS request to
  fonts.googleapis.com or fonts.gstatic.com during cold start)
- [ ] The PM monogram renders as uniform weight (both P and M at the same weight)
- [ ] Poppins OFL or Space Mono OFL license text is absent from the legal/about surface

### Logo checks

- [ ] PM monogram uses letter "v" instead of U+25BD `▽` in the version tag
- [ ] Wordmark "metheus" portion is not rendered in accent orange
- [ ] App icon corner radius deviates from 24% by more than 2%
- [ ] Clear space (one M height) is violated on any declared surface
- [ ] Side panel shows placeholder "PM" text mark instead of the real `PrometheusMarkWidget`
- [ ] About or first-run surface shows Falkon branding instead of Prometheus mark

### Theme checks

- [ ] Any color value in the shipped QSS deviates from the canonical hex values in this
  spec by more than ±2 in any RGB channel (except alpha-composited values)
- [ ] Switching from dark to light theme (or vice versa) requires a restart
- [ ] Any element uses a hard-coded color hex instead of the theme token variable
- [ ] The supervised-action state is visually indistinguishable from the normal agent-ready state
- [ ] Focus ring is absent from any keyboard-navigable interactive element

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
