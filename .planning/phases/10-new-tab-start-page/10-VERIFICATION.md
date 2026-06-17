---
phase: 10-new-tab-start-page
verified: 2026-06-17T00:00:00Z
status: human_needed
score: 13/13
overrides_applied: 0
human_verification:
  - test: "Open a new tab (Cmd+T) — confirm URL bar shows falkon:start and the PM mark, wordmark, sub-line, omnibox, favorites grid, and suggestion strip all render"
    expected: "Full Prometheus start page visible with warm dark theme, no legacy Falkon speeddial"
    why_human: "Visual rendering of HTML/CSS/Qt font loading cannot be verified programmatically"
  - test: "Type text in the omnibox and click Ask FSB — confirm the PrometheusAgent side panel opens in FSB Agent mode with the prompt pre-filled and NOT auto-submitted"
    expected: "Panel opens, composer shows the typed text, Run Task button not activated"
    why_human: "Side panel interaction, prompt population, and non-auto-submit behavior require a running browser"
  - test: "Type a URL (e.g., https://github.com) in the omnibox and press Enter — confirm the tab navigates to that URL instead of seeding the agent panel"
    expected: "Tab navigates to the URL; agent panel does not open"
    why_human: "URL heuristic routing (isUrlLike) in the JS omnibox handler cannot be tested without a live page"
  - test: "Add a bookmark (Cmd+D), then open a new tab — confirm the favorites grid shows real bookmark data as a colored tile with 2-letter mono abbreviation and name"
    expected: "Tile renders with correct color, mono text, and site name; clicking navigates the tab"
    why_human: "Bookmark data rendered from QWebChannel bridge.bookmarkFavoritesJson requires live browser session"
  - test: "Click a suggestion card (e.g., 'Triage my inbox') — confirm the side panel opens with the exact prompt pre-filled and NOT auto-submitted"
    expected: "Panel opens, composer shows 'Triage my inbox — archive newsletters and draft replies...'; human must press Run Task"
    why_human: "Card-click to seedPromptAndOpen flow requires a running browser to exercise"
  - test: "Toggle to light theme via Prometheus theme setting, then open a new tab — confirm the background is near-white (#fffdfb range) and accent orange is unchanged"
    expected: "[data-theme='light'] CSS token set active; warm light palette visible"
    why_human: "Theme switching requires running the browser and toggling the Interface/PrometheusThemeDark setting"
  - test: "Open DevTools (F12) Network tab, then open a new tab — confirm no font or icon requests go to the network; all qrc: assets load as local resources"
    expected: "Zero network requests to fontawesome.com, Google Fonts, or any CDN; Poppins and Space Mono load from qrc:"
    why_human: "Offline asset validation requires browser DevTools network inspection"
  - test: "Narrow the browser window until content is ~720px wide — confirm suggestion cards collapse from 3-column to 1-column layout"
    expected: "Responsive CSS @media (max-width: 720px) rule collapses .pm-fsb-cards to grid-template-columns: 1fr"
    why_human: "Layout responsiveness requires a live browser and window resizing"
---

# Phase 10: New Tab Start Page — Verification Report

**Phase Goal:** Build the Prometheus New Tab start page — hero PM mark, omnibox with an Ask FSB handoff, favorites grid, and FSB suggested automations — skinned to the canonical Prometheus design.
**Verified:** 2026-06-17
**Status:** human_needed — all automated checks VERIFIED (13/13); 8 visual/behavioral checks require a running browser
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | New Tab opens `falkon:start` by default for fresh profiles | VERIFIED | `tabwidget.cpp:176` — `settings.value(QSL("newTabUrl"), QSL("falkon:start"))` |
| 2 | Three suggestion-card FA SVGs exist as Qt resources (inbox, cart-shopping, calendar-check) | VERIFIED | Files exist non-empty under `falkon/src/lib/data/icons/fa/`; all three registered in `icons.qrc` (3 matches) |
| 3 | `falkon:start` serves the full Prometheus start page HTML with hero, omnibox, favorites grid, and suggestion strip | VERIFIED | `start.html` is 717 lines; contains PM mark HTML, omnibox, favorites grid (`#pm-fav-grid`), suggestion strip (`#pm-fsb-cards`), and all five `qrc:fonts/poppins/` + `qrc:fonts/spacemono/` declarations |
| 4 | The page references only `qrc:` URLs for fonts and icons — no network fetch | VERIFIED | Zero `https?://` occurrences in `start.html`; all font-face and icon `<img src>` use `qrc:` scheme |
| 5 | Both warm dark and warm light themes render via `[data-theme]` attribute set by the bridge | VERIFIED | CSS `:root` defines dark tokens (`--surface: #141110`); `[data-theme="light"]` overrides all warm light tokens (`--surface: #fffdfb`); `initPage` calls `bridge.currentTheme(fn)` and sets `document.documentElement.setAttribute('data-theme', theme)` |
| 6 | QWebChannel bootstrap present with 2-second bridge timeout fallback | VERIFIED | `start.html:492` — `<script src="qrc:///qtwebchannel/qwebchannel.js">`; `start.html:697-699` — `_bridgeTimer = setTimeout(showBridgeError, 2000)`; bridge-absent path shows `pm-bridge-error` and hides `.ask` button |
| 7 | `externaljsobject.cpp` registers `qz_prometheus_start` UNCONDITIONALLY (no construction-time URL guard) | VERIFIED | `externaljsobject.cpp:56-62` — `webChannel->registerObject(QSL("qz_prometheus_start"), new PrometheusStartBridge(bw, page, webChannel))` with NO surrounding if-guard; comment at line 49-55 explains the CR-01 fix rationale |
| 8 | `prometheusstartbridge.cpp` enforces `m_page->url() == falkon:start` INSIDE `openAgentWithPrompt` and `navigateTo` (call-time guards) | VERIFIED | Line 64: `if (!m_page \|\| m_page->url() != QUrl(QSL("falkon:start"))) { return; }` in `openAgentWithPrompt`; Line 107: same guard in `navigateTo` |
| 9 | ZERO `submitTask`/`runTask` in `prometheusstartbridge.cpp` (no auto-submit) | VERIFIED | `grep -n "submitTask\|runTask" prometheusstartbridge.cpp` returned zero matches; `seedPromptAndOpen` only calls `m_taskPrompt->setPlainText(prompt)` and `m_modeStack->setCurrentIndex(0)` |
| 10 | `start.html` `safeName` escapes `& " ' < >` (XSS WR-01 fix) | VERIFIED | Lines 544-551: `.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;')` applied to both `safeName` and `safeMono` |
| 11 | `QPointer<BrowserWindow> m_window` (WR-02 fix) | VERIFIED | `prometheusstartbridge.h:23` — `#include <QPointer>`; line 47 — `QPointer<BrowserWindow> m_window;` |
| 12 | Bounded BFS: `visited < kMaxVisit` cap in `bookmarkFavoritesJson` (WR-03 fix) | VERIFIED | `prometheusstartbridge.cpp:126-131` — `int visited = 0; const int kMaxVisit = 500; while (!queue.isEmpty() && count < 8 && visited < kMaxVisit)` |
| 13 | `seedPromptAndOpen` seeds FSB Agent composer + opens the panel without auto-running | VERIFIED | `agentruntimesidebar.cpp:182-190` — sets `m_taskPrompt->setPlainText(prompt)` and `m_modeStack->setCurrentIndex(0)`; no `submitTask`/`runTask` call path reachable from this method |

**Score: 13/13 automated truths VERIFIED**

---

### Required Artifacts

| Artifact | Status | Evidence |
|----------|--------|----------|
| `falkon/src/lib/data/icons/fa/inbox.svg` | VERIFIED | File exists, non-empty, registered in `icons.qrc` |
| `falkon/src/lib/data/icons/fa/cart-shopping.svg` | VERIFIED | File exists, non-empty, registered in `icons.qrc` |
| `falkon/src/lib/data/icons/fa/calendar-check.svg` | VERIFIED | File exists, non-empty, registered in `icons.qrc` |
| `falkon/src/lib/data/html/start.html` | VERIFIED | 717 lines; contains `qz_prometheus_start`, all qrc: font/icon refs, FSB_SUGGESTIONS, `%PRIVATE-BROWSING%`, `%TITLE%`, both theme token sets, QWebChannel bootstrap |
| `falkon/src/lib/network/schemehandlers/falkonschemehandler.cpp` | VERIFIED | `startPage()` uses two-stage cache (line 151-168): Stage 1 builds static template with `%TITLE%` substituted; Stage 2 replaces `%PRIVATE-BROWSING%` per-request on a local copy |
| `falkon/src/lib/agent/prometheusstartbridge.h` | VERIFIED | Include guard `PROMETHEUSSTARTBRIDGE_H`; `QPointer<BrowserWindow> m_window`; `WebPage* m_page`; four public Q_SLOTS declared |
| `falkon/src/lib/agent/prometheusstartbridge.cpp` | VERIFIED | All four slots implemented; per-slot falkon:start guard in `openAgentWithPrompt` and `navigateTo`; BFS bounded at 500 visited; zero submitTask/runTask |
| `falkon/src/lib/webengine/javascript/externaljsobject.cpp` | VERIFIED | Unconditional bridge registration at lines 56-62; no construction-time URL guard; `#include "prometheusstartbridge.h"` at line 21 |
| `falkon/src/lib/agent/agentruntimesidebar.h` | VERIFIED | `seedPromptAndOpen(const QString& prompt)` declared in public Q_SLOTS at line 38 |
| `falkon/src/lib/agent/agentruntimesidebar.cpp` | VERIFIED | `seedPromptAndOpen` implemented at lines 182-190; sets `m_taskPrompt->setPlainText` and `m_modeStack->setCurrentIndex(0)` |
| `falkon/src/lib/CMakeLists.txt` | VERIFIED | `agent/prometheusstartbridge.cpp` at line 72; `agent/prometheusstartbridge.h` at line 325 |
| `falkon/src/lib/tabwidget/tabwidget.cpp` | VERIFIED | Line 176: `settings.value(QSL("newTabUrl"), QSL("falkon:start")).toUrl()` |

---

### Key Link Verification

| From | To | Via | Status | Evidence |
|------|----|-----|--------|----------|
| `start.html` JS | `qz_prometheus_start` bridge | `new QWebChannel(qt.webChannelTransport, fn) → channel.objects.qz_prometheus_start` | VERIFIED | `start.html:706-707` |
| `start.html` `@font-face` | `qrc:fonts/poppins/Poppins-Thin.ttf` | `src: url('qrc:fonts/poppins/Poppins-Thin.ttf')` | VERIFIED | `start.html:11` |
| `start.html` `<img>` | `qrc:icons/fa/inbox.svg` | `icon: "qrc:icons/fa/inbox.svg"` in FSB_SUGGESTIONS | VERIFIED | `start.html:496` |
| `externaljsobject.cpp setupWebChannel` | `PrometheusStartBridge` | `webChannel->registerObject("qz_prometheus_start", new PrometheusStartBridge(...))` | VERIFIED | `externaljsobject.cpp:60-61` |
| `PrometheusStartBridge::openAgentWithPrompt` | `AgentRuntimeSidebarWidget::seedPromptAndOpen` | `agentWidget->seedPromptAndOpen(prompt)` | VERIFIED | `prometheusstartbridge.cpp:87, 98` |
| `PrometheusStartBridge::bookmarkFavoritesJson` | `mApp->bookmarks()->rootItem()` | BFS traversal with `BookmarkItem* root = mApp->bookmarks()->rootItem()` | VERIFIED | `prometheusstartbridge.cpp:123` |
| `tabwidget.cpp` | `falkon:start` | `settings.value(QSL("newTabUrl"), QSL("falkon:start"))` | VERIFIED | `tabwidget.cpp:176` |

---

### Code Review Fix Confirmation

The REVIEW.md identified 1 BLOCKER (CR-01) and 3 warnings (WR-01, WR-02, WR-03). All four are confirmed fixed:

| Finding | Fix Required | Confirmed in Code |
|---------|-------------|-------------------|
| **CR-01** — Bridge registered with construction-time URL guard (always false, bridge never reached) | Register unconditionally in `setupWebChannel`; per-slot call-time guard | `externaljsobject.cpp:56-62` — unconditional registration; `prometheusstartbridge.cpp:64, 107` — per-slot `m_page->url() != QUrl(QSL("falkon:start"))` guards |
| **WR-01** — `safeName` in `start.html` only escaped `< >`, not `& " '` (XSS via bookmark title in `title=""` attr) | Escape all five: `& < > " '` | `start.html:544-551` — five-way replace chain on both `safeName` and `safeMono` |
| **WR-02** — `m_window` was a raw pointer, use-after-free risk during in-flight event loop messages | Use `QPointer<BrowserWindow>` | `prometheusstartbridge.h:23, 47` — `#include <QPointer>` + `QPointer<BrowserWindow> m_window` |
| **WR-03** — BFS queue unbounded (only output count capped, not visited nodes) | Add `visited < kMaxVisit` loop guard | `prometheusstartbridge.cpp:126-131` — `kMaxVisit = 500` with `visited` counter |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `start.html` favorites grid | `items` from `bridge.bookmarkFavoritesJson` | `mApp->bookmarks()->rootItem()` BFS traversal | Yes — live bookmark DB, up to 8 URL items | FLOWING |
| `start.html` theme | `theme` from `bridge.currentTheme` | `Settings.value("Interface/PrometheusThemeDark", true)` | Yes — reads real settings | FLOWING |
| `start.html` suggestion cards | `FSB_SUGGESTIONS` constant | Hardcoded in JS per spec ("Static suggestion data — do NOT fetch from backend") | N/A — intentionally static per plan | VERIFIED (by design) |

---

### Anti-Patterns Scan

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `prometheusstartbridge.cpp` | 130 | `kMaxVisit = 500` (not 2000 as REVIEW suggested) | Info | Conservative choice — plan's REVIEW suggested 2000 as the cap; implementation uses 500. Both are bounded; 500 is stricter. Not a defect. |

No `TBD`, `FIXME`, or `XXX` markers found in any phase-10 files. No placeholder returns. No hardcoded empty arrays flowing to UI (FSB_SUGGESTIONS are intentionally static per spec).

---

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| START-01 | Opening a New Tab shows the Prometheus start page with hero PM mark, wordmark, and omnibox | SATISFIED (automated + human pending) | `tabwidget.cpp:176` defaults to `falkon:start`; `start.html` contains PM mark, wordmark h1, and omnibox; visual check required |
| START-02 | Omnibox accepts search/address; Ask FSB hands natural-language prompt to FSB Agent panel | SATISFIED (automated + human pending) | `openAgentWithPrompt` implemented with no auto-submit; `navigateTo` scheme-validated; omnibox JS routing verified in code; live test required |
| START-03 | Start page shows a favorites grid that navigates to chosen entry | SATISFIED (automated + human pending) | `bookmarkFavoritesJson` BFS real data confirmed; `navigateTo` wired to tile click; live bookmark rendering check required |
| START-04 | Start page shows FSB suggested automations that seed the agent panel | SATISFIED (automated + human pending) | FSB_SUGGESTIONS hardcoded per spec; `bridge.openAgentWithPrompt(s.prompt)` on card click confirmed; live check required |
| START-05 | Start page uses canonical Prometheus design system (warm tokens, Poppins, Space Mono, Font Awesome) in both themes | SATISFIED (automated + human pending) | All five Poppins weights + Space Mono declared as `qrc:` fonts; dark/light token sets complete; FA SVGs offline-only; DevTools check required |

---

### Human Verification Required

All automated evidence is satisfied. Eight checks require a running browser binary:

#### 1. Start page renders correctly in dark theme

**Test:** Open a new tab (Cmd+T). Confirm URL bar shows `falkon:start`.
**Expected:** Full Prometheus start page — 64x64 PM mark with orange gradient, "Prometheus." heading, sub-line, pill omnibox, empty or populated favorites grid, three suggestion cards in warm-dark theme.
**Why human:** Visual rendering of HTML/CSS/Qt font loading cannot be verified programmatically.

#### 2. Ask FSB handoff — non-auto-submit

**Test:** Type "summarize this morning's emails" in the omnibox and click Ask FSB (or press Enter).
**Expected:** PrometheusAgent side panel opens in FSB Agent mode with prompt pre-filled in the composer. Task does NOT auto-run. Human must press Run Task.
**Why human:** Side panel interaction and non-auto-submit behavior require a running browser.

#### 3. URL routing vs. agent routing

**Test:** Type `https://github.com` in the omnibox and press Enter.
**Expected:** Tab navigates to github.com directly; agent panel does not open.
**Why human:** The `isUrlLike` JS heuristic routing requires a live page execution environment.

#### 4. Favorites grid — real bookmark data

**Test:** Add a bookmark (Cmd+D on any page), then open a new tab.
**Expected:** Favorites grid shows a colored tile with 2-letter mono abbreviation and site name. Clicking the tile navigates the tab.
**Why human:** Bookmark data populated from QWebChannel bridge requires a live browser session.

#### 5. Suggestion card seeding

**Test:** Click "Triage my inbox" card on the start page.
**Expected:** PrometheusAgent side panel opens with "Triage my inbox — archive newsletters and draft replies to anything from my team." pre-filled. NOT auto-submitted.
**Why human:** Card-click to seedPromptAndOpen flow requires a running browser.

#### 6. Light theme rendering

**Test:** Toggle the Prometheus theme setting to light, then open a new tab.
**Expected:** Page background is near-white (#fffdfb range); accent orange unchanged; text is near-black (#1f1a17 range).
**Why human:** Theme switching requires toggling Interface/PrometheusThemeDark and a browser reload.

#### 7. Offline asset validation (DevTools)

**Test:** Open DevTools (F12) Network tab, then open a new tab. Filter for Font and other asset requests.
**Expected:** Zero network requests to any CDN, fontawesome.com, or Google Fonts. Poppins and Space Mono load from qrc: (appear as local resources).
**Why human:** Network tab inspection requires a running browser with DevTools.

#### 8. Responsive layout

**Test:** With the start page open, open the PrometheusAgent side panel to narrow content width to ~720px.
**Expected:** Three suggestion cards collapse from 3-column to 1-column layout at that breakpoint.
**Why human:** Layout responsiveness requires a live browser and window/panel resizing.

---

### Commits Verified

| Commit | Description | In falkon sub-repo |
|--------|-------------|-------------------|
| `05757cfd9` | chore(10-01): bundle FA SVG glyphs | Yes |
| `d4df16fa0` | feat(10-01): repoint new-tab default URL to falkon:start | Yes |
| `e0d592dcf` | feat(10-02): write complete Prometheus start page HTML/CSS/JS | Yes |
| `44aa1aca3` | feat(10-02): update startPage() to two-stage token cache | Yes |
| `ae4db34b8` | feat(10-03): add PrometheusStartBridge and seedPromptAndOpen slot | Yes |
| `ab14cdaa6` | feat(10-03): register qz_prometheus_start bridge in setupWebChannel | Yes |
| `08a8bb8c7` | fix(10): CR-01/WR-02 register bridge unconditionally, per-slot guard, QPointer | Yes |
| `c75a5a147` | fix(10): WR-01 full attribute escaping in safeName/safeMono (XSS close) | Yes |

---

_Verified: 2026-06-17_
_Verifier: Claude (gsd-verifier)_
