import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject clipboardService
    property bool active: false
    property var results: []
    property int selectedIndex: -1
    property bool wipeConfirmationOpen: false
    readonly property int resultLimit: 8
    readonly property int visibleRowCount: Math.max(5, Math.min(resultLimit, results.length > 0 ? results.length : 5))

    signal closeRequested()

    function refreshResults() {
        if (!active)
            return ;

        results = clipboardService.search(searchField.text, resultLimit);
        selectedIndex = results.length > 0 ? Math.max(0, Math.min(selectedIndex, results.length - 1)) : -1;
    }

    function open() {
        wipeConfirmationOpen = false;
        searchField.text = "";
        selectedIndex = 0;
        clipboardService.refresh();
        refreshResults();
        searchField.focusInput();
    }

    function resetTransientState() {
        wipeConfirmationOpen = false;
        searchField.text = "";
    }

    function moveSelection(offset) {
        if (results.length === 0)
            return ;

        selectedIndex = (selectedIndex + offset + results.length) % results.length;
        resultsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function copySelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return ;

        clipboardService.copyItem(results[selectedIndex]);
    }

    implicitWidth: theme.clipboardWidth
    implicitHeight: clipboardColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()
    Keys.onDeletePressed: {
        if (selectedIndex >= 0 && selectedIndex < results.length)
            clipboardService.deleteItem(results[selectedIndex]);

    }

    Connections {
        function onItemsChanged() {
            root.refreshResults();
        }

        function onItemCopied() {
            root.closeRequested();
        }

        target: root.clipboardService
    }

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: clipboardColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: root.theme.space3

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: root.theme.radiusControl
                    color: root.theme.pink
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconMd
                        height: root.theme.iconMd
                        source: Quickshell.shellDir + "/assets/icons/clipboard.svg"
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textLg
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.clipboardService.captureEnabled ? "Local history is being captured" : "Capture is paused"
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 24
                    radius: root.theme.radiusPill
                    color: root.theme.alpha(root.theme.green, 0.58)
                    border.width: 1
                    border.color: root.theme.ink

                    Text {
                        anchors.centerIn: parent
                        text: "LOCAL ONLY"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: 7
                        font.weight: Font.Bold
                    }

                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 34
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close clipboard"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            Ui.SearchField {
                id: searchField

                Layout.fillWidth: true
                theme: root.theme
                placeholderText: "Search copied text"
                onTextChanged: {
                    root.selectedIndex = 0;
                    root.refreshResults();
                }
                onMoveRequested: (offset) => {
                    return root.moveSelection(offset);
                }
                onSubmitRequested: root.copySelected()
                onCancelRequested: root.closeRequested()
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.theme.clipboardRowHeight * root.visibleRowCount + root.theme.space2 * (root.visibleRowCount - 1)

                ListView {
                    id: resultsList

                    anchors.fill: parent
                    visible: !root.clipboardService.loading && !root.clipboardService.error && root.results.length > 0
                    clip: true
                    spacing: root.theme.space2
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.results
                    }

                    delegate: ClipboardRow {
                        required property int index
                        required property var modelData

                        width: resultsList.width
                        theme: root.theme
                        entry: modelData
                        selected: index === root.selectedIndex
                        onHovered: root.selectedIndex = index
                        onActivated: {
                            root.selectedIndex = index;
                            root.copySelected();
                        }
                        onDeleteRequested: {
                            root.selectedIndex = index;
                            root.clipboardService.deleteItem(modelData);
                        }
                    }

                }

                Column {
                    anchors.centerIn: parent
                    visible: root.clipboardService.loading
                    spacing: root.theme.space2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Reading local history"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textMd
                        font.weight: Font.Bold
                    }

                }

                Column {
                    anchors.centerIn: parent
                    visible: !root.clipboardService.loading && (root.clipboardService.error || root.results.length === 0)
                    spacing: root.theme.space2

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.theme.iconLg
                        height: root.theme.iconLg
                        source: Quickshell.shellDir + "/assets/icons/clipboard.svg"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.clipboardService.error ? "Clipboard history is unavailable" : (searchField.text.length > 0 ? "No matching clipboard entries" : "Nothing copied yet")
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textMd
                        font.weight: Font.Bold
                    }

                }

            }

            Rectangle {
                visible: root.wipeConfirmationOpen
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                radius: root.theme.radiusCard
                color: root.theme.alpha(root.theme.coral, 0.38)
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.theme.space2
                    spacing: root.theme.space2

                    Text {
                        Layout.fillWidth: true
                        text: "Permanently clear every clipboard entry?"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: Font.DemiBold
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 78
                        theme: root.theme
                        label: "Cancel"
                        fill: root.theme.surfaceRaised
                        onClicked: root.wipeConfirmationOpen = false
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 78
                        theme: root.theme
                        label: "Clear"
                        fill: root.theme.coral
                        onClicked: {
                            root.wipeConfirmationOpen = false;
                            root.clipboardService.wipe();
                        }
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space3

                Text {
                    Layout.fillWidth: true
                    text: "Enter copies   Delete removes   Esc closes"
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 112
                    theme: root.theme
                    label: root.clipboardService.captureEnabled ? "Pause capture" : "Resume capture"
                    fill: root.theme.blue
                    onClicked: root.clipboardService.toggleCapture()
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 92
                    theme: root.theme
                    label: "Clear all"
                    fill: root.theme.coral
                    enabled: root.clipboardService.items.length > 0 && !root.clipboardService.actionBusy
                    onClicked: root.wipeConfirmationOpen = true
                }

            }

            Text {
                visible: root.clipboardService.lastError.length > 0
                Layout.fillWidth: true
                text: root.clipboardService.lastError
                color: root.theme.danger
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
            }

        }

    }

}
