---
phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
reviewed: 2026-06-17T00:00:00Z
depth: deep
files_reviewed: 16
files_reviewed_list:
  - falkon/src/lib/agent/promethusfontloader.cpp
  - falkon/src/lib/agent/promethusfontloader.h
  - falkon/src/lib/agent/prometheusiconresolver.cpp
  - falkon/src/lib/agent/prometheusiconresolver.h
  - falkon/src/lib/agent/prometheusmarkwidget.cpp
  - falkon/src/lib/agent/prometheusmarkwidget.h
  - falkon/src/lib/agent/agentruntimesidebar.cpp
  - falkon/src/lib/app/mainapplication.cpp
  - falkon/src/lib/app/qzcommon.h
  - falkon/src/lib/other/aboutdialog.cpp
  - falkon/src/lib/other/aboutdialog.h
  - falkon/src/lib/navigation/locationbar.cpp
  - falkon/src/lib/navigation/navigationbar.cpp
  - falkon/src/lib/webengine/webview.cpp
  - falkon/themes/prometheus/prometheus-common.qss
  - falkon/themes/prometheus/prometheus-dark.qss
  - falkon/themes/prometheus/prometheus-light.qss
  - falkon/themes/prometheus/main.css
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: resolved
fixed: [CR-01, CR-02, WR-01, WR-02, WR-03]
deferred: [IN-01, IN-02]
---

# Phase 09: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** deep
**Files Reviewed:** 16 (+main.css, fonts.qrc, icons.qrc cross-referenced)
**Status:** findings

## Summary

Phase 09 delivers: offline FA icon bundling, PromethusFontLoader, PrometheusIconResolver singleton,
PrometheusMarkWidget QPainter monogram, runtime theme switching with accent token substitution, and
the PrometheusMarkWidget integration into the about dialog and sidebar. The overall architecture is
sound — the token substitution pipeline works, the 3-step icon fallback chain is correct, and the
QRC manifests are complete (every resolver path is present in icons.qrc). No security or data-loss
issues were found.

Two blockers require fixing before this ships: the `main.css` file violates its own contract and
causes a dark-theme flash for light-theme users; and the `fontM` family-fallback check in
`prometheusmarkwidget.cpp` is incomplete, meaning a silently failed Poppins-Black load goes
undetected and renders the monogram in the wrong font without any warning. Three quality warnings
cover: a confusingly-written font-family condition for `fontP`, the matching incomplete check for
`fontTag`, and the avoidable double `setStyleSheet` call on startup.

---

## Critical Issues

### CR-01: `main.css` violates its own no-literal-accent contract and causes a light-theme startup flash

**File:** `falkon/themes/prometheus/main.css:2-4, 57, 81, 94`

**Issue:** The file header on line 3 states "NO literal accent hex in this file. Substitution is
done at runtime by MainApplication::setPrometheusAccent() before setStyleSheet is called." This
contract is false: `main.css` is a static concatenation of `prometheus-common.qss` and
`prometheus-dark.qss` with all `@@ACCENT@@`/`@@ACCENT_SOFT2@@` tokens already expanded to their
default hex values (`#ff6b35`, `rgba(255,107,53,0.18)`, etc.).

The actual flow in `loadSettings()` is:

1. `loadTheme("prometheus")` reads `main.css` and calls `setStyleSheet(literal_dark_qss)`.
2. `loadPrometheusVariant(useDark)` immediately calls `setStyleSheet(tokenized_qss)`, replacing step 1.

For **dark**-theme users this is a no-op waste (two identical effective stylesheets applied). For
**light**-theme users it produces a visible flash: the dark palette from `main.css` is rendered
for one frame before `loadPrometheusVariant(false)` replaces it with the light palette. The
comment on line 2 also contradicts line 3: it refers to the literal values as "tokens".

**Fix:** Replace `main.css` with a minimal stub that provides only the non-accent structural rules
(navigation bar height, border radii, etc.) with `@@ACCENT@@` tokens, identical to
`prometheus-common.qss`. Then either (a) have `loadTheme("prometheus")` skip the `setStyleSheet`
call and delegate entirely to `loadPrometheusVariant`, or (b) replace the `main.css` body with a
forward comment pointing to `prometheus-common.qss`:

```cpp
// In mainapplication.cpp loadSettings(), replace the two-step call with:
void MainApplication::loadSettings()
{
    Settings settings;
    settings.beginGroup(QSL("Themes"));
    QString activeTheme = settings.value(QSL("activeTheme"), DEFAULT_THEME_NAME).toString();
    settings.endGroup();

    if (activeTheme == QLatin1String("prometheus")) {
        // Skip loadTheme for prometheus — the tokenized QSS files are the canonical source.
        const bool useDark = settings.value(QSL("Interface/PrometheusThemeDark"), true).toBool();
        loadPrometheusVariant(useDark);
    } else {
        loadTheme(activeTheme);
    }
    // ... rest of loadSettings unchanged
}
```

And update `main.css` header to accurately state it contains pre-expanded defaults (or remove
the contradicting comment entirely).

---

### CR-02: `fontM` family-fallback guard is incomplete — silently uses wrong font on load failure

**File:** `falkon/src/lib/agent/prometheusmarkwidget.cpp:63-65`

**Issue:** `QFontDatabase::font(family, style, 0)` does not return a null or empty-family font on
failure; it returns the nearest available match (per Qt docs: "If the family does not exist, the
nearest match is returned"). This means if `Poppins-Black.ttf` fails to load (resource missing,
corrupt, or QtSvg-related failure), `QFontDatabase::font("Poppins", "Black", 0)` returns a
substitute font whose `.family()` is something like `"Helvetica Neue"` — not empty. The guard at
line 64 only checks `isEmpty()` and therefore does **not** trigger the retry:

```cpp
// Current — incomplete guard for fontM:
QFont fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), 0);
if (fontM.family().isEmpty()) {           // <-- NEVER triggers for a fallback family
    fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), px);
}
```

The monogram renders the "M" in the system default proportional font at Black weight — visually
wrong — with no warning emitted. Contrast with `fontP` at line 55, which (accidentally, through
operator-precedence chaining) detects the non-"Poppins" fallback family; `fontM` lacks the
equivalent detection.

Note: `fontTag` (Space Mono, line 89-92) has the same incomplete `isEmpty()` guard.

**Fix:** Apply the same family identity check used for `fontP`, stated explicitly:

```cpp
// Fixed fontM guard:
QFont fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), 0);
if (fontM.family().isEmpty() || fontM.family() != QSL("Poppins")) {
    fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), px);
    if (fontM.family() != QSL("Poppins")) {
        qWarning("PrometheusMarkWidget: Poppins Black not found, falling back to %s",
                 qPrintable(fontM.family()));
    }
}

// Fixed fontTag guard (line 89-92):
QFont fontTag = QFontDatabase::font(QSL("Space Mono"), QSL("Regular"), 0);
if (fontTag.family().isEmpty() || fontTag.family() != QSL("Space Mono")) {
    qWarning("PrometheusMarkWidget: Space Mono not found, using fallback");
    fontTag.setFamily(QSL("monospace"));
}
```

---

## Warnings

### WR-01: `fontP` family-check condition relies on accidental operator-precedence chaining

**File:** `falkon/src/lib/agent/prometheusmarkwidget.cpp:55`

**Issue:** The condition

```cpp
if (fontP.family().isEmpty() || fontP.family() == QSL("Poppins") == false)
```

reads as if it chains two comparisons, but C++ evaluates `==` left-to-right:
`(fontP.family() == QSL("Poppins")) == false`, which is `!(fontP.family() == QSL("Poppins"))`.
The logic is accidentally correct (it detects any non-"Poppins" family), but it will draw a
compiler warning under `-Wbool-operation` or equivalent, and every reader is forced to mentally
trace operator precedence. The intent should be stated directly.

**Fix:**
```cpp
if (fontP.family().isEmpty() || fontP.family() != QSL("Poppins")) {
    fontP = QFontDatabase::font(QSL("Poppins"), QSL("Thin"), px);
}
```

---

### WR-02: `fontTag` (Space Mono) family-fallback guard is incomplete — same root cause as CR-02

**File:** `falkon/src/lib/agent/prometheusmarkwidget.cpp:89-92`

**Issue:** As with `fontM`, `QFontDatabase::font("Space Mono", "Regular", 0)` returns a non-empty
fallback family when Space Mono is not registered. The existing guard

```cpp
if (fontTag.family().isEmpty()) {
    fontTag.setFamily(QSL("Space Mono"));
}
```

never triggers in the failure case, so the version tag silently renders in the wrong typeface.
Space Mono has no themed fallback and no `qWarning` either, so failures are completely silent.

**Fix:** See the corrected guard under CR-02 above.

---

### WR-03: Double `setStyleSheet` on startup causes a one-frame dark flash for light-theme users

**File:** `falkon/src/lib/app/mainapplication.cpp:1048, 1054`

**Issue:** `loadSettings()` unconditionally calls `loadTheme(activeTheme)` first (which calls
`setStyleSheet` with `main.css` — a baked-in dark palette), then immediately calls
`loadPrometheusVariant(useDark)` (another `setStyleSheet`). The first call is wasted for dark
users and actively harmful for light users: Qt processes the first `setStyleSheet` synchronously,
so any pending paint event before `loadPrometheusVariant` runs will display the wrong palette.
This is directly caused by the same root as CR-01. The fix under CR-01 (skip `loadTheme` for the
prometheus theme path) resolves this warning automatically.

---

## Info

### IN-01: `s_mapInitialized` is redundant with `Q_GLOBAL_STATIC` construction guarantee

**File:** `falkon/src/lib/agent/prometheusiconresolver.cpp:7, 15-18`
**File:** `falkon/src/lib/agent/prometheusiconresolver.h:41`

**Issue:** `Q_GLOBAL_STATIC` guarantees the `PrometheusIconResolver` constructor is called exactly
once (via `std::call_once` semantics in Qt 5/6). The `s_mapInitialized` bool and the
`if (!s_mapInitialized)` guard inside the constructor are therefore unreachable dead state — the
constructor can only ever run once. The bool adds noise and a misleading impression that the map
could be initialized multiple times.

**Fix:** Remove `s_mapInitialized` entirely. Call `initActionMap()` unconditionally in the
constructor body.

---

### IN-02: `aboutdialog.cpp` fallback branch leaves `m_markWidget` invisible if layout cast fails

**File:** `falkon/src/lib/other/aboutdialog.cpp:66-69`

**Issue:** The `else` branch (line 67) executes when `qobject_cast<QVBoxLayout*>(layout())`
returns null. In that case `m_markWidget` is created with `this` as parent (line 51) but is
never added to any layout, so it is invisible. The `aboutdialog.ui` file does use `QVBoxLayout`
so the fallback is currently dead code. However, if the `.ui` ever changes, the fallback silently
produces no visual output instead of gracefully degrading.

**Fix:** In the fallback branch, add `m_markWidget` above `ui->label`:
```cpp
} else {
    ui->label->hide();
    // Insert markWidget above textLabel as a fallback
    QVBoxLayout* topLevel = new QVBoxLayout();
    topLevel->addWidget(m_markWidget, 0, Qt::AlignHCenter);
    topLevel->addWidget(ui->textLabel);
    topLevel->addWidget(ui->buttonBox);
    // or simply add at top of whatever layout exists:
    layout()->insertWidget(0, m_markWidget);  // generic insertion
}
```

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
