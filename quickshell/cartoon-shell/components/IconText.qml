import QtQuick
import qs.services

Text {
    property string name: "undefined"

    // xs | small | normal | large | xl
    property string size: "normal"

    property color textColor: theme.primary.foreground
    property string fontFamily: "Material Symbols Rounded"
    font.variableAxes: {
        "FILL": 1
    }
    renderType: Text.NativeRendering

    text: name
    color: textColor

    font.family: fontFamily
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    font.pixelSize: {
        switch (size) {
        case "xs":
            return ScalerService.s(16);
        case "small":
            return ScalerService.s(22);
        case "normal":
            return ScalerService.s(32);
        case "large":
            return ScalerService.s(38);
        case "xl":
            return ScalerService.s(64);
        default:
            return ScalerService.s(40);
        }
    }
}
