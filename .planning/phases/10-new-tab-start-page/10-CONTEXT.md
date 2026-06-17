# Phase 10 Context: New Tab Start Page

## User Steer

The New Tab page is the Prometheus start surface. It should feel like the
prototype start page: a calm hero with the PM mark, a single prominent omnibox
that can either search/navigate or hand a natural-language task to the FSB agent,
a favorites grid, and a short row of FSB suggested automations. Minimal, warm,
agent-first.

## Canonical Refs (MUST read before planning)

- `.planning/design/DESIGN-REFERENCE.md` — start page section and design tokens
- `.planning/design/prometheus-browser/prometheus/StartPage.jsx` — exact layout, copy, and behavior
- `.planning/design/prometheus-browser/prometheus/styles.css` — `.pm-start`, `.pm-hero`, `.pm-omni`, `.pm-fav-*`, `.pm-fsb-*` rules
- `.planning/design/prometheus-brand/Prometheus Logo.html` — PM mark and wordmark construction

## Decisions (locked)

- **Surface**: replace/extend the browser New Tab page with the Prometheus start
  page. Implemented natively in the Qt/Falkon browser (the JSX is the visual
  target, not the technology).
- **Hero**: PM mark (Poppins weight-contrast) + "Prometheus" wordmark + the
  sub line "Search the web, or ask FSB to do it for you."
- **Omnibox**: single rounded field with a magnifier and an "Ask FSB" button.
  Enter on a normal query searches/navigates; the Ask FSB action (or an
  agent-style query) seeds the prompt into the FSB Agent side panel mode and
  opens the panel.
- **Favorites**: grid of favorite tiles (icon tile + name); click navigates.
- **Suggested automations**: a short card list of FSB prompt shortcuts (for
  example "Triage my inbox", "Reorder groceries", "Find a meeting slot") that
  seed the agent panel when chosen.
- **Design system**: warm dark and light tokens, Poppins display, Space Mono
  labels, Font Awesome icons, FSB orange accent — per the design reference. Both
  themes must render correctly.

## Dependencies

- **Phase 8** provides the FSB Agent side panel mode that the omnibox and
  suggestions hand prompts to.
- **Phase 9** provides the bundled offline fonts, Font Awesome icons, and theme
  tokens this page consumes.

## Deferred Ideas

- Real, personalized favorites and history sourcing (prototype uses mock data) —
  wire to actual browser bookmarks/history during planning if in reach, else a
  follow-up.
- Dynamic, context-aware automation suggestions — start with a static curated set.
