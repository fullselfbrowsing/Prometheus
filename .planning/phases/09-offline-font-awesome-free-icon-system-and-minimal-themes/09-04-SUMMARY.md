---
phase: "09"
plan: "04"
subsystem: themes
tags: [qss, theme, prometheus, warm-dark, warm-light, accent, runtime-switching]
dependency_graph:
  requires: ["09-01", "09-02"]
  provides: ["prometheus-dark.qss", "prometheus-light.qss", "prometheus-common.qss", "main.css", "loadPrometheusVariant", "setPrometheusAccent"]
  affects: ["mainapplication.cpp", "mainapplication.h", "fsbcontrolpanel.cpp"]
tech_stack:
  added: []
  patterns:
    - "@@ACCENT@@/@@ACCENT2@@/@@ACCENT_SOFT2@@ token substitution in QSS before setStyleSheet"
    - "substituteAccentTokens() static function using QColor to derive rgba soft values"
    - "Pre-substituted main.css snapshot for static loadTheme() path; dynamic loadPrometheusVariant() for runtime"
    - "DEFAULT_THEME_NAME overridden to prometheus so warm aesthetic is active on first launch"
key_files:
  created:
    - falkon/themes/prometheus/prometheus-dark.qss
    - falkon/themes/prometheus/prometheus-light.qss
    - falkon/themes/prometheus/prometheus-common.qss
    - falkon/themes/prometheus/main.css
    - falkon/themes/prometheus/metadata.desktop
  modified:
    - falkon/src/lib/app/mainapplication.cpp
    - falkon/src/lib/app/mainapplication.h
    - falkon/src/lib/app/qzcommon.h
    - falkon/src/lib/agent/fsbcontrolpanel.cpp
    - falkon/src/lib/agent/fsbcontrolpanel.h
decisions:
  - "main.css is a pre-substituted FSB Orange dark snapshot so static loadTheme() path produces a usable result even before loadPrometheusVariant() runs"
  - "DEFAULT_THEME_NAME changed to 'prometheus' in qzcommon.h so new users see the warm aesthetic immediately without any settings change"
  - "Four-swatch accent picker placed in a new Appearance section appended to FsbControlPanel section rail (index 9)"
  - "substituteAccentTokens() is a module-level static free function, not a method, keeping it accessible to both loadPrometheusVariant and future callers"
metrics:
  duration: "5min"
  completed: "2026-06-17"
  tasks_completed: 2
  files_changed: 10
---

# Phase 09 Plan 04: Prometheus Warm Minimal Theme System Summary

Implemented the complete Prometheus warm minimal theme with runtime dark/light switching and a four-swatch accent system. Three tokenized QSS files (common structural, dark token values, light token values), a pre-substituted main.css entry point, metadata.desktop, and two new slots in MainApplication deliver the visual core of Phase 9.

## What Was Built

### Task 1: Prometheus Theme Directory

Five files created at `falkon/themes/prometheus/`:

**prometheus-common.qss** — Structural rules shared by both variants. Contains zero literal accent hex. All accent-colored rules use `@@ACCENT@@`, `@@ACCENT2@@`, `@@ACCENT_SOFT2@@` substitution tokens. Covers: toolbar icon buttons (30x30, 16px icon, 8px radius), side panel sizing (320px fixed width), status pill (9999px radius), chips, accent-colored CTA buttons, destructive buttons (fixed #ff5f57, NOT swappable), disabled state (opacity 0.35), focus ring (4px at `@@ACCENT_SOFT2@@`), warning labels (#febc2e), supervised-action pill, panel rows (12px radius), large cards (18px radius), navigation bar height (50px).

**prometheus-dark.qss** — All warm dark token values from 09-UI-SPEC.md: bg-app `#0d0a09`, chrome `#1d1816`, surface `#141110`, text `#f6efe9`, text-2 `#d2c1b4`, text-3 `#a99283`, borders as rgba(255,241,232,0.10/0.18/0.06). Accent values use `@@ACCENT@@`/`@@ACCENT_SOFT2@@` tokens throughout (tab selectedTextColor, sidebar tab selected, location bar selection, focus rings, status pill).

**prometheus-light.qss** — Warm light token values: bg-app `#e9e2da`, chrome `#f3ede6`, chrome-2 `#ece4db`, surface `#fffdfb`, text `#1f1a17`, text-2 `#6a584d`, text-3 `#8d7a6e`, borders as rgba(41,29,20,0.10/0.16/0.08). Identical accent token usage.

**main.css** — Pre-substituted snapshot: concatenation of common + dark with all `@@ACCENT@@` replaced by `#ff6b35`, `@@ACCENT2@@` by `#ff8c42`, `@@ACCENT_SOFT2@@` by `rgba(255,107,53,0.18)`. Ensures `loadTheme("prometheus")` produces a complete warm dark stylesheet on the static path even before `loadPrometheusVariant()` is called.

**metadata.desktop** — Falkon theme discovery entry with Name=Prometheus, Type=Service, X-Falkon-Type=Theme.

### Task 2: Runtime Switching and Accent Picker in MainApplication

**substituteAccentTokens()** — Module-level static function. Uses QColor to derive RGB components for the `@@ACCENT_SOFT2@@` expansion (rgba at 18% opacity). Replaces all three token variants in the concatenated QSS string.

**loadPrometheusVariant(bool useDark)** — Public slot. Reads common + dark or light QSS from the prometheus theme directory, reads stored accent from `PrometheusRuntime/Theme/accent[2]` (default FSB Orange), calls substituteAccentTokens, persists the variant choice to `Interface/PrometheusThemeDark`, calls setStyleSheet. Runtime dark/light switch — no restart required.

**setPrometheusAccent(accent, accent2)** — Public slot. Persists both hex values to QzSettings, then calls loadPrometheusVariant with the current dark/light variant. The single entry point called by all four swatch buttons.

**loadSettings() modification** — After `loadTheme(activeTheme)`, detects if active theme is "prometheus" and immediately calls `loadPrometheusVariant(useDark)` to apply the tokenized stylesheet. Static main.css is overridden within the same launch sequence.

**DEFAULT_THEME_NAME** — Changed from platform-conditional (windows/mac/linux) to always `"prometheus"`. New users see warm aesthetics immediately.

**FsbControlPanel Appearance section** — A new tenth section appended to the section rail. Contains: Dark/Light variant toggle buttons (calling `loadPrometheusVariant` directly), "Accent color" label, and four 28px circle swatch buttons for FSB Orange (`#ff6b35`), Indigo (`#6366f1`), Teal (`#14b8a6`), Rose (`#f43f5e`). Each swatch calls `setPrometheusAccent()` on click.

## Commits

| Task | Commit | Files |
|------|--------|-------|
| Task 1: Theme QSS files | `ee5475b19` (falkon) | prometheus-dark.qss, prometheus-light.qss, prometheus-common.qss, main.css, metadata.desktop |
| Task 2: MainApplication wiring | `aa1891ced` (falkon) | mainapplication.cpp, mainapplication.h, qzcommon.h, fsbcontrolpanel.cpp, fsbcontrolpanel.h |

## Verification Results

All plan verification checks passed:

- prometheus-dark.qss: `#0d0a09` (bg-app), `#1d1816` (chrome), `#141110` (surface), `#f6efe9` (text), `#d2c1b4` (text-2), `#a99283` (text-3) all present
- prometheus-light.qss: `#e9e2da` (bg-app), `#f3ede6` (chrome), `#fffdfb` (surface), `#1f1a17` (text), `#6a584d` (text-2), `#8d7a6e` (text-3) all present
- prometheus-common.qss: zero literal accent hex; `@@ACCENT@@`, `@@ACCENT2@@`, `@@ACCENT_SOFT2@@` tokens present; 9999px pill radius; 0.35 disabled opacity
- main.css: `#ff6b35` pre-substituted; no unreplaced `@@` tokens
- mainapplication.cpp: `loadPrometheusVariant`, `setPrometheusAccent`, `substituteAccentTokens`, `PrometheusRuntime/Theme/accent` all present
- FalkonPrivate: builds cleanly (246/246 targets, only pre-existing deprecation warnings from Qt WebEngine)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All functionality is fully wired: theme files are real QSS, accent substitution is live code, swatch buttons call real slots, and DEFAULT_THEME_NAME activates prometheus on first launch.

## Threat Flags

No new threat surfaces introduced beyond those covered in the plan's threat model. QSS files are compile-time local files; accent hex comes only from the four fixed curated swatches (no free-text input path); Settings persistence is local user preference data.

## Self-Check: PASSED

All created files confirmed present. Both falkon sub-repo commits (`ee5475b19`, `aa1891ced`) confirmed in git log. FalkonPrivate built successfully to `bin/libFalkonPrivate.dylib`.
