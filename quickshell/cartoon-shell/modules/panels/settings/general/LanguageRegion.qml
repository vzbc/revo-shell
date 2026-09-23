import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.components

Item {
    id: root
    function setLanguageEditor(name) {
        Settings.general.lang = name;
    }
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: ScalerService.s(20)
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: parent.width
            spacing: ScalerService.s(15)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)

                // Tiêu đề
                HeaderSettings {
                    name: "Language Region"
                    opacity: root.animationProgress > 0.1 ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
                opacity: root.animationProgress > 0.2 ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            // Language Selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)

                CustomText {
                    name: lang.general?.language_label || "Ngôn ngữ:"
                    size: "small"
                    opacity: root.animationProgress > 0.3 ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                Grid {
                    Layout.fillWidth: true
                    columns: 6
                    columnSpacing: ScalerService.s(6)
                    rowSpacing: ScalerService.s(6)

                    Repeater {
                        model: [
                            {
                                code: "vi",
                                name: "Tiếng Việt",
                                flagImg: "vietnam"
                            },
                            {
                                code: "en",
                                name: "English",
                                flagImg: "britain"
                            },
                            {
                                code: "zh",
                                name: "中文",
                                flagImg: "china"
                            },
                            {
                                code: "ja",
                                name: "日本語",
                                flagImg: "japan"
                            },
                            {
                                code: "ko",
                                name: "한국어",
                                flagImg: "korea"
                            },
                            {
                                code: "ru",
                                name: "Русский",
                                flagImg: "russia"
                            },
                            {
                                code: "hi",
                                name: "हिन्दी",
                                flagImg: "india"
                            },
                            {
                                code: "es",
                                name: "Español",
                                flagImg: "spain"
                            },
                            {
                                code: "pt",
                                name: "Português",
                                flagImg: "portugal"
                            },
                            {
                                code: "fr",
                                name: "Français",
                                flagImg: "france"
                            },
                            {
                                code: "de",
                                name: "Deutsch",
                                flagImg: "german"
                            },
                            {
                                code: "it",
                                name: "Italiano",
                                flagImg: "italy"
                            },
                            {
                                code: "ar",
                                name: "العربية",
                                flagImg: "saudi_arabia"
                            },
                            {
                                code: "tr",
                                name: "Türkçe",
                                flagImg: "turkey"
                            },
                            {
                                code: "nl",
                                name: "Nederlands",
                                flagImg: "netherlands"
                            },
                            {
                                code: "pl",
                                name: "Polski",
                                flagImg: "poland"
                            },
                            {
                                code: "sv",
                                name: "Svenska",
                                flagImg: "sweden"
                            },
                            {
                                code: "th",
                                name: "ไทย",
                                flagImg: "thailand"
                            },
                            {
                                code: "uk",
                                name: "Українська",
                                flagImg: "ukraine"
                            },
                            {
                                code: "no",
                                name: "Norsk",
                                flagImg: "norway"
                            },
                            {
                                code: "da",
                                name: "Dansk",
                                flagImg: "denmark"
                            },
                            {
                                code: "fi",
                                name: "Suomi",
                                flagImg: "finland"
                            },
                            {
                                code: "id",
                                name: "Indonesia",
                                flagImg: "indonesia"
                            },
                            {
                                code: "cs",
                                name: "Čeština",
                                flagImg: "czech"
                            },
                            {
                                code: "el",
                                name: "Ελληνικά",
                                flagImg: "greece"
                            },
                            {
                                code: "he",
                                name: "עברית",
                                flagImg: "israel"
                            },
                            {
                                code: "ro",
                                name: "Română",
                                flagImg: "romania"
                            },
                            {
                                code: "hu",
                                name: "Magyar",
                                flagImg: "hungary"
                            },
                            {
                                code: "bg",
                                name: "Български",
                                flagImg: "bulgaria"
                            },
                            {
                                code: "sk",
                                name: "Slovenčina",
                                flagImg: "slovakia"
                            },
                        ]

                        delegate: Item {
                            id: parentItem
                            width: root.width / 7
                            height: root.width / 7
                            CustomRectangle {
                                implicitWidth: 0
                                implicitHeight: 0
                                anchors.centerIn: parentItem
                                SequentialAnimation on implicitWidth {
                                    running: root.animationProgress > 0.2

                                    PauseAnimation {
                                        duration: index * 15
                                    }

                                    NumberAnimation {
                                        to: parentItem.width
                                        duration: 500
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                SequentialAnimation on implicitHeight {
                                    running: root.animationProgress > 0.2

                                    PauseAnimation {
                                        duration: index * 15
                                    }

                                    NumberAnimation {
                                        to: parentItem.height
                                        duration: 500
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                radius: ScalerService.s(10)
                                color: Settings.general.lang === modelData.code ? Qt.alpha(theme.button.text, 0.6) : (langMouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))
                                border.color: Settings.general.lang === modelData.code ? Qt.alpha(theme.button.text, 0.6) : (langMouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
                                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: ScalerService.s(4)

                                    IconImage {
                                        path: `flags/${modelData.flagImg}.png`
                                        size: "large"
                                        Layout.alignment: Qt.AlignHCenter
                                        opacity: 0

                                        SequentialAnimation on opacity {
                                            running: root.animationProgress > 0.8

                                            PauseAnimation {
                                                duration: index * 15
                                            }

                                            NumberAnimation {
                                                to: 1
                                                duration: 500
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    CustomText {
                                        name: modelData.name
                                        textColor: Settings.general.lang === modelData.code ? theme.primary.background : theme.primary.foreground
                                        isBold: Settings.general.lang === modelData.code
                                        size: "xs"
                                        Layout.alignment: Qt.AlignHCenter
                                        opacity: 0

                                        SequentialAnimation on opacity {
                                            running: root.animationProgress > 0.9

                                            PauseAnimation {
                                                duration: index * 15
                                            }

                                            NumberAnimation {
                                                to: 1
                                                duration: 500
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: langMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        SoundService.playSound("pick");
                                        setLanguageEditor(modelData.code);
                                    }
                                    onEntered: {
                                        SoundService.playSound("hover");
                                    }
                                }

                                // Checkmark for selected language
                                Rectangle {
                                    visible: Settings.general.lang === modelData.code
                                    width: ScalerService.s(18)
                                    height: ScalerService.s(18)
                                    radius: ScalerService.s(9)
                                    color: theme.button.text
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: ScalerService.s(4)
                                    opacity: 0

                                    SequentialAnimation on opacity {
                                        running: root.animationProgress > 0.9

                                        PauseAnimation {
                                            duration: index * 15
                                        }

                                        NumberAnimation {
                                            to: 1
                                            duration: 500
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    IconText {
                                        name: "check"
                                        size: "xs"
                                        textColor: theme.primary.background
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            } // Spacer
        }
    }
}
