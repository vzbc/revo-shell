import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import ".."

Item {
    id: root

    property bool showBrowser: false
    property string currentBrowserPath: "file://" + Quickshell.env("HOME")

    // Reusable Geometric / Square Toggle Switch Component
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    function formatFileUrl(path) {
        if (!path) return ""
        if (path.startsWith("file://")) return path
        if (path.startsWith("/")) return "file://" + path
        return "file://" + Quickshell.env("HOME") + "/" + path
    }

    // Helper to check provider selection state
    function isSourceSelected(src) {
        if (Config.quoteSource === "both") {
            return src === "zenquotes" || src === "jokeapi"
        }
        return Config.quoteSource === src
    }

    // Helper to toggle provider selection state
    function toggleSource(src) {
        let hasZen = isSourceSelected("zenquotes")
        let hasJoke = isSourceSelected("jokeapi")
        let hasRss = isSourceSelected("rss")

        if (src === "zenquotes") hasZen = !hasZen
        if (src === "jokeapi") hasJoke = !hasJoke
        if (src === "rss") hasRss = !hasRss

        if (hasRss && !hasZen && !hasJoke) {
            Config.quoteSource = "rss"
        } else if (hasZen && hasJoke && !hasRss) {
            Config.quoteSource = "both"
        } else if (hasZen && !hasJoke && !hasRss) {
            Config.quoteSource = "zenquotes"
        } else if (hasJoke && !hasZen && !hasRss) {
            Config.quoteSource = "jokeapi"
        } else {
            Config.quoteSource = "none"
        }

        if (Config.fetchOnlineQuotes) {
            Config.triggerQuoteFetch()
        }
    }

    // --- STANDARD MASCOT SETTINGS VIEW ---
    RowLayout {
        anchors.fill: parent
        visible: !root.showBrowser
        spacing: 20

        // LEFT COLUMN: Controls, Toggles & Quotes Manager
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Text {
                text: "MASCOT CONFIGURATION"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
            }

            // TOGGLE: ENABLE DESKTOP MASCOT
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Enable Desktop Mascot"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontBody)
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Show the animated mascot on your desktop"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        wrapMode: Text.WordWrap
                    }
                }

                ToggleSwitch {
                    checked: Config.showMascot !== false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.showMascot = (Config.showMascot === false)
                            if (typeof Config.saveConfig === "function") Config.saveConfig()
                            else if (typeof Config.save === "function") Config.save()
                        }
                    }
                }
            }

            // TOGGLE: AUTO-FETCH ONLINE QUOTES
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Auto-Fetch Online Quotes"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontBody)
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Periodically retrieve quotes from online providers"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        wrapMode: Text.WordWrap
                    }
                }

                ToggleSwitch {
                    checked: Config.fetchOnlineQuotes !== false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.fetchOnlineQuotes = (Config.fetchOnlineQuotes === false)
                            if (typeof Config.saveConfig === "function") Config.saveConfig()
                            else if (typeof Config.save === "function") Config.save()
                        }
                    }
                }
            }

            // MULTI-SELECT PROVIDER SELECTOR
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: Config.fetchOnlineQuotes

                Text {
                    text: "Feed Provider:"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                }

                Rectangle {
                    implicitWidth: 100; implicitHeight: 24
                    radius: Config.cornerRadius / 2
                    color: isSourceSelected("zenquotes") ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Inspirational"
                        color: isSourceSelected("zenquotes") ? Config.bgBase : Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    TapHandler { onTapped: toggleSource("zenquotes") }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                Rectangle {
                    implicitWidth: 60; implicitHeight: 24
                    radius: Config.cornerRadius / 2
                    color: isSourceSelected("jokeapi") ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Jokes"
                        color: isSourceSelected("jokeapi") ? Config.bgBase : Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    TapHandler { onTapped: toggleSource("jokeapi") }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                Rectangle {
                    implicitWidth: 50; implicitHeight: 24
                    radius: Config.cornerRadius / 2
                    color: isSourceSelected("rss") ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "RSS"
                        color: isSourceSelected("rss") ? Config.bgBase : Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    TapHandler { onTapped: toggleSource("rss") }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }

            // RSS FEED URL INPUT FIELD
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: Config.fetchOnlineQuotes && isSourceSelected("rss")

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(0, 0, 0, 0.15)
                    border.color: rssInput.activeFocus ? Config.accent : "transparent"
                    border.width: 1
                    clip: true // Prevents text overflow

                    TextInput {
                        id: rssInput
                        anchors.fill: parent
                        anchors.margins: 6
                        text: Config.rssFeedUrl || ""
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "https://example.com/rss.xml"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            verticalAlignment: Text.AlignVCenter
                            visible: rssInput.text.length === 0 && !rssInput.activeFocus
                            elide: Text.ElideRight
                        }

                        onAccepted: {
                            Config.rssFeedUrl = text.trim()
                            if (Config.fetchOnlineQuotes && Config.rssFeedUrl.length > 0) {
                                Config.triggerQuoteFetch()
                            }
                        }

                        onEditingFinished: {
                            Config.rssFeedUrl = text.trim()
                        }

                        HoverHandler { cursorShape: Qt.IBeamCursor }
                    }
                }
            }

            // BROWSE BUTTON & PATH DISPLAY
            RowLayout {
                spacing: 10
                Layout.fillWidth: true

                Rectangle {
                    implicitWidth: browseText.implicitWidth + 24
                    implicitHeight: 28
                    radius: Config.cornerRadius / 2
                    color: browseHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                    Text {
                        id: browseText
                        anchors.centerIn: parent
                        text: "BROWSE"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        color: browseHover.hovered ? Config.bgBase : Config.textMain
                    }

                    TapHandler { onTapped: root.showBrowser = true }
                    HoverHandler { id: browseHover; cursorShape: Qt.PointingHandCursor }
                }

                Text {
                    text: Config.mascotPath ? Config.mascotPath.replace(/^file:\/\//, "") : "No image selected"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }
            }

            // MANUAL QUOTE INPUT ROW
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(0, 0, 0, 0.15)
                    border.color: manualInput.activeFocus ? Config.accent : "transparent"
                    border.width: 1
                    clip: true // Enforces strictly bounded input area

                    TextInput {
                        id: manualInput
                        anchors.fill: parent
                        anchors.margins: 6
                        text: ""
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Type custom phrase and hit Enter..."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            verticalAlignment: Text.AlignVCenter
                            visible: manualInput.text.length === 0 && !manualInput.activeFocus
                            elide: Text.ElideRight
                        }

                        onAccepted: {
                            let val = text.trim()
                            if (val.length > 0) {
                                Config.addMascotPhrase(val)
                                text = ""
                            }
                        }

                        HoverHandler { cursorShape: Qt.IBeamCursor }
                    }
                }

                Rectangle {
                    implicitWidth: addBtnText.implicitWidth + 16
                    implicitHeight: 28
                    radius: Config.cornerRadius / 2
                    color: addHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                    Text {
                        id: addBtnText
                        anchors.centerIn: parent
                        text: "ADD"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        color: addHover.hovered ? Config.bgBase : Config.textMain
                    }

                    TapHandler {
                        onTapped: {
                            let val = manualInput.text.trim()
                            if (val.length > 0) {
                                Config.addMascotPhrase(val)
                                manualInput.text = ""
                            }
                        }
                    }

                    HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                }
            }

            // PHRASES / QUOTES HEADER WITH NOTIFICATION-STYLE CLEAR ALL BUTTON
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Text {
                    text: "ACTIVE PHRASES LIST"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: clearText.implicitWidth + 12
                    implicitHeight: 24
                    radius: Config.cornerRadius / 2
                    color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    visible: Config.mascotPhrases && Config.mascotPhrases.length > 0

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
                            Config.mascotPhrases = []
                        }
                    }

                    HoverHandler {
                        id: clearHover
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            // LIST OF EXISTING PHRASES
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: Config.cornerRadius / 2
                clip: true

                ListView {
                    id: phrasesListView
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    clip: true
                    model: Config.mascotPhrases || []

                    delegate: Rectangle {
                        width: phrasesListView.width
                        implicitHeight: rowContent.implicitHeight + 8
                        radius: Config.cornerRadius / 2
                        color: phraseHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.15)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: phraseHover }

                        RowLayout {
                            id: rowContent
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            spacing: 8

                            Text {
                                text: modelData
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                color: Config.textMain
                                Layout.fillWidth: true
                                elide: Text.ElideRight // Truncates with "..." when overflowing item width
                                maximumLineCount: 1
                            }

                            // DELETE BUTTON
                            Rectangle {
                                id: deleteBtn
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: Config.cornerRadius / 4
                                color: deleteHover.hovered ? Qt.rgba(255, 255, 0.12) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: deleteHover.hovered ? Config.accent : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontSubhead)
                                    font.bold: true
                                }

                                TapHandler { onTapped: Config.removeMascotPhrase(index) }
                                HoverHandler {
                                    id: deleteHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }
                }
            }
        }

        // RIGHT COLUMN: PREVIEW PANE
        Rectangle {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: Config.cornerRadius
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1
            clip: true

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    var size = 10
                    ctx.fillStyle = "#1e1e1e"
                    ctx.fillRect(0, 0, width, height)
                    ctx.fillStyle = "#2a2a2a"
                    for (var x = 0; x < width; x += size) {
                        for (var y = 0; y < height; y += size) {
                            if ((x / size + y / size) % 2 === 0) {
                                ctx.fillRect(x, y, size, size)
                            }
                        }
                    }
                }
            }

            AnimatedImage {
                id: previewImage
                anchors.fill: parent
                anchors.margins: 12
                fillMode: Image.PreserveAspectFit
                playing: true
                source: root.formatFileUrl(Config.mascotPath)
                visible: previewImage.status === AnimatedImage.Ready

                onStatusChanged: {
                    if (status === AnimatedImage.Ready) {
                        playing = true
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: previewImage.status !== AnimatedImage.Ready
                spacing: 4

                Text {
                    text: "hide_image"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 28
                    color: Config.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No Preview"
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    color: Config.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- INTEGRATED FILE BROWSER VIEW ---
    ColumnLayout {
        anchors.fill: parent
        visible: root.showBrowser
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Text { 
                text: "SELECT MASCOT IMAGE"
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontTitle)
                font.bold: true
                color: Config.textMain
                Layout.fillWidth: true 
            }

            Rectangle {
                implicitWidth: cancelText.implicitWidth + 16
                implicitHeight: 22
                radius: Config.cornerRadius / 2
                color: cancelHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "CANCEL"
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                    color: cancelHover.hovered ? Config.bgBase : Config.textMuted
                }

                TapHandler { onTapped: root.showBrowser = false }
                HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
            }
        }

        Text { 
            text: root.currentBrowserPath.replace("file://", "")
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            color: Config.textMuted
            elide: Text.ElideLeft
            Layout.fillWidth: true 
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.15)
            radius: Config.cornerRadius / 2
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1
            clip: true

            ListView {
                id: fileListView
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2
                clip: true

                model: FolderListModel {
                    folder: root.currentBrowserPath
                    showDirsFirst: true
                    showDotAndDotDot: true
                    nameFilters: ["*.gif", "*.png", "*.jpg", "*.jpeg"] 
                }

                delegate: Rectangle {
                    width: fileListView.width
                    implicitHeight: fileName === "." ? 0 : 34
                    visible: fileName !== "."
                    radius: Config.cornerRadius / 2
                    color: fileHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                    RowLayout {
                        spacing: 8
                        anchors.fill: parent
                        anchors.leftMargin: 8

                        Text { 
                            text: fileIsDir ? "folder" : "image"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.accent 
                        }

                        Text { 
                            text: fileName
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            color: Config.textMain
                            Layout.fillWidth: true
                            elide: Text.ElideRight 
                        }
                    }

                    TapHandler {
                        onTapped: {
                            if (fileIsDir) {
                                root.currentBrowserPath = fileUrl.toString()
                            } else {
                                let urlString = fileUrl.toString()
                                let parsedPath = urlString.startsWith("file:///") ? urlString.substring(7) : urlString.replace("file://", "")

                                Config.mascotPath = parsedPath
                                root.showBrowser = false
                            }
                        }
                    }

                    HoverHandler { id: fileHover; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}