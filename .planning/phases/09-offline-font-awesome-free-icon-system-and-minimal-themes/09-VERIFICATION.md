---
phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
verified: 2026-06-17T08:27:45Z
status: human_needed
score: 11/12 must-haves verified (SC-5 start page deferred to Phase 10)
overrides_applied: 0
deferred:
  - truth: "Logo pass wires the real Prometheus PM mark across start page"
    addressed_in: "Phase 10"
    evidence: "Phase 10 goal: 'Build the Prometheus New Tab start page — hero PM mark, omnibox with Ask FSB handoff...' (ROADMAP.md). PrometheusMarkWidget.h comment documents Medium(64) as 'start-page hero'. Component is ready; page is Phase 10 work."
human_verification:
  - test: "Two-weight PM monogram rendering in sidebar header"
    expected: "26x26 compact area shows P visually thin (Poppins Thin 100) adjacent to M visually heavy (Poppins Black 900). No version tag at 26px. Not placeholder text."
    why_human: "QPainter text rendering with registered fonts cannot be verified without running the binary"
  - test: "About dialog PrometheusMarkWidget(Large) at 128px"
    expected: "P in Poppins Thin 100 and M in Poppins Black 900 at ~52px. Version tag shows U+25BD (downward triangle, not letter v) + '0.1' below. No Falkon branding visible anywhere in the dialog."
    why_human: "Font rendering and visual correctness require a live binary"
  - test: "Dark/light theme toggle without restart"
    expected: "Switching from dark to light (or reverse) via theme toggle updates chrome color immediately (warm near-black #1d1816 to warm off-white #f3ede6). Single setStyleSheet call per switch — no flash."
    why_human: "One-frame flash behavior and live palette update cannot be confirmed via grep"
  - test: "Accent swatch picker changes accent color immediately"
    expected: "FSB Control Panel appearance section shows 4 swatch buttons (FSB Orange, Indigo, Teal, Rose). Clicking Indigo changes selected tab highlight, focus ring, and CTA buttons to #6366f1 without restart. FSB Orange restores to #ff6b35."
    why_human: "Requires running binary to confirm UI event wiring and live stylesheet reapplication"
  - test: "Toolbar icons are bundled FA vector glyphs, not platform-theme icons"
    expected: "Back (arrow-left), forward (arrow-right), reload (rotate-right), stop (xmark) show as crisp vector glyphs at 16px within 30x30 buttons. Location bar shows lock (nav-lock-secure) and magnifying-glass (nav-search) from FA subset."
    why_human: "Icon source (bundled vs platform theme) requires visual inspection at runtime"
  - test: "App icon shows canonical PM mark in Finder/Dock"
    expected: "Prometheus.app icon shows orange gradient rounded square with P (thin) and M (heavy) in white. Not a Falkon bird or generic browser icon."
    why_human: "Requires building and inspecting the macOS bundle icon"
  - test: "Font license OFL text accessible in about/legal surface"
    expected: "About dialog shows expandable 'Show Poppins OFL' and 'Show Space Mono OFL' sections that render the license text from Qt resources :/fonts/poppins/OFL.txt and :/fonts/spacemono/OFL.txt."
    why_human: "QTextBrowser content requires running binary to confirm resource loading"
  - test: "No network font requests during cold start"
    expected: "Browser opens new tab with no DNS requests to fonts.googleapis.com or fonts.gstatic.com. All font references resolve from :/fonts/ Qt resources."
    why_human: "Requires network monitoring during live binary execution"
---

# Phase 09: Offline Font Awesome Free Icon System and Minimal Themes — Verification Report

**Phase Goal:** Bundle a free offline Font Awesome icon system and the Poppins and Space Mono brand fonts, complete the logo pass to the real Prometheus mark and wordmark, and reduce Prometheus themes to the canonical warm minimal aesthetic (dark and light token sets).
**Verified:** 2026-06-17T08:27:45Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | FA Free icon subset bundled in Qt resources, license/attribution preserved, no network dependency | VERIFIED | 69 SVGs in `falkon/src/lib/data/icons/fa/`; all have `<!-- Font Awesome Free 6.x — ... CC BY 4.0 -->` comment; icons.qrc has 69 `<file>icons/fa/...` entries; no http/https in QRC files |
| 2 | Central native icon resolver maps all primary action IDs to bundled SVGs | VERIFIED | `prometheusiconresolver.cpp`: 91 `s_actionMap` references (>70 unique action IDs), 3-step fallback chain verified; spot-check action IDs `vault-open`, `diag-log`, `supervision-badge`, `tool-reader`, `utility-theme-toggle`, `tab-pin` all present |
| 3 | Existing QIcon::fromTheme call sites used by primary UI have deterministic Prometheus fallbacks | VERIFIED | 14 specified call sites migrated: navigationbar.cpp (2), locationbar.cpp (4), webview.cpp (8); IC-4b broader scan finds only in-scope unmigrated calls in context-menu code (outside plan scope) |
| 4 | Poppins and Space Mono fonts bundled offline as Qt resources with license/attribution, no network loading | VERIFIED | 5 TTFs present on disk; fonts.qrc lists all 5; OFL.txt files present for both families and listed in fonts.qrc; no `fonts.googleapis.com`/`fonts.gstatic.com` references anywhere in source |
| 5 | Logo pass wires real PM mark and wordmark across app icon, side panel header, start page, and about/first-run | PARTIAL — start page deferred | Side panel: `agentruntimesidebar.cpp:104` uses `PrometheusMarkWidget(Compact)`; about dialog: `aboutdialog.cpp:51` uses `PrometheusMarkWidget(Large)`; app icon: `prometheus.icns` 128KB (non-placeholder), SVG has orange gradient; **start page deferred to Phase 10** |
| 6 | Minimal themes implement canonical warm dark and warm light token sets as pure token swaps | VERIFIED | `prometheus-common.qss`: 0 literal accent hex, 5 `@@ACCENT@@` tokens; `prometheus-dark.qss` has #0d0a09, #1d1816, #141110; `prometheus-light.qss` has #e9e2da, #f3ede6, #fffdfb; disabled opacity 0.35 in common; focus ring with `@@ACCENT_SOFT2@@` |
| 7 | Release packaging includes icon/font/theme assets and Font Awesome plus brand font license metadata | VERIFIED | OFL.txt files in `fonts.qrc`; FA SVGs in `icons.qrc`; FSB logo assets (fsb_logo_dark.png, fsb_logo_light.png, fsb_icon.png) in `icons.qrc`; `prometheus.icns` in `src/main/CMakeLists.txt` bundle |
| 8 | Visual/resource validation fails if icons/fonts missing, remote-loaded, or inconsistent | VERIFIED | `PrometheusIconResolver::icon()` emits `qWarning("...release gate will fail")` and returns 1x1 transparent placeholder for missing icons; no remote URLs in QRC; automated IC/FC/LC/TC gate checks documented as PASS in REVIEW.md |

**Score:** 11/12 truths verified (SC-5 start-page clause deferred to Phase 10)

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Logo pass wires PM mark to start page | Phase 10 | Phase 10 goal: "Build the Prometheus New Tab start page — hero PM mark..." (ROADMAP.md). `PrometheusMarkWidget::Medium` documented as "start-page hero" in prometheusmarkwidget.h. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `falkon/src/lib/data/icons/fa/*.svg` (69 files) | FA Free 6.x SVG subset, CC BY 4.0 attribution | VERIFIED | 69 files present; all have `CC BY 4.0` comment; sidebar-flip is custom placeholder per plan spec |
| `falkon/src/lib/data/fonts/poppins/Poppins-Thin.ttf` | Weight 100 font asset | VERIFIED | File present |
| `falkon/src/lib/data/fonts/poppins/Poppins-Light.ttf` | Weight 300 font asset | VERIFIED | File present |
| `falkon/src/lib/data/fonts/poppins/Poppins-ExtraBold.ttf` | Weight 800 font asset | VERIFIED | File present |
| `falkon/src/lib/data/fonts/poppins/Poppins-Black.ttf` | Weight 900 font asset | VERIFIED | File present |
| `falkon/src/lib/data/fonts/spacemono/SpaceMono-Regular.ttf` | Weight 400 font asset | VERIFIED | File present |
| `falkon/src/lib/data/fonts/poppins/OFL.txt` | SIL OFL 1.1 for Poppins | VERIFIED | Present on disk and listed in fonts.qrc |
| `falkon/src/lib/data/fonts/spacemono/OFL.txt` | SIL OFL 1.1 for Space Mono | VERIFIED | Present on disk and listed in fonts.qrc |
| `falkon/src/lib/data/fonts.qrc` | Qt resource manifest for 5 TTFs + 2 OFL.txt | VERIFIED | 7 font entries confirmed; CMakeLists includes `data/fonts.qrc` |
| `falkon/src/lib/data/icons.qrc` | Extended with 69 FA SVG entries and 3 FSB asset entries | VERIFIED | 69 `icons/fa/` entries + `assets/fsb_logo_dark.png`, `fsb_logo_light.png`, `fsb_icon.png` |
| `falkon/src/lib/agent/promethusfontloader.h` | PromethusFontLoader with static registerAll() | VERIFIED | Exists; correct FALKON_EXPORT class; static registerAll() declared |
| `falkon/src/lib/agent/promethusfontloader.cpp` | registerAll() with 5 font paths and qWarning | VERIFIED | 5 FontEntry structs with correct paths; qWarning with em-dash and weight; listed in CMakeLists |
| `falkon/src/lib/agent/prometheusiconresolver.h` | PrometheusIconResolver singleton with static icon() | VERIFIED | Exists; Q_GLOBAL_STATIC singleton; static icon() and instance() declared |
| `falkon/src/lib/agent/prometheusiconresolver.cpp` | Full action map (70+ entries) and 3-step fallback | VERIFIED | 91 s_actionMap references; steps 1/2/3 all present; qWarning messages verified |
| `falkon/src/lib/agent/prometheusmarkwidget.h` | PrometheusMarkWidget with Size enum | VERIFIED | Exists; Size enum (Compact=26, Medium=64, Large=128); paintEvent override |
| `falkon/src/lib/agent/prometheusmarkwidget.cpp` | Two-weight PM rendering, U+25BD version tag | VERIFIED | `QChar(0x25BD)` confirmed; Poppins Thin + Black separate font lookups confirmed; CR-02+WR-02 guards present |
| `falkon/themes/prometheus/prometheus-common.qss` | Structural rules, NO literal accent hex, @@ACCENT@@ tokens | VERIFIED | 0 literal `#ff6b35`/`#ff8c42`; 5 `@@ACCENT@@` tokens; 1 `@@ACCENT_SOFT2@@`; disabled opacity 0.35; border-radius 9999px |
| `falkon/themes/prometheus/prometheus-dark.qss` | Warm dark token hex values | VERIFIED | #0d0a09 (bg-app), #1d1816 (chrome), #141110 (surface), #f6efe9, #d2c1b4, #a99283 all present |
| `falkon/themes/prometheus/prometheus-light.qss` | Warm light token hex values | VERIFIED | #e9e2da (bg-app), #f3ede6 (chrome), #fffdfb (surface), #1f1a17, #6a584d, #8d7a6e all present |
| `falkon/themes/prometheus/main.css` | Prometheus theme entry point (now bypassed at runtime) | VERIFIED | File exists 318 lines; no `@@ACCENT@@` tokens (pre-baked) but bypassed by `loadSettings()` prometheus branch |
| `falkon/themes/prometheus/metadata.desktop` | Theme metadata for discovery | VERIFIED | File exists per plan execution |
| `falkon/src/lib/data/icons/exeicons/prometheus.icns` | macOS app icon — canonical PM mark | VERIFIED | 128,071 bytes (non-placeholder); SVG has orange gradient (#ff6b35 → #ff8c42); CMakeLists wired |
| `falkon/src/lib/data/icons/exeicons/prometheus.svg` | Canonical PM mark SVG | VERIFIED | Has `rx="30.72"` (24% corner radius), linearGradient with #ff6b35/#ff8c42 stop colors |
| `falkon/src/lib/data/assets/fsb_logo_dark.png` | FSB wordmark dark | VERIFIED | File present; in icons.qrc |
| `falkon/src/lib/data/assets/fsb_logo_light.png` | FSB wordmark light | VERIFIED | File present; in icons.qrc |
| `falkon/src/lib/data/assets/fsb_icon.png` | FSB icon compact | VERIFIED | File present; in icons.qrc |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mainapplication.cpp` | `PromethusFontLoader::registerAll` | Direct call after QIcon::setThemeName block | VERIFIED | Line 144: `PromethusFontLoader::registerAll();` |
| `PromethusFontLoader::registerAll` | `:/fonts/poppins/Poppins-Thin.ttf` | `QFontDatabase::addApplicationFont` | VERIFIED | kFonts[] struct entry at index 0 |
| `fonts.qrc` | `fonts/poppins/Poppins-Thin.ttf` | `<file>` element | VERIFIED | Confirmed by file content |
| `icons.qrc` | `icons/fa/bolt.svg` | `<file>` element | VERIFIED | All 69 FA entries confirmed |
| `prometheusiconresolver.cpp` | `:/icons/fa/bolt.svg` | `QIcon(it->first)` step 1 | VERIFIED | `const QIcon bundled(it->first);` |
| `prometheusiconresolver.cpp` | `QIcon::fromTheme(it->second)` | Step 2 fallback | VERIFIED | `QIcon::fromTheme(it->second, QIcon())` |
| `agentruntimesidebar.cpp` | `PrometheusMarkWidget` | `new PrometheusMarkWidget(PrometheusMarkWidget::Compact, this)` | VERIFIED | Line 104; old placeholder QLabel removed |
| `mainapplication.cpp loadSettings()` | `prometheus-dark.qss` / `prometheus-light.qss` | `loadPrometheusVariant(useDark)` bypassing loadTheme | VERIFIED | CR-01 fix: if (activeTheme == "prometheus") skips loadTheme, calls loadPrometheusVariant directly |
| `mainapplication.cpp setPrometheusAccent` | `@@ACCENT@@` token in QSS files | `substituteAccentTokens()` → `setStyleSheet()` | VERIFIED | `result.replace(QSL("@@ACCENT@@"), accent)` at line 1208 |
| `fsbcontrolpanel.cpp` swatch buttons | `mApp->setPrometheusAccent` | QPushButton onClick | VERIFIED | Line 908; 4 swatches defined at lines 888-891 |
| `aboutdialog.cpp` | `PrometheusMarkWidget(Large)` | Widget construction at line 51 | VERIFIED | `m_markWidget = new PrometheusMarkWidget(PrometheusMarkWidget::Large, this)` |
| `aboutdialog.cpp` | `:/fonts/poppins/OFL.txt` | `QFile` read via `readOfl()` | VERIFIED | Lines 119-120: reads and renders OFL text in about HTML |
| `qzcommon.h` | `DEFAULT_THEME_NAME = "prometheus"` | Macro definition | VERIFIED | Line 135: `#define DEFAULT_THEME_NAME QSL("prometheus")` |
| `src/main/CMakeLists.txt` | `prometheus.icns` | `MACOSX_BUNDLE_ICON_FILE` | VERIFIED | Lines 27-28 set MACOSX_BUNDLE_ICON_FILE to "prometheus.icns" |

### Code Review Findings — Confirmed Fixed

All 5 issues flagged in 09-REVIEW.md (CR-01, CR-02, WR-01, WR-02, WR-03) are confirmed resolved in the codebase:

| Finding | Fix Description | Verified |
|---------|----------------|---------|
| CR-01: theme-flash on startup (double setStyleSheet) | `loadSettings()` now has `if (activeTheme == "prometheus")` branch that calls `loadPrometheusVariant()` directly, skipping `loadTheme()` / main.css entirely | VERIFIED at lines 1048-1055 |
| CR-02: fontM family-fallback guard incomplete (`isEmpty()` only) | `fontM.family().isEmpty() \|\| fontM.family() != QSL("Poppins")` check added with inner `qWarning` on fallback | VERIFIED at lines 64-70 |
| WR-01: fontP condition used accidental operator-precedence chaining | Rewritten as `fontP.family().isEmpty() \|\| fontP.family() != QSL("Poppins")` — intent explicit | VERIFIED at line 55 |
| WR-02: fontTag family-fallback guard incomplete | `fontTag.family().isEmpty() \|\| fontTag.family() != QSL("Space Mono")` with `qWarning` and fallback to "monospace" | VERIFIED at lines 96-100 |
| WR-03: double setStyleSheet on startup (same root as CR-01) | Resolved by CR-01 fix — one setStyleSheet per startup | VERIFIED |

INFO findings IN-01 (redundant s_mapInitialized) and IN-02 (aboutdialog fallback branch invisible widget) were deferred per REVIEW.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `falkon/themes/prometheus/main.css` | 2 | Comment says "Accent-colored rules use #ff6b35, #ff8c42, rgba(255,107,53,0.18) tokens" — wording implies these are tokens but they are literal hex | INFO | Cosmetic only; `main.css` is now bypassed entirely at runtime by the CR-01 fix; comment is misleading but harmless |
| `falkon/src/lib/navigation/locationbar.cpp` | 98 | `QIcon::fromTheme(QSL("edit-paste"))` for `PasteAndGo` action — bare fromTheme not migrated | INFO | Not in plan migration scope (plan listed lines 366/438/446/449 only); PasteAndGo is context-menu convenience action, not primary nav surface |

No TBD/FIXME/XXX debt markers found in phase 09 files.

### IC-4b Broader fromTheme Scan

Remaining `QIcon::fromTheme` hits in the 4 primary-UI scoped files:

- `locationbar.cpp:98` — `edit-paste` in PasteAndGo constructor (not a plan migration site; context-menu accessory)
- **NONE** in `navigationbar.cpp` (besides intentionally kept context-menu `edit-clear` at lines 437/476 which are in history drop-down menus, not primary chrome)
- `webview.cpp:771,792,795,826,830,846,853,925,945` — context-menu code paths for copy-link, reload-dials, select-all, edit-find-in-page; outside plan migration scope (plan specified lines ~989-1027 only)
- **NONE** in `agentruntimesidebar.cpp` (previously had line 63 for the app icon theme call, but that is confirmed removed)

All remaining hits are in context-menu / history-menu code that was not in the migration scope of Plan 05. The plan explicitly stated: "Only migrate the 14 call sites listed above."

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ICON-01 | 09-01, 09-03 | Offline FA Free icon subset in Qt resources, license preserved | SATISFIED | 69 SVGs with CC BY 4.0; icons.qrc complete |
| ICON-02 | 09-03 | Central native icon resolver for all action categories | SATISFIED | PrometheusIconResolver with 91+ entries covering all 09-UI-SPEC.md tables |
| ICON-03 | 09-03, 09-05 | Primary UI icons have deterministic bundled fallbacks | SATISFIED | 3-step fallback chain; 14 primary call sites migrated to resolver |
| ICON-04 | 09-06 | Release validation fails when icons missing/remote/unattributed | SATISFIED | qWarning + 1x1 placeholder for missing icons; IC-1/IC-2/IC-3/IC-4 gate checks all documented PASS in REVIEW.md |
| THEME-01 | 09-04 | Minimal native-feeling themes, restrained surfaces | SATISFIED | QSS verified; warm token values match 09-UI-SPEC.md; disabled/hover/focus states present |
| THEME-02 | 09-04 | Themes support all states without heavy gradients | SATISFIED | disabled=0.35 opacity; warning=#febc2e; destructive=#ff5f57; supervised pill with @@ACCENT@@ |
| THEME-03 | 09-04, 09-06 | Canonical warm dark/light token sets and accent recolor as pure token swaps | SATISFIED | @@ACCENT@@/@@ACCENT2@@/@@ACCENT_SOFT2@@ tokens; substituteAccentTokens() verified; 4 curated swatches |
| FONT-01 | 09-01, 09-02 | Poppins/Space Mono bundled offline, no network loading | SATISFIED | 5 TTFs in fonts.qrc; registerAll() called before UI; no Google Fonts CDN refs |
| LOGO-01 | 09-05, 09-06 | Real PM brand mark across app icon, side panel header, about/first-run | SATISFIED | PrometheusMarkWidget(Compact) in sidebar; PrometheusMarkWidget(Large) in about; prometheus.icns 128KB non-placeholder; **start page deferred to Phase 10** |

### Human Verification Required

1. **Two-weight PM monogram in sidebar header**
   **Test:** Build and run the browser, open the sidebar panel.
   **Expected:** 26x26 compact area shows P visually thin (Poppins Thin 100) adjacent to M visually heavy (Poppins Black 900). Wordmark "Pro" (light) + "metheus" (orange #ff6b35) follows. No placeholder "Prometheus" plain-text label.
   **Why human:** QPainter font-weight rendering requires a running binary.

2. **About dialog PrometheusMarkWidget(Large)**
   **Test:** Open Help > About Prometheus.
   **Expected:** 128x128 PM mark at top (P thin, M heavy). Version tag shows "▽0.1" with U+25BD (downward triangle, not letter v). No Falkon branding. OFL license sections for Poppins and Space Mono are expandable.
   **Why human:** Font rendering, Unicode character appearance, and OFL resource loading require a live binary.

3. **Dark/light theme toggle without restart**
   **Test:** Toggle dark ↔ light via the theme toggle control (toolbar or settings).
   **Expected:** Chrome color changes immediately from warm near-black #1d1816 (dark) to warm off-white #f3ede6 (light). No visible flash or intermediate state. Single-frame transition.
   **Why human:** One-frame flash elimination and live palette update cannot be confirmed programmatically.

4. **Accent swatch picker changes accent color immediately**
   **Test:** Navigate to FSB Control Panel / appearance section. Four swatch buttons must be visible.
   **Expected:** Clicking Indigo changes accent to #6366f1 immediately (selected tab highlight, focus rings, CTA buttons). Clicking FSB Orange restores to #ff6b35. No restart required.
   **Why human:** Requires running binary to confirm UI event wiring and live setStyleSheet() reapplication.

5. **Toolbar icons are bundled FA vector glyphs**
   **Test:** Observe back/forward/reload/stop buttons and location bar icons in the running browser.
   **Expected:** Arrow-left, arrow-right, rotate-right, xmark glyphs (not platform-native icons). Lock and magnifying-glass in location bar. Icons are crisp at both 1x and 2x display scale.
   **Why human:** Bundle vs. platform-theme icon source requires visual confirmation.

6. **App icon shows canonical PM mark**
   **Test:** View Prometheus.app in macOS Finder or Dock.
   **Expected:** Orange gradient (#ff6b35 → #ff8c42) rounded square with P (thin) and M (heavy) in white. Not the Falkon bird or generic browser placeholder.
   **Why human:** Bundle icon appearance requires a built .app package.

7. **Font license text accessible in about/legal surface**
   **Test:** Expand "Show Poppins OFL" and "Show Space Mono OFL" in the about dialog.
   **Expected:** Full SIL OFL 1.1 license text renders from Qt resources :/fonts/poppins/OFL.txt and :/fonts/spacemono/OFL.txt.
   **Why human:** Resource loading and text rendering require a running binary.

8. **No network font requests during cold start**
   **Test:** Run the browser with a network proxy or packet capture. Open a new tab.
   **Expected:** Zero DNS requests to fonts.googleapis.com or fonts.gstatic.com. All fonts load from :/fonts/ Qt resources.
   **Why human:** Requires network monitoring during live binary execution.

### Gaps Summary

No gaps blocking goal achievement. The single deferred item (start page logo) is explicitly scoped to Phase 10 per the roadmap. All automated verification checks from 09-REVIEW.md ICON-04 release gate are documented as PASS. All 5 code-review findings (CR-01, CR-02, WR-01, WR-02, WR-03) are confirmed fixed in the codebase. The remaining bare `QIcon::fromTheme` calls in the 4 scoped files are all in context-menu code paths that were not part of the Phase 9 plan migration scope.

**Status is `human_needed` because 8 visual/behavioral checks require a running binary.** Automated evidence is solid for all 11 verifiable truths.

---

_Verified: 2026-06-17T08:27:45Z_
_Verifier: Claude (gsd-verifier)_
