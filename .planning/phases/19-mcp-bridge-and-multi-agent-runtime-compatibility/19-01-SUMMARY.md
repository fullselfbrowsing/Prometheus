---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 01
subsystem: external-mcp-compatibility
tags: [node, mcp, json-schema, clean-room, tdd]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Closed native route/session/ownership contracts
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    provides: Bounded page read/action routes and typed errors
provides:
  - Frozen literal 46-name and 59-name compatibility inputs with a tested 90-name union
  - One closed catalog mapping every external name to native, alias, typed stub, later phase, or removal
  - Strict schema normalization, numeric coercion, target conflict checks, and visual badge normalization
  - Wave 0 transport, native-client, diagnostics, visual, and compatibility-error fixtures
affects: [19-02, 19-05, 19-06, 19-07, phase-20-runtime, phase-21-supervision]

tech-stack:
  added: [Node 20 built-in test runner]
  patterns:
    - Dependency-free ESM modules with closed data-driven tool definitions
    - Literal clean-room name fixtures that never import preserved GPL/BUSL implementations
    - Named test.todo ownership for behavior that is not implemented yet

key-files:
  created:
    - tools/prometheus-mcp/src/catalog.mjs
    - tools/prometheus-mcp/src/schema.mjs
    - tools/prometheus-mcp/src/errors.mjs
    - tools/prometheus-mcp/test/fixtures/frozen-v1-tools.json
    - tools/prometheus-mcp/test/fixtures/current-fsb-tools.json
    - tools/prometheus-mcp/test/fixtures/protocol-cases.json
  modified:
    - tools/prometheus-mcp/package.json

key-decisions:
  - "Keep clear as the canonical native route and clear_input as its one-way external alias."
  - "Treat tab_id/tabId as positive stable handles and tabIndex as a zero-based mutable index that cannot coexist with a stable-handle spelling."
  - "Normalize a supplied visual client against thirteen presentation labels without using client/reason metadata as authority."

patterns-established:
  - "Every catalog schema is an object with explicit properties, required fields, and additionalProperties:false."
  - "Only declared numeric fields coerce trimmed finite decimal strings; integer and range rules apply after coercion."
  - "Unsupported, deferred, and removed names always produce structured recovery data rather than an empty success."

requirements-completed: []
requirements-progressed: [MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MCP-07]

duration: 7min
completed: 2026-07-12
---

# Phase 19 Plan 01: Clean-Room MCP Compatibility Foundation Summary

**A dependency-free 90-name compatibility catalog now locks native routes, aliases, deferred capabilities, removals, strict argument schemas, visual metadata, and Wave 0 protocol fixtures without importing preserved implementations.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-12T20:45:00-05:00
- **Completed:** 2026-07-12T20:52:00-05:00
- **Tasks:** 3
- **Files modified:** 14 including this summary

## Accomplishments

- Fixture-derived tests prove the preserved 46 names and current 59 names overlap by 15 and form an exact 90-name union.
- `COMPATIBILITY_CATALOG` assigns each union name exactly one truthful disposition, including all eight aliases, 31 Phase 20 owners, five Phase 21 owners, and two removed visual-session tools.
- Strict normalization rejects undeclared properties, invalid bounds, conflicting target spellings, spoofed visual badges, and unsafe internal-surface values before native dispatch.
- Wave 0 now has executable fixture-integrity coverage for both framing modes, MCP lifecycle/results/cancellation, loopback descriptor/auth shape, and the exact ten diagnostic components; 11 implementation-dependent cases remain visibly assigned to Plans 19-05/19-06.

## Task Commits

1. **Task 1: Freeze observable name inputs and RED catalog contract** - `de02db75d` (test)
2. **Task 2: Implement clean-room catalog, schema normalizer, and compatibility errors** - `a4584902c` (feat)
3. **Task 2 correction: Allow zero-based mutable tab indices** - `64c9d9118` (fix)
4. **Task 3: Add Wave 0 protocol/native/diagnostic fixtures** - `76d03933b` (test)
5. **Post-review: Cover finite exact decimal/scientific integer coercion** - `f99f46b54` (test)

**Plan metadata:** (this commit)

## Files Created/Modified

- `tools/prometheus-mcp/package.json` - Private dependency-free Node 20 ESM package and test scripts.
- `tools/prometheus-mcp/src/catalog.mjs` - Sorted 90-name manifest with closed schemas and disposition metadata.
- `tools/prometheus-mcp/src/schema.mjs` - Strict argument validation, declared numeric coercion, target normalization, byte bounds, and badge normalization.
- `tools/prometheus-mcp/src/errors.mjs` - Stable typed compatibility failures for stubs, later phases, and removals.
- `tools/prometheus-mcp/test/catalog.test.mjs` - Literal union, schema, alias, bounds, owner, removal, and unsafe-route gates.
- `tools/prometheus-mcp/test/errors.test.mjs` - Structured compatibility error coverage.
- `tools/prometheus-mcp/test/visual-session.test.mjs` - Optional metadata subsets, thirteen labels, denial, and UTF-8 bounds.
- `tools/prometheus-mcp/test/transport.test.mjs` - Wave 0 framing/lifecycle fixture checks and Plan 19-06 TODOs.
- `tools/prometheus-mcp/test/native-client.test.mjs` - Loopback descriptor/auth checks and Plan 19-05/19-06 TODOs.
- `tools/prometheus-mcp/test/diagnostics.test.mjs` - Exact ten-key/status and content-denylist checks.

## Decisions Made

- Used only concise observable names/counts and new Prometheus-authored schemas; tests do not load or execute preserved GPL/BUSL implementations.
- Kept optional visual fields independent. Supplied client labels normalize for presentation; omitted labels can use the generic `External Client` display without inserting missing metadata into a native request.
- Kept `activate_tab` internal-only: `switch_tab` targets it without adding a 91st external catalog entry.
- Kept all unimplemented transport/native behaviors as named TODOs with an exact owner plan rather than introducing fake clients or empty-success mocks.

## Deviations from Plan

### Auto-fixed Issues

**1. Mutable tab indices are zero-based**

- **Found during:** Parent review after Task 2 GREEN
- **Issue:** The first schema used the positive stable-handle bound for `tabIndex`, incorrectly rejecting the first tab at index 0.
- **Fix:** Split the schemas: `tab_id`/`tabId` remain 1..2147483647 while `tabIndex` accepts 0..2147483647; stable and mutable spellings cannot coexist.
- **Verification:** Catalog regression accepts string `"0"`, rejects `-1`, and all focused tests pass.
- **Committed in:** `64c9d9118`

**2. Numeric compatibility accepts exact integer values in decimal notation**

- **Found during:** Cross-language codec review after Plan 19-02.
- **Issue:** Node already accepted finite decimal/scientific strings whose value is an exact integer, but the parity case was not explicit in the catalog tests.
- **Fix:** Added coverage for `"42.0"` and `"1e2"`; the native codec received matching coverage and behavior.
- **Verification:** Focused Node tests pass 14/14; native route/transport/audit tests pass 37/37.
- **Committed in:** `f99f46b54` (Node) and nested `bd9e23b20e` (C++).

---

**Total deviations:** 2 auto-fixed compatibility issues.  
**Impact on plan:** Both corrections align Node and native normalization with the locked compatibility contract and add no scope.

## Issues Encountered

The first RED shell wrapper used zsh's reserved `status` variable after the expected missing-module failure. The RED run itself was correct; rerunning with `red_exit` confirmed exit 1 from `ERR_MODULE_NOT_FOUND` before the Task 1 commit.

## Verification

- `node --test tools/prometheus-mcp/test/*.test.mjs` — 31 tests, 20 passed, 11 named TODO, 0 failed/skipped.
- Focused catalog/schema/error/visual run — 14 passed, 0 failed/TODO/skipped.
- Fixture counts — 46 frozen, 59 current, 15 overlap, 90 union.
- Package dependency inspection — zero runtime and development dependencies.
- Embedded-runtime static scan — no child process, agent CLI, terminal, engine selector, or CLAUDE.md production references.
- `git diff --check -- tools/prometheus-mcp` — passed.

## User Setup Required

None. The adapter transport and executable are intentionally not implemented until Plans 19-05/19-06.

## Next Phase Readiness

Plans 19-02 through 19-06 can consume one stable catalog/schema/error vocabulary. The remaining 11 TODOs are explicit Wave 0 owners, not completion claims. Plan 19-07 must remove all TODOs only after the secure native gateway and stdio bridge are real.

## Self-Check: PASSED

- FOUND: all 13 production/test/package files under `tools/prometheus-mcp/`
- FOUND: commits `de02db75d`, `a4584902c`, `64c9d9118`, `76d03933b`, and `f99f46b54`
- VERIFIED: exact 90-name catalog, zero unmapped names, zero test failures

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*  
*Completed: 2026-07-12*
