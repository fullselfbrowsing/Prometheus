# Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions are captured in `15-CONTEXT.md`.

**Date:** 2026-07-07
**Phase:** 15-chromium-ui-shell-compact-chrome-and-tab-model
**Mode:** Autonomous smart discuss defaults accepted

---

## Compact Chrome Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Safari-inspired compact mode with separate fallback | Carry forward Phase 7: compact toolbar tabs, active tab as address/search, but Prometheus styling and separate layout preserved. | yes |
| Literal Safari clone | Higher familiarity but conflicts with Prometheus product identity and Chromium platform conventions. | |
| Conventional Chromium only | Lowest risk but fails UX-01 compact chrome requirement. | |

## Toolbar and Entry Points

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse Chromium toolbar/tab-search/side-panel primitives | Keeps command routing, accessibility, focus, and side-panel behavior aligned with Chromium. | yes |
| Build a separate Prometheus top bar | More control, but higher risk of breaking window/frame behavior and duplicating tab search. | |

## Agent and Tab State Affordances

| Option | Description | Selected |
|--------|-------------|----------|
| Compact glyph/status affordances with safe stubs | Preserves Phase 7 agent/supervision visibility without blocking on Phase 17 services. | yes |
| Text-heavy labels in chrome | More explicit but too cluttered for compact chrome. | |
| Hide state until Phase 17 | Easier now but fails UX-04 and makes later integration riskier. | |

## Advanced Tab Management

| Option | Description | Selected |
|--------|-------------|----------|
| Map Prometheus behavior to Chromium `TabStripModel`, groups, commands, and tab search | Preserves native behavior and avoids copying Falkon/Qt implementation. | yes |
| Rebuild v1 tab model from scratch | More direct parity shape but conflicts with Chromium architecture and license boundary. | |

## Verification Priorities

| Option | Description | Selected |
|--------|-------------|----------|
| Automated native UI coverage plus rendered checks across desktop widths | Required for UX-06 and carries forward Phase 7 visual debt into Chromium. | yes |
| Build-only/static checks | Faster but insufficient for compact layout, overlap, and focus behavior. | |

## the agent's Discretion

- Exact pref/feature names, class names, and plan slicing are left to planner
  discretion as long as the context decisions and UX requirements are met.

## Deferred Ideas

- Real side-panel WebUI/runtime content belongs to Phases 16 and 20.
- Authenticated tab ownership and command service state belongs to Phase 17.
- Full supervision/pairing behavior belongs to Phase 21.
