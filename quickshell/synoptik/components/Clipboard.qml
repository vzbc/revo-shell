import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: clipRoot

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    property string filterText: ""

    ListModel { id: clipModel }

    function refreshClipboard() {
        fetchProc.running = false
        fetchProc.running = true
    }

    Component.onCompleted: {
        refreshClipboard()
    }

    Connections {
        target: Config
        function onShowClipboardChanged() {
            if (Config.showClipboard) {
                refreshClipboard()
            }
        }
    }
    
    // Process 1: Instantaneous list fetching
    Process {
        id: fetchProc
        running: false
        command: ["cliphist", "list"]
        
        stdout: StdioCollector {
            id: fetchOut 
            onStreamFinished: {
                let outText = fetchOut.text
                
                if (!outText || outText.trim() === "") {
                    clipModel.clear()
                    return
                }
                
                let lines = outText.trim().split("\n")
                let newItems = []
                
                for (let line of lines) {
                    if (!line) continue
                    let firstTab = line.indexOf("\t")
                    
                    if (firstTab !== -1) {
                        let id = line.substring(0, firstTab).trim()
                        let text = line.substring(firstTab + 1).trim()
                        
                        let isBinary = text.includes("binary data") || text.includes("image") || text.startsWith("[[")
                        let isBase64 = text.startsWith("data:image/")
                        let isWebUrl = /^https?:\/\/.*\.(png|jpg|jpeg|webp|gif|svg)(\?.*)?$/i.test(text)
                        let isLocalFile = (text.startsWith("/") || text.startsWith("file://")) && 
                                          /\.(png|jpg|jpeg|webp|gif|svg)$/i.test(text)

                        let finalImgPath = ""
                        
                        if (isBinary || isBase64) {
                            finalImgPath = ""
                        } else if (isWebUrl) {
                            finalImgPath = text
                        } else if (isLocalFile) {
                            finalImgPath = text.startsWith("file://") ? text : ("file://" + text)
                        }

                        let isVisualItem = isBinary || isBase64 || isWebUrl || isLocalFile

                        newItems.push({
                            itemId: id,
                            previewText: text,
                            isImage: isVisualItem,
                            imagePath: finalImgPath
                        })
                    }
                }
                
                clipModel.clear()
                for (let item of newItems) {
                    clipModel.append(item)
                }

                cacheProc.running = false
                cacheProc.running = true
            }
        }
    }

    // Process 2: Heavy asynchronous image generation
    Process {
        id: cacheProc
        running: false
        command: [
            "sh", "-c", 
            "mkdir -p /tmp/cliphist; " +
            "cliphist list | head -n 40 | while read -r id line; do " +
                "img_path=\"/tmp/cliphist/$id.png\"; " +
                "if [ -f \"$img_path\" ]; then " +
                    "echo \"$id\"; " +
                "else " +
                    "case \"$line\" in " +
                        "*\\[\\[*|*image*|*binary*) " +
                            "printf '%s\\t%s\\n' \"$id\" \"$line\" | cliphist decode > \"$img_path\" 2>/dev/null; " +
                            "[ -s \"$img_path\" ] && echo \"$id\"; " +
                            ";; " +
                    "esac; " +
                "fi; " +
            "done"
        ]

        stdout: StdioCollector {
            id: cacheOut
            onStreamFinished: {
                let out = cacheOut.text
                if (!out) return
                
                let generatedIds = out.trim().split("\n")
                if (generatedIds.length === 0 || !generatedIds[0]) return

                for (let i = 0; i < clipModel.count; i++) {
                    let item = clipModel.get(i)
                    if (generatedIds.includes(item.itemId)) {
                        let targetPath = "file:///tmp/cliphist/" + item.itemId + ".png"
                        clipModel.setProperty(i, "imagePath", targetPath + "?t=" + Date.now())
                    }
                }
            }
        }
    }

    Process { 
        id: copyProc
        onExited: {
            refreshClipboard()
        }
    }

    Process {
        id: deleteSingleProc
        running: false
        onExited: {
            refreshClipboard()
        }
    }

    Process {
        id: wipeProc
        running: false
        command: ["fish", "-c", "cliphist wipe; and rm -rf /tmp/cliphist/*"]
        onExited: {
            refreshClipboard()
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: clipRoot.cardMargin
        spacing: clipRoot.cardMargin / 2

        Rectangle {
            id: mainCard
            Layout.fillWidth: true
            implicitWidth: 380
            implicitHeight: cardContent.implicitHeight + (clipRoot.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("clipboard")
                iconSize: 150
                seed: 9
            }

            Behavior on implicitHeight {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: clipRoot.cardMargin
                spacing: clipRoot.cardMargin

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        implicitWidth: clipTitleText.implicitWidth
                        implicitHeight: clipTitleText.implicitHeight

                        Glow {
                            anchors.fill: clipTitleText
                            source: clipTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: clipTitleText
                            anchors.fill: parent
                            text: "CLIPBOARD"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                        }
                    }

                    // ITEM COUNT BADGE
                    Rectangle {
                        implicitWidth: countText.implicitWidth + 12
                        implicitHeight: 20
                        radius: 10
                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3)
                        visible: clipModel.count > 0

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: clipModel.count + " ITEMS"
                            color: Config.accent
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: clearText.implicitWidth + 12
                        implicitHeight: 24
                        radius: Config.cornerRadius / 2
                        color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                        visible: clipModel.count > 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "CLEAR ALL"
                            color: clearHover.hovered ? Config.accent : Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { 
                            onTapped: {
                                wipeProc.running = false
                                wipeProc.running = true 
                            }
                        }
                        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                    }
                }

                // SEARCH BAR
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Qt.rgba(0, 0, 0, 0.25)
                    radius: Config.cornerRadius / 2
                    border.width: searchInput.activeFocus ? 1 : 0
                    border.color: Config.accent
                    visible: clipModel.count > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "search"
                            color: Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "Search history..."
                            placeholderTextColor: Config.textMuted
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            background: null
                            selectByMouse: true
                            onTextChanged: clipRoot.filterText = text.trim().toLowerCase()
                        }

                        Rectangle {
                            implicitWidth: 18; implicitHeight: 18; radius: 9
                            color: clearSearchHover.hovered ? Qt.rgba(255,255,255,0.15) : "transparent"
                            visible: searchInput.text.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                color: Config.textMuted
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                            }

                            TapHandler { onTapped: searchInput.text = "" }
                            HoverHandler { id: clearSearchHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: clipModel.count > 0 
                        ? Math.min(clipList.contentHeight, 320) 
                        : emptyStateContainer.implicitHeight
                    color: "transparent"
                    clip: true

                    Behavior on implicitHeight {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    ListView {
                        id: clipList
                        anchors.fill: parent
                        model: clipModel
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: delegateRoot
                            required property string itemId
                            required property string previewText
                            required property bool isImage
                            required property string imagePath

                            property bool matchesSearch: clipRoot.filterText === "" || previewText.toLowerCase().includes(clipRoot.filterText)

                            visible: matchesSearch
                            width: ListView.view.width
                            implicitHeight: matchesSearch ? ((delegateRoot.isImage && delegateRoot.imagePath !== "" && imgPreview.status === Image.Ready) ? 110 : 38) : 0
                            radius: 8
                            color: itemHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.03)

                            RowLayout {
                                visible: !delegateRoot.isImage || delegateRoot.imagePath === "" || imgPreview.status !== Image.Ready
                                anchors {
                                    left: parent.left; right: deleteBtn.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10; rightMargin: 6
                                }
                                spacing: 8

                                Text {
                                    text: delegateRoot.isImage ? "image" : "description"
                                    color: Config.accent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: delegateRoot.previewText
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Image {
                                id: imgPreview
                                visible: delegateRoot.isImage && delegateRoot.imagePath !== "" && status === Image.Ready
                                anchors {
                                    top: parent.top; bottom: parent.bottom; left: parent.left; right: deleteBtn.left
                                    margins: 6
                                }
                                source: (delegateRoot.isImage && delegateRoot.imagePath !== "") ? delegateRoot.imagePath : ""
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: 110
                                cache: true
                                asynchronous: true
                            }

                            // Inline Comment: Explicit left-side MouseArea to copy without overlapping the delete button
                            MouseArea {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    right: deleteBtn.left
                                }
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    copyProc.command = ["fish", "-c", "cliphist list | awk 'BEGIN{FS=\"\\t\"} $1 == \"" + itemId + "\" {print $0}' | cliphist decode | wl-copy"]
                                    copyProc.running = false
                                    copyProc.running = true
                                }
                            }

                            // Inline Comment: Per-item delete button with awk tab-field matching
                            Rectangle {
                                id: deleteBtn
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 6
                                }
                                width: 24
                                height: 24
                                radius: 4
                                color: deleteHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "close"
                                    color: deleteHover.hovered ? Config.accent : Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // Inline Comment: Extract exact line by ID column via awk and pipe to cliphist delete
                                        deleteSingleProc.command = ["fish", "-c", "cliphist list | awk -F '\\t' '$1 == \"" + itemId + "\"' | cliphist delete; and rm -f /tmp/cliphist/" + itemId + ".png"]
                                        deleteSingleProc.running = false
                                        deleteSingleProc.running = true
                                    }
                                }

                                HoverHandler { id: deleteHover }
                            }

                            HoverHandler { id: itemHover }
                        }

                        ColumnLayout {
                            id: emptyStateContainer
                            anchors.centerIn: parent
                            spacing: 6
                            visible: clipModel.count === 0 && !fetchProc.running

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "content_paste_off"
                                color: Config.textMuted
                                opacity: 0.5
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 28
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Clipboard history is empty"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                            }
                        }
                    }
                }
            }
        }
    }
}