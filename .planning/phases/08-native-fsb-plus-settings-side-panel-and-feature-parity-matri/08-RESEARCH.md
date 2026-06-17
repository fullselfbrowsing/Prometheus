# Phase 08: Native FSB-Plus Settings Side Panel and Feature Parity Matrix - Research

**Researched:** 2026-06-17  
**Domain:** Qt/Falkon native control center, FSB parity, MCP/runtime security, release validation  
**Confidence:** HIGH

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

No `## Decisions` section exists in `08-CONTEXT.md`; the following user steer and planning targets are copied from the phase context and treated as locked phase constraints. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`]

**User steer**

The browser should include relevant native settings and a native side panel, and it should cover all FSB features but better. "Better" needs to be concrete: native control over browser-owned surfaces, safer secrets, lower-latency routing, richer tab/session state, and better supervised visibility.

**Planning targets**

- Create `FSB-PARITY.md` that lists FSB feature groups, Prometheus native equivalents, native improvements, status, and validation command.
- Upgrade native side panel/settings to expose tasks, provider/model discovery, MCP status, internal permissions, vault, memory/site guides, logs, diagnostics, supervision, and dashboard pairing.
- Add user-facing settings for internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, and supervision pairing.
- Connect side panel task execution to provider-backed execution when practical, while preserving local/MCP fallback behavior.
- Add release validation that fails if parity rows are missing, undocumented, or unverified.

### Claude's Discretion

No `## Claude's Discretion` section exists in `08-CONTEXT.md`. Research discretion is limited to implementation placement, validation shape, and which provider-backed execution boundaries should be concrete in this phase. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`]

### Deferred Ideas (OUT OF SCOPE)

No `## Deferred Ideas` section exists in `08-CONTEXT.md`. Do not expand this phase into unrelated Phase 9 visual polish or live internet-only provider validation. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`; VERIFIED: `.planning/ROADMAP.md`]

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FSBP-01 | Native side panel/control center for tasks, providers, MCP status, permissions, vault, memory, site guides, logs, diagnostics, supervision, dashboard pairing. | The existing sidebar has Task, Providers, Logs, Memory, and Vault tabs, while runtime/router code already exposes diagnostics, provider config, memory, site guides, vault metadata, task state, and supervision APIs; Phase 8 should add missing MCP status, permissions, model discovery, supervision, pairing, and dashboard-state UI surfaces. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| FSBP-02 | Feature parity matrix against FSB covering side panel, provider settings, model discovery, MCP tools, DOM snapshots, action tools, visual feedback, memory, vault, remote dashboard, tab management, diagnostics. | Local FSB sources enumerate these baseline categories, including side panel/options/control panel/logs/analytics/memory/vault/sync, 51 extension tools, 59 MCP handlers, DOM snapshots, action verification, visual feedback, logs, memory, vault flows, model discovery, and local MCP. [VERIFIED: `.context/fsb-org/FSB/README.md`; VERIFIED: `.context/fsb-org/FSB/mcp/ai/tool-definitions.cjs`; VERIFIED: `.context/fsb-org/FSB/mcp/src/tools`] |
| FSBP-03 | Native improvements over FSB: internal settings control, safer secret handling, richer tab/session state, lower-latency native routing, offline-capable UI assets. | Prometheus already has native internal-surface routing, stable tab/session metadata, local bearer-protected HTTP routing, native-only secret rejection over remote transports, and runtime profile persistence; the matrix should classify these as native improvements where validation exists. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| FSBP-04 | Side panel task execution can use configured provider-backed execution when available and local/MCP execution when unavailable. | Current native sidebar task execution is local-only and immediately finishes with a local runtime outcome; the router has provider configuration metadata but no hosted execution adapter in the reviewed code. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| FSBP-05 | User-facing settings expose internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, supervision pairing state. | Preferences already persist browser settings through Qt/Falkon settings patterns; agent cap is currently environment-only, and ownership/supervision fields are visible in router diagnostics/list_tabs but not in a durable settings surface. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; VERIFIED: `falkon/src/lib/app/mainapplication.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| FSBP-06 | Release validation includes a parity gate that fails when required FSB feature categories are missing, regressed, undocumented, or unverified. | `release-validate.sh` already chains syntax checks, build, agent smoke, MCP bridge smoke, compact tab smoke, browser smoke, packaging, and packaged-app smoke, so a parity gate should be integrated as another required script. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

</phase_requirements>

## Summary

Phase 8 should be planned as a native control-center and evidence artifact phase, not as a broad rewrite of Prometheus runtime internals. Prometheus already has the main native primitives: `AgentRuntime` owns task/provider/log/diagnostics/memory/site-guide/vault state, `AgentRuntimeSidebarWidget` renders the first native tabs, `AgentCommandRouter` exposes native/MCP-callable tools, and `release-validate.sh` already provides a release-gate spine. [VERIFIED: `falkon/src/lib/agent/agentruntime.h`; VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]

The largest gaps are explicit rather than hidden: the sidebar does not yet cover MCP status, permissions, model discovery, diagnostics, supervision, or dashboard pairing; side-panel task execution is currently local-only; `discover_models` currently returns provider config/list metadata rather than performing live discovery; and there is no maintained parity matrix that binds FSB baseline categories to Prometheus implementation evidence and validation commands. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/README.md`]

**Primary recommendation:** implement a native settings/control-center layer over the existing runtime/router primitives, add `FSB-PARITY.md` as the source of truth for parity status and validation evidence, and wire a new parity smoke gate into `release-validate.sh` so missing or undocumented FSB categories fail release validation. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Native side panel/control center | Browser / Client | API / Backend | The UI is a Qt native sidebar, while authoritative state and mutations should continue to flow through `AgentRuntime` and `AgentCommandRouter` instead of duplicating state in widgets. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`] |
| Preferences/settings surface | Browser / Client | Database / Storage | Falkon preferences persist settings through Qt/Falkon settings objects, so Phase 8 policy controls should live in preferences/settings and read/write durable profile settings. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; CITED: `https://doc.qt.io/qt-6/qsettings.html`] |
| Provider configuration and model discovery | API / Backend | Browser / Client | Runtime/router code owns provider metadata and secret boundaries; UI should render provider/model state and request discovery without handling raw provider logic. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Provider-backed task execution | API / Backend | Browser / Client | Side panel and MCP should submit tasks, but execution routing, fallback selection, outcomes, costs, and unavailable reasons belong in runtime/router code. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| MCP tool bridge/status | API / Backend | Browser / Client | `server.mjs` is the stdio bridge and native HTTP router is the command endpoint; the control center should observe and display status rather than implement another transport. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Vault and provider secrets | Database / Storage | Browser / Client | Secrets should remain native-only in Keychain or owner-only fallback secret files; side panel/preferences can save native secrets but MCP/router paths must reject raw secret payloads. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Memory and site guides | Database / Storage | Browser / Client | Runtime persists `memory.json` and `site-guides.json` under the profile runtime directory; side panel/settings should browse and manage metadata through runtime APIs. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`] |
| Tab ownership/session state | API / Backend | Browser / Client | Tab state comes from `TabModel` and router `list_tabs`/diagnostics; UI should expose owner, automation, supervision, health, group, and visual state without creating independent tab authority. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VERIFICATION.md`] |
| Supervision/dashboard pairing | API / Backend | Browser / Client | Pairing sessions, expiry, target validation, and DOM snapshots are enforced in the router; UI should display session state and controls. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`] |
| Release parity gate | Build / CI | API / Backend | `release-validate.sh` already orchestrates release validation, so parity verification should be a first-class script invoked by that gate. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` file exists in the working directory, so there are no additional project-specific directives from that file. [VERIFIED: shell check in `/Users/lakshman/conductor/workspaces/prometheus/puebla`]

No `.claude/skills/` or `.agents/skills/` project skill directories were found in the working directory. [VERIFIED: shell check in `/Users/lakshman/conductor/workspaces/prometheus/puebla`]

## Standard Stack

### Core

| Library / Component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| Prometheus/Falkon native browser | `26.07.70` | Host application for sidebar, preferences, native router, runtime, tab model, and QtWebEngine surfaces. | The local binary reports this version and the project roadmap requires continuing the Falkon/QtWebEngine native-browser path. [VERIFIED: `prometheus --version`; VERIFIED: `.planning/PROJECT.md`] |
| Qt / QtWebEngine | Qt `6.11.1` installed; project minimum Qt `6.4.0` | Native widgets, preferences UI, web engine pages, and local networking. | The build files require Qt6 widgets/network/webengine components, and local Homebrew Qt CMake packages are present. [VERIFIED: `falkon/CMakeLists.txt`; VERIFIED: local `/opt/homebrew/Cellar/qt/6.11.1`; CITED: `https://doc.qt.io/qt-6/qtabwidget.html`] |
| `AgentRuntime` | In-tree | Source of truth for runtime tasks, providers, logs, diagnostics, memory, site guides, vault metadata, and secret storage. | Phase 5 intentionally made `AgentRuntime` the shared native state layer for sidebar and MCP/runtime parity surfaces. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md`; VERIFIED: `falkon/src/lib/agent/agentruntime.h`] |
| `AgentRuntimeSidebarWidget` | In-tree | Native side panel UI. | Existing UI already uses Qt widgets and tabs for Task, Providers, Logs, Memory, and Vault, making it the natural extension point for the FSB-plus control center. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`] |
| `AgentCommandRouter` | In-tree | Bearer-protected local HTTP command router for native tools, MCP bridge calls, diagnostics, tasks, tabs, DOM snapshots, supervision, memory, and vault metadata. | Existing smokes and MCP bridge already route through this component, so Phase 8 should extend it rather than add a second command path. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| Falkon preferences / `QSettings` / `QzSettings` | In-tree plus Qt | Durable user-facing settings. | Existing preferences persist browser settings through Settings/QSettings patterns and should host Phase 8 policy settings. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; VERIFIED: `falkon/src/lib/tools/qzsettings.h`; CITED: `https://doc.qt.io/qt-6/qsettings.html`] |
| `QSaveFile` JSON profile persistence | Qt | Atomic writes for runtime JSON files. | `AgentRuntime` already persists tasks/logs/memory/site guides/vault metadata using `QSaveFile`, and Qt documents commit-based replacement semantics for safer writes. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; CITED: `https://doc.qt.io/qt-6/qsavefile.html`] |
| macOS Security.framework Keychain | macOS system framework | Native provider/vault secret storage. | The runtime links Security.framework on macOS and uses Keychain APIs before falling back to owner-only files. [VERIFIED: `falkon/src/lib/CMakeLists.txt`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`] |
| Node.js MCP bridge | Node `v24.14.1` | Stdio MCP bridge script and MCP smoke tests. | `server.mjs` and `smoke.mjs` are Node ESM scripts already included in release validation. [VERIFIED: `node --version`; VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |
| CMake / CTest / Ninja | CMake `4.3.3`, CTest `4.3.3`, Ninja `1.13.2` | Build and focused Qt tests. | Existing build targets include `prometheus`, `agentcommandroutertest`, and `tabmodeltest`; release validation builds through CMake. [VERIFIED: `cmake --version`; VERIFIED: `ctest --version`; VERIFIED: `ninja --version`; VERIFIED: `cmake --build falkon/build/fsb-baseline --target help`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Bash | `/bin/bash` `3.2.57` | Release and smoke gate scripts. | Use for parity gate scripts following existing `smoke-agent-control.sh` and `smoke-compact-tabs.sh` patterns. [VERIFIED: `/bin/bash --version`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`; VERIFIED: `falkon/tools/fsb-baseline/smoke-compact-tabs.sh`] |
| `curl` | `8.7.1` | Local router smoke calls. | Use for bearer-protected `/health` and `/agent/command` validation. [VERIFIED: `curl --version`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| `rg` | `15.1.0` | Static parity and release checks. | Use in smoke/parity gates to assert required source patterns and matrix rows. [VERIFIED: `rg --version`; VERIFIED: `falkon/tools/fsb-baseline/smoke-compact-tabs.sh`] |
| Local FSB checkout | `.context/fsb-org/FSB` | Offline FSB feature baseline. | Use as the authoritative local baseline for parity categories and tool lists rather than live internet. [VERIFIED: `.context/fsb-org/FSB/README.md`; VERIFIED: `.context/fsb-org/FSB/mcp/ai/tool-definitions.cjs`] |
| OWASP ASVS | Official project | Security control taxonomy for validation and threat mapping. | Use as a checklist vocabulary for auth/session/access-control/input-validation/crypto/data-protection risks in the security domain. [CITED: `https://owasp.org/www-project-application-security-verification-standard/`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native Qt sidebar/settings | Embedded FSB web side panel | The phase is explicitly native and Phase 5 chose native secret/UI boundaries, so an embedded web app would weaken native control and secret boundaries. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md`; VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`] |
| Local FSB checkout for parity | Live FSB website or package lookup | Local sources keep validation offline-capable and reproducible; live lookup would make release validation dependent on external network state. [VERIFIED: `.context/fsb-org/FSB/README.md`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |
| Existing `AgentCommandRouter` and MCP bridge | New side-channel transport | Existing release smokes, MCP server, and native router already prove this route, so adding another transport would increase parity risk. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| Keychain/native-only secret path | Persisting API keys in JSON, preferences text, or MCP args | Current runtime already blocks remote secret payloads and stores native secrets through Keychain/fallback; JSON or MCP secret transport would regress the Phase 5 security decision. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Offline local parity gate | Live provider/dashboard integration tests as required release gates | Phase 8 can expose live-provider/dashboard capability status, but required release validation should not depend on external provider accounts or internet availability. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

**Installation:**

No new package installation is required for the standard Phase 8 stack. [VERIFIED: local tool availability audit]

```bash
cmake --build falkon/build/fsb-baseline --target prometheus agentcommandroutertest tabmodeltest
ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|tabmodeltest' --output-on-failure
```

**Version verification:** package-manager version checks were not needed because the recommended stack is in-tree plus system Qt/CMake/Node tools; local command probes verified the versions listed above. [VERIFIED: local environment audit]

## Architecture Patterns

### System Architecture Diagram

```text
Human operator
  -> Native Sidebar / Preferences
      -> AgentRuntime state APIs
      -> AgentCommandRouter command APIs
          -> QtWebEngine page + TabModel ownership/session state
          -> Supervision snapshot/diff/pairing state
          -> Internal-surface router
      -> Profile storage (QSettings + QSaveFile JSON)
      -> Native secret storage (Keychain or owner-only fallback)

MCP client
  -> tools/prometheus-mcp/server.mjs
      -> bearer token from /health
      -> AgentCommandRouter /agent/command
          -> same runtime, tab, supervision, vault metadata, and diagnostics paths

Release validation
  -> tools/fsb-baseline/release-validate.sh
      -> syntax/build/focused tests
      -> agent/MCP/browser/compact smoke scripts
      -> new FSB-plus parity gate
          -> FSB-PARITY.md required rows
          -> local FSB baseline evidence
          -> Prometheus native evidence
          -> live smoke checks when binary is available
```

This flow keeps UI, MCP, and release validation pointed at the same runtime/router behavior instead of creating separate parity claims. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]

### Recommended Project Structure

```text
falkon/
+-- src/lib/agent/
|   +-- agentruntime.*              # Durable runtime state, provider/task policy, secrets, parity metadata helpers
|   +-- agentruntimesidebar.*       # Native FSB-plus control center UI
|   +-- agentcommandrouter.*        # MCP/native command surface, diagnostics, provider execution routing
+-- src/lib/preferences/
|   +-- preferences.*               # User-facing persisted policy settings
|   +-- preferences.ui              # Settings controls for agent cap, permissions, telemetry, vault, visual feedback, pairing
+-- autotests/
|   +-- agentcommandroutertest.cpp  # Router/security/execution-mode focused coverage
|   +-- tabmodeltest.cpp            # Existing tab/session state coverage
+-- tools/fsb-baseline/
    +-- FSB-PARITY.md               # Required parity matrix and evidence ledger
    +-- smoke-fsb-plus-parity.sh    # Static + optional live parity gate
    +-- release-validate.sh         # Invokes parity gate as release-blocking validation
```

This structure follows existing file ownership: agent runtime/router code remains under `src/lib/agent`, persistent settings remain under `src/lib/preferences`, and release smokes remain under `tools/fsb-baseline`. [VERIFIED: `falkon/src/lib/agent`; VERIFIED: `falkon/src/lib/preferences`; VERIFIED: `falkon/tools/fsb-baseline`]

### Pattern 1: Runtime Owns State, UI Renders State

**What:** UI widgets should call runtime/router APIs and render returned state; widgets should not create independent copies of task/provider/vault/memory/session truth. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`]

**When to use:** Use this for tasks, providers, model discovery status, memory, site guides, vault entries, diagnostics, supervision, pairing, and MCP status. [VERIFIED: `falkon/src/lib/agent/agentruntime.h`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Example:**

```cpp
// Source: falkon/src/lib/agent/agentruntimesidebar.cpp
const QVariantMap config = runtime()->providerConfig(id);
const bool secretConfigured = config.value(QSL("secretConfigured")).toBool();
const QString discoveryStatus = config.value(QSL("discoveryStatus")).toString();
```

### Pattern 2: Native-Only Secret Save, Sanitized Read Paths

**What:** Native UI may pass secrets to `AgentRuntime::saveProviderConfig(..., true)`, while router/MCP calls must reject secret payloads and only expose `secretConfigured` metadata. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**When to use:** Use this for provider API keys, vault entries, payment credentials, autofill references, and diagnostics/log display. [VERIFIED: `.context/fsb-org/FSB/mcp/src/tools/vault.ts`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Example:**

```cpp
// Source: falkon/src/lib/agent/agentruntime.cpp
if (!secret.isEmpty()) {
    if (!allowSecretPayload) {
        return { false, QStringLiteral("SECRET_TRANSPORT_BLOCKED") };
    }
    if (!storeSecret(providerSecretKey(provider), secret, &error)) {
        return { false, error };
    }
}
```

### Pattern 3: Parity Matrix as Release Evidence

**What:** `FSB-PARITY.md` should be a required evidence ledger with one row per FSB category, mapped to Prometheus status, native improvement, source evidence, and validation command. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`; VERIFIED: `.context/fsb-org/FSB/README.md`]

**When to use:** Use it whenever claiming FSB coverage for side panel, provider settings, model discovery, MCP tools, DOM snapshots, action tools, visual feedback, memory, vault, remote dashboard, tab management, diagnostics, and release gates. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.context/fsb-org/FSB/README.md`]

**Example:**

```markdown
| Category | FSB Baseline | Prometheus Native Equivalent | Status | Native Improvement | Validation |
|----------|--------------|------------------------------|--------|--------------------|------------|
| Vault | Metadata list + extension-mediated fill; raw secrets do not cross MCP | Native vault metadata plus native-only confirmation boundary | Native-improved | Keychain/native confirmation; MCP secret rejection | `tools/fsb-baseline/smoke-agent-control.sh` + `smoke-fsb-plus-parity.sh` |
```

### Pattern 4: Provider Execution Uses Explicit Capability State

**What:** Task execution should report `executionMode`, `provider`, `model`, `providerAvailable`, and `unavailableReason` rather than silently pretending hosted execution happened. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`]

**When to use:** Use when the configured provider is missing a secret, endpoint, model, adapter, or network capability; fall back to local/MCP execution and mark the task outcome accordingly. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `.planning/REQUIREMENTS.md`]

**Example:**

```cpp
// Proposed Phase 8 shape based on existing AgentRuntime task outcomes.
QVariantMap outcome;
outcome.insert(QSL("executionMode"), providerReady ? QSL("provider") : QSL("local"));
outcome.insert(QSL("provider"), selectedProvider);
outcome.insert(QSL("model"), selectedModel);
outcome.insert(QSL("unavailableReason"), providerReady ? QString() : QSL("provider_not_configured"));
runtime->finishTask(taskId, summary, outcome);
```

### Pattern 5: Release Gate Combines Static Matrix Checks and Live Router Checks

**What:** Static checks should require matrix rows/evidence for each FSB category, and live checks should exercise native runtime behavior when a binary is available. [VERIFIED: `falkon/tools/fsb-baseline/smoke-compact-tabs.sh`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`]

**When to use:** Use in `smoke-fsb-plus-parity.sh`, then invoke it from `release-validate.sh` after syntax/build and before packaging success. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]

**Example:**

```bash
# Source pattern: falkon/tools/fsb-baseline/smoke-compact-tabs.sh
rg -q "FSBP-01" "$ROOT/tools/fsb-baseline/FSB-PARITY.md"
rg -q "vault.*SECRET_TRANSPORT_BLOCKED" "$ROOT/tools/fsb-baseline/FSB-PARITY.md"
```

### Anti-Patterns to Avoid

- **Duplicating runtime state in sidebar widgets:** this creates divergent task/provider/vault/memory truth; use `AgentRuntime` and router state instead. [VERIFIED: `falkon/src/lib/agent/agentruntime.h`; VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`]
- **Claiming model discovery parity while `discover_models` only returns saved config:** current router code aliases provider config/list behavior, so the matrix must either implement real discovery/fallback state or mark the category partial. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/ai/model-discovery.js`]
- **Passing secrets through MCP, diagnostics, logs, or matrix examples:** both Prometheus and FSB baseline enforce secret indirection/metadata boundaries. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/mcp/src/tools/vault.ts`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`]
- **Making live internet/provider access required for release validation:** provider-backed capability can be exposed, but parity validation should be reproducible with local code and optional live checks. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`; VERIFIED: `.planning/ROADMAP.md`]
- **Leaving agent cap as environment-only while calling settings complete:** `PROMETHEUS_AGENT_CAP` is read at router construction, while FSB exposes a user-facing cap setting. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/ui/control_panel.html`; VERIFIED: `.context/fsb-org/FSB/extension/options.js`]
- **Treating dashboard pairing as a UI-only status:** Prometheus pairing includes session ID, pairing code, target key, expiry, sequence, and stale/target validation; UI should reflect those server-side facts. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Native settings persistence | Ad hoc JSON or globals for preferences | Existing Falkon preferences, `Settings`, `QSettings`, and `QzSettings` patterns | Preferences already load/save durable settings and Qt provides platform-independent persistent settings groups. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; CITED: `https://doc.qt.io/qt-6/qsettings.html`] |
| Runtime JSON writes | Manual `QFile` overwrite | `QSaveFile` through existing `AgentRuntime` helpers | Existing runtime persistence uses atomic save helpers, and Qt documents safer commit semantics. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; CITED: `https://doc.qt.io/qt-6/qsavefile.html`] |
| Secret storage | JSON settings, logs, MCP args, or diagnostics fields | Existing Keychain/native-only secret path plus owner-only fallback | Phase 5 established native-only secret transport and current code blocks remote secret payloads. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| MCP bridge | New protocol bridge | `tools/prometheus-mcp/server.mjs` plus `AgentCommandRouter` | Existing bridge handles `/health` token acquisition and forwards tool calls to native HTTP. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`] |
| Tool parity inventory | Manual memory of FSB tools | Local FSB `TOOL_REGISTRY`, `mcp/src/tools`, and README baseline | The local FSB checkout contains the authoritative offline feature/tool baseline. [VERIFIED: `.context/fsb-org/FSB/mcp/ai/tool-definitions.cjs`; VERIFIED: `.context/fsb-org/FSB/mcp/src/tools`; VERIFIED: `.context/fsb-org/FSB/README.md`] |
| Native tab/session ownership | New side-panel tab registry | Existing `TabModel` and router `tabInfo()` | Router already reports stable tab IDs, owner, automation, supervision, health, group state, and visual reason. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| DOM snapshots/action tools | Separate injected JS library from sidebar | Existing router/native tool handlers | Router already exposes DOM snapshots, page snapshots, attributes, JS execution, and manual action tools to MCP/native callers. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`] |
| Parity validation | Human-only checklist | Scripted `smoke-fsb-plus-parity.sh` invoked by `release-validate.sh` | Existing release validation is script-driven and should fail missing parity evidence automatically. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

**Key insight:** Phase 8 should turn existing native runtime capabilities into visible, testable, documented control-center parity; custom side channels, custom secret stores, and manual parity claims would undercut the native FSB-plus story. [VERIFIED: `.planning/STATE.md`; VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Model Discovery Looks Implemented But Is Only Config Echo

**What goes wrong:** A planner may count `discover_models` as FSB parity because the tool name exists. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Why it happens:** `routeProviderConfig()` handles `get_provider_config`, `list_providers`, and `discover_models` using the same provider-config branch, while FSB has provider-specific discovery and fallback model lists. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/ai/model-discovery.js`]

**How to avoid:** Add explicit discovery status/fallback model behavior or mark the row partial with an unavailable reason and validation. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.context/fsb-org/FSB/extension/ai/model-discovery.js`]

**Warning signs:** `discover_models` returns only `secretConfigured`, `models`, `endpoint`, and `discoveryStatus: configured/not_configured` without source/fallback/cache metadata. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

### Pitfall 2: Side Panel Task Execution Remains Local-Only

**What goes wrong:** FSBP-04 fails because UI task execution never attempts provider-backed execution when a provider is configured. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`]

**Why it happens:** Current `runTask()` in the sidebar marks a task running and immediately finishes with a local runtime summary. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`]

**How to avoid:** Introduce an execution routing contract that records provider readiness, provider/model, execution mode, fallback mode, and unavailable reason in task outcome metadata. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Warning signs:** Completed task outcomes always report `cost: 0` and local browser actions without provider/model metadata. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

### Pitfall 3: MCP Tool Lists Drift

**What goes wrong:** `server.mjs` advertises tools that `/health` does not list, or router code supports commands not represented in the parity matrix. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Why it happens:** The native router, MCP server tool array, and health payload are separate definitions today. [VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**How to avoid:** Make the parity gate compare required tool names across `server.mjs`, router routing branches, `/health` output, and `FSB-PARITY.md`. [VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`; VERIFIED: `falkon/tools/prometheus-mcp/smoke.mjs`]

**Warning signs:** A tool is validated by the MCP smoke but absent from `/health.tools`, or vice versa. [VERIFIED: `falkon/tools/prometheus-mcp/smoke.mjs`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

### Pitfall 4: Secret Boundaries Regress Through Settings or Diagnostics

**What goes wrong:** API keys, vault credentials, payment data, or telemetry-sensitive values leak through MCP args, logs, diagnostics, matrix examples, or preferences echo text. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`]

**Why it happens:** A native settings UI can legitimately collect secrets, but remote transports and diagnostics must only expose metadata. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**How to avoid:** Keep secret inputs write-only, clear fields after save, return `secretConfigured`, and keep `SECRET_TRANSPORT_BLOCKED` and `VAULT_NATIVE_CONFIRMATION_REQUIRED` paths in release smokes. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`]

**Warning signs:** A test fixture or UI label contains a literal API key/password/card number, or `set_provider_config` accepts `apiKey` over MCP. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/mcp/src/tools/vault.ts`]

### Pitfall 5: Settings Surface Does Not Actually Control Runtime Policy

**What goes wrong:** Settings are visible but do not affect agent cap, permissions, telemetry, visual feedback, vault boundaries, or pairing state. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `falkon/src/lib/preferences/preferences.cpp`]

**Why it happens:** Current agent cap is read from `PROMETHEUS_AGENT_CAP` at router construction, while FSB exposes cap and visual/telemetry controls in the control panel. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/ui/control_panel.html`; VERIFIED: `.context/fsb-org/FSB/extension/options.js`]

**How to avoid:** Persist policy settings through Preferences/QSettings and have router/runtime read them as the source of policy truth, with environment variables only as test/bootstrap overrides. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; VERIFIED: `falkon/src/lib/app/mainapplication.cpp`]

**Warning signs:** A Phase 8 setting exists only as label text or checkbox state in the sidebar and is never read by runtime/router code. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

### Pitfall 6: Dashboard Pairing Is Treated As Generic "Connected/Disconnected"

**What goes wrong:** The UI hides expiry, target key, sequence, or stale-session rejection, weakening supervised visibility. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`]

**Why it happens:** FSB has remote dashboard pairing concepts, while Prometheus supervision is native/session-stamped and should display different but stronger fields. [VERIFIED: `.context/fsb-org/FSB/extension/ui/control_panel.html`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**How to avoid:** Surface session ID, pairing code, target, expiry, sequence, active session count, and last error status in the control center. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]

**Warning signs:** Matrix row says dashboard pairing is complete but no validation checks expired/stale/target mismatch behavior. [VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`; VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`]

## Code Examples

Verified patterns from official/local sources:

### Native Secret Rejection Over Remote Transport

```cpp
// Source: falkon/src/lib/agent/agentcommandrouter.cpp
const QStringList secretKeys = {
    QSL("secret"),
    QSL("apiKey"),
    QSL("password"),
    QSL("token"),
};
for (const QString &key : secretKeys) {
    if (params.contains(key) && !params.value(key).toString().isEmpty()) {
        return errorResult(QSL("SECRET_TRANSPORT_BLOCKED"),
                           QSL("Secrets can only be updated from the native Prometheus settings UI."));
    }
}
```

### Existing Provider Metadata Shape

```cpp
// Source: falkon/src/lib/agent/agentruntime.cpp
config.insert(QSL("secretConfigured"), hasSecret(providerSecretKey(provider)));
config.insert(QSL("models"), models);
config.insert(QSL("discoveryStatus"), config.value(QSL("secretConfigured")).toBool()
              ? QSL("configured")
              : QSL("not_configured"));
config.insert(QSL("secretTransport"), QSL("native_ui_only"));
```

### Existing Task Submit and Immediate Local Completion Pattern

```cpp
// Source: falkon/src/lib/agent/agentruntimesidebar.cpp
auto result = runtime()->submitTask(prompt, context, false);
runtime()->markTaskRunning(taskId);
runtime()->appendTaskProgress(taskId, tr("Captured context for %1").arg(url));
runtime()->finishTask(taskId, tr("Local Prometheus runtime captured the current page context."),
                      QVariantMap {
                          { QSL("url"), url },
                          { QSL("title"), title },
                          { QSL("cost"), 0 },
                      });
```

### Parity Gate Static Check Pattern

```bash
# Source pattern: falkon/tools/fsb-baseline/smoke-compact-tabs.sh
need_pattern "FSBP-02" "$ROOT/tools/fsb-baseline/FSB-PARITY.md"
need_pattern "Model discovery" "$ROOT/tools/fsb-baseline/FSB-PARITY.md"
need_pattern "SECRET_TRANSPORT_BLOCKED" "$ROOT/tools/fsb-baseline/FSB-PARITY.md"
need_pattern "smoke-fsb-plus-parity.sh" "$ROOT/tools/fsb-baseline/release-validate.sh"
```

### Local Bearer-Protected Router Smoke Pattern

```bash
# Source pattern: falkon/tools/fsb-baseline/smoke-agent-control.sh
HEALTH_JSON="$(curl -fsS "$BASE/health")"
TOKEN="$(node -e "const h=JSON.parse(process.argv[1]); console.log(h.token || '')" "$HEALTH_JSON")"
call_tool diagnostics '{}'
call_tool list_tabs '{}'
```

## State of the Art

| Old Approach | Current Approach | When Changed / Verified | Impact |
|--------------|------------------|--------------------------|--------|
| FSB extension side panel/options/control panel/logs/memory/vault/sync surfaces. | Prometheus native Qt sidebar plus planned native preferences/control-center settings. | Phase 5 introduced native sidebar/runtime; Phase 8 extends it. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-01-SUMMARY.md`; VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`] | Native UI can control browser-owned surfaces and keep secrets off web/MCP transports. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md`] |
| FSB WebCrypto extension secure config and vault mediation. | Prometheus Keychain/native-only provider and vault secret boundary with metadata over MCP. | Phase 5 provider/vault summaries and current runtime/router code. [VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-02-SUMMARY.md`; VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces/05-05-SUMMARY.md`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`] | Prometheus can claim safer native secret handling when validation proves remote secret rejection and native-only writes. [VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| FSB explicit `start_visual_session` / `end_visual_session` tools. | Prometheus returns typed legacy removal for visual-session tools and uses native supervision/session flows instead. | Phase 6 and current MCP smoke. [VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-01-SUMMARY.md`; VERIFIED: `falkon/tools/prometheus-mcp/smoke.mjs`] | Matrix should mark this as intentional replacement, not a missing tool, only if supervision/visual feedback evidence is complete. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| FSB remote dashboard pairing/sync UI. | Prometheus session-stamped supervision pairing with target, expiry, sequence, and stale validation. | Phase 6 summaries and current router code. [VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] | Native dashboard/pairing row should focus on supervised visibility and validation, not a one-for-one remote web dashboard clone. [VERIFIED: `.planning/ROADMAP.md`] |
| FSB tab management with multi-agent ownership and agent cap. | Prometheus stable tab IDs, owner/automation/supervision/health/group fields, and cap default from environment. | Phase 7 verification and router code. [VERIFIED: `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VERIFICATION.md`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] | Phase 8 should move cap/ownership policy into visible settings and matrix rows. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Deprecated/outdated:**

- `start_visual_session` / `end_visual_session` as active Prometheus tools are intentionally removed legacy paths that return `legacy_visual_session_removed`; validation should assert the typed response and supervise through current pairing/snapshot tools. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/prometheus-mcp/smoke.mjs`]
- Treating FSB parity as "all tool names exist" is outdated for Prometheus because native improvements can intentionally replace FSB mechanisms only when the matrix documents replacement, risk, and validation. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`; VERIFIED: `.context/fsb-org/FSB/README.md`]

## Assumptions Log

All claims in this research were verified against local project files, local FSB baseline files, local environment probes, or cited official documentation; no `[ASSUMED]` claims are used. [VERIFIED: research source audit]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | No assumed claims. | - | - |

## Open Questions (RESOLVED)

1. **Should `FSB-PARITY.md` live under `falkon/tools/fsb-baseline/` or only under the phase directory?**  
   What we know: the phase context requires creating `FSB-PARITY.md`, and release validation scripts live in `falkon/tools/fsb-baseline/`. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]  
   What's unclear: the user did not specify the durable file path. [VERIFIED: user prompt]  
   Recommendation: place the release-enforced matrix at `falkon/tools/fsb-baseline/FSB-PARITY.md` so `release-validate.sh` can validate it; optionally link/copy phase evidence from the planning directory. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]  
   **Resolved:** Plan 08-01 places the durable matrix at `falkon/tools/fsb-baseline/FSB-PARITY.md` and wires `smoke-fsb-plus-parity.sh` + `release-validate.sh` to validate it.

2. **How much real hosted-provider execution should Phase 8 implement?**  
   What we know: provider config exists, provider secrets can be saved natively, and current execution is local-only. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`]  
   What's unclear: there is no reviewed in-tree hosted-provider adapter for task reasoning/execution. [VERIFIED: `falkon/src/lib/agent`; VERIFIED: `falkon/tools/prometheus-mcp/server.mjs`]  
   Recommendation: implement a typed execution-mode contract now, use provider-backed execution only for adapters that exist and can be tested without exposing secrets, and mark missing providers unavailable with fallback metadata instead of pretending parity. [VERIFIED: `.planning/REQUIREMENTS.md`]  
   **Resolved:** Plan 08-02 adds a typed execution-mode contract to `finishTask` (executionMode / provider / model / providerAvailable / unavailableReason) and a `PROVIDER_NOT_CONFIGURED` code; missing providers are reported unavailable with fallback metadata rather than faking parity.

3. **Should Prometheus align the agent cap default with FSB's default of 8 or preserve the current router default of 4?**  
   What we know: FSB exposes a configurable cap default of 8 and clamps 1..64; Prometheus router defaults to 4 unless `PROMETHEUS_AGENT_CAP` is set. [VERIFIED: `.context/fsb-org/FSB/extension/options.js`; VERIFIED: `.context/fsb-org/FSB/references/multi-agent-contract.md`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`]  
   What's unclear: whether the stricter Prometheus default is an intentional native improvement or just pre-Phase-8 bootstrap behavior. [VERIFIED: `.planning/REQUIREMENTS.md`]  
   Recommendation: expose a persisted cap setting and document the default in the matrix; change to 8 only if exact FSB behavioral parity is desired. [VERIFIED: `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`]  
   **Resolved:** Plans 08-02/08-03 expose a persisted `PrometheusRuntime/Policy/agentCap` setting (SpinBox range 1–16, default 4) read by the router at startup; the stricter native default of 4 is preserved as an intentional improvement and documented in the parity matrix.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `prometheus` binary | Live smoke validation | yes | `26.07.70` | Static checks can still run, but full parity smoke should use the binary. [VERIFIED: `prometheus --version`] |
| CMake | Build/test | yes | `4.3.3` | None needed. [VERIFIED: `cmake --version`] |
| CTest | Focused Qt tests | yes | `4.3.3` | None needed. [VERIFIED: `ctest --version`] |
| Ninja | Build backend | yes | `1.13.2` | CMake can use another configured generator only if build tree is regenerated. [VERIFIED: `ninja --version`] |
| Qt | Native UI/build | yes | `6.11.1` installed; project minimum `6.4.0` | None for local planning; build depends on configured Qt. [VERIFIED: local Qt CMake package paths; VERIFIED: `falkon/CMakeLists.txt`] |
| Node.js | MCP bridge and smoke scripts | yes | `v24.14.1` | None needed for existing scripts. [VERIFIED: `node --version`] |
| npm | Optional JS tooling/version probes | yes | `11.11.0` | Not required for Phase 8 core work. [VERIFIED: `npm --version`] |
| Bash | Smoke scripts | yes | `3.2.57` | Existing scripts use POSIX-compatible Bash patterns. [VERIFIED: `/bin/bash --version`] |
| `curl` | Local HTTP router smoke | yes | `8.7.1` | Node HTTP fallback possible but not needed. [VERIFIED: `curl --version`] |
| `rg` | Static smoke checks | yes | `15.1.0` | `grep` fallback possible but not needed. [VERIFIED: `rg --version`] |
| Local FSB checkout | Offline parity baseline | yes | Local `.context/fsb-org/FSB` | If absent, parity gate would need vendored baseline data; not needed here. [VERIFIED: `.context/fsb-org/FSB/README.md`] |
| Live provider accounts/API keys | Hosted-provider execution | no / not probed | - | Use native configured-provider checks and local/unavailable fallback; do not require live accounts for release validation. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `.planning/REQUIREMENTS.md`] |
| Remote dashboard service | Dashboard pairing parity | no / not required | - | Validate local pairing/session state and matrix row offline. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/ROADMAP.md`] |

**Missing dependencies with no fallback:**

- None for planning, static parity validation, focused Qt tests, or local router smoke. [VERIFIED: local environment audit]

**Missing dependencies with fallback:**

- Live hosted-provider credentials are not available and should not be required for release validation; provider-backed paths should fall back to explicit local/unavailable task outcomes. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `.planning/REQUIREMENTS.md`]
- A remote dashboard service is not required to validate native supervision pairing state; local router pairing/session tests cover the native surface. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | CMake/CTest `4.3.3`, Qt Test targets, Bash smoke scripts, Node MCP smoke scripts. [VERIFIED: `ctest --version`; VERIFIED: `falkon/autotests/CMakeLists.txt`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |
| Config file | `falkon/autotests/CMakeLists.txt`, `falkon/build/fsb-baseline`, `falkon/tools/fsb-baseline/release-validate.sh`. [VERIFIED: local files] |
| Quick run command | `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|tabmodeltest' --output-on-failure` [VERIFIED: `ctest --test-dir falkon/build/fsb-baseline -N -R 'agentcommandroutertest|tabmodeltest'`] |
| Full suite command | `falkon/tools/fsb-baseline/release-validate.sh --build-dir falkon/build/fsb-baseline` [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FSBP-01 | Control center exposes tasks, providers, MCP status, permissions, vault, memory, site guides, logs, diagnostics, supervision, and pairing. | Smoke + focused Qt/UI-static checks | `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh --binary prometheus` | No - Wave 0: create `smoke-fsb-plus-parity.sh`; existing sidebar files partial. [VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`] |
| FSBP-02 | Parity matrix covers required FSB categories with native equivalents, status, improvement, evidence, and validation command. | Static parity gate | `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh --matrix-only` | No - Wave 0: create `falkon/tools/fsb-baseline/FSB-PARITY.md` and script. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.context/fsb-org/FSB/README.md`] |
| FSBP-03 | Native improvements over FSB are concrete and verified: settings/internal control, secret safety, tab/session state, native routing, offline UI assets. | Static + router smoke | `falkon/tools/fsb-baseline/smoke-agent-control.sh --binary prometheus && falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh --matrix-only` | Existing partial: `smoke-agent-control.sh`; No - Wave 0 for improvement matrix/offline asset checks. [VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| FSBP-04 | Side panel task execution records provider-backed execution when configured and local/MCP fallback when unavailable. | Focused Qt/runtime test + router smoke | `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|agentruntimetest' --output-on-failure` | Existing `agentcommandroutertest` partial; No - Wave 0: add execution-mode coverage. [VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntimesidebar.cpp`] |
| FSBP-05 | User-facing settings persist and affect internal permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, and pairing state. | Focused Qt settings test + static source check | `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|preferencestest' --output-on-failure` | No - Wave 0: add or extend tests; preferences currently lack Phase 8 controls. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| FSBP-06 | Release validation fails when required parity categories are missing, regressed, undocumented, or unverified. | Release gate | `falkon/tools/fsb-baseline/release-validate.sh --build-dir falkon/build/fsb-baseline` | Existing release gate; No - Wave 0: insert parity script invocation. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

### Sampling Rate

- **Per task commit:** run `ctest --test-dir falkon/build/fsb-baseline -R 'agentcommandroutertest|tabmodeltest' --output-on-failure` plus `bash -n falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` when the script exists. [VERIFIED: `falkon/autotests/CMakeLists.txt`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]
- **Per wave merge:** run `falkon/tools/fsb-baseline/smoke-agent-control.sh --binary prometheus`, `node falkon/tools/prometheus-mcp/smoke.mjs --binary prometheus` through the existing release path, and the new parity smoke. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`; VERIFIED: `falkon/tools/prometheus-mcp/smoke.mjs`]
- **Phase gate:** full `release-validate.sh --build-dir falkon/build/fsb-baseline` must pass and include the parity gate before `/gsd-verify-work`. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`; VERIFIED: `.planning/ROADMAP.md`]

### Wave 0 Gaps

- [ ] `falkon/tools/fsb-baseline/FSB-PARITY.md` - source-of-truth matrix for FSBP-02/FSBP-03/FSBP-06. [VERIFIED: missing file check; VERIFIED: `.planning/REQUIREMENTS.md`]
- [ ] `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` - static matrix/category/tool coverage plus optional live router checks. [VERIFIED: missing file check; VERIFIED: `falkon/tools/fsb-baseline/smoke-compact-tabs.sh`]
- [ ] Extend `falkon/tools/fsb-baseline/release-validate.sh` - invoke the new parity gate and fail release validation on missing rows/evidence. [VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`]
- [ ] Extend `falkon/autotests/agentcommandroutertest.cpp` or add `falkon/autotests/agentruntimetest.cpp` - cover execution-mode fallback, provider-unavailable metadata, settings policy reads, and secret redaction. [VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`; VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`]
- [ ] Add static/preferences validation for new settings controls in `preferences.cpp`/`preferences.ui`. [VERIFIED: `falkon/src/lib/preferences/preferences.cpp`; VERIFIED: `falkon/src/lib/preferences/preferences.ui`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Yes, for local command access. | Continue health-issued bearer tokens for `/agent/command`, reject unauthenticated POST/OPTIONS, and avoid caller-supplied identity grants. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`; CITED: `https://owasp.org/www-project-application-security-verification-standard/`] |
| V3 Session Management | Yes, for bearer sessions and supervision pairing. | Keep session IDs, pairing codes, target keys, expiry, sequence validation, and stale-session errors visible and testable. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.planning/phases/06-supervision-packaging-and-release-hardening/06-02-SUMMARY.md`] |
| V4 Access Control | Yes. | Enforce tab ownership, internal-surface permissions, vault confirmation, and agent cap policy in runtime/router code, not only in UI. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`] |
| V5 Input Validation | Yes. | Validate provider IDs, setting bounds, agent caps, telemetry toggles, URLs, task params, and vault metadata through typed Qt/JSON handling and explicit error codes. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/options.js`] |
| V6 Cryptography | Yes. | Use Keychain/Security.framework or existing owner-only fallback for secrets; do not add custom crypto or JSON secret storage. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/CMakeLists.txt`] |
| V7 Error Handling and Logging | Yes. | Keep diagnostics/logs redacted, structured, and bounded; preserve typed errors like `SECRET_TRANSPORT_BLOCKED`, `VAULT_NATIVE_CONFIRMATION_REQUIRED`, and ownership/session errors. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| V8 Data Protection | Yes. | Keep provider/vault secrets native-only, expose telemetry controls, and avoid sending raw page/payment/credential data into diagnostics or parity artifacts. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `.context/fsb-org/FSB/extension/telemetry-collector.js`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`] |

### Known Threat Patterns for Prometheus FSB-Plus

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Web page or local process tries to invoke native command router without consent. | Spoofing / Elevation of Privilege | Keep health-issued bearer token requirement, no permissive CORS, unauthenticated OPTIONS rejection, and local-only routing. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`] |
| Provider API key leaks through MCP, logs, diagnostics, settings echo, or parity examples. | Information Disclosure | Allow secrets only through native UI writes, return `secretConfigured`, and block remote secret keys with `SECRET_TRANSPORT_BLOCKED`. [VERIFIED: `falkon/src/lib/agent/agentruntime.cpp`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Vault credential/payment data crosses tool arguments or model prompts. | Information Disclosure / Tampering | Use metadata references and native confirmation; preserve `VAULT_NATIVE_CONFIRMATION_REQUIRED` for autofill. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/mcp/src/tools/vault.ts`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`] |
| Agent manipulates another agent-owned tab. | Elevation of Privilege / Tampering | Enforce stable tab IDs, owner checks, and typed ownership errors in router commands and tests. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/autotests/agentcommandroutertest.cpp`] |
| Internal settings surface becomes too broadly controllable through MCP. | Elevation of Privilege | Add explicit internal-surface permission settings and audit visibility; default to least privilege for sensitive pages. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`] |
| Telemetry captures prompts, URLs, credentials, or page content. | Information Disclosure | Expose telemetry opt-out/boundary settings and follow FSB-style allowlisted event fields rather than raw context capture. [VERIFIED: `.context/fsb-org/FSB/extension/telemetry-collector.js`; VERIFIED: `.planning/REQUIREMENTS.md`] |
| Dashboard pairing remains valid after target/session changes. | Spoofing / Repudiation | Display and validate target key, session ID, expiry, sequence, stale snapshot errors, and active session state. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`] |
| Parity matrix hides missing security-sensitive categories. | Repudiation | Make release validation fail when required rows are absent, undocumented, or lack validation commands. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `falkon/tools/fsb-baseline/release-validate.sh`] |

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md` - product direction, native browser constraints, FSB-plus goals. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - FSBP-01 through FSBP-06 requirements. [VERIFIED: local file]
- `.planning/ROADMAP.md` - Phase 8 success criteria and release expectations. [VERIFIED: local file]
- `.planning/STATE.md` - current phase state and prior phase decisions/gaps. [VERIFIED: local file]
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md` - user steer and planning targets. [VERIFIED: local file]
- `.planning/phases/05-fsb-runtime-parity-surfaces/05-CONTEXT.md`, `05-01-SUMMARY.md` through `05-05-SUMMARY.md` - runtime/sidebar/provider/task/log/memory/site-guide/vault decisions and outcomes. [VERIFIED: local files]
- `.planning/phases/06-supervision-packaging-and-release-hardening/06-01-SUMMARY.md` through `06-04-SUMMARY.md` - supervision, pairing, packaging, release validation outcomes. [VERIFIED: local files]
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VERIFICATION.md` - Phase 7 tab/session/agent ownership verification. [VERIFIED: local file]
- `falkon/src/lib/agent/agentruntime.h` and `.cpp` - runtime state, provider config, persistence, secrets, diagnostics. [VERIFIED: local code]
- `falkon/src/lib/agent/agentruntimesidebar.h` and `.cpp` - current native sidebar and task/provider/log/memory/vault tabs. [VERIFIED: local code]
- `falkon/src/lib/agent/agentcommandrouter.h` and `.cpp` - local router, tool surface, auth, tabs, DOM/action tools, runtime APIs, supervision, diagnostics. [VERIFIED: local code]
- `falkon/tools/prometheus-mcp/server.mjs` and `smoke.mjs` - MCP bridge and MCP smoke coverage. [VERIFIED: local code]
- `falkon/tools/fsb-baseline/smoke-agent-control.sh`, `smoke-compact-tabs.sh`, and `release-validate.sh` - current validation spine and smoke patterns. [VERIFIED: local code]
- `.context/fsb-org/FSB/README.md` - local FSB feature baseline. [VERIFIED: local file]
- `.context/fsb-org/FSB/mcp/ai/tool-definitions.cjs` and `.context/fsb-org/FSB/mcp/src/tools` - local FSB tool baseline. [VERIFIED: local code]
- `.context/fsb-org/FSB/extension/ui/control_panel.html`, `sidepanel.html`, `options.js`, `ai/model-discovery.js`, `config/secure-config.js`, `telemetry-collector.js`, and `diagnostics-ring-buffer.js` - local FSB settings/provider/security/telemetry/diagnostics baseline. [VERIFIED: local code]
- `falkon/autotests/agentcommandroutertest.cpp`, `tabmodeltest.cpp`, and `autotests/CMakeLists.txt` - focused test infrastructure and existing router/tab assertions. [VERIFIED: local code]

### Secondary (MEDIUM confidence)

- Qt `QSettings` documentation - persistent platform-independent settings API. [CITED: `https://doc.qt.io/qt-6/qsettings.html`]
- Qt `QSaveFile` documentation - safe write/commit semantics. [CITED: `https://doc.qt.io/qt-6/qsavefile.html`]
- Qt `QTabWidget` documentation - native tabbed widget structure. [CITED: `https://doc.qt.io/qt-6/qtabwidget.html`]
- Qt `QWebEnginePage::runJavaScript` documentation - JavaScript execution API and isolated world support. [CITED: `https://doc.qt.io/qt-6/qwebenginepage.html#runJavaScript`]
- Qt `QTcpServer::listen` documentation - local server listen behavior. [CITED: `https://doc.qt.io/qt-6/qtcpserver.html#listen`]
- OWASP ASVS project page - security verification category vocabulary. [CITED: `https://owasp.org/www-project-application-security-verification-standard/`]

### Tertiary (LOW confidence)

- None. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - local build files, binaries, and tool versions were inspected. [VERIFIED: `falkon/CMakeLists.txt`; VERIFIED: local command probes]
- Architecture: HIGH - existing runtime/sidebar/router/preference ownership is visible in local code and phase summaries. [VERIFIED: `falkon/src/lib/agent`; VERIFIED: `falkon/src/lib/preferences`; VERIFIED: `.planning/phases/05-fsb-runtime-parity-surfaces`]
- FSB parity categories: HIGH - local FSB README, tool registry, MCP tools, UI, provider, vault, telemetry, and diagnostics files were inspected. [VERIFIED: `.context/fsb-org/FSB`]
- Provider-backed execution: MEDIUM - the absence of reviewed in-tree hosted execution adapters is clear, but exact desired provider implementation scope remains an open product decision. [VERIFIED: `falkon/src/lib/agent`; VERIFIED: Open Questions]
- Pitfalls/security: HIGH - risks are grounded in existing code paths, FSB baseline boundaries, and current smoke coverage. [VERIFIED: `falkon/src/lib/agent/agentcommandrouter.cpp`; VERIFIED: `.context/fsb-org/FSB/references/vault-boundary.md`; VERIFIED: `falkon/tools/fsb-baseline/smoke-agent-control.sh`]

**Research date:** 2026-06-17  
**Valid until:** 2026-07-17 for local architecture and validation structure; re-verify earlier if Phase 8 provider APIs or FSB baseline sources change. [VERIFIED: current research date; VERIFIED: local source dependency]
