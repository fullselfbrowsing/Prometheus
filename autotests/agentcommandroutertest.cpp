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

#include <QFile>
#include <QFileInfo>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpSocket>
#include <QStringList>

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
