# Phase 2: Prometheus Product Identity Shell - UI Design Contract

**Created:** 2026-06-16
**Status:** Approved

## Product Identity

- **Product name:** Prometheus
- **Affiliation/tagline:** Powered by FSB
- **Identifier pattern:** `com.fullselfbrowsing.prometheus`
- **Primary product promise:** agent-native browser control through DOM/native structure, not screenshots.

## Visual System

| Token | Value | Use |
|-------|-------|-----|
| Background | `#090909` | Dark browser/app surfaces and built-in pages |
| Surface | `#141414` | Panels/cards/boxed built-in page content |
| Border | `#2a2a2a` | Dividers and boxed content |
| Primary orange | `#ff6b35` | Links, focus states, primary emphasis |
| Secondary orange | `#ff8c42` | Hover/focus glow and secondary emphasis |
| Text | `#f2f2f2` | Primary text on dark surfaces |
| Muted text | `#a7a7a7` | Supporting metadata |

## Copy Rules

- Use `Prometheus` for app name, window title, app metadata, about title, default bookmarks, and user-facing docs.
- Use `Powered by FSB` as supporting copy, not as part of every title.
- Preserve inherited legal/copyright notices in legal/about surfaces.
- Do not expose Falkon/KDE as the product identity in primary UI; legal attribution can still mention inherited code.

## Surfaces

### App Metadata
- macOS bundle name and display name: `Prometheus`
- macOS bundle identifier: `com.fullselfbrowsing.prometheus`
- Windows product/file description: `Prometheus`
- Linux desktop default `Name`: `Prometheus`
- Linux default `Icon`: `prometheus`
- Linux default `Exec`: `prometheus %u`

### Built-In Pages
- Start/about/config pages should use near-black backgrounds and orange accents.
- Start page should show Prometheus as the destination brand and `Powered by FSB` as supporting copy.
- Default search provider can remain DuckDuckGo.

### About Surface
- Dialog title: `About Prometheus`
- About content should include Prometheus, Powered by FSB, version, QtWebEngine version, inherited authors, and legal/source availability through existing license surfaces.

### Browser Chrome
- Main theme should shift away from neutral grey/blue toward dark surfaces and FSB orange accents.
- This phase sets a baseline; deeper operator panels are Phase 5.

## Accessibility and Layout

- Keep all existing control sizes stable.
- Do not reduce contrast below the current theme.
- Avoid layout churn in preferences and about dialogs.
- Do not use oversized marketing hero layouts inside the desktop app shell.

## Verification

- `rg -n "Prometheus|Powered by FSB|com.fullselfbrowsing.prometheus" ...` finds product identity in primary surfaces.
- `rg -n "Name=Falkon|CFBundleDisplayName.*Falkon|ProductName.*Falkon"` finds no primary default metadata entries.
- `cmake --build build/fsb-baseline` passes.
- Smoke helper launches `build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus`.
