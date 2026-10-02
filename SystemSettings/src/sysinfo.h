#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>

class SysInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(double totalBytes READ totalBytes NOTIFY storageChanged)
    Q_PROPERTY(double usedBytes READ usedBytes NOTIFY storageChanged)
    Q_PROPERTY(double freeBytes READ freeBytes NOTIFY storageChanged)

public:
    explicit SysInfo(QObject *parent = nullptr);

    bool scanning() const { return m_scanning; }
    double totalBytes() const { return m_total; }
    double usedBytes() const { return m_used; }
    double freeBytes() const { return m_total - m_used; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString fmt(double bytes) const;
    Q_INVOKABLE double category(const QString &key) const;
    Q_INVOKABLE QVariantList details(const QString &key) const;

signals:
    void scanningChanged();
    void storageChanged();

private:
    void runScan();

    bool m_scanning = false;
    double m_total = 0;
    double m_used = 0;
    QVariantMap m_cats;
    QVariantMap m_details;
};
