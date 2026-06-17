#include "agentruntime.h"

#include "datapaths.h"
#include "settings.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QSaveFile>
#include <QUrl>

#if defined(Q_OS_MACOS)
#include <Security/Security.h>
#endif

namespace {

QString nowUtc()
{
    return QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
}

QString providerTitle(const QString &provider)
{
    if (provider == QL1S("hosted")) {
        return QSL("Hosted");
    }
    if (provider == QL1S("routed")) {
        return QSL("Routed");
    }
    if (provider == QL1S("local")) {
        return QSL("Local");
    }
    if (provider == QL1S("custom")) {
        return QSL("Custom");
    }
    if (provider == QL1S("openai")) {
        return QSL("OpenAI");
    }
    if (provider == QL1S("anthropic")) {
        return QSL("Anthropic");
    }
    if (provider == QL1S("gemini")) {
        return QSL("Gemini");
    }
    if (provider == QL1S("xai")) {
        return QSL("xAI");
    }
    if (provider == QL1S("openrouter")) {
        return QSL("OpenRouter");
    }
    if (provider == QL1S("lmstudio")) {
        return QSL("LM Studio");
    }
    return provider;
}

QJsonObject errorObject(const QString &code, const QString &message)
{
    return QJsonObject{{QSL("ok"), false}, {QSL("errorCode"), code}, {QSL("message"), message}};
}

} // namespace

AgentRuntime::AgentRuntime(QObject* parent)
    : QObject(parent)
    , m_nextTaskNumber(1)
{
    loadPersistentData();
}

QJsonObject AgentRuntime::submitTask(const QString &prompt, const QJsonObject &context, const QString &source, bool autoRun)
{
    const QString trimmedPrompt = prompt.trimmed();
    if (trimmedPrompt.isEmpty()) {
        return errorObject(QSL("missing_param"), QSL("Missing task prompt."));
    }

    const QString taskId = QSL("task-%1-%2").arg(QDateTime::currentMSecsSinceEpoch()).arg(m_nextTaskNumber++);
    QJsonObject task{
        {QSL("id"), taskId},
        {QSL("prompt"), trimmedPrompt},
        {QSL("source"), source},
        {QSL("status"), QSL("queued")},
        {QSL("createdAt"), nowUtc()},
        {QSL("updatedAt"), nowUtc()},
        {QSL("context"), context},
        {QSL("progress"), QJsonArray{
             QJsonObject{{QSL("timestamp"), nowUtc()}, {QSL("message"), QSL("Task accepted")}}
         }},
        {QSL("finalResult"), QString()},
        {QSL("metrics"), QJsonObject{{QSL("estimatedCostUsd"), 0.0}, {QSL("modelRequests"), 0}, {QSL("browserActions"), 0}}}
    };

    m_tasks.prepend(task);
    while (m_tasks.size() > 200) {
        m_tasks.removeAt(m_tasks.size() - 1);
    }

    appendLog(QSL("task"), QSL("Task accepted"), QJsonObject{{QSL("taskId"), taskId}, {QSL("source"), source}});
    saveTasks();

    if (autoRun) {
        markTaskRunning(taskId, QSL("Running in local Prometheus runtime"));
        finishTask(taskId, QSL("Task recorded and completed in local browser runtime mode."), QJsonObject{{QSL("estimatedCostUsd"), 0.0}, {QSL("modelRequests"), 0}, {QSL("browserActions"), 0}});
    }

    return QJsonObject{{QSL("ok"), true}, {QSL("task"), taskObject(taskId)}};
}

QJsonObject AgentRuntime::markTaskRunning(const QString &taskId, const QString &message)
{
    QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }

    if (task.value(QSL("status")).toString() == QL1S("cancelled")) {
        return errorObject(QSL("TASK_CANCELLED"), QSL("Task is already cancelled."));
    }

    task.insert(QSL("status"), QSL("running"));
    task.insert(QSL("updatedAt"), nowUtc());
    QJsonArray progress = task.value(QSL("progress")).toArray();
    progress.append(QJsonObject{{QSL("timestamp"), nowUtc()}, {QSL("message"), message}});
    task.insert(QSL("progress"), progress);
    setTaskObject(taskId, task);
    appendLog(QSL("task"), message, QJsonObject{{QSL("taskId"), taskId}});
    saveTasks();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::appendTaskProgress(const QString &taskId, const QString &message, const QJsonObject &details)
{
    QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }

    QJsonArray progress = task.value(QSL("progress")).toArray();
    QJsonObject event{{QSL("timestamp"), nowUtc()}, {QSL("message"), message}};
    if (!details.isEmpty()) {
        event.insert(QSL("details"), details);
    }
    progress.append(event);
    task.insert(QSL("progress"), progress);
    task.insert(QSL("updatedAt"), nowUtc());
    setTaskObject(taskId, task);
    appendLog(QSL("task"), message, QJsonObject{{QSL("taskId"), taskId}, {QSL("details"), details}});
    saveTasks();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::finishTask(const QString &taskId, const QString &finalResult, const QJsonObject &metrics)
{
    QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }

    if (task.value(QSL("status")).toString() == QL1S("cancelled")) {
        return errorObject(QSL("TASK_CANCELLED"), QSL("Task is already cancelled."));
    }

    // Merge execution-mode fields into the stored metrics.
    // If the caller supplied executionMode in metrics, pass through provider/model/providerAvailable/unavailableReason.
    // If not supplied, default to local-fallback mode; unavailableReason maps to the PROVIDER_NOT_CONFIGURED error code.
    QJsonObject storedMetrics = metrics;
    if (!storedMetrics.contains(QSL("executionMode"))) {
        storedMetrics.insert(QSL("executionMode"), QSL("local"));
        storedMetrics.insert(QSL("providerAvailable"), false);
        storedMetrics.insert(QSL("unavailableReason"), QSL("provider_not_configured"));
        if (!storedMetrics.contains(QSL("provider"))) {
            storedMetrics.insert(QSL("provider"), QString());
        }
        if (!storedMetrics.contains(QSL("model"))) {
            storedMetrics.insert(QSL("model"), QString());
        }
    }

    task.insert(QSL("status"), QSL("complete"));
    task.insert(QSL("updatedAt"), nowUtc());
    task.insert(QSL("completedAt"), nowUtc());
    task.insert(QSL("finalResult"), finalResult);
    task.insert(QSL("metrics"), storedMetrics);
    QJsonArray progress = task.value(QSL("progress")).toArray();
    progress.append(QJsonObject{{QSL("timestamp"), nowUtc()}, {QSL("message"), QSL("Task complete")}});
    task.insert(QSL("progress"), progress);
    setTaskObject(taskId, task);
    appendLog(QSL("task"), QSL("Task complete"), QJsonObject{{QSL("taskId"), taskId}, {QSL("finalResult"), finalResult}});
    saveTasks();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::failTask(const QString &taskId, const QString &errorCode, const QString &message)
{
    QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }

    task.insert(QSL("status"), QSL("failed"));
    task.insert(QSL("updatedAt"), nowUtc());
    task.insert(QSL("error"), QJsonObject{{QSL("code"), errorCode}, {QSL("message"), message}});
    setTaskObject(taskId, task);
    appendLog(QSL("task_error"), message, QJsonObject{{QSL("taskId"), taskId}, {QSL("errorCode"), errorCode}});
    saveTasks();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::cancelTask(const QString &taskId, const QString &reason)
{
    QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }

    const QString status = task.value(QSL("status")).toString();
    if (status == QL1S("complete") || status == QL1S("failed")) {
        return errorObject(QSL("TASK_ALREADY_FINISHED"), QSL("Task has already finished."));
    }

    task.insert(QSL("status"), QSL("cancelled"));
    task.insert(QSL("updatedAt"), nowUtc());
    task.insert(QSL("cancelledAt"), nowUtc());
    task.insert(QSL("cancelReason"), reason);
    QJsonArray progress = task.value(QSL("progress")).toArray();
    progress.append(QJsonObject{{QSL("timestamp"), nowUtc()}, {QSL("message"), QSL("Task cancelled")}, {QSL("reason"), reason}});
    task.insert(QSL("progress"), progress);
    setTaskObject(taskId, task);
    appendLog(QSL("task"), QSL("Task cancelled"), QJsonObject{{QSL("taskId"), taskId}, {QSL("reason"), reason}});
    saveTasks();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::taskStatus(const QString &taskId) const
{
    const QJsonObject task = taskObject(taskId);
    if (task.isEmpty()) {
        return errorObject(QSL("TASK_NOT_FOUND"), QSL("Task was not found."));
    }
    return QJsonObject{{QSL("ok"), true}, {QSL("task"), task}};
}

QJsonObject AgentRuntime::listTasks(int limit) const
{
    QJsonArray tasks;
    const int boundedLimit = qBound(1, limit, 200);
    for (int i = 0; i < m_tasks.size() && i < boundedLimit; ++i) {
        tasks.append(m_tasks.at(i));
    }
    return QJsonObject{{QSL("ok"), true}, {QSL("tasks"), tasks}};
}

QJsonObject AgentRuntime::providerConfig() const
{
    const QStringList providers{
        QSL("hosted"),
        QSL("routed"),
        QSL("local"),
        QSL("openai"),
        QSL("anthropic"),
        QSL("gemini"),
        QSL("xai"),
        QSL("openrouter"),
        QSL("lmstudio"),
        QSL("custom")
    };
    QJsonArray providerArray;
    Settings settings;
    for (const QString &provider : providers) {
        const QString prefix = QSL("PrometheusRuntime/Providers/%1/").arg(provider);
        const QString model = settings.value(prefix + QSL("model")).toString();
        QStringList configuredModels = settings.value(prefix + QSL("models")).toStringList();
        if (!model.isEmpty() && !configuredModels.contains(model)) {
            configuredModels.prepend(model);
        }

        QJsonArray models;
        for (const QString &configuredModel : configuredModels) {
            models.append(configuredModel);
        }

        const QString endpoint = settings.value(prefix + QSL("endpoint")).toString();
        const bool secretConfigured = hasSecret(providerSecretAccount(provider));
        providerArray.append(QJsonObject{
            {QSL("id"), provider},
            {QSL("name"), settings.value(prefix + QSL("displayName"), providerTitle(provider)).toString()},
            {QSL("enabled"), settings.value(prefix + QSL("enabled"), provider == QL1S("local")).toBool()},
            {QSL("model"), model},
            {QSL("endpoint"), endpoint},
            {QSL("secretConfigured"), secretConfigured},
            {QSL("models"), models},
            {QSL("discoveryStatus"), model.isEmpty() && endpoint.isEmpty() && !secretConfigured ? QSL("not_configured") : QSL("configured")}
        });
    }

    return QJsonObject{
        {QSL("ok"), true},
        {QSL("providers"), providerArray},
        {QSL("secretTransport"), QSL("native_ui_only")}
    };
}

QJsonObject AgentRuntime::saveProviderConfig(const QString &provider, const QJsonObject &config, bool allowSecretPayload)
{
    const QString normalizedProvider = normalizeProvider(provider);
    if (normalizedProvider.isEmpty()) {
        return errorObject(QSL("UNSUPPORTED_PROVIDER"), QSL("Provider must be hosted, routed, local, OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, or custom."));
    }

    if (!allowSecretPayload && config.contains(QSL("secret"))) {
        return errorObject(QSL("SECRET_TRANSPORT_BLOCKED"), QSL("Provider secrets can only be stored from the native Prometheus UI."));
    }

    Settings settings;
    const QString prefix = QSL("PrometheusRuntime/Providers/%1/").arg(normalizedProvider);
    settings.setValue(prefix + QSL("enabled"), config.value(QSL("enabled")).toBool(true));
    settings.setValue(prefix + QSL("displayName"), config.value(QSL("displayName")).toString(providerTitle(normalizedProvider)));
    settings.setValue(prefix + QSL("model"), config.value(QSL("model")).toString());
    settings.setValue(prefix + QSL("endpoint"), config.value(QSL("endpoint")).toString());
    if (config.value(QSL("models")).isArray()) {
        QStringList models;
        const QJsonArray modelArray = config.value(QSL("models")).toArray();
        for (const QJsonValue &value : modelArray) {
            if (!value.toString().isEmpty()) {
                models.append(value.toString());
            }
        }
        settings.setValue(prefix + QSL("models"), models);
    }

    const QString secret = config.value(QSL("secret")).toString();
    if (allowSecretPayload && !secret.isEmpty()) {
        QString secretError;
        if (!storeSecret(providerSecretAccount(normalizedProvider), secret, &secretError)) {
            return errorObject(QSL("SECRET_STORE_FAILED"), secretError);
        }
    }

    appendLog(QSL("provider"), QSL("Provider configuration updated"), QJsonObject{{QSL("provider"), normalizedProvider}, {QSL("secretConfigured"), hasSecret(providerSecretAccount(normalizedProvider))}});
    settings.sync();
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("provider"), normalizedProvider}, {QSL("config"), providerConfig()}};
}

QJsonObject AgentRuntime::listRuntimeLogs(int limit) const
{
    QJsonArray logs;
    const int boundedLimit = qBound(1, limit, 500);
    for (int i = 0; i < m_logs.size() && i < boundedLimit; ++i) {
        logs.append(m_logs.at(i));
    }
    return QJsonObject{{QSL("ok"), true}, {QSL("logs"), logs}};
}

QJsonObject AgentRuntime::diagnostics() const
{
    int complete = 0;
    int running = 0;
    int cancelled = 0;
    for (const QJsonValue &value : m_tasks) {
        const QString status = value.toObject().value(QSL("status")).toString();
        if (status == QL1S("complete")) {
            ++complete;
        } else if (status == QL1S("running") || status == QL1S("queued")) {
            ++running;
        } else if (status == QL1S("cancelled")) {
            ++cancelled;
        }
    }

    return QJsonObject{
        {QSL("ok"), true},
        {QSL("runtimeDir"), runtimeDir()},
        {QSL("taskCount"), m_tasks.size()},
        {QSL("completeTaskCount"), complete},
        {QSL("activeTaskCount"), running},
        {QSL("cancelledTaskCount"), cancelled},
        {QSL("logCount"), m_logs.size()},
        {QSL("providers"), providerConfig().value(QSL("providers")).toArray()},
        {QSL("vaultSecretTransport"), QSL("native_ui_only")}
    };
}

QJsonObject AgentRuntime::saveMemory(const QString &key, const QString &text, const QString &url)
{
    const QString trimmedKey = key.trimmed();
    if (trimmedKey.isEmpty()) {
        return errorObject(QSL("missing_param"), QSL("Missing memory key."));
    }

    QJsonArray items = readJsonArray(QSL("memory.json"));
    QJsonObject entry{
        {QSL("key"), trimmedKey},
        {QSL("text"), text},
        {QSL("url"), url},
        {QSL("updatedAt"), nowUtc()}
    };

    bool replaced = false;
    for (int i = 0; i < items.size(); ++i) {
        if (items.at(i).toObject().value(QSL("key")).toString() == trimmedKey) {
            items.replace(i, entry);
            replaced = true;
            break;
        }
    }
    if (!replaced) {
        items.prepend(entry);
    }

    writeJsonArray(QSL("memory.json"), items);
    appendLog(QSL("memory"), QSL("Memory updated"), QJsonObject{{QSL("key"), trimmedKey}, {QSL("url"), url}});
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("memory"), entry}};
}

QJsonObject AgentRuntime::listMemory() const
{
    return QJsonObject{{QSL("ok"), true}, {QSL("memory"), readJsonArray(QSL("memory.json"))}};
}

QJsonObject AgentRuntime::saveSiteGuide(const QString &origin, const QString &instructions)
{
    const QString trimmedOrigin = origin.trimmed();
    if (trimmedOrigin.isEmpty()) {
        return errorObject(QSL("missing_param"), QSL("Missing site guide origin."));
    }

    QJsonArray items = readJsonArray(QSL("site-guides.json"));
    QJsonObject entry{
        {QSL("origin"), trimmedOrigin},
        {QSL("instructions"), instructions},
        {QSL("updatedAt"), nowUtc()}
    };

    bool replaced = false;
    for (int i = 0; i < items.size(); ++i) {
        if (items.at(i).toObject().value(QSL("origin")).toString() == trimmedOrigin) {
            items.replace(i, entry);
            replaced = true;
            break;
        }
    }
    if (!replaced) {
        items.prepend(entry);
    }

    writeJsonArray(QSL("site-guides.json"), items);
    appendLog(QSL("site_guide"), QSL("Site guide updated"), QJsonObject{{QSL("origin"), trimmedOrigin}});
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("siteGuide"), entry}};
}

QJsonObject AgentRuntime::listSiteGuides() const
{
    return QJsonObject{{QSL("ok"), true}, {QSL("siteGuides"), readJsonArray(QSL("site-guides.json"))}};
}

QJsonObject AgentRuntime::saveVaultEntryMetadata(const QString &origin, const QString &label, bool autofillAllowed)
{
    const QString trimmedOrigin = origin.trimmed();
    const QString trimmedLabel = label.trimmed();
    if (trimmedOrigin.isEmpty() || trimmedLabel.isEmpty()) {
        return errorObject(QSL("missing_param"), QSL("Missing vault origin or label."));
    }

    QJsonArray items = readJsonArray(QSL("vault-index.json"));
    const QString account = vaultSecretAccount(trimmedOrigin, trimmedLabel);
    QJsonObject entry{
        {QSL("origin"), trimmedOrigin},
        {QSL("label"), trimmedLabel},
        {QSL("autofillAllowed"), autofillAllowed},
        {QSL("secretConfigured"), hasSecret(account)},
        {QSL("updatedAt"), nowUtc()}
    };

    bool replaced = false;
    for (int i = 0; i < items.size(); ++i) {
        const QJsonObject existing = items.at(i).toObject();
        if (existing.value(QSL("origin")).toString() == trimmedOrigin && existing.value(QSL("label")).toString() == trimmedLabel) {
            items.replace(i, entry);
            replaced = true;
            break;
        }
    }
    if (!replaced) {
        items.prepend(entry);
    }

    writeJsonArray(QSL("vault-index.json"), items);
    appendLog(QSL("vault"), QSL("Vault metadata updated"), QJsonObject{{QSL("origin"), trimmedOrigin}, {QSL("label"), trimmedLabel}, {QSL("secretConfigured"), entry.value(QSL("secretConfigured")).toBool()}});
    Q_EMIT runtimeChanged();
    return QJsonObject{{QSL("ok"), true}, {QSL("vaultEntry"), entry}};
}

QJsonObject AgentRuntime::saveVaultSecret(const QString &origin, const QString &label, const QString &secret, bool autofillAllowed)
{
    if (secret.isEmpty()) {
        return errorObject(QSL("missing_param"), QSL("Missing vault secret."));
    }

    QString secretError;
    if (!storeSecret(vaultSecretAccount(origin.trimmed(), label.trimmed()), secret, &secretError)) {
        return errorObject(QSL("SECRET_STORE_FAILED"), secretError);
    }

    return saveVaultEntryMetadata(origin, label, autofillAllowed);
}

QJsonObject AgentRuntime::listVaultEntries() const
{
    QJsonArray items = readJsonArray(QSL("vault-index.json"));
    for (int i = 0; i < items.size(); ++i) {
        QJsonObject entry = items.at(i).toObject();
        entry.insert(QSL("secretConfigured"), hasSecret(vaultSecretAccount(entry.value(QSL("origin")).toString(), entry.value(QSL("label")).toString())));
        items.replace(i, entry);
    }
    return QJsonObject{{QSL("ok"), true}, {QSL("vaultEntries"), items}, {QSL("secretTransport"), QSL("native_ui_only")}};
}

QString AgentRuntime::runtimeDir() const
{
    return DataPaths::currentProfilePath() + QLatin1String("/prometheus-runtime");
}

QJsonObject AgentRuntime::taskObject(const QString &taskId) const
{
    for (const QJsonValue &value : m_tasks) {
        const QJsonObject task = value.toObject();
        if (task.value(QSL("id")).toString() == taskId) {
            return task;
        }
    }
    return QJsonObject();
}

void AgentRuntime::setTaskObject(const QString &taskId, const QJsonObject &task)
{
    for (int i = 0; i < m_tasks.size(); ++i) {
        if (m_tasks.at(i).toObject().value(QSL("id")).toString() == taskId) {
            m_tasks.replace(i, task);
            return;
        }
    }
}

QJsonObject AgentRuntime::appendLog(const QString &type, const QString &message, const QJsonObject &details)
{
    QJsonObject entry{
        {QSL("timestamp"), nowUtc()},
        {QSL("type"), type},
        {QSL("message"), message}
    };
    if (!details.isEmpty()) {
        entry.insert(QSL("details"), details);
    }

    m_logs.prepend(entry);
    while (m_logs.size() > 500) {
        m_logs.removeAt(m_logs.size() - 1);
    }
    writeJsonArray(QSL("runtime-log.json"), m_logs);
    return entry;
}

void AgentRuntime::loadPersistentData()
{
    m_tasks = readJsonArray(QSL("tasks.json"));
    m_logs = readJsonArray(QSL("runtime-log.json"));
    m_nextTaskNumber = m_tasks.size() + 1;
}

void AgentRuntime::saveTasks() const
{
    writeJsonArray(QSL("tasks.json"), m_tasks);
}

QJsonArray AgentRuntime::readJsonArray(const QString &fileName) const
{
    QFile file(runtimeDir() + QLatin1Char('/') + fileName);
    if (!file.open(QIODevice::ReadOnly)) {
        return QJsonArray();
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    return document.isArray() ? document.array() : QJsonArray();
}

bool AgentRuntime::writeJsonArray(const QString &fileName, const QJsonArray &array) const
{
    QDir().mkpath(runtimeDir());
    QSaveFile file(runtimeDir() + QLatin1Char('/') + fileName);
    if (!file.open(QIODevice::WriteOnly)) {
        return false;
    }

    file.write(QJsonDocument(array).toJson(QJsonDocument::Indented));
    return file.commit();
}

QString AgentRuntime::normalizeProvider(const QString &provider) const
{
    const QString normalized = provider.trimmed().toLower();
    const QStringList providers{
        QSL("hosted"),
        QSL("routed"),
        QSL("local"),
        QSL("openai"),
        QSL("anthropic"),
        QSL("gemini"),
        QSL("xai"),
        QSL("openrouter"),
        QSL("lmstudio"),
        QSL("custom")
    };
    if (providers.contains(normalized)) {
        return normalized;
    }
    return QString();
}

QString AgentRuntime::providerSecretAccount(const QString &provider) const
{
    return QSL("provider:%1").arg(provider);
}

QString AgentRuntime::vaultSecretAccount(const QString &origin, const QString &label) const
{
    return QSL("vault:%1:%2").arg(origin, label);
}

bool AgentRuntime::storeSecret(const QString &account, const QString &secret, QString* errorMessage) const
{
#if defined(Q_OS_MACOS)
    static const QByteArray service = QByteArrayLiteral("Prometheus FSB Runtime");
    const QByteArray accountBytes = account.toUtf8();
    const QByteArray secretBytes = secret.toUtf8();

    UInt32 existingLength = 0;
    void* existingData = nullptr;
    SecKeychainItemRef item = nullptr;
    OSStatus status = SecKeychainFindGenericPassword(nullptr,
                                                     static_cast<UInt32>(service.size()),
                                                     service.constData(),
                                                     static_cast<UInt32>(accountBytes.size()),
                                                     accountBytes.constData(),
                                                     &existingLength,
                                                     &existingData,
                                                     &item);
    if (status == errSecSuccess) {
        status = SecKeychainItemModifyAttributesAndData(item, nullptr, static_cast<UInt32>(secretBytes.size()), secretBytes.constData());
        if (existingData) {
            SecKeychainItemFreeContent(nullptr, existingData);
        }
        if (item) {
            CFRelease(item);
        }
    } else if (status == errSecItemNotFound) {
        status = SecKeychainAddGenericPassword(nullptr,
                                               static_cast<UInt32>(service.size()),
                                               service.constData(),
                                               static_cast<UInt32>(accountBytes.size()),
                                               accountBytes.constData(),
                                               static_cast<UInt32>(secretBytes.size()),
                                               secretBytes.constData(),
                                               nullptr);
    }

    if (status != errSecSuccess) {
        if (errorMessage) {
            *errorMessage = QSL("Keychain returned status %1.").arg(static_cast<int>(status));
        }
        return false;
    }
    return true;
#else
    QDir().mkpath(runtimeDir() + QLatin1String("/secrets"));
    QSaveFile file(secretFallbackPath(account));
    if (!file.open(QIODevice::WriteOnly)) {
        if (errorMessage) {
            *errorMessage = QSL("Could not open owner-only fallback secret file.");
        }
        return false;
    }
    file.write(secret.toUtf8());
    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = QSL("Could not write owner-only fallback secret file.");
        }
        return false;
    }
    QFile::setPermissions(secretFallbackPath(account), QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    return true;
#endif
}

bool AgentRuntime::hasSecret(const QString &account) const
{
#if defined(Q_OS_MACOS)
    static const QByteArray service = QByteArrayLiteral("Prometheus FSB Runtime");
    const QByteArray accountBytes = account.toUtf8();
    UInt32 passwordLength = 0;
    void* passwordData = nullptr;
    SecKeychainItemRef item = nullptr;
    const OSStatus status = SecKeychainFindGenericPassword(nullptr,
                                                           static_cast<UInt32>(service.size()),
                                                           service.constData(),
                                                           static_cast<UInt32>(accountBytes.size()),
                                                           accountBytes.constData(),
                                                           &passwordLength,
                                                           &passwordData,
                                                           &item);
    if (status == errSecSuccess) {
        if (passwordData) {
            SecKeychainItemFreeContent(nullptr, passwordData);
        }
        if (item) {
            CFRelease(item);
        }
        return true;
    }
    return false;
#else
    return QFile::exists(secretFallbackPath(account));
#endif
}

QString AgentRuntime::secretFallbackPath(const QString &account) const
{
    return runtimeDir() + QLatin1String("/secrets/") + QString::fromLatin1(QUrl::toPercentEncoding(account)) + QLatin1String(".secret");
}

QJsonObject AgentRuntime::agentPolicyValue(const QString &key, const QVariant &defaultValue) const
{
    Settings settings;
    settings.beginGroup(QSL("PrometheusRuntime/Policy"));
    const QVariant v = settings.value(key, defaultValue);
    settings.endGroup();
    return QJsonObject{{QSL("key"), key}, {QSL("value"), QJsonValue::fromVariant(v)}};
}
