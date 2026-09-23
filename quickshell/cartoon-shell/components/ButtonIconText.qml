import QtQuick
import qs.services

Rectangle {
    id: root

    // Properties
    property string name: "undefined"
    property string size: "normal"  // xs | small | normal | large | xl
    property color textColor: theme.primary.foreground
    property string fontFamily: "Material Symbols Rounded"

    // Thêm property hovered để sửa lỗi undefined
    readonly property alias hovered: mouseArea.containsMouse

    // Signal để forward sự kiện ra ngoài
    signal clicked
    signal wheel(var event)

    color: "transparent"

    implicitWidth: maxSize
    implicitHeight: maxSize

    readonly property int maxSize: {
        switch (size) {
        case "xs":
            return ScalerService.s(20);
        case "small":
            return ScalerService.s(26);
        case "normal":
            return ScalerService.s(32);
        case "large":
            return ScalerService.s(58);
        case "xl":
            return ScalerService.s(72);
        default:
            return ScalerService.s(46);
        }
    }

    Text {
        id: iconText
        anchors.centerIn: parent

        font.variableAxes: {
            "FILL": 1
        }
        renderType: Text.NativeRendering
        font.family: root.fontFamily

        text: root.name
        color: root.hovered ? Qt.lighter(root.textColor, 1.2) : root.textColor

        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        Behavior on rotation {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutQuad
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        font.pixelSize: {
            switch (root.size) {
            case "xs":
                return root.hovered ? ScalerService.s(20) : ScalerService.s(16);
            case "small":
                return root.hovered ? ScalerService.s(26) : ScalerService.s(22);
            case "normal":
                return root.hovered ? ScalerService.s(34) : ScalerService.s(32);
            case "large":
                return root.hovered ? ScalerService.s(58) : ScalerService.s(52);
            case "xl":
                return root.hovered ? ScalerService.s(72) : ScalerService.s(64);
            default:
                return root.hovered ? ScalerService.s(46) : ScalerService.s(40);
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            SoundService.playSound("pick");
            root.clicked();
        }

        onWheel: event => {
            root.wheel(event);
        }
    }
}
