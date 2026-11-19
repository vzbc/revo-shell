import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// Type-to-Siri bubble (macOS 26/27, SiriUI "Siri - 800 x 300" reference):
// a frosted capsule under the menu bar on the right with a shifting
// pastel glow (pink / peach / lavender / sky), Siri glyph on the left, mic on
// the right, and a rounded answer card underneath.
PanelWindow {
    id: bubble

    property bool active: false
    property string state: "idle"           // idle | listening | thinking | speaking
    property string heard: ""
    property string answer: ""
    property string error: ""
    signal submitted(string text)
    signal micPressed()
    signal dismissRequested()

    readonly property int pillW: 440
    readonly property int pillH: 44
    readonly property bool hasCard: heard !== "" || answer !== "" || error !== "" || state === "thinking"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "macos:siri"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 34; right: 12 }
    implicitWidth: pillW + 40
    implicitHeight: 40 + pillH + 12 + (hasCard ? card.implicitHeight : 0) + 20
    color: "transparent"
    visible: active || content.opacity > 0.01
    mask: Region { item: content }

    onActiveChanged: {
        if (active) {
            input.text = ""
            input.forceActiveFocus()
        }
    }

    Item {
        id: content
        x: 20; y: 20
        width: bubble.pillW
        height: bubble.pillH + (bubble.hasCard ? 12 + card.implicitHeight : 0)
        opacity: bubble.active ? 1 : 0
        scale: 0.96 + 0.04 * opacity
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // ---------------------------------------------------- glow halo
        Item {
            id: halo
            anchors.fill: pill
            anchors.margins: -10
            property real phase: 0
            NumberAnimation on phase { from: 0; to: 1; duration: 6000; loops: Animation.Infinite; running: bubble.visible }
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 24 }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 8; height: parent.height - 8
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.hsva((0.95 + halo.phase) % 1, 0.45, 1, 0.85) }
                    GradientStop { position: 0.35; color: Qt.hsva((0.08 + halo.phase) % 1, 0.45, 1, 0.85) }
                    GradientStop { position: 0.7; color: Qt.hsva((0.78 + halo.phase) % 1, 0.40, 1, 0.85) }
                    GradientStop { position: 1.0; color: Qt.hsva((0.58 + halo.phase) % 1, 0.40, 1, 0.85) }
                }
                opacity: bubble.state === "listening" ? 1.0 : 0.8
            }
        }

        // -------------------------------------------------------- pill
        Rectangle {
            id: pill
            width: bubble.pillW; height: bubble.pillH
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.86)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.9)
            // inner pastel wash like the reference
            Rectangle {
                anchors.fill: parent; anchors.margins: 1
                radius: height / 2
                opacity: 0.35
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#FFE7C2" }
                    GradientStop { position: 0.5; color: "#FFF4F1" }
                    GradientStop { position: 1.0; color: "#FFC8DD" }
                }
            }
            Image {
                id: glyph
                source: Qt.resolvedUrl("../../assets/siri/siri_gen2_glyph.png")
                width: 20; height: 20
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                smooth: true; mipmap: true
            }
            TextInput {
                id: input
                anchors.left: glyph.right; anchors.leftMargin: 10
                anchors.right: mic.left; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                font.family: "SF Pro Text"; font.pixelSize: 15
                color: "#1d1d1f"
                selectionColor: "#0A84FF"
                cursorDelegate: Rectangle { width: 2; color: "#0A64D8"; radius: 1 }
                clip: true
                Keys.onEscapePressed: bubble.dismissRequested()
                onAccepted: if (text.trim() !== "") { bubble.submitted(text.trim()); text = "" }
                Text {
                    visible: !input.text && !input.activeFocus
                    text: "Ask Siri…"
                    color: Qt.rgba(0, 0, 0, 0.35)
                    font: input.font
                }
            }
            Item {
                id: mic
                width: 28; height: 28
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0x1002B0)          // mic (SF Symbols)
                    font.family: "SF Pro Text"; font.pixelSize: 17
                    color: bubble.state === "listening" ? "#0A84FF" : Qt.rgba(0, 0, 0, 0.55)
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bubble.micPressed() }
            }
        }

        // -------------------------------------------------------- card
        Rectangle {
            id: card
            visible: bubble.hasCard
            anchors.top: pill.bottom; anchors.topMargin: 12
            width: bubble.pillW
            implicitHeight: Math.min(420, col.implicitHeight + 36)
            radius: 22
            color: Qt.rgba(1, 1, 1, 0.96)
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.06)
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.18; shadowBlur: 0.8; shadowVerticalOffset: 6 }
            Flickable {
                anchors.fill: parent; anchors.margins: 18
                contentHeight: col.implicitHeight
                clip: true
                Column {
                    id: col
                    width: parent.width
                    spacing: 10
                    Text {
                        visible: bubble.heard !== ""
                        width: parent.width
                        text: bubble.heard
                        wrapMode: Text.Wrap
                        font.family: "SF Pro Display"; font.pixelSize: 17; font.weight: Font.DemiBold
                        color: "#1d1d1f"
                    }
                    Rectangle { visible: bubble.heard !== ""; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }
                    Text {
                        width: parent.width
                        text: bubble.error !== "" ? bubble.error
                              : (bubble.answer !== "" ? bubble.answer : "…")
                        textFormat: Text.MarkdownText
                        wrapMode: Text.Wrap
                        font.family: "SF Pro Text"; font.pixelSize: 14
                        lineHeight: 1.15
                        color: bubble.error !== "" ? "#c0392b" : "#3a3a3c"
                    }
                }
            }
        }
    }
}
