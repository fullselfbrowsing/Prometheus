# Milestones

## v2.0 Chromium Engine Migration (Active: started 2026-06-17)

**Planned phases:** 14 phases (Phases 11-24)
**Scope:** Preserve v1 Falkon/Prometheus source and product decisions, retire Falkon as the active implementation, check out/build Chromium, and rebuild Prometheus on Chromium-native UI, WebUI, agent-control, MCP, runtime, supervision, extension, validation, and packaging primitives.

**Key objectives:**

- Preserve the Falkon-based v1 source reference as a recoverable bundle and patch series before deleting the active `falkon/` tree.
- Carry forward the Prometheus/FSB product DNA: Prometheus name, Powered by FSB affiliation, DOM/native control thesis, MCP compatibility, supervision, secure vault/provider runtime, memory/site guides, compact chrome, warm themes, PM mark, FSB assets, Poppins/Space Mono, and Font Awesome Free.
- Establish a clean upstream Chromium checkout/build baseline and record the exact revision.
- Rebuild product identity, design system, chrome, WebUI surfaces, native agent service, page adapters, MCP bridge, FSB runtime, supervision, and extension policy on Chromium.
- Complete parity, security, legal, visual, and release validation before calling the migration complete.

**Primary artifacts:**

- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.context/falkon-preservation/falkon-prometheus-v1.bundle`
- `.context/falkon-preservation/patches/`

**Status:** Phase 11 preservation artifacts started; implementation not yet migrated.

---

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
