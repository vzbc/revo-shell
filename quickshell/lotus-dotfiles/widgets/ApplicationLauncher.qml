import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject launcherService
    property bool active: false
    property var results: []
    property int selectedIndex: -1
    readonly property int resultLimit: theme.launcherVisibleRows

    signal closeRequested()

    function refreshResults() {
        if (!active)
            return ;

        results = launcherService.search(searchField.text, resultLimit);
        selectedIndex = results.length > 0 ? Math.max(0, Math.min(selectedIndex, results.length - 1)) : -1;
    }

    function open() {
        searchField.text = "";
        selectedIndex = 0;
        refreshResults();
        searchField.focusInput();
    }

    function moveSelection(offset) {
        if (results.length === 0)
            return ;

        selectedIndex = (selectedIndex + offset + results.length) % results.length;
        resultsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function launchSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return ;

        if (launcherService.launch(results[selectedIndex]))
            closeRequested();

    }

    implicitWidth: theme.launcherWidth
    implicitHeight: launcherColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Connections {
        function onApplicationsUpdated() {
            root.refreshResults();
        }

        target: root.launcherService
    }

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: launcherColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: root.theme.space2

                Image {
                    Layout.preferredWidth: root.theme.iconMd
                    Layout.preferredHeight: root.theme.iconMd
                    source: Quickshell.shellDir + "/assets/icons/lotus.svg"
                    sourceSize.width: root.theme.iconMd
                    sourceSize.height: root.theme.iconMd
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Applications"
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textLg
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.preferredWidth: countLabel.implicitWidth + root.theme.space3
                    Layout.preferredHeight: 24
                    radius: root.theme.radiusPill
                    color: root.theme.alpha(root.theme.gold, 0.55)
                    border.width: 1
                    border.color: root.theme.ink

                    Text {
                        id: countLabel

                        anchors.centerIn: parent
                        text: root.launcherService.loading ? "..." : root.launcherService.applications.length + " apps"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: Font.Bold
                    }

                }

            }

            Ui.SearchField {
                id: searchField

                Layout.fillWidth: true
                theme: root.theme
                onTextChanged: {
                    root.selectedIndex = 0;
                    root.refreshResults();
                }
                onMoveRequested: (offset) => {
                    return root.moveSelection(offset);
                }
                onSubmitRequested: root.launchSelected()
                onCancelRequested: root.closeRequested()
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.theme.launcherRowHeight * root.resultLimit

                ListView {
                    id: resultsList

                    anchors.fill: parent
                    visible: !root.launcherService.loading && root.results.length > 0
                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.results
                    }

                    delegate: ApplicationRow {
                        required property int index
                        required property var modelData

                        width: resultsList.width
                        theme: root.theme
                        application: modelData
                        selected: index === root.selectedIndex
                        onHovered: root.selectedIndex = index
                        onActivated: {
                            root.selectedIndex = index;
                            root.launchSelected();
                        }
                    }

                }

                Column {
                    anchors.centerIn: parent
                    visible: root.launcherService.loading
                    spacing: root.theme.space2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Indexing desktop apps"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textMd
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "The list updates when desktop files change."
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Column {
                    anchors.centerIn: parent
                    visible: !root.launcherService.loading && root.results.length === 0
                    spacing: root.theme.space2

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.theme.iconLg
                        height: root.theme.iconLg
                        source: Quickshell.shellDir + "/assets/icons/application.svg"
                        sourceSize.width: root.theme.iconLg
                        sourceSize.height: root.theme.iconLg
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.launcherService.nativeAvailable ? "No matching applications" : "No desktop applications found"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textMd
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.launcherService.nativeAvailable ? "Try another name or category." : "Use the Rofi fallback below."
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.theme.outlineSoft
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.theme.controlHeight + root.theme.shadowOffset
                spacing: root.theme.space3

                Text {
                    Layout.fillWidth: true
                    text: "Up / Down to move   Enter to open   Esc to close"
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

                Ui.PixelButton {
                    theme: root.theme
                    label: root.launcherService.fallbackChecked ? "Rofi fallback" : "Checking Rofi"
                    fill: root.theme.blue
                    enabled: root.launcherService.fallbackAvailable
                    onClicked: {
                        if (root.launcherService.openFallback())
                            root.closeRequested();

                    }
                }

            }

            Text {
                visible: root.launcherService.lastError.length > 0
                Layout.fillWidth: true
                text: root.launcherService.lastError
                color: root.theme.danger
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
            }

        }

    }

}
