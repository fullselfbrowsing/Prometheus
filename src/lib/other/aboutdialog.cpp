/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2010-2018 David Rosca <nowrep@gmail.com>
* Copyright (C) 2020-2025 Juraj Oravec <jurajoravec@mailo.com>
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
#include "aboutdialog.h"
#include "ui_aboutdialog.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "webpage.h"
#include "useragentmanager.h"
#include "agent/prometheusmarkwidget.h"
#include "../config.h"

#include <QFile>
#include <QTextStream>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QDialog>
#include <QTextBrowser>
#include <QWebEnginePage>
#include <QWebEngineProfile>
#include <QtWebEngineCoreVersion>

AboutDialog::AboutDialog(QWidget* parent)
    : QDialog(parent)
    , ui(new Ui::AboutDialog)
    , m_markWidget(nullptr)
{
    setAttribute(Qt::WA_DeleteOnClose);

    ui->setupUi(this);

    // Replace the static logo label with the real PrometheusMarkWidget(Large).
    // The UI file has a QLabel named "label" at the top of the vertical layout.
    // We replace it with the 128x128 PM monogram widget.
    m_markWidget = new PrometheusMarkWidget(PrometheusMarkWidget::Large, this);
    m_markWidget->setObjectName(QSL("PrometheusMarkAbout"));

    // Swap the QLabel out: find its position in the layout and replace it.
    QVBoxLayout* vbox = qobject_cast<QVBoxLayout*>(layout());
    if (vbox) {
        // The label is at index 0 in the vertical layout.
        QLayoutItem* labelItem = vbox->takeAt(0);
        if (labelItem) {
            if (labelItem->widget()) {
                labelItem->widget()->hide();
            }
            delete labelItem;
        }
        vbox->insertWidget(0, m_markWidget, 0, Qt::AlignHCenter);
    } else {
        // Fallback: just hide the old label and let the mark widget appear at top.
        ui->label->hide();
    }

    showAbout();
}

AboutDialog::~AboutDialog()
{
    delete ui;
}

void AboutDialog::showAbout()
{
    QString aboutHtml;
    aboutHtml += QSL("<div style='margin:0px 20px;'>");
    aboutHtml += QSL("<p><b>Prometheus</b> &mdash; agentic browser &middot; by FSB</p>");
    aboutHtml += tr("<p><b>Application version %1</b><br/>").arg(
#ifdef FALKON_GIT_REVISION
                       QString(QSL("%1 (%2)")).arg(QString::fromLatin1(Qz::VERSION), QL1S(FALKON_GIT_REVISION))
#else
                       QString::fromLatin1(Qz::VERSION)
#endif
                   );
    aboutHtml += tr("<b>QtWebEngine version %1</b></p>").arg(QStringLiteral(QTWEBENGINECORE_VERSION_STR));

    aboutHtml += QSL("<p>");

    for (const auto &author : Qz::AUTHORS) {
        aboutHtml += QStringLiteral("&copy; %1-%2 %3<br/>").arg(
            QString::number(author.copyrightBegin),
            QString::number(author.copyrightEnd),
            author.name
        );
    }

    aboutHtml += QStringLiteral("<a href=%1>%1</a></p>").arg(QString::fromLatin1(Qz::WWWADDRESS));
    aboutHtml += QStringLiteral("<p>") + mApp->userAgentManager()->defaultUserAgent() + QStringLiteral("</p>");

    // Font license section — reads OFL texts from Qt resources (:/fonts/poppins/OFL.txt etc.)
    // Satisfies ICON-04 gate: "Poppins OFL or Space Mono OFL absent from legal/about surface"
    auto readOfl = [](const QString& path) -> QString {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return QStringLiteral("License information unavailable.");
        }
        QTextStream ts(&f);
        return ts.readAll().toHtmlEscaped().left(4000) + QSL("&hellip;");
    };

    aboutHtml += QSL("<hr/><p><b>Font Licenses</b></p>");
    aboutHtml += QSL("<p><b>Poppins</b> (SIL Open Font License 1.1)<br/>");
    aboutHtml += QSL("<details><summary>Show Poppins OFL</summary><pre style='font-size:9px;'>");
    aboutHtml += readOfl(QSL(":/fonts/poppins/OFL.txt"));
    aboutHtml += QSL("</pre></details></p>");

    aboutHtml += QSL("<p><b>Space Mono</b> (SIL Open Font License 1.1)<br/>");
    aboutHtml += QSL("<details><summary>Show Space Mono OFL</summary><pre style='font-size:9px;'>");
    aboutHtml += readOfl(QSL(":/fonts/spacemono/OFL.txt"));
    aboutHtml += QSL("</pre></details></p>");

    aboutHtml += QStringLiteral("</div>");
    ui->textLabel->setText(aboutHtml);
    setFixedHeight(sizeHint().height());
}
