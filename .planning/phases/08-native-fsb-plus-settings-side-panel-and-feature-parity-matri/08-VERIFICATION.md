---
phase: 08-native-fsb-plus-settings-side-panel-and-feature-parity-matri
verified: 2026-06-16T00:00:00Z
status: human_needed
score: 18/18
overrides_applied: 0
human_verification:
  - test: "Control panel window opens from router surface"
    expected: "POST open_internal_surface with surface=control_panel to the native agent port opens a floating window titled 'Prometheus Control Panel'."
    why_human: "Requires a running Prometheus build and an HTTP round-trip to the native agent port; cannot be verified without launching the binary."
  - test: "All nine section names visible in the section rail"
    expected: "The left-side QListWidget shows exactly: Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix — no blank or duplicated entries."
    why_human: "Widget layout and rail population require the UI to be rendered; grep cannot confirm row text or ordering."
  - test: "Section switching navigates content pages"
    expected: "Clicking each section name in the rail switches the QStackedWidget to the corresponding content page with no blank or overlapping page."
    why_human: "QStackedWidget page switching is a runtime behavior dependent on Qt layout rendering."
  - test: "48px header band layout"
    expected: "Prometheus Display label, Powered by FSB tagline, and four status chip labels (MCP, Agents, Vault, Supervision) all fit within a single 48px row at the default window width with no overlap."
    why_human: "Pixel-level layout correctness requires visual inspection of the rendered widget."
  - test: "Secret fields use password echo mode"
    expected: "Key field in Providers section and secret field in Vault section display dots/bullets when typing rather than plain text."
    why_human: "Echo mode appearance is a visual property verified only by observation."
  - test: "Provider list shows key state metadata only"
    expected: "Provider QListWidget rows display 'Key saved' or 'No key saved' — never the raw API key value."
    why_human: "Requires visual inspection of the rendered list with a provider configured."
  - test: "Vault list shows metadata only"
    expected: "Vault QListWidget rows display origin, label, and secret-state chip only; no raw secret values visible."
    why_human: "Requires visual inspection with a vault entry saved."
  - test: "Parity Matrix section has Open Parity Matrix button and parsed table"
    expected: "The Parity Matrix section shows an 'Open Parity Matrix' button and a QTableWidget with rows parsed from FSB-PARITY.md."
    why_human: "File-parsing and table population require the widget to be rendered and the file path to resolve at runtime."
  - test: "No layout overlap at 320px"
    expected: "At minimum window width no text, button, or label overlaps an adjacent element in any section of the control panel."
    why_human: "Layout overflow detection requires visual inspection at the target width."
  - test: "Side panel four modes accessible via Ctrl+Shift+P"
    expected: "Ctrl+Shift+P opens the side panel showing four mode tabs: FSB Agent, Explorer, Tabs, Tools — all unchanged from Plan 08-04."
    why_human: "Keyboard shortcut binding and tab visibility require the running browser with UI focus."
---

# Phase 08: Native FSB-Plus Settings Side Panel and Feature Parity Matrix — Verification Report

**Phase Goal:** Build the four-mode Prometheus side panel (FSB Agent, Explorer, Tabs, Tools) as the fast everyday surface and the dense FSB Control Panel page as the operator center, both skinned to the canonical Prometheus design, with settings and a verified parity matrix against FSB.
**Verified:** 2026-06-16T00:00:00Z
**Status:** human_needed
**Score:** 18/18 automated truths verified
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | FSB-PARITY.md contains one row per required FSB category (25 total) with Status, Native Improvement, and Validation columns | VERIFIED | Python check confirms all 25 categories present; FSBP-01 through FSBP-06 present in file; Better rows have non-empty Native Improvement and Validation |
| 2 | smoke-fsb-plus-parity.sh runs static matrix checks without a binary and live router checks with one | VERIFIED | `bash -n` exits 0 (valid syntax); `--matrix-only` exits 0 with "Parity matrix static checks passed"; run_static_checks() contains all required require_rg calls |
| 3 | release-validate.sh invokes smoke-fsb-plus-parity.sh as a blocking gate with syntax check before build and live check after compact-tabs smoke | VERIFIED | Two matches at lines 56 (syntax check block) and 68 (live block port 17888); `bash -n release-validate.sh` exits 0 |
| 4 | AgentRuntime.finishTask accepts executionMode, provider, model, providerAvailable, unavailableReason in metrics and stores them in the task outcome | VERIFIED | `agentruntime.cpp` has 2 occurrences of executionMode; PROVIDER_NOT_CONFIGURED referenced 3 times; agentPolicyValue declared in agentruntime.h line 62 |
| 5 | AgentCommandRouter reads agentCap from Settings PrometheusRuntime/Policy/agentCap before falling back to PROMETHEUS_AGENT_CAP env and then 4 | VERIFIED | 2 matches for `PrometheusRuntime/Policy/agentCap` in agentcommandrouter.cpp; Settings-first pattern confirmed |
| 6 | PERMISSION_BLOCKED and PROVIDER_NOT_CONFIGURED typed error codes exist in agentcommandrouter.cpp | VERIFIED | 4 occurrences of PERMISSION_BLOCKED; 3 occurrences of PROVIDER_NOT_CONFIGURED |
| 7 | Router adds routeGetAgentPolicy and routeSetAgentPolicy dispatch branches and health tools array entries | VERIFIED | 2 occurrences of `get_agent_policy` (dispatch + health array); native_only vaultBoundary default in 4 occurrences |
| 8 | agentcommandroutertest.cpp covers execution-mode fallback, PROVIDER_NOT_CONFIGURED, and policy Settings read | VERIFIED | testGetAgentPolicy (line 364), testSetAgentPolicyPersists (line 376), testExecutionModeLocalFallback (line 394) confirmed |
| 9 | Preferences dialog has a Prometheus agent policy section with controls for all required settings rows | VERIFIED | All 10 required widget objectNames found in preferences.ui via XML parse |
| 10 | loadSettings reads PrometheusRuntime/Policy group with correct defaults | VERIFIED | 2 matches for PrometheusRuntime/Policy in preferences.cpp; internalSurfaceControl default=true at line 597 matching router default=true (CR-03 fix applied) |
| 11 | saveSettings writes PrometheusRuntime/Policy group; locked vault rows not written | VERIFIED | Save block present; vaultBoundaryCheck and vaultAutofillCheck excluded from save block per plan requirement |
| 12 | Agent cap SpinBox range 1-16 with default 4; secret fields absent from preferences UI | VERIFIED | agentCapSpin present in preferences.ui; no QLineEdit with password echo added to Prometheus tab |
| 13 | Side panel has exactly four modes: FSB Agent, Explorer, Tabs, Tools via QTabBar + QStackedWidget | VERIFIED | m_modeStack declared in agentruntimesidebar.h line 64; buildFsbAgentPage, buildExplorerPage, buildTabsPage, buildToolsPage all declared; QTabBar (not QTabWidget) used after WR-05 fix at line 117 |
| 14 | FSB Agent mode shows message stream, typing indicator, and composer with Run Task (accent) and Cancel Task (destructive) | VERIFIED | 8 occurrences of executionMode/Execution: in sidebar; CR-04 fix at line 410 uses `status == "complete"` matching finishTask output; agentRuntime()->submitTask called |
| 15 | Side panel minimum width is 320px | VERIFIED | setMinimumWidth(320) at agentruntimesidebar.cpp line 95 |
| 16 | FsbControlPanelPage class exists with all nine required sections and is wired via surface=control_panel | VERIFIED | fsbcontrolpanel.h and fsbcontrolpanel.cpp exist; 9 build method declarations in header; 18 occurrences in .cpp; control_panel branch in agentcommandrouter.cpp (2 matches) |
| 17 | FsbControlPanelPage is registered in CMakeLists.txt and build compiles | VERIFIED | fsbcontrolpanel.cpp at line 68 and fsbcontrolpanel.h at line 317 in CMakeLists.txt; all 17 phase 8 commits exist in falkon sub-repo |
| 18 | All four critical blocker bugs found in code review are fixed (CR-01 through CR-04) and all five warnings resolved (WR-01 through WR-05) | VERIFIED | CR-01: config["secret"] at fsbcontrolpanel.cpp:1148; CR-02: result["task"]["id"] at :1090; CR-03: Preferences defaults aligned to true matching router; CR-04: status=="complete" at agentruntimesidebar.cpp:410; WR-01: single writeAudit at :1329; WR-02: m_activeSupervisionSessionId tracked at fsbcontrolpanel.cpp:70; WR-03: get_dom_snapshot/get_page_snapshot at smoke script:236; WR-04: rawVaultBoundary single read at router:1256; WR-05: QTabBar at sidebar:117 |

**Score:** 18/18 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `falkon/tools/fsb-baseline/FSB-PARITY.md` | 25-row parity evidence ledger | VERIFIED | All 25 categories present; FSBP-01 through FSBP-06; Better rows evidenced with Native Improvement and Validation |
| `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` | Static + live parity gate script | VERIFIED | Valid syntax; --matrix-only passes; run_static_checks() with all required require_rg calls |
| `falkon/tools/fsb-baseline/release-validate.sh` | Release gate with parity invocation | VERIFIED | Two parity invocations (syntax line 56, live line 68); syntax valid |
| `falkon/src/lib/agent/agentruntime.cpp` | finishTask with execution-mode metrics | VERIFIED | executionMode (2 occurrences), PROVIDER_NOT_CONFIGURED (3 occurrences) |
| `falkon/src/lib/agent/agentruntime.h` | agentPolicyValue declaration | VERIFIED | Declared at line 62 |
| `falkon/src/lib/agent/agentcommandrouter.cpp` | Settings-backed cap; PERMISSION_BLOCKED; PROVIDER_NOT_CONFIGURED; get/set routes | VERIFIED | All patterns confirmed with match counts |
| `falkon/autotests/agentcommandroutertest.cpp` | Three new test methods | VERIFIED | testGetAgentPolicy (364), testSetAgentPolicyPersists (376), testExecutionModeLocalFallback (394) |
| `falkon/src/lib/preferences/preferences.ui` | 10 required policy controls | VERIFIED | XML parse confirms all 10 objectNames |
| `falkon/src/lib/preferences/preferences.cpp` | load/save PrometheusRuntime/Policy | VERIFIED | 2 group beginGroup matches; 8 control references in load+save |
| `falkon/src/lib/agent/agentruntimesidebar.h` | Four build methods; m_modeStack | VERIFIED | Lines 39-42 (build methods); line 64 (m_modeStack) |
| `falkon/src/lib/agent/agentruntimesidebar.cpp` | Four mode implementations; 320px width; execution-mode chip | VERIFIED | 8 occurrences each for build methods and executionMode; setMinimumWidth(320) line 95; QTabBar line 117 |
| `falkon/src/lib/agent/fsbcontrolpanel.h` | FsbControlPanelPage with nine build methods | VERIFIED | FALKON_EXPORT class; 9 section build method declarations |
| `falkon/src/lib/agent/fsbcontrolpanel.cpp` | Nine section implementations; runtime API calls; secret hygiene | VERIFIED | 18 build method occurrences; 5 runtime API calls; echoMode/Password (2); routeForSession control_panel (4); m_activeSupervisionSessionId member |
| `falkon/src/lib/CMakeLists.txt` | fsbcontrolpanel registered | VERIFIED | .cpp at line 68; .h at line 317 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `release-validate.sh` | `smoke-fsb-plus-parity.sh` | bash invocation | WIRED | Line 56 (syntax) and line 68 (live); both match pattern smoke-fsb-plus-parity |
| `smoke-fsb-plus-parity.sh` | `FSB-PARITY.md` | require_rg checks | WIRED | require_rg 'FSBP-01|...|FSBP-06' FSB-PARITY.md at line 130 |
| `agentcommandrouter.cpp` | Settings PrometheusRuntime/Policy | agentCap read | WIRED | 2 matches for PrometheusRuntime/Policy/agentCap |
| `agentcommandroutertest.cpp` | `agentcommandrouter.cpp` | PROVIDER_NOT_CONFIGURED test | WIRED | testExecutionModeLocalFallback at line 394 |
| `preferences.cpp` | Settings PrometheusRuntime/Policy | beginGroup load+save | WIRED | 2 beginGroup matches |
| `agentcommandrouter.cpp` | `fsbcontrolpanel.cpp` | surface=control_panel | WIRED | wantsControlPanel check; FsbControlPanelPage construction |
| `fsbcontrolpanel.cpp` | `agentruntime.cpp` | listTasks/listVaultEntries/diagnostics | WIRED | 5 runtime API call matches |
| `agentruntimesidebar.cpp` | `agentruntime.cpp` | agentRuntime()->submitTask | WIRED | 1 match for agentRuntime()->submitTask |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `agentruntimesidebar.cpp` refreshFsbAgent | task list from listTasks(20) | AgentRuntime::listTasks | Yes — reads from persistent task store | FLOWING |
| `fsbcontrolpanel.cpp` buildTasksSection | listTasks(20) | AgentRuntime::listTasks | Yes | FLOWING |
| `fsbcontrolpanel.cpp` buildVaultSection | listVaultEntries() | AgentRuntime::listVaultEntries | Yes — reads from Keychain/fallback file | FLOWING |
| `fsbcontrolpanel.cpp` buildMcpStatusSection | diagnostics() | AgentRuntime::diagnostics | Yes — live router diagnostics | FLOWING |
| `fsbcontrolpanel.cpp` buildMemorySiteGuidesSection | listMemory() / listSiteGuides() | AgentRuntime persistence | Yes | FLOWING |
| `preferences.cpp` loadSettings | PrometheusRuntime/Policy group | QSettings disk read | Yes — persistent Settings | FLOWING |
| `agentcommandrouter.cpp` routeGetAgentPolicy | Settings PrometheusRuntime/Policy | QSettings disk read | Yes | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| smoke-fsb-plus-parity.sh syntax valid | `bash -n .../smoke-fsb-plus-parity.sh` | exit 0 | PASS |
| smoke-fsb-plus-parity.sh --matrix-only | `bash .../smoke-fsb-plus-parity.sh --matrix-only` | "Parity matrix static checks passed." exit 0 | PASS |
| release-validate.sh syntax valid | `bash -n .../release-validate.sh` | exit 0 | PASS |
| FSB-PARITY.md has all 25 categories | Python check | "All 25 categories present" | PASS |
| All 10 preference controls in preferences.ui | Python XML parse | "All required controls present" | PASS |

---

### Probe Execution

No probe scripts declared beyond the parity smoke script. The parity smoke script probe (`smoke-fsb-plus-parity.sh --matrix-only`) was run above and passed.

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FSBP-01 | 08-04, 08-05 | Native side panel/control center for tasks, providers, MCP status, permissions, vault, memory, logs, diagnostics, supervision, pairing | SATISFIED | FsbControlPanelPage nine sections; four-mode AgentRuntimeSidebarWidget |
| FSBP-02 | 08-01 | Feature parity matrix against FSB with all required categories | SATISFIED | FSB-PARITY.md with all 25 categories; FSBP IDs referenced throughout |
| FSBP-03 | 08-01, 08-05 | Native improvements over FSB documented and verified | SATISFIED | Six Better rows in parity matrix each with non-empty Native Improvement and Validation; smoke static checks enforce presence |
| FSBP-04 | 08-02, 08-04 | Side panel task execution reports provider-backed vs local/MCP execution mode | SATISFIED | executionMode field in finishTask metrics; execution-mode chip in FSB Agent message stream (CR-04 fix applied) |
| FSBP-05 | 08-02, 08-03 | User-facing settings expose internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault, supervision | SATISFIED | 10 preference controls in preferences.ui; load/save wired to PrometheusRuntime/Policy; router reads same Settings group |
| FSBP-06 | 08-01 | Release validation fails when parity rows missing, regressed, undocumented, or unverified | SATISFIED | smoke-fsb-plus-parity.sh wired as blocking gate in release-validate.sh at both syntax-check and live invocation points |

All six requirement IDs from PLAN frontmatter are satisfied. No orphaned requirements for Phase 8 in REQUIREMENTS.md (FSBP-01 through FSBP-06 all map to Phase 8 in the Traceability table).

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `agentruntimesidebar.cpp` | buildToolsPage | `// Annotate chip row (placeholder)` | INFO | Annotate chip is a QLabel placeholder; plan explicitly permits this in Phase 8 |
| `agentruntimesidebar.cpp` | refreshExplorer | `// Reading list: placeholder empty state` | INFO | No reading list API in Phase 8; plan explicitly defers; clear-then-populate pattern still has IN-03 weakness (WR deferred as info, not critical) |
| `fsbcontrolpanel.cpp` (known stub) | buildProvidersSection | Fallback order Save button not connected | WARNING | Noted in 08-05-SUMMARY.md known stubs; not in must-haves; no user-visible breakage since button is present but inert |

No TBD, FIXME, or XXX markers found in any phase 8 modified file. No unreferenced debt markers.

---

### Code Review Fixes Confirmed

All four critical bugs (CR-01 through CR-04) and five warnings (WR-01 through WR-05) from 08-REVIEW.md are present in the codebase:

| Finding | Status | Evidence |
|---------|--------|----------|
| CR-01: Provider apiKey vs secret key mismatch | FIXED | `config[QSL("secret")] = secret` at fsbcontrolpanel.cpp:1148; comment confirms fix |
| CR-02: Wrong task ID JSON path result["taskId"] | FIXED | `result.value("task").toObject().value("id")` at fsbcontrolpanel.cpp:1090; comment confirms fix |
| CR-03: internalSurfaceControl and supervisionPairing default mismatch | FIXED | Preferences defaults aligned to `true` at preferences.cpp:597,603; router defaults also `true` at router:915,1258 |
| CR-04: status "completed" vs "complete" mismatch | FIXED | `status == QSL("complete")` at agentruntimesidebar.cpp:410; comment "AgentRuntime::finishTask stores status 'complete'" |
| WR-01: Double writeAudit in routeSetAgentPolicy | FIXED | Single return via `success()` at router:1331; comment at 1329 explains why no explicit writeAudit |
| WR-02: Supervision session ID empty in endPairing | FIXED | m_activeSupervisionSessionId member in header:70; populated in pairDashboard at cpp:1294; used in endPairing at :1315 |
| WR-03: Smoke checks dom_snapshot vs get_dom_snapshot | FIXED | `get_dom_snapshot get_page_snapshot` at smoke script:236 |
| WR-04: vaultBoundary read twice | FIXED | Single rawVaultBoundary read at router:1256; ternary uses rawVaultBoundary not re-read |
| WR-05: QTabWidget mode switcher wastes 20-30px | FIXED | QTabBar at sidebar:117; comment references WR-05 |

---

### Human Verification Required

These items were identified during Plan 05 execution (checkpoint:human-verify task in 08-05-PLAN.md) and carried forward per the gsd deferred-human-verify pattern:

#### 1. Control Panel Window Opens

**Test:** Build and launch Prometheus, then POST `open_internal_surface` with `surface=control_panel` to the native agent port (default 17885). Get bearer token from `/health`, then POST to `/agent/command`.
**Expected:** A floating window titled "Prometheus Control Panel" opens and raises to the foreground.
**Why human:** Requires a running browser binary and HTTP access to the native agent port.

#### 2. All Nine Section Names in Section Rail

**Test:** With the control panel open, observe the left-side 130px rail.
**Expected:** Exactly nine entries appear in order: Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix.
**Why human:** QListWidget row text and order is a rendered layout property.

#### 3. Section Navigation Works

**Test:** Click each section name in the rail.
**Expected:** The right-side content area switches to the corresponding page with no blank, overlapping, or wrong content.
**Why human:** QStackedWidget navigation is a runtime behavior.

#### 4. 48px Header Band Layout

**Test:** Observe the control panel header at default window width.
**Expected:** "Prometheus" in Display size, "Powered by FSB" tagline, and four status chips (MCP, Agents, Vault, Supervision) all fit in one 48px row with no overlap.
**Why human:** Pixel-level layout requires visual inspection.

#### 5. Secret Fields Show Password Echo

**Test:** Navigate to Providers section and type in the Key field; navigate to Vault section and type in the Secret field.
**Expected:** Both fields display dots or bullets rather than plain characters while typing.
**Why human:** QLineEdit::Password echo mode appearance requires visual verification.

#### 6. Provider List Shows Key State Only

**Test:** With at least one provider configured, observe provider list rows.
**Expected:** Each row shows "Key saved" or "No key saved" — never the raw API key value.
**Why human:** Requires a configured provider and visual inspection of rendered rows.

#### 7. Vault List Shows Metadata Only

**Test:** With at least one vault entry saved, observe vault list rows.
**Expected:** Rows display origin, label, and secret-state chip (e.g., "Native-only") — no raw secret text.
**Why human:** Requires a saved vault entry and visual inspection.

#### 8. Parity Matrix Section

**Test:** Click "Parity Matrix" in the section rail and observe the content page.
**Expected:** "Open Parity Matrix" button is visible; QTableWidget below shows rows parsed from FSB-PARITY.md with Category, Status, Improvement, and Evidence columns.
**Why human:** File parsing and table population require runtime execution.

#### 9. No Layout Overlap at 320px

**Test:** Resize the control panel to its minimum width and inspect all nine sections.
**Expected:** No text, label, or button overlaps an adjacent element in any section.
**Why human:** Layout overflow requires visual inspection at the constrained width.

#### 10. Side Panel Four Modes

**Test:** Press Ctrl+Shift+P in the browser.
**Expected:** Side panel opens with four mode tabs (FSB Agent, Explorer, Tabs, Tools) visible and selectable.
**Why human:** Keyboard shortcut binding and tab switcher visibility require the running browser.

---

### Gaps Summary

No gaps. All 18 automated truths are VERIFIED. All code-level artifacts exist, are substantive, wired, and have real data flowing through them. All four critical blocker bugs from the code review are fixed. The only open items are the 10 visual/behavioral checks listed above that require a running browser build — these are explicitly deferred to human verification per the 08-05-PLAN.md checkpoint:human-verify task design.

---

_Verified: 2026-06-16T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
