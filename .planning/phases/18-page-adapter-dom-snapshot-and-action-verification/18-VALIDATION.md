---
phase: 18
slug: page-adapter-dom-snapshot-and-action-verification
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-07
---

# Phase 18 - Validation Strategy

Per-phase validation contract for page reads, DOM snapshots, JS execution, page actions, waits, and action verification.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Chromium GN targets with GTest unit tests and `InProcessBrowserTest` browser tests. |
| **Config file** | Unit target: `.context/chromium/src/chrome/browser/prometheus/BUILD.gn`; browser-test source set: `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn`, included by `.context/chromium/src/chrome/test/BUILD.gn`. |
| **Quick run command** | `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusPage*:*PrometheusAgent*'` |
| **Focused browser command** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*Prometheus*Page*:*PrometheusAgentService*'` |
| **Full suite command** | `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusPage*:*PrometheusAgent*' && ./out/Default/browser_tests --gtest_filter='*Prometheus*Page*:*PrometheusAgentService*'` |
| **Estimated runtime** | Focused unit tests: under 60 seconds; focused browser tests: several minutes; build depends on incremental Chromium state. |

---

## Sampling Rate

- **After every task commit:** Run the relevant focused `prometheus_unittests` filter for pure logic plus one targeted browser-test filter for changed browser behavior.
- **After every plan wave:** Build `browser_tests prometheus_unittests`, then run all Phase 18 focused unit and browser filters.
- **Before phase verification:** Build, focused unit tests, focused browser tests, root Chromium env checks, GPL guard, artifact isolation, diff checks, preservation ledger update, and Chromium patch export.
- **Max feedback latency:** Keep pure-logic feedback under 60 seconds where possible; browser-level feedback may take several minutes and must run before wave completion.

---

## Requirement Verification Map

| Requirement | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|------------|-----------------|-----------|-------------------|-------------|--------|
| PAGE-01 | `read_page` returns bounded visible text for the active or owned tab and fails stale or restricted targets. | T-18-01 / T-18-04 | Target resolution stays profile-scoped and content output is bounded. | browser + unit | `./out/Default/browser_tests --gtest_filter='*Prometheus*ReadPage*'` | No - Wave 0 | pending |
| PAGE-02 | `get_dom_snapshot` returns refs, selectors, form state, ARIA fields, text snippets, attributes, frame context, and actionability hints. | T-18-02 / T-18-03 | Refs are snapshot-scoped and document-bound; output is truncated with metadata. | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageSnapshot*'` | No - Wave 0 | pending |
| PAGE-03 | `get_page_snapshot` returns compact action-oriented page state with omitted/truncated metadata. | T-18-02 / T-18-03 | Compact output cannot become an unbounded page dump or durable authority. | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageSnapshot*Compact*'` | No - Wave 0 | pending |
| PAGE-04 | `execute_js` requires explicit permission, captures result/error, blocks internal pages, and verifies mutation. | T-18-02 / T-18-04 / T-18-05 | Normal-page JS uses a permissioned renderer seam and avoids privileged WebUI surfaces. | browser + unit | `./out/Default/browser_tests --gtest_filter='*Prometheus*ExecuteJs*'` | No - Wave 0 | pending |
| PAGE-05 | Click, type, key, scroll, hover, select, clear, drag, and drop-file routes work where safe or return typed unsupported denial. | T-18-03 / T-18-06 / T-18-07 | Actions re-resolve targets at time of use and deny unsafe file paths. | browser + unit | `./out/Default/browser_tests --gtest_filter='*Prometheus*PageAction*'` | No - Wave 0 | pending |
| PAGE-06 | Mutating routes wait for load, stability, visible state change, value/focus update, scroll change, or timeout. | T-18-04 / T-18-07 | Waits do not rely on fixed sleeps alone and return explicit timeout status. | browser | `./out/Default/browser_tests --gtest_filter='*Prometheus*PageWait*'` | No - Wave 0 | pending |
| PAGE-07 | Mutating routes return compact change reports and detect repeated or stuck action patterns. | T-18-05 / T-18-07 | Audit and change metadata excludes page text, DOM, scripts, typed text, and file paths. | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageActionHistory*:*PrometheusPageChangeReport*'` | No - Wave 0 | pending |
| PAGE-08 | Same-origin frames work; cross-origin, sandboxed, fenced, detached, prerendered, crashed, and restricted targets fail explicitly. | T-18-02 / T-18-04 | Frame policy never silently falls back to another frame or leaks restricted content. | browser | `./out/Default/browser_tests --gtest_filter='*Prometheus*Frame*'` | No - Wave 0 | pending |

---

## Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-18-01 | Confused deputy across tabs or profiles | Resolve all page routes through Phase 17 session, profile, ownership, and allowlist validation. |
| T-18-02 | Cross-origin or restricted-frame content leak | Use explicit frame policy, APC redaction metadata where available, and typed denial for unsupported targets. |
| T-18-03 | Renderer-controlled selector or ref spoofing | Treat refs/selectors as untrusted; bind refs to snapshot and document identity; re-resolve before action. |
| T-18-04 | TOCTOU navigation or frame swap | Use live RFH checks, document identity, WebContents observation, and time-of-use validation. |
| T-18-05 | Audit or change-report content exfiltration | Keep page text, DOM, scripts, typed text, file paths, and secrets out of audit records and compact change strings. |
| T-18-06 | Arbitrary local file access via drop | Deny file-drop inputs until an explicit safe file policy exists; never read arbitrary local paths from an untrusted route. |
| T-18-07 | Infinite repeated or stuck actions | Track recent session/tab/action fingerprints and return typed repeated/stuck action results. |

---

## Wave 0 Requirements

- [ ] Add `chrome/browser/prometheus/prometheus_page_adapter_unittest.cc` for route parsing, bounds, refs, typed errors, audit-safe change strings, and stuck-action fingerprints.
- [ ] Add `chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc` or equivalent if snapshot compaction is split from adapter logic.
- [ ] Add `chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` or extend `prometheus_agent_service_browsertest.cc` for end-to-end route behavior.
- [ ] Add local fixtures under `chrome/test/data/prometheus/page_adapter/` for visible text, forms, ARIA labels, dynamic DOM, same-origin iframe, cross-origin iframe, sandbox/restricted frame, navigation click, typing, selection, scrolling, hover/focus, drag/drop if implemented, and JS success/error/read-back.
- [ ] Wire new unit-test sources in `chrome/browser/prometheus/BUILD.gn` and browser-test sources in `chrome/browser/ui/views/prometheus/BUILD.gn` unless an existing browser-test file is extended.

---

## Manual-Only Verifications

All Phase 18 behaviors have automated verification requirements. Manual browser inspection is optional for debugging only and cannot replace the automated phase gate.

---

## Validation Sign-Off

- [x] All requirements have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks may land without automated verification.
- [x] Wave 0 covers all missing test files and fixtures.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-07
