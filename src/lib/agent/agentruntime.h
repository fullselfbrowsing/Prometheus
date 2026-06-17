#ifndef AGENTRUNTIME_H
#define AGENTRUNTIME_H

#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QStringList>

#include "qzcommon.h"

class FALKON_EXPORT AgentRuntime : public QObject
{
    Q_OBJECT

public:
    explicit AgentRuntime(QObject* parent = nullptr);

    QJsonObject submitTask(const QString &prompt, const QJsonObject &context, const QString &source, bool autoRun);
    QJsonObject markTaskRunning(const QString &taskId, const QString &message);
    QJsonObject appendTaskProgress(const QString &taskId, const QString &message, const QJsonObject &details = QJsonObject());
    QJsonObject finishTask(const QString &taskId, const QString &finalResult, const QJsonObject &metrics = QJsonObject());
    QJsonObject failTask(const QString &taskId, const QString &errorCode, const QString &message);
    QJsonObject cancelTask(const QString &taskId, const QString &reason);
    QJsonObject taskStatus(const QString &taskId) const;
    QJsonObject listTasks(int limit = 20) const;

    QJsonObject providerConfig() const;
    QJsonObject saveProviderConfig(const QString &provider, const QJsonObject &config, bool allowSecretPayload);

    QJsonObject listRuntimeLogs(int limit = 50) const;
    QJsonObject diagnostics() const;

    QJsonObject saveMemory(const QString &key, const QString &text, const QString &url);
    QJsonObject listMemory() const;
    QJsonObject saveSiteGuide(const QString &origin, const QString &instructions);
    QJsonObject listSiteGuides() const;

    QJsonObject saveVaultEntryMetadata(const QString &origin, const QString &label, bool autofillAllowed);
    QJsonObject saveVaultSecret(const QString &origin, const QString &label, const QString &secret, bool autofillAllowed);
    QJsonObject listVaultEntries() const;

    QString runtimeDir() const;

Q_SIGNALS:
    void runtimeChanged();

private:
    QJsonObject taskObject(const QString &taskId) const;
    void setTaskObject(const QString &taskId, const QJsonObject &task);
    QJsonObject appendLog(const QString &type, const QString &message, const QJsonObject &details = QJsonObject());
    void loadPersistentData();
    void saveTasks() const;
    QJsonArray readJsonArray(const QString &fileName) const;
    bool writeJsonArray(const QString &fileName, const QJsonArray &array) const;

    QString normalizeProvider(const QString &provider) const;
    QString providerSecretAccount(const QString &provider) const;
    QString vaultSecretAccount(const QString &origin, const QString &label) const;
    bool storeSecret(const QString &account, const QString &secret, QString* errorMessage) const;
    bool hasSecret(const QString &account) const;
    QString secretFallbackPath(const QString &account) const;
    QJsonObject agentPolicyValue(const QString &key, const QVariant &defaultValue) const;

    QJsonArray m_tasks;
    QJsonArray m_logs;
    int m_nextTaskNumber;
};

#endif // AGENTRUNTIME_H
