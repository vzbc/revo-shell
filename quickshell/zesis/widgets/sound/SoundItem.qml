import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    readonly property real _vol: AudioService.vol
    readonly property bool _muted: AudioService.muted
    icon: {
        if (_muted || _vol === 0)
            return "󰝟";
        if (_vol < 0.33)
            return "󰕿";
        if (_vol < 0.67)
            return "󰖀";
        return "󰕾";
    }

    WheelHandler {
        onWheel: function (w) {
            var audio = AudioService.sink?.audio;
            if (!audio)
                return;
            audio.volume = Math.max(0, Math.min(1.5, audio.volume + w.angleDelta.y / 1200.0));
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: 300
        implicitHeight: 320
        content: Component {
            Sound {}
        }
    }
}
