import QtQuick
import "../../"
import "../shared"

Item {
    id: sysinfo

    implicitWidth: Math.round(40 * UIScale.value)
    implicitHeight: Math.round(40 * UIScale.value)

    readonly property bool active: popup.visible

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    Text {
        anchors.centerIn: parent
        text: "󰍛"
        font.pixelSize: 20
        color: (mouseArea.containsMouse || sysinfo.active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        readonly property real arcLength: SysMonService.cpu.percent / 100
        readonly property color strokeColor: (mouseArea.containsMouse || sysinfo.active) ? Colors.accent : Colors.text

        onArcLengthChanged: requestPaint()
        onStrokeColorChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, strokeColor.a);
            ctx.lineWidth = height / 8;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - ctx.lineWidth / 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * arcLength, false);
            ctx.stroke();
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: sysinfo
        implicitWidth: Math.round(380 * UIScale.value)
        implicitHeight: Math.round(520 * UIScale.value)
        content: Component {
            SysMonView {}
        }
        onVisibleChanged: SysMonService.popupOpen = visible
    }
}
