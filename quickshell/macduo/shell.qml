pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Mac-Duo for Linux: capture the screen as the lid closes, sweep the picture
// into the original's perspective/blur/dim collapse, then suspend. On lid open
// capture again and play the collapse backwards.
Scope {
    id: root

    // ── preferences (settings.json, Mac-Duo defaults) ──
    property var prefs: ({})
    property bool settingsOpen: false
    property bool macosPresent: false
    readonly property bool gateOpen: macosPresent && pref("enabled", true)

    property double thresholdAngle: pref("threshold", 90)
    property double blurSpan: pref("blurSpan", 60)
    property double maxBlurRadius: pref("maxBlur", 135)
    property double maxDim: pref("maxDim", 1.0)
    property double viewingDistance: pref("viewingDistance", 6.0)
    property double recession: pref("recession", 1.0)
    property double dimReach: pref("dimReach", 0.5)
    property double blurEvenness: pref("blurEvenness", 0.0)
    readonly property double dimHingeFloor: 0.2
    readonly property double blurCurve: 1.6
    readonly property double dimCurve: 0.7
    readonly property double springFreq: 16.0

    property var openAngle: pref("previewOpen", 125)
    property var shutAngle: pref("previewShut", 21)
    readonly property var closeShutAngle: 5

    function pref(k, d) {
        return (prefs && typeof prefs[k] !== "undefined") ? prefs[k] : d;
    }

    function setPref(k, v) {
        const next = Object.assign({}, prefs);
        next[k] = v;
        prefs = next;
        cfgWriter.command = ["python3", Quickshell.shellDir + "/writecfg.py", JSON.stringify(next)];
        cfgWriter.running = true;
        syncGate();
    }

    FileView {
        id: prefsFile
        path: Qt.resolvedUrl("settings.json")
        onLoaded: (file) => {
            try { root.prefs = JSON.parse(file.text); }
            catch (e) { root.prefs = {}; }
            root.syncGate();
        }
    }

    Process {
        id: cfgWriter
        running: false
    }

    // ── run state ──
    property bool active: false
    property bool dismissing: false
    property string mode: "preview"        // preview | close | open
    property string pendingMode: "preview"
    property bool lidClosedSeen: false
    property bool suspendAfterFade: false
    property int shotSeq: 0
    property bool shotPending: false

    property double t: 0
    property double lastNow: 0
    property double springValue: 90
    property double springVel: 0
    property double maxLevel: 0

    readonly property string shotPath: "/tmp/macduo_shot_" + (shotSeq % 2) + ".png"

    // ── geometry / effect uniforms ──
    // corners in points, y up, hinge along the bottom edge (y = 0)
    property vector4d column0: Qt.vector4d(1, 0, 0, 0)
    property vector4d column1: Qt.vector4d(0, 1, 0, 0)
    property vector4d column2: Qt.vector4d(0, 0, 1, 0)
    property vector4d screenVec: Qt.vector4d(2560, 1600, 11, 0)
    property vector4d blurVec: Qt.vector4d(0, 0, 135, 0)
    property vector4d dimVec: Qt.vector4d(0, 0.2, 0.5, 1.0)

    // ─────────────────────────── math (ported) ───────────────────────────

    // Heckbert rectangle → quadrilateral homography, columns of the forward
    // screen→picture matrix laid out col-major.
    function homographyForward(w, h, c) {
        const x0 = c[0], y0 = c[1], x1 = c[2], y1 = c[3];
        const x2 = c[4], y2 = c[5], x3 = c[6], y3 = c[7];
        const dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
        const dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
        let g = 0, h2 = 0;
        if (Math.abs(dx3) > 1e-9 || Math.abs(dy3) > 1e-9) {
            const det = dx1 * dy2 - dx2 * dy1;
            if (Math.abs(det) > 1e-12) {
                g = (dx3 * dy2 - dx2 * dy3) / det;
                h2 = (dx1 * dy3 - dx3 * dy1) / det;
            }
        }
        const a = x1 - x0 + g * x1, b = x3 - x0 + h2 * x3, cc = x0;
        const d = y1 - y0 + g * y1, e = y3 - y0 + h2 * y3, f = y0;
        return [a / w, d / w, g / w,  b / h, e / h, h2 / h,  cc, f, 1];
    }

    // col-major 3x3 inverse
    function invert3(m) {
        const a = m[0], d = m[1], g = m[2];
        const b = m[3], e = m[4], h = m[5];
        const c = m[6], f = m[7], i = m[8];
        const A = e * i - f * h, B = f * g - d * i, C = d * h - e * g;
        const det = a * A + b * B + c * C;
        if (Math.abs(det) < 1e-12) return null;
        const r00 = A / det, r01 = (c * h - b * i) / det, r02 = (b * f - c * e) / det;
        const r10 = B / det, r11 = (a * i - c * g) / det, r12 = (c * d - a * f) / det;
        const r20 = C / det, r21 = (b * g - a * h) / det, r22 = (a * e - b * d) / det;
        return [r00, r10, r20,  r01, r11, r21,  r02, r12, r22];
    }

    // Projected screen rectangle at a given lid angle — the original's
    // DepthGeometry: perspective away from the hinge plus a recession
    // rotation of the plane as the angle drops.
    function duoCorners(curDeg) {
        const w = 2560, h = 1600;
        const start = root.thresholdAngle * Math.PI / 180;
        const cur = curDeg * Math.PI / 180;
        const travel = Math.max(root.thresholdAngle - curDeg, 0);
        const sep = Math.min(root.recession * travel, 88) * Math.PI / 180;
        const reach = h * root.viewingDistance + h / 2 * Math.cos(start);
        const rise = h / 2 * Math.sin(start);
        const along = reach * Math.cos(cur) + rise * Math.sin(cur);
        const depth = Math.max(reach * Math.sin(cur) - rise * Math.cos(cur), h / 10);
        const half = w / 2;
        const proj = (x, y) => {
            const s = depth / (depth + y * Math.sin(sep));
            return [half + (x - half) * s, along + (y * Math.cos(sep) - along) * s];
        };
        return [...proj(0, 0), ...proj(w, 0), ...proj(w, h), ...proj(0, h)];
    }

    // ─────────────────────────── timeline ───────────────────────────

    function timelineTarget() {
        if (mode === "preview") {
            if (t < 1.4) return openAngle + (shutAngle - openAngle) * (t / 1.4);
            if (t < 2.2) return shutAngle;
            if (t < 2.8) return shutAngle + (openAngle - shutAngle) * ((t - 2.2) / 0.6);
            return thresholdAngle;   // closing-out eases back to flat
        }
        if (mode === "close") {
            if (t < 1.2) return thresholdAngle + (closeShutAngle - thresholdAngle) * (t / 1.2);
            return closeShutAngle;
        }
        // open
        if (t < 0.6) return closeShutAngle + (thresholdAngle - closeShutAngle) * (t / 0.6);
        return thresholdAngle;
    }

    function timelineDone() {
        if (mode === "preview") {
            if (t < 3.4) return false;
            // let the spring settle to flat (bounded, like the original's 1.2 s cap)
            if (t >= 4.0) return true;
            return Math.abs(springValue - thresholdAngle) < 0.05 && Math.abs(springVel) < 0.05;
        }
        if (mode === "close") return t >= 1.8;
        return t >= 0.6;
    }

    // ─────────────────────────── frame step ───────────────────────────

    function step() {
        if (t === 0) console.log("MACDUO firstFrame t=", t, "spring=", springValue);
        const now = Date.now();
        let dt = (now - lastNow) / 1000;
        lastNow = now;
        if (dt <= 0) return;
        if (dt < 1 / 240) dt = 1 / 240;
        if (dt > 1 / 20) dt = 1 / 20;

        if (!dismissing) {
            t += dt;
            const target = timelineTarget();
            const f = springFreq;
            const acc = f * f * (target - springValue) - 2 * f * springVel;
            springVel += acc * dt;
            springValue += springVel * dt;
            if (timelineDone()) finishRun();
        }
        applyVisual();
    }

    function applyVisual() {
        const progress = Math.min(Math.max((thresholdAngle - springValue) / blurSpan, 0), 1);
        const blurStrength = Math.pow(progress, blurCurve);
        const dimStrength = Math.pow(progress, dimCurve);

        const c = duoCorners(springValue);
        const fwd = homographyForward(2560, 1600, c);
        const inv = invert3(fwd);
        if (inv) {
            column0 = Qt.vector4d(inv[0], inv[1], inv[2], 0);
            column1 = Qt.vector4d(inv[3], inv[4], inv[5], 0);
            column2 = Qt.vector4d(inv[6], inv[7], inv[8], 0);
        }
        blurVec = Qt.vector4d(blurStrength, blurEvenness, maxBlurRadius, 0);
        dimVec = Qt.vector4d(dimStrength, dimHingeFloor, dimReach, maxDim);
    }

    // ─────────────────────────── run control ───────────────────────────

    function startRun(m) {
        console.log("MACDUO startRun", m, "gate=", gateOpen, "active=", active);
        if (active) return;
        pendingMode = m;
        shotSeq++;
        shotPending = true;
        shotProc.running = false;
        shotProc.running = true;
        shotWatchdog.restart();
    }

    function afterShot(ok) {
        console.log("MACDUO afterShot ok=", ok, "imgStatus=", pictureImg.status, "mode=", pendingMode);
        shotPending = false;
        shotWatchdog.stop();
        if (!ok) {
            if (pendingMode === "close") suspendProc.running = true;
            return;
        }
        // picture source is already (re)pointed; wait for Image.Ready
        if (pictureImg.status === Image.Ready) beginRun();
    }

    function beginRun() {
        console.log("MACDUO beginRun mode=", pendingMode);
        mode = pendingMode;
        active = true;
        dismissing = false;
        suspendAfterFade = false;
        t = 0;
        lastNow = Date.now();
        springValue = (mode === "open") ? closeShutAngle : thresholdAngle;
        springVel = 0;
        overlay.visible = true;
        effect.opacity = 0;
        applyVisual();
        fadeAnim.stop();
        fadeAnim.from = 0;
        fadeAnim.to = 1;
        fadeAnim.duration = 70;
        fadeAnim.easing.type = Easing.OutCubic;
        fadeAnim.start();
    }

    function finishRun() {
        console.log("MACDUO finishRun mode=", mode, "spring=", springValue.toFixed(1));
        if (dismissing) return;
        dismissing = true;
        if (mode === "close") {
            suspendAfterFade = true;
            // never sleep with the settings dialog holding keyboard focus
            settingsOpen = false;
        }
        fadeAnim.stop();
        fadeAnim.from = effect.opacity;
        fadeAnim.to = 0;
        fadeAnim.duration = 220;
        fadeAnim.easing.type = Easing.InOutCubic;
        fadeAnim.start();
    }

    function forceStop() {
        console.log("MACDUO forceStop");
        fadeAnim.stop();
        active = false;
        dismissing = false;
        overlay.visible = false;
        effect.opacity = 0;
        suspendAfterFade = false;
    }

    NumberAnimation {
        id: fadeAnim
        target: effect
        property: "opacity"
        onFinished: {
            // only the dismiss fade cleans up; the reveal fade just finished
            if (!root.dismissing) return;
            root.active = false;
            root.dismissing = false;
            overlay.visible = false;
            if (root.suspendAfterFade) {
                root.suspendAfterFade = false;
                root.settingsOpen = false;
                suspendProc.running = true;
            }
        }
    }

    FrameAnimation {
        id: frameTick
        running: root.active && !root.dismissing
        onTriggered: root.step()
    }

    // ─────────────────────────── capture ───────────────────────────

    Image {
        id: pictureImg
        visible: false
        mipmap: true
        asynchronous: true
        source: ""
        onStatusChanged: {
            if (!root.shotPending) return;
            if (status === Image.Ready) root.afterShot(true);
            else if (status === Image.Error) root.afterShot(false);
        }
    }

    Process {
        id: shotProc
        running: false
        command: ["grim", "-o", "eDP-1", root.shotPath]
        onExited: (code, status) => {
            if (!root.shotPending) return;
            if (code === 0) pictureImg.source = "file://" + root.shotPath;
            else root.afterShot(false);
        }
    }

    Timer {
        id: shotWatchdog
        interval: 2500
        onTriggered: if (root.shotPending) root.afterShot(false)
    }

    // ─────────────────────────── lid / timers ───────────────────────────

    Timer {
        id: openDelay
        interval: 400
        onTriggered: root.startRun("open")
    }

    // ─────────────────────── lifecycle gate (macos shell) ───────────────────────
    // Everything that touches the system (lid events, logind inhibit, tray
    // icon) runs only while the macos shell is alive and the effect is
    // enabled. macduo never modifies the macos shell itself.

    function syncGate() {
        const sniWant = macosPresent;
        const animWant = gateOpen;
        if (sniWant !== sniProc.running) sniProc.running = sniWant;
        if (animWant !== lidProc.running) lidProc.running = animWant;
        if (animWant !== inhibitProc.running) inhibitProc.running = animWant;
        if (!animWant && active) forceStop();
    }

    Process {
        id: gateProc
        running: false
        command: ["qs", "list", "--all"]
        stdout: StdioCollector {
            id: gateOut
            onStreamFinished: {
                root.macosPresent = gateOut.text.includes("/quickshell/macos/shell.qml");
                root.syncGate();
            }
        }
    }

    Timer {
        id: gateTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!gateProc.running) gateProc.running = true
    }

    Process {
        id: sniProc
        running: false
        command: ["python3", Quickshell.shellDir + "/sni.py"]
    }

    Process {
        id: suspendProc
        running: false
        command: ["systemctl", "suspend"]
    }

    // Keeps the lid's logind handling blocked while the effect is armed; if
    // this shell dies or the gate closes, the inhibitor dies with it and
    // normal logind lid behavior returns.
    Process {
        id: inhibitProc
        running: false
        command: ["systemd-inhibit", "--what=handle-lid-switch",
                  "--who=macduo", "--why=macduo close animation",
                  "--mode=block", "sleep", "infinity"]
    }

    Process {
        id: lidProc
        running: false
        command: ["python3", Quickshell.shellDir + "/lidwatch.py"]
    }

    IpcHandler {
        target: "macduo"

        function preview(): void {
            root.startRun("preview");
        }

        function toggleSettings(): void {
            root.settingsOpen = !root.settingsOpen;
        }

        function openSettings(): void {
            root.settingsOpen = true;
        }

        function closeSettings(): void {
            root.settingsOpen = false;
        }

        function setPref(key: string, value: real): void {
            root.setPref(key, value);
        }

        function lid(state: string): void {
            if (!root.gateOpen) return;
            if (state === "closed") {
                root.lidClosedSeen = true;
                openDelay.stop();
                if (!root.active) root.startRun("close");
            } else if (state === "open") {
                if (root.lidClosedSeen) {
                    root.lidClosedSeen = false;
                    if (!root.active) openDelay.start();
                }
            }
        }

        function stop(): void {
            root.forceStop();
            root.settingsOpen = false;
        }
    }

    SettingsWindow {}

    GlobalShortcut {
        name: "macduoPreview"
        description: "Play the Mac-Duo lid animation"
        onPressed: root.startRun("preview")
    }

    // ─────────────────────────── the overlay ───────────────────────────

    PanelWindow {
        id: overlay
        screen: Quickshell.screens.find(s => s.name === "eDP-1") || Quickshell.screens[0]
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: false

        WlrLayershell.namespace: "macduo"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // empty region: click-through, the effect never takes input
        mask: Region {}

        ShaderEffect {
            id: effect
            anchors.fill: parent
            opacity: 0

            property variant picture: pictureImg
            property vector4d column0: root.column0
            property vector4d column1: root.column1
            property vector4d column2: root.column2
            property vector4d screenVec: root.screenVec
            property vector4d blurVec: root.blurVec
            property vector4d dimVec: root.dimVec

            fragmentShader: Qt.resolvedUrl("shaders/duo.frag.qsb")
        }
    }
}

