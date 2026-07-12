---
phase: 15
slug: chromium-ui-shell-compact-chrome-and-tab-model
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
completed: 2026-07-07
---

# Phase 15 - Validation Strategy

> Per-phase validation contract for compact Chromium chrome and tab management.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Chromium `prometheus_unittests` and `browser_tests` |
| **Config file** | `.context/chromium/src/out/Default/args.gn` |
| **Quick run command** | `.context/chromium/src/out/Default/prometheus_unittests` |
| **Full suite command** | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*Prometheus*Compact*:*Prometheus*Chrome*:*Prometheus*Tab*'` |
| **Estimated runtime** | build-dependent; targeted tests expected under 5 minutes after build |

---

## Sampling Rate

- **After every Chromium commit:** run `autoninja -C out/Default prometheus_unittests`
  and `./out/Default/prometheus_unittests`.
- **After every browser UI plan:** run the matching `browser_tests` filter for
  the new Prometheus chrome/tab tests.
- **After every root planning change:** run `git diff --check` and the relevant
  GSD structure verifier.
- **Before phase verification:** full targeted unit/browser tests plus
  `check-chromium-env`, `check-falkon-gpl-guard`, and `verify-artifact-isolation`.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | UX-01, UX-02 | unit | `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='*PrometheusChromeMode*'` | yes | passed |
| 15-02-01 | 02 | 2 | UX-01, UX-02, UX-06, UX-07 | browser/ui | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusCompactChromeLayout*'` | yes | passed |
| 15-03-01 | 03 | 2 | UX-05, UX-06, UX-07 | browser/ui | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusToolbarEntryPoint*'` | yes | passed |
| 15-04-01 | 04 | 3 | UX-04, UX-06 | unit/browser | `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='*PrometheusTabState*'` | yes | passed |
| 15-05-01 | 05 | 3 | UX-03, UX-04, UX-05 | browser | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusTabCommands*'` | yes | passed |
| 15-06-01 | 06 | 4 | UX-01..UX-07 | gate | `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/verify-artifact-isolation.sh` | yes | passed |

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 15 requirements:

- `.context/chromium/src/out/Default` exists from Phase 12.
- `prometheus_unittests` exists from Phase 14.
- `browser_tests` target exists from Phase 14 token gallery work.
- Phase 14 Prometheus color/icon/resource pipeline exists.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rendered compact top chrome at 800px, 1280px, and 1728px+ | UX-06 | Requires visual inspection of actual desktop chrome geometry | Launch Prometheus, enable compact mode, resize to each width, confirm active address/search remains readable, Search Tabs and side-panel toggle are reachable, and no text/icon overlap occurs. |
| macOS traffic lights and drag regions | UX-07 | Platform-native window behavior is hard to prove in unit tests | On macOS, confirm traffic lights remain in native position, titlebar drag still works, and Cmd-L/Cmd-T/Cmd-W/Cmd-Shift-T behave normally. |

## Phase 15-06 Gate Evidence

Automated gates passed on 2026-07-07:

- `.context/chromium/src/out/Default/phase15-06-build.log` - `chrome browser_tests prometheus_unittests`, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase15-06-prometheus-unittests.log` - full `prometheus_unittests`, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase15-06-browser-tests.log` - `browser_tests --gtest_filter='*Prometheus*Compact*:*Prometheus*Chrome*:*Prometheus*Tab*'`, 7/7 tests passed, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase15-06-toolbar-browser-test.log` - `browser_tests --gtest_filter='*PrometheusToolbarEntryPoint*'`, 1/1 tests passed, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase15-06-root-gates.log` - Chromium environment, GPL guard, and artifact isolation gates, `EXIT_CODE=0`.
- `.planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/patches/` - 11 non-empty Chromium patches exported from `19d1f8e0de..HEAD`.

Visual capture note:

- `.context/chromium/src/out/Default/phase15-06-visual-capture-blocker.log` documents the screenshot blocker. `screencapture -R` failed with `could not create image from rect`; full-screen captures returned `EXIT_CODE=0` but visual inspection showed desktop/wallpaper rather than the Prometheus window; Apple Events foreground/window targeting was unavailable with `-1743` authorization errors.
- Do not treat Phase 15 as human-visual approved. Automated geometry coverage passed for compact layout reachability at 800px. Desktop review at 800px, 1280px, 1728px+, including traffic lights and drag regions, is consolidated into the final release review as non-blocking and is not a Phase 15 completion gate.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual checks.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test infrastructure references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.
- [x] Phase 15 automated gate logs contain `EXIT_CODE=0`.
- [x] Phase 15 Chromium patch series exported.
- [x] Desktop visual UAT disposition recorded: deferred to the final release review as non-blocking; automated gates remain the Phase 15 acceptance evidence.

**Approval:** approved 2026-07-07
