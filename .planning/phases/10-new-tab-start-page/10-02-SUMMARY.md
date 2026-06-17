---
phase: 10
plan: 02
subsystem: start-page
tags: [start-page, html, qwebchannel, themes, new-tab]
dependency_graph:
  requires:
    - qrc:icons/fa/inbox.svg
    - qrc:icons/fa/cart-shopping.svg
    - qrc:icons/fa/calendar-check.svg
    - falkon:start as new-tab default
  provides:
    - falkon:start Prometheus start page (hero PM mark, omnibox, favorites, suggestions)
    - JS bridge contract qz_prometheus_start.openAgentWithPrompt / bookmarkFavoritesJson / currentTheme
  affects:
    - falkon/src/lib/data/html/start.html
    - falkon/src/lib/network/schemehandlers/falkonschemehandler.cpp
tech_stack:
  added:
    - Prometheus start page HTML/CSS/JS served via falkon:start scheme
  patterns:
    - Two-stage scheme-reply cache (static page cache + per-request %PRIVATE-BROWSING% token), mirroring speeddialPage()
    - QWebChannel bridge consumption with graceful degradation (timeout fallback when bridge absent)
    - Warm dark/light theme via [data-theme] using canonical Phase 9 tokens
    - Offline-only assets: qrc:fonts/* @font-face + qrc:icons/fa/*.svg <img> (no web fonts, no network)
key_files:
  created: []
  modified:
    - falkon/src/lib/data/html/start.html
    - falkon/src/lib/network/schemehandlers/falkonschemehandler.cpp
decisions:
  - Reused Phase 9 offline fonts (Poppins/Space Mono) and Font Awesome SVGs via qrc: URLs; zero network references.
  - Both warm themes implemented as [data-theme="dark"|"light"] token swaps; theme resolved at load via bridge currentTheme().
  - Ask-FSB and suggestion cards call qz_prometheus_start.openAgentWithPrompt(prompt); favorites populated from bridge bookmarkFavoritesJson(); JS degrades gracefully if the bridge is not yet available.
requirements: [START-01, START-02, START-03, START-05]
---

# Phase 10 Plan 02: Prometheus Start Page HTML and Scheme Handler Summary

## What Was Built

Replaced the default Falkon Speed Dial content served at `falkon:start` with the full
Prometheus New Tab start page (703 lines of HTML/CSS/JS in `start.html`):

- **Hero**: PM mark + "Prometheus" wordmark and a sub-line ("Search the web, or ask FSB to do it for you.").
- **Omnibox**: single rounded field with an Ask-FSB action (`.ask` button) that hands the typed prompt to the agent panel via the QWebChannel bridge.
- **Favorites grid**: tiles populated from `qz_prometheus_start.bookmarkFavoritesJson()`, navigate-on-click.
- **Suggested automations**: static cards (using the inbox / cart-shopping / calendar-check FA glyphs bundled in 10-01) that seed the agent panel via `openAgentWithPrompt`.
- **Theming**: warm dark and light token sets via `[data-theme]`, resolved through the bridge `currentTheme()`; offline Poppins/Space Mono `@font-face` from `qrc:fonts/*` and Font Awesome `<img src="qrc:icons/fa/*.svg">`.

`FalkonSchemeReply::startPage()` was updated to a two-stage cache (static page cache plus a
per-request `%PRIVATE-BROWSING%` token substitution) following the `speeddialPage()` pattern.

## Verification Results

- `start.html` references the bridge object `qz_prometheus_start` and methods `openAgentWithPrompt`, `bookmarkFavoritesJson`, `currentTheme`.
- Offline assets only: 4 `qrc:fonts/poppins` refs, 7 `qrc:icons/fa` refs; **0 remote/network URLs** (no `http(s)://`, no `fonts.googleapis`/`fonts.gstatic`/cdn).
- Both themes present (`data-theme` ×3).
- `FalkonSchemeReply::startPage()` two-stage cache + `%PRIVATE-BROWSING%` token confirmed in `falkonschemehandler.cpp`.
- `cmake --build falkon/build/fsb-baseline --target FalkonPrivate` → exit 0 (no work to do; compiles clean).

## Commits

- `e0d592dcf` (falkon): `feat(10-02): write complete Prometheus start page HTML/CSS/JS`
- `44aa1aca3` (falkon): `feat(10-02): update startPage() to two-stage token cache`

## Deviations from Plan

- The executor subagent's API connection dropped after committing both falkon code tasks but before writing this SUMMARY and the outer tracking commit. The code work was verified complete and building on disk; this SUMMARY was reconstructed by the orchestrator from the committed diffs and a build/grep verification pass (filesystem-fallback recovery).

## Known Stubs

- Suggested-automation cards are a static set (dynamic, context-aware suggestions are an explicitly deferred CONTEXT.md idea).

## Threat Surface Scan

- The page consumes the bridge but does not itself expose any privileged surface; the bridge's URL guard and no-auto-submit enforcement are implemented in Plan 10-03. The page degrades gracefully (timeout fallback) when the bridge is absent. No network endpoints are contacted.

## Self-Check: PASSED
