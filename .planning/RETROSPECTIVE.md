# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-06-17
**Phases:** 10 | **Plans:** 51 | **Sessions:** not tracked precisely (~2 calendar days, 2026-06-16 → 2026-06-17)

### What Was Built
- A rebranded, legally-inventoried Falkon/QtWebEngine fork ("Prometheus", Powered by FSB) with preserved GPL/Qt/KDE notices.
- A native agent control spine (command router, surface adapters, permissioned JS execution, DOM/page reads) and an FSB-compatible MCP bridge with multi-agent ownership, typed errors, and visual-session fields.
- Native FSB runtime surfaces (side panel, providers, autopilot, logs, memory/site guides, secure vault), PhantomStream-style supervision, safe pairing, and a local macOS validation package.
- Compact Safari-style chrome with advanced tab management, a native FSB-Plus control center with a release-gated parity matrix, an offline icon/font/theme system, and a Prometheus start page.

### What Worked
- The GSD phase pipeline (discuss → plan → execute → verify → code review → UI audit) drove 51 plans across 10 phases with consistent atomic commits.
- Tracking the heavy upstream browser code as a separate `falkon/` checkout kept the GPL codebase out of the planning repo while GSD tracked plans and summaries cleanly.
- Static verification gates (177/177 build-link check, parity gate, code review) caught most issues without needing a live build.

### What Was Inefficient
- Requirements traceability drifted: phases 8-10 were inserted mid-milestone, but their requirement statuses stayed "Planned" and checkboxes were left inconsistent — all 20 had to be reconciled at milestone close.
- 26 verification items could only be confirmed by a human running the binary; they accumulated unverified across phases 08/09/10 and shipped as deferred items rather than being cleared, so v1.0 closed without an end-to-end human run.
- Milestone-close auto-extraction pulled garbage "accomplishments" from SUMMARY.md files ("Status:", code-review fragments) and had to be rewritten by hand.
- Scope grew: phases 7-10 were added after the original six-phase release-hardening milestone, expanding v1.0 well beyond its initial definition.

### Patterns Established
- Maintain a release-gated FSB feature parity matrix as the definition of "done" for parity categories.
- Offline-bundle all UI assets (icons, fonts) in Qt resources with attribution, and gate releases on their presence.
- Mark verification items that genuinely require a human/binary as `human_needed` so they don't block code-complete but stay tracked as deferred.

### Key Lessons
1. Update requirement traceability statuses when a phase completes, not at milestone close — mid-milestone phase insertions otherwise leave the table inconsistent.
2. For UI-heavy work that can't be grep-verified, schedule a dedicated human-visual verification pass before declaring the milestone shippable, or explicitly accept and defer the gap (as done here).
3. Auto-extracted milestone accomplishments are unreliable across heterogeneous SUMMARY.md formats — always curate them.

### Cost Observations
- Model profile: `balanced` (per `.planning/config.json`); exact model mix not tracked.
- Velocity (from STATE.md metrics): ~7 min average per plan; heavy parallelization across waves.
- Notable: code-complete reached fast, but human-visual verification debt was traded off to get there.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | n/a | 10 | Established the GSD pipeline; scope grew from 6 to 10 phases mid-milestone |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | static + Qt focused tests | n/a | offline icon/font assets bundled (no new network deps) |

### Top Lessons (Verified Across Milestones)

1. Keep requirement traceability current per-phase; reconciling at close is error-prone.
2. UI verification that needs a human must be scheduled deliberately, not deferred indefinitely.
