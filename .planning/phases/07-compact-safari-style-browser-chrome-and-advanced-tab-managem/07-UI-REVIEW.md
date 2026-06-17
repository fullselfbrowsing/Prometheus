# Phase 07 - UI Review

**Audited:** 2026-06-17  
**Baseline:** approved `07-UI-SPEC.md`  
**Screenshots:** not captured (native Qt desktop UI; Playwright/web-server capture not applicable). Manual visual checklist was approved on 2026-06-16 16:05:29 CDT.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract labels and destructive confirmations are present; exact tab-action error copy is not traceable in source. |
| 2. Visuals | 4/4 | Compact row, grouped tabs, badges, overview/search controls, and accessibility labels are implemented and visually approved. |
| 3. Color | 3/4 | Accent, destructive, and group swatches follow the spec; owner badge uses one hardcoded neutral outside the declared palette. |
| 4. Typography | 4/4 | Uses Qt platform font defaults, semibold emphasis, and required right/middle elision without viewport or negative letter spacing. |
| 5. Spacing | 3/4 | Core 32px rows, 16px icons, 180/320/520px address constraints, and 4px/8px spacing are present; Search popup group chip height is 16px vs the 24px group-label contract. |
| 6. Experience Design | 4/4 | Keyboard navigation, empty states, disabled states, destructive confirmations, state badges, restore/unload/close flows, and manual visual coverage are present. |

**Overall: 21/24**

---

## Top 3 Priority Fixes

No blocking priority fixes. Minor contract follow-ups:

1. **Add the exact tab-action error copy or document why native errors use another surface** - users and future audits cannot trace `Tab action failed. Refresh the tab list and try again.` in source - add a shared fallback error label for failed popup row actions or update `07-UI-SPEC.md` if typed native/API errors are the intended contract.
2. **Align Search popup group chip height with the 24px contract** - group labels in overview/search are currently 16px - change `GroupLabelHeight` in `tabsearchdelegate.cpp` to 24px if it still fits the 32px row, or explicitly amend the spec for dense popup rows.
3. **Replace hardcoded neutral owner badge gray with a palette-derived token** - `#606060` may drift from dark/light native themes - derive the owner badge fill from `QPalette` or declare the neutral in the design contract.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

The approved preference labels and values are implemented exactly: `Tab Layout`, `Compact`, `Separate`, `Tab Display`, `Title and Icon`, and `Favicon Only` appear in `falkon/src/lib/preferences/preferences.ui:847`, `:855`, `:860`, `:888`, `:896`, and `:901`, with load/save wiring in `preferences.cpp:266` and `:1009`.

Tab management copy also matches the contract for primary CTA and empty/destructive states. `New Tab Group` is used in `tabsearchpopup.cpp:115`; the empty state uses `No tabs found` and `Clear the search or open a new tab group.` at `tabsearchpopup.cpp:85-86`; destructive confirmations include `Close Other Tabs`, `Close these tabs?`, and `Close Tab Group` at `tabcontextmenu.cpp:95-132` and `tabsearchpopup.cpp:824-827`.

Gap: the exact error copy `Tab action failed. Refresh the tab list and try again.` from `07-UI-SPEC.md` was not found in the phase UI source. The verification record says Search Tabs error states were human-approved (`07-VERIFICATION.md:121-126`), so this is a traceability/copy risk, not evidence of a failed rendered state.

### Pillar 2: Visuals (4/4)

Compact chrome is a single native row: `NavigationBar` registers `CompactTabStrip`, adds the existing `TabWidget::locationBars()` as the active address/search field, and wires icon-only `Tab Overview` and `Search Tabs` controls with tooltips/accessibility names (`navigationbar.cpp:131-145`, `:185-231`). Compact mode uses fixed layout IDs with `compact-tabs`, `locationbar`, `button-taboverview`, and `button-searchtabs` in one row (`navigationbar.cpp:574-587`).

Visual state density is well supported. Compact tabs render group rails, collapsed chips, favicon/title modes, and right-edge owner/automation/supervision/health badges (`compacttabdelegate.cpp:145-229`, `:253-280`). Search rows render favicon, semibold title, middle-elided domain/URL, group labels, rails, and state badges (`tabsearchdelegate.cpp:142-217`, `:258-282`).

Human verification covers the visual risk that code cannot prove here: compact/separate layout, title/favicon-only display, 800px/1280px/1728px+ widths, grouped/overflow tabs, active automation, supervised/warning/private states, Tab Overview, and Search Tabs were approved in `07-VERIFICATION.md:117-126`.

### Pillar 3: Color (3/4)

Accent and destructive usage is restrained and state-based. The delegates define `#ff6b35` only for active automation, supervision, and focus rings, and `#ff6666` only for unhealthy tab badges (`compacttabdelegate.cpp:42-43`, `:214-220`, `:264-277`; `tabsearchdelegate.cpp:44-45`, `:219-225`, `:269-282`).

Group swatches match the approved muted list exactly in both rendering and model normalization: `#3a7bd5`, `#2f9e7e`, `#9b6ade`, `#d29b36`, and `#a65b5b` (`tabgroupmodel.cpp:291-329`; mirrored in `compacttabdelegate.cpp:46-76` and `tabsearchdelegate.cpp:48-78`).

Minor issue: owner badges use a hardcoded neutral `#606060` in both delegates (`compacttabdelegate.cpp:253-261`; `tabsearchdelegate.cpp:258-266`). It is not accent misuse, but it is outside the declared palette and could age poorly across platform themes.

### Pillar 4: Typography (4/4)

The phase follows the spec's system-font direction by relying on Qt platform fonts rather than hardcoded sizes. Heading/label emphasis uses semibold via `QFont::DemiBold` (`tabsearchpopup.cpp:93-96`, `:155-157`; `compacttabdelegate.cpp:184-201`; `tabsearchdelegate.cpp:169-212`).

Text overflow behavior matches the contract. Compact tab titles and group labels elide right (`compacttabdelegate.cpp:201`, `:209`), while overview/search URLs/domains elide middle (`tabsearchdelegate.cpp:216`). No viewport-scaled font sizing or negative letter spacing was found in the audited phase files.

### Pillar 5: Spacing (3/4)

The main compact chrome dimensions match the UI-SPEC. Address/search constraints are 180px minimum, 320px preferred, 520px maximum, with a 40px maximum compact row (`navigationbar.cpp:66-69`, `:680-693`). Compact tab dimensions are 32px row height, 16px icons, 32px favicon-only cells, 144px preferred inactive tabs, 72px minimum, and 176px maximum (`compacttabdelegate.h:46-51`; `compacttabstrip.cpp:127-134`).

Spacing constants generally follow the 4px scale: `Padding = 8`, `Gap = 4`, `DotSize = 8`, and fixed 32px rows in compact/search delegates (`compacttabdelegate.cpp:30-40`; `tabsearchdelegate.cpp:32-42`). The 2px group rail is explicitly allowed by the visual contract.

Spec mismatch: `tabsearchdelegate.cpp:39` sets `GroupLabelHeight = 16`, while the UI-SPEC declares group label height as 24px. Compact tabs use 24px (`compacttabdelegate.cpp:37`), so the mismatch is limited to overview/search row group chips.

### Pillar 6: Experience Design (4/4)

The native interaction surface is complete. Preferences persist compact/separate and title/favicon settings with clamped defaults (`qzsettings.cpp:26-64`, `:110-133`; `preferences.cpp:266-271`, `:1009-1016`). Separate mode still restores normal toolbar/search behavior, while compact mode hides the standalone search bar and conventional tab row (`navigationbar.cpp:574-606`; `tabwidget.cpp:165-180`).

Search/overview supports keyboard and state coverage: Esc closes, Enter activates, printable typing moves focus to search, and Ctrl+F focuses the search field (`tabsearchpopup.cpp:267-320`). Empty state is wired through `updateEmptyState()` and the stacked view (`tabsearchpopup.cpp:85-86`, `:171-190`, `:394-397`).

Advanced actions route through existing native methods instead of direct data mutation: duplicate/detach/load/unload/restore/clear/close actions are wired in `tabsearchpopup.cpp:480-527`, and group operations are guarded through native methods at `tabsearchpopup.cpp:742-830`. Destructive flows use `CheckBoxDialog` with state summaries that surface group, owner, active automation, supervision, and health before action (`tabcontextmenu.cpp:59-81`, `:390-497`; `tabsearchpopup.cpp:622-664`, `:835-850`).

---

## Files Audited

- `/Users/lakshman/.codex/get-shit-done/references/ui-brand.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-UI-SPEC.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-CONTEXT.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VERIFICATION.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-REVIEW.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-REVIEW-FIX.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-01-PLAN.md` through `07-10-PLAN.md`
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-01-SUMMARY.md` through `07-10-SUMMARY.md`
- `falkon/src/lib/navigation/navigationbar.cpp`
- `falkon/src/lib/tabwidget/compacttabdelegate.h`
- `falkon/src/lib/tabwidget/compacttabdelegate.cpp`
- `falkon/src/lib/tabwidget/compacttabfiltermodel.cpp`
- `falkon/src/lib/tabwidget/compacttabstrip.cpp`
- `falkon/src/lib/tabwidget/tabsearchdelegate.h`
- `falkon/src/lib/tabwidget/tabsearchdelegate.cpp`
- `falkon/src/lib/tabwidget/tabsearchfiltermodel.cpp`
- `falkon/src/lib/tabwidget/tabsearchpopup.cpp`
- `falkon/src/lib/tabwidget/tabcontextmenu.cpp`
- `falkon/src/lib/tabwidget/tabgroupmodel.cpp`
- `falkon/src/lib/tabwidget/tabwidget.cpp`
- `falkon/src/lib/preferences/preferences.ui`
- `falkon/src/lib/preferences/preferences.cpp`
- `falkon/src/lib/other/qzsettings.cpp`
- `falkon/src/lib/app/browserwindow.cpp`
- `falkon/src/lib/app/mainmenu.cpp`
