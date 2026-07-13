---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 04
subsystem: native-tabs-and-element-reads
tags: [chromium, tabs, mojo, renderer, apc, frame-policy, tdd]

requires:
  - phase: 19-02
    provides: Closed native route/result contracts and strict transport codec
  - phase: 19-03
    provides: Profile-keyed sessions and exact tab ownership
provides:
  - Structured stable tab/window metadata with zero-based call-time index resolution
  - Background-first tab opening with explicit foreground activation
  - Closed-enum internal-surface compatibility routing
  - Fresh-APC exact-frame get_text/get_attribute reads over bounded read-only Mojo
affects: [19-05, 19-06, 19-07]

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_element_reader.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_element_reader.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/common/prometheus_render_frame.mojom
    - .context/chromium/src/chrome/renderer/prometheus_action_dispatcher.cc
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.cc

requirements-completed: []
requirements-progressed: [MCP-02, MCP-03, MCP-07]

completed: 2026-07-13
---

# Phase 19 Plan 04: Native Tabs and Exact-Frame Element Reads Summary

**Native compatibility now returns structured stable tab data, opens tabs without stealing focus by default, exposes only the closed Prometheus surface set, and reads element text/attributes through fresh exact-frame browser and renderer policy.**

## Accomplishments

- Replaced legacy `changed_state` tab/window strings with bounded typed metadata containing stable tab handles, window ids, current zero-based indexes, title, URL, active state, and caller-only ownership.
- Resolved index aliases at call time, kept stable handles canonical across reorder, and rejected stable-handle/index conflicts.
- Made `open_tab` background-first while preserving explicit foreground and activation routes; explicit background page operations do not change the active tab.
- Implemented `open_internal_surface` as a closed switch over new tab, side panel, and control panel using existing Prometheus-owned paths, with no generic internal-URL opener.
- Added a dedicated read-only `ReadElement` Mojo contract with conservative 128-byte attribute names, 65,536-byte values, and distinct absent versus present-empty attributes.
- Added `PrometheusPageElementReader`, which fetches fresh APC, resolves one document-scoped ref or exact selector, revalidates the exact live document/frame before Mojo and after callback, and never substitutes another frame or executes caller JavaScript.
- Enforced stale, detached, crashed, cross-origin, sandboxed, fenced, prerendered, non-primary, and non-web denials with empty changed state and content-free audit results.

## Nested Chromium Commits

1. `9b4ac38c37` — `test(19-04): specify structured background tab compatibility`
2. `efa1dde21f` — `feat(19-04): add structured background tab routes`
3. `2c320b88f6` — `test(19-04): specify exact-frame element reads`
4. `6e99d63fce` — `feat(19-04): add exact-frame element read routes`

## Verification

- `autoninja -C out/Default browser_tests prometheus_unittests prometheus_action_dispatcher_unittests` — passed.
- Agent-service and tab-command browser inventory — 15/15 passed serially.
- Renderer parsing, attribute validation, result shaping, absent/empty handling, and value bounds — 7/7 passed.
- Element-read plus Phase 18 frame/background regression inventory — 19/19 passed serially, including 9 new element-read browser cases.
- Nested `git diff --check` — passed; nested worktree clean.

## Deviations

- The standalone renderer unit binary double-initialized Blink when using `content::RenderViewTest`. Pure renderer validation/result helpers now cover the closed input and output limits there, while real DOM lookup, exact-frame association, and Mojo behavior are exercised end-to-end by the browser matrix. Production behavior and required denial coverage are unchanged.
- The browser fixture helper now foregrounds explicitly by default because Plan 19-04 intentionally changed production `open_tab` to background-first; the dedicated background test opts out and proves no activation theft.

## Next Plan Readiness

Plan 19-05 can expose these profile-pinned native routes through the authenticated IPv4-loopback gateway. Structured results remain browser-owned, and the external bridge does not need page-content access, arbitrary JavaScript, an embedded terminal, or a bundled agent runtime.

## Self-Check: PASSED

- FOUND: all four nested commits and the dedicated browser element-reader files.
- VERIFIED: 15 tab/service browser tests, 7 renderer checks, and 19 frame/element/background browser regressions.
- VERIFIED: background-first open, closed internal surfaces, fresh APC, exact live frame, bounded Mojo values, and no fallback content.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-13*
