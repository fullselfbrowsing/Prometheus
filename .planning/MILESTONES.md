# Milestones

## v1.0 MVP (Shipped: 2026-06-17)

**Phases completed:** 10 phases, 51 plans, 42 tasks
**Timeline:** 2026-06-16 → 2026-06-17 (~2 days, 70 planning-repo commits)

**Delivered:** An agent-native, FSB-powered desktop browser built on a rebranded Falkon/QtWebEngine fork — native agent control, MCP compatibility, FSB runtime parity, supervision, compact chrome, offline theming, and a start page — as a statically-verified local macOS validation build.

**Key accomplishments:**

- Built and legally inventoried a Falkon/QtWebEngine fork baseline, then rebranded all product-visible surfaces to Prometheus ("Powered by FSB") while preserving GPL/Qt/KDE legal notices (Phases 1-2).
- Shipped a native agent control spine: command router, surface adapters, permissioned JavaScript execution, and DOM/page reads across web and browser-owned surfaces (Phase 3).
- Restored FSB-compatible MCP control with browser-owned agent identity, tab ownership, concurrency caps, typed recovery errors, and implicit visual-session fields (Phase 4).
- Rebuilt FSB runtime surfaces natively — agent side panel, multi-provider configuration, autopilot, logs/diagnostics, memory/site guides, and a secure vault — plus PhantomStream-style supervision, safe pairing, and a validated local macOS release package (Phases 5-6).
- Added compact Safari-style chrome with advanced tab management (groups, overview/search, quick switch, unload/restore) and a native FSB-Plus control center backed by a release-gated feature parity matrix (Phases 7-8).
- Delivered an offline Font Awesome Free icon system with Poppins/Space Mono brand fonts, warm dark/light themes, a real PM brand mark, and a Prometheus start page with omnibox/Ask FSB handoff, favorites, and suggested automations (Phases 9-10).

**Known deferred items at close:** 3 verification files (26 human-visual UAT items across phases 08/09/10) carried forward to the next milestone — see STATE.md Deferred Items. The internal Falkon → Prometheus symbol rename and a notarized public macOS release also remain deferred.

---
