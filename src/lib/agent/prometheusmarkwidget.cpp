#include "prometheusmarkwidget.h"

#include <QColor>
#include <QFontDatabase>
#include <QFontMetrics>
#include <QPainter>
#include <QPainterPath>

PrometheusMarkWidget::PrometheusMarkWidget(Size size, QWidget* parent)
    : QWidget(parent)
    , m_size(size)
{
    setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    setAttribute(Qt::WA_OpaquePaintEvent, false);
}

QSize PrometheusMarkWidget::sizeHint() const
{
    return QSize(m_size, m_size);
}

QSize PrometheusMarkWidget::minimumSizeHint() const
{
    return sizeHint();
}

int PrometheusMarkWidget::letterPx() const
{
    switch (m_size) {
    case Compact: return 12;
    case Medium:  return 26;
    case Large:   return 52;
    }
    return 12;
}

bool PrometheusMarkWidget::showVersionTag() const
{
    // 09-UI-SPEC.md: show version tag when lockup height >= 28 px.
    // Compact = 26, so no tag. Medium (64) and Large (128) show it.
    return static_cast<int>(m_size) >= 28;
}

void PrometheusMarkWidget::paintEvent(QPaintEvent* /*event*/)
{
    QPainter p(this);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.setRenderHint(QPainter::TextAntialiasing, true);

    const int px = letterPx();
    const QColor textColor = palette().color(QPalette::WindowText);

    // --- Poppins Thin 100 for "P" ---
    QFont fontP = QFontDatabase::font(QSL("Poppins"), QSL("Thin"), 0);
    if (fontP.family().isEmpty() || fontP.family() != QSL("Poppins")) {
        // Family not registered yet or lookup returned a system fallback — try again
        fontP = QFontDatabase::font(QSL("Poppins"), QSL("Thin"), px);
    }
    fontP.setPixelSize(px);
    fontP.setWeight(QFont::Thin);  // ensure Qt weight 100 mapping

    // --- Poppins Black 900 for "M" ---
    QFont fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), 0);
    if (fontM.family().isEmpty() || fontM.family() != QSL("Poppins")) {
        // QFontDatabase::font() returns a non-empty system fallback when the requested family is
        // absent, so isEmpty() alone is insufficient. Retry with an explicit pixel size.
        fontM = QFontDatabase::font(QSL("Poppins"), QSL("Black"), px);
        if (fontM.family() != QSL("Poppins")) {
            qWarning("PrometheusMarkWidget: Poppins Black not found, falling back to %s",
                     qPrintable(fontM.family()));
        }
    }
    fontM.setPixelSize(px);
    fontM.setWeight(QFont::Black);  // Qt weight 900 mapping

    // Measure both letters so we can center the combined block.
    const QFontMetrics fmP(fontP);
    const QFontMetrics fmM(fontM);

    const int wP = fmP.horizontalAdvance(QLatin1Char('P'));
    const int wM = fmM.horizontalAdvance(QLatin1Char('M'));
    const int totalLetterW = wP + wM;

    // The tallest ascent among the two fonts determines the baseline.
    const int ascP = fmP.ascent();
    const int ascM = fmM.ascent();
    const int letterAsc = qMax(ascP, ascM);

    // Vertical block height: the letter row only (no version tag row for Compact).
    const int letterBlockH = letterAsc + qMax(fmP.descent(), fmM.descent());

    // If we will show a version tag, factor in its height below the letter row.
    // Space Mono at max(8, px/4) pixels.
    const int tagPx = qMax(8, px / 4);
    QFont fontTag = QFontDatabase::font(QSL("Space Mono"), QSL("Regular"), 0);
    if (fontTag.family().isEmpty() || fontTag.family() != QSL("Space Mono")) {
        // QFontDatabase::font() returns a non-empty system fallback when the requested family is
        // absent, so isEmpty() alone is insufficient. Fall back to generic monospace and warn.
        qWarning("PrometheusMarkWidget: Space Mono not found, falling back to monospace");
        fontTag.setFamily(QSL("monospace"));
    }
    fontTag.setPixelSize(tagPx);

    const QFontMetrics fmTag(fontTag);
    // Version tag string: ▽ (U+25BD) followed by "0.1"
    const QString tagStr = QString(QChar(0x25BD)) + QSL("0.1");
    const int tagH = showVersionTag() ? (fmTag.ascent() + fmTag.descent() + 2) : 0;

    const int totalBlockH = letterBlockH + tagH;

    // Center the entire block vertically and horizontally.
    const int startX = (width() - totalLetterW) / 2;
    const int startY = (height() - totalBlockH) / 2 + letterAsc;

    // Draw "P" in Thin 100
    p.setFont(fontP);
    p.setPen(textColor);
    p.drawText(startX, startY, QLatin1String("P"));

    // Draw "M" in Black 900 immediately after "P" with no gap
    p.setFont(fontM);
    p.setPen(textColor);
    p.drawText(startX + wP, startY, QLatin1String("M"));

    // Draw version tag below the letter row when lockup height >= 28 px
    if (showVersionTag()) {
        const int tagW = fmTag.horizontalAdvance(tagStr);
        const int tagX = (width() - tagW) / 2;
        const int tagY = startY + letterBlockH - letterAsc + fmTag.ascent() + 2;

        const QColor tagColor(0xa9, 0x92, 0x83);  // --text-3 from 09-UI-SPEC.md

        p.setFont(fontTag);
        p.setPen(tagColor);
        p.drawText(tagX, tagY, tagStr);
    }
}
