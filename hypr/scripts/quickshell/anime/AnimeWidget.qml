import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    Caching { id: paths }
    readonly property string cacheDir: paths.getCacheDir("anime")
    readonly property string apiBase: "http://127.0.0.1:17390"

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val);
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color crust: _theme.crust
    readonly property color mantle: _theme.mantle
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color red: _theme.red || "#f38ba8"

    property string currentView: "search"
    property string animeMode: "sub"
    property string animeQuality: "best"
    property bool isSearching: searchInput.text.trim() !== ""
    property bool isSearchingNetwork: false
    property bool isSearchMode: window.isSearching
    property string selectedId: ""
    property string selectedTitle: ""
    property string selectedThumbnail: ""
    property string selectedNth: "1"
    property bool isLoadingSeries: false
    property bool isPlaying: false

    property var currentFetchResults: []

    // --- ROOT-LEVEL PROCESSES (Quickshell can't inline Process{...} in JS) ---
    Process {
        id: apiProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                apiProc.running = false
                if (typeof window._apiCb === "function") {
                    let fn = window._apiCb
                    window._apiCb = null
                    let data = this.text.trim()
                    if (data !== "" && data !== "null") {
                        try { fn(JSON.parse(data)) }
                        catch(e) { fn(null) }
                    } else { fn(null) }
                }
            }
        }
    }
    property var _apiCb: null

    Process {
        id: hcProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                hcProc.running = false
                let data = this.text.trim()
                if (data !== "" && data !== "null") {
                    if (typeof window._hcCb === "function") {
                        let fn = window._hcCb; window._hcCb = null
                        fn(true)
                    }
                } else {
                    window._hcTries++
                    if (window._hcTries >= 6) {
                        if (typeof window._hcCb === "function") {
                            let fn = window._hcCb; window._hcCb = null
                            fn(false)
                        }
                    } else {
                        hcTimer.start()
                    }
                }
            }
        }
    }
    property var _hcCb: null
    property int _hcTries: 0

    Timer {
        id: hcTimer
        interval: 500; repeat: false
        onTriggered: {
            hcProc.running = false
            hcProc.command = ["bash", "-c",
                "curl -s --max-time 2 '" + window.apiBase + "/api/version' 2>/dev/null || echo 'null'"
            ]
            hcProc.running = true
        }
    }

    Process {
        id: playProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                playProc.running = false
                playTimeout.stop()
                window.isPlaying = false
                let data = this.text.trim()
                if (data !== "" && data !== "null") {
                    try {
                        let j = JSON.parse(data)
                        if (j && j.ok) {
                            showToast(j.message || "Playing episode " + playProc._ep)
                        } else {
                            showToast(j && j.error ? j.error : "Failed to play")
                        }
                    } catch(e) {
                        showToast("Play failed")
                    }
                } else {
                    showToast("Couldn't reach ani-gui server")
                }
            }
        }
        property string _ep: ""
    }

    Timer {
        id: playTimeout
        interval: 30000; repeat: false
        onTriggered: {
            if (window.isPlaying) {
                window.isPlaying = false
                showToast("Play request timed out")
                playProc.running = false
            }
        }
    }

    Timer {
        id: safetyLoadingTimer
        interval: 12000
        running: window.isSearchingNetwork
        repeat: false
        onTriggered: { window.isSearchingNetwork = false }
    }

    Timer {
        id: searchDebounceTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (searchInput.text.trim() !== "") doSearch(searchInput.text)
        }
    }

    property real introPhase: 0
    NumberAnimation on introPhase {
        id: introPhaseAnim
        from: 0; to: 1; duration: 800; easing.type: Easing.OutQuart; running: true
    }

    Timer {
        id: focusTimer
        interval: 50; running: true; repeat: false
        onTriggered: {
            if (window.currentView === "search") searchInput.forceActiveFocus()
            else window.forceActiveFocus()
        }
    }

    Timer {
        id: scrollToTopTimer
        interval: 80; running: false; repeat: false
        onTriggered: { searchGrid.positionViewAtBeginning() }
    }

    Keys.onPressed: (event) => {
        if (window.currentView === "series") {
            if (event.key === Qt.Key_Escape) {
                window.currentView = "search"
                searchInput.forceActiveFocus()
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                if (epList.currentIndex < epList.count - 1) epList.currentIndex++; event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                if (epList.currentIndex > 0) epList.currentIndex--; event.accepted = true
            } else if (event.key === Qt.Key_Return) {
                let ep = episodeModel.get(epList.currentIndex)
                if (ep) playEpisode(ep.epNum)
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Escape) {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"])
            event.accepted = true
        }
    }

    property bool isKeyboardNav: false
    Timer { id: keyboardNavTimer; interval: 500; repeat: false; onTriggered: window.isKeyboardNav = false }

    ListModel { id: searchResults }
    ListModel { id: episodeModel }

    // --- API ---
    function apiGet(path, cb) {
        apiProc.running = false
        window._apiCb = cb
        apiProc.command = ["bash", "-c",
            "curl -s --max-time 15 '" + window.apiBase + path.replace(/'/g, "'\\''") + "' 2>/dev/null || echo 'null'"
        ]
        apiProc.running = true
    }

    function ensureAnimeGui(cb) {
        window._hcCb = cb
        window._hcTries = 0
        hcTimer.start()
    }

    // --- SEARCH ---
    function doSearch(query) {
        if (query.trim() === "") { searchResults.clear(); window.isSearchingNetwork = false; return }
        window.isSearchingNetwork = true
        searchResults.clear()
        let q = encodeURIComponent(query.trim())
        apiGet("/api/search?q=" + q + "&mode=" + window.animeMode, function(data) {
            window.isSearchingNetwork = false
            if (data && data.results) {
                window.currentFetchResults = data.results
                searchResults.clear()
                for (let i = 0; i < data.results.length; i++) {
                    let r = data.results[i]
                    searchResults.append({
                        id: r.id,
                        title: r.name,
                        thumbnail: r.thumbnail || "",
                        sub: r.sub || 0,
                        dub: r.dub || 0,
                        count: r.count || 0,
                        nth: String(r.nth || (i + 1))
                    })
                }
            }
        })
    }

    // --- EPISODES ---
    function loadSeriesDetails(id, title, thumbnail, nth) {
        window.selectedId = id
        window.selectedTitle = title
        window.selectedThumbnail = thumbnail
        window.selectedNth = nth || "1"
        window.currentView = "series"
        window.forceActiveFocus()
        window.isLoadingSeries = true
        episodeModel.clear()

        apiGet("/api/episodes?id=" + encodeURIComponent(id) + "&mode=" + window.animeMode, function(data) {
            window.isLoadingSeries = false
            if (data && data.episodes) {
                for (let i = 0; i < data.episodes.length; i++) {
                    episodeModel.append({ epNum: data.episodes[i], epTitle: "Episode " + data.episodes[i] })
                }
                if (epList.count > 0) epList.currentIndex = 0
            }
        })
    }

    // --- PLAY ---
    function playEpisode(ep) {
        if (window.isPlaying) return
        window.isPlaying = true
        showToast("Starting episode " + ep + "...")

        ensureAnimeGui(function(ready) {
            if (!ready) {
                showToast("ani-gui not running — press Super+J again")
                window.isPlaying = false
                return
            }

            let payload = JSON.stringify({
                query: window.selectedTitle,
                nth: parseInt(window.selectedNth) || 1,
                ep: parseInt(ep) || 1,
                quality: window.animeQuality,
                mode: window.animeMode,
                thumbnail: window.selectedThumbnail,
                title: window.selectedTitle,
                id: window.selectedId
            })

            let escaped = payload.replace(/'/g, "'\\''")
            let cmd = "curl -s --max-time 60 -X POST -H 'Content-Type: application/json' -d '" + escaped + "' '" + window.apiBase + "/api/play' 2>/dev/null; echo"

            playProc.running = false
            playProc._ep = String(ep)
            playProc.command = ["bash", "-c", cmd]
            playTimeout.stop()
            playTimeout.start()
            playProc.running = true
        })
    }

    // --- TOAST ---
    property string toastText: ""
    property bool toastVisible: false
    Timer { id: toastTimer; interval: 3000; repeat: false; onTriggered: window.toastVisible = false }

    function showToast(msg) {
        window.toastText = msg
        window.toastVisible = true
        toastTimer.restart()
    }

    // --- SORT ---
    property string filterSort: "Default"

    function applyFilters() {
        let items = window.currentFetchResults.slice()
        let mode = window.filterSort
        if (mode === "Title (A-Z)") items.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        else if (mode === "Title (Z-A)") items.sort((a, b) => (b.name || "").localeCompare(a.name || ""))
        searchResults.clear()
        for (let i = 0; i < items.length; i++) {
            let r = items[i]
            searchResults.append({
                id: r.id,
                title: r.name,
                thumbnail: r.thumbnail || "",
                sub: r.sub || 0,
                dub: r.dub || 0,
                count: r.count || 0,
                nth: String(r.nth || (i + 1))
            })
        }
    }

    // --- SHARED STYLES ---
    component CustomComboBox: ComboBox {
        id: control
        font.family: "JetBrains Mono"; font.pixelSize: window.s(14)
        delegate: ItemDelegate {
            width: control.width; height: window.s(36)
            contentItem: Text { text: modelData || model.name; color: window.text; font: control.font; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: control.highlightedIndex === index ? window.surface1 : "transparent"; radius: window.s(10) }
        }
        indicator: Canvas {
            id: canvas
            x: control.width - width - control.rightPadding; y: control.topPadding + (control.availableHeight - height) / 2
            width: 12; height: 8; contextType: "2d"
            Connections { target: control; function onPressedChanged() { canvas.requestPaint() } }
            onPaint: { var ctx = canvas.getContext("2d"); ctx.reset(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height); ctx.fillStyle = window.subtext0; ctx.fill() }
        }
        contentItem: Text { leftPadding: window.s(10); rightPadding: control.indicator.width + control.spacing; text: control.currentText; font: control.font; color: window.text; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { implicitWidth: window.s(180); implicitHeight: window.s(36); color: window.surface0; border.color: control.activeFocus ? window.surface2 : window.surface1; border.width: control.visualFocus ? 2 : 1; radius: window.s(10) }
        popup: Popup {
            y: control.height + window.s(4); width: control.width; implicitHeight: contentItem.implicitHeight; padding: window.s(4)
            contentItem: ListView { clip: true; implicitHeight: contentHeight; model: control.popup.visible ? control.delegateModel : null; currentIndex: control.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator { } }
            background: Rectangle { color: window.crust; border.color: window.surface1; radius: window.s(14) }
        }
    }

    // --- UI LAYOUT ---
    Rectangle {
        id: mainBg
        width: parent.width; height: parent.height
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        radius: window.s(14)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.95)
        border.color: Qt.rgba(window.text.r, window.text.g, window.text.b, 0.08)
        border.width: 1
        clip: true
        transform: Translate { y: (1 - window.introPhase) * window.s(50) }
        opacity: window.introPhase
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            visible: window.currentView === "search"
            Rectangle {
                Layout.alignment: Qt.AlignTop; Layout.fillWidth: true; Layout.preferredHeight: window.s(120); color: "transparent"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: window.s(15); spacing: window.s(10)
                    RowLayout {
                        Layout.fillWidth: true; spacing: window.s(15)
                        Rectangle {
                            Layout.preferredWidth: window.s(200); Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0
                            Rectangle {
                                id: modeHighlight
                                width: parent.width / 2 - window.s(4); height: parent.height - window.s(8)
                                y: window.s(4); radius: window.s(8); color: window.animeMode === "sub" ? window.mauve : window.blue; z: 0
                                property real targetX: window.animeMode === "sub" ? window.s(4) : (parent.width / 2)
                                property real actualX: targetX
                                Behavior on actualX { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                                x: actualX
                            }
                            RowLayout {
                                anchors.fill: parent; spacing: 0
                                MouseArea {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: { window.animeMode = "sub"; if (searchInput.text !== "") doSearch(searchInput.text) }
                                    Text { anchors.centerIn: parent; text: "Sub"; font.family: "JetBrains Mono"; font.weight: window.animeMode === "sub" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.animeMode === "sub" ? window.crust : window.text }
                                }
                                MouseArea {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: { window.animeMode = "dub"; if (searchInput.text !== "") doSearch(searchInput.text) }
                                    Text { anchors.centerIn: parent; text: "Dub"; font.family: "JetBrains Mono"; font.weight: window.animeMode === "dub" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.animeMode === "dub" ? window.crust : window.text }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: window.s(160); Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0
                            RowLayout {
                                anchors.fill: parent; spacing: 0
                                MouseArea {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: { window.animeQuality = "best"; if (searchInput.text !== "") doSearch(searchInput.text) }
                                    Text { anchors.centerIn: parent; text: "Best"; font.family: "JetBrains Mono"; font.weight: window.animeQuality === "best" ? Font.Bold : Font.Medium; font.pixelSize: window.s(12); color: window.animeQuality === "best" ? window.crust : window.text }
                                }
                                MouseArea {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: { window.animeQuality = "1080"; if (searchInput.text !== "") doSearch(searchInput.text) }
                                    Text { anchors.centerIn: parent; text: "1080p"; font.family: "JetBrains Mono"; font.weight: window.animeQuality === "1080" ? Font.Bold : Font.Medium; font.pixelSize: window.s(12); color: window.animeQuality === "1080" ? window.crust : window.text }
                                }
                                MouseArea {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: { window.animeQuality = "720"; if (searchInput.text !== "") doSearch(searchInput.text) }
                                    Text { anchors.centerIn: parent; text: "720p"; font.family: "JetBrains Mono"; font.weight: window.animeQuality === "720" ? Font.Bold : Font.Medium; font.pixelSize: window.s(12); color: window.animeQuality === "720" ? window.crust : window.text }
                                }
                            }
                        }
                        CustomComboBox {
                            id: filterSelector
                            Layout.preferredWidth: window.s(160)
                            model: ["Default", "Title (A-Z)", "Title (Z-A)"]
                            onActivated: {
                                window.filterSort = currentText
                                applyFilters()
                            }
                        }
                    }
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true; Layout.preferredHeight: window.s(42)
                        background: Rectangle {
                            color: searchInput.activeFocus ? Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6) : window.surface0
                            radius: window.s(10); border.color: searchInput.activeFocus ? window.surface2 : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(15); leftPadding: window.s(15)
                        placeholderText: "Search anime..."
                        placeholderTextColor: window.subtext0; verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: {
                            if (text.trim() === "") { searchResults.clear(); window.isSearchingNetwork = false; searchDebounceTimer.stop() }
                            else searchDebounceTimer.restart()
                        }
                        Keys.onRightPressed: {
                            window.isKeyboardNav = true; keyboardNavTimer.restart()
                            let g = searchGrid
                            if (g && g.count > 0 && g.currentIndex < g.count - 1) g.currentIndex++
                            event.accepted = true
                        }
                        Keys.onLeftPressed: {
                            window.isKeyboardNav = true; keyboardNavTimer.restart()
                            let g = searchGrid
                            if (g && g.count > 0 && g.currentIndex > 0) g.currentIndex--
                            event.accepted = true
                        }
                        Keys.onDownPressed: {
                            window.isKeyboardNav = true; keyboardNavTimer.restart()
                            let g = searchGrid
                            if (g && g.count > 0) {
                                let columns = Math.max(1, Math.floor(g.width / g.cellWidth))
                                if (g.currentIndex + columns < g.count) g.currentIndex += columns
                            }
                            event.accepted = true
                        }
                        Keys.onUpPressed: {
                            window.isKeyboardNav = true; keyboardNavTimer.restart()
                            let g = searchGrid
                            if (g && g.count > 0) {
                                let columns = Math.max(1, Math.floor(g.width / g.cellWidth))
                                if (g.currentIndex - columns >= 0) g.currentIndex -= columns
                            }
                            event.accepted = true
                        }
                        Keys.onReturnPressed: {
                            if (text.trim() !== "" && searchResults.count === 0 && !window.isSearchingNetwork) {
                                doSearch(text)
                            } else if (window.isKeyboardNav) {
                                let g = searchGrid
                                if (g && g.count > 0 && g.currentIndex >= 0 && g.currentIndex < g.count) {
                                    let item = g.model.get(g.currentIndex)
                                    if (item) loadSeriesDetails(item.id, item.title, item.thumbnail, item.nth)
                                }
                            }
                            event.accepted = true
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.8)
                    visible: window.isSearchingNetwork
                    z: 10
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: window.s(15)
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: window.s(34); height: window.s(34)
                            property real spinAngle: 0
                            NumberAnimation on spinAngle {
                                from: 0; to: 360; duration: 900
                                loops: Animation.Infinite; running: true
                                easing.type: Easing.Linear
                            }
                            Canvas {
                                anchors.fill: parent
                                property real angle: parent.spinAngle
                                onAngleChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    var cx = width / 2, cy = height / 2, r = width / 2 - 3
                                    var startRad = (parent.spinAngle - 90) * Math.PI / 180
                                    var endRad = startRad + 1.7 * Math.PI
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, startRad, endRad)
                                    ctx.strokeStyle = window.mauve
                                    ctx.lineWidth = 3
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                            }
                        }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Searching..."; color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(14) }
                    }
                }
                Item {
                    anchors.fill: parent; anchors.margins: window.s(15); visible: !window.isSearchingNetwork
                    Component {
                        id: gridHighlightComp
                        Item {
                            z: 0
                            Rectangle {
                                color: window.surface0; border.color: window.surface1; border.width: 1; radius: window.s(10)
                                property real actX: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.x + window.s(5) : 0
                                property real actY: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.y + window.s(5) : 0
                                x: actX; y: actY; width: parent.GridView.view.cellWidth - window.s(10); height: parent.GridView.view.cellHeight - window.s(10)
                                Behavior on actX { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                                Behavior on actY { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                                opacity: parent.GridView.view.count > 0 && parent.GridView.view.currentIndex >= 0 ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                    Component {
                        id: mediaGridDelegate
                        Item {
                            width: GridView.view.cellWidth; height: GridView.view.cellHeight; z: 1
                            Rectangle {
                                anchors.fill: parent; anchors.margins: window.s(5); radius: window.s(10); color: "transparent"
                                property bool isActive: index === parent.parent.GridView.view.currentIndex
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(8)
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: window.s(8); color: window.crust; clip: true
                                        scale: parent.parent.isActive && window.isKeyboardNav ? 1.03 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                        Image {
                                            id: gridImage
                                            anchors.fill: parent
                                            source: model.thumbnail !== "" ? model.thumbnail : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true; smooth: true; cache: true
                                            visible: status === Image.Ready
                                        }
                                        Rectangle {
                                            anchors.fill: parent; color: window.surface0
                                            visible: model.thumbnail === "" || gridImage.status === Image.Error || gridImage.status === Image.Loading
                                            radius: window.s(8)
                                            property bool isLoading: model.thumbnail !== "" && gridImage.status === Image.Loading
                                            Rectangle {
                                                anchors.fill: parent; radius: window.s(8); color: "transparent"
                                                visible: parent.isLoading
                                                Rectangle {
                                                    width: parent.width * 0.4; height: parent.height
                                                    color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.4)
                                                    property real shimX: -parent.parent.width
                                                    x: shimX
                                                    NumberAnimation on shimX {
                                                        from: -parent.parent.width
                                                        to: parent.parent.width * 1.5
                                                        duration: 1200; loops: Animation.Infinite
                                                        running: parent.parent.parent.isLoading
                                                        easing.type: Easing.InOutSine
                                                    }
                                                }
                                            }
                                            Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: model.title || "Unknown"; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; visible: !parent.isLoading }
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: window.s(8)
                                            color: window.mauve
                                            opacity: parent.parent.parent.isActive ? 0.2 : 0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true; text: model.title; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); font.weight: Font.Bold
                                        color: parent.parent.isActive ? window.text : window.subtext0
                                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; lineHeight: 1.1; horizontalAlignment: Text.AlignHCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "EP: " + (model.count || "?")
                                        font.family: "JetBrains Mono"; font.pixelSize: window.s(11); color: window.surface2; horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: { window.isKeyboardNav = false; parent.parent.GridView.view.currentIndex = index }
                                    onClicked: {
                                        loadSeriesDetails(model.id, model.title, model.thumbnail, model.nth)
                                    }
                                }
                            }
                        }
                    }
                    GridView {
                        id: searchGrid
                        anchors.fill: parent
                        model: searchResults; cellWidth: Math.floor(width / 5); cellHeight: cellWidth * 1.5 + window.s(60)
                        boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }
                        Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                        add: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuart } NumberAnimation { property: "y"; from: y + window.s(30); duration: 500; easing.type: Easing.OutQuart } NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 500; easing.type: Easing.OutBack } } }
                        highlight: gridHighlightComp; delegate: mediaGridDelegate
                    }
                }
            }
        }
        // ==========================================
        // SERIES VIEW
        // ==========================================
        RowLayout {
            anchors.fill: parent; anchors.margins: window.s(20); spacing: window.s(25)
            visible: window.currentView === "series"
            ColumnLayout {
                Layout.preferredWidth: window.s(220); Layout.minimumWidth: window.s(220); Layout.maximumWidth: window.s(220)
                Layout.fillHeight: true; spacing: window.s(12)
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(300); radius: window.s(14); color: window.crust; clip: true
                    Image {
                        anchors.fill: parent
                        source: window.selectedThumbnail !== "" ? window.selectedThumbnail : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; smooth: true; cache: true
                        sourceSize.width: window.s(440); sourceSize.height: window.s(600)
                        visible: status === Image.Ready
                    }
                    Rectangle {
                        anchors.fill: parent; color: window.surface0; radius: window.s(14)
                        visible: window.selectedThumbnail === "" || parent.children[0].status === Image.Error || parent.children[0].status === Image.Loading
                        Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: window.selectedTitle; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
                    }
                }
                Text {
                    Layout.fillWidth: true; text: window.selectedTitle
                    font.family: "JetBrains Mono"; font.pixelSize: window.s(16); font.weight: Font.Bold
                    color: window.text; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 3; elide: Text.ElideRight
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(10)
                    property bool isHovered: backMouse.containsMouse
                    color: isHovered ? window.surface2 : window.surface1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text { anchors.centerIn: parent; text: "← Back"; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); font.weight: Font.Medium; color: window.text }
                    MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { window.currentView = "search"; searchInput.forceActiveFocus() } }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0
                    RowLayout {
                        anchors.fill: parent; spacing: 0
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeMode = "sub"
                            Text { anchors.centerIn: parent; text: "Sub"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: window.animeMode === "sub" ? Font.Bold : Font.Medium; color: window.animeMode === "sub" ? window.mauve : window.text }
                        }
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeMode = "dub"
                            Text { anchors.centerIn: parent; text: "Dub"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: window.animeMode === "dub" ? Font.Bold : Font.Medium; color: window.animeMode === "dub" ? window.blue : window.text }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0
                    RowLayout {
                        anchors.fill: parent; spacing: 0
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeQuality = "best"
                            Text { anchors.centerIn: parent; text: "Best"; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); font.weight: window.animeQuality === "best" ? Font.Bold : Font.Medium; color: window.animeQuality === "best" ? window.green : window.text }
                        }
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeQuality = "1080"
                            Text { anchors.centerIn: parent; text: "1080p"; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); font.weight: window.animeQuality === "1080" ? Font.Bold : Font.Medium; color: window.animeQuality === "1080" ? window.green : window.text }
                        }
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeQuality = "720"
                            Text { anchors.centerIn: parent; text: "720p"; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); font.weight: window.animeQuality === "720" ? Font.Bold : Font.Medium; color: window.animeQuality === "720" ? window.green : window.text }
                        }
                        MouseArea {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            onClicked: window.animeQuality = "480"
                            Text { anchors.centerIn: parent; text: "480p"; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); font.weight: window.animeQuality === "480" ? Font.Bold : Font.Medium; color: window.animeQuality === "480" ? window.green : window.text }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: window.s(12)
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(44)
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Episodes (" + window.animeMode + ")"
                        font.family: "JetBrains Mono"; font.pixelSize: window.s(15); font.weight: Font.Bold
                        color: window.text
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ListView {
                        id: epList
                        anchors.fill: parent
                        model: episodeModel; spacing: window.s(6); clip: true
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2; implicitWidth: window.s(4) } }
                        Text {
                            anchors.centerIn: parent
                            visible: window.isLoadingSeries
                            text: "Fetching episodes..."
                            color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
                        }
                        highlight: Rectangle {
                            color: window.surface0; border.color: window.surface2; border.width: 1; radius: window.s(10); z: 0
                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                        }
                        highlightFollowsCurrentItem: true
                        highlightMoveVelocity: -1
                        delegate: Item {
                            id: epDelegate
                            width: ListView.view.width; height: window.s(58); z: 1
                            property bool isCurrent: ListView.isCurrentItem
                            property bool isHovered: false
                            Rectangle {
                                anchors.fill: parent; radius: window.s(10)
                                color: epDelegate.isHovered || isCurrent ? window.surface0 : "transparent"
                                border.color: epDelegate.isHovered || isCurrent ? window.surface2 : "transparent"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(12)
                                    Rectangle {
                                        Layout.preferredWidth: window.s(36); Layout.preferredHeight: window.s(36)
                                        radius: window.s(8)
                                        color: isCurrent || epDelegate.isHovered ? window.mauve : window.surface1
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: model.epNum
                                            font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: Font.Bold
                                            color: isCurrent || epDelegate.isHovered ? window.crust : window.subtext0
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }
                                    Column {
                                        Layout.fillWidth: true; spacing: window.s(2)
                                        Text {
                                            width: parent.width
                                            text: model.epTitle
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: window.s(13)
                                            color: window.text
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Rectangle {
                                        id: playBtn
                                        Layout.preferredWidth: window.s(60); Layout.preferredHeight: window.s(30); radius: window.s(8)
                                        color: (playBtnHover.hovered || isCurrent) && !window.isPlaying ? window.green : window.surface1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: window.isPlaying ? "..." : "▶ Play"
                                            font.family: "JetBrains Mono"; font.pixelSize: window.s(11); font.weight: Font.Bold
                                            color: (playBtnHover.hovered || isCurrent) && !window.isPlaying ? window.crust : window.text
                                        }
                                        HoverHandler { id: playBtnHover }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: epDelegate.isHovered = true
                                    onExited: epDelegate.isHovered = false
                                    onClicked: mouse => {
                                        let pt = mapToItem(playBtn, mouse.x, mouse.y)
                                        if (pt.x >= 0 && pt.x <= playBtn.width && pt.y >= 0 && pt.y <= playBtn.height) {
                                            epList.currentIndex = index
                                            playEpisode(model.epNum)
                                        } else {
                                            epList.currentIndex = index
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: window.s(20)
        width: Math.max(toastLabel.width + window.s(40), window.s(200))
        height: window.s(44)
        radius: window.s(10)
        color: Qt.rgba(window.crust.r, window.crust.g, window.crust.b, 0.95)
        border.color: window.surface2; border.width: 1
        opacity: window.toastVisible ? 1 : 0
        visible: opacity > 0
        z: 200
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: window.toastText
            font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
            color: window.green
        }
    }
}
