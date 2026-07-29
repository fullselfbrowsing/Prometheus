---
phase: 22-chrome-extension-ecosystem-and-policy
plan: 03
subsystem: browser-agent
tags: [chromium, extensions, webui, mcp, diagnostics, privacy]

requires:
  - phase: 22-01
    provides: Generation-bound extension inventory, regular/Private grant lattice, lifecycle authority, and bounded health types
  - phase: 22-02
    provides: Browser-owned extension surface resolution and policy-gated Agent dispatch
provides:
  - Accessible local Extension policy controls inside Permissions & Agents without replacing chrome://extensions
  - Generation-bound native mutation with fresh identity, active-state, context, and Private eligibility checks
  - Safe-default browser confirmation for Interact increases and immediate downgrade/revocation
  - Live exact-ten external extension health limited to ready, degraded, or unavailable with bounded inventory-free recovery
affects: [22-04-extension-fixtures, 22-05-extension-smoke, 23-extension-security]

tech-stack:
  added: []
  patterns:
    - Renderer mutation carries ordinal, generation, closed grant, and Private intent only
    - Native code re-resolves current extension identity before confirmation and again before mutation
    - External extension diagnostics forward one stable reason and bounded recovery while local inventory remains browser-only

key-files:
  created:
    - .planning/chromium/verify-phase-22-webui.sh
    - .planning/chromium/verify-phase-22-mcp.sh
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_runtime_dialogs.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - tools/prometheus-mcp/src/tool-handler.mjs

key-decisions:
  - "Keep extension lifecycle in chrome://extensions and place only Prometheus Agent grants in the existing local Permissions & Agents section."
  - "Treat renderer ordinals and generations as display references; native code resolves the current full identity and never returns it to JavaScript or MCP."
  - "Require a safe-default browser modal only when effective access increases to Interact; downgrades and revocations remain immediate."
  - "Preserve the ten-component diagnostic order and expose no extension inventory, authority, content, count, or full identity externally."

patterns-established:
  - "Two-pass sensitive mutation: resolve before confirmation, then re-resolve identity, generation, registry activity, profile context, Private eligibility, and current grant before apply."
  - "Live extension health: ready|degraded|unavailable plus a status-bound stable reason and UTF-8 byte-bounded recovery."
  - "Focused verification directly recompiles and links current objects while proving .ninja_log and .ninja_deps remain byte-identical."

requirements-completed: [EXT-01, EXT-02, EXT-03, EXT-06]

duration: 1h 17m
completed: 2026-07-29
---

# Phase 22 Plan 03: Local Extension Policy and Live Health Summary

**Generation-bound local extension grants with safe native Interact confirmation and exact-ten, inventory-free live MCP health**

## Performance

- **Duration:** 1h 17m
- **Started:** 2026-07-29T11:31:18Z
- **Completed:** 2026-07-29T12:48:31Z
- **Tasks:** 4
- **Files modified:** 32 root and nested repository paths

## Accomplishments

- Added the `Extension policy` subsection to the existing Permissions & Agents area with loading, empty, unavailable, enabled/disabled, regular/Private, Store, Manifest, compatibility, stale, and recovery states while preserving exactly nine top-level sections.
- Limited renderer mutation requests to ordinal, generation, one closed grant, and Private intent. Native code resolves the current ID, revalidates registry activity and context, and never exposes installed inventory or full identities to MCP.
- Added a real browser-owned confirmation for Interact increases with `Keep current access` as the focused safe default and Escape/cancel/close preserving the existing grant.
- Replaced the fixed `extensions:not_ready` placeholder with live regular-profile policy health while preserving the exact ordered ten-component document and 48-byte reason/160-byte recovery bounds.
- Updated MCP normalization and smoke assertions to reject reordered, malformed, over-limit, inventory-bearing, authority-bearing, or `extensions:not_ready` payloads without forwarding partial diagnostics.

## Task Commits

Each RED and GREEN task boundary was committed atomically in both repositories:

1. **Task 1: Retain local policy UI, confirmation, privacy, and responsive RED contract**
   - Root: `51a774836`
   - Chromium: `96da6e7720`
2. **Task 2: Implement generation-bound policy UI and safe native mutation**
   - Root: `d64ea1319`
   - Chromium: `a1f4ad2f90`
3. **Task 3: Retain live-health and inventory-privacy RED contract**
   - Root: `dc8c778d6`
   - Chromium: `cba6d36ddd`
4. **Task 4: Publish live bounded extension health**
   - Root: `71d269051`
   - Chromium: `3b738d8ed5`

## Files Created/Modified

- `.planning/chromium/verify-phase-22-webui.sh` - Fresh GRIT/resource, direct compile/link, nonempty test-list, retry-zero, expected-RED, and metadata-preservation gate.
- `.planning/chromium/verify-phase-22-mcp.sh` - Direct native/browser build plus Node discovery, exact RED allowlists, crash/skip/network guards, and metadata-preserving GREEN gate.
- `prometheus_control_panel.html`, `prometheus_webui.js`, and `prometheus_webui.css` - Accessible local policy rows, lifecycle recovery link, closed renderer messages, responsive layout, and exact UI copy/tokens.
- `prometheus_web_ui.{h,cc}` and its browser tests - Bounded snapshot projection, generation-bound request handling, refresh/focus behavior, and native mutation orchestration.
- `prometheus_runtime_dialogs.{h,cc}` - Safe-default Interact confirmation with exact accept/cancel behavior.
- `prometheus_extension_policy_service.{h,cc}` - Fresh ordinal-to-ID resolution and final pre-mutation lifecycle/context/Private checks.
- `prometheus_agent_gateway.{h,cc}` and gateway tests - Live policy-service health projection, closed status mapping, sanitization, exact ordering, and recursive privacy evidence.
- `tool-handler.mjs`, diagnostics tests, and MCP smoke fixtures - Live extension status/reason/recovery forwarding with strict order, shape, byte bounds, and malformed/inventory rejection.
- `patches/0009-*.patch` through `0012-*.patch` - Ordered source-only Chromium RED/GREEN exports.

## Decisions Made

- Keep `chrome://extensions` as Chromium's sole lifecycle manager. Prometheus links there for lifecycle recovery and owns only the explicit Agent access policy.
- Confirm only increases to Interact. A user can always reduce or revoke access immediately, while every Interact acceptance repeats all native authorization checks.
- Keep the full extension ID solely inside browser-owned native resolution. Local UI receives a bounded suffix; MCP health receives no row, name, count, source, permission, manifest, path, content, or authority.
- Accept external extension health only when status and stable reason agree: `ready/extension_policy_ready`, `degraded/extension_system_not_ready`, or `unavailable/extension_policy_unavailable`.

## Deviations from Plan

### Auto-fixed Issues

**1. Registered the extension policy factory in canonical profile startup**

- **Found during:** Task 2 direct WebUI integration
- **Issue:** WebUI could request the keyed service before any feature-specific caller had initialized its factory.
- **Fix:** Registered the factory with the normal profile extra-parts construction path and rebuilt the ABI-sensitive WebUI/profile composition objects.
- **Files modified:** `chrome/browser/profiles/BUILD.gn`, `chrome_browser_main_extra_parts_profiles.cc`, and the focused WebUI verifier.
- **Verification:** The exact 3-test WebUI/dialog cohort passed with fresh resources and unchanged Ninja hashes.
- **Committed in:** `a1f4ad2f90`

**2. Preserved the complete browser response in the MCP focused linker**

- **Found during:** Task 3 RED link validation
- **Issue:** Removing every unrelated test object also omitted transitive Prometheus composition objects from the stale reviewed response, producing link-only undefined symbols.
- **Fix:** Kept the complete reviewed response, directly rebuilt the gateway/unit/browser objects, and appended current extension and supervision objects without invoking Ninja.
- **Files modified:** `.planning/chromium/verify-phase-22-mcp.sh`
- **Verification:** The required RED gate selected two native/browser and two named Node tests and failed only through the retained assertions.
- **Committed in:** `dc8c778d6`

**3. Removed the historical extension deferral from live-smoke assertions**

- **Found during:** Task 4 complete MCP regression
- **Issue:** The reusable smoke-client validator still required `extensions=not_ready`, contradicting the promoted live gateway and Node contract.
- **Fix:** Required the same three live states, stable reason mapping, and 48/160-byte bounds in smoke fixtures and assertions.
- **Files modified:** `smoke-client.mjs`, `smoke.test.mjs`, `tools.test.mjs`, and `protocol-cases.json`.
- **Verification:** All 85 MCP Node tests and the focused 10-test smoke contract passed; an explicit regression now rejects `extensions=not_ready`.
- **Committed in:** `71d269051`

---

**Total deviations:** 3 auto-fixed blocking/integration issues.
**Impact on plan:** Each fix was required to make the planned local policy or live external-health contract executable and verifiable; no lifecycle or authority surface was added.

## Issues Encountered

- The broader historical extension-policy wrapper selects and passes its native/browser cohort but retains an unrelated static expectation about the ordinary page adapter's exact HTTP(S) spelling. Plan 22-03's required WebUI/MCP gates and the direct gateway regressions are independent and pass.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash .planning/chromium/verify-phase-22-webui.sh --focused --expect-failure` retained the intended Task 1 assertion-only RED boundary.
- `bash .planning/chromium/verify-phase-22-webui.sh --focused` passed 3/3 WebUI and actual-dialog browser tests using fresh current resources.
- `bash .planning/chromium/verify-phase-22-mcp.sh --focused --expect-failure` selected 2 native/browser tests and 2 named Node tests and failed only through the Task 3 allowlists.
- `bash .planning/chromium/verify-phase-22-mcp.sh --focused` passed 2/2 native/browser tests and all 5 diagnostics tests with zero skips.
- The expanded gateway health regression passed 7/7, including existing supervision, exact-ten, native endpoint, and pinned-session cases.
- `node --test tools/prometheus-mcp/test/*.test.mjs` passed 85/85; the focused smoke contract passed 10/10.
- `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- All 12 ordered Phase 22 patches matched their nested commit stable patch IDs and replayed from baseline `de937473bd1b5e99aec391ea003545ecd205e367` to the exact nested HEAD tree `10baa53557965987aa03eea7134e97f891da839d`.
- Artifact-isolation, preservation, root/nested `git diff --check`, and clean-worktree checks passed.

## Next Phase Readiness

- Plan 22-04 can exercise deterministic MV3 fixtures against the completed local policy controls, visible-surface router, and live diagnostics without changing their authority contracts.
- Plan 22-05 can use the live-smoke validator directly; it now rejects the historical extension placeholder.
- No Plan 22-03 implementation or verification blockers remain.

## Self-Check: PASSED

- All four root and nested task commits resolve, and patches `0009` through `0012` exist.
- Required RED/GREEN, WebUI/dialog, gateway regression, full Node, smoke, metadata, patch replay, artifact, and preservation evidence passes.
- Both repositories were clean before summary/tracking creation.

---
*Phase: 22-chrome-extension-ecosystem-and-policy*
*Completed: 2026-07-29*
