#include "sysinfo.h"

#include <sys/statvfs.h>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QMetaObject>
#include <thread>

namespace {

bool g_scanning = false;

quint64 dirSize(const QString &path)
{
    quint64 total = 0;
    QDirIterator it(path, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        const QFileInfo fi = it.fileInfo();
        if (fi.isDir())
            continue;
        total += static_cast<quint64>(fi.size());
    }
    return total;
}

struct CatResult {
    QString key;
    double bytes = 0;
    QVariantList details;
};

QVariantList detailSizes(const QList<QPair<QString, QString>> &entries)
{
    QVariantList out;
    for (const auto &e : entries) {
        const double b = static_cast<double>(dirSize(e.second));
        out.append(QVariantMap{{"t", e.first}, {"v", b}});
    }
    return out;
}

} // namespace

SysInfo::SysInfo(QObject *parent) : QObject(parent) {}

void SysInfo::refresh()
{
    if (g_scanning)
        return;
    g_scanning = true;
    m_scanning = true;
    emit scanningChanged();

    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);

    std::thread([this, home]() {
        struct statvfs st {};
        double total = 0, used = 0;
        if (statvfs("/", &st) == 0) {
            total = double(st.f_blocks) * double(st.f_frsize);
            used = double(st.f_blocks - st.f_bfree) * double(st.f_frsize);
        }

        QList<CatResult> results;

        {
            CatResult r;
            r.key = "applications";
            QStringList appDirs{"/opt", "/var/lib/flatpak", "/var/lib/snapd/snaps",
                                home + "/.local/share/Flatpak"};
            double sum = 0;
            QVariantList det;
            for (const QString &d : appDirs) {
                if (!QDir(d).exists())
                    continue;
                const double b = double(dirSize(d));
                sum += b;
                det.append(QVariantMap{{"t", QFileInfo(d).fileName()}, {"v", b}});
            }
            r.bytes = sum;
            r.details = det;
            results.append(r);
        }

        {
            CatResult r;
            r.key = "documents";
            QStringList docDirs{"Documents", "Downloads", "Desktop", "Music", "Pictures",
                                "Videos", "Templates"};
            double sum = 0;
            QVariantList det;
            for (const QString &d : docDirs) {
                const QString p = home + "/" + d;
                if (!QDir(p).exists())
                    continue;
                const double b = double(dirSize(p));
                sum += b;
                det.append(QVariantMap{{"t", d}, {"v", b}});
            }
            r.bytes = sum;
            r.details = det;
            results.append(r);
        }

        {
            CatResult r;
            r.key = "macos";
            QStringList sysDirs{"/usr", "/boot", "/etc", "/bin", "/sbin", "/lib", "/lib64"};
            double sum = 0;
            QVariantList det;
            for (const QString &d : sysDirs) {
                if (!QDir(d).exists())
                    continue;
                const double b = double(dirSize(d));
                sum += b;
                det.append(QVariantMap{{"t", QFileInfo(d).fileName()}, {"v", b}});
            }
            r.bytes = sum;
            r.details = det;
            results.append(r);
        }

        {
            CatResult r;
            r.key = "systemData";
            QStringList sdDirs{"/var", "/tmp"};
            QStringList sdHome{"/.cache", "/.local/share", "/.config", "/.npm", "/.cargo"};
            double sum = 0;
            QVariantList det;
            for (const QString &d : sdDirs) {
                if (!QDir(d).exists())
                    continue;
                const double b = double(dirSize(d));
                sum += b;
                det.append(QVariantMap{{"t", QFileInfo(d).fileName()}, {"v", b}});
            }
            for (const QString &d : sdHome) {
                const QString p = home + d;
                if (!QDir(p).exists())
                    continue;
                const double b = double(dirSize(p));
                sum += b;
                det.append(QVariantMap{{"t", d.mid(1)}, {"v", b}});
            }
            r.bytes = sum;
            r.details = det;
            results.append(r);
        }

        {
            CatResult r;
            r.key = "bins";
            const QString p = home + "/.local/share/Trash";
            r.bytes = QDir(p).exists() ? double(dirSize(p)) : 0.0;
            r.details = QVariantList{};
            results.append(r);
        }

        QVariantMap cats;
        QVariantMap details;
        for (const CatResult &r : results) {
            cats.insert(r.key, r.bytes);
            details.insert(r.key, r.details);
        }

        QMetaObject::invokeMethod(this, [this, cats, details, total, used]() {
            m_cats = cats;
            m_details = details;
            m_total = total;
            m_used = used;
            m_scanning = false;
            g_scanning = false;
            emit storageChanged();
            emit scanningChanged();
        }, Qt::QueuedConnection);
    }).detach();
}

QString SysInfo::fmt(double bytes) const
{
    const double tb = bytes / (1024.0 * 1024.0 * 1024.0 * 1024.0);
    if (tb >= 1.0)
        return QString::number(tb, 'f', tb >= 10.0 ? 1 : 2) + " TB";
    const double gb = bytes / (1024.0 * 1024.0 * 1024.0);
    if (gb >= 1.0)
        return QString::number(gb, 'f', gb >= 100.0 ? 0 : 1) + " GB";
    const double mb = bytes / (1024.0 * 1024.0);
    return QString::number(mb, 'f', mb >= 10.0 ? 0 : 1) + " MB";
}

double SysInfo::category(const QString &key) const
{
    return m_cats.value(key).toDouble();
}

QVariantList SysInfo::details(const QString &key) const
{
    return m_details.value(key).toList();
}
