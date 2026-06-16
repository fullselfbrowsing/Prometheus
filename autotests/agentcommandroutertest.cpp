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

#include <QJsonObject>

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

FALKONTEST_MAIN(AgentCommandRouterTest)
