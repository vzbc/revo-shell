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
    Component.onCompleted: reset(selectedId)

    // Toolbar: back / forward + title
    Item {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34

        Rectangle {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 27
            radius: 8
            color: backArea.containsMouse && pane.canBack ? Theme.toolbarBtnHover : Theme.toolbarBtn

            Text {
                anchors.centerIn: parent
                text: "‹"
                font.pixelSize: 24
                font.weight: Font.Light
                color: pane.canBack ? Theme.toolbarBtnText : Theme.toolbarBtnTextDisabled
            }

            MouseArea {
                id: backArea
                anchors.fill: parent
                enabled: pane.canBack
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: pane.stackIdx--
            }
        }

        Rectangle {
            x: 58
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 27
            radius: 8
            color: fwdArea.containsMouse && pane.canForward ? Theme.toolbarBtnHover : Theme.toolbarBtn

            Text {
                anchors.centerIn: parent
                text: "›"
                font.pixelSize: 24
                font.weight: Font.Light
                color: pane.canForward ? Theme.toolbarBtnText : Theme.toolbarBtnTextDisabled
            }

            MouseArea {
                id: fwdArea
                anchors.fill: parent
                enabled: pane.canForward
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: pane.stackIdx++
            }
        }

        Text {
            x: 114
            anchors.verticalCenter: parent.verticalCenter
            text: pane.currentTitle
            font.family: Theme.fontText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            elide: Text.ElideRight
            width: parent.width - 130
        }
    }

    Flickable {
        id: flick
        anchors.top: toolbar.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: pageLoader.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

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
