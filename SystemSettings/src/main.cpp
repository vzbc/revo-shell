#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QDebug>
#include <QQmlError>
#include <QQmlContext>
#include <QQmlComponent>
#include <QDir>
#include "sysinfo.h"
#include "shellctl.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QGuiApplication::setApplicationName(QStringLiteral("System Settings"));
    QGuiApplication::setOrganizationName(QStringLiteral("macOS"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QQmlApplicationEngine engine;

    // absolute home for QML — never hardcode a dev user's path
    engine.rootContext()->setContextProperty(QStringLiteral("HOME_DIR"), QDir::homePath());

    SysInfo sysInfo;
    engine.rootContext()->setContextProperty("SysInfo", &sysInfo);
    sysInfo.refresh();

    ShellCtl shell;
    engine.rootContext()->setContextProperty("Shell", &shell);

    // Theme instance
    {
        QQmlComponent themeComp(&engine, QUrl(QStringLiteral("qrc:/Theme.qml")));
        QObject *themeObj = themeComp.create(engine.rootContext());
        if (!themeObj) {
            qWarning() << "Theme instance failed:" << themeComp.errorString();
        } else {
            themeObj->setParent(&engine);
            engine.rootContext()->setContextProperty("Theme", themeObj);
        }
    }

    QObject::connect(&engine, &QQmlEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
                         for (const QQmlError &e : warnings)
                             qWarning() << "QML WARNING:" << e.toString() << "|" << e.description();
                     });

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() {
                         qWarning() << "QML: objectCreationFailed";
                         QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.loadFromModule("org.macos.systemsettings", "Main");

    if (engine.rootObjects().isEmpty()) {
        qWarning() << "QML: rootObjects empty after loadFromModule";
        return -1;
    }

    return app.exec();
}
