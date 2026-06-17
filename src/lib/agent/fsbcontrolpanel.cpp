#include "fsbcontrolpanel.h"

#include "agentcommandrouter.h"
#include "agentruntime.h"
#include "browserwindow.h"
#include "mainapplication.h"
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
    root->setContentsMargins(8, 8, 8, 8);
    root->setSpacing(8);

    // Header: 48px band
    auto* headerWidget = new QWidget(this);
    headerWidget->setFixedHeight(48);
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
    contentLayout->setSpacing(8);
    contentLayout->setContentsMargins(0, 0, 0, 0);

    // Section selector rail (130px fixed, shows at >=420px — always visible for simplicity)
    m_sectionRail = new QListWidget(this);
    m_sectionRail->setFixedWidth(130);
    m_sectionRail->setObjectName(QSL("sectionRail"));

    const QStringList sectionNames = {
        tr("Tasks"),
        tr("Providers & Models"),
        tr("MCP Status"),
        tr("Permissions & Agents"),
        tr("Vault"),
        tr("Memory & Site Guides"),
        tr("Logs & Diagnostics"),
        tr("Supervision & Pairing"),
        tr("Parity Matrix")
    };
    for (const QString &name : sectionNames) {
        m_sectionRail->addItem(name);
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

// ---------------------------------------------------------------------------
// Section builders
// ---------------------------------------------------------------------------

void FsbControlPanelPage::buildTasksSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Tasks"), page);
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

    auto* runBtn = new QPushButton(tr("Run Task"), page);
    runBtn->setMinimumHeight(32);
    runBtn->setProperty("accent", true);
    connect(runBtn, &QPushButton::clicked, this, &FsbControlPanelPage::runTask);

    auto* cancelBtn = new QPushButton(tr("Cancel Task"), page);
    cancelBtn->setMinimumHeight(32);
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

    auto* saveBtn = new QPushButton(tr("Save Provider"), page);
    saveBtn->setMinimumHeight(32);
    connect(saveBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveProvider);

    auto* discoverBtn = new QPushButton(tr("Discover Models"), page);
    discoverBtn->setMinimumHeight(32);
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

    auto* saveFallbacks = new QPushButton(tr("Save Fallbacks"), page);
    saveFallbacks->setMinimumHeight(32);
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

    auto* refreshBtn = new QPushButton(tr("Refresh Diagnostics"), page);
    refreshBtn->setMinimumHeight(32);
    connect(refreshBtn, &QPushButton::clicked, this, &FsbControlPanelPage::refreshDiagnostics);
    layout->addWidget(refreshBtn);
}

void FsbControlPanelPage::buildPermissionsSection(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(8);

    auto* sectionTitle = new QLabel(tr("Permissions & Agents"), page);
    sectionTitle->setObjectName(QSL("sectionHeading"));
    layout->addWidget(sectionTitle);

    // Permission matrix
    const QStringList surfaces = {
        tr("Preferences"),
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

    // Agent cap
    auto* capRow = new QHBoxLayout;
    capRow->setSpacing(8);
    auto* capLabel = new QLabel(tr("Agent cap (1–16):"), page);
    m_agentCapSpin = new QSpinBox(page);
    m_agentCapSpin->setRange(1, 16);
    m_agentCapSpin->setValue(4);
    m_agentCapSpin->setMinimumHeight(32);

    // Read persisted cap if available
    Settings policySettings;
    const int savedCap = policySettings.value(QSL("PrometheusRuntime/Policy/agentCap"), 4).toInt();
    m_agentCapSpin->setValue(qBound(1, savedCap, 16));

    capRow->addWidget(capLabel);
    capRow->addWidget(m_agentCapSpin);
    capRow->addStretch();
    layout->addLayout(capRow);

    auto* saveBtn = new QPushButton(tr("Save Permissions"), page);
    saveBtn->setMinimumHeight(32);
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

    auto* saveBtn = new QPushButton(tr("Save Vault Entry"), page);
    saveBtn->setMinimumHeight(32);
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
    auto* memGroup = new QGroupBox(tr("Memory"), page);
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

    auto* saveMemoryBtn = new QPushButton(tr("Save Memory"), memGroup);
    saveMemoryBtn->setMinimumHeight(32);
    connect(saveMemoryBtn, &QPushButton::clicked, this, &FsbControlPanelPage::saveMemory);
    memLayout->addWidget(saveMemoryBtn);

    layout->addWidget(memGroup);

    // Site Guides group
    auto* siteGroup = new QGroupBox(tr("Site Guides"), page);
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

    auto* saveSiteBtn = new QPushButton(tr("Save Site Guide"), siteGroup);
    saveSiteBtn->setMinimumHeight(32);
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

    auto* refreshBtn = new QPushButton(tr("Refresh Diagnostics"), page);
    refreshBtn->setMinimumHeight(32);
    connect(refreshBtn, &QPushButton::clicked, this, &FsbControlPanelPage::refreshDiagnostics);

    auto* exportBtn = new QPushButton(tr("Export Diagnostics"), page);
    exportBtn->setMinimumHeight(32);
    connect(exportBtn, &QPushButton::clicked, this, [this]() {
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

    auto* pairBtn = new QPushButton(tr("Pair Dashboard"), page);
    pairBtn->setMinimumHeight(32);
    pairBtn->setProperty("accent", true);
    connect(pairBtn, &QPushButton::clicked, this, &FsbControlPanelPage::pairDashboard);

    auto* endBtn = new QPushButton(tr("End Pairing"), page);
    endBtn->setMinimumHeight(32);
    endBtn->setProperty("destructive", true);
    connect(endBtn, &QPushButton::clicked, this, &FsbControlPanelPage::endPairing);

    auto* unpairBtn = new QPushButton(tr("Unpair Dashboard"), page);
    unpairBtn->setMinimumHeight(32);
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
    auto* openBtn = new QPushButton(tr("Open Parity Matrix"), page);
    openBtn->setMinimumHeight(32);
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
    auto* runParityBtn = new QPushButton(tr("Run Parity Check"), page);
    runParityBtn->setMinimumHeight(32);
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

    // Use routeForSession with sessionKey "control_panel" (internal surface key — bypasses remote transport checks)
    // Do NOT call a direct route() method; routeForSession is the correct API.
    const QJsonObject request = QJsonObject{
        {QSL("tool"), QSL("set_agent_policy")},
        {QSL("params"), QJsonObject{
            {QSL("agentCap"), newCap}
        }}
    };
    mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));

    // Persist agent cap via Settings as backup
    Settings policySettings;
    policySettings.setValue(QSL("PrometheusRuntime/Policy/agentCap"), newCap);
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
    mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));
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
        {QSL("params"), QJsonObject{}}
    };
    mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));
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
