import QtQuick
import ".."

Item {
    id: prev

    property string position: "bottom"
    readonly property bool vertical: position === "left" || position === "right"
    property int iconSize: 40
    property bool magnify: true
    property bool autohide: false
    property bool indicators: true
    property bool animateOpen: true

    readonly property bool hideDock: autohide && !reveal.hovered
    readonly property int baseSize: Math.round(24 + (Math.max(16, Math.min(128, iconSize)) - 16) / 112 * 20)
    readonly property int magnSize: magnify ? Math.round(baseSize * 0.85) : 0

    // real macOS dock artwork, resolved through the active Icon & Widget Style
    readonly property string iconsUrl: "file://" + Shell.shellDir + "/assets/icons/"
    readonly property string iconStyle: String(Shell.uget("iconStyle", "Default"))
    readonly property string iconTint: String(Shell.uget("iconTint", "#8E8E93"))
    readonly property string tintSlug: iconTint.replace("#", "").toLowerCase()

    function srcFor(name) {
        if (iconStyle === "Tinted" && tintSlug.length > 0)
            return iconsUrl + "tinted/" + tintSlug + "/" + name
        if (iconStyle === "Dark")
            return iconsUrl + "dark/" + name
        return iconsUrl + name
    }

    implicitHeight: vertical ? 210 : 150
    width: parent ? parent.width : 640
    clip: true

    readonly property real trayY: vertical
        ? (height - tray.height) / 2
        : (hideDock ? height - 26 : height - tray.height - 12)

    Rectangle {
        id: backdrop
        anchors.fill: parent
        radius: 12
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.accent }
            GradientStop { position: 0.55; color: Theme.dark ? "#3a3f52" : "#9fb0d0" }
            GradientStop { position: 1.0; color: Theme.dark ? "#101014" : "#5b6c8c" }
        }
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.12)

        // menu bar strip hint
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12
            color: Theme.dark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(1, 1, 1, 0.35)
        }
    }

    Item {
        id: tray
        width: vertical ? prev.baseSize + 26 : dockRow.width + 30
        height: vertical ? dockRow.height + 30 : prev.baseSize + 34

        anchors.horizontalCenter: vertical ? undefined : prev.horizontalCenter
        anchors.left: vertical && prev.position === "left" ? backdrop.left : undefined
        anchors.right: vertical && prev.position === "right" ? backdrop.right : undefined
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        y: prev.trayY
        Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: vertical ? width * 0.3 : 22
            color: Theme.dark ? Qt.rgba(0.05, 0.05, 0.07, 0.62) : Qt.rgba(1, 1, 1, 0.62)
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.14)
        }

        HoverHandler { id: reveal }
        HoverHandler { id: rvh }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 7

            Repeater {
                model: [
                    { f: "Finder.png" },
                    { f: "Safari.png" },
                    { f: "Telegram.png" },
                    { f: "Steam.png" },
                    { f: "Photos.png" },
                    { f: "im-message.png" },
                    { f: "Calendar.png" }
                ]

                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property int idx: index
                    readonly property real boost: {
                        if (!prev.magnify || !rvh.hovered)
                            return 0
                        var reach = prev.baseSize + prev.magnSize + 30
                        var c = prev.vertical
                            ? (slot.y + slot.height / 2) + dockRow.y
                            : (slot.x + slot.width / 2) + dockRow.x
                        var p = prev.vertical ? rvh.point.position.y : rvh.point.position.x
                        var d = Math.abs(p - c)
                        if (d >= reach)
                            return 0
                        return Math.cos(d / reach * Math.PI / 2)
                    }
                    property real bounceY: 0

                    width: prev.baseSize + Math.round(prev.magnSize * boost)
                    height: width

                    transform: Translate { y: slot.bounceY }

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                    Rectangle {
                        anchors.fill: parent
                        radius: width * 0.27
                        color: "transparent"

                        Image {
                            id: slotIcon
                            anchors.fill: parent
                            anchors.margins: Math.round(parent.width * 0.04)
                            property string baseSrc: prev.iconsUrl + slot.modelData.f
                            property string styleSrc: prev.srcFor(slot.modelData.f)
                            property string effSrc: styleSrc
                            source: effSrc
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            mipmap: true
                            smooth: true
                            opacity: prev.iconStyle === "Clear" ? 0.55 : 1
                            onStatusChanged: {
                                if (status === Image.Error && effSrc !== baseSrc)
                                    effSrc = baseSrc
                            }
                        }
                    }

                    Rectangle {
                        visible: prev.indicators
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: prev.vertical ? undefined : parent.bottom
                        anchors.left: prev.vertical && prev.position === "left" ? parent.left : undefined
                        anchors.right: prev.vertical && prev.position === "right" ? parent.right : undefined
                        anchors.bottomMargin: -8
                        anchors.leftMargin: -8
                        anchors.rightMargin: -8
                        width: 4
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.92)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (prev.animateOpen) bounceAnim.restart()
                    }

                    SequentialAnimation {
                        id: bounceAnim
                        NumberAnimation { target: slot; property: "bounceY"; to: -16; duration: 170; easing.type: Easing.OutQuad }
                        NumberAnimation { target: slot; property: "bounceY"; to: 0; duration: 420; easing.type: Easing.OutBounce }
                    }
                }
            }

            Rectangle {
                visible: !prev.vertical
                width: 1
                height: prev.baseSize + 6
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(1, 1, 1, 0.30)
            }
        }
    }
}
