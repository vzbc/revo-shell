import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: root
    property real animationProgress: 0
    property int indexCategory: 0
    signal currentTab(int index)
    property var listCategory: [
        {
            categoryName: "General",
            items: [
                {
                    name: "Language & Region",
                    image: "settings/languages.png",
                    icon: "translate",
                    category: "language"
                },
                {
                    name: "Date & Time",
                    image: "settings/time.png",
                    icon: "calendar_month",
                    category: "datetime"
                },
                {
                    name: "Startup",
                    image: "settings/startup.png",
                    icon: "rocket_launch",
                    category: "session"
                },
                {
                    name: "Behavior",
                    image: "settings/behavior.png",
                    icon: "psychology_alt",
                    category: "behavior"
                },
                {
                    name: "Notifications",
                    icon: "notifications",
                    image: "settings/notification.png",
                    category: "notifications"
                },
                {
                    name: "Privacy",
                    icon: "privacy_tip",
                    image: "settings/privacy.png",
                    category: "privacy"
                }
            ]
        },
        {
            categoryName: "Appearance",
            items: [
                {
                    name: "Theme",
                    image: "settings/theme.png",
                    icon: "palette",
                    category: "theme"
                },
                {
                    name: "Panel",
                    image: "settings/layout.png",
                    icon: "mobile_layout",
                    category: "panel"
                },
                {
                    name: "Clock",
                    image: "settings/clock.png",
                    icon: "nest_clock_farsight_analog",
                    category: "clock"
                },
                {
                    name: "Fonts",
                    image: "settings/fonts.png",
                    icon: "font_download",
                    category: "fonts"
                },
                {
                    name: "Icons",
                    image: "settings/icons.png",
                    icon: "add_reaction",
                    category: "icons"
                },
                {
                    name: "Effects",
                    image: "settings/effects.png",
                    icon: "wand_stars",
                    category: "effects"
                },
                {
                    name: "Layout",
                    image: "settings/layout.png",
                    icon: "auto_awesome_mosaic",
                    category: "layout"
                },
                {
                    name: "Wallpaper",
                    image: "settings/Wallpaper.png",
                    icon: "wallpaper",
                    category: "wallpaper"
                }
            ]
        }
    ]
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(50)
    opacity: root.animationProgress > 0.1 ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    color: Qt.alpha(theme.button.background, 0.6)
    radius: ScalerService.s(12)

    RowLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(8)
        spacing: ScalerService.s(16)

        Item {
            Layout.fillWidth: true
        } // Spacer
        Repeater {
            model: root.listCategory[root.indexCategory].items

            delegate: Item {
                id: minimalDelegate
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(42)

                property bool selected: root.currentTab === index

                // Hiệu ứng scale
                scale: mouseArea.containsPress ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                // Icon
                IconImage {
                    anchors.centerIn: parent
                    path: modelData.image
                    opacity: 0
                    size: "large"
                    visible: Settings.appearance.styleIcons === "image"
                    SequentialAnimation on opacity {
                        running: root.animationProgress > 0.4

                        PauseAnimation {
                            duration: index * 15
                        }

                        NumberAnimation {
                            to: 1
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                IconText {
                    name: modelData.icon
                    textColor: theme.button.text
                    visible: Settings.appearance.styleIcons === "icon"
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentTab(index);
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        } // Spacer
    }
}
