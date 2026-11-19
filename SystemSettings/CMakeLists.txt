cmake_minimum_required(VERSION 3.21)
project(SystemSettings VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 Multimedia)
qt_standard_project_setup()

file(GLOB ICON_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/icons/*.png")

foreach(icon IN LISTS ICON_FILES)
    get_filename_component(icon_name "${icon}" NAME)
    set_source_files_properties("${icon}" PROPERTIES QT_RESOURCE_ALIAS "${icon_name}")
endforeach()

qt_add_executable(systemsettings
    src/main.cpp
    src/sysinfo.cpp
    src/sysinfo.h
    src/shellctl.cpp
    src/shellctl.h
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_RESOURCE_ALIAS "Theme.qml")

qt_add_resources(systemsettings "themeres"
    PREFIX "/"
    FILES qml/Theme.qml
)

qt_add_resources(systemsettings "icons"
    PREFIX "/icons"
    FILES ${ICON_FILES}
)

# helper scripts run by pages (copied to ~/.cache/systemsettings on use)
set_source_files_properties(scripts/battery_history.py PROPERTIES QT_RESOURCE_ALIAS "battery_history.py")
set_source_files_properties(scripts/steam_profile.py PROPERTIES QT_RESOURCE_ALIAS "steam_profile.py")
qt_add_resources(systemsettings "scripts"
    PREFIX "/scripts"
    FILES scripts/battery_history.py scripts/steam_profile.py
)

# Trackpad gesture movies (Apple's Trackpad.mov, one animated WebP per chapter)
file(GLOB TRACKPAD_MEDIA CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/media/trackpad/*.webp")
foreach(clip IN LISTS TRACKPAD_MEDIA)
    get_filename_component(clip_name "${clip}" NAME)
    set_source_files_properties("${clip}" PROPERTIES QT_RESOURCE_ALIAS "trackpad/${clip_name}")
endforeach()
qt_add_resources(systemsettings "media"
    PREFIX "/media"
    BIG_RESOURCES
    FILES ${TRACKPAD_MEDIA}
)

qt_add_qml_module(systemsettings
    URI org.macos.systemsettings
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Pages.js
        qml/PagesContent.js
        qml/Sidebar.qml
        qml/SidebarRow.qml
        qml/AppleAccountCell.qml
        qml/Avatar.qml
        qml/DetailPane.qml
        qml/Placard.qml
        qml/GroupCard.qml
        qml/DetailRow.qml
        qml/PlaceholderPage.qml
        qml/MacToggle.qml
        qml/MacCheck.qml
        qml/MacPicker.qml
        qml/MacSlider.qml
        qml/MacButton.qml
        qml/BlueLink.qml
        qml/HelpCircle.qml
        qml/InfoDot.qml
        qml/AppTile.qml
        qml/SectionHeader.qml
        qml/ToggleRow.qml
        qml/HueGradient.qml
        qml/MenuControlRow.qml
        qml/pages/GeneralPage.qml
        qml/pages/ListPage.qml
        qml/pages/StoragePage.qml
        qml/pages/StorageDetail.qml
        qml/pages/SignInPage.qml
        qml/pages/MenuBarPage.qml
        qml/pages/AppearancePage.qml
        qml/pages/HoverTextPage.qml
        qml/pages/MotionPage.qml
    qml/pages/DeviceDetailsPage.qml
    qml/pages/WifiPage.qml
    qml/pages/BluetoothPage.qml
    qml/pages/NetworkPage.qml
    qml/pages/BatteryPage.qml
    qml/pages/IcloudPage.qml
        qml/pages/DockPreview.qml
        qml/pages/DesktopDockPage.qml
        qml/pages/WallpaperPage.qml
        qml/pages/SoundPage.qml
        qml/pages/SpotlightPage.qml
        qml/pages/DisplaysPage.qml
        qml/pages/LockScreenPage.qml
        qml/pages/SiriPage.qml
        qml/pages/TrackpadPage.qml
        qml/pages/AboutPage.qml
        qml/pages/SoftwareUpdatePage.qml
        qml/pages/GameCenterPage.qml
        qml/pages/ScreenTimePage.qml
        qml/MacSegmented.qml
)

target_link_libraries(systemsettings PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia)
