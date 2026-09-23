import QtQuick
import QtQuick.Layouts
import qs.components
import qs.commons
import Quickshell.Services.Pipewire
import qs.services

Item {
    id: root

    property int style: Settings.bar.volume.style
    readonly property var sink: Pipewire.defaultAudioSink

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
    }

    function changeVolume(delta) {
        if (!sink)
            return;
        var newVol = Math.min(1.5, Math.max(0, sink.audio.volume + delta));
        sink.audio.volume = newVol;
        if (sink.audio.muted && delta > 0)
            sink.audio.muted = false;
    }

    function toggleMute() {
        if (sink)
            sink.audio.muted = !sink.audio.muted;
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: ScalerService.s(2)

        IconImage {
            visible: root.style === 1
            path: sink && sink.audio.muted ? "volume/mute.png" : "volume/volume.png"
        }

        IconText {
            visible: root.style === 2
            size: isVertical ? "small" : "normal"
            name: {
                if (!sink || sink.audio.muted)
                    return "volume_off";
                return getIcon(Math.round(sink.audio.volume * 100));
            }
            textColor: theme.button.text
        }

        CustomText {
            visible: root.style === 1 && (Settings.bar.position === "top" || Settings.bar.position === "bottom")
            name: sink ? Math.round(sink.audio.volume * 100) + "%" : "0%"
            isBold: true
            size: isVertical ? "xs" : "small"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor

        onWheel: wheel => {
            let step = 0.05;

            SoundService.playSound("pop");
            if (wheel.angleDelta.y > 0)
                changeVolume(step);
            else if (wheel.angleDelta.y < 0)
                changeVolume(-step);
        }

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                toggleMute();
                mouse.accepted = true;
            } else {
                mouse.accepted = false;
            }
        }
    }
}
