#ifndef FSBCONTROLPANEL_H
#define FSBCONTROLPANEL_H

#include "qzcommon.h"

#include <QWidget>

class BrowserWindow;
class QCheckBox;
class QComboBox;
class QLabel;
class QLineEdit;
class QListWidget;
class QPlainTextEdit;
class QPushButton;
class QSpinBox;
class QStackedWidget;
class QTableWidget;

class FALKON_EXPORT FsbControlPanelPage : public QWidget
{
    Q_OBJECT

public:
    explicit FsbControlPanelPage(BrowserWindow* window, QWidget* parent = nullptr);

private:
    void buildTasksSection(QWidget* page);
    void buildProvidersSection(QWidget* page);
    void buildMcpStatusSection(QWidget* page);
    void buildPermissionsSection(QWidget* page);
    void buildVaultSection(QWidget* page);
    void buildMemorySiteGuidesSection(QWidget* page);
    void buildLogsDiagnosticsSection(QWidget* page);
    void buildSupervisionSection(QWidget* page);
    void buildParityMatrixSection(QWidget* page);

    // Refresh slots
    void refreshAll();
    void refreshDiagnostics();

    // Tasks section slots
    void runTask();
    void cancelTask();

    // Providers section slots
    void saveProvider();
    void discoverModels();

    // Memory & Site Guides section slots
    void saveMemory();
    void saveSiteGuide();

    // Vault section slots
    void saveVaultEntry();

    // Permissions section slots
    void savePermissions();

    // Supervision section slots
    void pairDashboard();
    void endPairing();

    // Parity Matrix section slots
    void openParityMatrix();
    void runParityCheck();

    BrowserWindow* m_window;
    QString m_currentTaskId;

    QStackedWidget* m_sectionStack;
    QListWidget* m_sectionRail;

    // Header status chips
    QLabel* m_mcpChip;
    QLabel* m_agentsChip;
    QLabel* m_vaultChip;
    QLabel* m_supervisionChip;

    // Tasks section widgets
    QPlainTextEdit* m_taskPrompt;
    QListWidget* m_taskList;

    // Providers section widgets
    QListWidget* m_providerList;
    QCheckBox* m_providerEnabled;
    QLineEdit* m_providerModel;
    QLineEdit* m_providerEndpoint;
    QLineEdit* m_providerSecret;
    QLabel* m_providerSecretState;
    QListWidget* m_modelList;
    QListWidget* m_fallbackOrderList;

    // MCP status section widgets
    QTableWidget* m_mcpTable;
    QLabel* m_mcpEmptyState;

    // Permissions section widgets
    QTableWidget* m_permissionsTable;
    QSpinBox* m_agentCapSpin;

    // Vault section widgets
    QListWidget* m_vaultList;
    QLineEdit* m_vaultOrigin;
    QLineEdit* m_vaultLabel;
    QLineEdit* m_vaultSecret;
    QCheckBox* m_vaultAutofill;

    // Memory section widgets
    QListWidget* m_memoryList;
    QLineEdit* m_memoryKey;
    QPlainTextEdit* m_memoryText;

    // Site Guides section widgets
    QListWidget* m_siteGuideList;
    QLineEdit* m_siteOrigin;
    QPlainTextEdit* m_siteGuideText;

    // Logs & Diagnostics section widgets
    QComboBox* m_logFilter;
    QPlainTextEdit* m_logView;
    QListWidget* m_diagGroupList;

    // Supervision section widgets
    QLabel* m_pairingCode;
    QLabel* m_sessionId;
    QLabel* m_sessionTarget;
    QLabel* m_sessionExpiry;
    QLabel* m_supervisionStatus;

    // Parity Matrix section widgets
    QTableWidget* m_parityTable;
    QPlainTextEdit* m_parityOutput;
};

#endif // FSBCONTROLPANEL_H
