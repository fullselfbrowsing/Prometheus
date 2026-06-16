---
phase: 07
slug: compact-safari-style-browser-chrome-and-advanced-tab-managem
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-16
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for compact browser chrome and advanced tab-management execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Qt Test / CMake |
| **Config file** | `falkon/build` configured build tree |
| **Quick run command** | `git diff --check && rg "tabLayout|tabDisplay|TitleAndIcon|FaviconOnly|Compact|Separate" falkon/src/lib` |
| **Full suite command** | `cmake --build falkon/build --target help` |
| **Estimated runtime** | ~30 seconds for static checks; build time depends on local Qt cache |

---

## Sampling Rate

- **After every task commit:** Run `git diff --check` plus the plan-specific `rg` or build command.
- **After every plan wave:** Run `cmake --build falkon/build --target help`; if a concrete Falkon target is available, run `cmake --build falkon/build --target Falkon`.
- **Before `$gsd-verify-work`:** Static checks and available CMake target checks must be green.
- **Max feedback latency:** 90 seconds for static checks; longer build runs may be deferred to wave completion.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | UX-01, UX-02 | T-07-01 | Settings changes do not alter default separate layout | static/build | `rg "tabLayout|tabDisplay|Compact|Separate" falkon/src/lib && git diff --check` | yes | pending |
| 07-02-01 | 02 | 2 | UX-01, UX-04 | T-07-02 | Agent/supervision indicators expose state without leaking secrets | static/build | `rg "agentId|Supervised session active|visual_reason|tabOwner" falkon/src/lib && git diff --check` | yes | pending |
| 07-03-01 | 03 | 3 | UX-03, UX-05 | T-07-03 | Tab actions preserve ownership visibility before destructive operations | static/build | `rg "Search Tabs|Tab Overview|Duplicate Tab|Unload Tab|Detach Tab" falkon/src/lib falkon/src/plugins && git diff --check` | yes | pending |
| 07-04-01 | 04 | 4 | UX-03 | T-07-04 | Group operations route through existing close/restore safeguards | static/build | `rg "New Tab Group|Close Tab Group|Close all tabs in this group" falkon/src/lib && git diff --check` | yes | pending |
| 07-05-01 | 05 | 3 | UX-03, UX-05 | T-07-05 | Tab overview/search foundation filters text without mutating source/MRU order | static/build | `rg "TabSearchFilterModel|TabSearchDelegate|TabSearchPopup" falkon/src/lib/tabwidget falkon/src/lib/CMakeLists.txt && git diff --check` | yes | pending |
| 07-09-01 | 09 | 7 | UX-03, UX-04, UX-05, UX-06 | T-07-09 | Group roles drive compact rails/chips and overview/search group filters | static/build | `rg "TabGroupIdRole|TabGroupCollapsedRole|setGroupFilter|Ungrouped" falkon/src/lib/tabwidget/compacttab* falkon/src/lib/tabwidget/tabsearch* && git diff --check` | yes | pending |
| 07-10-01 | 10 | 8 | UX-06 | T-07-10 | Visual/manual checklist records compact/separate/grouped pass/fail states | manual/static | `test -f .planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VERIFICATION.md` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers phase planning. If implementation adds new `TabModel` roles or tab-group persistence, add or extend Qt tests in:

- `falkon/autotests/tabmodeltest.cpp`
- `falkon/autotests/locationbartest.cpp`
- `falkon/autotests/webtabtest.cpp`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Compact layout at 800px, 1280px, and 1728px+ | UX-01, UX-06 | Requires rendered Qt desktop chrome | Launch Prometheus, switch to Compact, resize window, verify no overlap and active address minimum width. |
| Title-and-icon vs favicon-only display | UX-02 | Requires visual row-height comparison | Toggle Tab Display and verify row height remains stable. |
| Agent, automation, supervision, and tab health badges | UX-04 | Requires runtime agent/supervision state | Start agent-owned/supervised sessions and verify visible badges/tooltips before close/unload/detach. |
| Tab overview/search empty, grouped, and error states | UX-03, UX-06 | Requires interactive popover state | Open Tab Overview and Search Tabs, filter to empty state, trigger row actions, verify copy and layout. |
| Keyboard and mouse behavior | UX-05 | Requires native event delivery | Verify `Ctrl+L`, `Alt+D`, `Ctrl+T`, `Ctrl+W`, `Ctrl+Shift+T`, drag reorder, middle-click close, and context menus. |

---

## Validation Sign-Off

- [x] All phase requirements have automated static/build checks or manual validation entries.
- [x] Sampling continuity defined for task commits and waves.
- [x] No watch-mode commands.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-16
