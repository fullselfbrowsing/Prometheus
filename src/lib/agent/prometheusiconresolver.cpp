#include "prometheusiconresolver.h"
#include <QPainter>
#include <QPixmap>
#include <QGlobalStatic>
#include <QSettings>

// ---- static member definitions ----
QHash<QString, QPair<QString, QString>> PrometheusIconResolver::s_actionMap;
bool PrometheusIconResolver::s_mapInitialized = false;

// ---- singleton storage ----
Q_GLOBAL_STATIC(PrometheusIconResolver, s_instance)

namespace {

QColor prometheusIconColor()
{
    QSettings settings;
    const bool useDark = settings.value(QSL("Interface/PrometheusThemeDark"), true).toBool();
    return useDark ? QColor(QSL("#d2c1b4")) : QColor(QSL("#6a584d"));
}

QIcon tintedIcon(const QIcon &source)
{
    if (source.isNull()) {
        return source;
    }

    const QColor normalColor = prometheusIconColor();
    QColor disabledColor = normalColor;
    disabledColor.setAlphaF(0.35);

    QIcon result;
    const QList<int> sizes = {11, 14, 16, 18, 22, 24, 32, 48, 64};
    for (int size : sizes) {
        const QPixmap base = source.pixmap(size, size);
        if (base.isNull()) {
            continue;
        }

        auto tintPixmap = [&base](const QColor &color) {
            QPixmap tinted(base.size());
            tinted.setDevicePixelRatio(base.devicePixelRatio());
            tinted.fill(Qt::transparent);

            QPainter painter(&tinted);
            painter.drawPixmap(0, 0, base);
            painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
            painter.fillRect(tinted.rect(), color);
            return tinted;
        };

        result.addPixmap(tintPixmap(normalColor), QIcon::Normal);
        result.addPixmap(tintPixmap(disabledColor), QIcon::Disabled);
    }

    return result.isNull() ? source : result;
}

} // namespace

PrometheusIconResolver::PrometheusIconResolver(QObject* parent)
    : QObject(parent)
{
    if (!s_mapInitialized) {
        initActionMap();
        s_mapInitialized = true;
    }
}

PrometheusIconResolver* PrometheusIconResolver::instance()
{
    return s_instance();
}

// --- Action map: every row from 09-UI-SPEC.md action-to-glyph tables ---
// Covers: nav, agent, MCP, provider, vault, diag/supervision,
//         tab, page tools, settings, utility, mode tabs (side-panel switcher).
void PrometheusIconResolver::initActionMap()
{
    // ---- Browser navigation actions ----
    s_actionMap.insert(QSL("nav-back"),             qMakePair(QSL(":/icons/fa/arrow-left.svg"),           QSL("go-previous")));
    s_actionMap.insert(QSL("nav-forward"),          qMakePair(QSL(":/icons/fa/arrow-right.svg"),          QSL("go-next")));
    s_actionMap.insert(QSL("nav-reload"),           qMakePair(QSL(":/icons/fa/rotate-right.svg"),         QSL("view-refresh")));
    s_actionMap.insert(QSL("nav-stop"),             qMakePair(QSL(":/icons/fa/xmark.svg"),                QSL("process-stop")));
    s_actionMap.insert(QSL("nav-home"),             qMakePair(QSL(":/icons/fa/house.svg"),                QSL("go-home")));
    s_actionMap.insert(QSL("nav-new-tab"),          qMakePair(QSL(":/icons/fa/plus.svg"),                 QSL("list-add")));
    s_actionMap.insert(QSL("nav-close-tab"),        qMakePair(QSL(":/icons/fa/xmark.svg"),                QSL("window-close")));
    s_actionMap.insert(QSL("nav-search"),           qMakePair(QSL(":/icons/fa/magnifying-glass.svg"),     QSL("edit-find")));
    s_actionMap.insert(QSL("nav-lock-secure"),      qMakePair(QSL(":/icons/fa/lock.svg"),                 QSL("security-medium")));
    s_actionMap.insert(QSL("nav-lock-insecure"),    qMakePair(QSL(":/icons/fa/lock-open.svg"),            QSL("security-low")));
    s_actionMap.insert(QSL("nav-share"),            qMakePair(QSL(":/icons/fa/arrow-up-from-bracket.svg"), QSL("document-share")));
    s_actionMap.insert(QSL("nav-downloads"),        qMakePair(QSL(":/icons/fa/arrow-down-to-line.svg"),   QSL("emblem-downloads")));
    s_actionMap.insert(QSL("nav-bookmarks"),        qMakePair(QSL(":/icons/fa/star.svg"),                 QSL("bookmark-new")));
    s_actionMap.insert(QSL("nav-bookmark-add"),     qMakePair(QSL(":/icons/fa/star.svg"),                 QSL("bookmark-new")));
    s_actionMap.insert(QSL("nav-bookmark-remove"),  qMakePair(QSL(":/icons/fa/star-half-stroke.svg"),     QSL("edit-delete")));

    // ---- Agent actions ----
    s_actionMap.insert(QSL("agent-fsb"),            qMakePair(QSL(":/icons/fa/bolt.svg"),                 QSL("")));
    s_actionMap.insert(QSL("agent-ready"),          qMakePair(QSL(":/icons/fa/circle-check.svg"),         QSL("")));
    s_actionMap.insert(QSL("agent-working"),        qMakePair(QSL(":/icons/fa/bolt.svg"),                 QSL("")));
    s_actionMap.insert(QSL("agent-mic"),            qMakePair(QSL(":/icons/fa/microphone.svg"),           QSL("audio-input-microphone")));
    s_actionMap.insert(QSL("agent-send"),           qMakePair(QSL(":/icons/fa/arrow-up.svg"),             QSL("")));
    s_actionMap.insert(QSL("agent-stop-task"),      qMakePair(QSL(":/icons/fa/stop.svg"),                 QSL("process-stop")));
    s_actionMap.insert(QSL("agent-summarize"),      qMakePair(QSL(":/icons/fa/wand-magic-sparkles.svg"),  QSL("")));
    s_actionMap.insert(QSL("agent-extract"),        qMakePair(QSL(":/icons/fa/table.svg"),                QSL("")));
    s_actionMap.insert(QSL("agent-translate"),      qMakePair(QSL(":/icons/fa/language.svg"),             QSL("")));
    s_actionMap.insert(QSL("agent-find-prices"),    qMakePair(QSL(":/icons/fa/tag.svg"),                  QSL("")));

    // ---- MCP actions ----
    s_actionMap.insert(QSL("mcp-connected"),        qMakePair(QSL(":/icons/fa/plug.svg"),                 QSL("")));
    s_actionMap.insert(QSL("mcp-disconnected"),     qMakePair(QSL(":/icons/fa/plug-circle-xmark.svg"),    QSL("")));
    s_actionMap.insert(QSL("mcp-tool"),             qMakePair(QSL(":/icons/fa/wrench.svg"),               QSL("")));
    s_actionMap.insert(QSL("mcp-status-ok"),        qMakePair(QSL(":/icons/fa/circle-check.svg"),         QSL("")));
    s_actionMap.insert(QSL("mcp-status-error"),     qMakePair(QSL(":/icons/fa/circle-xmark.svg"),         QSL("")));
    s_actionMap.insert(QSL("mcp-status-warn"),      qMakePair(QSL(":/icons/fa/triangle-exclamation.svg"), QSL("")));

    // ---- Provider actions ----
    s_actionMap.insert(QSL("provider-add"),         qMakePair(QSL(":/icons/fa/circle-plus.svg"),          QSL("list-add")));
    s_actionMap.insert(QSL("provider-remove"),      qMakePair(QSL(":/icons/fa/circle-minus.svg"),         QSL("list-remove")));
    s_actionMap.insert(QSL("provider-model"),       qMakePair(QSL(":/icons/fa/microchip.svg"),            QSL("")));
    s_actionMap.insert(QSL("provider-key"),         qMakePair(QSL(":/icons/fa/key.svg"),                  QSL("")));
    s_actionMap.insert(QSL("provider-endpoint"),    qMakePair(QSL(":/icons/fa/server.svg"),               QSL("")));

    // ---- Vault actions ----
    s_actionMap.insert(QSL("vault-open"),           qMakePair(QSL(":/icons/fa/vault.svg"),                QSL("")));
    s_actionMap.insert(QSL("vault-lock"),           qMakePair(QSL(":/icons/fa/lock.svg"),                 QSL("")));
    s_actionMap.insert(QSL("vault-unlock"),         qMakePair(QSL(":/icons/fa/lock-open.svg"),            QSL("")));
    s_actionMap.insert(QSL("vault-secret-add"),     qMakePair(QSL(":/icons/fa/user-secret.svg"),          QSL("")));
    s_actionMap.insert(QSL("vault-secret-remove"),  qMakePair(QSL(":/icons/fa/circle-minus.svg"),         QSL("list-remove")));

    // ---- Diagnostics / supervision ----
    s_actionMap.insert(QSL("diag-log"),             qMakePair(QSL(":/icons/fa/scroll.svg"),               QSL("")));
    s_actionMap.insert(QSL("diag-health"),          qMakePair(QSL(":/icons/fa/heart-pulse.svg"),          QSL("")));
    s_actionMap.insert(QSL("diag-error"),           qMakePair(QSL(":/icons/fa/circle-xmark.svg"),         QSL("dialog-error")));
    s_actionMap.insert(QSL("diag-warning"),         qMakePair(QSL(":/icons/fa/triangle-exclamation.svg"), QSL("dialog-warning")));
    s_actionMap.insert(QSL("supervision-badge"),    qMakePair(QSL(":/icons/fa/eye.svg"),                  QSL("")));
    s_actionMap.insert(QSL("supervision-pair"),     qMakePair(QSL(":/icons/fa/link.svg"),                 QSL("")));
    s_actionMap.insert(QSL("supervision-unpair"),   qMakePair(QSL(":/icons/fa/link-slash.svg"),           QSL("")));

    // ---- Tab actions ----
    s_actionMap.insert(QSL("tab-all"),              qMakePair(QSL(":/icons/fa/table-cells-large.svg"),    QSL("view-list-icons")));
    s_actionMap.insert(QSL("tab-overview"),         qMakePair(QSL(":/icons/fa/layer-group.svg"),          QSL("view-list-icons")));
    s_actionMap.insert(QSL("tab-closed"),           qMakePair(QSL(":/icons/fa/rotate-left.svg"),          QSL("edit-undo")));
    s_actionMap.insert(QSL("tab-scroll-left"),      qMakePair(QSL(":/icons/fa/arrow-left.svg"),           QSL("go-previous")));
    s_actionMap.insert(QSL("tab-scroll-right"),     qMakePair(QSL(":/icons/fa/arrow-right.svg"),          QSL("go-next")));
    s_actionMap.insert(QSL("tab-pin"),              qMakePair(QSL(":/icons/fa/thumbtack.svg"),            QSL("")));
    s_actionMap.insert(QSL("tab-mute"),             qMakePair(QSL(":/icons/fa/volume-xmark.svg"),         QSL("audio-volume-muted")));
    s_actionMap.insert(QSL("tab-unmute"),           qMakePair(QSL(":/icons/fa/volume-high.svg"),          QSL("audio-volume-high")));
    s_actionMap.insert(QSL("tab-private"),          qMakePair(QSL(":/icons/fa/user-secret.svg"),          QSL("")));
    s_actionMap.insert(QSL("tab-group"),            qMakePair(QSL(":/icons/fa/layer-group.svg"),          QSL("")));

    // ---- Page tool actions (Tools mode) ----
    s_actionMap.insert(QSL("tool-reader"),          qMakePair(QSL(":/icons/fa/book-open.svg"),            QSL("")));
    s_actionMap.insert(QSL("tool-focus"),           qMakePair(QSL(":/icons/fa/highlighter.svg"),          QSL("")));
    s_actionMap.insert(QSL("tool-force-dark"),      qMakePair(QSL(":/icons/fa/moon.svg"),                 QSL("")));
    s_actionMap.insert(QSL("tool-annotate-highlight"), qMakePair(QSL(":/icons/fa/highlighter.svg"),       QSL("")));
    s_actionMap.insert(QSL("tool-annotate-draw"),   qMakePair(QSL(":/icons/fa/pen.svg"),                  QSL("")));
    s_actionMap.insert(QSL("tool-annotate-note"),   qMakePair(QSL(":/icons/fa/note-sticky.svg"),          QSL("")));
    s_actionMap.insert(QSL("tool-annotate-snapshot"), qMakePair(QSL(":/icons/fa/camera.svg"),             QSL("")));
    s_actionMap.insert(QSL("tool-annotate-copy"),   qMakePair(QSL(":/icons/fa/link.svg"),                 QSL("edit-copy")));

    // ---- Settings ----
    s_actionMap.insert(QSL("settings-general"),     qMakePair(QSL(":/icons/fa/sliders.svg"),              QSL("preferences-system")));
    s_actionMap.insert(QSL("settings-appearance"),  qMakePair(QSL(":/icons/fa/palette.svg"),              QSL("preferences-desktop-theme")));
    s_actionMap.insert(QSL("settings-privacy"),     qMakePair(QSL(":/icons/fa/shield.svg"),               QSL("preferences-system-privacy")));
    s_actionMap.insert(QSL("settings-permissions"), qMakePair(QSL(":/icons/fa/circle-nodes.svg"),         QSL("")));
    s_actionMap.insert(QSL("settings-shortcuts"),   qMakePair(QSL(":/icons/fa/keyboard.svg"),             QSL("preferences-desktop-keyboard")));
    s_actionMap.insert(QSL("settings-extensions"),  qMakePair(QSL(":/icons/fa/puzzle-piece.svg"),         QSL("applications-system")));
    s_actionMap.insert(QSL("settings-downloads"),   qMakePair(QSL(":/icons/fa/arrow-down-to-line.svg"),   QSL("folder-downloads")));

    // ---- Utility ----
    s_actionMap.insert(QSL("utility-copy"),         qMakePair(QSL(":/icons/fa/copy.svg"),                 QSL("edit-copy")));
    s_actionMap.insert(QSL("utility-paste"),        qMakePair(QSL(":/icons/fa/paste.svg"),                QSL("edit-paste")));
    s_actionMap.insert(QSL("utility-cut"),          qMakePair(QSL(":/icons/fa/scissors.svg"),             QSL("edit-cut")));
    s_actionMap.insert(QSL("utility-undo"),         qMakePair(QSL(":/icons/fa/rotate-left.svg"),          QSL("edit-undo")));
    s_actionMap.insert(QSL("utility-redo"),         qMakePair(QSL(":/icons/fa/rotate-right.svg"),         QSL("edit-redo")));
    s_actionMap.insert(QSL("utility-delete"),       qMakePair(QSL(":/icons/fa/trash.svg"),                QSL("edit-delete")));
    s_actionMap.insert(QSL("utility-select-all"),   qMakePair(QSL(":/icons/fa/check-double.svg"),         QSL("edit-select-all")));
    s_actionMap.insert(QSL("utility-info"),         qMakePair(QSL(":/icons/fa/circle-info.svg"),          QSL("dialog-information")));
    s_actionMap.insert(QSL("utility-question"),     qMakePair(QSL(":/icons/fa/circle-question.svg"),      QSL("dialog-question")));
    s_actionMap.insert(QSL("utility-close"),        qMakePair(QSL(":/icons/fa/xmark.svg"),                QSL("dialog-close")));
    s_actionMap.insert(QSL("utility-match-case"),   qMakePair(QSL(":/icons/fa/language.svg"),             QSL("format-text-uppercase")));
    s_actionMap.insert(QSL("utility-new-folder"),   qMakePair(QSL(":/icons/fa/folder-plus.svg"),          QSL("folder-new")));
    s_actionMap.insert(QSL("utility-theme-toggle"), qMakePair(QSL(":/icons/fa/circle-half-stroke.svg"),   QSL("")));
    s_actionMap.insert(QSL("utility-menu"),         qMakePair(QSL(":/icons/fa/bars.svg"),                 QSL("")));
    s_actionMap.insert(QSL("utility-sidebar-toggle"), qMakePair(QSL(":/icons/fa/sidebar-flip.svg"),       QSL("")));

    // ---- Side-panel mode-switcher tab icons ----
    s_actionMap.insert(QSL("mode-agent"),           qMakePair(QSL(":/icons/fa/bolt.svg"),                 QSL("")));
    s_actionMap.insert(QSL("mode-explorer"),        qMakePair(QSL(":/icons/fa/compass.svg"),              QSL("")));
    s_actionMap.insert(QSL("mode-tabs"),            qMakePair(QSL(":/icons/fa/layer-group.svg"),          QSL("")));
    s_actionMap.insert(QSL("mode-tools"),           qMakePair(QSL(":/icons/fa/wand-magic-sparkles.svg"),  QSL("")));
}

// --- 3-step fallback chain ---
QIcon PrometheusIconResolver::icon(const QString &actionId)
{
    // Ensure map is ready (instance() initialises in ctor; calling instance() here
    // is safe because Q_GLOBAL_STATIC construction is thread-safe in Qt5/Qt6).
    instance();

    auto it = s_actionMap.constFind(actionId);
    if (it == s_actionMap.constEnd()) {
        qWarning("PrometheusIconResolver: unknown actionId %s", qPrintable(actionId));
        return QIcon();
    }

    // Step 1: bundled SVG resource
    const QIcon bundled(it->first);
    if (!bundled.isNull()) {
        return tintedIcon(bundled);
    }

    // Step 2: QIcon::fromTheme fallback
    if (!it->second.isEmpty()) {
        const QIcon themed = QIcon::fromTheme(it->second, QIcon());
        if (!themed.isNull()) {
            return tintedIcon(themed);
        }
    }

    // Step 3: 1x1 transparent placeholder — release gate will catch this
    qWarning("PrometheusIconResolver: missing icon for action %s \xe2\x80\x94 release gate will fail",
             qPrintable(actionId));
    QPixmap placeholder(1, 1);
    placeholder.fill(Qt::transparent);
    return QIcon(placeholder);
}
