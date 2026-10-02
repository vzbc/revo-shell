#include "shellctl.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QProcess>
#include <QImageReader>
#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QSet>
#include <QDateTime>

const QString ShellCtl::userPath = QStringLiteral("/home/revo/.config/quickshell/macos/userconfig.json");
const QString ShellCtl::eqPath = QStringLiteral("/home/revo/.config/aureli/config.json");

QString ShellCtl::shellDir() const
{
    return QStringLiteral("/home/revo/.config/quickshell/macos");
}

ShellCtl::ShellCtl(QObject *parent)
    : QObject(parent)
{
    reloadUser();
    reloadEq();
    m_watcher.addPath(userPath);
    m_watcher.addPath(eqPath);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &p) {
        if (p == userPath) reloadUser();
        else if (p == eqPath) reloadEq();
        if (!m_watcher.files().contains(p))
            m_watcher.addPath(p);
    });
}

QVariantMap ShellCtl::readJson(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    if (!doc.isObject())
        return {};
    return doc.object().toVariantMap();
}

bool ShellCtl::writeJson(const QString &path, const QVariantMap &map, int indent)
{
    const QJsonDocument doc(QJsonObject::fromVariantMap(map));
    const QByteArray bytes = doc.toJson(indent > 0 ? QJsonDocument::Indented : QJsonDocument::Compact);
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    f.write(bytes);
    f.close();
    return true;
}

void ShellCtl::reloadUser()
{
    m_user = readJson(userPath);
    emit userCfgChanged();
}

void ShellCtl::reloadEq()
{
    m_eq = readJson(eqPath);
    emit eqCfgChanged();
}

QVariant ShellCtl::mapGet(const QVariantMap &m, const QString &dotted, const QVariant &def)
{
    const QStringList parts = dotted.split(QLatin1Char('.'));
    QVariantMap tmp = m;
    for (int i = 0; i < parts.size(); ++i) {
        if (!tmp.contains(parts[i]))
            return def;
        const QVariant &v = tmp.value(parts[i]);
        if (i == parts.size() - 1)
            return v;
        if (!v.canConvert<QVariantMap>())
            return def;
        tmp = v.toMap();
    }
    return def;
}

void ShellCtl::mapSet(QVariantMap &m, const QString &dotted, const QVariant &v)
{
    const QStringList parts = dotted.split(QLatin1Char('.'));
    auto set = [](auto &&self, QVariantMap &map, const QStringList &ps, int idx, const QVariant &val) -> void {
        if (idx == ps.size() - 1) {
            map[ps[idx]] = val;
            return;
        }
        QVariant &c = map[ps[idx]];
        QVariantMap sub = c.toMap();
        self(self, sub, ps, idx + 1, val);
        c = sub;
    };
    set(set, m, parts, 0, v);
}

QVariant ShellCtl::uget(const QString &key, const QVariant &def) const
{
    return mapGet(m_user, key, def);
}

void ShellCtl::uset(const QString &key, const QVariant &value)
{
    // read-modify-write against the file on disk so a concurrent writer
    // (the shell, a second instance) never drops keys we have not seen yet.
    QVariantMap m = readJson(userPath);
    if (m.isEmpty())
        m = m_user;
    mapSet(m, key, value);
    writeJson(userPath, m, 2);
    m_user = m;
    emit userCfgChanged();
}

QVariant ShellCtl::eget(const QString &dotted, const QVariant &def) const
{
    return mapGet(m_eq, dotted, def);
}

void ShellCtl::eset(const QString &dotted, const QVariant &value)
{
    QVariantMap m = readJson(eqPath);
    if (m.isEmpty())
        m = m_eq;
    mapSet(m, dotted, value);
    writeJson(eqPath, m, 4);
    m_eq = m;
    emit eqCfgChanged();
}

void ShellCtl::ipc(const QString &target, const QString &fn, const QStringList &args)
{
    auto *p = new QProcess(this);
    QStringList a{QStringLiteral("--path"), QStringLiteral("/home/revo/.config/quickshell/macos"),
                  QStringLiteral("ipc"), QStringLiteral("call"), target, fn};
    a << args;
    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, p](int code, QProcess::ExitStatus) {
                emit ipcFinished(QString::fromUtf8(p->readAllStandardOutput()), code);
                p->deleteLater();
            });
    p->start(QStringLiteral("qs"), a);
}

void ShellCtl::run(const QString &cmd)
{
    auto *p = new QProcess(this);
    p->setProgram(QStringLiteral("/bin/sh"));
    p->setArguments({QStringLiteral("-c"), cmd});
    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, p](int code, QProcess::ExitStatus) {
                emit runFinished(QString::fromUtf8(p->readAllStandardOutput()), code);
                p->deleteLater();
            });
    p->start();
}

QString ShellCtl::execOut(const QString &cmd, int timeoutMs)
{
    QProcess p;
    p.start(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
    if (!p.waitForFinished(timeoutMs))
        return {};
    return QString::fromUtf8(p.readAllStandardOutput()).trimmed();
}

QStringList ShellCtl::listFiles(const QString &dir, const QString &exts)
{
    QDir d(dir);
    if (!d.exists())
        return {};
    QStringList filters;
    const QStringList want = exts.isEmpty()
        ? QStringList{QStringLiteral("*.png"), QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"),
                     QStringLiteral("*.webp"), QStringLiteral("*.gif"), QStringLiteral("*.bmp"),
                     QStringLiteral("*.mp4"), QStringLiteral("*.webm"), QStringLiteral("*.mkv"),
                     QStringLiteral("*.mov")}
        : exts.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    for (const QString &w : want)
        filters << (w.contains(QLatin1Char('*')) ? w : (QStringLiteral("*.") + w));

    const QFileInfoList list = d.entryInfoList(filters, QDir::Files | QDir::Readable, QDir::Name);
    QStringList out;
    out.reserve(list.size());
    for (const QFileInfo &fi : list)
        out << fi.absoluteFilePath();
    return out;
}

QVariantList ShellCtl::listImages(const QString &dir)
{
    static const QSet<QString> movie = {QStringLiteral("mp4"), QStringLiteral("webm"),
                                        QStringLiteral("mkv"), QStringLiteral("mov"),
                                        QStringLiteral("avi"), QStringLiteral("m4v")};
    QVariantList out;
    const QStringList files = listFiles(dir);
    out.reserve(files.size());
    for (const QString &f : files) {
        const QFileInfo fi(f);
        const QString suf = fi.suffix().toLower();
        QImageReader r(f);
        r.setAutoTransform(true);
        const QSize sz = r.size();
        QVariantMap m;
        m.insert(QStringLiteral("path"), f);
        m.insert(QStringLiteral("name"), fi.completeBaseName());
        m.insert(QStringLiteral("ext"), suf);
        m.insert(QStringLiteral("w"), sz.isValid() ? sz.width() : 0);
        m.insert(QStringLiteral("h"), sz.isValid() ? sz.height() : 0);
        m.insert(QStringLiteral("animated"),
                 movie.contains(suf) || r.supportsAnimation());
        m.insert(QStringLiteral("mtime"), fi.lastModified().toSecsSinceEpoch());
        out.append(m);
    }
    return out;
}

QStringList ShellCtl::listDirs(const QString &dir)
{
    QDir d(dir);
    if (!d.exists())
        return {};
    const QStringList names = d.entryList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Readable, QDir::Name);
    QStringList out;
    for (const QString &n : names)
        out << d.absoluteFilePath(n);
    return out;
}

static QString shOut(const QString &cmd, int ms = 2500)
{
    QProcess p;
    p.start(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
    if (!p.waitForFinished(ms))
        return {};
    return QString::fromUtf8(p.readAllStandardOutput());
}

QVariantMap ShellCtl::audioState() const
{
    QVariantMap out;

    const QString vol = shOut(QStringLiteral("wpctl get-volume @DEFAULT_AUDIO_SINK@"));
    QRegularExpression volRe(QStringLiteral("Volume:\\s*([0-9.]+)"));
    auto vm = volRe.match(vol);
    double sinkVol = vm.hasMatch() ? vm.captured(1).toDouble() : -1.0;
    out.insert(QStringLiteral("volume"), sinkVol);
    out.insert(QStringLiteral("muted"), vol.contains(QStringLiteral("MUTED")));

    const QString svol = shOut(QStringLiteral("wpctl get-volume @DEFAULT_AUDIO_SOURCE@"));
    auto sm = volRe.match(svol);
    out.insert(QStringLiteral("inputVolume"), sm.hasMatch() ? sm.captured(1).toDouble() : -1.0);
    out.insert(QStringLiteral("inputMuted"), svol.contains(QStringLiteral("MUTED")));

    const QString status = shOut(QStringLiteral("wpctl status"));
    auto section = [&status](const QString &name) -> QStringList {
        QStringList rows;
        bool in = false;
        const QChar branch1(0x251C); // ├
        const QChar branch2(0x2514); // └
        const QStringList lines = status.split(QLatin1Char('\n'));
        for (const QString &raw : lines) {
            if (raw.contains(name + QLatin1Char(':'))) {
                in = true;
                continue;
            }
            if (!in)
                continue;
            if (raw.contains(branch1) || raw.contains(branch2))
                break;
            rows << raw;
        }
        return rows;
    };

    auto parseNodes = [&section](const QString &key) {
        QVariantList list;
        const QString re = QStringLiteral(
            "([*]?)\\s*(\\d+)\\.\\s+(.+?)(?:\\s*\\[vol:.*)?$");
        QRegularExpression rx(re);
        for (const QString &line : section(key)) {
            if (!line.contains(QLatin1Char('.')))
                continue;
            auto m = rx.match(line.trimmed());
            if (!m.hasMatch())
                continue;
            QVariantMap n;
            n.insert(QStringLiteral("id"), m.captured(2).toInt());
            n.insert(QStringLiteral("name"), m.captured(3).trimmed());
            n.insert(QStringLiteral("default"), m.captured(1).trimmed() == QLatin1String("*"));
            list.append(n);
        }
        return list;
    };

    out.insert(QStringLiteral("sinks"), parseNodes(QStringLiteral("Sinks")));
    out.insert(QStringLiteral("sources"), parseNodes(QStringLiteral("Sources")));
    return out;
}

void ShellCtl::setDefaultNode(int id)
{
    shOut(QStringLiteral("wpctl set-default %1").arg(id));
}

void ShellCtl::setSinkVolume(double vol)
{
    shOut(QStringLiteral("wpctl set-volume @DEFAULT_AUDIO_SINK@ %1").arg(vol, 0, 'f', 3));
}

void ShellCtl::setSourceVolume(double vol)
{
    shOut(QStringLiteral("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ %1").arg(vol, 0, 'f', 3));
}

QVariantMap ShellCtl::displayState() const
{
    QVariantMap out;

    const QString b = shOut(QStringLiteral("brightnessctl -m"));
    const QStringList parts = b.split(QLatin1Char(','));
    if (parts.size() >= 4)
        out.insert(QStringLiteral("brightness"), QString(parts.at(3)).remove(QLatin1Char('%')).toDouble());
    else
        out.insert(QStringLiteral("brightness"), -1.0);
    out.insert(QStringLiteral("device"), parts.value(0));
    out.insert(QStringLiteral("max"), parts.value(4).toInt());

    const QString mon = shOut(QStringLiteral("hyprctl monitors -j"));
    const QJsonDocument doc = QJsonDocument::fromJson(mon.toUtf8());
    if (doc.isArray() && !doc.array().isEmpty()) {
        const QJsonObject o = doc.array().at(0).toObject();
        out.insert(QStringLiteral("name"), o.value(QStringLiteral("name")).toString());
        out.insert(QStringLiteral("model"), o.value(QStringLiteral("model")).toString());
        out.insert(QStringLiteral("make"), o.value(QStringLiteral("make")).toString());
        out.insert(QStringLiteral("width"), o.value(QStringLiteral("width")).toInt());
        out.insert(QStringLiteral("height"), o.value(QStringLiteral("height")).toInt());
        out.insert(QStringLiteral("refreshRate"), o.value(QStringLiteral("refreshRate")).toDouble());
        out.insert(QStringLiteral("scale"), o.value(QStringLiteral("scale")).toDouble());
        out.insert(QStringLiteral("x"), o.value(QStringLiteral("x")).toInt());
        out.insert(QStringLiteral("y"), o.value(QStringLiteral("y")).toInt());
    }
    return out;
}

QString ShellCtl::readFile(const QString &path) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();
    return QString::fromUtf8(f.readAll());
}

bool ShellCtl::writeFile(const QString &path, const QString &text)
{
    const QFileInfo fi(path);
    if (!fi.dir().exists() && !fi.dir().mkpath(QStringLiteral(".")))
        return false;
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return false;
    f.write(text.toUtf8());
    f.close();
    return true;
}

bool ShellCtl::saveAvatar(const QString &src, const QString &dst, int size)
{
    QImageReader rd(src);
    rd.setAutoTransform(true);
    if (!rd.canRead())
        return false;
    QImage im = rd.read();
    if (im.isNull())
        return false;
    im = im.convertToFormat(QImage::Format_ARGB32);

    // centre-crop to a square first so the circle always matches the picture
    const int side = qMin(im.width(), im.height());
    QImage sq = im.copy((im.width() - side) / 2, (im.height() - side) / 2, side, side);
    if (size > 0 && sq.width() != size)
        sq = sq.scaled(size, size, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

    // circular alpha mask: the picture then sits on any background
    QImage out(sq.size(), QImage::Format_ARGB32);
    out.fill(Qt::transparent);
    {
        QPainterPath path;
        path.addEllipse(QRectF(QPointF(0, 0), QSizeF(out.size())));
        QPainter p(&out);
        p.setRenderHint(QPainter::Antialiasing);
        p.setClipPath(path);
        p.drawImage(0, 0, sq);
    }

    const QFileInfo di(dst);
    if (!di.dir().exists() && !di.dir().mkpath(QStringLiteral(".")))
        return false;
    QFile::remove(dst);
    return out.save(dst, "PNG");
}

bool ShellCtl::copyImage(const QString &src, const QString &dst, int maxEdge)
{
    QImageReader rd(src);
    rd.setAutoTransform(true);
    if (!rd.canRead())
        return false;
    QImage im = rd.read();
    if (im.isNull())
        return false;
    if (maxEdge > 0 && (im.width() > maxEdge || im.height() > maxEdge))
        im = im.scaled(maxEdge, maxEdge, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    const QFileInfo di(dst);
    if (!di.dir().exists() && !di.dir().mkpath(QStringLiteral(".")))
        return false;
    QFile::remove(dst);
    return im.save(dst, "PNG");
}

QVariantList ShellCtl::displays() const
{
    QVariantList out;
    const QString mon = shOut(QStringLiteral("hyprctl monitors -j"));
    const QJsonDocument doc = QJsonDocument::fromJson(mon.toUtf8());
    if (!doc.isArray())
        return out;
    const QJsonArray arr = doc.array();
    out.reserve(arr.size());
    for (const QJsonValue &v : arr) {
        const QJsonObject o = v.toObject();
        QVariantMap m;
        m.insert(QStringLiteral("name"), o.value(QStringLiteral("name")).toString());
        m.insert(QStringLiteral("model"), o.value(QStringLiteral("model")).toString());
        m.insert(QStringLiteral("make"), o.value(QStringLiteral("make")).toString());
        m.insert(QStringLiteral("width"), o.value(QStringLiteral("width")).toInt());
        m.insert(QStringLiteral("height"), o.value(QStringLiteral("height")).toInt());
        m.insert(QStringLiteral("refreshRate"), o.value(QStringLiteral("refreshRate")).toDouble());
        m.insert(QStringLiteral("scale"), o.value(QStringLiteral("scale")).toDouble());
        m.insert(QStringLiteral("x"), o.value(QStringLiteral("x")).toInt());
        m.insert(QStringLiteral("y"), o.value(QStringLiteral("y")).toInt());
        m.insert(QStringLiteral("transform"), o.value(QStringLiteral("transform")).toInt(0));
        m.insert(QStringLiteral("focused"), o.value(QStringLiteral("focused")).toBool(false));
        m.insert(QStringLiteral("disabled"), o.value(QStringLiteral("disabled")).toBool(false));
        QStringList modes;
        const QJsonArray am = o.value(QStringLiteral("availableModes")).toArray();
        for (const QJsonValue &mv : am)
            modes << mv.toString();
        m.insert(QStringLiteral("modes"), modes);
        out.append(m);
    }
    return out;
}

bool ShellCtl::setMonitorRefresh(double hz)
{
    const QVariantMap m = displayState();
    const QString name = m.value(QStringLiteral("name")).toString();
    if (name.isEmpty() || hz < 20.0)
        return false;
    const int w = m.value(QStringLiteral("width")).toInt();
    const int h = m.value(QStringLiteral("height")).toInt();
    const int x = m.value(QStringLiteral("x")).toInt();
    const int y = m.value(QStringLiteral("y")).toInt();
    const double scale = m.value(QStringLiteral("scale")).toDouble();
    const QString cmd = QStringLiteral(
        "hyprctl keyword monitor \"%1,%2x%3@%4,%5x%6,%7\"")
        .arg(name)
        .arg(w).arg(h)
        .arg(hz, 0, 'f', 3)
        .arg(x).arg(y)
        .arg(scale, 0, 'f', 2);
    shOut(cmd);
    return true;
}

void ShellCtl::setBrightness(double pct)
{
    const int p = qBound(0, qRound(pct * 100.0), 100);
    shOut(QStringLiteral("brightnessctl -q set %1%%").arg(p));
}

bool ShellCtl::setMonitorScale(double scale)
{
    const QVariantMap m = displayState();
    const QString name = m.value(QStringLiteral("name")).toString();
    if (name.isEmpty() || scale <= 0.1)
        return false;
    const int w = m.value(QStringLiteral("width")).toInt();
    const int h = m.value(QStringLiteral("height")).toInt();
    const int x = m.value(QStringLiteral("x")).toInt();
    const int y = m.value(QStringLiteral("y")).toInt();
    const double hz = m.value(QStringLiteral("refreshRate")).toDouble();
    const QString cmd = QStringLiteral(
        "hyprctl keyword monitor \"%1,%2x%3@%4,%5x%6,%7\"")
        .arg(name)
        .arg(w).arg(h)
        .arg(hz, 0, 'f', 2)
        .arg(x).arg(y)
        .arg(scale, 0, 'f', 2);
    shOut(cmd);
    return true;
}
