#pragma once

#include <QObject>
#include <QVariantMap>
#include <QFileSystemWatcher>
#include <QProcess>

class ShellCtl : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap userCfg READ userCfg NOTIFY userCfgChanged)
    Q_PROPERTY(QVariantMap eqCfg READ eqCfg NOTIFY eqCfgChanged)
    Q_PROPERTY(QString shellDir READ shellDir CONSTANT)

public:
    explicit ShellCtl(QObject *parent = nullptr);

    QVariantMap userCfg() const { return m_user; }
    QVariantMap eqCfg() const { return m_eq; }
    QString shellDir() const;

    Q_INVOKABLE QVariant uget(const QString &key, const QVariant &def = QVariant()) const;
    Q_INVOKABLE void uset(const QString &key, const QVariant &value);

    Q_INVOKABLE QVariant eget(const QString &dotted, const QVariant &def = QVariant()) const;
    Q_INVOKABLE void eset(const QString &dotted, const QVariant &value);

    Q_INVOKABLE void ipc(const QString &target, const QString &fn, const QStringList &args = QStringList());
    Q_INVOKABLE void run(const QString &cmd);
    Q_INVOKABLE QString execOut(const QString &cmd, int timeoutMs = 3000);
    Q_INVOKABLE QStringList listFiles(const QString &dir, const QString &exts = QString());
    Q_INVOKABLE QStringList listDirs(const QString &dir);
    Q_INVOKABLE QVariantList listImages(const QString &dir);
    Q_INVOKABLE QString readFile(const QString &path) const;
    Q_INVOKABLE bool writeFile(const QString &path, const QString &text);
    Q_INVOKABLE bool copyImage(const QString &src, const QString &dst, int maxEdge = 512);
    Q_INVOKABLE bool saveAvatar(const QString &src, const QString &dst, int size = 512);
    Q_INVOKABLE QVariantList displays() const;
    Q_INVOKABLE bool setMonitorRefresh(double hz);
    Q_INVOKABLE QVariantMap audioState() const;
    Q_INVOKABLE void setDefaultNode(int id);
    Q_INVOKABLE void setSinkVolume(double vol);
    Q_INVOKABLE void setSourceVolume(double vol);
    Q_INVOKABLE QVariantMap displayState() const;
    Q_INVOKABLE void setBrightness(double pct);
    Q_INVOKABLE bool setMonitorScale(double scale);

    static const QString userPath;
    static const QString eqPath;

signals:
    void userCfgChanged();
    void eqCfgChanged();
    void ipcFinished(const QString &output, int code);
    void runFinished(const QString &output, int code);

private:
    void reloadUser();
    void reloadEq();
    static QVariantMap readJson(const QString &path);
    static bool writeJson(const QString &path, const QVariantMap &map, int indent);
    static QVariant mapGet(const QVariantMap &m, const QString &dotted, const QVariant &def);
    static void mapSet(QVariantMap &m, const QString &dotted, const QVariant &v);

    QVariantMap m_user;
    QVariantMap m_eq;
    QFileSystemWatcher m_watcher;
};
