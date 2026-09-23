import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.commons
import qs.services

Item {
    property var path: ""

    // xs | small | normal | large | xl
    property string size: "normal"

    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }
    Behavior on rotation {
        NumberAnimation {
            duration: 500
        }
    }

    width: {
        switch (size) {
        case "xs":
            return ScalerService.s(12);
        case "small":
            return ScalerService.s(22);
        case "normal":
            return ScalerService.s(32);
        case "large":
            return ScalerService.s(40);
        case "xl":
            return ScalerService.s(50);
        case "2xl":
            return ScalerService.s(64);
        case "3xl":
            return ScalerService.s(84);
        case "4xl":
            return ScalerService.s(100);
        default:
            return ScalerService.s(32);
        }
    }

    height: width

    Layout.preferredWidth: width
    Layout.preferredHeight: height

    Image {
        anchors.fill: parent
        anchors.margins: ScalerService.s(2)

        source: Directories.assetsPath + "/" + path

        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
