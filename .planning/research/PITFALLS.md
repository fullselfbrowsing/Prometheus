# Pitfalls Research

**Domain:** Agent-native desktop browser fork
**Researched:** 2026-06-16
**Confidence:** MEDIUM

## Critical Pitfalls

### Pitfall 1: Treating "remove Falkon traces" as license removal

**What goes wrong:**
Required GPL, copyright, and third-party notices are deleted while rebranding product identity.

**Why it happens:**
Product branding work gets mixed with legal metadata cleanup.

**How to avoid:**
Separate user-facing identity from legal attribution. Keep a legal inventory and verify license screens/files still exist.

**Warning signs:**
Bulk replacements touch `COPYING`, source headers, third-party notices, or about/license UI without legal review.

**Phase to address:**
Phase 1 and Phase 2.

---

### Pitfall 2: Porting FSB as an embedded extension

**What goes wrong:**
The browser inherits extension limitations and still cannot control settings, restricted pages, or internal surfaces.

**Why it happens:**
It is faster to copy content scripts than to design native command APIs.

**How to avoid:**
Build a native surface adapter model early. Use page scripts for web content only.

**Warning signs:**
Internal pages are controlled through selectors/clicks instead of typed commands.

**Phase to address:**
Phase 3.

---

### Pitfall 3: Breaking browser build while rebranding

**What goes wrong:**
CMake targets, bundle IDs, plugins, translations, icons, desktop files, and install paths drift.

**Why it happens:**
Falkon names are both product strings and build identifiers.

**How to avoid:**
Create a rebrand inventory, rename by layer, and build after each layer.

**Warning signs:**
One large patch changes `FalkonPrivate`, app IDs, icons, plugin metadata, translations, and docs at once.

**Phase to address:**
Phase 2.

---

### Pitfall 4: Unsafe direct JavaScript execution

**What goes wrong:**
Agents can run arbitrary code without visible permission boundaries, logging, or verification.

**Why it happens:**
`execute_js` is powerful and FSB already prioritizes it for many tasks.

**How to avoid:**
Gate JS execution by target surface and permission, log every call, normalize return values, and require read-back verification after mutations.

**Warning signs:**
JS tools run on internal pages or sensitive pages with no audit trail.

**Phase to address:**
Phase 3 and Phase 4.

---

### Pitfall 5: Losing FSB compatibility while optimizing

**What goes wrong:**
The native browser is technically better but existing FSB MCP clients, skills, and workflows fail.

**Why it happens:**
Native routes are renamed or simplified before compatibility tests exist.

**How to avoid:**
Keep a canonical tool registry and add parity tests for existing FSB tool names, required fields, and typed errors.

**Warning signs:**
New tool names appear without compatibility adapters or migration docs.

**Phase to address:**
Phase 4.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Copy FSB JS modules wholesale | Fast prototype | Confusing extension assumptions and duplicated runtime state | Only behind a temporary adapter with deletion plan. |
| Leave Falkon strings in low-visibility UI | Faster rebrand | Product feels unfinished and audits get harder | Only before the rebrand phase starts. |
| Use screenshots for restricted surfaces | Easy demo | Breaks DOM-first value and creates brittle control | Only as diagnostic fallback. |
| Store provider/vault data in plain settings | Faster config | Security failure | Never. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full-DOM snapshots without budgeting | Slow/heavy pages freeze | Viewport-aware truncation, structural filters, diffs | Large apps like YouTube/docs/dashboards. |
| Sync action execution without wait model | Flaky automation | Wait for load, DOM stability, visible change, and post-action state | Any dynamic SPA. |
| Video preview as default | High bandwidth and stale clicks | PhantomStream-style DOM mirror | Remote dashboard use. |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Running agent JS on browser-owned privileged pages | Browser settings or vault compromise | Native command APIs with permission checks. |
| Sending secrets across MCP/WebSocket | Credential exposure | Resolve vault secrets inside browser process and inject directly. |
| Remote dashboard control without session identity | Cross-session control or stale actions | Pairing, session stamping, stale-message rejection. |
| Multi-agent shared tab access | One agent hijacks another's work | Ownership tokens and typed rejections. |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Hiding agent actions | Users cannot supervise automation | Visible client badge, action glow, logs, and final state. |
| Too much marketing UI in the browser | Browser feels less usable | Dense, utilitarian agent/operator surfaces. |
| Rebrand only the logo | Users still see Falkon in dialogs, defaults, package names | Full product-visible identity audit. |

## "Looks Done But Isn't" Checklist

- [ ] **Rebrand:** Verify app name, bundle ID, desktop/appdata files, icons, default bookmarks, window titles, about/license screens, docs, and package names.
- [ ] **MCP compatibility:** Verify tool names, required fields, typed errors, and read/action queue behavior.
- [ ] **JS execution:** Verify mutation calls are logged and followed by read-back.
- [ ] **Internal page control:** Verify at least settings control works through native commands, not UI scraping.
- [ ] **Multi-agent:** Verify cross-agent tab access rejects with typed errors.
- [ ] **Legal:** Verify license files and appropriate notices remain.

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| License removal during rebrand | Phase 1/2 | Legal inventory and license UI/file check. |
| Extension-port thinking | Phase 3 | Internal-page native command proof. |
| Build breakage during rebrand | Phase 2 | Build after each identity layer. |
| Unsafe JS execution | Phase 3/4 | Permission/logging/verification tests. |
| MCP drift | Phase 4 | FSB tool contract parity tests. |

## Sources

- Local Falkon source and GPL COPYING file.
- FSB MCP docs and tool registry.
- PhantomStream architecture and limitations.
- FSB project history around service-worker eviction, ownership, visual-session contract, and dashboard streaming.

---
*Pitfalls research for: FSB Browser*
*Researched: 2026-06-16*
