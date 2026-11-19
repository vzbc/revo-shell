import QtQuick
import QtQuick.Controls
import "Pages.js" as Pages
import "PagesContent.js" as Content

Item {
    id: pane

    property string selectedId: "general"
    property string accountName: ""
    property string accountEmail: ""
    property var stack: ["general"]
    property int stackIdx: 0

    signal signedIn(string email, string name)
    signal signedOut

    readonly property string currentId: (stackIdx >= 0 && stackIdx < stack.length) ? stack[stackIdx] : "general"
    readonly property string currentTitle: {
        if (currentId === "appleId" && accountEmail.length > 0)
            return accountName
        if (Pages.info[currentId] && Pages.info[currentId].title)
            return Pages.info[currentId].title
        if (Content.titles[currentId])
            return Content.titles[currentId]
        return ""
    }
    readonly property bool canBack: stackIdx > 0
    readonly property bool canForward: stackIdx < stack.length - 1

    function reset(id) {
        stack = [id]
        stackIdx = 0
    }

    function open(id) {
        if (id === currentId)
            return
        var s = stack.slice(0, stackIdx + 1)
        s.push(id)
        stack = s
        stackIdx = s.length - 1
    }

    onSelectedIdChanged: reset(selectedId)
    onCurrentIdChanged: flick.contentY = -flick.topMargin
    Component.onCompleted: reset(selectedId)

    signal dragWindow

    // Content scrolls underneath a floating glass toolbar (Tahoe).
    Item {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.toolbarHeight
        z: 5

        // scroll-edge effect: content fades out under the toolbar
        Rectangle {
            anchors.fill: parent
            anchors.bottomMargin: -14
            opacity: flick.contentY + flick.topMargin > 2 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.windowFrame }
                GradientStop { position: 0.62; color: Qt.rgba(Theme.windowFrame.r, Theme.windowFrame.g, Theme.windowFrame.b, 0.92) }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.windowFrame.r, Theme.windowFrame.g, Theme.windowFrame.b, 0) }
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: pane.dragWindow()
            onDoubleClicked: Shell.run("hyprctl dispatch fullscreen 1 >/dev/null 2>&1")
        }

        // back / forward: one glass capsule, two segments
        Rectangle {
            id: navCapsule
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 72
            height: 34
            radius: height / 2
            color: Theme.toolbarBtn
            border.width: 1
            border.color: Theme.glassControlStroke

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.9)
            }

            Repeater {
                model: 2
                delegate: Item {
                    id: seg
                    required property int index
                    readonly property bool enabledSeg: index === 0 ? pane.canBack : pane.canForward
                    x: index * (navCapsule.width / 2)
                    width: navCapsule.width / 2
                    height: navCapsule.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: height / 2
                        color: segArea.pressed && seg.enabledSeg ? Theme.pressedBg
                             : (segArea.containsMouse && seg.enabledSeg ? Theme.hoverBg : "transparent")
                    }

                    Canvas {
                        id: chev
                        anchors.centerIn: parent
                        width: 9
                        height: 15
                        property color ink: seg.enabledSeg ? Theme.toolbarBtnText : Theme.toolbarBtnTextDisabled
                        onInkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = ink
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            if (seg.index === 0) {
                                ctx.moveTo(7, 1.5); ctx.lineTo(1.8, 7.5); ctx.lineTo(7, 13.5)
                            } else {
                                ctx.moveTo(2, 1.5); ctx.lineTo(7.2, 7.5); ctx.lineTo(2, 13.5)
                            }
                            ctx.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }

                    MouseArea {
                        id: segArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: seg.enabledSeg
                        onClicked: seg.index === 0 ? pane.stackIdx-- : pane.stackIdx++
                    }
                }
            }
        }

        Text {
            anchors.left: navCapsule.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: pane.currentTitle
            font.family: Theme.fontDisplay
            font.pixelSize: 15
            font.weight: Font.Bold
            color: Theme.textPrimary
            elide: Text.ElideRight
            width: parent.width - x - 16
        }
    }

    // back/forward with mouse side buttons and Cmd-[ / Cmd-]
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        z: -1
        onClicked: (m) => {
            if (m.button === Qt.BackButton && pane.canBack) pane.stackIdx--
            else if (m.button === Qt.ForwardButton && pane.canForward) pane.stackIdx++
        }
    }
    Shortcut { sequences: ["Ctrl+[", "Alt+Left"]; onActivated: if (pane.canBack) pane.stackIdx-- }
    Shortcut { sequences: ["Ctrl+]", "Alt+Right"]; onActivated: if (pane.canForward) pane.stackIdx++ }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.topMargin: 0
        topMargin: Theme.toolbarHeight + 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: pageLoader.implicitHeight + 28
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { width: 7; topPadding: Theme.toolbarHeight }

        Loader {
            id: pageLoader
            width: flick.width
            source: {
                var f = Pages.files[pane.currentId]
                if (f !== undefined)
                    return Qt.resolvedUrl(f)
                if (Content.content[pane.currentId] !== undefined)
                    return Qt.resolvedUrl("pages/ListPage.qml")
                return Qt.resolvedUrl("PlaceholderPage.qml")
            }

            onStatusChanged: {
                if (status === Loader.Error)
                    console.log("PAGE LOAD ERROR:", source)
            }
        }

        Connections {
            target: pageLoader.item
            enabled: pageLoader.item !== null
            ignoreUnknownSignals: true

            function onNavigate(id) {
                pane.open(id)
            }

            function onSignedIn(email, name) {
                pane.signedIn(email, name)
            }

            function onSignedOut() {
                pane.signedOut()
            }
        }
    }

    Binding {
        target: pageLoader.item
        property: "pageId"
        value: pane.currentId
        when: pageLoader.item !== null && pageLoader.item !== undefined
    }

    Binding {
        target: pageLoader.item
        property: "accountName"
        value: pane.accountName
        when: pageLoader.item !== null && pageLoader.item !== undefined
    }

    Binding {
        target: pageLoader.item
        property: "accountEmail"
        value: pane.accountEmail
        when: pageLoader.item !== null && pageLoader.item !== undefined
    }
}
