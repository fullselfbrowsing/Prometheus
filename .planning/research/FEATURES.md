# Feature Research

**Domain:** Agent-native desktop browser based on FSB
**Researched:** 2026-06-16
**Confidence:** HIGH for FSB parity, MEDIUM for native browser internals

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Normal browser shell | A browser must browse before it can automate. | MEDIUM | Falkon already supplies tabs, navigation, downloads, history, settings, and QtWebEngine. |
| FSB MCP compatibility | Existing agents already know FSB tools. | HIGH | Preserve manual actions, read tools, autopilot, vault, observability, and typed errors. |
| Direct JS execution | User explicitly requested JS on supported and normally unsupported surfaces. | HIGH | Web pages use QtWebEngine scripting; internal pages need native APIs rather than unsafe content injection. |
| DOM/page snapshots | FSB's core advantage is structural page understanding. | HIGH | Include refs, selectors, forms, ARIA, visible text, and hidden/structural cues. |
| Agent tab ownership | Multiple agents need safe concurrency. | HIGH | Carry over FSB ownership, caps, reconnect grace, and typed rejection semantics. |
| Settings/internal-page control | This is the main browser-native advantage over a Chrome extension. | HIGH | Browser-owned pages need command models and automation APIs. |
| FSB-branded UI | The browser should not look like Falkon. | MEDIUM | Dark shell, orange action color, FSB logos, dense control surfaces. |
| License/legal compliance | Forked GPL browser code has obligations. | MEDIUM | Preserve legal notices and source-availability obligations. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Whole-browser agent control | Agents can control browser UI, settings, restricted pages, and web pages. | HIGH | This is the key break from Chrome-extension limits. |
| Native optimized FSB MCP bridge | Lower latency and fewer extension/service-worker failure modes. | HIGH | Keep existing tool contract where possible. |
| PhantomStream supervision | Low-bandwidth, DOM-addressable live preview and remote control. | HIGH | Better fit than screenshots/video for FSB's DOM-first identity. |
| First-class internal command model | Settings/downloads/history/extensions are structured agent surfaces. | HIGH | Must be designed, not scraped from UI text. |
| FSB parity inside a browser | Side panel, control panel, vault, memory, logs, dashboard sync, provider config. | HIGH | Full parity can be phased after the agent core. |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Delete every Falkon/KDE notice | Makes the product look original. | Violates license/attribution obligations and creates legal risk. | Remove product-visible branding; keep required notices. |
| Build a browser engine | Sounds like a full rewrite. | Massive scope and unnecessary for the product goal. | Rebuild product shell/control layers on QtWebEngine. |
| Vision-first control loop | Easy fallback for any surface. | Slower, expensive, less inspectable, loses hidden structure. | DOM/native first; screenshot fallback only. |
| Full FSB parity before first native control | Feels complete on paper. | Delays the unique browser-native value. | Ship agent core first, then rebuild parity surfaces. |

## Feature Dependencies

```text
Falkon build baseline
    -> FSB branding shell
    -> Native agent control layer
        -> MCP compatibility adapter
        -> DOM/page snapshots
        -> Direct JS execution
        -> Internal page command APIs
            -> Settings/downloads/history/extensions control

Native agent control layer
    -> Multi-agent tab ownership
    -> Visual session overlay
    -> Logs/observability
    -> Autopilot

DOM/page snapshots
    -> Action verification
    -> Stuck detection
    -> PhantomStream supervision

Vault/security boundaries
    -> Credential/payment tools
    -> Safe provider config
```

## MVP Definition

### Launch With (v1)

- [ ] Browser builds and runs locally under Prometheus identity, with "Powered by FSB" as the affiliation/tagline.
- [ ] Native MCP server exposes the core FSB manual/read tool contract.
- [ ] Agents can navigate, list/switch/open/close tabs, read pages, get DOM snapshots, execute JS, click, type, scroll, press keys, and verify changes.
- [ ] Agents can control at least one browser-owned settings/internal surface through native structured commands.
- [ ] Multi-agent tab ownership and typed errors are in place.
- [ ] Product-visible Falkon identity is removed from primary app surfaces, while license notices remain intact.

### Add After Validation (v1.x)

- [ ] Autopilot parity, logs, analytics, memory/site guides, vault, provider settings, and visual session polish.
- [ ] PhantomStream dashboard preview and remote-control path.
- [ ] Broader internal surfaces: downloads, history, bookmarks, permissions, extension manager if supported.
- [ ] Packaging and update flow for macOS first, then Linux/Windows.

### Future Consideration (v2+)

- [ ] Lattice-backed provider routing/receipts/policy if it materially simplifies runtime complexity.
- [ ] Hosted pairing or fleet control.
- [ ] Deep extension ecosystem support beyond what QtWebEngine/Falkon exposes.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Buildable FSB-branded browser shell | HIGH | MEDIUM | P1 |
| Core MCP manual/read tools | HIGH | HIGH | P1 |
| Direct JS execution | HIGH | MEDIUM | P1 |
| Internal-page control | HIGH | HIGH | P1 |
| Multi-agent tab ownership | HIGH | HIGH | P1 |
| Full FSB side/control panels | HIGH | HIGH | P2 |
| PhantomStream live supervision | MEDIUM | HIGH | P2 |
| Lattice integration | MEDIUM | MEDIUM | P3 |

## Sources

- FSB README and MCP README for existing feature contract.
- FSB `extension/ai/tool-definitions.js` for tool grouping and action/read split.
- PhantomStream README and architecture for DOM-native mirroring.
- FSB website for positioning and visual identity.
- Local Falkon tree for browser baseline and rebrand scope.

---
*Feature research for: Prometheus*
*Researched: 2026-06-16*
