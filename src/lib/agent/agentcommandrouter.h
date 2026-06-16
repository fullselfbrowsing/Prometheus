#ifndef AGENTCOMMANDROUTER_H
#define AGENTCOMMANDROUTER_H

#include <QHash>
#include <QJsonObject>
#include <QJsonValue>
#include <QObject>
#include <QPointer>
#include <QSet>
#include <QTcpServer>
#include <QUrl>
#include <QVariant>

#include "qzcommon.h"

class BrowserWindow;
class QTcpSocket;
class TabbedWebView;
class WebTab;

class FALKON_EXPORT AgentCommandRouter : public QObject
{
    Q_OBJECT

public:
    explicit AgentCommandRouter(QObject* parent = nullptr);

    bool start(quint16 port);
    quint16 port() const;
    QJsonObject route(const QJsonObject &request);
    QJsonObject routeForSession(const QJsonObject &request, const QString &sessionKey);
    QJsonObject tabChromeState(int windowIndex, int tabIndex) const;

Q_SIGNALS:
    void tabChromeStateChanged(int windowIndex, int tabIndex);

private Q_SLOTS:
    void handleNewConnection();

private:
    struct Target {
        BrowserWindow* window = nullptr;
        TabbedWebView* view = nullptr;
        int windowIndex = -1;
        int tabIndex = -1;
    };

    void handleSocketReady(QTcpSocket* socket);
    void handleHttpRequest(QTcpSocket* socket, const QByteArray &headers, const QByteArray &body);
    void sendJson(QTcpSocket* socket, const QJsonObject &payload, int statusCode = 200, const QByteArray &statusText = QByteArrayLiteral("OK"));
    bool isAuthorizedAgentRequest(const QByteArray &headers, QString* sessionKey) const;
    QString issueAuthorizationToken();

    QJsonObject health();
    QJsonObject success(const QString &id, const QString &tool, const QJsonObject &result, quint64 auditSequence);
    QJsonObject failure(const QString &id, const QString &tool, const QString &code, const QString &message, quint64 auditSequence, const QJsonObject &details = QJsonObject());
    quint64 writeAudit(const QString &id, const QString &tool, bool ok, const QString &errorCode, const QJsonObject &details);

    bool resolveTarget(const QJsonObject &params, Target* target, QString* errorCode, QString* errorMessage) const;
    QJsonObject tabInfo(BrowserWindow* window, int windowIndex, int tabIndex) const;
    QJsonObject routeListTabs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeNewTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeActivateTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeNavigate(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeReload(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeCloseTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeReadPage(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeDomSnapshot(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routePageSnapshot(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeGetAttribute(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeExecuteJs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeOpenInternalSurface(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeManualAction(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeDiagnostics(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeLegacyVisualSession(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeSubmitTask(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeCancelTask(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeTaskStatus(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeProviderConfig(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeSetProviderConfig(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeRuntimeLogs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeRuntimeDiagnostics(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeMemory(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeVault(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);
    QJsonObject routeSupervision(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence);

    QJsonValue jsonFromVariant(const QVariant &value) const;
    QString auditPath() const;
    QString targetKey(int windowIndex, int tabIndex) const;
    QString targetKey(const Target &target) const;
    QString ensureTargetKey(const Target &target);
    QString existingTabKey(WebTab *tab) const;
    QString ensureTabKey(WebTab *tab);
    WebTab* webTabForTarget(const Target &target) const;
    bool currentTargetForKey(const QString &key, Target* target) const;
    QJsonObject buildSupervisionSnapshot(const Target &target, QString* snapshotHash) const;
    bool validateSupervisionSession(const QString &sessionId, const Target &target, QString* errorCode, QString* errorMessage) const;
    QUrl taskUrlFromPrompt(const QString &prompt) const;
    QString agentIdForParams(const QJsonObject &params, QString* errorCode, QString* errorMessage);
    bool enforceOwnership(const QJsonObject &params, const Target &target, QString* agentId, QString* errorCode, QString* errorMessage);
    QJsonObject visualDetails(const QJsonObject &params, const QString &agentId) const;
    bool hasActiveSupervision(const QString &key) const;
    QString sanitizedChromeStatus(const QString &status) const;
    void updateTabChromeState(const Target &target, const QString &tool, const QString &agentId, const QString &health, const QString &reason, bool activeAutomation);
    void setTabChromeFailure(const Target &target, const QString &tool, const QString &message);
    void clearTabChromeState(int windowIndex, int tabIndex);
    void clearTabStateForKey(const QString &key);
    void showActionStatus(const Target &target, const QString &tool, const QString &agentId, const QJsonObject &params);
    void waitForLoad(TabbedWebView* view, int timeoutMs);

    QTcpServer m_server;
    quint64 m_auditSequence;
    int m_nextAgentNumber;
    int m_agentCap;
    QHash<QString, QString> m_agentIds;
    QHash<QString, QString> m_tabOwners;
    QHash<QString, QJsonObject> m_tabChromeStates;
    QHash<QString, QJsonObject> m_supervisionSessions;
    QSet<QString> m_authorizedSessions;
};

#endif // AGENTCOMMANDROUTER_H
