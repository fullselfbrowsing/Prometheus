#include "agentcommandrouter.h"

#include "agentruntime.h"
#include "browserwindow.h"
#include "datapaths.h"
#include "mainapplication.h"
#include "preferences.h"
#include "sidebar.h"
#include "statusbar.h"
#include "tabbedwebview.h"
#include "tabmodel.h"
#include "tabwidget.h"
#include "webpage.h"
#include "webtab.h"

#include <QDateTime>
#include <QCryptographicHash>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonValue>
#include <QCoreApplication>
#include <QRegularExpression>
#include <QTcpSocket>
#include <QUrl>
#include <QUuid>

namespace {

bool isUnsupportedGroupMutationTool(const QString &tool)
{
    return tool == QL1S("create_tab_group")
            || tool == QL1S("rename_tab_group")
            || tool == QL1S("move_tab_to_group")
            || tool == QL1S("collapse_tab_group")
            || tool == QL1S("expand_tab_group")
            || tool == QL1S("close_tab_group");
}

QByteArray headerValue(const QByteArray &headers, const QByteArray &wantedName)
{
    const QList<QByteArray> lines = headers.split('\n');
    for (QByteArray line : lines) {
        line = line.trimmed();
        const int colon = line.indexOf(':');
        if (colon < 0) {
            continue;
        }
        const QByteArray name = line.left(colon).trimmed().toLower();
        if (name == wantedName) {
            return line.mid(colon + 1).trimmed();
        }
    }
    return {};
}

}

AgentCommandRouter::AgentCommandRouter(QObject* parent)
    : QObject(parent)
    , m_auditSequence(0)
    , m_nextAgentNumber(1)
    , m_agentCap(4)
{
    bool ok = false;
    const int configuredCap = qgetenv("PROMETHEUS_AGENT_CAP").toInt(&ok);
    if (ok && configuredCap > 0) {
        m_agentCap = configuredCap;
    }

    connect(&m_server, &QTcpServer::newConnection, this, &AgentCommandRouter::handleNewConnection);
}

bool AgentCommandRouter::start(quint16 port)
{
    if (m_server.isListening()) {
        return true;
    }

    return m_server.listen(QHostAddress::LocalHost, port);
}

quint16 AgentCommandRouter::port() const
{
    return m_server.serverPort();
}

QJsonObject AgentCommandRouter::tabChromeState(int windowIndex, int tabIndex) const
{
    const QString key = targetKey(windowIndex, tabIndex);
    const QJsonObject storedState = m_tabChromeStates.value(key);
    QString health = storedState.value(QSL("health")).toString(QSL("ok"));
    if (health.isEmpty()) {
        health = QSL("ok");
    }

    return QJsonObject{
        {QSL("owner"), m_tabOwners.value(key)},
        {QSL("activeAutomation"), storedState.value(QSL("activeAutomation")).toBool(false)},
        {QSL("supervisionActive"), hasActiveSupervision(key)},
        {QSL("health"), health},
        {QSL("lastTool"), storedState.value(QSL("lastTool")).toString()},
        {QSL("visualReason"), storedState.value(QSL("visualReason")).toString()}
    };
}

QJsonObject AgentCommandRouter::route(const QJsonObject &request)
{
    return routeForSession(request, QSL("in-process"));
}

QJsonObject AgentCommandRouter::routeForSession(const QJsonObject &request, const QString &sessionKey)
{
    const QString id = request.value(QSL("id")).toVariant().toString();
    const QString tool = request.value(QSL("tool")).toString();
    QJsonObject params = request.value(QSL("params")).toObject();
    params.insert(QSL("_prometheusSessionKey"), sessionKey.isEmpty() ? QSL("in-process") : sessionKey);

    if (tool.isEmpty()) {
        return failure(id, tool, QSL("invalid_request"), QSL("Missing tool name."), 0);
    }

    if (tool == QL1S("start_visual_session") || tool == QL1S("end_visual_session")) {
        return routeLegacyVisualSession(id, tool, params, 0);
    }
    if (isUnsupportedGroupMutationTool(tool)) {
        return failure(id,
                       tool,
                       QSL("unsupported_group_mutation"),
                       QSL("Tab group mutation tools are not exposed through Prometheus agent routing. Use list_tabs for groupId, groupName, groupColor, groupCollapsed, owner, activeAutomation, supervisionActive, and health reads; use the native UI for group changes until an ownership-enforced mutation contract is added."),
                       0,
                       QJsonObject{{QSL("migration"), QSL("Read tab group state with list_tabs. Native group mutations remain UI-only in this release.")}});
    }
    if (tool == QL1S("diagnostics") || tool == QL1S("get_diagnostics")) {
        return routeDiagnostics(id, tool, params, 0);
    }
    if (tool == QL1S("submit_task")) {
        return routeSubmitTask(id, tool, params, 0);
    }
    if (tool == QL1S("cancel_task")) {
        return routeCancelTask(id, tool, params, 0);
    }
    if (tool == QL1S("task_status") || tool == QL1S("list_tasks")) {
        return routeTaskStatus(id, tool, params, 0);
    }
    if (tool == QL1S("get_provider_config") || tool == QL1S("list_providers") || tool == QL1S("discover_models")) {
        return routeProviderConfig(id, tool, params, 0);
    }
    if (tool == QL1S("set_provider_config")) {
        return routeSetProviderConfig(id, tool, params, 0);
    }
    if (tool == QL1S("list_runtime_logs") || tool == QL1S("action_history")) {
        return routeRuntimeLogs(id, tool, params, 0);
    }
    if (tool == QL1S("runtime_diagnostics")) {
        return routeRuntimeDiagnostics(id, tool, params, 0);
    }
    if (tool == QL1S("save_memory") || tool == QL1S("list_memory") || tool == QL1S("save_site_guide") || tool == QL1S("list_site_guides")) {
        return routeMemory(id, tool, params, 0);
    }
    if (tool == QL1S("create_vault_entry") || tool == QL1S("list_vault_entries") || tool == QL1S("vault_autofill")) {
        return routeVault(id, tool, params, 0);
    }
    if (tool == QL1S("create_supervision_pairing") || tool == QL1S("start_supervision_session") ||
        tool == QL1S("get_supervision_snapshot") || tool == QL1S("get_supervision_diff") ||
        tool == QL1S("end_supervision_session")) {
        return routeSupervision(id, tool, params, 0);
    }
    if (tool == QL1S("list_tabs")) {
        return routeListTabs(id, tool, params, 0);
    }
    if (tool == QL1S("new_tab")) {
        return routeNewTab(id, tool, params, 0);
    }
    if (tool == QL1S("activate_tab") || tool == QL1S("switch_tab")) {
        return routeActivateTab(id, tool, params, 0);
    }
    if (tool == QL1S("navigate") || tool == QL1S("go_to_url")) {
        return routeNavigate(id, tool, params, 0);
    }
    if (tool == QL1S("reload") || tool == QL1S("refresh")) {
        return routeReload(id, tool, params, 0);
    }
    if (tool == QL1S("close_tab")) {
        return routeCloseTab(id, tool, params, 0);
    }
    if (tool == QL1S("read_page") || tool == QL1S("get_text")) {
        return routeReadPage(id, tool, params, 0);
    }
    if (tool == QL1S("get_dom_snapshot")) {
        return routeDomSnapshot(id, tool, params, 0);
    }
    if (tool == QL1S("get_page_snapshot")) {
        return routePageSnapshot(id, tool, params, 0);
    }
    if (tool == QL1S("get_attribute")) {
        return routeGetAttribute(id, tool, params, 0);
    }
    if (tool == QL1S("execute_js")) {
        return routeExecuteJs(id, tool, params, 0);
    }
    if (tool == QL1S("open_internal_surface")) {
        return routeOpenInternalSurface(id, tool, params, 0);
    }
    if (tool == QL1S("click") || tool == QL1S("type") || tool == QL1S("type_text") ||
        tool == QL1S("press_key") || tool == QL1S("scroll") || tool == QL1S("hover") ||
        tool == QL1S("select") || tool == QL1S("clear") || tool == QL1S("drag_drop") ||
        tool == QL1S("wait_for_load")) {
        return routeManualAction(id, tool, params, 0);
    }

    return failure(id, tool, QSL("unsupported_tool"), QSL("Unsupported agent tool."), 0);
}

void AgentCommandRouter::handleNewConnection()
{
    while (QTcpSocket* socket = m_server.nextPendingConnection()) {
        socket->setParent(this);
        connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
            handleSocketReady(socket);
        });
        connect(socket, &QTcpSocket::disconnected, socket, &QTcpSocket::deleteLater);
    }
}

void AgentCommandRouter::handleSocketReady(QTcpSocket* socket)
{
    QByteArray buffer = socket->property("agentBuffer").toByteArray();
    buffer.append(socket->readAll());

    const int headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) {
        socket->setProperty("agentBuffer", buffer);
        return;
    }

    const QByteArray headers = buffer.left(headerEnd);
    int contentLength = 0;
    const QList<QByteArray> lines = headers.split('\n');
    for (QByteArray line : lines) {
        line = line.trimmed();
        const int colon = line.indexOf(':');
        if (colon < 0) {
            continue;
        }
        const QByteArray name = line.left(colon).trimmed().toLower();
        if (name == "content-length") {
            contentLength = line.mid(colon + 1).trimmed().toInt();
        }
    }

    const int bodyStart = headerEnd + 4;
    if (buffer.size() < bodyStart + contentLength) {
        socket->setProperty("agentBuffer", buffer);
        return;
    }

    const QByteArray body = buffer.mid(bodyStart, contentLength);
    handleHttpRequest(socket, headers, body);
}

void AgentCommandRouter::handleHttpRequest(QTcpSocket* socket, const QByteArray &headers, const QByteArray &body)
{
    const QByteArray firstLine = headers.left(headers.indexOf('\n')).trimmed();
    const QList<QByteArray> parts = firstLine.split(' ');
    const QByteArray method = parts.value(0);
    const QByteArray path = parts.value(1);

    if (method == "OPTIONS") {
        sendJson(socket, QJsonObject{
            {QSL("ok"), false},
            {QSL("error"), QJsonObject{
                {QSL("code"), QSL("unauthorized")},
                {QSL("message"), QSL("Agent command preflight requests are not authorized.")}
            }}
        }, 401, QByteArrayLiteral("Unauthorized"));
        return;
    }

    if (method == "GET" && path == "/health") {
        sendJson(socket, health());
        return;
    }

    if (method == "POST" && path == "/agent/command") {
        QString sessionKey;
        if (!isAuthorizedAgentRequest(headers, &sessionKey)) {
            sendJson(socket, QJsonObject{
                {QSL("ok"), false},
                {QSL("error"), QJsonObject{
                    {QSL("code"), QSL("unauthorized")},
                    {QSL("message"), QSL("Missing or invalid agent authorization.")}
                }}
            }, 401, QByteArrayLiteral("Unauthorized"));
            return;
        }

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(body, &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            sendJson(socket, QJsonObject{
                {QSL("ok"), false},
                {QSL("error"), QJsonObject{
                    {QSL("code"), QSL("invalid_json")},
                    {QSL("message"), parseError.errorString()}
                }}
            }, 400, QByteArrayLiteral("Bad Request"));
            return;
        }

        sendJson(socket, routeForSession(document.object(), sessionKey));
        return;
    }

    sendJson(socket, QJsonObject{
        {QSL("ok"), false},
        {QSL("error"), QJsonObject{
            {QSL("code"), QSL("not_found")},
            {QSL("message"), QSL("Unknown Prometheus agent endpoint.")}
        }}
    }, 404, QByteArrayLiteral("Not Found"));
}

void AgentCommandRouter::sendJson(QTcpSocket* socket, const QJsonObject &payload, int statusCode, const QByteArray &statusText)
{
    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    QByteArray response;
    response.append("HTTP/1.1 ");
    response.append(QByteArray::number(statusCode));
    response.append(' ');
    response.append(statusText);
    response.append("\r\nContent-Type: application/json\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: ");
    response.append(QByteArray::number(body.size()));
    response.append("\r\n\r\n");
    response.append(body);
    socket->write(response);
    socket->disconnectFromHost();
}

bool AgentCommandRouter::isAuthorizedAgentRequest(const QByteArray &headers, QString* sessionKey) const
{
    const QByteArray auth = headerValue(headers, QByteArrayLiteral("authorization"));
    QByteArray token;
    const QByteArray bearerPrefix = QByteArrayLiteral("Bearer ");
    if (auth.startsWith(bearerPrefix)) {
        token = auth.mid(bearerPrefix.size()).trimmed();
    }
    if (token.isEmpty()) {
        token = headerValue(headers, QByteArrayLiteral("x-prometheus-agent-token"));
    }

    const QString candidate = QString::fromLatin1(token);
    if (candidate.isEmpty() || !m_authorizedSessions.contains(candidate)) {
        return false;
    }

    if (sessionKey) {
        *sessionKey = candidate;
    }
    return true;
}

QString AgentCommandRouter::issueAuthorizationToken()
{
    QString token;
    do {
        token = QUuid::createUuid().toString(QUuid::Id128);
    } while (token.isEmpty() || m_authorizedSessions.contains(token));

    m_authorizedSessions.insert(token);
    return token;
}

QJsonObject AgentCommandRouter::health()
{
    const QString authorizationToken = issueAuthorizationToken();
    return QJsonObject{
        {QSL("ok"), true},
        {QSL("name"), QSL("Prometheus")},
        {QSL("version"), QString::fromLatin1(Qz::VERSION)},
        {QSL("port"), port()},
        {QSL("auditPath"), auditPath()},
        {QSL("authorization"), QJsonObject{
            {QSL("type"), QSL("bearer")},
            {QSL("header"), QSL("Authorization")},
            {QSL("token"), authorizationToken}
        }},
        {QSL("tools"), QJsonArray{
            QSL("list_tabs"),
            QSL("new_tab"),
            QSL("activate_tab"),
            QSL("navigate"),
            QSL("reload"),
            QSL("close_tab"),
            QSL("read_page"),
            QSL("get_text"),
            QSL("get_dom_snapshot"),
            QSL("get_page_snapshot"),
            QSL("execute_js"),
            QSL("open_internal_surface"),
            QSL("submit_task"),
            QSL("cancel_task"),
            QSL("task_status"),
            QSL("list_tasks"),
            QSL("get_provider_config"),
            QSL("set_provider_config"),
            QSL("list_runtime_logs"),
            QSL("runtime_diagnostics"),
            QSL("save_memory"),
            QSL("list_memory"),
            QSL("save_site_guide"),
            QSL("list_site_guides"),
            QSL("create_vault_entry"),
            QSL("list_vault_entries"),
            QSL("vault_autofill"),
            QSL("create_supervision_pairing"),
            QSL("start_supervision_session"),
            QSL("get_supervision_snapshot"),
            QSL("get_supervision_diff"),
            QSL("end_supervision_session")
        }}
    };
}

QJsonObject AgentCommandRouter::success(const QString &id, const QString &tool, const QJsonObject &result, quint64 auditSequence)
{
    Q_UNUSED(auditSequence)

    const quint64 successAuditSequence = writeAudit(id, tool, true, QString(), result);
    return QJsonObject{
        {QSL("ok"), true},
        {QSL("id"), id},
        {QSL("tool"), tool},
        {QSL("result"), result},
        {QSL("audit"), QJsonObject{{QSL("sequence"), static_cast<qint64>(successAuditSequence)}}}
    };
}

QJsonObject AgentCommandRouter::failure(const QString &id, const QString &tool, const QString &code, const QString &message, quint64 auditSequence, const QJsonObject &details)
{
    Q_UNUSED(auditSequence)

    const quint64 failureAuditSequence = writeAudit(id, tool, false, code, details);
    QJsonObject error{
        {QSL("code"), code},
        {QSL("message"), message}
    };
    if (!details.isEmpty()) {
        error.insert(QSL("details"), details);
    }

    return QJsonObject{
        {QSL("ok"), false},
        {QSL("id"), id},
        {QSL("tool"), tool},
        {QSL("error"), error},
        {QSL("audit"), QJsonObject{{QSL("sequence"), static_cast<qint64>(failureAuditSequence)}}}
    };
}

quint64 AgentCommandRouter::writeAudit(const QString &id, const QString &tool, bool ok, const QString &errorCode, const QJsonObject &details)
{
    const quint64 sequence = ++m_auditSequence;
    QJsonObject entry{
        {QSL("sequence"), static_cast<qint64>(sequence)},
        {QSL("timestamp"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)},
        {QSL("id"), id},
        {QSL("tool"), tool},
        {QSL("ok"), ok}
    };
    if (!errorCode.isEmpty()) {
        entry.insert(QSL("errorCode"), errorCode);
    }
    if (!details.isEmpty()) {
        entry.insert(QSL("details"), details);
    }

    QDir().mkpath(DataPaths::path(DataPaths::Config));
    QFile file(auditPath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        file.write(QJsonDocument(entry).toJson(QJsonDocument::Compact));
        file.write("\n");
    }

    return sequence;
}

bool AgentCommandRouter::resolveTarget(const QJsonObject &params, Target* target, QString* errorCode, QString* errorMessage) const
{
    const QList<BrowserWindow*> windows = mApp->windows();
    if (windows.isEmpty()) {
        *errorCode = QSL("no_window");
        *errorMessage = QSL("No browser window is available.");
        return false;
    }

    int windowIndex = params.value(QSL("windowIndex")).isDouble() ? params.value(QSL("windowIndex")).toInt() : 0;
    if (windowIndex < 0 || windowIndex >= windows.size()) {
        *errorCode = QSL("invalid_target");
        *errorMessage = QSL("windowIndex is out of range.");
        return false;
    }

    BrowserWindow* window = windows.at(windowIndex);
    TabWidget* tabs = window->tabWidget();
    if (!tabs || tabs->count() < 1) {
        *errorCode = QSL("no_tab");
        *errorMessage = QSL("No tab is available.");
        return false;
    }

    int tabIndex = params.value(QSL("tabIndex")).isDouble() ? params.value(QSL("tabIndex")).toInt() : tabs->currentIndex();
    if (tabIndex < 0 || tabIndex >= tabs->count()) {
        *errorCode = QSL("invalid_target");
        *errorMessage = QSL("tabIndex is out of range.");
        return false;
    }

    WebTab* tab = tabs->webTab(tabIndex);
    if (!tab || !tab->webView()) {
        *errorCode = QSL("invalid_target");
        *errorMessage = QSL("Target tab does not have a web view.");
        return false;
    }

    target->window = window;
    target->view = tab->webView();
    target->windowIndex = windowIndex;
    target->tabIndex = tabIndex;
    return true;
}

QJsonObject AgentCommandRouter::tabInfo(BrowserWindow* window, int windowIndex, int tabIndex) const
{
    WebTab* tab = window->tabWidget()->webTab(tabIndex);
    QJsonObject info{
        {QSL("windowIndex"), windowIndex},
        {QSL("tabIndex"), tabIndex},
        {QSL("current"), tabIndex == window->tabWidget()->currentIndex()},
        {QSL("url"), tab ? tab->url().toString() : QString()},
        {QSL("title"), tab ? tab->title(true) : QString()},
        {QSL("loading"), tab ? tab->isLoading() : false},
        {QSL("pinned"), tab ? tab->isPinned() : false}
    };
    const QJsonObject chromeState = tabChromeState(windowIndex, tabIndex);
    for (auto it = chromeState.constBegin(); it != chromeState.constEnd(); ++it) {
        info.insert(it.key(), it.value());
    }

    info.insert(QSL("groupId"), QString());
    info.insert(QSL("groupName"), QString());
    info.insert(QSL("groupColor"), QString());
    info.insert(QSL("groupCollapsed"), false);

    TabModel *model = window->tabModel();
    if (!tab || !model) {
        return info;
    }

    const QModelIndex modelIndex = model->tabIndex(tab);
    if (!modelIndex.isValid()) {
        return info;
    }

    info.insert(QSL("groupId"), modelIndex.data(TabModel::TabGroupIdRole).toString());
    info.insert(QSL("groupName"), modelIndex.data(TabModel::TabGroupNameRole).toString());
    info.insert(QSL("groupColor"), modelIndex.data(TabModel::TabGroupColorRole).toString());
    info.insert(QSL("groupCollapsed"), modelIndex.data(TabModel::TabGroupCollapsedRole).toBool());
    info.insert(QSL("owner"), modelIndex.data(TabModel::TabOwnerRole).toString());
    info.insert(QSL("activeAutomation"), modelIndex.data(TabModel::ActiveAutomationRole).toBool());
    info.insert(QSL("supervisionActive"), modelIndex.data(TabModel::SupervisionRole).toBool());
    const QString health = modelIndex.data(TabModel::TabHealthRole).toString();
    info.insert(QSL("health"), health.isEmpty() ? QSL("ok") : health);
    return info;
}

QJsonObject AgentCommandRouter::routeListTabs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Q_UNUSED(params)

    QJsonArray windowsJson;
    const QList<BrowserWindow*> windows = mApp->windows();
    for (int windowIndex = 0; windowIndex < windows.size(); ++windowIndex) {
        BrowserWindow* window = windows.at(windowIndex);
        QJsonArray tabsJson;
        for (int tabIndex = 0; tabIndex < window->tabWidget()->count(); ++tabIndex) {
            tabsJson.append(tabInfo(window, windowIndex, tabIndex));
        }
        windowsJson.append(QJsonObject{
            {QSL("windowIndex"), windowIndex},
            {QSL("current"), window == mApp->getWindow()},
            {QSL("tabCount"), window->tabWidget()->count()},
            {QSL("currentTabIndex"), window->tabWidget()->currentIndex()},
            {QSL("tabs"), tabsJson}
        });
    }

    return success(id, tool, QJsonObject{{QSL("windows"), windowsJson}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeNewTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    QString agentErrorCode;
    QString agentErrorMessage;
    const QString agentId = agentIdForParams(params, &agentErrorCode, &agentErrorMessage);
    if (agentId.isEmpty()) {
        return failure(id, tool, agentErrorCode, agentErrorMessage, auditSequence);
    }

    const QList<BrowserWindow*> windows = mApp->windows();
    if (windows.isEmpty()) {
        return failure(id, tool, QSL("no_window"), QSL("No browser window is available."), auditSequence);
    }

    const int windowIndex = params.value(QSL("windowIndex")).isDouble() ? params.value(QSL("windowIndex")).toInt() : 0;
    if (windowIndex < 0 || windowIndex >= windows.size()) {
        return failure(id, tool, QSL("invalid_target"), QSL("windowIndex is out of range."), auditSequence);
    }

    const QString rawUrl = params.value(QSL("url")).toString();
    const QUrl url = rawUrl.isEmpty() ? QUrl() : QUrl::fromUserInput(rawUrl);
    const int tabIndex = windows.at(windowIndex)->tabWidget()->addView(url, Qz::NT_SelectedTabAtTheEnd);
    m_tabOwners.insert(targetKey(windowIndex, tabIndex), agentId);
    Target target;
    target.window = windows.at(windowIndex);
    target.windowIndex = windowIndex;
    target.tabIndex = tabIndex;
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{{QSL("windowIndex"), windowIndex}, {QSL("tabIndex"), tabIndex}, {QSL("url"), url.toString()}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeActivateTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    target.window->tabWidget()->setCurrentIndex(target.tabIndex);
    target.window->activateWindow();
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeNavigate(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString rawUrl = params.value(QSL("url")).toString();
    if (rawUrl.isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing url parameter."), auditSequence);
    }

    const QUrl url = QUrl::fromUserInput(rawUrl);
    if (!url.isValid()) {
        return failure(id, tool, QSL("invalid_url"), QSL("URL is invalid."), auditSequence);
    }

    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    target.view->load(url);
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("url"), url.toString()}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeReload(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    target.view->reload();
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeCloseTab(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    showActionStatus(target, tool, agentId, params);
    m_tabOwners.remove(targetKey(target.windowIndex, target.tabIndex));
    clearTabChromeState(target.windowIndex, target.tabIndex);
    target.window->tabWidget()->requestCloseTab(target.tabIndex);
    return success(id, tool, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeReadPage(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    const QString script = QSL("(function(){return document.body ? document.body.innerText : (document.documentElement ? document.documentElement.innerText : '');})()");
    const QVariant value = target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 2000);
    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("url"), target.view->url().toString()},
        {QSL("text"), value.toString()}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeDomSnapshot(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    const QString script = QSL(R"JS(
(function(){
  const nodes = [];
  function ownText(el) {
    let text = '';
    for (const child of el.childNodes) {
      if (child.nodeType === Node.TEXT_NODE) text += child.textContent + ' ';
    }
    return text.trim().replace(/\s+/g, ' ').slice(0, 180);
  }
  function walk(el, depth) {
    if (!el || el.nodeType !== Node.ELEMENT_NODE || depth > 6 || nodes.length >= 200) return;
    nodes.push({
      depth,
      tag: el.tagName.toLowerCase(),
      id: el.id || '',
      role: el.getAttribute('role') || '',
      ariaLabel: el.getAttribute('aria-label') || '',
      text: ownText(el)
    });
    for (const child of el.children) walk(child, depth + 1);
  }
  walk(document.documentElement, 0);
  return nodes;
})()
)JS");

    const QVariant value = target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 3000);
    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("url"), target.view->url().toString()},
        {QSL("nodes"), jsonFromVariant(value)}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routePageSnapshot(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    const QString script = QSL(R"JS(
(function(){
  const active = document.activeElement;
  const text = document.body ? document.body.innerText : '';
  return {
    url: location.href,
    title: document.title,
    contentType: document.contentType,
    textSnippet: text.replace(/\s+/g, ' ').slice(0, 1000),
    viewport: {width: innerWidth, height: innerHeight, scrollX: scrollX, scrollY: scrollY},
    activeElement: active ? {tag: active.tagName.toLowerCase(), id: active.id || '', name: active.getAttribute('name') || ''} : null
  };
})()
)JS");

    const QVariant value = target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 3000);
    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("snapshot"), jsonFromVariant(value)}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeGetAttribute(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString selector = params.value(QSL("selector")).toString();
    const QString attribute = params.value(QSL("attribute")).toString();
    if (selector.isEmpty() || attribute.isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing selector or attribute parameter."), auditSequence);
    }

    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    const QJsonObject args{{QSL("selector"), selector}, {QSL("attribute"), attribute}};
    const QString script = QSL(R"JS(
(function(args){
  const el = document.querySelector(args.selector);
  if (!el) return {ok:false, errorCode:'ELEMENT_NOT_FOUND', message:'No element matched selector.'};
  const value = args.attribute === 'value' && 'value' in el ? el.value : el.getAttribute(args.attribute);
  return {ok:true, selector:args.selector, attribute:args.attribute, value};
})(%1)
)JS").arg(QString::fromUtf8(QJsonDocument(args).toJson(QJsonDocument::Compact)));

    const QJsonValue value = jsonFromVariant(target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 2000));
    const QJsonObject result = value.toObject();
    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("ELEMENT_NOT_FOUND")), result.value(QSL("message")).toString(), auditSequence);
    }

    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("attribute"), result}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeExecuteJs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString code = params.value(QSL("code")).toString();
    if (code.trimmed().isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing code parameter."), auditSequence);
    }

    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    const int timeout = params.value(QSL("timeoutMs")).isDouble() ? params.value(QSL("timeoutMs")).toInt() : 3000;
    const QVariant value = target.view->page()->execJavaScript(code, WebPage::UnsafeJsWorld, qBound(100, timeout, 10000));
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("url"), target.view->url().toString()},
        {QSL("value"), jsonFromVariant(value)},
        {QSL("agentId"), agentId},
        {QSL("visual"), visualDetails(params, agentId)}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeOpenInternalSurface(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString surface = params.value(QSL("surface")).toString(QSL("preferences"));
    const bool wantsPreferences = surface == QL1S("preferences");
    const bool wantsAgent = surface == QL1S("agent") || surface == QL1S("prometheus_agent") || surface == QL1S("runtime");
    if (!wantsPreferences && !wantsAgent) {
        return failure(id, tool, QSL("unsupported_surface"), QSL("Supported internal surfaces are preferences and prometheus_agent."), auditSequence);
    }

    const QList<BrowserWindow*> windows = mApp->windows();
    if (windows.isEmpty()) {
        return failure(id, tool, QSL("no_window"), QSL("No browser window is available."), auditSequence);
    }

    const int windowIndex = params.value(QSL("windowIndex")).isDouble() ? params.value(QSL("windowIndex")).toInt() : 0;
    if (windowIndex < 0 || windowIndex >= windows.size()) {
        return failure(id, tool, QSL("invalid_target"), QSL("windowIndex is out of range."), auditSequence);
    }

    QString agentErrorCode;
    QString agentErrorMessage;
    const QString agentId = agentIdForParams(params, &agentErrorCode, &agentErrorMessage);
    if (agentId.isEmpty()) {
        return failure(id, tool, agentErrorCode, agentErrorMessage, auditSequence);
    }

    if (wantsPreferences) {
        auto* preferences = new Preferences(windows.at(windowIndex));
        preferences->setAttribute(Qt::WA_DeleteOnClose);
        preferences->show();
        preferences->raise();
        preferences->activateWindow();
    } else {
        windows.at(windowIndex)->sideBarManager()->showSideBar(QSL("PrometheusAgent"), false);
    }

    Target target;
    target.window = windows.at(windowIndex);
    target.windowIndex = windowIndex;
    showActionStatus(target, tool, agentId, params);

    return success(id, tool, QJsonObject{{QSL("surface"), surface}, {QSL("windowIndex"), windowIndex}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
}

QJsonObject AgentCommandRouter::routeManualAction(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    QString agentId;
    if (!enforceOwnership(params, target, &agentId, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    if (tool == QL1S("wait_for_load")) {
        waitForLoad(target.view, params.value(QSL("timeoutMs")).toInt(3000));
        showActionStatus(target, tool, agentId, params);
        return success(id, tool, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("loading"), target.view->isLoading()}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
    }

    const QJsonObject args{
        {QSL("action"), tool},
        {QSL("selector"), params.value(QSL("selector")).toString()},
        {QSL("targetSelector"), params.value(QSL("targetSelector")).toString()},
        {QSL("text"), params.value(QSL("text")).toString(params.value(QSL("value")).toString())},
        {QSL("value"), params.value(QSL("value")).toString()},
        {QSL("key"), params.value(QSL("key")).toString()},
        {QSL("x"), params.value(QSL("x")).toDouble()},
        {QSL("y"), params.value(QSL("y")).toDouble()},
        {QSL("deltaX"), params.value(QSL("deltaX")).toDouble()},
        {QSL("deltaY"), params.value(QSL("deltaY")).toDouble(params.value(QSL("amount")).toDouble())}
    };

    const QString script = QSL(R"JS(
(function(args){
  function byTarget(selector, x, y) {
    if (selector) return document.querySelector(selector);
    if (Number.isFinite(x) && Number.isFinite(y)) return document.elementFromPoint(x, y);
    return document.activeElement || document.body;
  }
  function elementState(el) {
    if (!el) return null;
    return {
      tag: el.tagName ? el.tagName.toLowerCase() : '',
      id: el.id || '',
      value: 'value' in el ? el.value : '',
      text: (el.innerText || el.textContent || '').replace(/\s+/g, ' ').slice(0, 200),
      scrollX: scrollX,
      scrollY: scrollY,
      textLength: document.body ? document.body.innerText.length : 0
    };
  }
  const el = args.action === 'scroll' ? (document.scrollingElement || document.documentElement) : byTarget(args.selector, args.x, args.y);
  if (!el) return {ok:false, errorCode:'ELEMENT_NOT_FOUND', message:'No element matched selector or coordinates.'};
  const before = elementState(el);
  if (args.action === 'click') {
    el.focus && el.focus();
    el.click();
  } else if (args.action === 'type' || args.action === 'type_text') {
    el.focus && el.focus();
    if (!('value' in el)) return {ok:false, errorCode:'NOT_EDITABLE', message:'Target element does not accept text.'};
    el.value = String(args.text || '');
    el.dispatchEvent(new InputEvent('input', {bubbles:true, inputType:'insertText', data:String(args.text || '')}));
    el.dispatchEvent(new Event('change', {bubbles:true}));
  } else if (args.action === 'press_key') {
    const key = String(args.key || '');
    if (!key) return {ok:false, errorCode:'missing_param', message:'Missing key parameter.'};
    el.dispatchEvent(new KeyboardEvent('keydown', {key, bubbles:true}));
    el.dispatchEvent(new KeyboardEvent('keyup', {key, bubbles:true}));
  } else if (args.action === 'scroll') {
    scrollBy(Number(args.deltaX || 0), Number(args.deltaY || 0));
  } else if (args.action === 'hover') {
    el.dispatchEvent(new MouseEvent('mouseover', {bubbles:true, clientX:args.x || 0, clientY:args.y || 0}));
    el.dispatchEvent(new MouseEvent('mousemove', {bubbles:true, clientX:args.x || 0, clientY:args.y || 0}));
  } else if (args.action === 'select') {
    if (!('value' in el)) return {ok:false, errorCode:'NOT_SELECTABLE', message:'Target element does not accept a value.'};
    el.value = String(args.value || args.text || '');
    el.dispatchEvent(new Event('input', {bubbles:true}));
    el.dispatchEvent(new Event('change', {bubbles:true}));
  } else if (args.action === 'clear') {
    if (!('value' in el)) return {ok:false, errorCode:'NOT_EDITABLE', message:'Target element does not accept text.'};
    el.value = '';
    el.dispatchEvent(new InputEvent('input', {bubbles:true, inputType:'deleteContentBackward'}));
    el.dispatchEvent(new Event('change', {bubbles:true}));
  } else if (args.action === 'drag_drop') {
    const target = document.querySelector(args.targetSelector || '');
    if (!target) return {ok:false, errorCode:'DROP_TARGET_NOT_FOUND', message:'No drop target matched targetSelector.'};
    el.dispatchEvent(new MouseEvent('mousedown', {bubbles:true}));
    target.dispatchEvent(new MouseEvent('mousemove', {bubbles:true}));
    target.dispatchEvent(new MouseEvent('mouseup', {bubbles:true}));
  }
  const after = elementState(el);
  return {ok:true, action:args.action, selector:args.selector || '', before, after, changeDetected: JSON.stringify(before) !== JSON.stringify(after)};
})(%1)
)JS").arg(QString::fromUtf8(QJsonDocument(args).toJson(QJsonDocument::Compact)));

    const QJsonValue value = jsonFromVariant(target.view->page()->execJavaScript(script, WebPage::UnsafeJsWorld, 3000));
    const QJsonObject actionResult = value.toObject();
    if (!actionResult.value(QSL("ok")).toBool()) {
        const QString message = actionResult.value(QSL("message")).toString(QSL("Action failed."));
        setTabChromeFailure(target, tool, message);
        return failure(id, tool, actionResult.value(QSL("errorCode")).toString(QSL("action_failed")), message, auditSequence, QJsonObject{{QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}});
    }

    waitForLoad(target.view, params.value(QSL("waitMs")).toInt(250));
    showActionStatus(target, tool, agentId, params);
    return success(id, tool, QJsonObject{
        {QSL("windowIndex"), target.windowIndex},
        {QSL("tabIndex"), target.tabIndex},
        {QSL("agentId"), agentId},
        {QSL("visual"), visualDetails(params, agentId)},
        {QSL("changeReport"), actionResult},
        {QSL("loading"), target.view->isLoading()}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeSubmitTask(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString prompt = params.value(QSL("prompt")).toString(params.value(QSL("task")).toString());
    if (prompt.trimmed().isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing prompt parameter."), auditSequence);
    }

    QString agentErrorCode;
    QString agentErrorMessage;
    const QString agentId = agentIdForParams(params, &agentErrorCode, &agentErrorMessage);
    if (agentId.isEmpty()) {
        return failure(id, tool, agentErrorCode, agentErrorMessage, auditSequence);
    }

    Target target;
    QString targetErrorCode;
    QString targetErrorMessage;
    const bool explicitTarget = params.contains(QSL("windowIndex")) || params.contains(QSL("tabIndex"));
    const bool hasTarget = resolveTarget(params, &target, &targetErrorCode, &targetErrorMessage);
    if (explicitTarget && !hasTarget) {
        return failure(id, tool, targetErrorCode, targetErrorMessage, auditSequence);
    }

    QJsonObject context{
        {QSL("agentId"), agentId},
        {QSL("client"), params.value(QSL("client")).toVariant().toString()}
    };
    if (hasTarget) {
        context.insert(QSL("windowIndex"), target.windowIndex);
        context.insert(QSL("tabIndex"), target.tabIndex);
        context.insert(QSL("url"), target.view->url().toString());
    }

    const QJsonObject submitted = mApp->agentRuntime()->submitTask(prompt, context, QSL("router"), false);
    if (!submitted.value(QSL("ok")).toBool()) {
        return failure(id, tool, submitted.value(QSL("errorCode")).toString(QSL("task_error")), submitted.value(QSL("message")).toString(), auditSequence);
    }

    const QString taskId = submitted.value(QSL("task")).toObject().value(QSL("id")).toString();
    const bool run = params.value(QSL("run")).toBool(true);
    if (!run) {
        return success(id, tool, submitted, auditSequence);
    }

    mApp->agentRuntime()->markTaskRunning(taskId, QSL("Autopilot loop started"));

    int browserActions = 0;
    QString finalResult = QSL("Task accepted and completed in local Prometheus runtime mode.");
    const QUrl requestedUrl = taskUrlFromPrompt(prompt);
    if (requestedUrl.isValid() && !requestedUrl.isEmpty()) {
        if (!hasTarget) {
            mApp->agentRuntime()->failTask(taskId, QSL("NO_BROWSER_TARGET"), QSL("A browser target is required to open a URL."));
            return failure(id, tool, QSL("no_browser_target"), QSL("A browser target is required to open a URL."), auditSequence);
        }

        QString ownershipAgent;
        if (!enforceOwnership(params, target, &ownershipAgent, &targetErrorCode, &targetErrorMessage)) {
            mApp->agentRuntime()->failTask(taskId, targetErrorCode, targetErrorMessage);
            return failure(id, tool, targetErrorCode, targetErrorMessage, auditSequence, QJsonObject{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
        }

        target.view->load(requestedUrl);
        waitForLoad(target.view, params.value(QSL("timeoutMs")).toInt(5000));
        ++browserActions;
        mApp->agentRuntime()->appendTaskProgress(taskId, QSL("Opened requested URL"), QJsonObject{{QSL("url"), requestedUrl.toString()}});
        finalResult = QSL("Opened %1.").arg(requestedUrl.toString());
        showActionStatus(target, tool, ownershipAgent, params);
    } else if (hasTarget) {
        const QString script = QSL("(function(){return document.body ? document.body.innerText.replace(/\\s+/g,' ').slice(0,500) : '';})()");
        const QVariant value = target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 2000);
        mApp->agentRuntime()->appendTaskProgress(taskId, QSL("Captured page context"), QJsonObject{{QSL("url"), target.view->url().toString()}, {QSL("textSnippet"), value.toString()}});
        finalResult = QSL("Captured the current page context for the task.");
    }

    const QJsonObject finished = mApp->agentRuntime()->finishTask(taskId, finalResult, QJsonObject{{QSL("estimatedCostUsd"), 0.0}, {QSL("modelRequests"), 0}, {QSL("browserActions"), browserActions}});
    if (!finished.value(QSL("ok")).toBool()) {
        return failure(id, tool, finished.value(QSL("errorCode")).toString(QSL("task_error")), finished.value(QSL("message")).toString(), auditSequence);
    }

    return success(id, tool, finished, auditSequence);
}

QJsonObject AgentCommandRouter::routeCancelTask(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString taskId = params.value(QSL("taskId")).toString();
    if (taskId.isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing taskId parameter."), auditSequence);
    }

    const QJsonObject result = mApp->agentRuntime()->cancelTask(taskId, params.value(QSL("reason")).toString(QSL("Cancelled by client")));
    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("task_error")), result.value(QSL("message")).toString(), auditSequence);
    }
    return success(id, tool, result, auditSequence);
}

QJsonObject AgentCommandRouter::routeTaskStatus(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    if (tool == QL1S("list_tasks") || !params.contains(QSL("taskId"))) {
        return success(id, tool, mApp->agentRuntime()->listTasks(params.value(QSL("limit")).toInt(20)), auditSequence);
    }

    const QJsonObject result = mApp->agentRuntime()->taskStatus(params.value(QSL("taskId")).toString());
    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("task_error")), result.value(QSL("message")).toString(), auditSequence);
    }
    return success(id, tool, result, auditSequence);
}

QJsonObject AgentCommandRouter::routeProviderConfig(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Q_UNUSED(params)
    return success(id, tool, mApp->agentRuntime()->providerConfig(), auditSequence);
}

QJsonObject AgentCommandRouter::routeSetProviderConfig(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    const QString provider = params.value(QSL("provider")).toString();
    if (provider.isEmpty()) {
        return failure(id, tool, QSL("missing_param"), QSL("Missing provider parameter."), auditSequence);
    }

    QJsonObject config = params.value(QSL("config")).toObject();
    const QStringList keys{QSL("enabled"), QSL("displayName"), QSL("model"), QSL("endpoint"), QSL("models"), QSL("secret")};
    for (const QString &key : keys) {
        if (params.contains(key)) {
            config.insert(key, params.value(key));
        }
    }

    const QJsonObject result = mApp->agentRuntime()->saveProviderConfig(provider, config, false);
    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("provider_error")), result.value(QSL("message")).toString(), auditSequence);
    }
    return success(id, tool, result, auditSequence);
}

QJsonObject AgentCommandRouter::routeRuntimeLogs(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    return success(id, tool, mApp->agentRuntime()->listRuntimeLogs(params.value(QSL("limit")).toInt(50)), auditSequence);
}

QJsonObject AgentCommandRouter::routeRuntimeDiagnostics(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Q_UNUSED(params)
    return success(id, tool, mApp->agentRuntime()->diagnostics(), auditSequence);
}

QJsonObject AgentCommandRouter::routeMemory(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    if (tool == QL1S("list_memory")) {
        return success(id, tool, mApp->agentRuntime()->listMemory(), auditSequence);
    }
    if (tool == QL1S("list_site_guides")) {
        return success(id, tool, mApp->agentRuntime()->listSiteGuides(), auditSequence);
    }

    QJsonObject result;
    if (tool == QL1S("save_memory")) {
        result = mApp->agentRuntime()->saveMemory(params.value(QSL("key")).toString(), params.value(QSL("text")).toString(params.value(QSL("value")).toString()), params.value(QSL("url")).toString());
    } else {
        result = mApp->agentRuntime()->saveSiteGuide(params.value(QSL("origin")).toString(), params.value(QSL("instructions")).toString(params.value(QSL("text")).toString()));
    }

    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("runtime_error")), result.value(QSL("message")).toString(), auditSequence);
    }
    return success(id, tool, result, auditSequence);
}

QJsonObject AgentCommandRouter::routeVault(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    if (tool == QL1S("list_vault_entries")) {
        return success(id, tool, mApp->agentRuntime()->listVaultEntries(), auditSequence);
    }

    if (tool == QL1S("vault_autofill")) {
        return failure(id, tool, QSL("VAULT_NATIVE_CONFIRMATION_REQUIRED"), QSL("Vault secrets can only be injected through native UI with foreground confirmation."), auditSequence);
    }

    if (params.contains(QSL("secret")) || params.contains(QSL("password")) || params.contains(QSL("value"))) {
        return failure(id, tool, QSL("SECRET_TRANSPORT_BLOCKED"), QSL("Vault secrets cannot cross the Prometheus agent or MCP transports."), auditSequence);
    }

    const QJsonObject result = mApp->agentRuntime()->saveVaultEntryMetadata(params.value(QSL("origin")).toString(), params.value(QSL("label")).toString(), params.value(QSL("autofillAllowed")).toBool(false));
    if (!result.value(QSL("ok")).toBool()) {
        return failure(id, tool, result.value(QSL("errorCode")).toString(QSL("vault_error")), result.value(QSL("message")).toString(), auditSequence);
    }
    return success(id, tool, result, auditSequence);
}

QJsonObject AgentCommandRouter::routeSupervision(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    if (tool == QL1S("end_supervision_session")) {
        const QString sessionId = params.value(QSL("sessionId")).toString();
        if (sessionId.isEmpty() || !m_supervisionSessions.contains(sessionId)) {
            return failure(id, tool, QSL("STALE_SUPERVISION_SESSION"), QSL("Unknown or stale supervision session."), auditSequence);
        }

        const QJsonObject session = m_supervisionSessions.take(sessionId);
        const QJsonObject targetJson = session.value(QSL("target")).toObject();
        const int windowIndex = targetJson.value(QSL("windowIndex")).toInt(-1);
        const int tabIndex = targetJson.value(QSL("tabIndex")).toInt(-1);
        if (windowIndex >= 0 && tabIndex >= 0) {
            Q_EMIT tabChromeStateChanged(windowIndex, tabIndex);
        }
        return success(id, tool, QJsonObject{{QSL("sessionId"), sessionId}, {QSL("ended"), true}, {QSL("target"), session.value(QSL("target")).toObject()}}, auditSequence);
    }

    Target target;
    QString errorCode;
    QString errorMessage;
    if (!resolveTarget(params, &target, &errorCode, &errorMessage)) {
        return failure(id, tool, errorCode, errorMessage, auditSequence);
    }

    if (tool == QL1S("create_supervision_pairing") || tool == QL1S("start_supervision_session")) {
        QString agentErrorCode;
        QString agentErrorMessage;
        const QString agentId = agentIdForParams(params, &agentErrorCode, &agentErrorMessage);
        if (agentId.isEmpty()) {
            return failure(id, tool, agentErrorCode, agentErrorMessage, auditSequence);
        }

        QString snapshotHash;
        QJsonObject snapshot = buildSupervisionSnapshot(target, &snapshotHash);
        const QString sessionId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        const QString pairingCode = QUuid::createUuid().toString(QUuid::Id128).left(8).toUpper();
        const QJsonObject targetJson{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("key"), targetKey(target.windowIndex, target.tabIndex)}};
        QJsonObject session{
            {QSL("sessionId"), sessionId},
            {QSL("pairingCode"), pairingCode},
            {QSL("agentId"), agentId},
            {QSL("target"), targetJson},
            {QSL("createdAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)},
            {QSL("expiresAt"), QDateTime::currentDateTimeUtc().addSecs(600).toString(Qt::ISODateWithMs)},
            {QSL("sequence"), 1},
            {QSL("lastHash"), snapshotHash}
        };
        m_supervisionSessions.insert(sessionId, session);

        snapshot.insert(QSL("sequence"), 1);
        showActionStatus(target, tool, agentId, QJsonObject{{QSL("visual_reason"), QSL("Supervision session paired")}});
        return success(id, tool, QJsonObject{{QSL("session"), session}, {QSL("snapshot"), snapshot}}, auditSequence);
    }

    const QString sessionId = params.value(QSL("sessionId")).toString();
    if (!validateSupervisionSession(sessionId, target, &errorCode, &errorMessage)) {
        setTabChromeFailure(target, tool, errorMessage);
        return failure(id, tool, errorCode, errorMessage, auditSequence, QJsonObject{{QSL("sessionId"), sessionId}, {QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}});
    }

    QJsonObject session = m_supervisionSessions.value(sessionId);
    QString snapshotHash;
    QJsonObject snapshot = buildSupervisionSnapshot(target, &snapshotHash);
    const int nextSequence = session.value(QSL("sequence")).toInt(1) + 1;
    const QString previousHash = session.value(QSL("lastHash")).toString();
    const bool changed = previousHash != snapshotHash;
    session.insert(QSL("lastHash"), snapshotHash);
    session.insert(QSL("sequence"), nextSequence);
    session.insert(QSL("lastSeenAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs));
    m_supervisionSessions.insert(sessionId, session);

    snapshot.insert(QSL("sequence"), nextSequence);
    if (tool == QL1S("get_supervision_snapshot")) {
        return success(id, tool, QJsonObject{{QSL("sessionId"), sessionId}, {QSL("snapshot"), snapshot}, {QSL("changed"), changed}}, auditSequence);
    }

    QJsonObject diff{
        {QSL("sessionId"), sessionId},
        {QSL("sequence"), nextSequence},
        {QSL("changed"), changed},
        {QSL("previousHash"), previousHash},
        {QSL("hash"), snapshotHash}
    };
    if (changed) {
        diff.insert(QSL("snapshot"), snapshot);
        diff.insert(QSL("strategy"), QSL("hash_changed_full_snapshot"));
    } else {
        diff.insert(QSL("strategy"), QSL("no_dom_change"));
    }
    return success(id, tool, diff, auditSequence);
}

QJsonObject AgentCommandRouter::routeDiagnostics(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Q_UNUSED(params)

    QJsonObject ownership;
    for (auto it = m_tabOwners.constBegin(); it != m_tabOwners.constEnd(); ++it) {
        ownership.insert(it.key(), it.value());
    }

    return success(id, tool, QJsonObject{
        {QSL("browser"), QJsonObject{{QSL("name"), QSL("Prometheus")}, {QSL("version"), QString::fromLatin1(Qz::VERSION)}, {QSL("windowCount"), mApp->windowCount()}}},
        {QSL("server"), QJsonObject{{QSL("listening"), m_server.isListening()}, {QSL("port"), port()}, {QSL("auditPath"), auditPath()}}},
        {QSL("adapters"), QJsonObject{{QSL("tabs"), true}, {QSL("page"), true}, {QSL("internalSurface"), true}, {QSL("runtime"), true}, {QSL("sidebar"), true}, {QSL("supervision"), true}, {QSL("mcpBridge"), QSL("stdio")}}},
        {QSL("agents"), QJsonObject{{QSL("active"), m_agentIds.size()}, {QSL("cap"), m_agentCap}}},
        {QSL("ownership"), ownership},
        {QSL("runtime"), mApp->agentRuntime()->diagnostics()},
        {QSL("supervision"), QJsonObject{{QSL("activeSessions"), m_supervisionSessions.size()}}}
    }, auditSequence);
}

QJsonObject AgentCommandRouter::routeLegacyVisualSession(const QString &id, const QString &tool, const QJsonObject &params, quint64 auditSequence)
{
    Q_UNUSED(params)
    return failure(id, tool, QSL("legacy_visual_session_removed"), QSL("Explicit visual-session start/end tools are not used by Prometheus. Pass visual_reason, client, and is_final on action tools instead."), auditSequence);
}

QJsonValue AgentCommandRouter::jsonFromVariant(const QVariant &value) const
{
    const QJsonValue json = QJsonValue::fromVariant(value);
    return json.isUndefined() ? QJsonValue() : json;
}

QString AgentCommandRouter::auditPath() const
{
    return DataPaths::path(DataPaths::Config) + QLatin1String("/agent-audit.jsonl");
}

QString AgentCommandRouter::targetKey(int windowIndex, int tabIndex) const
{
    return QSL("%1:%2").arg(windowIndex).arg(tabIndex);
}

QJsonObject AgentCommandRouter::buildSupervisionSnapshot(const Target &target, QString* snapshotHash) const
{
    const QString script = QSL(R"JS(
(function(){
  const nodes = [];
  function ownText(el) {
    let text = '';
    for (const child of el.childNodes) {
      if (child.nodeType === Node.TEXT_NODE) text += child.textContent + ' ';
    }
    return text.trim().replace(/\s+/g, ' ').slice(0, 160);
  }
  function stablePath(el) {
    const parts = [];
    let current = el;
    while (current && current.nodeType === Node.ELEMENT_NODE && parts.length < 10) {
      let part = current.tagName.toLowerCase();
      if (current.id) {
        part += '#' + current.id;
        parts.unshift(part);
        break;
      }
      let index = 1;
      let sibling = current.previousElementSibling;
      while (sibling) {
        if (sibling.tagName === current.tagName) index++;
        sibling = sibling.previousElementSibling;
      }
      part += ':nth-of-type(' + index + ')';
      parts.unshift(part);
      current = current.parentElement;
    }
    return parts.join('>');
  }
  function walk(el, depth) {
    if (!el || el.nodeType !== Node.ELEMENT_NODE || depth > 7 || nodes.length >= 300) return;
    const rect = el.getBoundingClientRect();
    nodes.push({
      nodeId: stablePath(el),
      depth,
      tag: el.tagName.toLowerCase(),
      id: el.id || '',
      role: el.getAttribute('role') || '',
      ariaLabel: el.getAttribute('aria-label') || '',
      text: ownText(el),
      rect: {x: Math.round(rect.x), y: Math.round(rect.y), width: Math.round(rect.width), height: Math.round(rect.height)}
    });
    for (const child of el.children) walk(child, depth + 1);
  }
  walk(document.documentElement, 0);
  return {
    url: location.href,
    title: document.title,
    contentType: document.contentType,
    viewport: {width: innerWidth, height: innerHeight, scrollX: scrollX, scrollY: scrollY},
    nodeCount: nodes.length,
    nodes
  };
})()
)JS");

    QJsonObject snapshot = jsonFromVariant(target.view->page()->execJavaScript(script, WebPage::SafeJsWorld, 3000)).toObject();
    snapshot.insert(QSL("windowIndex"), target.windowIndex);
    snapshot.insert(QSL("tabIndex"), target.tabIndex);
    const QByteArray encoded = QJsonDocument(snapshot).toJson(QJsonDocument::Compact);
    const QString hash = QString::fromLatin1(QCryptographicHash::hash(encoded, QCryptographicHash::Sha256).toHex());
    snapshot.insert(QSL("hash"), hash);
    if (snapshotHash) {
        *snapshotHash = hash;
    }
    return snapshot;
}

bool AgentCommandRouter::validateSupervisionSession(const QString &sessionId, const Target &target, QString* errorCode, QString* errorMessage) const
{
    if (sessionId.isEmpty() || !m_supervisionSessions.contains(sessionId)) {
        *errorCode = QSL("STALE_SUPERVISION_SESSION");
        *errorMessage = QSL("Unknown or stale supervision session.");
        return false;
    }

    const QJsonObject session = m_supervisionSessions.value(sessionId);
    const QString expectedTarget = session.value(QSL("target")).toObject().value(QSL("key")).toString();
    if (expectedTarget != targetKey(target.windowIndex, target.tabIndex)) {
        *errorCode = QSL("SUPERVISION_TARGET_MISMATCH");
        *errorMessage = QSL("Supervision session belongs to a different tab.");
        return false;
    }

    const QDateTime expiresAt = QDateTime::fromString(session.value(QSL("expiresAt")).toString(), Qt::ISODateWithMs);
    if (expiresAt.isValid() && expiresAt < QDateTime::currentDateTimeUtc()) {
        *errorCode = QSL("STALE_SUPERVISION_SESSION");
        *errorMessage = QSL("Supervision session has expired.");
        return false;
    }

    return true;
}

QUrl AgentCommandRouter::taskUrlFromPrompt(const QString &prompt) const
{
    static const QRegularExpression re(QSL(R"((https?://[^\s"'<>]+|www\.[^\s"'<>]+))"));
    const QRegularExpressionMatch match = re.match(prompt);
    if (!match.hasMatch()) {
        return QUrl();
    }

    return QUrl::fromUserInput(match.captured(1));
}

QString AgentCommandRouter::agentIdForParams(const QJsonObject &params, QString* errorCode, QString* errorMessage)
{
    QString label = params.value(QSL("client")).toVariant().toString();
    if (label.isEmpty()) {
        label = params.value(QSL("clientLabel")).toVariant().toString();
    }
    if (label.isEmpty()) {
        label = QSL("local-default");
    }

    if (m_agentIds.contains(label)) {
        return m_agentIds.value(label);
    }

    if (m_agentIds.size() >= m_agentCap) {
        *errorCode = QSL("AGENT_CAP_REACHED");
        *errorMessage = QSL("The configured concurrent agent cap has been reached.");
        return QString();
    }

    const QString agentId = QSL("agent-%1").arg(m_nextAgentNumber++);
    m_agentIds.insert(label, agentId);
    return agentId;
}

bool AgentCommandRouter::enforceOwnership(const QJsonObject &params, const Target &target, QString* agentId, QString* errorCode, QString* errorMessage)
{
    *agentId = agentIdForParams(params, errorCode, errorMessage);
    if (agentId->isEmpty()) {
        return false;
    }

    const QString key = targetKey(target.windowIndex, target.tabIndex);
    const QString owner = m_tabOwners.value(key);
    if (owner.isEmpty()) {
        m_tabOwners.insert(key, *agentId);
        Q_EMIT tabChromeStateChanged(target.windowIndex, target.tabIndex);
        return true;
    }

    if (owner != *agentId) {
        *errorCode = QSL("TAB_OWNED_BY_OTHER_AGENT");
        *errorMessage = QSL("Target tab is owned by another agent.");
        setTabChromeFailure(target, QSL("ownership"), *errorMessage);
        return false;
    }

    return true;
}

QJsonObject AgentCommandRouter::visualDetails(const QJsonObject &params, const QString &agentId) const
{
    const QString reason = params.value(QSL("visual_reason")).toString(params.value(QSL("visualReason")).toString());
    return QJsonObject{
        {QSL("agentId"), agentId},
        {QSL("client"), params.value(QSL("client")).toVariant().toString()},
        {QSL("visual_reason"), reason},
        {QSL("is_final"), params.value(QSL("is_final")).toBool(params.value(QSL("isFinal")).toBool(false))}
    };
}

bool AgentCommandRouter::hasActiveSupervision(const QString &key) const
{
    for (auto it = m_supervisionSessions.constBegin(); it != m_supervisionSessions.constEnd(); ++it) {
        if (it.value().value(QSL("target")).toObject().value(QSL("key")).toString() == key) {
            return true;
        }
    }
    return false;
}

QString AgentCommandRouter::sanitizedChromeStatus(const QString &status) const
{
    QString text = status;
    text.replace(QRegularExpression(QSL("[\\r\\n\\t]+")), QSL(" "));
    text = text.simplified();

    static const int maxStatusLength = 120;
    if (text.size() > maxStatusLength) {
        text = text.left(maxStatusLength - 3) + QSL("...");
    }
    return text;
}

void AgentCommandRouter::updateTabChromeState(const Target &target, const QString &tool, const QString &agentId, const QString &health, const QString &reason, bool activeAutomation)
{
    if (target.windowIndex < 0 || target.tabIndex < 0) {
        return;
    }

    const QString key = targetKey(target.windowIndex, target.tabIndex);
    QJsonObject state = m_tabChromeStates.value(key);
    state.insert(QSL("activeAutomation"), activeAutomation);
    if (!tool.isEmpty()) {
        state.insert(QSL("lastTool"), tool);
    }
    if (!health.isEmpty()) {
        state.insert(QSL("health"), health);
    }
    const QString visualReason = sanitizedChromeStatus(reason);
    if (!visualReason.isEmpty()) {
        state.insert(QSL("visualReason"), visualReason);
    }
    if (!agentId.isEmpty()) {
        m_tabOwners.insert(key, agentId);
    }
    m_tabChromeStates.insert(key, state);
    Q_EMIT tabChromeStateChanged(target.windowIndex, target.tabIndex);
}

void AgentCommandRouter::setTabChromeFailure(const Target &target, const QString &tool, const QString &message)
{
    updateTabChromeState(target, tool, QString(), QSL("warning"), message, false);
}

void AgentCommandRouter::clearTabChromeState(int windowIndex, int tabIndex)
{
    m_tabChromeStates.remove(targetKey(windowIndex, tabIndex));
    Q_EMIT tabChromeStateChanged(windowIndex, tabIndex);
}

void AgentCommandRouter::showActionStatus(const Target &target, const QString &tool, const QString &agentId, const QJsonObject &params)
{
    QString reason = params.value(QSL("visual_reason")).toString(params.value(QSL("visualReason")).toString());
    if (reason.isEmpty()) {
        reason = tool;
    }
    updateTabChromeState(target, tool, agentId, QSL("ok"), reason, true);

    if (!target.window || !target.window->statusBar()) {
        return;
    }

    target.window->statusBar()->showMessage(QSL("%1 controlling Prometheus: %2").arg(agentId, sanitizedChromeStatus(reason)), 3000);
}

void AgentCommandRouter::waitForLoad(TabbedWebView* view, int timeoutMs)
{
    if (!view || timeoutMs <= 0) {
        return;
    }

    QElapsedTimer timer;
    timer.start();
    while (view->isLoading() && timer.elapsed() < timeoutMs) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 50);
    }
}
