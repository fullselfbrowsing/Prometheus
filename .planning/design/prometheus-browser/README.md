# Prometheus — Browser Interface

A minimal, agent-first browser concept. Compact-Safari chrome on the FSB
design system (warm-dark surfaces + orange `#ff6b35`). Interactive React
prototype, no build step — open the HTML directly.

Short name: **PM** · Full name: **Prometheus**

---

## Run it
Open `Prometheus Browser.html` in a browser. Everything loads from CDN
(React 18, Babel, Font Awesome, Space Grotesk / Space Mono) plus the local
files in `prometheus/`.

## File map
```
Prometheus Browser.html     Shell: fonts, CDN libs, mounts the 4 JSX files
prometheus/
  styles.css                ALL styling + the two theme token sets
  app.jsx                   Window shell — chrome toolbar, tab pills, state, theme, tweaks
  StartPage.jsx             New-Tab page — omnibox, favorites, FSB suggestions
  SidePanel.jsx             Side panel + its 4 modes + mock data
  tweaks-panel.jsx          Tweaks host wiring (starter component, untouched)
  assets/                   Real FSB logos/icon (copied from the extension)
```

---

## Design system (where the values live)
`styles.css` top block. Two themes are just token swaps on
`[data-theme="dark|light"]` — change a token once, both the chrome and the
page follow.

| Token            | Dark      | Light     | Used for                       |
|------------------|-----------|-----------|--------------------------------|
| `--accent`       | #ff6b35   | #ff6b35   | FSB orange — active tab, agent, CTAs |
| `--chrome`       | #1d1816   | #f3ede6   | toolbar                         |
| `--surface`      | #141110   | #fffdfb   | page / content                  |
| `--text`         | #f6efe9   | #1f1a17   | primary text                    |
| `--r-pill`       | 999px     | —         | tab + chip radius (the "pills") |

Fonts: **Space Grotesk** (display/wordmark), system UI (body),
**Space Mono** (urls, labels, monospace accents).

---

## Anatomy of the chrome  (`app.jsx` → `.pm-chrome`)
Single unified compact bar, left → right:

1. **Traffic lights** — decorative macOS dots (hover reveals glyphs).
2. **Nav cluster** — back / forward / sidebar toggle (`.on` when panel open).
3. **Tab strip**
   - **Pinned tabs** = icon-only pills (`.pm-pin`), FSB first. Active pin gets
     an orange ring. Divider separates pinned from regular.
   - **Regular tabs** (`.pm-tab`) are pills too. The **active tab expands and
     turns into the address bar** (`.pm-addr` shows, title hides) — this is the
     compact-Safari trick. Inactive tabs show favicon + title, ellipsised.
   - `+` new-tab button.
4. **Right tools** — share · ⚡ FSB agent · all-tabs · **theme toggle** · menu.

## Side panel  (`SidePanel.jsx`)
Collapsible (sidebar button / animates width to 0). Segmented switch with 4
modes — all driven by mock data at the bottom of the file:

- **FSB Agent** — automation chat. Composer + status pill; sending a message
  fakes a tool-call → working → reply sequence. The start-page omnibox and the
  ⚡ button seed a prompt straight into here.
- **Explorer** — Bookmarks / Reading list / History rows.
- **Tabs** — Pinned, colour-coded tab groups, and "open now" overview.
- **Tools** — per-page toggles (reader / focus / force-dark), annotate chips,
  and FSB page actions.

Panel side (left/right) and collapse state are live.

## Start page  (`StartPage.jsx`)
PM mark → wordmark → **omnibox** with an "Ask FSB" button → favorites grid →
"Suggested automations" card. Pressing Enter in the omnibox or clicking a
suggestion hands the text to the agent panel.

---

## State & persistence  (`app.jsx`)
React state, persisted to `localStorage` under the `pm_` prefix:
`theme`, active tab, panel collapsed, panel mode. Refresh keeps your place.

## Tweaks (toolbar → Tweaks)
- **FSB accent** — recolours the whole UI (curated swatches).
- **Side panel** — left / right.
- **Tab density** — compact / regular / comfy (pill widths).

---

## Notes / next steps
- Page tabs render a striped **placeholder** — only the New-Tab start page is
  built out. Easy to drop in a real FSB control-panel page or a tab-grid.
- FSB logo art is in `prometheus/assets/` but not yet wired into the chrome
  (currently a styled "PM"/"F" mark) — pending the logo pass.
- All data in `SidePanel.jsx` / `app.jsx` is mock; swap the arrays for real
  sources.
