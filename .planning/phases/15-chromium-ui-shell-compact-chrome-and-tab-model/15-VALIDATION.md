---
phase: 15
slug: chromium-ui-shell-compact-chrome-and-tab-model
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
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
| 15-01-01 | 01 | 1 | UX-01, UX-02 | unit | `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='*PrometheusChromeMode*'` | yes | pending |
| 15-02-01 | 02 | 2 | UX-01, UX-02, UX-06, UX-07 | browser/ui | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusCompactChromeLayout*'` | yes | pending |
| 15-03-01 | 03 | 2 | UX-05, UX-06, UX-07 | browser/ui | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusToolbarEntryPoint*'` | yes | pending |
| 15-04-01 | 04 | 3 | UX-04, UX-06 | unit/browser | `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='*PrometheusTabState*'` | yes | pending |
| 15-05-01 | 05 | 3 | UX-03, UX-04, UX-05 | browser | `.context/chromium/src/out/Default/browser_tests --gtest_filter='*PrometheusTabCommands*'` | yes | pending |
| 15-06-01 | 06 | 4 | UX-01..UX-07 | gate | `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/verify-artifact-isolation.sh` | yes | pending |

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

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual checks.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test infrastructure references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-07
