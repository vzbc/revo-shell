import QtQuick
import "../../"
import "./"

// I KNOW this has a current tug of war with the widget bar SysMon.
// We need to find a way to signal what each widget needs, probably add/remove needed requests.
// OR we just spawn a second athroisma process here, idk. And I don't care.
// This is proof of concept written at, let's see... it was written at shit o' clock, 00:06 in the evening!
// And I am so tired. I thought this would be a bright cool concept, cyberpunk'ish thing.
// But in reality that would take far more effort, and I don't wanna waste time on this.

// Whoever fixes this PLEASE write down the time you wasted on it here.
// So people will be scared off to never attempt this shitty ass concept again.

Item {
    id: root

    Component.onCompleted: SysMonService.desktopWidgetActive = true
    Component.onDestruction: SysMonService.desktopWidgetActive = false

    readonly property real _p: Math.round(14 * UIScale.value)

    readonly property var _gpu: SysMonService.gpu.length > 0 ? SysMonService.gpu[0] : null
    readonly property int _netRx: {
        var t = 0;
        for (var i = 0; i < SysMonService.net.length; i++)
            t += SysMonService.net[i].rx_bytes_per_sec;
        return t;
    }
    readonly property int _netTx: {
        var t = 0;
        for (var i = 0; i < SysMonService.net.length; i++)
            t += SysMonService.net[i].tx_bytes_per_sec;
        return t;
    }
    readonly property int _diskRd: SysMonService.disk.length > 0 ? SysMonService.disk[0].read_bytes_per_sec : 0
    readonly property int _diskWr: SysMonService.disk.length > 0 ? SysMonService.disk[0].write_bytes_per_sec : 0

    function _gb(n) {
        return (n / 1073741824).toFixed(1);
    }

    readonly property real _snapUnit: Math.round(100 * UIScale.value)
    implicitWidth: Math.ceil((col.implicitWidth + _p * 2) / _snapUnit) * _snapUnit
    implicitHeight: col.implicitHeight + _p * 2

    Column {
        id: col
        x: root._p
        y: root._p
        spacing: Math.round(5 * UIScale.value)

        SysMonStatRow {
            lbl: "CPU"
            val: Math.round(SysMonService.cpu.percent) + "%"
            dim: "load " + SysMonService.cpu.load.toFixed(2)
        }
        SysMonStatRow {
            lbl: "MEM"
            val: root._gb(SysMonService.memory.used_bytes) + " / " + root._gb(SysMonService.memory.total_bytes) + " G"
        }
        SysMonStatRow {
            visible: SysMonService.memory.swap_total_bytes > 0
            lbl: "SWP"
            val: root._gb(SysMonService.memory.swap_used_bytes) + " / " + root._gb(SysMonService.memory.swap_total_bytes) + " G"
        }

        Item {
            width: 1
            height: Math.round(5 * UIScale.value)
        }

        SysMonStatRow {
            visible: root._gpu !== null
            lbl: "GPU"
            val: root._gpu ? root._gpu.busy + "%" : ""
            dim: root._gpu ? Math.round(root._gpu.temp_c) + "°   " + Math.round(root._gpu.power_w) + " W" : ""
        }
        SysMonStatRow {
            visible: root._gpu !== null && root._gpu.vram_total > 0
            lbl: "VRM"
            val: root._gpu ? root._gb(root._gpu.vram_used) + " / " + root._gb(root._gpu.vram_total) + " G" : ""
        }

        Item {
            width: 1
            height: Math.round(5 * UIScale.value)
        }

        SysMonStatRow {
            lbl: "NET"
            val: "↓ " + SysMonService.fmtRate(root._netRx) + "   ↑ " + SysMonService.fmtRate(root._netTx)
        }
        SysMonStatRow {
            lbl: "DSK"
            val: "↓ " + SysMonService.fmtRate(root._diskRd) + "   ↑ " + SysMonService.fmtRate(root._diskWr)
        }
    }
}
