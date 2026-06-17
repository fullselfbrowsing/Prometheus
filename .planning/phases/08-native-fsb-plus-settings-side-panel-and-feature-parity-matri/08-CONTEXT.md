# Phase 8 Context: Native FSB-Plus Settings Side Panel and Feature Parity Matrix

## User Steer

The browser should include relevant native settings and a native side panel, and it should cover all FSB features but better. "Better" needs to be concrete: native control over browser-owned surfaces, safer secrets, lower-latency routing, richer tab/session state, and better supervised visibility.

## Research Summary

FSB currently advertises natural-language tasks from the side panel, provider settings, live model discovery with fallbacks, 50+ browser actions, 59 MCP handlers, DOM snapshots, verification, smart waiting, stuck detection, visual feedback, logs, long-term memory, vault flows, local MCP, remote dashboard pairing, and site intelligence.

Prometheus already has a basic native sidebar in `falkon/src/lib/agent/agentruntimesidebar.cpp` with Task, Providers, Logs, Memory, and Vault tabs. `AgentRuntime` already has task, provider, logs, diagnostics, memory, site guide, and vault APIs. Phase 8 should make this a complete native control center and track parity explicitly.

## Planning Targets

- Create `FSB-PARITY.md` with every FSB feature category, native status, improvement target, and verification command.
- Build the four-mode side panel (FSB Agent, Explorer, Tabs, Tools) and the FSB Control Panel page that hosts tasks, providers, model discovery/fallbacks, MCP, permissions, vault, memory, site guides, logs, diagnostics, supervision, and pairing.
- Add settings for internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, and supervision.
- Connect provider-backed execution where practical while preserving MCP/local paths.
- Add a release validation parity gate.

## Canonical Refs (MUST read before planning)

- `.planning/design/DESIGN-REFERENCE.md` — canonical Prometheus design (authoritative for look and layout)
- `.planning/design/prometheus-browser/prometheus/SidePanel.jsx` — the four side panel modes (exact layout, copy, behavior)
- `.planning/design/prometheus-browser/prometheus/app.jsx` — chrome, FSB pinned tab / control panel entry, Tweaks settings
- `.planning/design/prometheus-browser/prometheus/styles.css` — warm token sets and component styles
- `.planning/design/prometheus-brand/Prometheus Logo.html` — logo, wordmark, palette
- `08-UI-SPEC.md` — revised UI contract (side panel four modes + FSB Control Panel page)
- `08-RESEARCH.md`, `08-VALIDATION.md`, and `.planning/REQUIREMENTS.md` (FSBP-01 through FSBP-06)

## Design Decisions (locked, 2026-06-16)

- **Side panel / control panel split**: the side panel is four modes only (FSB Agent, Explorer, Tabs, Tools); the dense operator center (the nine sections) and all settings live on the FSB Control Panel page reached from the pinned FSB tab (`fsb://dashboard`). The earlier plan to put all sections in the side panel is superseded.
- **Side panel modes**: FSB Agent (automation chat with status pill, tool-call stream, composer), Explorer (bookmarks / reading list / history), Tabs (pinned, groups, open-now), Tools (page toggles, annotate chips, FSB page actions).
- **Settings**: native settings (internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, supervision) live on the control panel; the lightweight Tweaks surface (accent, panel side, tab density) matches the prototype.
- **Design system**: warm dark and light tokens, FSB orange `#ff6b35` accent, Poppins (display) plus Space Mono (mono) per the brand sheet. Implemented natively in Qt; the React prototype is the look target only.
- **Fonts and icons**: Phase 8 may use an interim system font and `QIcon::fromTheme` fallbacks; Phase 9 bundles Poppins/Space Mono and the Font Awesome offline subset and runs the logo pass. No network assets.
- **Provider-backed execution** preserved alongside MCP and local paths.
- **Parity matrix** lives on the control panel page; `FSB-PARITY.md` remains the artifact.

These decisions revised `08-UI-SPEC.md` (status: revised) to match the canonical design.

