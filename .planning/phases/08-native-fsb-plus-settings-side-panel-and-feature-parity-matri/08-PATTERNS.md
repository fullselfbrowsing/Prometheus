# Phase 8: Native FSB-Plus Settings Side Panel and Feature Parity Matrix - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `falkon/src/lib/agent/agentruntimesidebar.cpp` (modify) | component | request-response | itself (extend in place) | exact |
| `falkon/src/lib/agent/agentruntimesidebar.h` (modify) | component | request-response | itself (extend in place) | exact |
| `falkon/src/lib/agent/agentruntime.cpp` (modify) | service | CRUD | itself (extend in place) | exact |
| `falkon/src/lib/agent/agentruntime.h` (modify) | service | CRUD | itself (extend in place) | exact |
| `falkon/src/lib/agent/agentcommandrouter.cpp` (modify) | controller | request-response | itself (extend in place) | exact |
| `falkon/src/lib/preferences/preferences.cpp` (modify) | config | CRUD | itself (extend in place) | exact |
| `falkon/tools/fsb-baseline/FSB-PARITY.md` (create) | utility | batch | `falkon/tools/fsb-baseline/README.md` | role-match |
| `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` (create) | utility | batch | `falkon/tools/fsb-baseline/smoke-compact-tabs.sh` | exact |
| `falkon/tools/fsb-baseline/release-validate.sh` (modify) | config | batch | itself (extend in place) | exact |

---

## Pattern Assignments

### `falkon/src/lib/agent/agentruntimesidebar.cpp` + `.h` (component, request-response)

**Analog:** itself — the file already implements the sidebar for Task, Providers, Logs, Memory, Vault; Phase 8 extends it to four modes and wires new sections to the same runtime APIs.

**Current imports pattern** (lines 1-26 of `agentruntimesidebar.cpp`):
```cpp
#include "agentruntimesidebar.h"
#include "agentruntime.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "tabbedwebview.h"

#include <QAction>
#include <QComboBox>
#include <QFormLayout>
#include <QFont>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QIcon>
#include <QJsonArray>
#include <QJsonObject>
#include <QKeySequence>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QTabWidget>
#include <QUrl>
#include <QVBoxLayout>
```

Phase 8 adds `QStackedWidget`, `QListView`, `QSpinBox`, `QCheckBox`, `QDialog`, and `QMessageBox` to this import block. Keep `QTabWidget` only for the four-mode segmented switcher.

**Core widget-constructor pattern** (lines 70-138 of `agentruntimesidebar.cpp`):
```cpp
AgentRuntimeSidebarWidget::AgentRuntimeSidebarWidget(BrowserWindow* window, QWidget* parent)
    : QWidget(parent)
    , m_window(window)
{
    setObjectName(QSL("PrometheusAgentSidebar"));
    setMinimumWidth(300);  // Phase 8: raise to 320px

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(10, 10, 10, 10);
    root->setSpacing(8);

    auto* title = new QLabel(tr("Prometheus"), this);
    // ...
    auto* poweredBy = new QLabel(tr("Powered by FSB"), this);
    // ...
    auto* tabs = new QTabWidget(this);  // Phase 8: replace with QStackedWidget + mode switcher
    tabs->setDocumentMode(true);
    root->addWidget(tabs, 1);

    // ... buildXxxPage(...) calls

    connect(mApp->agentRuntime(), &AgentRuntime::runtimeChanged, this, &AgentRuntimeSidebarWidget::refreshAll);
    refreshAll();
}
```

Phase 8 changes to this constructor:
- Replace `QTabWidget` with a 4-button segmented mode switcher (FSB Agent / Explorer / Tabs / Tools) and a `QStackedWidget` below it.
- `setMinimumWidth(320)` per UI spec.
- Add `buildFsbAgentPage`, `buildExplorerPage`, `buildTabsPage`, `buildToolsPage` in place of current build methods; current Task/Provider/Logs/Memory/Vault build methods move to the FSB Control Panel page (see below).

**Runtime state call pattern** (lines 296-315, 382-403 of `agentruntimesidebar.cpp`):
```cpp
// Calls runtime APIs; widgets do not own state.
const QJsonObject submitted = mApp->agentRuntime()->submitTask(prompt, context, QSL("sidebar"), false);
// ...
const QJsonArray tasks = mApp->agentRuntime()->listTasks(30).value(QSL("tasks")).toArray();
// ...
const QJsonArray providers = mApp->agentRuntime()->providerConfig().value(QSL("providers")).toArray();
```

All new sections follow this same call pattern: call `mApp->agentRuntime()->someApi()`, read the returned `QJsonObject`, populate widgets. Never cache runtime state locally in member variables.

**Secret field clear-after-save pattern** (lines 330-342 of `agentruntimesidebar.cpp`):
```cpp
void AgentRuntimeSidebarWidget::saveProvider()
{
    const QString provider = m_providerCombo->currentData().toString();
    const QJsonObject config{
        {QSL("enabled"), true},
        {QSL("model"), m_providerModel->text()},
        {QSL("endpoint"), m_providerEndpoint->text()},
        {QSL("secret"), m_providerSecret->text()}
    };
    const QJsonObject result = mApp->agentRuntime()->saveProviderConfig(provider, config, true);
    m_providerSecret->clear();  // always clear after save
    m_providerStatus->setText(result.value(QSL("ok")).toBool() ? tr("Saved") : result.value(QSL("message")).toString());
    refreshProvider();
}
```

Apply this pattern to every secret-accepting field in the Phase 8 control panel page (provider key, vault secret). The `allowSecretPayload = true` argument is the native-UI-only gate; MCP/router paths pass `false`.

**Helper button factory** (lines 38-43 of `agentruntimesidebar.cpp`):
```cpp
QPushButton* iconButton(const QString &text, const QString &iconName, QWidget* parent)
{
    auto* button = new QPushButton(QIcon::fromTheme(iconName), text, parent);
    button->setMinimumHeight(30);  // Phase 8: normalize to 32px where touched
    return button;
}
```

Phase 8 normalizes `setMinimumHeight` to 32px in all new/touched buttons.

**H file class member pattern** (lines 27-85 of `agentruntimesidebar.h`):
```cpp
class FALKON_EXPORT AgentRuntimeSidebarWidget : public QWidget
{
    Q_OBJECT
public:
    explicit AgentRuntimeSidebarWidget(BrowserWindow* window, QWidget* parent = nullptr);
private:
    void buildTaskPage(QWidget* page);
    // ... one build method per page/section
    void runTask();
    // ... one slot per action
    void refreshAll();
    // ... one refresh method per data surface
    BrowserWindow* m_window;
    QString m_currentTaskId;
    // ... one pointer per widget that needs runtime updates
};
```

Phase 8 adds corresponding new build/slot/refresh members for FSB Agent, Explorer, Tabs, Tools modes. The control panel page sections (Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix) are built by a new `FsbControlPanelPage` widget class in this same file or a separate `fsbcontrolpanel.{h,cpp}` alongside.

---

### `falkon/src/lib/agent/agentruntime.cpp` + `.h` (service, CRUD)

**Analog:** itself. Phase 8 adds execution-mode metadata to `finishTask`, durable settings reads for agent policy, and a helper to expose parity metadata.

**Provider config save pattern with Settings** (lines 295-334 of `agentruntime.cpp`):
```cpp
QJsonObject AgentRuntime::saveProviderConfig(const QString &provider, const QJsonObject &config, bool allowSecretPayload)
{
    // ...validate, block secret if !allowSecretPayload...
    Settings settings;
    const QString prefix = QSL("PrometheusRuntime/Providers/%1/").arg(normalizedProvider);
    settings.setValue(prefix + QSL("enabled"), config.value(QSL("enabled")).toBool(true));
    settings.setValue(prefix + QSL("model"),   config.value(QSL("model")).toString());
    // ...
    settings.sync();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, ...};
}
```

Phase 8 agent policy settings (agent cap, internal-surface permissions, tab ownership enforcement, visual feedback, telemetry, vault boundaries, supervision pairing) follow this exact `Settings settings; settings.setValue(prefix + key, value); settings.sync();` pattern. Use the key group `PrometheusRuntime/Policy/`.

**QSaveFile JSON persistence pattern** (lines 581-590 of `agentruntime.cpp`):
```cpp
bool AgentRuntime::writeJsonArray(const QString &fileName, const QJsonArray &array) const
{
    QSaveFile file(runtimeDir() + QLatin1Char('/') + fileName);
    if (!file.open(QIODevice::WriteOnly)) {
        return false;
    }
    file.write(QJsonDocument(array).toJson());
    return file.commit();
}
```

Any new runtime JSON persistence (e.g., parity row cache, permission rules) uses `QSaveFile` and `file.commit()` — never direct `QFile` overwrite.

**Secret store/read pattern** (lines 624+, 689+ of `agentruntime.cpp`):
```cpp
bool AgentRuntime::storeSecret(const QString &account, const QString &secret, QString* errorMessage) const;
bool AgentRuntime::hasSecret(const QString &account) const;
```

Phase 8 never adds a new secret storage mechanism. All native secret paths go through these two existing helpers. Vault and provider UI both use `saveVaultSecret(..., secret, ...)` or `saveProviderConfig(..., config-with-secret, allowSecretPayload=true)`.

**Task metrics shape for execution-mode** (lines 157-181 of `agentruntime.cpp`, to be extended):
```cpp
// Current finishTask metrics shape:
{QSL("estimatedCostUsd"), 0.0}, {QSL("modelRequests"), 0}, {QSL("browserActions"), 0}

// Phase 8 adds execution mode fields to metrics:
{QSL("executionMode"), providerReady ? QSL("provider") : QSL("local")},
{QSL("provider"), selectedProvider},
{QSL("model"), selectedModel},
{QSL("providerAvailable"), providerReady},
{QSL("unavailableReason"), providerReady ? QString() : QSL("provider_not_configured")}
```

**AgentRuntime.h API extension pattern** (lines 14-66 of `agentruntime.h`):
```cpp
// All public methods return QJsonObject with ok/error envelope.
QJsonObject submitTask(const QString &prompt, const QJsonObject &context, const QString &source, bool autoRun);
QJsonObject markTaskRunning(const QString &taskId, const QString &message);
QJsonObject finishTask(const QString &taskId, const QString &finalResult, const QJsonObject &metrics = QJsonObject());
// ...
Q_SIGNALS:
    void runtimeChanged();  // always emit after any state mutation
```

Phase 8 new AgentRuntime methods follow this signature convention: return `QJsonObject`, accept typed params, emit `runtimeChanged()` if state changed.

---

### `falkon/src/lib/agent/agentcommandrouter.cpp` (controller, request-response)

**Analog:** itself. Phase 8 extends the router with settings-policy reads, MCP status observation, and execution-mode routing.

**Route dispatch pattern** (lines 113-219 of `agentcommandrouter.cpp`):
```cpp
QJsonObject AgentCommandRouter::routeForSession(const QJsonObject &request, const QString &sessionKey)
{
    const QString tool = request.value(QSL("tool")).toString();
    // ...
    if (tool == QL1S("diagnostics") || tool == QL1S("get_diagnostics")) {
        return routeDiagnostics(id, tool, params, 0);
    }
    // ... one if-block per tool or tool family
    return failure(id, tool, QSL("unsupported_tool"), QSL("Unsupported agent tool."), 0);
}
```

Phase 8 adds route branches for `get_mcp_status`, `get_agent_policy`, `set_agent_policy`, and `get_parity_status` following this identical dispatch pattern. Each new route method signature must match: `QJsonObject routeXxx(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)`.

**Health tools array extension** (lines 394-428 of `agentcommandrouter.cpp`):
```cpp
{QSL("tools"), QJsonArray{
    QSL("list_tabs"),
    // ... full list ...
    QSL("end_supervision_session")
}}
```

Phase 8 appends new tool names here in the same order they appear in the route dispatch block. The parity smoke gate checks this array against `server.mjs` and the router routing branches.

**Success/failure response shape** (lines 431-468 of `agentcommandrouter.cpp`):
```cpp
// success:
return QJsonObject{
    {QSL("ok"), true},
    {QSL("id"), id},
    {QSL("tool"), tool},
    {QSL("result"), result},
    {QSL("audit"), QJsonObject{{QSL("sequence"), static_cast<qint64>(successAuditSequence)}}}
};
// failure:
return QJsonObject{
    {QSL("ok"), false},
    {QSL("id"), id},
    {QSL("tool"), tool},
    {QSL("error"), QJsonObject{{QSL("code"), code}, {QSL("message"), message}}}
};
```

Every new route method uses `success(id, tool, result, auditSequence)` or `failure(id, tool, code, message, auditSequence)`. Never construct these envelopes inline.

**Agent cap and ownership enforcement** (lines 1580-1630 of `agentcommandrouter.cpp`):
```cpp
if (m_agentIds.size() >= m_agentCap) {
    *errorCode = QSL("AGENT_CAP_REACHED");
    *errorMessage = QSL("The configured concurrent agent cap has been reached.");
    return QString();
}
// ...
if (owner != *agentId) {
    *errorCode = QSL("TAB_OWNED_BY_OTHER_AGENT");
    *errorMessage = QSL("Target tab is owned by another agent.");
    setTabChromeFailure(target, QSL("ownership"), *errorMessage);
    return false;
}
```

Phase 8 replaces the `qgetenv("PROMETHEUS_AGENT_CAP")` read at constructor time (lines 72-74) with a `Settings` read from `PrometheusRuntime/Policy/agentCap` falling back to the current default of 4. The typed error codes `AGENT_CAP_REACHED` and `TAB_OWNED_BY_OTHER_AGENT` remain unchanged.

**SECRET_TRANSPORT_BLOCKED pattern** (from `agentruntime.cpp` lines 302-303):
```cpp
if (!allowSecretPayload && config.contains(QSL("secret"))) {
    return errorObject(QSL("SECRET_TRANSPORT_BLOCKED"), QSL("Provider secrets can only be stored from the native Prometheus UI."));
}
```

Phase 8 must preserve this check. Do not add any new route that accepts raw secret values.

---

### `falkon/src/lib/preferences/preferences.cpp` + `preferences.ui` (config, CRUD)

**Analog:** itself. Phase 8 adds a new "Prometheus" tab or section to the preferences dialog.

**Settings load pattern** (lines 140-272 of `preferences.cpp`, representative excerpt):
```cpp
void Preferences::loadSettings()
{
    Settings settings;
    settings.beginGroup(QSL("Web-URL-Settings"));
    m_homepage = settings.value(QSL("homepage"), QUrl(QSL("falkon:start"))).toUrl();
    // ...
    settings.endGroup();

    settings.beginGroup(QSL("Browser-View-Settings"));
    ui->showStatusbar->setChecked(settings.value(QSL("showStatusBar"), false).toBool());
    // ...
    settings.endGroup();
}
```

Phase 8 adds a corresponding block to `loadSettings`:
```cpp
settings.beginGroup(QSL("PrometheusRuntime/Policy"));
ui->agentCapSpin->setValue(settings.value(QSL("agentCap"), 4).toInt());
ui->internalSurfaceCheck->setChecked(settings.value(QSL("internalSurfaceControl"), false).toBool());
ui->tabOwnershipCheck->setChecked(settings.value(QSL("tabOwnershipEnforcement"), true).toBool());
ui->visualFeedbackCheck->setChecked(settings.value(QSL("visualFeedback"), true).toBool());
ui->telemetryCombo->setCurrentIndex(settings.value(QSL("telemetry"), 0).toInt()); // 0 = Local only
ui->supervisionPairingCheck->setChecked(settings.value(QSL("supervisionPairing"), false).toBool());
settings.endGroup();
```

**Settings save pattern** (lines 1048-1200 of `preferences.cpp`, representative excerpt):
```cpp
void Preferences::saveSettings()
{
    Settings settings;
    settings.beginGroup(QSL("Web-Browser-Settings"));
    settings.setValue(QSL("allowPlugins"), ui->allowPlugins->isChecked());
    // ...
    settings.endGroup();
}
```

Phase 8 adds a corresponding block to `saveSettings`:
```cpp
settings.beginGroup(QSL("PrometheusRuntime/Policy"));
settings.setValue(QSL("agentCap"), ui->agentCapSpin->value());
settings.setValue(QSL("internalSurfaceControl"), ui->internalSurfaceCheck->isChecked());
settings.setValue(QSL("tabOwnershipEnforcement"), ui->tabOwnershipCheck->isChecked());
settings.setValue(QSL("visualFeedback"), ui->visualFeedbackCheck->isChecked());
settings.setValue(QSL("telemetry"), ui->telemetryCombo->currentIndex());
settings.setValue(QSL("supervisionPairing"), ui->supervisionPairingCheck->isChecked());
settings.endGroup();
```

The `settings.beginGroup / endGroup` bracket is mandatory. All new keys live under `PrometheusRuntime/Policy/` to match the group AgentRuntime and AgentCommandRouter already use.

---

### `falkon/tools/fsb-baseline/FSB-PARITY.md` (utility artifact, batch)

**Analog:** `falkon/tools/fsb-baseline/README.md` for file location convention; the matrix structure is defined by RESEARCH.md Pattern 3.

**Required matrix structure** (from RESEARCH.md Pattern 3):
```markdown
| Category | FSB Baseline | Prometheus Native Equivalent | Status | Native Improvement | Validation |
|----------|--------------|------------------------------|--------|--------------------|------------|
| Vault | Metadata list + extension-mediated fill; raw secrets do not cross MCP | Native vault metadata plus native-only confirmation boundary | Native-improved | Keychain/native confirmation; MCP secret rejection | `tools/fsb-baseline/smoke-agent-control.sh` + `smoke-fsb-plus-parity.sh` |
```

Required category rows (from UI-SPEC.md parity matrix section):

side panel, provider settings, model discovery, fallback routing, MCP tools, DOM snapshots, page snapshots, read tools, action tools, smart waiting, stuck detection, visual feedback, memory, site guides, vault, remote dashboard pairing, supervision DOM mirror, tab ownership, tab groups/state, diagnostics, logs/action history, cost/token accounting, telemetry controls, internal settings control, release validation.

Status values must be exactly: `Missing`, `Partial`, `Parity`, `Better`, or `Verified`. `Better` requires a native improvement target and validation command. `Verified` requires evidence path and passing command.

---

### `falkon/tools/fsb-baseline/smoke-fsb-plus-parity.sh` (utility, batch)

**Analog:** `falkon/tools/fsb-baseline/smoke-compact-tabs.sh` — copy its entire shell structure including `set -euo pipefail`, `SCRIPT_DIR`/`SOURCE_ROOT` derivation, `--binary` / `--port` / `--help` argument parsing, `require_rg` static-check helper, `run_static_checks()` function, the binary-absent early exit, bearer-token acquisition, `post_command`, `require_ok`, `require_error_code`, and `json_field` helpers.

**Shell header and script boilerplate** (lines 1-50 of `smoke-compact-tabs.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BINARY=""
BINARY_PROVIDED="false"
PORT="${PROMETHEUS_AGENT_PORT:-17887}"  # Phase 8: use 17888 to avoid collisions
PROFILE="compact-tabs-smoke-$$"
AUTH_TOKEN=""

usage() { cat <<'USAGE'
Usage: smoke-fsb-plus-parity.sh [--binary PATH] [--port PORT] [--matrix-only]
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --binary) BINARY="${2:-}"; BINARY_PROVIDED="true"; shift 2 ;;
    --port)   PORT="${2:-}"; shift 2 ;;
    --matrix-only) MATRIX_ONLY="true"; shift ;;  # Phase 8: static-only flag
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
```

**Static check helper pattern** (lines 51-87 of `smoke-compact-tabs.sh`):
```bash
require_rg() {
  local pattern="$1"
  shift
  if ! rg --quiet "$pattern" "$@"; then
    printf 'Missing required pattern %s in %s\n' "$pattern" "$*" >&2
    exit 1
  fi
}

run_static_checks() {
  command -v rg >/dev/null 2>&1 || { printf 'rg is required.\n' >&2; exit 1; }

  require_rg 'TabGroupIdRole|...' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"
}
```

Phase 8 static checks for `smoke-fsb-plus-parity.sh` follow this identical `require_rg` function and `run_static_checks` structure:
```bash
run_static_checks() {
  command -v rg >/dev/null 2>&1 || { printf 'rg is required.\n' >&2; exit 1; }

  # Required parity matrix rows
  require_rg 'FSBP-01|FSBP-02|FSBP-03|FSBP-04|FSBP-05|FSBP-06' \
    "${SOURCE_ROOT}/tools/fsb-baseline/FSB-PARITY.md"

  # Required matrix categories
  for category in 'side panel' 'provider settings' 'model discovery' 'MCP tools' \
                  'vault' 'supervision' 'tab ownership' 'release validation'; do
    require_rg "$category" "${SOURCE_ROOT}/tools/fsb-baseline/FSB-PARITY.md"
  done

  # Secret transport enforcement in router
  require_rg 'SECRET_TRANSPORT_BLOCKED' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp" \
    "${SOURCE_ROOT}/src/lib/agent/agentruntime.cpp"

  # Parity gate invoked from release-validate.sh
  require_rg 'smoke-fsb-plus-parity' \
    "${SOURCE_ROOT}/tools/fsb-baseline/release-validate.sh"

  # Agent cap read from Settings (not only from environment)
  require_rg 'PrometheusRuntime/Policy/agentCap' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"
}
```

**Binary-absent early exit pattern** (lines 196-204 of `smoke-compact-tabs.sh`):
```bash
if [ -z "$BINARY" ] || [ ! -x "$BINARY" ]; then
  if [ "$BINARY_PROVIDED" = "true" ]; then
    printf 'No executable Prometheus binary found at %s.\n' "$BINARY" >&2
    exit 1
  fi
  printf 'No executable Prometheus binary found; skipped live parity smoke.\n'
  exit 0
fi
```

Copy this exactly: static checks always run; live router checks are skipped if no binary is found and `--binary` was not explicitly passed.

**Bearer token acquisition** (lines 236-242 of `smoke-compact-tabs.sh`):
```bash
HEALTH=""
for _ in $(seq 1 80); do
  if HEALTH="$(curl -fsS "http://127.0.0.1:${PORT}/health" 2>/dev/null)"; then
    break
  fi
  sleep 0.25
done
require_ok "$HEALTH"
AUTH_TOKEN="$(json_field "$HEALTH" "authorization.token")"
```

**post_command helper** (lines 188-194 of `smoke-compact-tabs.sh`):
```bash
post_command() {
  curl -fsS \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "http://127.0.0.1:${PORT}/agent/command" \
    --data "$1"
}
```

---

### `falkon/tools/fsb-baseline/release-validate.sh` (config, batch)

**Analog:** itself. Phase 8 inserts the parity gate into the existing validation chain.

**Gate insertion point** (lines 50-70 of `release-validate.sh`):
```bash
node --check "${SOURCE_ROOT}/tools/prometheus-mcp/server.mjs"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-agent-control.sh"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-compact-tabs.sh"
# Phase 8: add here
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-fsb-plus-parity.sh"

cmake --build "$BUILD_DIR"

"${SOURCE_ROOT}/tools/fsb-baseline/smoke-agent-control.sh" --binary "$BINARY" --port 17885
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-mcp-bridge.sh"    --binary "$BINARY" --port 17886
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-compact-tabs.sh"  --binary "$BINARY" --port 17887
# Phase 8: add after compact tabs smoke
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-fsb-plus-parity.sh" --binary "$BINARY" --port 17888
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-browser.sh" --binary "$BINARY" --wait 1
```

The syntax check (`bash -n`) runs before the build; the live invocation runs after the build and after the compact-tab smoke. Use port 17888 to avoid collision with existing smokes.

---

## Shared Patterns

### Pattern A: Runtime Owns State, Widgets Only Render

**Source:** `falkon/src/lib/agent/agentruntimesidebar.cpp` lines 382-468
**Apply to:** all new side panel mode pages, all FSB Control Panel sections

```cpp
// Correct: call runtime API, iterate returned JSON, populate list widget
const QJsonArray tasks = mApp->agentRuntime()->listTasks(30).value(QSL("tasks")).toArray();
for (const QJsonValue &value : tasks) {
    const QJsonObject task = value.toObject();
    m_taskList->addItem(task.value(QSL("status")).toString() + ...);
}

// Wrong: do NOT copy task/provider/vault/memory arrays into member variables
// Wrong: do NOT create a separate QTimer to poll runtime outside of runtimeChanged signal
```

Connect once to `mApp->agentRuntime()->runtimeChanged()` at widget construction; call `refreshAll()` from the slot.

### Pattern B: Native-Only Secret Save, Metadata-Only Read

**Source:** `falkon/src/lib/agent/agentruntime.cpp` lines 295-334; `falkon/src/lib/agent/agentcommandrouter.cpp` lines 1160-1163
**Apply to:** provider save, vault save, any new secret-bearing field

```cpp
// Save path (native UI only, allowSecretPayload = true):
const QJsonObject result = mApp->agentRuntime()->saveProviderConfig(provider, configWithSecret, true);
m_providerSecret->clear();  // always clear

// Read path (never returns raw secret):
const QJsonObject config = mApp->agentRuntime()->providerConfig();
const bool hasKey = config.value(QSL("providers")).toArray()
    .first().toObject().value(QSL("secretConfigured")).toBool();
```

### Pattern C: Settings beginGroup / setValue / endGroup

**Source:** `falkon/src/lib/preferences/preferences.cpp` lines 140-272 (load) and 1048-1200 (save)
**Apply to:** all Phase 8 durable settings for agent cap, permissions, visual feedback, telemetry, vault boundaries, supervision pairing

```cpp
Settings settings;
settings.beginGroup(QSL("PrometheusRuntime/Policy"));
settings.setValue(QSL("agentCap"), value);
settings.endGroup();
// Always use endGroup. Never call settings.sync() from preferences.cpp;
// AgentRuntime.saveProviderConfig calls settings.sync() for runtime group.
```

### Pattern D: Typed Error Codes

**Source:** `falkon/src/lib/agent/agentcommandrouter.cpp` lines 1591-1628
**Apply to:** all new route methods in `agentcommandrouter.cpp`

Preserve and extend existing typed codes:
- `SECRET_TRANSPORT_BLOCKED` — secret value arrived over MCP/remote
- `VAULT_NATIVE_CONFIRMATION_REQUIRED` — autofill attempted over remote
- `AGENT_CAP_REACHED` — concurrent agent limit hit
- `TAB_OWNED_BY_OTHER_AGENT` — ownership conflict
- `STALE_SUPERVISION_SESSION` — session expired or unknown
- `SUPERVISION_TARGET_MISMATCH` — session belongs to different tab

Phase 8 new codes to add:
- `PERMISSION_BLOCKED` — internal-surface action blocked by policy setting
- `PROVIDER_NOT_CONFIGURED` — provider-backed execution attempted without key/endpoint

### Pattern E: require_rg Static Check

**Source:** `falkon/tools/fsb-baseline/smoke-compact-tabs.sh` lines 51-87
**Apply to:** `smoke-fsb-plus-parity.sh` static checks section

```bash
require_rg() {
  local pattern="$1"
  shift
  if ! rg --quiet "$pattern" "$@"; then
    printf 'Missing required pattern %s in %s\n' "$pattern" "$*" >&2
    exit 1
  fi
}
```

Copy this function verbatim into `smoke-fsb-plus-parity.sh`.

### Pattern F: QSaveFile Atomic Write

**Source:** `falkon/src/lib/agent/agentruntime.cpp` lines 581-590
**Apply to:** any new JSON persistence in `agentruntime.cpp` (parity row cache, permission rule files)

```cpp
bool AgentRuntime::writeJsonArray(const QString &fileName, const QJsonArray &array) const
{
    QSaveFile file(runtimeDir() + QLatin1Char('/') + fileName);
    if (!file.open(QIODevice::WriteOnly)) {
        return false;
    }
    file.write(QJsonDocument(array).toJson());
    return file.commit();
}
```

Reuse this existing helper. Never add a direct `QFile::open / write / close` for runtime JSON.

---

## No Analog Found

All nine files have close in-tree analogs. No files require falling back to RESEARCH.md patterns alone.

---

## Metadata

**Analog search scope:** `falkon/src/lib/agent/`, `falkon/src/lib/preferences/`, `falkon/tools/fsb-baseline/`, `falkon/autotests/`
**Files scanned:** 13 source files read in full or in targeted sections
**Pattern extraction date:** 2026-06-16
