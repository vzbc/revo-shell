import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import QtQuick.Controls.Basic
import Quickshell.Io

Item {
    id: root

    // Font list model
    ListModel {
        id: fontListModel
    }

    property bool isLoading: true
    property int highlightedIndex: 0

    // Process to get font list
    Process {
        id: fcListProcess
        command: ["bash", "-c", "fc-list : family | tr ',' '\\n' | sed 's/^[ \\t]*//' | grep -v '^Noto ' | sort -u"]

        stdout: StdioCollector {
            onStreamFinished: {
                var fonts = this.text.trim().split('\n');
                fontListModel.clear();

                for (var i = 0; i < fonts.length; i++) {
                    if (fonts[i].trim() !== "") {
                        fontListModel.append({
                            "name": fonts[i].trim()
                        });
                    }
                }

                isLoading = false;

                // Tìm và set current index sau khi load xong
                var currentIndex = findCurrentFontIndex();
                if (currentIndex !== -1) {
                    highlightedIndex = currentIndex;
                    fontCombo.currentIndex = currentIndex;
                } else if (fontListModel.count > 0) {
                    highlightedIndex = 0;
                    fontCombo.currentIndex = 0;
                }

                console.log("Loaded " + fontListModel.count + " fonts");
            }
        }
    }

    function findCurrentFontIndex() {
        var currentFont = Settings.appearance.font || "Iosevka";
        console.log("Current font:" + currentFont);

        for (var i = 0; i < fontListModel.count; i++) {
            if (fontListModel.get(i).name === currentFont) {
                return i;
            }
        }
        return -1;
    }

    function addFallbackFonts() {
        var fallbackFonts = ["Iosevka", "JetBrains Mono", "Noto Sans", "DejaVu Sans"];

        for (var i = 0; i < fallbackFonts.length; i++) {
            fontListModel.append({
                "name": fallbackFonts[i]
            });
        }
        isLoading = false;
    }

    function refreshFontList() {
        isLoading = true;
        fontListModel.clear();
        fcListProcess.running = true;
    }

    Component.onCompleted: {
        refreshFontList();
    }

    ColumnLayout {
        width: parent.width
        spacing: ScalerService.s(20)

        // Title
        HeaderSettings {
            name: "Font Settings"
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScalerService.s(1)
            color: theme.primary.foreground
            opacity: 0.2
        }

        // Loading indicator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(100)
            color: Qt.alpha(theme.primary.background, 0.5)
            radius: ScalerService.s(8)
            visible: isLoading

            ColumnLayout {
                anchors.centerIn: parent
                spacing: ScalerService.s(10)

                CustomText {
                    name: "Loading fonts..."
                    textColor: theme.primary.foreground
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                }
            }
        }

        // Simple ComboBox for fonts
        Rectangle {
            Layout.fillWidth: true
            color: "transparent"
            visible: !isLoading

            ColumnLayout {
                width: parent.width
                spacing: ScalerService.s(10)

                CustomText {
                    name: "Select Font"
                    textColor: theme.primary.foreground
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(10)

                    ComboBox {
                        id: fontCombo
                        Layout.fillWidth: true
                        model: fontListModel
                        textRole: "name"
                        currentIndex: highlightedIndex

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && currentIndex < fontListModel.count) {
                                root.highlightedIndex = currentIndex;
                                var selectedFont = fontListModel.get(currentIndex).name;
                                Settings.appearance.font = selectedFont;
                                console.log("Selected font:", Settings.appearance.font);
                            }
                        }

                        background: Rectangle {
                            color: theme.button.background
                            border.color: theme.button.border
                            border.width: 1
                            radius: 4
                        }

                        delegate: ItemDelegate {
                            width: parent.width
                            highlighted: parent.highlightedIndex === index

                            contentItem: CustomText {
                                name: model.name
                                font.family: model.name
                                textColor: highlighted ? theme.primary.foreground : theme.primary.dim_foreground
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: highlighted ? Qt.alpha(theme.accent, 0.3) : "transparent"
                            }
                        }
                    }

                    Button {
                        text: "↻"
                        font.pixelSize: ScalerService.s(16)
                        onClicked: {
                            refreshFontList();
                        }
                    }
                }
            }
        }
    }
}
