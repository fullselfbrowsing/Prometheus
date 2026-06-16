# Stack Research

**Domain:** Agent-native desktop browser based on QtWebEngine/Falkon plus FSB automation
**Researched:** 2026-06-16
**Confidence:** MEDIUM

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Qt | 6.4+ minimum from Falkon | Browser UI, widgets, app shell, internal pages | Falkon already depends on Qt 6 and QtWebEngine; keeping this avoids a browser-engine rewrite. |
| QtWebEngine | 6.4+ minimum from Falkon | Chromium-backed page rendering and page scripting | Provides working browser primitives, profiles, tabs, downloads, permissions, and JS execution hooks. |
| CMake | 3.18+ from Falkon | Native build system | Existing Falkon build and packaging are CMake/KDE-based. |
| C++ | Existing Falkon standard | Native browser integration | Needed for QtWebEngine, browser chrome, internal pages, settings, and privileged agent APIs. |
| TypeScript/Node | Node 18+ for FSB MCP; Node 24+ if adopting Lattice | MCP compatibility, local agent services, provider adapters | Existing FSB MCP is TypeScript/Node; Lattice is TypeScript-first if adopted later. |
| WebSocket/stdio MCP | Existing FSB contract | Agent control protocol | Preserves compatibility with current FSB users and MCP clients. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@modelcontextprotocol/sdk` | Existing FSB MCP package uses `^1.29.0` | MCP server implementation | Use for a native/optimized FSB Browser MCP server. |
| `ws` | Existing FSB MCP package uses `^8.19.0` | Local bridge, dashboard sync, PhantomStream relay | Use where local WebSocket transport remains useful. |
| `zod` | Existing FSB MCP package uses `^3.24.0` | Tool input schemas | Preserve MCP schema validation and typed errors. |
| PhantomStream core | Extracted FSB package | DOM-native live mirroring | Use as reference or dependency for dashboard preview and supervision. |
| Lattice | Optional | Provider routing, receipts, policy, agent runtime | Use only if it removes complexity; do not block v1 on it. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `rg` | Rebrand and codebase audits | Falkon has many product-visible strings across C++, CMake, desktop files, icons, docs, and translations. |
| Falkon CMake build | Native validation | First technical milestone should prove local build before broad refactor. |
| FSB MCP smoke tests | Compatibility gate | Use existing tool names/behavior as contract tests for the native browser. |
| License scanners/manual audit | Legal boundary | Rebrand product identity without deleting required GPL/third-party notices. |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| QtWebEngine/Falkon fork | Chromium/Electron | Only if QtWebEngine cannot expose required agent/internal-page control. Electron conflicts with the lightweight goal. |
| Native C++ browser control layer | Content-script-only port of FSB | Content scripts cannot control browser-owned pages, settings, and restricted surfaces. |
| Existing FSB MCP-compatible tool names | New proprietary protocol | Use new protocol internally only if a compatibility adapter preserves current MCP clients. |
| DOM-native PhantomStream | WebRTC/video streaming | Use video only as fallback diagnostics for non-DOM surfaces. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron as the base browser | Heavy and bundles Chromium separately; conflicts with "super lightweight." | QtWebEngine/Falkon bootstrap. |
| Screenshot-first automation | Slower, higher token/bandwidth cost, loses hidden structure. | DOM/native snapshots plus action verification. |
| Raw string-only JS execution without audit | Hard to secure and hard to debug. | Permissioned execute_js with logs, verification, and result normalization. |
| One giant rebrand commit | Easy to break build/package IDs and hard to review. | Phased identity audit and scoped replacements. |

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Falkon source | Qt 6.4+ | Confirmed from local `CMakeLists.txt`; later Qt versions need build verification. |
| FSB MCP server | Node 18.20+ | Existing package metadata requires Node 18.20+. |
| Lattice | Node 24+ | Optional; adopting it raises runtime requirements. |

## Sources

- https://github.com/fullselfbrowsing/FSB - FSB README, extension manifest, MCP README, tool registry.
- https://github.com/fullselfbrowsing/Lattice - Runtime SDK README and project context.
- https://github.com/fullselfbrowsing/PhantomStream - DOM streaming README and architecture.
- https://github.com/fullselfbrowsing/cmd-k - Native app/provider/storage reference.
- https://www.full-selfbrowsing.com - Current FSB brand and positioning.
- Local `falkon/` checkout - Falkon CMake, README, COPYING, source layout.

---
*Stack research for: FSB Browser*
*Researched: 2026-06-16*
