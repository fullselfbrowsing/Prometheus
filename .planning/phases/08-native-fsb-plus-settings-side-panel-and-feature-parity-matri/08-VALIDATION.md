---
phase: 08
slug: native-fsb-plus-settings-side-panel-and-feature-parity-matri
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-17
---

# Phase 08 - Validation Strategy

> Per-phase validation contract for the native FSB-plus control center, settings surface, provider execution metadata, and parity release gate.

**Revision note (2026-06-16):** This strategy predates the canonical design split. The nine operator sections and settings now live on the FSB Control Panel page; the side panel exposes the four modes (FSB Agent, Explorer, Tabs, Tools). Per-task source-file targets below are starting points; confirm exact files (side panel vs control panel page) when Phase 8 is planned. See `08-UI-SPEC.md` and `.planning/design/DESIGN-REFERENCE.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Qt Test / CMake / CTest, Bash smoke scripts, Node MCP smoke scripts |
| **Config file** | `falkon/autotests/CMakeLists.txt`, `falkon/build/fsb-baseline`, `falkon/tools/fsb-baseline/release-validate.sh` |
| **Quick run command** | `git diff --check && git -C falkon diff --check && bash -n falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh && ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|tabmodeltest' --output-on-failure` |
| **Full suite command** | `falkon/tools/fsb-baseline/release-validate.sh --build-dir falkon/build/fsb-baseline` |
| **Estimated runtime** | ~2 minutes for focused static/test checks; full release validation depends on local build cache |

---

## Sampling Rate

- **After every task commit:** Run `git diff --check`, `git -C falkon diff --check`, plan-specific `rg` checks, and the focused CTest target for touched code.
- **After every plan wave:** Run `bash -n falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` and `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|tabmodeltest' --output-on-failure`.
- **Before `$gsd-verify-work`:** Run `falkon/tools/fsb-baseline/release-validate.sh --build-dir falkon/build/fsb-baseline`; it must include and pass the FSB-plus parity gate.
- **Max feedback latency:** 120 seconds for focused checks; full release validation may exceed that and is required at phase gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-W0-01 | 01 | 1 | FSBP-02, FSBP-03, FSBP-06 | T-08-01 | Parity evidence is explicit and release-blocking; no undocumented FSB category can silently pass. | static/smoke | `bash -n falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh && falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh --matrix-only` | no - Wave 0 creates `falkon/tools/fsb-baseline/FSB-PARITY.md` and `smoke-fsb-plus-parity.sh` | pending |
| 08-01-01 | 01 | 1 | FSBP-02, FSBP-03, FSBP-06 | T-08-01 | Release validation fails on missing matrix rows, source evidence, or validation commands. | release/static | `rg "smoke-fsb-plus-parity.sh" falkon/tools/fsb-baseline/release-validate.sh && falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh --matrix-only` | partial - release script exists, parity files missing | pending |
| 08-02-01 | 02 | 2 | FSBP-04 | T-08-02 | Provider-backed execution is represented with explicit mode/fallback metadata; unavailable providers cannot be misreported as hosted execution. | Qt/router | `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest' --output-on-failure` | partial - router tests exist but execution-mode coverage is missing | pending |
| 08-03-01 | 03 | 2 | FSBP-01, FSBP-05 | T-08-03 | Settings persist agent policy without exposing raw secrets or weakening tab ownership and internal-surface safeguards. | Qt/static | `rg "agentCap|tabOwnership|telemetry|vault|supervision|visualFeedback" falkon/src/lib/preferences falkon/src/lib/agent && ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest' --output-on-failure` | partial - preferences exist but Phase 8 controls are missing | pending |
| 08-04-01 | 04 | 3 | FSBP-01, FSBP-03, FSBP-05 | T-08-04 | Native control center renders FSB-plus state from runtime/router APIs and does not duplicate sensitive state in widgets. | static/build | `rg "MCP|Permissions|Diagnostics|Supervision|Pairing|Parity" falkon/src/lib/agent && cmake --build falkon/build/fsb-baseline --target FalkonPrivate agentcommandroutertest tabmodeltest -j2` | partial - control panel page sections to be built; side panel hosts the four modes | pending |
| 08-05-01 | 05 | 4 | FSBP-01, FSBP-02, FSBP-06 | T-08-05 | MCP bridge, diagnostics, memory, site guides, vault, supervision, and pairing remain observable through native and MCP validation paths. | smoke/release | `node --check falkon/tools/prometheus-mcp/server.mjs && falkon/tools/fsb-baseline/release-validate.sh --build-dir falkon/build/fsb-baseline` | partial - MCP and release scripts exist, parity gate missing | pending |

---

## Wave 0 Requirements

- [ ] `falkon/tools/fsb-baseline/FSB-PARITY.md` - required matrix rows for side panel, provider settings, model discovery, MCP tools, DOM snapshots, action tools, visual feedback, memory, vault, remote dashboard, tab management, diagnostics, and release gates.
- [ ] `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` - static matrix validator with `--matrix-only` and release-gate behavior.
- [ ] `falkon/tools/fsb-baseline/release-validate.sh` - invokes `smoke-fsb-plus-parity.sh` as a release-blocking gate.
- [ ] `falkon/autotests/agentcommandroutertest.cpp` or equivalent focused coverage - provider execution-mode fallback, unavailable provider metadata, policy reads, and secret redaction.
- [ ] Static source validation for Phase 8 settings controls in `falkon/src/lib/preferences/preferences.cpp` and `falkon/src/lib/preferences/preferences.ui`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Side panel modes and control panel section density | FSBP-01 | Requires rendered Qt widget inspection | Launch Prometheus, open the side panel and verify the four modes (FSB Agent, Explorer, Tabs, Tools); open the FSB Control Panel page (pinned FSB tab) and verify Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, and Parity Matrix are reachable without clipped text at 320px, 384px, and 720px widths. |
| Settings surface copy and destructive/security states | FSBP-05 | Requires rendered Preferences dialog inspection | Open Preferences, find Phase 8 agent policy settings, verify labels and state copy match `08-UI-SPEC.md`, and confirm secret/vault controls do not display raw secrets. |
| Provider configured vs unavailable task route | FSBP-04 | Live provider credentials should not be required for automated release validation | Configure a provider with no secret, submit a side-panel task, and verify task details show local fallback plus `provider_not_configured` or equivalent unavailable reason instead of claiming hosted execution. |
| Parity matrix reviewability | FSBP-02, FSBP-03 | Human judgment confirms "better than FSB" claims are concrete | Open `falkon/tools/fsb-baseline/FSB-PARITY.md` and verify each `Native-improved` row names a specific browser-owned improvement and a validation command. |

---

## Validation Sign-Off

- [x] All phase requirements have automated static/build/release checks or manual validation entries.
- [x] Sampling continuity defined for task commits, plan waves, and phase gate.
- [x] Wave 0 covers all missing validation dependencies from research.
- [x] No watch-mode commands.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-17
