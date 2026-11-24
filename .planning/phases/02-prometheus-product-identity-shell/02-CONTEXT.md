# Phase 2: Prometheus Product Identity Shell - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 changes primary product-visible surfaces from Falkon to Prometheus, with "Powered by FSB" as the affiliation/tagline, while preserving buildability and inherited legal notices. It is a first rebrand layer, not a full internal symbol migration.

</domain>

<decisions>
## Implementation Decisions

### Product Name and Affiliation
- The app/product name is `Prometheus`.
- Use `Powered by FSB` as the affiliation/tagline in about, first-run/start, docs, and metadata where space allows.
- Use `com.fullselfbrowsing.prometheus` as the new bundle/app identifier pattern.
- Keep FSB visual language: near-black surfaces, orange primary accent, dense operator feel.

### Rebrand Boundary
- Change primary product-visible app metadata, default bookmarks, about/config/start pages, platform metadata, and docs.
- Keep inherited legal/copyright notices intact.
- Do not mass-edit copyright headers or translated historical/legal text.
- Internal build target names can remain where renaming would create avoidable build risk; use output/app metadata to expose Prometheus to users.

### Build Safety
- After each rebrand layer, preserve the macOS baseline build from Phase 1.
- Treat build failure as blocking.
- Avoid binary asset churn unless necessary for a visible product surface.
- Prefer SVG/text assets for first-pass identity where build tooling supports them.

### the agent's Discretion
Implementation details for exact CSS selectors, generated SVG markup, and package metadata wording are at the agent's discretion as long as the visible product identity is Prometheus and legal attribution remains available.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 1 inventories: `falkon/tools/fsb-baseline/product-identity-inventory.md` and `falkon/tools/fsb-baseline/legal-notice-inventory.md`.
- Runtime product constants live in `falkon/src/lib/app/qzcommon.cpp`.
- macOS bundle metadata lives in `falkon/src/main/Info.plist` and `falkon/src/main/CMakeLists.txt`.
- About UI lives in `falkon/src/lib/other/aboutdialog.cpp` and `.ui`.
- Built-in pages live under `falkon/src/lib/data/html/`.
- Default bookmarks live in `falkon/src/lib/data/data/bookmarks.json`.

### Established Patterns
- The app is a Qt/CMake project with qrc resource files.
- Theme styling uses CSS-like Qt stylesheets under `falkon/themes/{mac,linux,windows}/main.css`.
- Required legal notices are source files and about/license surfaces, not just marketing text.

### Integration Points
- Rebuild with `cmake --build build/fsb-baseline`.
- Smoke with `./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus --wait 1` after output-name rebrand.

</code_context>

<specifics>
## Specific Ideas

- Product name: Prometheus.
- Affiliation/tagline: Powered by FSB.
- Visual language: dark/near-black, FSB orange accents, operator-focused.

</specifics>

<deferred>
## Deferred Ideas

- Full internal namespace/class/library rename from Falkon to Prometheus is deferred.
- Full translated string replacement is deferred until translation strategy is decided.
- Polished final icon family and signed package assets are deferred to release hardening.

</deferred>
