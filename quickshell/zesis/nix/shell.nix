{
  mkShell,
  lib,
  quickshell,
  clang-tools,
  imagemagick,
  glsl_analyzer,
  qt6,
  python3,
  athroisma,
  congeries,
}:
mkShell {
  packages = [
    quickshell
    clang-tools
    imagemagick
    glsl_analyzer
    qt6.qtshadertools
    athroisma
    congeries
    (python3.withPackages (ps:
      with ps; [
        icalendar
        recurring-ical-events
      ]))
  ];

  QML_IMPORT_PATH = lib.concatStringsSep ":" [
    "${qt6.qtdeclarative}/lib/qt-6/qml"
    "${qt6.qtquick3d}/lib/qt-6/qml"
    "${quickshell}/lib/qt-6/qml"
    "${congeries}/lib/qt-6/qml"
  ];

  QT_PLUGIN_PATH = lib.concatStringsSep ":" [
    "${qt6.qtquick3d}/lib/qt-6/plugins"
    "${qt6.qtdeclarative}/lib/qt-6/plugins"
    "${qt6.qtbase}/lib/qt-6/plugins"
  ];

  ZESIS_DEV = "1";
}
