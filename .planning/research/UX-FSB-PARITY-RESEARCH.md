# UX, FSB Parity, Icons, and Theme Research

**Date:** 2026-06-16
**Purpose:** Capture the research basis for extending v1.0 through Phases 7-9.

## External Findings

### Safari Compact Chrome Reference

Apple's Safari Tabs settings define two relevant layouts: separate tabs below the toolbar, and compact tabs moved into the toolbar where the active tab is the Smart Search field.

Source: https://support.apple.com/en-afri/guide/safari/ibrw1045/mac

Apple's Safari customization docs also support user-customizable toolbar items, tab layout choice, website color in the tab bar, and title-vs-icon display preferences.

Source: https://support.apple.com/guide/safari/customize-the-safari-window-ibrw1012/mac

Safari tab groups support grouping, arranging tabs, arranging tab groups from the sidebar, renaming, deleting, and overview-style workflows.

Source: https://support.apple.com/guide/safari/edit-and-customize-tab-groups-ibrwd0cea393/mac

Prometheus should borrow the space-saving interaction model, not copy Safari branding. Compact mode should still expose agent ownership, automation state, supervision state, secure-origin cues, and tab health.

### FSB Feature Bar

The current public FSB README describes natural-language browser tasks from the side panel, provider support, live model discovery with bundled fallbacks, a 51-entry extension tool registry, 59 MCP handlers, DOM snapshots, action verification, smart waiting, stuck detection, visual feedback, session logs, long-term memory, vault flows, and local MCP support.

Source: https://github.com/fullselfbrowsing/FSB

The FSB website also emphasizes 50+ browser actions, smart DOM analysis, visual feedback, site intelligence, MCP integration, remote dashboard pairing, memory, and provider flexibility.

Source: https://full-selfbrowsing.com/

Prometheus should not claim "FSB but better" by implication. It needs an explicit feature parity matrix with status, native improvement, and verification command for every FSB feature category.

### Font Awesome Free

Font Awesome Free is documented as free, open source, and GPL-friendly. In the Free download, icons packaged as SVG/JS are CC BY 4.0, fonts are SIL OFL 1.1, and code is MIT. Attribution comments should be preserved.

Source: https://github.com/FortAwesome/Font-Awesome

Prometheus should bundle a curated offline subset in Qt resources, keep attribution/license files in the release artifact, and validate that primary UI icons do not depend on network or host theme availability.

## Local Code Findings

- `falkon/src/lib/agent/agentruntimesidebar.cpp` already provides a Prometheus sidebar with Task, Providers, Logs, Memory, and Vault tabs. It is the right anchor for Phase 8, but currently stops at basic local runtime flows.
- `falkon/src/lib/agent/agentruntime.h` already exposes task, provider, logs, diagnostics, memory, site guide, and vault methods.
- `falkon/src/lib/sidebar/sidebar.cpp` already supports native sidebars, which means the Prometheus control center can stay native instead of becoming a web overlay.
- `falkon/src/lib/tabwidget/tabbar.cpp`, `tabwidget.cpp`, `tabmodel.cpp`, `tabtreemodel.cpp`, `tabmrumodel.cpp`, the `VerticalTabs` plugin, and the `TabManager` plugin are the natural starting points for Phase 7.
- `falkon/src/lib/data/icons.qrc`, `falkon/src/lib/data/icons/`, theme images, and many `QIcon::fromTheme` call sites show why Phase 9 needs a central Prometheus icon resolver and deterministic bundled fallbacks.

## Implementation Direction

1. Phase 7 should first introduce compact/separate layout settings and native tab model capabilities, then layer visual polish.
2. Phase 8 should start with the parity matrix and use it to drive side panel/settings scope, not the reverse.
3. Phase 9 should add the icon resolver and resource/legal validation before replacing individual call sites.

