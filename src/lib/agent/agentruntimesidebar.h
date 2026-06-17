#ifndef AGENTRUNTIMESIDEBAR_H
#define AGENTRUNTIMESIDEBAR_H

#include "sidebarinterface.h"

#include <QWidget>

class BrowserWindow;
class QCheckBox;
class QLabel;
class QLineEdit;
class QListWidget;
class QPlainTextEdit;
class QPushButton;
class QStackedWidget;
class QTabWidget;

class FALKON_EXPORT AgentRuntimeSidebarController : public SideBarInterface
{
    Q_OBJECT

public:
    explicit AgentRuntimeSidebarController(QObject* parent = nullptr);

    QString title() const override;
    QAction* createMenuAction() override;
    QWidget* createSideBarWidget(BrowserWindow* mainWindow) override;
};

class FALKON_EXPORT AgentRuntimeSidebarWidget : public QWidget
{
    Q_OBJECT

public:
    explicit AgentRuntimeSidebarWidget(BrowserWindow* window, QWidget* parent = nullptr);

public Q_SLOTS:
    void seedPromptAndOpen(const QString& prompt);

private:
    // Four mode builders
    void buildFsbAgentPage(QWidget* page);
    void buildExplorerPage(QWidget* page);
    void buildTabsPage(QWidget* page);
    void buildToolsPage(QWidget* page);

    // Slots for FSB Agent mode
    void runTask();
    void cancelCurrentTask();
    void refreshFsbAgent();

    // Slots for Explorer mode
    void refreshExplorer();

    // Slots for Tabs mode
    void refreshTabsMode();

    // Refresh all
    void refreshAll();

    QString currentUrl() const;
    QString currentOrigin() const;

    BrowserWindow* m_window;
    QString m_currentTaskId;

    QStackedWidget* m_modeStack;

    // FSB Agent mode widgets
    QPlainTextEdit* m_taskPrompt;
    QListWidget* m_agentMessageStream;
    QLabel* m_agentStatus;
    QPushButton* m_runTaskBtn;
    QPushButton* m_cancelTaskBtn;

    // Explorer mode widgets
    QTabWidget* m_explorerTabs;
    QListWidget* m_bookmarkList;
    QListWidget* m_readingList;
    QListWidget* m_historyList;

    // Tabs mode widgets
    QListWidget* m_pinnedList;
    QListWidget* m_groupList;
    QListWidget* m_openTabsList;

    // Tools mode widgets
    QCheckBox* m_readerModeCheck;
    QCheckBox* m_focusHighlightCheck;
    QCheckBox* m_forceDarkCheck;
};

#endif // AGENTRUNTIMESIDEBAR_H
