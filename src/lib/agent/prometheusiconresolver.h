#pragma once
#include "qzcommon.h"
#include <QObject>
#include <QIcon>
#include <QHash>
#include <QPair>
#include <QString>

// Central icon authority for all Prometheus UI actions.
// Maps every named action ID from the 09-UI-SPEC.md action-to-glyph table to a
// deterministic QIcon using a 3-step fallback:
//   1. Bundled SVG resource (:/icons/fa/{glyph}.svg)
//   2. QIcon::fromTheme(themeFallback) if themeFallback is non-empty
//   3. 1x1 transparent QPixmap + qWarning (release gate catches this)
//
// For unknown action IDs (not in the map) icon() returns QIcon() and emits
// qWarning("PrometheusIconResolver: unknown actionId ...").
//
// Singleton: PrometheusIconResolver::instance() via Q_GLOBAL_STATIC.
// Thread-safety: s_actionMap is populated once at first instance() call;
// icon() is read-only after initialization (safe for concurrent reads).

class FALKON_EXPORT PrometheusIconResolver : public QObject
{
    Q_OBJECT
public:
    // Central lookup. actionId must be one of the action IDs in 09-UI-SPEC.md.
    static QIcon icon(const QString &actionId);

    static PrometheusIconResolver* instance();

    // Public constructor required by Q_GLOBAL_STATIC; callers must use instance().
    explicit PrometheusIconResolver(QObject* parent = nullptr);

private:

    // value: QPair<resourcePath, themeFallback>
    // themeFallback may be empty (no fromTheme fallback defined for that action)
    static QHash<QString, QPair<QString, QString>> s_actionMap;
    static void initActionMap();
    static bool s_mapInitialized;
};
