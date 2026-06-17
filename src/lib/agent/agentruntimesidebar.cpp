#include "agentruntimesidebar.h"

#include "agentruntime.h"
#include "prometheusmarkwidget.h"
#include "bookmarkitem.h"
#include "bookmarks.h"
#include "browserwindow.h"
#include "history.h"
#include "mainapplication.h"
#include "tabbedwebview.h"
#include "tabgroupmodel.h"
#include "tabmodel.h"
#include "tabwidget.h"
#include "webtab.h"

#include <QAction>
#include <QCheckBox>
#include <QComboBox>
#include <QFont>
#include <QFontDatabase>
#include <QFormLayout>
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
#include <QShortcut>
#include <QStackedWidget>
#include <QTabBar>
#include <QTabWidget>
#include <QUrl>
#include <QVBoxLayout>

namespace {

QString progressSummary(const QJsonObject &task)
{
    const QJsonArray progress = task.value(QSL("progress")).toArray();
    if (progress.isEmpty()) {
        return QString();
    }
    return progress.at(progress.size() - 1).toObject().value(QSL("message")).toString();
}

} // namespace

AgentRuntimeSidebarController::AgentRuntimeSidebarController(QObject* parent)
    : SideBarInterface(parent)
{
}

QString AgentRuntimeSidebarController::title() const
{
    return tr("Prometheus");
}

QAction* AgentRuntimeSidebarController::createMenuAction()
{
    auto* action = new QAction(QIcon::fromTheme(QSL("prometheus"), QIcon(QSL(":icons/prometheus.svg"))), tr("Prometheus"), this);
    action->setCheckable(true);
    action->setShortcut(QKeySequence(QSL("Ctrl+Shift+P")));
    return action;
}

QWidget* AgentRuntimeSidebarController::createSideBarWidget(BrowserWindow* mainWindow)
{
    return new AgentRuntimeSidebarWidget(mainWindow);
}

AgentRuntimeSidebarWidget::AgentRuntimeSidebarWidget(BrowserWindow* window, QWidget* parent)
    : QWidget(parent)
    , m_window(window)
    , m_modeStack(nullptr)
    , m_taskPrompt(nullptr)
    , m_agentMessageStream(nullptr)
    , m_agentStatus(nullptr)
    , m_runTaskBtn(nullptr)
    , m_cancelTaskBtn(nullptr)
    , m_explorerTabs(nullptr)
    , m_bookmarkList(nullptr)
    , m_readingList(nullptr)
    , m_historyList(nullptr)
    , m_pinnedList(nullptr)
    , m_groupList(nullptr)
    , m_openTabsList(nullptr)
    , m_readerModeCheck(nullptr)
    , m_focusHighlightCheck(nullptr)
    , m_forceDarkCheck(nullptr)
{
    setObjectName(QSL("PrometheusAgentSidebar"));
    setMinimumWidth(320);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(8, 8, 8, 8);
    root->setSpacing(8);

    // Header: PM mark (26x26 Compact) + Pro/metheus wordmark labels
    auto* markWidget = new PrometheusMarkWidget(PrometheusMarkWidget::Compact, this);
    markWidget->setObjectName(QSL("PrometheusMark"));
    markWidget->setFixedSize(26, 26);

    // Wordmark: "Pro" (Poppins Light 300) + "metheus" (Poppins ExtraBold 800, accent)
    auto* wordmarkLayout = new QHBoxLayout();
    wordmarkLayout->setSpacing(0);
    wordmarkLayout->setContentsMargins(0, 0, 0, 0);

    auto* wPro = new QLabel(tr("Pro"), this);
    QFont lightFont = QFontDatabase::font(QSL("Poppins"), QSL("Light"), 0);
    lightFont.setPixelSize(14);
    wPro->setFont(lightFont);
    wPro->setObjectName(QSL("PrometheusWordmarkPro"));

    auto* wMetheus = new QLabel(tr("metheus"), this);
    QFont boldFont = QFontDatabase::font(QSL("Poppins"), QSL("ExtraBold"), 0);
    boldFont.setPixelSize(14);
    wMetheus->setFont(boldFont);
    wMetheus->setObjectName(QSL("PrometheusWordmarkMetheus"));
    // --accent color applied via QSS: QLabel#PrometheusWordmarkMetheus { color: #ff6b35; }

    wordmarkLayout->addWidget(wPro);
    wordmarkLayout->addWidget(wMetheus);

    auto* headerRow = new QHBoxLayout();
    headerRow->setContentsMargins(0, 0, 0, 0);
    headerRow->setSpacing(8);
    headerRow->addWidget(markWidget);
    headerRow->addLayout(wordmarkLayout);
    headerRow->addStretch();

    auto* headerWidget = new QWidget(this);
    headerWidget->setObjectName(QSL("PrometheusHeader"));
    headerWidget->setLayout(headerRow);
    root->addWidget(headerWidget);

    // Mode switcher: use QTabBar directly so no dummy QWidget content areas are
    // allocated (WR-05 — QTabWidget wastes ~20-30 px of sidebar height for the
    // empty tab content region even with setMaximumHeight(36)).
    auto* modeSwitcher = new QTabBar(this);
    modeSwitcher->setDocumentMode(true);
    modeSwitcher->setMaximumHeight(36);

    // Stacked widget holding the four mode pages
    m_modeStack = new QStackedWidget(this);

    auto* fsbAgentPage = new QWidget(m_modeStack);
    buildFsbAgentPage(fsbAgentPage);
    m_modeStack->addWidget(fsbAgentPage);

    auto* explorerPage = new QWidget(m_modeStack);
    buildExplorerPage(explorerPage);
    m_modeStack->addWidget(explorerPage);

    auto* tabsPage = new QWidget(m_modeStack);
    buildTabsPage(tabsPage);
    m_modeStack->addWidget(tabsPage);

    auto* toolsPage = new QWidget(m_modeStack);
    buildToolsPage(toolsPage);
    m_modeStack->addWidget(toolsPage);

    // Add four tab labels; content is managed by m_modeStack, not the bar itself.
    modeSwitcher->addTab(tr("FSB Agent"));
    modeSwitcher->addTab(tr("Explorer"));
    modeSwitcher->addTab(tr("Tabs"));
    modeSwitcher->addTab(tr("Tools"));

    connect(modeSwitcher, &QTabBar::currentChanged, m_modeStack, &QStackedWidget::setCurrentIndex);

    root->addWidget(modeSwitcher);
    root->addWidget(m_modeStack, 1);

    connect(mApp->agentRuntime(), &AgentRuntime::runtimeChanged, this, &AgentRuntimeSidebarWidget::refreshAll);
    refreshAll();
}

void AgentRuntimeSidebarWidget::seedPromptAndOpen(const QString& prompt)
{
    if (m_taskPrompt) {
        m_taskPrompt->setPlainText(prompt);
    }
    if (m_modeStack) {
        m_modeStack->setCurrentIndex(0);
    }
}

void AgentRuntimeSidebarWidget::buildFsbAgentPage(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 8, 0, 0);
    layout->setSpacing(8);

    // Status pill
    m_agentStatus = new QLabel(tr("Ready"), page);
    m_agentStatus->setObjectName(QSL("agentStatusPill"));
    layout->addWidget(m_agentStatus);

    // Message stream
    m_agentMessageStream = new QListWidget(page);
    m_agentMessageStream->setSelectionMode(QAbstractItemView::SingleSelection);
    m_agentMessageStream->setEditTriggers(QAbstractItemView::NoEditTriggers);
    layout->addWidget(m_agentMessageStream, 1);

    // Composer
    m_taskPrompt = new QPlainTextEdit(page);
    m_taskPrompt->setPlaceholderText(tr("Ask Prometheus to work in this browser…"));
    m_taskPrompt->setFixedHeight(96);
    layout->addWidget(m_taskPrompt);

    // Action row
    auto* actionRow = new QHBoxLayout;
    actionRow->setSpacing(8);

    m_runTaskBtn = new QPushButton(tr("Run Task"), page);
    m_runTaskBtn->setMinimumHeight(32);
    m_runTaskBtn->setProperty("accent", true);
    auto* runShortcut = new QShortcut(QKeySequence(Qt::CTRL | Qt::Key_Return), page);
    connect(runShortcut, &QShortcut::activated, this, &AgentRuntimeSidebarWidget::runTask);

    m_cancelTaskBtn = new QPushButton(tr("Cancel Task"), page);
    m_cancelTaskBtn->setMinimumHeight(32);
    m_cancelTaskBtn->setProperty("destructive", true);
    m_cancelTaskBtn->setVisible(false);

    actionRow->addWidget(m_runTaskBtn);
    actionRow->addWidget(m_cancelTaskBtn);
    layout->addLayout(actionRow);

    connect(m_runTaskBtn, &QPushButton::clicked, this, &AgentRuntimeSidebarWidget::runTask);
    connect(m_cancelTaskBtn, &QPushButton::clicked, this, &AgentRuntimeSidebarWidget::cancelCurrentTask);
}

void AgentRuntimeSidebarWidget::buildExplorerPage(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 8, 0, 0);
    layout->setSpacing(0);

    m_explorerTabs = new QTabWidget(page);
    m_explorerTabs->setDocumentMode(true);

    // Bookmarks sub-tab
    auto* bookmarksWidget = new QWidget(m_explorerTabs);
    auto* bookmarksLayout = new QVBoxLayout(bookmarksWidget);
    bookmarksLayout->setContentsMargins(0, 4, 0, 0);
    bookmarksLayout->setSpacing(4);
    m_bookmarkList = new QListWidget(bookmarksWidget);
    bookmarksLayout->addWidget(m_bookmarkList, 1);
    m_explorerTabs->addTab(bookmarksWidget, tr("Bookmarks"));

    // Reading List sub-tab
    auto* readingWidget = new QWidget(m_explorerTabs);
    auto* readingLayout = new QVBoxLayout(readingWidget);
    readingLayout->setContentsMargins(0, 4, 0, 0);
    readingLayout->setSpacing(4);
    m_readingList = new QListWidget(readingWidget);
    readingLayout->addWidget(m_readingList, 1);
    m_explorerTabs->addTab(readingWidget, tr("Reading List"));

    // History sub-tab
    auto* historyWidget = new QWidget(m_explorerTabs);
    auto* historyLayout = new QVBoxLayout(historyWidget);
    historyLayout->setContentsMargins(0, 4, 0, 0);
    historyLayout->setSpacing(4);
    m_historyList = new QListWidget(historyWidget);
    historyLayout->addWidget(m_historyList, 1);
    m_explorerTabs->addTab(historyWidget, tr("History"));

    layout->addWidget(m_explorerTabs, 1);

    // Navigate bookmarks on double-click
    connect(m_bookmarkList, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem* item) {
        const QUrl url(item->data(Qt::UserRole).toString());
        if (!url.isEmpty() && m_window && m_window->weView()) {
            m_window->weView()->load(url);
        }
    });

    // Navigate history on double-click
    connect(m_historyList, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem* item) {
        const QUrl url(item->data(Qt::UserRole).toString());
        if (!url.isEmpty() && m_window && m_window->weView()) {
            m_window->weView()->load(url);
        }
    });
}

void AgentRuntimeSidebarWidget::buildTabsPage(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 8, 0, 0);
    layout->setSpacing(8);

    // Pinned section
    auto* pinnedLabel = new QLabel(tr("Pinned"), page);
    pinnedLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(pinnedLabel);

    m_pinnedList = new QListWidget(page);
    layout->addWidget(m_pinnedList);

    // Groups section
    auto* groupsLabel = new QLabel(tr("Groups"), page);
    groupsLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(groupsLabel);

    m_groupList = new QListWidget(page);
    layout->addWidget(m_groupList);

    // Open now section
    auto* openLabel = new QLabel(tr("Open now"), page);
    openLabel->setObjectName(QSL("sectionLabel"));
    layout->addWidget(openLabel);

    m_openTabsList = new QListWidget(page);
    layout->addWidget(m_openTabsList, 1);
}

void AgentRuntimeSidebarWidget::buildToolsPage(QWidget* page)
{
    auto* layout = new QVBoxLayout(page);
    layout->setContentsMargins(0, 8, 0, 0);
    layout->setSpacing(8);

    // Page toggle checkboxes
    m_readerModeCheck = new QCheckBox(tr("Reader mode"), page);
    m_readerModeCheck->setMinimumHeight(32);
    layout->addWidget(m_readerModeCheck);

    m_focusHighlightCheck = new QCheckBox(tr("Focus highlight"), page);
    m_focusHighlightCheck->setMinimumHeight(32);
    layout->addWidget(m_focusHighlightCheck);

    m_forceDarkCheck = new QCheckBox(tr("Force dark site"), page);
    m_forceDarkCheck->setMinimumHeight(32);
    layout->addWidget(m_forceDarkCheck);

    // Annotate chip row (placeholder)
    auto* annotateLabel = new QLabel(tr("Annotate"), page);
    annotateLabel->setObjectName(QSL("chipRow"));
    annotateLabel->setMinimumHeight(32);
    layout->addWidget(annotateLabel);

    // FSB on this page: switches to FSB Agent mode (index 0)
    auto* fsbOnPageBtn = new QPushButton(tr("FSB on this page"), page);
    fsbOnPageBtn->setMinimumHeight(32);
    connect(fsbOnPageBtn, &QPushButton::clicked, this, [this]() {
        if (m_modeStack) {
            m_modeStack->setCurrentIndex(0);
        }
    });
    layout->addWidget(fsbOnPageBtn);

    layout->addStretch(1);
}

void AgentRuntimeSidebarWidget::runTask()
{
    if (!m_taskPrompt) {
        return;
    }

    const QString prompt = m_taskPrompt->toPlainText().trimmed();
    if (prompt.isEmpty()) {
        return;
    }

    QJsonObject context{
        {QSL("url"), currentUrl()},
        {QSL("origin"), currentOrigin()}
    };

    const QJsonObject submitted = mApp->agentRuntime()->submitTask(prompt, context, QSL("sidebar"), false);
    if (!submitted.value(QSL("ok")).toBool()) {
        if (m_agentStatus) {
            m_agentStatus->setText(submitted.value(QSL("message")).toString());
        }
        return;
    }

    const QString taskId = submitted.value(QSL("task")).toObject().value(QSL("id")).toString();
    m_currentTaskId = taskId;
    mApp->agentRuntime()->markTaskRunning(taskId, tr("Running from Prometheus sidebar"));
    mApp->agentRuntime()->appendTaskProgress(taskId, tr("Captured current browser context"), context);
    mApp->agentRuntime()->finishTask(taskId, tr("Prometheus accepted the task and stored the browser runtime outcome."), QJsonObject{
        {QSL("estimatedCostUsd"), 0.0},
        {QSL("modelRequests"), 0},
        {QSL("browserActions"), 0},
        {QSL("executionMode"), QSL("local")},
        {QSL("providerAvailable"), false},
        {QSL("unavailableReason"), QSL("provider_not_configured")}
    });
    m_taskPrompt->clear();
    refreshFsbAgent();
}

void AgentRuntimeSidebarWidget::cancelCurrentTask()
{
    if (m_currentTaskId.isEmpty()) {
        return;
    }

    mApp->agentRuntime()->cancelTask(m_currentTaskId, tr("Cancelled from sidebar"));
    refreshFsbAgent();
}

void AgentRuntimeSidebarWidget::refreshFsbAgent()
{
    if (!m_agentMessageStream) {
        return;
    }

    m_agentMessageStream->clear();

    const QJsonArray tasks = mApp->agentRuntime()->listTasks(20).value(QSL("tasks")).toArray();
    bool hasRunning = false;

    for (const QJsonValue &value : tasks) {
        const QJsonObject task = value.toObject();
        const QString status = task.value(QSL("status")).toString();
        const QString prompt = task.value(QSL("prompt")).toString();
        const QString progress = progressSummary(task);

        // Determine execution mode chip from metrics
        const QJsonObject metrics = task.value(QSL("metrics")).toObject();
        const QString executionMode = metrics.value(QSL("executionMode")).toString();
        QString executionChip;
        if (executionMode == QSL("provider")) {
            executionChip = tr(" [Execution: Provider]");
        } else if (executionMode == QSL("mcp")) {
            executionChip = tr(" [Execution: MCP]");
        } else if (!executionMode.isEmpty()) {
            executionChip = tr(" [Execution: Local/offline]");
        }

        // Build display text: role prefix + content
        QString displayText = QSL("User: %1").arg(prompt);
        if (!progress.isEmpty()) {
            displayText += QSL("\n  %1").arg(progress);
        }
        // AgentRuntime::finishTask stores status "complete" (not "completed").
        if (!executionChip.isEmpty() && (status == QSL("complete") || status == QSL("cancelled") || status == QSL("failed"))) {
            displayText += executionChip;
        }

        auto* item = new QListWidgetItem(displayText, m_agentMessageStream);
        item->setData(Qt::UserRole, task.value(QSL("id")).toString());

        if (status == QSL("running") || status == QSL("queued")) {
            hasRunning = true;
            if (task.value(QSL("id")).toString() == m_currentTaskId) {
                // Mark with System role prefix for active task
                item->setText(QSL("System: Working on task\nUser: %1").arg(prompt));
            }
        }
    }

    // Update status pill
    if (m_agentStatus) {
        m_agentStatus->setText(hasRunning ? tr("Working") : tr("Ready"));
    }

    // Update cancel button visibility
    if (m_cancelTaskBtn) {
        m_cancelTaskBtn->setVisible(hasRunning && !m_currentTaskId.isEmpty());
    }
}

void AgentRuntimeSidebarWidget::refreshExplorer()
{
    // Refresh bookmarks
    if (m_bookmarkList) {
        m_bookmarkList->clear();
        BookmarkItem* root = mApp->bookmarks()->rootItem();
        // Collect all URL bookmarks from the tree
        QList<BookmarkItem*> queue = root->children();
        while (!queue.isEmpty()) {
            BookmarkItem* item = queue.takeFirst();
            if (item->isUrl()) {
                auto* listItem = new QListWidgetItem(
                    QSL("%1\n%2").arg(item->title(), item->urlString()),
                    m_bookmarkList
                );
                listItem->setData(Qt::UserRole, item->url().toString());
            } else if (item->isFolder()) {
                queue.append(item->children());
            }
        }
        if (m_bookmarkList->count() == 0) {
            m_bookmarkList->addItem(tr("No bookmarks"));
        }
    }

    // Reading list: placeholder empty state (no reading list API in Phase 8)
    if (m_readingList && m_readingList->count() == 0) {
        m_readingList->addItem(tr("No reading list items"));
    }

    // Refresh history
    if (m_historyList) {
        m_historyList->clear();
        const QVector<HistoryEntry> entries = mApp->history()->mostVisited(50);
        for (const HistoryEntry &entry : entries) {
            auto* listItem = new QListWidgetItem(
                QSL("%1\n%2").arg(entry.title, entry.url.toString()),
                m_historyList
            );
            listItem->setData(Qt::UserRole, entry.url.toString());
        }
        if (m_historyList->count() == 0) {
            m_historyList->addItem(tr("No history"));
        }
    }
}

void AgentRuntimeSidebarWidget::refreshTabsMode()
{
    if (!m_window) {
        return;
    }

    TabModel* tabModel = m_window->tabModel();
    if (!tabModel) {
        return;
    }

    // Refresh pinned tabs
    if (m_pinnedList) {
        m_pinnedList->clear();
        const int count = tabModel->rowCount();
        for (int i = 0; i < count; ++i) {
            const QModelIndex idx = tabModel->index(i, 0);
            if (!idx.data(TabModel::PinnedRole).toBool()) {
                continue;
            }
            const QString title = idx.data(TabModel::TitleRole).toString();
            const QIcon icon = idx.data(TabModel::IconRole).value<QIcon>();
            const QString owner = idx.data(TabModel::TabOwnerRole).toString();
            const bool automation = idx.data(TabModel::ActiveAutomationRole).toBool();
            const bool supervision = idx.data(TabModel::SupervisionRole).toBool();

            QString badges;
            if (automation) {
                badges += QSL(" A");
            }
            if (supervision) {
                badges += QSL(" S");
            }
            if (!owner.isEmpty()) {
                badges += QSL(" [%1]").arg(owner);
            }

            auto* item = new QListWidgetItem(icon, title + badges, m_pinnedList);
            Q_UNUSED(item)
        }
        if (m_pinnedList->count() == 0) {
            m_pinnedList->addItem(tr("No pinned tabs"));
        }
    }

    // Refresh tab groups
    if (m_groupList) {
        m_groupList->clear();
        TabGroupModel* groupModel = m_window->tabWidget()->tabGroupModel();
        if (groupModel) {
            const QStringList groupIds = groupModel->groupIds();
            for (const QString &groupId : groupIds) {
                const QString groupName = groupModel->groupName(groupId);
                const int memberCount = groupModel->tabsInGroup(groupId).count();
                m_groupList->addItem(QSL("%1 (%2)").arg(groupName).arg(memberCount));
            }
        }
        if (m_groupList->count() == 0) {
            m_groupList->addItem(tr("No tab groups"));
        }
    }

    // Refresh open tabs
    if (m_openTabsList) {
        m_openTabsList->clear();
        const int count = tabModel->rowCount();
        for (int i = 0; i < count; ++i) {
            const QModelIndex idx = tabModel->index(i, 0);
            if (idx.data(TabModel::PinnedRole).toBool()) {
                continue; // pinned tabs shown separately
            }

            const QString title = idx.data(TabModel::TitleRole).toString();
            const QIcon icon = idx.data(TabModel::IconRole).value<QIcon>();
            const bool isCurrent = idx.data(TabModel::CurrentTabRole).toBool();
            const QString owner = idx.data(TabModel::TabOwnerRole).toString();
            const bool automation = idx.data(TabModel::ActiveAutomationRole).toBool();
            const bool supervision = idx.data(TabModel::SupervisionRole).toBool();

            QString badges;
            if (isCurrent) {
                badges += QSL(" *");
            }
            if (automation) {
                badges += QSL(" A");
            }
            if (supervision) {
                badges += QSL(" S");
            }
            if (!owner.isEmpty()) {
                badges += QSL(" [%1]").arg(owner);
            }

            auto* item = new QListWidgetItem(icon, title + badges, m_openTabsList);
            Q_UNUSED(item)
        }
        if (m_openTabsList->count() == 0) {
            m_openTabsList->addItem(tr("No open tabs"));
        }
    }
}

void AgentRuntimeSidebarWidget::refreshAll()
{
    refreshFsbAgent();
    refreshExplorer();
    refreshTabsMode();
}

QString AgentRuntimeSidebarWidget::currentUrl() const
{
    if (!m_window || !m_window->weView()) {
        return QString();
    }
    return m_window->weView()->url().toString();
}

QString AgentRuntimeSidebarWidget::currentOrigin() const
{
    const QUrl url(currentUrl());
    if (!url.isValid() || url.scheme().isEmpty() || url.host().isEmpty()) {
        return QString();
    }
    return QSL("%1://%2").arg(url.scheme(), url.host());
}
