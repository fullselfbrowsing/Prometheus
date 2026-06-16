/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2026 Lakshman Narayan
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* ============================================================ */
#include "agentcommandroutertest.h"
#include "agentcommandrouter.h"

#include "autotests.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "tabwidget.h"
#include "webtab.h"

#include <QFile>
#include <QFileInfo>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpSocket>
#include <QStringList>
#include <QUrl>

namespace {

QByteArray httpExchange(quint16 port, const QByteArray &request)
{
    QTcpSocket socket;
    socket.connectToHost(QHostAddress::LocalHost, port);
    if (!socket.waitForConnected(1000)) {
        return {};
    }

    socket.write(request);
    socket.flush();

    QByteArray response;
    while (socket.state() != QAbstractSocket::UnconnectedState) {
        if (socket.waitForReadyRead(1000)) {
            response.append(socket.readAll());
        } else {
            socket.disconnectFromHost();
        }
    }
    response.append(socket.readAll());
    return response;
}

QByteArray httpBody(const QByteArray &response)
{
    const int split = response.indexOf("\r\n\r\n");
    if (split < 0) {
        return {};
    }
    return response.mid(split + 4);
}

QJsonObject command(const QString &id, const QString &tool, const QJsonObject &params = {})
{
    return QJsonObject{
        {QSL("id"), id},
        {QSL("tool"), tool},
        {QSL("params"), params}
    };
}

} // namespace

void AgentCommandRouterTest::defaultTabChromeState()
{
    AgentCommandRouter router;

    const QJsonObject state = router.tabChromeState(0, 0);

    QCOMPARE(state.value(QSL("owner")).toString(), QString());
    QCOMPARE(state.value(QSL("activeAutomation")).toBool(), false);
    QCOMPARE(state.value(QSL("supervisionActive")).toBool(), false);
    QCOMPARE(state.value(QSL("health")).toString(), QSL("ok"));
    QCOMPARE(state.value(QSL("lastTool")).toString(), QString());
    QCOMPARE(state.value(QSL("visualReason")).toString(), QString());
    QVERIFY(!state.contains(QSL("params")));
    QVERIFY(!state.contains(QSL("prompt")));
    QVERIFY(!state.contains(QSL("secret")));
    QVERIFY(!state.contains(QSL("password")));
}

void AgentCommandRouterTest::httpCommandRequiresAuthorizationToken()
{
    AgentCommandRouter router;
    QVERIFY(router.start(0));

    const QByteArray healthResponse = httpExchange(router.port(),
        "GET /health HTTP/1.1\r\n"
        "Host: 127.0.0.1\r\n"
        "Connection: close\r\n\r\n");
    QVERIFY2(healthResponse.startsWith("HTTP/1.1 200"), healthResponse.constData());
    QVERIFY(!healthResponse.contains("Access-Control-Allow-Origin"));

    const QJsonObject health = QJsonDocument::fromJson(httpBody(healthResponse)).object();
    const QString token = health.value(QSL("authorization")).toObject().value(QSL("token")).toString();
    QVERIFY(!token.isEmpty());

    const QByteArray commandBody = R"({"id":"auth","tool":"list_tabs"})";
    QByteArray unauthenticatedRequest;
    unauthenticatedRequest.append("POST /agent/command HTTP/1.1\r\n");
    unauthenticatedRequest.append("Host: 127.0.0.1\r\n");
    unauthenticatedRequest.append("Content-Type: application/json\r\n");
    unauthenticatedRequest.append("Content-Length: ");
    unauthenticatedRequest.append(QByteArray::number(commandBody.size()));
    unauthenticatedRequest.append("\r\nConnection: close\r\n\r\n");
    unauthenticatedRequest.append(commandBody);

    const QByteArray unauthenticatedResponse = httpExchange(router.port(), unauthenticatedRequest);
    QVERIFY2(unauthenticatedResponse.startsWith("HTTP/1.1 401"), unauthenticatedResponse.constData());
    QVERIFY(!unauthenticatedResponse.contains("Access-Control-Allow-Origin"));
    const QJsonObject unauthenticated = QJsonDocument::fromJson(httpBody(unauthenticatedResponse)).object();
    QCOMPARE(unauthenticated.value(QSL("error")).toObject().value(QSL("code")).toString(), QSL("unauthorized"));

    QByteArray preflightRequest;
    preflightRequest.append("OPTIONS /agent/command HTTP/1.1\r\n");
    preflightRequest.append("Host: 127.0.0.1\r\n");
    preflightRequest.append("Access-Control-Request-Method: POST\r\n");
    preflightRequest.append("Access-Control-Request-Headers: content-type, authorization\r\n");
    preflightRequest.append("Connection: close\r\n\r\n");

    const QByteArray preflightResponse = httpExchange(router.port(), preflightRequest);
    QVERIFY2(preflightResponse.startsWith("HTTP/1.1 401"), preflightResponse.constData());
    QVERIFY(!preflightResponse.contains("Access-Control-Allow-Origin"));
}

void AgentCommandRouterTest::callerControlledClientLabelDoesNotGrantOwnership()
{
    BrowserWindow *window = mApp->createWindow(Qz::BW_NewWindow);
    QTRY_VERIFY(window->tabWidget()->count() > 0);

    AgentCommandRouter router;
    const QJsonObject firstOwner = router.routeForSession(command(QSL("own"),
                                                                  QSL("activate_tab"),
                                                                  QJsonObject{{QSL("client"), QSL("shared-label")}, {QSL("tabIndex"), 0}}),
                                                          QSL("session-one"));
    QVERIFY2(firstOwner.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(firstOwner).toJson(QJsonDocument::Compact))));
    const QString agentId = firstOwner.value(QSL("result")).toObject().value(QSL("agentId")).toString();
    QVERIFY(!agentId.isEmpty());

    const QJsonObject sameSession = router.routeForSession(command(QSL("same-session"),
                                                                   QSL("activate_tab"),
                                                                   QJsonObject{{QSL("client"), QSL("different-display-label")}, {QSL("tabIndex"), 0}}),
                                                           QSL("session-one"));
    QVERIFY2(sameSession.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(sameSession).toJson(QJsonDocument::Compact))));
    QCOMPARE(sameSession.value(QSL("result")).toObject().value(QSL("agentId")).toString(), agentId);

    const QJsonObject spoofedLabel = router.routeForSession(command(QSL("spoofed-label"),
                                                                    QSL("activate_tab"),
                                                                    QJsonObject{{QSL("client"), QSL("shared-label")}, {QSL("tabIndex"), 0}}),
                                                            QSL("session-two"));
    QCOMPARE(spoofedLabel.value(QSL("ok")).toBool(), false);
    QCOMPARE(spoofedLabel.value(QSL("error")).toObject().value(QSL("code")).toString(), QSL("TAB_OWNED_BY_OTHER_AGENT"));

    delete window;
}

void AgentCommandRouterTest::tabChromeStateFollowsStableTabIdentity()
{
    BrowserWindow *window = mApp->createWindow(Qz::BW_NewWindow);
    window->tabWidget()->addView(QUrl(QSL("data:text/html,<title>before</title>")));
    window->tabWidget()->addView(QUrl(QSL("data:text/html,<title>owned</title>")));
    QTRY_VERIFY(window->tabWidget()->count() >= 3);

    AgentCommandRouter router;
    WebTab *ownedTab = window->tabWidget()->webTab(2);
    QVERIFY(ownedTab);

    const QJsonObject firstOwner = router.routeForSession(command(QSL("own-stable-tab"),
                                                                  QSL("activate_tab"),
                                                                  QJsonObject{{QSL("client"), QSL("stable-owner")}, {QSL("tabIndex"), 2}}),
                                                          QSL("stable-session"));
    QVERIFY2(firstOwner.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(firstOwner).toJson(QJsonDocument::Compact))));
    const QString agentId = firstOwner.value(QSL("result")).toObject().value(QSL("agentId")).toString();
    QVERIFY(!agentId.isEmpty());

    const QJsonObject supervision = router.routeForSession(command(QSL("supervise-stable-tab"),
                                                                   QSL("start_supervision_session"),
                                                                   QJsonObject{{QSL("client"), QSL("stable-owner")}, {QSL("tabIndex"), 2}}),
                                                           QSL("stable-session"));
    QVERIFY2(supervision.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(supervision).toJson(QJsonDocument::Compact))));
    const QString sessionId = supervision.value(QSL("result")).toObject().value(QSL("session")).toObject().value(QSL("sessionId")).toString();
    QVERIFY(!sessionId.isEmpty());

    QCOMPARE(router.tabChromeState(0, 2).value(QSL("owner")).toString(), agentId);
    QCOMPARE(router.tabChromeState(0, 2).value(QSL("supervisionActive")).toBool(), true);

    window->tabWidget()->moveTab(2, 0);
    QCOMPARE(window->tabWidget()->webTab(0), ownedTab);
    QCOMPARE(router.tabChromeState(0, 0).value(QSL("owner")).toString(), agentId);
    QCOMPARE(router.tabChromeState(0, 0).value(QSL("supervisionActive")).toBool(), true);
    QCOMPARE(router.tabChromeState(0, 2).value(QSL("owner")).toString(), QString());

    window->tabWidget()->moveTab(0, 1);
    QCOMPARE(window->tabWidget()->webTab(1), ownedTab);
    window->tabWidget()->closeTab(0);
    QCOMPARE(window->tabWidget()->webTab(0), ownedTab);
    QCOMPARE(router.tabChromeState(0, 0).value(QSL("owner")).toString(), agentId);
    QCOMPARE(router.tabChromeState(0, 0).value(QSL("supervisionActive")).toBool(), true);

    window->tabWidget()->detachTab(ownedTab->tabIndex());
    QTRY_VERIFY(ownedTab->browserWindow() && ownedTab->browserWindow() != window);
    BrowserWindow *detachedWindow = ownedTab->browserWindow();
    const int detachedWindowIndex = mApp->windows().indexOf(detachedWindow);
    QVERIFY(detachedWindowIndex >= 0);
    QCOMPARE(router.tabChromeState(detachedWindowIndex, ownedTab->tabIndex()).value(QSL("owner")).toString(), agentId);
    QCOMPARE(router.tabChromeState(detachedWindowIndex, ownedTab->tabIndex()).value(QSL("supervisionActive")).toBool(), true);

    const QJsonObject ended = router.routeForSession(command(QSL("end-stable-supervision"),
                                                            QSL("end_supervision_session"),
                                                            QJsonObject{{QSL("sessionId"), sessionId}}),
                                                    QSL("stable-session"));
    QVERIFY2(ended.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(ended).toJson(QJsonDocument::Compact))));
    const QJsonObject endedTarget = ended.value(QSL("result")).toObject().value(QSL("target")).toObject();
    QCOMPARE(endedTarget.value(QSL("windowIndex")).toInt(), detachedWindowIndex);
    QCOMPARE(endedTarget.value(QSL("tabIndex")).toInt(), ownedTab->tabIndex());
    QCOMPARE(router.tabChromeState(detachedWindowIndex, ownedTab->tabIndex()).value(QSL("supervisionActive")).toBool(), false);

    delete detachedWindow;
    delete window;
}

void AgentCommandRouterTest::successfulActionDoesNotLeaveActiveAutomation()
{
    BrowserWindow *window = mApp->createWindow(Qz::BW_NewWindow);
    QTRY_VERIFY(window->tabWidget()->count() > 0);

    AgentCommandRouter router;
    const QJsonObject response = router.routeForSession(command(QSL("activate-complete"),
                                                               QSL("activate_tab"),
                                                               QJsonObject{{QSL("client"), QSL("completion-state")}, {QSL("tabIndex"), 0}}),
                                                       QSL("completion-session"));
    QVERIFY2(response.value(QSL("ok")).toBool(), qPrintable(QString::fromUtf8(QJsonDocument(response).toJson(QJsonDocument::Compact))));

    const QString agentId = response.value(QSL("result")).toObject().value(QSL("agentId")).toString();
    const QJsonObject state = router.tabChromeState(0, 0);
    QCOMPARE(state.value(QSL("owner")).toString(), agentId);
    QCOMPARE(state.value(QSL("lastTool")).toString(), QSL("activate_tab"));
    QCOMPARE(state.value(QSL("activeAutomation")).toBool(), false);
    QCOMPARE(state.value(QSL("health")).toString(), QSL("ok"));

    delete window;
}

void AgentCommandRouterTest::listTabsContractIncludesGroupAndStateFields()
{
    const QFileInfo testSource(QString::fromLocal8Bit(__FILE__));
    QFile routerSource(testSource.dir().filePath(QSL("../src/lib/agent/agentcommandrouter.cpp")));
    QVERIFY2(routerSource.open(QIODevice::ReadOnly | QIODevice::Text), qPrintable(routerSource.fileName()));

    const QString source = QString::fromUtf8(routerSource.readAll());
    const QStringList requiredTokens = {
        QSL("TabGroupIdRole"),
        QSL("TabGroupNameRole"),
        QSL("TabGroupColorRole"),
        QSL("TabGroupCollapsedRole"),
        QSL("groupId"),
        QSL("groupName"),
        QSL("groupColor"),
        QSL("groupCollapsed"),
        QSL("owner"),
        QSL("activeAutomation"),
        QSL("supervisionActive"),
        QSL("health")
    };

    for (const QString &token : requiredTokens) {
        const QByteArray message = QByteArray("AgentCommandRouter::tabInfo must expose ") + token.toUtf8();
        QVERIFY2(source.contains(token), message.constData());
    }
}

void AgentCommandRouterTest::unsupportedGroupMutationToolsReturnCompatibilityError()
{
    AgentCommandRouter router;
    const QStringList groupMutationTools = {
        QSL("create_tab_group"),
        QSL("rename_tab_group"),
        QSL("move_tab_to_group"),
        QSL("collapse_tab_group"),
        QSL("expand_tab_group"),
        QSL("close_tab_group")
    };

    for (const QString &tool : groupMutationTools) {
        const QJsonObject response = router.route(QJsonObject{
            {QSL("id"), tool},
            {QSL("tool"), tool},
            {QSL("params"), QJsonObject()}
        });

        const QJsonObject error = response.value(QSL("error")).toObject();
        QCOMPARE(response.value(QSL("ok")).toBool(), false);
        QCOMPARE(error.value(QSL("code")).toString(), QSL("unsupported_group_mutation"));
        QVERIFY2(error.value(QSL("message")).toString().contains(QSL("list_tabs")),
                 qPrintable(error.value(QSL("message")).toString()));
    }
}

FALKONTEST_MAIN(AgentCommandRouterTest)
