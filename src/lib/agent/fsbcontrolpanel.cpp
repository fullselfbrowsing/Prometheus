#include "fsbcontrolpanel.h"

#include "agentcommandrouter.h"
#include "agentruntime.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "prometheusiconresolver.h"
#include "qzsettings.h"
#include "settings.h"
#include "tabbedwebview.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QFormLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProcess>
#include <QPushButton>
#include <QSize>
#include <QSpinBox>
#include <QStackedWidget>
#include <QTableWidget>
#include <QTableWidgetItem>
#include <QTimer>
#include <QUrl>
#include <QVBoxLayout>
#include <QVector>

namespace {

// Returns the SOURCE_ROOT directory where tools/fsb-baseline lives.
// We locate it relative to the application executable.
QString sourceRoot()
{
    // The parity file is at <SOURCE_ROOT>/tools/fsb-baseline/FSB-PARITY.md.
    // When running from a build tree the executable is typically two levels
    // below the source root: build/fsb-baseline/bin/prometheus.
    // Try walking up from the app dir until we find the tools/fsb-baseline dir.
    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 6; ++i) {
        if (QFileInfo(dir, QSL("tools/fsb-baseline/FSB-PARITY.md")).exists()) {
            return dir.absolutePath();
        }
        if (!dir.cdUp()) {
            break;
        }
    }
    // Fallback: return the directory two levels above the executable.
    QDir root(QCoreApplication::applicationDirPath());
    root.cdUp();
    root.cdUp();
    return root.absolutePath();
}

QString parityMatrixPath()
{
    return sourceRoot() + QSL("/tools/fsb-baseline/FSB-PARITY.md");
}

QString smokeScriptPath()
{
    return sourceRoot() + QSL("/tools/fsb-baseline/smoke-fsb-plus-parity.sh");
}

QGroupBox* makeControlCard(const QString &title, QWidget* parent)
{
    auto* group = new QGroupBox(title, parent);
    group->setProperty("pm-control-card", true);
    return group;
}

QLabel* makeHelpText(const QString &text, QWidget* parent)
{
    auto* label = new QLabel(text, parent);
    label->setObjectName(QSL("controlHelpText"));
    label->setWordWrap(true);
    return label;
}

QPushButton* makeActionButton(const QString &actionId, const QString &text, QWidget* parent)
{
    auto* button = new QPushButton(PrometheusIconResolver::icon(actionId), text, parent);
    button->setMinimumHeight(32);
    button->setIconSize(QSize(14, 14));
    return button;
}

void setComboToData(QComboBox* combo, const QString &value)
{
    const int index = combo->findData(value);
    combo->setCurrentIndex(index >= 0 ? index : 0);
}

} // namespace

FsbControlPanelPage::FsbControlPanelPage(BrowserWindow* window, QWidget* parent)
    : QWidget(parent)
    , m_window(window)
    , m_sectionStack(nullptr)
    , m_sectionRail(nullptr)
    , m_mcpChip(nullptr)
    , m_agentsChip(nullptr)
    , m_vaultChip(nullptr)
    , m_supervisionChip(nullptr)
    , m_taskPrompt(nullptr)
    , m_taskList(nullptr)
    , m_providerList(nullptr)
    , m_providerEnabled(nullptr)
    , m_providerModel(nullptr)
    , m_providerEndpoint(nullptr)
    , m_providerSecret(nullptr)
    , m_providerSecretState(nullptr)
    , m_modelList(nullptr)
    , m_fallbackOrderList(nullptr)
    , m_mcpTable(nullptr)
    , m_mcpEmptyState(nullptr)
    , m_permissionsTable(nullptr)
    , m_agentCapSpin(nullptr)
    , m_internalSurfaceCheck(nullptr)
    , m_tabOwnershipCheck(nullptr)
    , m_backgroundTabActionsCheck(nullptr)
    , m_visualFeedbackCheck(nullptr)
    , m_supervisionPairingCheck(nullptr)
    , m_dashboardRemoteCheck(nullptr)
    , m_telemetryCombo(nullptr)
    , m_vaultList(nullptr)
    , m_vaultOrigin(nullptr)
    , m_vaultLabel(nullptr)
    , m_vaultSecret(nullptr)
    , m_vaultAutofill(nullptr)
    , m_memoryList(nullptr)
    , m_memoryKey(nullptr)
    , m_memoryText(nullptr)
    , m_siteGuideList(nullptr)
    , m_siteOrigin(nullptr)
    , m_siteGuideText(nullptr)
    , m_logFilter(nullptr)
    , m_logView(nullptr)
    , m_diagGroupList(nullptr)
    , m_pairingCode(nullptr)
    , m_sessionId(nullptr)
    , m_sessionTarget(nullptr)
    , m_sessionExpiry(nullptr)
    , m_supervisionStatus(nullptr)
    , m_parityTable(nullptr)
    , m_parityOutput(nullptr)
{
    setObjectName(QSL("FsbControlPanelPage"));
    setMinimumSize(320, 400);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(12, 12, 12, 12);
    root->setSpacing(12);

    // Header: 48px band
    auto* headerWidget = new QWidget(this);
    headerWidget->setObjectName(QSL("FsbControlPanelHeader"));
    headerWidget->setFixedHeight(56);
    auto* headerLayout = new QHBoxLayout(headerWidget);
    headerLayout->setContentsMargins(0, 0, 0, 0);
    headerLayout->setSpacing(8);

    auto* titleLabel = new QLabel(tr("Prometheus"), headerWidget);
    QFont displayFont = titleLabel->font();
    displayFont.setPointSize(displayFont.pointSize() + 3);
    displayFont.setBold(true);
    titleLabel->setFont(displayFont);
    titleLabel->setObjectName(QSL("FsbControlPanelTitle"));

    auto* taglineLabel = new QLabel(tr("Powered by FSB"), headerWidget);
    taglineLabel->setObjectName(QSL("FsbControlPanelTagline"));

    headerLayout->addWidget(titleLabel);
    headerLayout->addWidget(taglineLabel);
    headerLayout->addStretch();

    m_mcpChip = new QLabel(tr("MCP: —"), headerWidget);
    m_mcpChip->setObjectName(QSL("statusChip"));
    m_agentsChip = new QLabel(tr("Agents: 0/4"), headerWidget);
    m_agentsChip->setObjectName(QSL("statusChip"));
    m_vaultChip = new QLabel(tr("Vault: Native-only"), headerWidget);
    m_vaultChip->setObjectName(QSL("statusChip"));
    m_supervisionChip = new QLabel(tr("Supervision: Unpaired"), headerWidget);
    m_supervisionChip->setObjectName(QSL("statusChip"));

    headerLayout->addWidget(m_mcpChip);
    headerLayout->addWidget(m_agentsChip);
    headerLayout->addWidget(m_vaultChip);
    headerLayout->addWidget(m_supervisionChip);

    root->addWidget(headerWidget);

    // Main content: section rail + stacked pages
    auto* contentLayout = new QHBoxLayout;
    contentLayout->setSpacing(12);
    contentLayout->setContentsMargins(0, 0, 0, 0);

    // Section selector rail.
    m_sectionRail = new QListWidget(this);
    m_sectionRail->setFixedWidth(188);
    m_sectionRail->setObjectName(QSL("sectionRail"));

    struct SectionDef {
        QString title;
        QString icon;
    };
    const QVector<SectionDef> sections = {
        { tr("Dashboard"), QSL("agent-fsb") },
        { tr("Providers & Models"), QSL("provider-model") },
        { tr("MCP Status"), QSL("mcp-connected") },
        { tr("Permissions & Agents"), QSL("settings-permissions") },
        { tr("Vault"), QSL("vault-open") },
        { tr("Memory & Site Guides"), QSL("tool-reader") },
        { tr("Logs & Diagnostics"), QSL("diag-log") },
        { tr("Supervision & Pairing"), QSL("supervision-pair") },
        { tr("Parity Matrix"), QSL("tab-overview") },
        { tr("Browser Settings"), QSL("settings-appearance") }
    };
    for (const SectionDef &section : sections) {
        auto* item = new QListWidgetItem(PrometheusIconResolver::icon(section.icon), section.title);
        item->setSizeHint(QSize(item->sizeHint().width(), 38));
        m_sectionRail->addItem(item);
    }

    m_sectionStack = new QStackedWidget(this);

    // Build all nine section pages
    auto* tasksPage = new QWidget(m_sectionStack);
    buildTasksSection(tasksPage);
    m_sectionStack->addWidget(tasksPage);

    auto* providersPage = new QWidget(m_sectionStack);
    buildProvidersSection(providersPage);
    m_sectionStack->addWidget(providersPage);

    auto* mcpPage = new QWidget(m_sectionStack);
    buildMcpStatusSection(mcpPage);
    m_sectionStack->addWidget(mcpPage);

    auto* permissionsPage = new QWidget(m_sectionStack);
    buildPermissionsSection(permissionsPage);
    m_sectionStack->addWidget(permissionsPage);

    auto* vaultPage = new QWidget(m_sectionStack);
    buildVaultSection(vaultPage);
    m_sectionStack->addWidget(vaultPage);

    auto* memoryPage = new QWidget(m_sectionStack);
    buildMemorySiteGuidesSection(memoryPage);
    m_sectionStack->addWidget(memoryPage);

    auto* logsPage = new QWidget(m_sectionStack);
    buildLogsDiagnosticsSection(logsPage);
    m_sectionStack->addWidget(logsPage);

    auto* supervisionPage = new QWidget(m_sectionStack);
    buildSupervisionSection(supervisionPage);
    m_sectionStack->addWidget(supervisionPage);

    auto* parityPage = new QWidget(m_sectionStack);
    buildParityMatrixSection(parityPage);
    m_sectionStack->addWidget(parityPage);

    auto* appearancePage = new QWidget(m_sectionStack);
    buildAppearanceSection(appearancePage);
    m_sectionStack->addWidget(appearancePage);

    connect(m_sectionRail, &QListWidget::currentRowChanged, m_sectionStack, &QStackedWidget::setCurrentIndex);
    m_sectionRail->setCurrentRow(0);

    contentLayout->addWidget(m_sectionRail);
    contentLayout->addWidget(m_sectionStack, 1);
    root->addLayout(contentLayout, 1);

    // Connect runtime signals
    if (mApp && mApp->agentRuntime()) {
        connect(mApp->agentRuntime(), &AgentRuntime::runtimeChanged, this, &FsbControlPanelPage::refreshAll);
    }

    // Initial population
    QTimer::singleShot(0, this, &FsbControlPanelPage::refreshAll);
}

void FsbControlPanelPage::showSettingsSection()
{
    if (m_sectionRail) {
        m_sectionRail->setCurrentRow(9);
    }
}

// ---------------------------------------------------------------------------
// Section builders
// ---------------------------------------------------------------------------

void FsbControlPanelPage::buildTasksSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Dashboard"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Prompt editor 96px fixed
    m_taskPrompt = new QPlainTextEdit(page);
    m_taskPrompt->setPlaceholderText(tr("Ask Prometheus to work in this browser…"));
    m_taskPrompt->setFixedHeight(96);
    layout->addWidget(m_taskPrompt);

    // Action row
    auto* actionRow = new QHBoxLayout;
    actionRow->setSpacing(8);

    auto* runBtn = makeActionButton(QSL("agent-send"), tr("Run Task"), page);
    runBtn->setProperty("accent", true);
    connect(runBtn, &QPushButton::clicked, this, &FsbControlPanelPage::runTask);

    auto* cancelBtn = makeActionButton(QSL("agent-stop-task"), tr("Cancel Task"), page);
    cancelBtn->setProperty("destructive", true);
    connect(cancelBtn, &QPushButton::clicked, this, &FsbControlPanelPage::cancelTask);

    actionRow->addWidget(runBtn);
    actionRow->addWidget(cancelBtn);
    layout->addLayout(actionRow);

    // Task list
    m_taskList = new QListWidget(page);
    m_taskList->setMinimumHeight(32);
    layout->addWidget(m_taskList, 1);

    // Empty state
    auto* emptyState = new QLabel(page);
    emptyState->setObjectName(QSL("emptyStateBody"));
    emptyState->setWordWrap(true);
    emptyState->setText(tr("Ask Prometheus to work in this browser. Tasks will appear here with progress, cost, and final result."));
    layout->addWidget(emptyState);
    emptyState->setVisible(false);
}

void FsbControlPanelPage::buildProvidersSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Providers & Models"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Provider list
    m_providerList = new QListWidget(page);
    m_providerList->setMinimumHeight(80);
    layout->addWidget(m_providerList);

    // Detail form
    auto* formWidget = new QWidget(page);
    auto* form = new QFormLayout(formWidget);
    form->setContentsMargins(0, 0, 0, 0);
    form->setSpacing(4);

    m_providerEnabled = new QCheckBox(page);
    form->addRow(tr("Enabled"), m_providerEnabled);

    m_providerModel = new QLineEdit(page);
    m_providerModel->setPlaceholderText(tr("Model name"));
    form->addRow(tr("Model"), m_providerModel);

    m_providerEndpoint = new QLineEdit(page);
    m_providerEndpoint->setPlaceholderText(tr("API endpoint URL"));
    form->addRow(tr("Endpoint"), m_providerEndpoint);

    // Key field: password echo mode; cleared after save
    m_providerSecret = new QLineEdit(page);
    m_providerSecret->setEchoMode(QLineEdit::Password);
    m_providerSecret->setPlaceholderText(tr("Paste key to save…"));
    form->addRow(tr("Key"), m_providerSecret);

    m_providerSecretState = new QLabel(tr("No key saved"), page);
    m_providerSecretState->setObjectName(QSL("secretStateLabel"));
    form->addRow(QString(), m_providerSecretState);

    layout->addWidget(formWidget);

    auto* btnRow = new QHBoxLayout;
    btnRow->setSpacing(8);

    auto* saveBtn = makeActionButton(QSL("provider-key"), tr("Save Provider"), page);
    connect(saveBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveProvider);

    auto* discoverBtn = makeActionButton(QSL("provider-model"), tr("Discover Models"), page);
    discoverBtn->setProperty("accent", true);
    connect(discoverBtn, &QPushButton::clicked, this, &FsbControlPanelPage::discoverModels);

    btnRow->addWidget(saveBtn);
    btnRow->addWidget(discoverBtn);
    layout->addLayout(btnRow);

    // Discovered model list
    auto* modelLabel = new QLabel(tr("Discovered models"), page);
    modelLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(modelLabel);

    m_modelList = new QListWidget(page);
    layout->addWidget(m_modelList);

    // Fallback order
    auto* fallbackLabel = new QLabel(tr("Fallback order"), page);
    fallbackLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(fallbackLabel);

    m_fallbackOrderList = new QListWidget(page);
    layout->addWidget(m_fallbackOrderList, 1);

    auto* saveFallbacks = makeActionButton(QSL("settings-general"), tr("Save Fallbacks"), page);
    layout->addWidget(saveFallbacks);
}

void FsbControlPanelPage::buildMcpStatusSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("MCP Status"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    m_mcpEmptyState = new QLabel(page);
    m_mcpEmptyState->setObjectName(QSL("emptyStateBody"));
    m_mcpEmptyState->setWordWrap(true);
    m_mcpEmptyState->setText(tr("MCP bridge offline. Start Prometheus with the native agent server enabled, then refresh diagnostics."));
    layout->addWidget(m_mcpEmptyState);

    m_mcpTable = new QTableWidget(0, 2, page);
    m_mcpTable->setHorizontalHeaderLabels({tr("Key"), tr("Value")});
    m_mcpTable->horizontalHeader()->setStretchLastSection(true);
    m_mcpTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_mcpTable->setSelectionBehavior(QAbstractItemView::SelectRows);
    layout->addWidget(m_mcpTable, 1);

    auto* refreshBtn = makeActionButton(QSL("diag-health"), tr("Refresh Diagnostics"), page);
    connect(refreshBtn, &QPushButton::clicked, this, &FsbControlPanelPage::refreshDiagnostics);
    layout->addWidget(refreshBtn);
}

void FsbControlPanelPage::buildPermissionsSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(12);

    auto* sectionTitle = new QLabel(tr("Permissions & Agents"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    auto* policyCard = makeControlCard(tr("Agent Policy"), page);
    auto* policyLayout = new QVBoxLayout(policyCard);
    policyLayout->setContentsMargins(14, 18, 14, 14);
    policyLayout->setSpacing(8);

    policyLayout->addWidget(makeHelpText(
        tr("These controls are part of the Prometheus control panel so agent permissions, browser UI, and FSB operation stay in one surface."),
        policyCard));

    m_internalSurfaceCheck = new QCheckBox(tr("Allow agents to open internal Prometheus surfaces"), policyCard);
    m_tabOwnershipCheck = new QCheckBox(tr("Enforce tab ownership before agent actions"), policyCard);
    m_backgroundTabActionsCheck = new QCheckBox(tr("Allow background-tab actions"), policyCard);
    m_visualFeedbackCheck = new QCheckBox(tr("Show visual feedback during agent actions"), policyCard);
    m_supervisionPairingCheck = new QCheckBox(tr("Allow supervision pairing"), policyCard);
    m_dashboardRemoteCheck = new QCheckBox(tr("Allow dashboard remote control"), policyCard);

    Settings policySettings;
    policySettings.beginGroup(QSL("PrometheusRuntime/Policy"));
    m_internalSurfaceCheck->setChecked(policySettings.value(QSL("internalSurfaceControl"), true).toBool());
    m_tabOwnershipCheck->setChecked(policySettings.value(QSL("tabOwnershipEnforcement"), true).toBool());
    m_backgroundTabActionsCheck->setChecked(policySettings.value(QSL("backgroundTabActions"), true).toBool());
    m_visualFeedbackCheck->setChecked(policySettings.value(QSL("visualFeedback"), true).toBool());
    m_supervisionPairingCheck->setChecked(policySettings.value(QSL("supervisionPairing"), true).toBool());
    m_dashboardRemoteCheck->setChecked(policySettings.value(QSL("dashboardRemoteControl"), false).toBool());

    policyLayout->addWidget(m_internalSurfaceCheck);
    policyLayout->addWidget(m_tabOwnershipCheck);
    policyLayout->addWidget(m_backgroundTabActionsCheck);
    policyLayout->addWidget(m_visualFeedbackCheck);
    policyLayout->addWidget(m_supervisionPairingCheck);
    policyLayout->addWidget(m_dashboardRemoteCheck);

    auto* telemetryRow = new QHBoxLayout;
    telemetryRow->setSpacing(8);
    auto* telemetryLabel = new QLabel(tr("Telemetry"), policyCard);
    m_telemetryCombo = new QComboBox(policyCard);
    m_telemetryCombo->addItems({tr("Local diagnostics only"), tr("Usage summary"), tr("Verbose debugging")});
    m_telemetryCombo->setCurrentIndex(qBound(0, policySettings.value(QSL("telemetry"), 0).toInt(), m_telemetryCombo->count() - 1));
    telemetryRow->addWidget(telemetryLabel);
    telemetryRow->addWidget(m_telemetryCombo, 1);
    policyLayout->addLayout(telemetryRow);
    policySettings.endGroup();

    auto* invariantLabel = makeHelpText(tr("Vault boundary is locked to native-only storage. Vault autofill confirmation remains required."), policyCard);
    invariantLabel->setProperty("pm-warning", true);
    policyLayout->addWidget(invariantLabel);

    layout->addWidget(policyCard);

    const QStringList surfaces = {
        tr("Browser Settings"),
        tr("Prometheus control center"),
        tr("Downloads"),
        tr("History"),
        tr("Vault"),
        tr("Provider settings"),
        tr("Supervision"),
        tr("Page JavaScript")
    };

    m_permissionsTable = new QTableWidget(surfaces.size(), 5, page);
    m_permissionsTable->setHorizontalHeaderLabels({
        tr("Surface"), tr("Mode"), tr("Agent scope"), tr("Audit"), tr("Last changed")
    });
    m_permissionsTable->horizontalHeader()->setStretchLastSection(true);
    m_permissionsTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_permissionsTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    for (int i = 0; i < surfaces.size(); ++i) {
        m_permissionsTable->setItem(i, 0, new QTableWidgetItem(surfaces.at(i)));
        m_permissionsTable->setRowHeight(i, 32);

        auto* modeCombo = new QComboBox(m_permissionsTable);
        modeCombo->addItems({tr("Allowed"), tr("Ask every time"), tr("Blocked")});
        modeCombo->setCurrentIndex(1); // Default: Ask every time
        m_permissionsTable->setCellWidget(i, 1, modeCombo);

        m_permissionsTable->setItem(i, 2, new QTableWidgetItem(tr("All agents")));
        m_permissionsTable->setItem(i, 3, new QTableWidgetItem(tr("On")));
        m_permissionsTable->setItem(i, 4, new QTableWidgetItem(tr("—")));
    }

    layout->addWidget(m_permissionsTable, 1);

    auto* capRow = new QHBoxLayout;
    capRow->setSpacing(8);
    auto* capLabel = new QLabel(tr("Agent cap (1–16):"), page);
    m_agentCapSpin = new QSpinBox(page);
    m_agentCapSpin->setRange(1, 16);
    m_agentCapSpin->setValue(4);
    m_agentCapSpin->setMinimumHeight(32);

    const int savedCap = Settings().value(QSL("PrometheusRuntime/Policy/agentCap"), 4).toInt();
    m_agentCapSpin->setValue(qBound(1, savedCap, 16));

    capRow->addWidget(capLabel);
    capRow->addWidget(m_agentCapSpin);
    capRow->addStretch();
    layout->addLayout(capRow);

    auto* saveBtn = makeActionButton(QSL("settings-permissions"), tr("Save Permissions"), page);
    saveBtn->setProperty("accent", true);
    connect(saveBtn, &QPushButton::clicked, this, &FsbControlPanelPage::savePermissions);
    layout->addWidget(saveBtn);
}

void FsbControlPanelPage::buildVaultSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Vault"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Vault entries list (metadata only — no raw secrets)
    m_vaultList = new QListWidget(page);
    layout->addWidget(m_vaultList, 1);

    // Save Vault Entry form
    auto* formWidget = new QWidget(page);
    auto* form = new QFormLayout(formWidget);
    form->setContentsMargins(0, 0, 0, 0);
    form->setSpacing(4);

    m_vaultOrigin = new QLineEdit(page);
    m_vaultOrigin->setPlaceholderText(tr("https://example.com"));
    form->addRow(tr("Origin"), m_vaultOrigin);

    m_vaultLabel = new QLineEdit(page);
    m_vaultLabel->setPlaceholderText(tr("Entry label"));
    form->addRow(tr("Label"), m_vaultLabel);

    // Secret field: password echo; cleared after save
    m_vaultSecret = new QLineEdit(page);
    m_vaultSecret->setEchoMode(QLineEdit::Password);
    m_vaultSecret->setPlaceholderText(tr("Secret (native only)"));
    form->addRow(tr("Secret"), m_vaultSecret);

    m_vaultAutofill = new QCheckBox(tr("Allow autofill"), page);
    form->addRow(QString(), m_vaultAutofill);

    layout->addWidget(formWidget);

    auto* saveBtn = makeActionButton(QSL("vault-secret-add"), tr("Save Vault Entry"), page);
    connect(saveBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveVaultEntry);
    layout->addWidget(saveBtn);
}

void FsbControlPanelPage::buildMemorySiteGuidesSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Memory & Site Guides"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Memory group
    auto* memGroup = makeControlCard(tr("Memory"), page);
    auto* memLayout = new QVBoxLayout(memGroup);
    memLayout->setSpacing(4);

    m_memoryList = new QListWidget(memGroup);
    memLayout->addWidget(m_memoryList);

    auto* memForm = new QFormLayout;
    memForm->setSpacing(4);

    m_memoryKey = new QLineEdit(memGroup);
    m_memoryKey->setPlaceholderText(tr("Key / topic"));
    memForm->addRow(tr("Key"), m_memoryKey);

    m_memoryText = new QPlainTextEdit(memGroup);
    m_memoryText->setFixedHeight(88);
    m_memoryText->setPlaceholderText(tr("Note text…"));
    memForm->addRow(tr("Note"), m_memoryText);

    memLayout->addLayout(memForm);

    auto* saveMemoryBtn = makeActionButton(QSL("tool-reader"), tr("Save Memory"), memGroup);
    connect(saveMemoryBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveMemory);
    memLayout->addWidget(saveMemoryBtn);

    layout->addWidget(memGroup);

    // Site Guides group
    auto* siteGroup = makeControlCard(tr("Site Guides"), page);
    auto* siteLayout = new QVBoxLayout(siteGroup);
    siteLayout->setSpacing(4);

    m_siteGuideList = new QListWidget(siteGroup);
    siteLayout->addWidget(m_siteGuideList);

    auto* siteForm = new QFormLayout;
    siteForm->setSpacing(4);

    m_siteOrigin = new QLineEdit(siteGroup);
    m_siteOrigin->setPlaceholderText(tr("https://example.com"));
    siteForm->addRow(tr("Origin"), m_siteOrigin);

    m_siteGuideText = new QPlainTextEdit(siteGroup);
    m_siteGuideText->setFixedHeight(112);
    m_siteGuideText->setPlaceholderText(tr("Instructions for this site…"));
    siteForm->addRow(tr("Instructions"), m_siteGuideText);

    siteLayout->addLayout(siteForm);

    auto* saveSiteBtn = makeActionButton(QSL("nav-lock-secure"), tr("Save Site Guide"), siteGroup);
    connect(saveSiteBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveSiteGuide);
    siteLayout->addWidget(saveSiteBtn);

    layout->addWidget(siteGroup, 1);
}

void FsbControlPanelPage::buildLogsDiagnosticsSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Logs & Diagnostics"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Log filter
    auto* filterRow = new QHBoxLayout;
    filterRow->setSpacing(8);
    auto* filterLabel = new QLabel(tr("Filter:"), page);
    m_logFilter = new QComboBox(page);
    m_logFilter->addItems({tr("All"), tr("Task"), tr("Provider"), tr("Memory"), tr("Vault"), tr("Supervision"), tr("Error")});
    m_logFilter->setMinimumHeight(32);
    connect(m_logFilter, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &FsbControlPanelPage::refreshAll);
    filterRow->addWidget(filterLabel);
    filterRow->addWidget(m_logFilter, 1);
    layout->addLayout(filterRow);

    // Log view: fixed-width 12px font, selectable text
    m_logView = new QPlainTextEdit(page);
    m_logView->setReadOnly(true);
    m_logView->setTextInteractionFlags(Qt::TextSelectableByMouse | Qt::TextSelectableByKeyboard);
    QFont monoFont = m_logView->font();
    monoFont.setFamily(QSL("Space Mono, Courier New, monospace"));
    monoFont.setPointSize(9);
    m_logView->setFont(monoFont);
    layout->addWidget(m_logView, 1);

    // Diagnostic groups
    auto* diagLabel = new QLabel(tr("Diagnostic groups"), page);
    diagLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(diagLabel);

    m_diagGroupList = new QListWidget(page);
    const QStringList diagGroups = {
        tr("Browser"), tr("Native server"), tr("MCP bridge"), tr("Adapters"),
        tr("Agents"), tr("Ownership"), tr("Runtime"), tr("Supervision"), tr("Release validation")
    };
    for (const QString &g : diagGroups) {
        auto* item = new QListWidgetItem(g);
        item->setSizeHint(QSize(item->sizeHint().width(), 32));
        m_diagGroupList->addItem(item);
    }
    layout->addWidget(m_diagGroupList);

    // Buttons
    auto* btnRow = new QHBoxLayout;
    btnRow->setSpacing(8);

    auto* refreshBtn = makeActionButton(QSL("diag-health"), tr("Refresh Diagnostics"), page);
    connect(refreshBtn, &QPushButton::clicked, this, &FsbControlPanelPage::refreshDiagnostics);

    auto* exportBtn = makeActionButton(QSL("nav-share"), tr("Export Diagnostics"), page);
    connect(exportBtn, &QPushButton::clicked, this, []() {
        if (!mApp || !mApp->agentRuntime()) {
            return;
        }
        const QJsonObject diag = mApp->agentRuntime()->diagnostics();
        const QByteArray json = QJsonDocument(diag).toJson(QJsonDocument::Indented);
        // Write to temp file and open it
        const QString path = QDir::tempPath() + QSL("/prometheus-diagnostics.json");
        QFile f(path);
        if (f.open(QIODevice::WriteOnly)) {
            f.write(json);
            f.close();
            QDesktopServices::openUrl(QUrl::fromLocalFile(path));
        }
    });

    btnRow->addWidget(refreshBtn);
    btnRow->addWidget(exportBtn);
    layout->addLayout(btnRow);
}

void FsbControlPanelPage::buildSupervisionSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Supervision & Pairing"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // 48px summary row with pairing code
    auto* summaryRow = new QWidget(page);
    summaryRow->setFixedHeight(48);
    auto* summaryLayout = new QHBoxLayout(summaryRow);
    summaryLayout->setContentsMargins(0, 0, 0, 0);
    summaryLayout->setSpacing(8);

    auto* codeLabel = new QLabel(tr("Pairing code:"), summaryRow);
    m_pairingCode = new QLabel(tr("—"), summaryRow);
    m_pairingCode->setObjectName(QSL("pairingCode"));
    QFont codeFont;
    codeFont.setFamily(QSL("Space Mono, Courier New"));
    codeFont.setPointSize(13);
    codeFont.setBold(true);
    m_pairingCode->setFont(codeFont);

    summaryLayout->addWidget(codeLabel);
    summaryLayout->addWidget(m_pairingCode);
    summaryLayout->addStretch();

    m_supervisionStatus = new QLabel(tr("Unpaired"), summaryRow);
    m_supervisionStatus->setObjectName(QSL("supervisionStatus"));
    summaryLayout->addWidget(m_supervisionStatus);

    layout->addWidget(summaryRow);

    // Session fields
    auto* fieldsForm = new QFormLayout;
    fieldsForm->setSpacing(4);

    m_sessionId = new QLabel(tr("—"), page);
    m_sessionId->setTextInteractionFlags(Qt::TextSelectableByMouse);
    fieldsForm->addRow(tr("Session ID:"), m_sessionId);

    m_sessionTarget = new QLabel(tr("—"), page);
    fieldsForm->addRow(tr("Target tab:"), m_sessionTarget);

    m_sessionExpiry = new QLabel(tr("—"), page);
    fieldsForm->addRow(tr("Expires at:"), m_sessionExpiry);

    layout->addLayout(fieldsForm);
    layout->addStretch(1);

    // Buttons
    auto* btnRow = new QHBoxLayout;
    btnRow->setSpacing(8);

    auto* pairBtn = makeActionButton(QSL("supervision-pair"), tr("Pair Dashboard"), page);
    pairBtn->setProperty("accent", true);
    connect(pairBtn, &QPushButton::clicked, this, &FsbControlPanelPage::pairDashboard);

    auto* endBtn = makeActionButton(QSL("supervision-unpair"), tr("End Pairing"), page);
    endBtn->setProperty("destructive", true);
    connect(endBtn, &QPushButton::clicked, this, &FsbControlPanelPage::endPairing);

    auto* unpairBtn = makeActionButton(QSL("utility-delete"), tr("Unpair Dashboard"), page);
    unpairBtn->setProperty("destructive", true);
    connect(unpairBtn, &QPushButton::clicked, this, [this]() {
        const int r = QMessageBox::question(this, tr("Unpair Dashboard"),
            tr("Unpair this dashboard? Remote control actions from this session will be rejected."),
            QMessageBox::Yes | QMessageBox::Cancel, QMessageBox::Cancel);
        if (r == QMessageBox::Yes) {
            endPairing();
        }
    });

    btnRow->addWidget(pairBtn);
    btnRow->addWidget(endBtn);
    btnRow->addWidget(unpairBtn);
    layout->addLayout(btnRow);
}

void FsbControlPanelPage::buildParityMatrixSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Parity Matrix"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Open Parity Matrix button
    auto* openBtn = makeActionButton(QSL("tab-overview"), tr("Open Parity Matrix"), page);
    connect(openBtn, &QPushButton::clicked, this, &FsbControlPanelPage::openParityMatrix);
    layout->addWidget(openBtn);

    // Condensed parity table: Category, Native status, Improvement, Evidence
    m_parityTable = new QTableWidget(0, 4, page);
    m_parityTable->setHorizontalHeaderLabels({
        tr("Category"), tr("Native status"), tr("Improvement"), tr("Evidence")
    });
    m_parityTable->horizontalHeader()->setStretchLastSection(true);
    m_parityTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_parityTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    // Parse FSB-PARITY.md at display time
    const QString parityPath = parityMatrixPath();
    QFile parityFile(parityPath);
    if (parityFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        bool inTable = false;
        int rowIndex = 0;
        while (!parityFile.atEnd()) {
            const QString line = QString::fromUtf8(parityFile.readLine()).trimmed();
            if (line.startsWith(QSL("| Category "))) {
                inTable = true;
                continue;
            }
            if (line.startsWith(QSL("|----"))) {
                continue;
            }
            if (inTable && line.startsWith(QSL("|")) && !line.isEmpty()) {
                // Parse pipe-delimited: | Category | FSB Baseline | Native Equivalent | Status | Native Improvement | Validation |
                // Condensed columns we want: Category[0], Status[3], Native Improvement[4], Validation[5]
                const QStringList cols = line.split(QSL("|"));
                // cols[0] is empty (before first |), cols[1]=Category, cols[2]=FSB, cols[3]=Native, cols[4]=Status, cols[5]=NativeImprovement, cols[6]=Validation
                if (cols.size() >= 7) {
                    m_parityTable->insertRow(rowIndex);
                    m_parityTable->setRowHeight(rowIndex, 32);
                    m_parityTable->setItem(rowIndex, 0, new QTableWidgetItem(cols.at(1).trimmed()));
                    m_parityTable->setItem(rowIndex, 1, new QTableWidgetItem(cols.at(4).trimmed()));
                    m_parityTable->setItem(rowIndex, 2, new QTableWidgetItem(cols.at(5).trimmed()));
                    m_parityTable->setItem(rowIndex, 3, new QTableWidgetItem(cols.at(6).trimmed()));
                    ++rowIndex;
                }
            } else if (inTable && !line.startsWith(QSL("|"))) {
                inTable = false;
            }
        }
    }

    if (m_parityTable->rowCount() == 0) {
        auto* emptyState = new QLabel(tr("No parity rows loaded. Generate FSB-PARITY.md before claiming FSB parity."), page);
        emptyState->setObjectName(QSL("emptyStateBody"));
        emptyState->setWordWrap(true);
        layout->addWidget(emptyState);
    }

    layout->addWidget(m_parityTable, 1);

    // Run Parity Check button
    auto* runParityBtn = makeActionButton(QSL("diag-health"), tr("Run Parity Check"), page);
    runParityBtn->setProperty("accent", true);
    connect(runParityBtn, &QPushButton::clicked, this, &FsbControlPanelPage::runParityCheck);
    layout->addWidget(runParityBtn);

    // Parity output area (initially hidden)
    m_parityOutput = new QPlainTextEdit(page);
    m_parityOutput->setReadOnly(true);
    m_parityOutput->setVisible(false);
    QFont monoFont = m_parityOutput->font();
    monoFont.setFamily(QSL("Space Mono, Courier New, monospace"));
    monoFont.setPointSize(9);
    m_parityOutput->setFont(monoFont);
    layout->addWidget(m_parityOutput);
}

void FsbControlPanelPage::buildAppearanceSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(12);

    auto* sectionTitle = new QLabel(tr("Browser Settings"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    auto* themeCard = makeControlCard(tr("Theme & Accent"), page);
    auto* themeLayout = new QVBoxLayout(themeCard);
    themeLayout->setContentsMargins(14, 18, 14, 14);
    themeLayout->setSpacing(10);

    auto* variantRow = new QHBoxLayout;
    variantRow->setSpacing(8);
    auto* darkBtn = new QPushButton(PrometheusIconResolver::icon(QSL("tool-force-dark")), tr("Dark"), themeCard);
    darkBtn->setMinimumHeight(32);
    darkBtn->setToolTip(tr("Switch to dark theme"));
    auto* lightBtn = new QPushButton(PrometheusIconResolver::icon(QSL("utility-theme-toggle")), tr("Light"), themeCard);
    lightBtn->setMinimumHeight(32);
    lightBtn->setToolTip(tr("Switch to light theme"));

    connect(darkBtn,  &QPushButton::clicked, this, [](){ mApp->loadPrometheusVariant(true); });
    connect(lightBtn, &QPushButton::clicked, this, [](){ mApp->loadPrometheusVariant(false); });

    variantRow->addWidget(darkBtn);
    variantRow->addWidget(lightBtn);
    variantRow->addStretch();
    themeLayout->addLayout(variantRow);

    auto* accentLabel = new QLabel(tr("Accent color"), themeCard);
    accentLabel->setObjectName(QSL("sectionLabel"));
    themeLayout->addWidget(accentLabel);

    struct SwatchDef { const char* label; const char* accent; const char* accent2; };
    static const SwatchDef swatches[] = {
        { "FSB Orange", "#ff6b35", "#ff8c42" },
        { "Indigo",     "#6366f1", "#818cf8" },
        { "Teal",       "#14b8a6", "#2dd4bf" },
        { "Rose",       "#f43f5e", "#fb7185" },
    };

    auto* swatchRow = new QHBoxLayout;
    swatchRow->setSpacing(8);
    for (const auto &sw : swatches) {
        auto* btn = new QPushButton(themeCard);
        btn->setToolTip(tr(sw.label));
        btn->setFixedSize(30, 30);
        btn->setStyleSheet(QStringLiteral(
            "QPushButton { background-color: %1; border-radius: 9999px; border: 2px solid transparent; }"
            "QPushButton:hover { border-color: rgba(255,255,255,0.4); }"
        ).arg(QLatin1String(sw.accent)));

        const QString accentVal  = QLatin1String(sw.accent);
        const QString accent2Val = QLatin1String(sw.accent2);
        connect(btn, &QPushButton::clicked, this, [accentVal, accent2Val]() {
            mApp->setPrometheusAccent(accentVal, accent2Val);
        });
        swatchRow->addWidget(btn);
    }
    swatchRow->addStretch();
    themeLayout->addLayout(swatchRow);
    layout->addWidget(themeCard);

    auto* chromeCard = makeControlCard(tr("Chrome & Tabs"), page);
    auto* chromeLayout = new QFormLayout(chromeCard);
    chromeLayout->setContentsMargins(14, 18, 14, 14);
    chromeLayout->setSpacing(8);

    Settings settings;

    settings.beginGroup(QSL("Browser-Tabs-Settings"));
    const QString currentTabLayout = settings.value(QSL("tabLayout"), QSL("Compact")).toString();
    const QString currentTabDisplay = settings.value(QSL("tabDisplay"), QSL("TitleAndIcon")).toString();
    const bool currentTabsOnTop = settings.value(QSL("TabsOnTop"), false).toBool();
    settings.endGroup();

    auto* tabLayoutCombo = new QComboBox(chromeCard);
    tabLayoutCombo->addItem(tr("Compact unified chrome"), QSL("Compact"));
    tabLayoutCombo->addItem(tr("Separate tab strip"), QSL("Separate"));
    setComboToData(tabLayoutCombo, currentTabLayout);
    chromeLayout->addRow(tr("Tab layout"), tabLayoutCombo);

    auto* tabDisplayCombo = new QComboBox(chromeCard);
    tabDisplayCombo->addItem(tr("Title and favicon"), QSL("TitleAndIcon"));
    tabDisplayCombo->addItem(tr("Favicon-only pills"), QSL("FaviconOnly"));
    setComboToData(tabDisplayCombo, currentTabDisplay);
    chromeLayout->addRow(tr("Tab labels"), tabDisplayCombo);

    auto* tabsOnTopCheck = new QCheckBox(tr("Place legacy tab strip above the toolbar"), chromeCard);
    tabsOnTopCheck->setChecked(currentTabsOnTop);
    chromeLayout->addRow(tr("Legacy tabs"), tabsOnTopCheck);

    settings.beginGroup(QSL("Browser-View-Settings"));
    const bool currentStatusBar = settings.value(QSL("showStatusBar"), false).toBool();
    const bool currentNavigationToolbar = settings.value(QSL("showNavigationToolbar"), true).toBool();
    const int currentSidebarWidth = settings.value(QSL("DefaultSideBarWidth"), qzSettings ? qzSettings->defaultSideBarWidth : 320).toInt();
    settings.endGroup();

    auto* navigationToolbarCheck = new QCheckBox(tr("Show navigation toolbar"), chromeCard);
    navigationToolbarCheck->setChecked(currentNavigationToolbar);
    chromeLayout->addRow(tr("Toolbar"), navigationToolbarCheck);

    auto* statusBarCheck = new QCheckBox(tr("Show status bar"), chromeCard);
    statusBarCheck->setChecked(currentStatusBar);
    chromeLayout->addRow(tr("Status bar"), statusBarCheck);

    auto* sidebarWidthSpin = new QSpinBox(chromeCard);
    sidebarWidthSpin->setRange(280, 520);
    sidebarWidthSpin->setSingleStep(20);
    sidebarWidthSpin->setValue(qBound(280, currentSidebarWidth, 520));
    chromeLayout->addRow(tr("Side panel width"), sidebarWidthSpin);

    auto* saveChromeBtn = makeActionButton(QSL("settings-general"), tr("Save Browser Settings"), chromeCard);
    saveChromeBtn->setProperty("accent", true);
    chromeLayout->addRow(QString(), saveChromeBtn);

    connect(saveChromeBtn, &QPushButton::clicked, this, [tabLayoutCombo, tabDisplayCombo, tabsOnTopCheck, navigationToolbarCheck, statusBarCheck, sidebarWidthSpin]() {
        Settings saveSettings;
        saveSettings.beginGroup(QSL("Browser-Tabs-Settings"));
        saveSettings.setValue(QSL("tabLayout"), tabLayoutCombo->currentData().toString());
        saveSettings.setValue(QSL("tabDisplay"), tabDisplayCombo->currentData().toString());
        saveSettings.setValue(QSL("TabsOnTop"), tabsOnTopCheck->isChecked());
        saveSettings.endGroup();

        saveSettings.beginGroup(QSL("Browser-View-Settings"));
        saveSettings.setValue(QSL("showNavigationToolbar"), navigationToolbarCheck->isChecked());
        saveSettings.setValue(QSL("showStatusBar"), statusBarCheck->isChecked());
        saveSettings.setValue(QSL("DefaultSideBarWidth"), sidebarWidthSpin->value());
        saveSettings.endGroup();

        if (qzSettings) {
            qzSettings->loadSettings();
        }
        if (mApp) {
            for (BrowserWindow* window : mApp->windows()) {
                if (window) {
                    window->toggleTabsOnTop(tabsOnTopCheck->isChecked());
                }
            }
            mApp->reloadSettings();
        }
    });

    layout->addWidget(chromeCard);

    layout->addStretch();
}

// ---------------------------------------------------------------------------
// Slot implementations
// ---------------------------------------------------------------------------

void FsbControlPanelPage::refreshAll()
{
    if (!mApp || !mApp->agentRuntime()) {
        return;
    }

    // Update header chips from diagnostics
    const QJsonObject diag = mApp->agentRuntime()->diagnostics();
    const QJsonObject agentsInfo = diag.value(QSL("agents")).toObject();
    const int activeAgents = agentsInfo.value(QSL("active")).toInt(0);
    const int cap = agentsInfo.value(QSL("cap")).toInt(4);
    if (m_agentsChip) {
        m_agentsChip->setText(tr("Agents: %1/%2").arg(activeAgents).arg(cap));
    }
    if (m_agentCapSpin && !m_agentCapSpin->hasFocus()) {
        m_agentCapSpin->setValue(qBound(1, cap, 16));
    }
    Settings policySettings;
    policySettings.beginGroup(QSL("PrometheusRuntime/Policy"));
    if (m_internalSurfaceCheck) {
        m_internalSurfaceCheck->setChecked(policySettings.value(QSL("internalSurfaceControl"), true).toBool());
    }
    if (m_tabOwnershipCheck) {
        m_tabOwnershipCheck->setChecked(policySettings.value(QSL("tabOwnershipEnforcement"), true).toBool());
    }
    if (m_backgroundTabActionsCheck) {
        m_backgroundTabActionsCheck->setChecked(policySettings.value(QSL("backgroundTabActions"), true).toBool());
    }
    if (m_visualFeedbackCheck) {
        m_visualFeedbackCheck->setChecked(policySettings.value(QSL("visualFeedback"), true).toBool());
    }
    if (m_supervisionPairingCheck) {
        m_supervisionPairingCheck->setChecked(policySettings.value(QSL("supervisionPairing"), true).toBool());
    }
    if (m_dashboardRemoteCheck) {
        m_dashboardRemoteCheck->setChecked(policySettings.value(QSL("dashboardRemoteControl"), false).toBool());
    }
    if (m_telemetryCombo) {
        m_telemetryCombo->setCurrentIndex(qBound(0, policySettings.value(QSL("telemetry"), 0).toInt(), m_telemetryCombo->count() - 1));
    }
    policySettings.endGroup();

    const QJsonObject mcpInfo = diag.value(QSL("mcp")).toObject();
    const QString mcpHealth = mcpInfo.value(QSL("health")).toString(tr("—"));
    if (m_mcpChip) {
        m_mcpChip->setText(tr("MCP: %1").arg(mcpHealth));
    }

    const QJsonObject supervisionInfo = diag.value(QSL("supervision")).toObject();
    const QString supervisionState = supervisionInfo.value(QSL("status")).toString(tr("Unpaired"));
    if (m_supervisionChip) {
        m_supervisionChip->setText(tr("Supervision: %1").arg(supervisionState));
    }
    if (m_supervisionStatus) {
        m_supervisionStatus->setText(supervisionState);
    }
    if (m_pairingCode) {
        const QString code = supervisionInfo.value(QSL("pairingCode")).toString(tr("—"));
        m_pairingCode->setText(code.isEmpty() ? tr("—") : code);
    }
    if (m_sessionId) {
        m_sessionId->setText(supervisionInfo.value(QSL("sessionId")).toString(tr("—")));
    }
    if (m_sessionTarget) {
        m_sessionTarget->setText(supervisionInfo.value(QSL("targetTab")).toString(tr("—")));
    }
    if (m_sessionExpiry) {
        m_sessionExpiry->setText(supervisionInfo.value(QSL("expiresAt")).toString(tr("—")));
    }

    // Refresh task list
    if (m_taskList) {
        m_taskList->clear();
        const QJsonObject tasksResult = mApp->agentRuntime()->listTasks(20);
        const QJsonArray tasks = tasksResult.value(QSL("tasks")).toArray();
        for (const QJsonValue &tv : tasks) {
            const QJsonObject task = tv.toObject();
            const QString status = task.value(QSL("status")).toString();
            const QString prompt = task.value(QSL("prompt")).toString();
            const QJsonObject metrics = task.value(QSL("metrics")).toObject();
            const QString execMode = metrics.value(QSL("executionMode")).toString();
            QString label = QSL("[%1] %2").arg(status, prompt.left(60));
            if (!execMode.isEmpty()) {
                label += QSL(" [Execution: %1]").arg(execMode);
            }
            auto* item = new QListWidgetItem(label);
            item->setData(Qt::UserRole, task.value(QSL("id")).toString());
            item->setSizeHint(QSize(item->sizeHint().width(), 32));
            m_taskList->addItem(item);
        }
    }

    // Refresh provider list
    if (m_providerList) {
        const QString currentSel = m_providerList->currentItem()
            ? m_providerList->currentItem()->text() : QString();
        m_providerList->clear();
        const QJsonObject provResult = mApp->agentRuntime()->providerConfig();
        const QJsonObject providers = provResult.value(QSL("providers")).toObject();
        for (const QString &provId : providers.keys()) {
            const QJsonObject cfg = providers.value(provId).toObject();
            const bool enabled = cfg.value(QSL("enabled")).toBool();
            const bool hasSecret = cfg.value(QSL("secretConfigured")).toBool();
            const QString label = QSL("%1 — %2 — %3")
                .arg(provId)
                .arg(enabled ? tr("Enabled") : tr("Disabled"))
                .arg(hasSecret ? tr("Key saved") : tr("No key saved"));
            auto* item = new QListWidgetItem(label);
            item->setData(Qt::UserRole, provId);
            item->setSizeHint(QSize(item->sizeHint().width(), 32));
            m_providerList->addItem(item);
        }
        if (!currentSel.isEmpty()) {
            const QList<QListWidgetItem*> matching = m_providerList->findItems(currentSel, Qt::MatchStartsWith);
            if (!matching.isEmpty()) {
                m_providerList->setCurrentItem(matching.first());
            }
        }
        if (m_providerSecretState) {
            const QString selectedProv = m_providerList->currentItem()
                ? m_providerList->currentItem()->data(Qt::UserRole).toString() : QString();
            if (!selectedProv.isEmpty()) {
                const QJsonObject pCfg = providers.value(selectedProv).toObject();
                m_providerSecretState->setText(pCfg.value(QSL("secretConfigured")).toBool()
                    ? tr("Key saved") : tr("No key saved"));
            }
        }
    }

    // Refresh vault list (metadata only — no raw secrets)
    if (m_vaultList) {
        m_vaultList->clear();
        const QJsonObject vaultResult = mApp->agentRuntime()->listVaultEntries();
        const QJsonArray entries = vaultResult.value(QSL("entries")).toArray();
        for (const QJsonValue &ev : entries) {
            const QJsonObject entry = ev.toObject();
            const QString origin = entry.value(QSL("origin")).toString();
            const QString label = entry.value(QSL("label")).toString();
            const bool autofill = entry.value(QSL("autofillAllowed")).toBool();
            const QString chip = autofill ? tr("Confirmation required") : tr("Native-only");
            const QString text = QSL("%1 / %2 — %3 — Remote blocked").arg(origin, label, chip);
            auto* item = new QListWidgetItem(text);
            item->setSizeHint(QSize(item->sizeHint().width(), 32));
            m_vaultList->addItem(item);
        }
    }

    // Refresh memory list
    if (m_memoryList) {
        m_memoryList->clear();
        const QJsonObject memResult = mApp->agentRuntime()->listMemory();
        const QJsonArray items = memResult.value(QSL("items")).toArray();
        for (const QJsonValue &mv : items) {
            const QJsonObject mem = mv.toObject();
            const QString key = mem.value(QSL("key")).toString();
            const QString text = mem.value(QSL("text")).toString().left(60);
            auto* lwItem = new QListWidgetItem(QSL("%1: %2").arg(key, text));
            lwItem->setSizeHint(QSize(lwItem->sizeHint().width(), 32));
            m_memoryList->addItem(lwItem);
        }
    }

    // Refresh site guides list
    if (m_siteGuideList) {
        m_siteGuideList->clear();
        const QJsonObject sgResult = mApp->agentRuntime()->listSiteGuides();
        const QJsonArray guides = sgResult.value(QSL("guides")).toArray();
        for (const QJsonValue &gv : guides) {
            const QJsonObject guide = gv.toObject();
            const QString origin = guide.value(QSL("origin")).toString();
            const QString instructions = guide.value(QSL("instructions")).toString().left(60);
            auto* item = new QListWidgetItem(QSL("%1: %2").arg(origin, instructions));
            item->setSizeHint(QSize(item->sizeHint().width(), 32));
            m_siteGuideList->addItem(item);
        }
    }

    // Refresh log view
    if (m_logView && m_logFilter) {
        const QJsonObject logsResult = mApp->agentRuntime()->listRuntimeLogs(100);
        const QJsonArray logs = logsResult.value(QSL("logs")).toArray();
        const QString filterText = m_logFilter->currentText().toLower();
        QString logContent;
        for (const QJsonValue &lv : logs) {
            const QJsonObject logEntry = lv.toObject();
            const QString type = logEntry.value(QSL("type")).toString().toLower();
            const QString message = logEntry.value(QSL("message")).toString();
            const QString ts = logEntry.value(QSL("timestamp")).toString();
            if (filterText == tr("all").toLower() || type.contains(filterText)) {
                logContent += QSL("[%1] [%2] %3\n").arg(ts, type, message);
            }
        }
        if (logContent.isEmpty()) {
            m_logView->setPlaceholderText(tr("No runtime logs yet. Run a task or refresh diagnostics."));
        } else {
            m_logView->setPlainText(logContent);
        }
    }

    // Refresh MCP table
    refreshDiagnostics();
}

void FsbControlPanelPage::refreshDiagnostics()
{
    if (!m_mcpTable || !mApp || !mApp->agentRuntime()) {
        return;
    }

    const QJsonObject diag = mApp->agentRuntime()->diagnostics();
    const QJsonObject mcpInfo = diag.value(QSL("mcp")).toObject();

    m_mcpTable->setRowCount(0);

    // Build key/value rows from diagnostic data
    const struct { QString key; QString field; } rows[] = {
        {tr("Server health"), QSL("health")},
        {tr("Authorization mode"), QSL("authorization")},
        {tr("Bridge transport"), QSL("transport")},
        {tr("Audit path"), QSL("auditPath")},
        {tr("Tool count"), QSL("toolCount")},
        {tr("Adapter health"), QSL("adapterHealth")},
    };

    bool hasData = false;
    for (const auto &row : rows) {
        const QJsonValue val = mcpInfo.value(row.field);
        if (!val.isUndefined() && !val.isNull()) {
            hasData = true;
            const int r = m_mcpTable->rowCount();
            m_mcpTable->insertRow(r);
            m_mcpTable->setRowHeight(r, 32);
            m_mcpTable->setItem(r, 0, new QTableWidgetItem(row.key));
            m_mcpTable->setItem(r, 1, new QTableWidgetItem(val.toVariant().toString()));
        }
    }

    // Also show agents info
    const QJsonObject agentsInfo = diag.value(QSL("agents")).toObject();
    if (!agentsInfo.isEmpty()) {
        hasData = true;
        const int r = m_mcpTable->rowCount();
        m_mcpTable->insertRow(r);
        m_mcpTable->setRowHeight(r, 32);
        m_mcpTable->setItem(r, 0, new QTableWidgetItem(tr("Agents active/cap")));
        m_mcpTable->setItem(r, 1, new QTableWidgetItem(
            QSL("%1/%2").arg(agentsInfo.value(QSL("active")).toInt()).arg(agentsInfo.value(QSL("cap")).toInt(4))));
    }

    if (m_mcpEmptyState) {
        m_mcpEmptyState->setVisible(!hasData);
    }
    m_mcpTable->setVisible(hasData);
}

void FsbControlPanelPage::runTask()
{
    if (!m_taskPrompt || !mApp || !mApp->agentRuntime()) {
        return;
    }
    const QString prompt = m_taskPrompt->toPlainText().trimmed();
    if (prompt.isEmpty()) {
        return;
    }
    const QJsonObject result = mApp->agentRuntime()->submitTask(prompt, QJsonObject(), QSL("control_panel"), false);
    // submitTask returns {ok, task:{id, ...}}; "taskId" at top level does not exist.
    m_currentTaskId = result.value(QSL("task")).toObject().value(QSL("id")).toString();
    m_taskPrompt->clear();
    refreshAll();
}

void FsbControlPanelPage::cancelTask()
{
    if (m_currentTaskId.isEmpty() || !mApp || !mApp->agentRuntime()) {
        // Try to cancel the selected task
        if (m_taskList && m_taskList->currentItem()) {
            const QString taskId = m_taskList->currentItem()->data(Qt::UserRole).toString();
            if (!taskId.isEmpty()) {
                const int r = QMessageBox::question(this, tr("Cancel Task"),
                    tr("Cancel this task? Progress stops now; logs remain available."),
                    QMessageBox::Yes | QMessageBox::Cancel, QMessageBox::Cancel);
                if (r == QMessageBox::Yes) {
                    mApp->agentRuntime()->cancelTask(taskId, QSL("User cancelled from control panel"));
                    refreshAll();
                }
            }
        }
        return;
    }
    const int r = QMessageBox::question(this, tr("Cancel Task"),
        tr("Cancel this task? Progress stops now; logs remain available."),
        QMessageBox::Yes | QMessageBox::Cancel, QMessageBox::Cancel);
    if (r == QMessageBox::Yes) {
        mApp->agentRuntime()->cancelTask(m_currentTaskId, QSL("User cancelled from control panel"));
        m_currentTaskId.clear();
        refreshAll();
    }
}

void FsbControlPanelPage::saveProvider()
{
    if (!m_providerList || !m_providerSecret || !mApp || !mApp->agentRuntime()) {
        return;
    }
    const QString providerId = m_providerList->currentItem()
        ? m_providerList->currentItem()->data(Qt::UserRole).toString() : QString();
    if (providerId.isEmpty()) {
        return;
    }

    QJsonObject config;
    if (m_providerEnabled) {
        config[QSL("enabled")] = m_providerEnabled->isChecked();
    }
    if (m_providerModel && !m_providerModel->text().isEmpty()) {
        config[QSL("model")] = m_providerModel->text().trimmed();
    }
    if (m_providerEndpoint && !m_providerEndpoint->text().isEmpty()) {
        config[QSL("endpoint")] = m_providerEndpoint->text().trimmed();
    }
    // Secret field: include only if non-empty; clear after save (native-only path)
    // Key must be "secret" — AgentRuntime::saveProviderConfig reads config.value("secret").
    const QString secret = m_providerSecret->text();
    if (!secret.isEmpty()) {
        config[QSL("secret")] = secret;
    }

    // allowSecretPayload=true for native UI paths only
    mApp->agentRuntime()->saveProviderConfig(providerId, config, /*allowSecretPayload=*/true);

    // Clear secret field after save (security requirement)
    m_providerSecret->clear();
    if (m_providerSecretState) {
        m_providerSecretState->setText(tr("Key saved"));
    }
    refreshAll();
}

void FsbControlPanelPage::discoverModels()
{
    if (!m_modelList) {
        return;
    }
    // Trigger model discovery via provider config
    if (!mApp || !mApp->agentRuntime()) {
        return;
    }
    const QJsonObject result = mApp->agentRuntime()->providerConfig();
    const QJsonObject providers = result.value(QSL("providers")).toObject();
    const QString selectedProv = m_providerList && m_providerList->currentItem()
        ? m_providerList->currentItem()->data(Qt::UserRole).toString() : QString();

    m_modelList->clear();
    if (!selectedProv.isEmpty()) {
        const QJsonObject cfg = providers.value(selectedProv).toObject();
        const QJsonArray models = cfg.value(QSL("models")).toArray();
        if (models.isEmpty()) {
            auto* item = new QListWidgetItem(tr("No models discovered"));
            m_modelList->addItem(item);
        } else {
            for (const QJsonValue &mv : models) {
                auto* item = new QListWidgetItem(mv.toString());
                item->setSizeHint(QSize(item->sizeHint().width(), 32));
                m_modelList->addItem(item);
            }
        }
    }
}

void FsbControlPanelPage::saveMemory()
{
    if (!m_memoryKey || !m_memoryText || !mApp || !mApp->agentRuntime()) {
        return;
    }
    const QString key = m_memoryKey->text().trimmed();
    const QString text = m_memoryText->toPlainText().trimmed();
    if (key.isEmpty() || text.isEmpty()) {
        return;
    }
    const QString url = m_window ? m_window->weView() ? m_window->weView()->url().toString() : QString() : QString();
    mApp->agentRuntime()->saveMemory(key, text, url);
    m_memoryKey->clear();
    m_memoryText->clear();
    refreshAll();
}

void FsbControlPanelPage::saveSiteGuide()
{
    if (!m_siteOrigin || !m_siteGuideText || !mApp || !mApp->agentRuntime()) {
        return;
    }
    const QString origin = m_siteOrigin->text().trimmed();
    const QString instructions = m_siteGuideText->toPlainText().trimmed();
    if (origin.isEmpty() || instructions.isEmpty()) {
        return;
    }
    mApp->agentRuntime()->saveSiteGuide(origin, instructions);
    m_siteOrigin->clear();
    m_siteGuideText->clear();
    refreshAll();
}

void FsbControlPanelPage::saveVaultEntry()
{
    if (!m_vaultOrigin || !m_vaultLabel || !m_vaultSecret || !m_vaultAutofill
            || !mApp || !mApp->agentRuntime()) {
        return;
    }
    const QString origin = m_vaultOrigin->text().trimmed();
    const QString label = m_vaultLabel->text().trimmed();
    const QString secret = m_vaultSecret->text();
    const bool autofill = m_vaultAutofill->isChecked();

    if (origin.isEmpty() || label.isEmpty()) {
        return;
    }

    // Native UI path — allowSecretPayload is implicit via saveVaultSecret
    if (!secret.isEmpty()) {
        // saveVaultSecret stores both metadata and the native-only secret
        mApp->agentRuntime()->saveVaultSecret(origin, label, secret, autofill);
    } else {
        // Metadata-only update
        mApp->agentRuntime()->saveVaultEntryMetadata(origin, label, autofill);
    }

    // Clear secret field after save (T-08-05: no raw secret in list/display)
    m_vaultSecret->clear();
    m_vaultOrigin->clear();
    m_vaultLabel->clear();
    m_vaultAutofill->setChecked(false);
    refreshAll();
}

void FsbControlPanelPage::savePermissions()
{
    if (!m_agentCapSpin || !mApp || !mApp->agentCommandRouter()) {
        return;
    }
    const int newCap = m_agentCapSpin->value();
    const bool internalSurface = !m_internalSurfaceCheck || m_internalSurfaceCheck->isChecked();
    const bool tabOwnership = !m_tabOwnershipCheck || m_tabOwnershipCheck->isChecked();
    const bool visualFeedback = !m_visualFeedbackCheck || m_visualFeedbackCheck->isChecked();
    const bool supervisionPairing = !m_supervisionPairingCheck || m_supervisionPairingCheck->isChecked();
    const int telemetry = m_telemetryCombo ? m_telemetryCombo->currentIndex() : 0;

    const QJsonObject request = QJsonObject{
        {QSL("tool"), QSL("set_agent_policy")},
        {QSL("params"), QJsonObject{
            {QSL("agentCap"), newCap},
            {QSL("internalSurfaceControl"), internalSurface},
            {QSL("tabOwnershipEnforcement"), tabOwnership},
            {QSL("visualFeedback"), visualFeedback},
            {QSL("telemetry"), telemetry},
            {QSL("supervisionPairing"), supervisionPairing}
        }}
    };
    mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));

    Settings policySettings;
    policySettings.beginGroup(QSL("PrometheusRuntime/Policy"));
    policySettings.setValue(QSL("agentCap"), newCap);
    policySettings.setValue(QSL("internalSurfaceControl"), internalSurface);
    policySettings.setValue(QSL("tabOwnershipEnforcement"), tabOwnership);
    policySettings.setValue(QSL("backgroundTabActions"), !m_backgroundTabActionsCheck || m_backgroundTabActionsCheck->isChecked());
    policySettings.setValue(QSL("visualFeedback"), visualFeedback);
    policySettings.setValue(QSL("telemetry"), telemetry);
    policySettings.setValue(QSL("supervisionPairing"), supervisionPairing);
    policySettings.setValue(QSL("dashboardRemoteControl"), m_dashboardRemoteCheck && m_dashboardRemoteCheck->isChecked());
    policySettings.endGroup();
    refreshAll();
}

void FsbControlPanelPage::pairDashboard()
{
    if (!mApp || !mApp->agentCommandRouter()) {
        return;
    }
    const QJsonObject request = QJsonObject{
        {QSL("tool"), QSL("start_supervision_session")},
        {QSL("params"), QJsonObject{}}
    };
    const QJsonObject response = mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));
    // Capture session ID so endPairing() can reference it; without this the
    // end_supervision_session call would always receive an empty sessionId and
    // the router would return STALE_SUPERVISION_SESSION immediately (WR-02).
    if (response.value(QSL("ok")).toBool()) {
        m_activeSupervisionSessionId = response.value(QSL("result")).toObject()
            .value(QSL("session")).toObject().value(QSL("sessionId")).toString();
    }
    refreshAll();
}

void FsbControlPanelPage::endPairing()
{
    if (!mApp || !mApp->agentCommandRouter()) {
        return;
    }
    const int r = QMessageBox::question(this, tr("End Pairing"),
        tr("End this supervision session? The dashboard will stop receiving snapshots for this tab."),
        QMessageBox::Yes | QMessageBox::Cancel, QMessageBox::Cancel);
    if (r != QMessageBox::Yes) {
        return;
    }
    const QJsonObject request = QJsonObject{
        {QSL("tool"), QSL("end_supervision_session")},
        // Pass the active session ID captured during pairDashboard(); empty string
        // would cause routeSupervision to return STALE_SUPERVISION_SESSION (WR-02).
        {QSL("params"), QJsonObject{{QSL("sessionId"), m_activeSupervisionSessionId}}}
    };
    mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));
    m_activeSupervisionSessionId.clear();
    refreshAll();
}

void FsbControlPanelPage::openParityMatrix()
{
    const QString path = parityMatrixPath();
    if (QFileInfo::exists(path)) {
        QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    } else {
        QMessageBox::warning(this, tr("Parity Matrix"),
            tr("FSB-PARITY.md not found at: %1").arg(path));
    }
}

void FsbControlPanelPage::runParityCheck()
{
    if (!m_parityOutput) {
        return;
    }

    // Fixed script path — not user-controlled (T-08-05d)
    const QString scriptPath = smokeScriptPath();
    if (!QFileInfo::exists(scriptPath)) {
        m_parityOutput->setPlainText(tr("Parity check script not found at: %1").arg(scriptPath));
        m_parityOutput->setVisible(true);
        return;
    }

    auto* proc = new QProcess(this);
    proc->setProgram(QSL("bash"));
    // Use QStringList args — not a shell command string (T-08-05d: no injection)
    proc->setArguments({scriptPath, QSL("--matrix-only")});

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc](int exitCode, QProcess::ExitStatus) {
        const QString output = QString::fromUtf8(proc->readAllStandardOutput())
            + QString::fromUtf8(proc->readAllStandardError());
        m_parityOutput->setPlainText(tr("Exit code: %1\n\n%2").arg(exitCode).arg(output));
        m_parityOutput->setVisible(true);
        proc->deleteLater();
    });

    m_parityOutput->setPlainText(tr("Running parity check…"));
    m_parityOutput->setVisible(true);
    proc->start();
}
