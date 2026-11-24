---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 10
subsystem: external-mcp-runtime-adapter
tags: [node, mcp, chromium, stdio, runtime, caller-isolation, built-smoke]

requires:
  - phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
    plan: 07
    provides: Dependency-free external stdio bridge and authenticated browser-issued sessions
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 09
    provides: Closed 27-route native runtime codec, gateway dispatch, isolation, and live health
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 13
    provides: Complete regular-profile runtime/control workflows and current built app
provides:
  - All 31 Phase 20 compatibility names live as 27 canonical native routes and four exact aliases
  - Exact final 90-name inventory of 49 native, 12 alias, 22 typed stub, five later phase, and two removed
  - Recursive metadata-only runtime schemas and pre-normalization LOCAL_UI_REQUIRED provider mutation denial
  - Deterministic loopback provider fixture plus two-client built-browser task, provider, memory, guide, vault, and diagnostic smoke
affects: [20-14, phase-21, phase-22, release-validation, external-mcp-clients]

tech-stack:
  added: []
  patterns:
    - Forward runtime codec commands with params-only envelopes while preserving page-route target/params/visual envelopes
    - Deny external provider mutation before normalization, logging, or native transport
    - Canonicalize disposable macOS smoke paths before native profile classification
    - Bind independent external callers while a regular browser and active tab are known available

key-files:
  created: []
  modified:
    - tools/prometheus-mcp/src/catalog.mjs
    - tools/prometheus-mcp/src/schema.mjs
    - tools/prometheus-mcp/src/tool-handler.mjs
    - tools/prometheus-mcp/test/catalog.test.mjs
    - tools/prometheus-mcp/test/tools.test.mjs
    - tools/prometheus-mcp/test/diagnostics.test.mjs
    - tools/prometheus-mcp/test/errors.test.mjs
    - tools/prometheus-mcp/test/fixture-server.mjs
    - tools/prometheus-mcp/test/smoke-client.mjs
    - tools/prometheus-mcp/test/smoke.test.mjs
    - tools/prometheus-mcp/smoke-browser.sh

key-decisions:
  - "Keep set_provider_config manifest-native for compatibility but return one content-free LOCAL_UI_REQUIRED result before reading raw arguments."
  - "Use params-only bodies for all 27 runtime-codec routes; page-action routes retain the existing target/params/visual body."
  - "Seed built smoke only through the closed native test bootstrap with a canonical disposable path, mode-0600 metadata file, and loopback LM Studio-compatible fixture."
  - "Create both smoke callers while the fresh regular browser is active so task authority is pinned deterministically; isolation is then proved after caller-owned state is created."

patterns-established:
  - "Runtime adapter boundary: aliases canonicalize once, recursive schemas accept only bounded metadata, and the Node bridge owns no execution or secret authority."
  - "Built-smoke boundary: fixture endpoints are loopback-only, exact-path, method-specific, body-bounded, and reject malformed or non-fixture traffic."
  - "Privacy gate: raw prompts, provider secret sentinels, browser credentials, session IDs, and profile paths are denylisted from captured output."

requirements-completed: [FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, FSB-07, FSB-08]

duration: 3h47m
completed: 2026-07-18
---

# Phase 20 Plan 10: External MCP Runtime Promotion Summary

**The external stdio bridge now exposes every Phase 20 runtime capability through the browser-owned native runtime, with closed recursive schemas, caller isolation, local-UI-only provider mutation, and a deterministic two-client built-app smoke.**

## Performance

- **Duration:** 3h47m
- **Started:** 2026-07-18T17:05:13Z
- **Completed:** 2026-07-18T20:51:55Z
- **Tasks:** 3
- **Files modified:** 11 implementation/test files

## Accomplishments

- Promoted the literal 31-name Phase 20 set to 27 canonical native routes plus the exact aliases `submit_task`, `cancel_task`, `task_status`, and `list_runtime_logs`; final manifest counts are exactly 49/12/22/5/2.
- Added closed recursive runtime schemas that reject undeclared, prototype, authority, secret, per-call URL/header, provider-body, and payment-value fields while retaining bounded metadata operations.
- Kept `set_provider_config` native in the manifest but made every external invocation return byte-equivalent `LOCAL_UI_REQUIRED` before argument normalization, stringification, logging, or transport.
- Split runtime forwarding into the native codec's exact `{params}` envelope while preserving the existing page-route `{target,params,visual}` protocol.
- Added deterministic loopback `GET /v1/models` and bounded `POST /v1/responses` fixtures with strict method/path/query/body rejection.
- Extended the real built-browser smoke across two independent clients for provider reads/discovery, task submit/status/list/cancel/logs, memory, guides, vault metadata/confirmation-only use, live diagnostics, alias parity, safe titles, caller isolation, and provider-mutation non-disclosure.
- Made macOS runtime bootstrap deterministic by canonicalizing the temporary root before path construction and explicitly advertising that root through `MAC_CHROMIUM_TMPDIR`.

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Freeze promotion counts, schemas, aliases, mutation denial, and diagnostics** - `52b1b9e83`
2. **Task 2 (GREEN): Promote the catalog and implement recursive closed schemas** - `5e42ec259`
3. **Task 3 (GREEN): Forward runtime commands and prove built-app external smoke** - `ffcb6eec2`

**Plan metadata:** (this commit)

## Files Created/Modified

- `tools/prometheus-mcp/src/catalog.mjs` - Final runtime schemas, 31-name promotion, exact aliases, and exported runtime-route identity.
- `tools/prometheus-mcp/src/schema.mjs` - Recursive object/array/oneOf normalization, bounds, and reserved/secret-field rejection.
- `tools/prometheus-mcp/src/tool-handler.mjs` - Pre-normalization provider mutation denial, live provider/vault diagnostics, and params-only runtime forwarding.
- `tools/prometheus-mcp/test/catalog.test.mjs` - Literal promotion table, exact inventory, schema fixtures, and recursive adversarial cases.
- `tools/prometheus-mcp/test/tools.test.mjs` - Canonical/alias forwarding parity, exact envelopes, isolation, and zero-call provider denial.
- `tools/prometheus-mcp/test/diagnostics.test.mjs` - Exact live Phase 20 and later-phase diagnostic contract.
- `tools/prometheus-mcp/test/errors.test.mjs` - Final five-name Phase 21 later-phase regression.
- `tools/prometheus-mcp/test/fixture-server.mjs` - Strict loopback page, model-discovery, and provider-response fixture.
- `tools/prometheus-mcp/test/smoke-client.mjs` - Two-client built-browser runtime, isolation, privacy, safe-title, and compatibility proof.
- `tools/prometheus-mcp/test/smoke.test.mjs` - Fixture rejection matrix and static bootstrap/shell contract.
- `tools/prometheus-mcp/smoke-browser.sh` - Closed mode-0600 provider bootstrap, canonical disposable profile, exact flags, lifecycle cleanup, and captured-output gate.

## Decisions Made

- Runtime routes are identified from the same catalog schema table and receive only `params`; this avoids duplicating a second route-name list while matching the native codec exactly.
- Provider mutation denial is keyed on the canonical native route, so the compatibility surface stays advertised but no future alias or schema path can accidentally authorize external mutation.
- The smoke provider is created only by the non-official native test bootstrap. Node and shell never mutate provider state, write `prometheus.runtime` preferences, transport a key, or launch a provider engine.
- Both independent clients are created immediately after the primary confirms the fresh active tab. Native read-only operations do not require a pinned browser, but task submission does; early binding makes the authority proof deterministic.
- Provider and vault diagnostics now reflect live browser-owned state. Supervision and extensions remain the only later-phase diagnostic components.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed provider mutation denial during the Task 2 gate**
- **Found during:** Task 2 catalog/schema verification
- **Issue:** The Task 2 tools gate included the new native disposition and could not become green while the old handler still normalized or forwarded `set_provider_config`.
- **Fix:** Added the specified canonical-route early denial before normalization as part of the Task 2 implementation.
- **Files modified:** `tools/prometheus-mcp/src/tool-handler.mjs`
- **Verification:** Normalizer and native call counts remain zero for normal, unknown, and nested secret-bearing input; all denials are byte-equivalent.
- **Committed in:** `5e42ec259`

**2. [Rule 1 - Bug] Corrected the runtime native request envelope**
- **Found during:** Task 3 rebuilt-browser smoke
- **Issue:** The generic page-command body added empty `target` and `visual` objects, which the closed native runtime codec rejects with an HTTP error.
- **Fix:** Exported the canonical runtime route set and forward those routes with exactly `{params: normalizedArguments}`.
- **Files modified:** catalog, handler, and tools regression.
- **Verification:** All 26 externally callable canonical runtime routes assert exact params-only envelopes; focused suite passed 37/37 and live runtime calls succeeded.
- **Committed in:** `ffcb6eec2`

**3. [Rule 3 - Blocking] Updated the stale later-phase error regression**
- **Found during:** Task 3 complete Node gate
- **Issue:** The pre-existing error test still classified promoted `run_task` as a Phase 20 later-phase stub.
- **Fix:** Replaced it with the exact five remaining Phase 21 supervision names.
- **Files modified:** `tools/prometheus-mcp/test/errors.test.mjs`
- **Verification:** Complete Node TAP passed 74/74 with zero failure, skip, or TODO.
- **Committed in:** `ffcb6eec2`

**4. [Rule 1 - Bug] Canonicalized the disposable macOS profile root**
- **Found during:** Task 3 native bootstrap smoke
- **Issue:** Chromium canonicalized the profile to `/private/var/...` while the launcher supplied `/var/...`; the textual parent check returned native bootstrap result `kProfileDenied`.
- **Fix:** Canonicalized `TEMP_ROOT` with `pwd -P` before deriving any paths and set `MAC_CHROMIUM_TMPDIR` to that exact root.
- **Files modified:** `tools/prometheus-mcp/smoke-browser.sh`
- **Verification:** The provider appeared with every exact expected field and the built smoke passed.
- **Committed in:** `ffcb6eec2`

**5. [Rule 1 - Bug] Removed a second-client active-browser binding race**
- **Found during:** Task 3 repeated clean smoke
- **Issue:** The gateway may create a read-capable session with no pinned Browser/tab if active-browser lookup is transiently unavailable; provider reads then pass but task submission returns `CAPABILITY_NOT_READY`.
- **Fix:** Created both independent clients immediately after the primary confirmed the fresh active regular tab, before later runtime/UI activity.
- **Files modified:** `tools/prometheus-mcp/test/smoke-client.mjs`
- **Verification:** Four consecutive early-bind smokes and the final clean non-diagnostic smoke passed.
- **Committed in:** `ffcb6eec2`

---

**Total deviations:** 5 auto-fixed (three bugs, two blocking test/sequence issues). **Impact:** All changes were required for exact native protocol correctness, deterministic browser authority, and full regression coverage; no execution engine, secret surface, or unrelated product feature was added.

## Issues Encountered

- The current component-build aggregate `prometheus_unittests` target compiles all Prometheus sources but fails its final link on unrelated missing Chrome symbols, including `Navigate`, `NavigateParams`, `UpgradeDetector`, `TrackerFactory`, and `FileSelectHelper`. The binary is therefore absent and the plan's exact native list/filter command cannot run in this output graph. The owned native sources compile, `ninja -C out/Default chrome` links the current app, and the real browser bootstrap/runtime path passes the built smoke. This aggregate target dependency defect remains a verification-infrastructure follow-up.
- The installed ripgrep interprets `-E` as an encoding option rather than extended-regex mode. Verification used the equivalent `rg -e` form for the exact TAP count guard.
- Temporary startup diagnostics proved the bootstrap denial enum and were removed before the final rebuild. Eighteen private diagnostic temp roots were then explicitly deleted; they are intentionally not recoverable.

## Verification

- Task 1 RED: 28 selected tests produced exactly the intended 12 contract failures under an explicitly negated command.
- Task 2 GREEN: catalog/tools gate passed 24/24.
- Final focused catalog/tools/diagnostics/smoke gate passed 37/37.
- Complete Node TAP passed 74/74 with exact `# fail 0`, `# skipped 0`, and `# todo 0`.
- The current built app compiled and linked successfully after temporary diagnostics were removed.
- Final clean non-diagnostic `bash tools/prometheus-mcp/smoke-browser.sh` exited 0; four immediately preceding early-bind repetitions also passed.
- Built smoke proved exact mode-0600 closed provider bootstrap, live list/config/discovery, two caller-isolated task flows including all four aliases, safe-title redaction, memory/guide isolation, vault confirmation-only use, live provider/vault diagnostics, zero provider mutation, and sentinel-free captures.
- `bash -n`, `node --check` for every changed module, production no-process/no-engine scans, and `git diff --check -- tools/prometheus-mcp` passed.
- Native aggregate exception: `ninja -C out/Default prometheus_unittests` fails at its pre-test link edge on unrelated unresolved Chrome symbols, so no native filter result is claimed.

## User Setup Required

None. No credential, provider account, real model engine, third-party SDK, external MCP client, or manual browser configuration is required.

## Next Phase Readiness

The complete browser-owned Phase 20 runtime is now available to external MCP clients with exact compatibility counts, closed schemas, native caller isolation, and built-app evidence. Plan 20-14 can consume this surface for final automated integration and release validation.

The product path has no source blocker. Before claiming the aggregate native unit gate in a release report, repair the component-build `prometheus_unittests` target dependencies or provide a maintained focused bootstrap test binary; this plan does not claim that unavailable filter.

## Self-Check: PASSED

- FOUND: all 11 modified implementation/test files
- FOUND: task commits `52b1b9e83`, `5e42ec259`, and `ffcb6eec2`
- VERIFIED: exact 31-name promotion and 49/12/22/5/2 inventory
- VERIFIED: complete 74/74 Node TAP and final built-browser smoke
- VERIFIED: pre-normalization provider denial, params-only runtime forwarding, caller isolation, and sentinel-free captures
- VERIFIED: no temporary diagnostic source or temp root remains
- RECORDED: aggregate native unit link exception without claiming a test result

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-18*

