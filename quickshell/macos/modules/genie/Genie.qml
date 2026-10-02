import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    readonly property int strips: 140
    readonly property int durMin: 360
    readonly property int durRes: 450

    property string state: "idle"
    property string dir: "in"
    property string addr: ""
    property string cachedAddr: ""
    property rect wrect: Qt.rect(0, 0, 0, 0)
    property vector2d tip: Qt.vector2d(0, 0)
    property double progress: 0
    property var srcToplevel: null

    onStateChanged: {
        capDelay.stop();
        capPoll.stop();
        if (state === "capturing") {
            capPoll.n = 0;
            capDelay.start();
        } else if (state === "ready" && dir === "in") {
            cachedAddr = addr;
        }
    }

    function sstep(u) {
        if (u <= 0)
            return 0;
        if (u >= 1)
            return 1;
        return u * u * u * (u * (u * 6 - 15) + 10);
    }

    function rowK(v) {
        return sstep((progress - 0.45 * (1 - v)) / 0.55);
    }

    function rowY(v) {
        const y0 = wrect.y + v * wrect.height;
        return y0 + (tip.y - y0) * rowK(v);
    }

    function rowCX(v) {
        const c = wrect.x + wrect.width / 2;
        return c + (tip.x - c) * rowK(v);
    }

    function rowHW(v) {
        return wrect.width / 2 + (8 - wrect.width / 2) * rowK(v);
    }

    function rowGeom(i) {
        const v0 = i / strips;
        const v1 = (i + 1) / strips;
        const y0 = rowY(v0);
        const y1 = rowY(v1);
        const cx = (rowCX(v0) + rowCX(v1)) / 2;
        const hw = (rowHW(v0) + rowHW(v1)) / 2;
        return {
            "x": cx - hw,
            "y": y0,
            "w": 2 * hw,
            "h": (y1 - y0) + 1
        };
    }

    IpcHandler {
        target: "genie"

        function prepare(a: string, x: real, y: real, w: real, h: real, tx: real, ty: real, d: string): string {
            if (root.state !== "idle")
                return "fail";
            root.dir = String(d);
            root.addr = String(a);
            root.wrect = Qt.rect(x, y, w, h);
            root.tip = Qt.vector2d(tx, ty);
            root.progress = root.dir === "in" ? 0 : 1;
            if (root.dir === "out") {
                if (root.cachedAddr !== root.addr || !scv.hasContent)
                    return "fail:cache";
                root.state = "ready";
                return "ok";
            }
            const norm = s => String(s === undefined || s === null ? "" : s).replace(/^0x/i, "").toLowerCase();
            const want = norm(root.addr);
            const ht = Hyprland.toplevels.values.find(t => norm(t.lastIpcObject && t.lastIpcObject.address) === want) || Hyprland.toplevels.values.find(t => norm(t.address) === want);
            if (!ht)
                return "fail:toplevel";
            let tl = ht.wayland;
            if (!tl) {
                const o = ht.lastIpcObject || {};
                const title = o.title || ht.title || "";
                const cls = o.class || "";
                tl = ToplevelManager.toplevels.values.find(t => t.appId === cls && t.title === title) || ToplevelManager.toplevels.values.find(t => t.title === title);
            }
            if (!tl)
                return "fail:capture-src";
            root.srcToplevel = tl;
            root.state = "capturing";
            return "ok";
        }

        function status(): string {
            return root.state;
        }

        function prog(): real {
            return root.progress;
        }

        function geom(): string {
            const a = root.rowGeom(0);
            const b = root.rowGeom(Math.floor(root.strips / 2));
            const c = root.rowGeom(root.strips - 1);
            return `${a.x},${a.y},${a.w},${a.h} | ${b.x},${b.y},${b.w},${b.h} | ${c.x},${c.y},${c.w},${c.h}`;
        }

        function go(): string {
            if (root.state !== "ready")
                return "fail";
            root.state = "playing";
            anim.from = root.dir === "in" ? 0 : 1;
            anim.to = root.dir === "in" ? 1 : 0;
            anim.duration = root.dir === "in" ? root.durMin : root.durRes;
            anim.start();
            return "ok";
        }

        function cancel(): string {
            root.state = "idle";
            anim.stop();
            hold.stop();
            return "ok";
        }
    }

    Timer {
        id: capDelay
        interval: 60
        onTriggered: {
            scv.captureFrame();
            capPoll.n = 0;
            capPoll.start();
        }
    }

    Timer {
        id: capPoll
        property int n: 0
        interval: 15
        onTriggered: {
            if (scv.hasContent) {
                stop();
                root.state = "ready";
            } else if (++n > 66) {
                stop();
                root.state = "idle";
            }
        }
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        easing.type: Easing.Linear
        onStopped: {
            if (root.state !== "playing")
                return;
            root.state = "hold";
            hold.start();
        }
    }

    Timer {
        id: hold
        interval: 100
        onTriggered: {
            if (root.state === "hold")
                root.state = "idle";
        }
    }

    PanelWindow {
        id: ov

        visible: root.state !== "idle"
        screen: Quickshell.screens[0]
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: -1
        focusable: false
        WlrLayershell.namespace: "macos:genie"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Item {
            id: stage
            anchors.fill: parent

            ScreencopyView {
                id: scv
                x: root.wrect.x
                y: root.wrect.y
                width: root.wrect.width
                height: root.wrect.height
                captureSource: root.srcToplevel
                live: false
            }

            ShaderEffectSource {
                id: hider
                width: 0
                height: 0
                sourceItem: scv
                hideSource: true
            }

            Item {
                id: rowsGroup
                anchors.fill: parent
                // last 8%: funnel dissolves into the Dock icon (never draws over it)
                opacity: Math.min(1, Math.max(0, (1 - root.progress) / 0.08))

                Repeater {
                    model: (root.state === "playing" || root.state === "hold") ? root.strips : 0

                    delegate: Item {
                        id: row

                        required property int index

                        readonly property var g: root.rowGeom(index)
                        x: g.x
                        y: g.y
                        width: g.w
                        height: g.h

                        ShaderEffectSource {
                            anchors.fill: parent
                            sourceItem: scv
                            sourceRect: Qt.rect(0, (row.index / root.strips) * root.wrect.height - 0.5, root.wrect.width, root.wrect.height / root.strips + 1)
                        }
                    }
                }
            }
        }
    }
}
