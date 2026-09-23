pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    focus: true

    readonly property var entries: ThemeCyclerService.entries
    readonly property int selectedIndex: ThemeCyclerService.selectedIndex

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Tab:
        case Qt.Key_Right:
            ThemeCyclerService.cycleForward();
            event.accepted = true;
            break;
        case Qt.Key_Backtab:
        case Qt.Key_Left:
            ThemeCyclerService.cycleBack();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            ThemeCyclerService.confirm();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            ThemeCyclerService.cancel();
            event.accepted = true;
            break;
        }
    }

    // Confirms the moment the hold-modifier is physically released, in-process
    // and synchronous - same as AppSwitcher.qml. The compositor's own
    // "release=true" keybind (see shell.qml's "themecycler" IpcHandler) also
    // calls confirm(), but that one is a separate spawned `qs ipc call`
    // process racing against any trailing autorepeated "cycle" calls from the
    // same gesture; this one wins that race every time since it's just a Qt
    // key event on the already-focused overlay, so it's the reliable path.
    // Checks both Ctrl and Alt since either can be the configured hold key.
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control || event.key === Qt.Key_Alt) {
            ThemeCyclerService.confirm();
            event.accepted = true;
        }
    }

    readonly property int cardW: Math.round(root.width * 0.16)
    readonly property int cardH: Math.round(cardW * 9 / 16)
    readonly property int cardSpacing: Math.round(root.width * 0.012)

    Text {
        anchors.centerIn: parent
        visible: root.entries.length === 0
        text: I18n.t("themecycler.noneAvailable")
        color: Colors.muted
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: Math.round(root.width * 0.5)
    }

    ListView {
        id: cardList
        visible: root.entries.length > 0
        orientation: ListView.Horizontal
        model: root.entries
        currentIndex: root.selectedIndex

        width: Math.min(root.width - 80, (root.cardW + root.cardSpacing) * root.entries.length)
        height: root.cardH + 40
        anchors.centerIn: parent

        clip: false
        spacing: root.cardSpacing

        preferredHighlightBegin: (width - root.cardW) / 2
        preferredHighlightEnd: (width - root.cardW) / 2 + root.cardW
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 220
        highlightMoveVelocity: -1
        highlight: null

        delegate: Item {
            id: cardDelegate
            required property var modelData
            required property int index

            readonly property bool isSelected: cardDelegate.index === root.selectedIndex
            readonly property string wallpaperPath: Themes.primaryWallpaper(cardDelegate.modelData)
            readonly property var swatchPalette: ThemeState.palette === "dark" ? cardDelegate.modelData.dark : cardDelegate.modelData.light

            width: root.cardW
            height: cardList.height
            scale: cardDelegate.isSelected ? 1.0 : 0.9
            Behavior on scale {
                NumberAnimation {
                    duration: Anim.medium
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: card
                width: root.cardW
                height: root.cardH
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                radius: 12
                color: Colors.surface
                clip: true

                Image {
                    anchors.fill: parent
                    source: cardDelegate.wallpaperPath ? ("file://" + cardDelegate.wallpaperPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 12
                    border.color: cardDelegate.isSelected ? Colors.accent : Colors.outline
                    border.width: cardDelegate.isSelected ? 2 : 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 6
                    spacing: 3
                    Repeater {
                        model: ["background", "primary", "on_background"]
                        Rectangle {
                            required property string modelData
                            width: 10
                            height: 10
                            radius: 3
                            color: cardDelegate.swatchPalette ? (cardDelegate.swatchPalette[modelData] || "#00000000") : "#00000000"
                            border.color: Colors.withAlpha(Colors.bg, 0.5)
                            border.width: 1
                        }
                    }
                }
            }

            Text {
                anchors.top: card.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: cardDelegate.modelData.name
                color: cardDelegate.isSelected ? Colors.text : Colors.textDim
                font.pixelSize: 11
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    ThemeCyclerService.selectedIndex = cardDelegate.index;
                    ThemeCyclerService.confirm();
                }
            }
        }
    }
}
