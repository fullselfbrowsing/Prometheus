# Prometheus Design Reference (canonical)

> This is the authoritative visual and interaction reference for the Prometheus
> browser. Phases 8, 9, and 10 build to it. When a phase document and this
> reference disagree on look or layout, this reference wins and the phase
> document should be updated to match.

## Source artifacts

| Source | Path | What it defines |
|--------|------|-----------------|
| Interactive browser prototype | `prometheus-browser/` | Whole window: chrome, side panel, start page, theme tokens, tweaks |
| Brand sheet | `prometheus-brand/Prometheus Logo.html` | Logo construction, wordmark, app icon, palette, type |
| Design system tokens | `prometheus-browser/prometheus/styles.css` | All tokens for both themes |
| Side panel | `prometheus-browser/prometheus/SidePanel.jsx` | The four side panel modes |
| App shell + tweaks | `prometheus-browser/prometheus/app.jsx` | Chrome, tab strip, settings tweaks |
| Start page | `prometheus-browser/prometheus/StartPage.jsx` | New tab surface |
| FSB logos | `prometheus-browser/prometheus/assets/` | `fsb_logo_dark.png`, `fsb_logo_light.png`, `fsb_icon.png` |

The prototype is React for previewing only. The shipping product is the native
Qt/Falkon browser. Treat the prototype as the look and behavior target, not the
implementation technology.

## Identity

Prometheus is the agentic browser, affiliation tagline "Powered by FSB". Short
name PM. The visual language is a warm dark operator aesthetic with a single
FSB orange accent.

### Palette

| Token | Dark | Light | Use |
|-------|------|-------|-----|
| `--accent` | `#ff6b35` | `#ff6b35` | FSB orange: active tab, agent, primary CTAs, focus ring |
| `--accent-2` | `#ff8c42` | `#ff8c42` | accent gradient end |
| ink / `--surface` | `#141110` | `#fffdfb` | page and content |
| `--chrome` | `#1d1816` | `#f3ede6` | toolbar and side panel body |
| `--bg-app` | `#0d0a09` | `#e9e2da` | desktop behind the window |
| `--text` | `#f6efe9` | `#1f1a17` | primary text |
| `--text-2` / `--text-3` | `#d2c1b4` / `#a99283` | `#6a584d` / `#8d7a6e` | secondary, tertiary text |

Brand palette anchors (from the brand sheet): accent `#FF6B35`, ink `#141110`,
paper `#F3EDE6`. Both themes are pure token swaps on `[data-theme="dark|light"]`,
so changing one token moves both chrome and page together. This replaces the
earlier cooler near black palette; the warm values above are canonical.

### Typography

| Role | Family | Notes |
|------|--------|-------|
| Display / wordmark | **Poppins** | Logo uses Thin 100 and Black 900 for weight contrast; wordmark uses 300 and 800 |
| Mono / labels / urls / version tags | **Space Mono** | also used for section labels and metadata |
| Body | system UI | native font stack for dense reading text |

Decision: the display family is unified on **Poppins**. The prototype CSS shipped
with Space Grotesk as a stand in for display; the brand sheet is authoritative and
specifies Poppins. Use Poppins for the logo, the wordmark, and display headings.
Space Mono and the body stack are unchanged. Both fonts are bundled offline in
Phase 9 (no network font loading).

### Logo and brand mark

Built on the FSB construction: a hairline first letter beside a heavy round
geometric second letter, with a monospace version tag beneath.

- **PM monogram**: `P` in Poppins Thin 100, `M` in Poppins Black 900, version tag
  `▽0.1` beneath in Space Mono. The `▽` glyph (U+25BD) replaces the letter v, with
  0.45em tracking.
- **Wordmark**: "Prometheus" set as **Pro** (light, 300) + **metheus** (heavy, 800,
  accent orange). Tagline "agentic browser · by FSB".
- **App icon**: rounded square at 24% corner radius, three treatments (orange
  gradient, white, ink), sizes 128 / 80 / 48.
- **Clear space and min size**: keep one "M" height of clear space on all sides.
  Drop the version tag below roughly 28px lockup height; below 24px use the "M"
  counter only.
- **Color treatments**: on ink, on paper, on accent gradient.

The real FSB wordmark logos ship in `prometheus-browser/prometheus/assets/`. The
prototype chrome currently renders a placeholder "PM"/"F" mark; wiring the real
logo and the brand wordmark is the Phase 9 logo pass.

## Window anatomy

### Chrome (Phase 7, already shipped)

Single unified compact bar: traffic lights, nav cluster (back / forward / sidebar
toggle), tab strip, right tools (share, FSB agent, all tabs, theme toggle, menu).
Pinned tabs are icon only pills; regular tabs are pills whose active tab expands
into the address bar. This already exists from Phase 7 and matches the design.

### Side panel (Phase 8)

A 320px collapsible panel (animates width to 0 when toggled; side is left or right
per the tweak). Header shows the PM mark, the "Prometheus" wordmark, and a version
tag, then a segmented switch over **four modes**:

1. **FSB Agent** — automation chat. Status pill (Ready / Working), message stream
   with system, user, and tool call bubbles, a typing indicator, starter
   suggestion chips, and a composer with mic and send. The start page omnibox and
   the chrome FSB button both seed a prompt straight into this mode.
2. **Explorer** — Bookmarks, Reading list, and History as compact list rows
   (favicon tile, title, sub url, optional meta).
3. **Tabs** — Pinned tabs, color coded tab groups, and an "Open now" overview;
   the active tab is marked.
4. **Tools** — current page tools as toggle rows (Reader mode, Focus highlight,
   Force dark site), an Annotate chip row (Highlight, Draw, Note, Snapshot, Copy
   link), and an "FSB on this page" chip row (Summarize, Extract table, Translate,
   Find prices).

The side panel is the fast, friendly surface. It is **not** the dense operator
control center.

### FSB Control Panel page (Phase 8)

The dense operator control center lives on a dedicated internal page reached from
the pinned FSB tab (`fsb://dashboard`), not inside the side panel. It holds the
nine operator sections — Tasks, Providers & Models, MCP Status, Permissions &
Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing,
and the Parity Matrix — plus the FSB parity matrix and all settings. The full
contract for this surface (copy, status labels, security boundaries, layout) is in
`phases/08-.../08-UI-SPEC.md`.

This split is deliberate: quick everyday actions in the side panel, full operator
depth on the control panel page.

### Settings / Tweaks (Phase 8)

The prototype exposes a tweaks surface with: FSB accent (curated swatches that
recolor the whole UI), side panel side (left / right), and tab density (compact /
regular / comfy). The full native settings (internal surface permissions, agent
caps, tab ownership, visual feedback, telemetry, vault boundaries, supervision)
live on the control panel page per the Phase 8 UI spec.

### Start page / New Tab (Phase 10)

New tab surface: hero PM mark, "Prometheus" wordmark, an omnibox with an "Ask FSB"
button (Enter or the button hands the text to the agent panel), a favorites grid,
and a "Suggested automations" card of FSB prompt shortcuts. This is new scope
captured as Phase 10.

## Icons and theme system (Phase 9)

- **Icons**: Font Awesome Free, bundled offline. The prototype names specific
  glyphs throughout (for example `fa-bolt`, `fa-compass`, `fa-layer-group`,
  `fa-wand-magic-sparkles`, `fa-book-open`, `fa-highlighter`). Phase 9 produces the
  offline subset and the native resolver.
- **Themes**: two warm themes (dark and light) as token swaps, plus the accent
  recolor tweak. Minimal native aesthetic, no decorative chrome.

## Phase map

| Surface | Phase | Status |
|---------|-------|--------|
| Compact chrome and tabs | 7 | shipped, matches design |
| Side panel (4 modes) + Tweaks settings | 8 | this milestone |
| FSB Control Panel page (9 operator sections, parity matrix) | 8 | this milestone |
| Offline Font Awesome icons + Poppins/Space Mono fonts + minimal themes + logo pass | 9 | this milestone |
| New Tab start page | 10 | new scope |

## Out of scope / wrong file

A second download labeled "Brand Guidelines" turned out to be a different product
("Voyza", a travel brand: azure palette, Poppins+Nunito, "AI Indigo" accent). It
contains no Prometheus or FSB content and is not part of this project. Do not use
it.
