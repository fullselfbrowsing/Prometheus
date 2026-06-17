#pragma once
#include "qzcommon.h"
#include <QWidget>
#include <QPaintEvent>

// PrometheusMarkWidget — the real PM monogram widget.
//
// Renders two QPainter text draws side-by-side:
//   P — Poppins Thin 100, palette WindowText color
//   M — Poppins Black 900, palette WindowText color
//
// Version tag ▽0.1 (U+25BD) is drawn below in Space Mono Regular 400,
// color #a99283 (--text-3), only when the lockup height is >= 28 px
// (i.e. Medium and Large sizes).
//
// Size rules from 09-UI-SPEC.md Logo Contract:
//   Compact (26): side panel header, 12 px letter size, no version tag
//   Medium  (64): start-page hero, 26 px letter size, version tag shown
//   Large  (128): about/first-run, 52 px letter size, version tag shown
//
// Background gradient is NOT painted by this widget; the parent is
// responsible for applying an accent gradient background via QSS
// (object name "PrometheusMark" for the 26x26 panel instance).

class FALKON_EXPORT PrometheusMarkWidget : public QWidget
{
    Q_OBJECT
public:
    enum Size {
        Compact = 26,   // Side panel header: 26x26 rounded-square area
        Medium  = 64,   // Start page hero: 64x64, letters + version tag
        Large   = 128   // About/first-run: 128x128, letters + version tag
    };

    explicit PrometheusMarkWidget(Size size = Compact, QWidget* parent = nullptr);

    QSize sizeHint() const override;
    QSize minimumSizeHint() const override;

protected:
    void paintEvent(QPaintEvent* event) override;

private:
    Size m_size;

    // Letter font pixel size derived from the lockup size.
    // Compact -> 12, Medium -> 26, Large -> 52.
    int letterPx() const;

    // Returns true when the lockup height is >= 28 px (Medium and Large).
    bool showVersionTag() const;
};
