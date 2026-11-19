import QtQuick
import Quickshell
import Quickshell.Wayland

// Siri / Apple Intelligence screen-edge light (macOS 27, 26A428).
//
// Motion = SiriUICore.framework SUICLightPhysics (C, decompiled):
//   * 33 seeds rand()/2^31 * 600 - 300                      (CommonPhysics_Init)
//   * time += step*0.7*0.5 + 0.5*0.8*min(25*step, 2.5*vol*step)  (UpdatePhysicsTick, Mac: +0x101 = 1)
//   * light i, angle k = noise2(3i+k-8.5, seed[3i+k] + 0.05*time) * 4*pi
//     x = cos c cos b - sin c sin a sin b ; y = -cos a sin c ; * 1.1   (FinalizeStateForFrame)
//   * noise2 = PhysicsKit _noise2 (Perlin improved noise, *0.507)
// Edge mask = SUICEdgeLightMaskMetalLayer: noise drift (0.007, -0.011, 0.06 + 0.1675*vol),
// noise rotation -0.1 rad/s, burst for 9.9 s after animateOn, falloff -24 (landscape).
PanelWindow {
    id: root

    property bool active: false       // Siri session visible
    property real voiceLevel: 0       // 0..1 microphone power while listening
    property bool burstOnShow: true    // voice activation burst (animateOn with burst)

    // tunables (not encoded in the shaders)
    property real flameScale: 3.0      // layout flameScale = 3 / _flameScale (ivar 0x8e0 = 1.0)
    property real screenCornerRadius: 14

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "macos:siri-glow"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}                    // never takes input
    visible: active || fade.running || glow.visibility > 0.001

    // ---------------------------------------------------------------- physics
    readonly property var perm: [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]
    property var seeds: []
    property real physTime: 0
    property real volSmooth: 0

    function p(i) { return root.perm[i & 255] }
    function grad(h, x, y) {
        var u = (h & 4) === 0 ? y : x
        var v = (h & 4) === 0 ? x : y
        return ((h & 2) === 0 ? 2 : -2) * u + ((h & 1) === 0 ? v : -v)
    }
    // PhysicsKit _noise2
    function noise2(x, y) {
        var xi = Math.trunc(x) - (x <= 0 ? 1 : 0)
        var yi = Math.trunc(y) - (y <= 0 ? 1 : 0)
        var xf = x - xi, yf = y - yi
        var fx = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
        var fy = yf * yf * yf * (yf * (yf * 6 - 15) + 10)
        var X = xi & 255, Y = yi & 255
        var aa = p(p(Y) + X), ba = p(p(Y) + X + 1)
        var ab = p(p(Y + 1) + X), bb = p(p(Y + 1) + X + 1)
        var x0 = grad(aa, xf, yf), x1 = grad(ba, xf - 1, yf)
        var y0 = grad(ab, xf, yf - 1), y1 = grad(bb, xf - 1, yf - 1)
        var l0 = x0 + (y0 - x0) * fy
        var l1 = x1 + (y1 - x1) * fy
        return (l0 + (l1 - l0) * fx) * 0.507
    }
    function reseed() {
        var s = []
        for (var i = 0; i < 33; i++) s.push(Math.random() * 600 - 300)
        root.seeds = s
    }
    function lightPos(i) {
        var tt = root.physTime * 0.05
        var A = []
        for (var k = 0; k < 3; k++)
            A.push(noise2((3 * i + k) - 8.5, root.seeds[3 * i + k] + tt) * 4 * Math.PI)
        var a = A[0], b = A[1], c = A[2]
        var x = Math.cos(c) * Math.cos(b) - Math.sin(c) * Math.sin(a) * Math.sin(b)
        var y = -Math.cos(a) * Math.sin(c)
        return Qt.point(x * 1.1, y * 1.1)
    }

    // ------------------------------------------------------------ edge state
    property real burstStart: -1
    property vector3d noiseOff: Qt.vector3d(Math.random(), Math.random(), Math.random())
    property real noiseRot: 0

    Component.onCompleted: reseed()
    onActiveChanged: {
        if (active) {
            reseed()
            root.burstStart = root.burstOnShow ? (Date.now() / 1000 + 0.133328) : -1
            fade.to = 1; fade.duration = 250; fade.restart()
        } else {
            fade.to = 0; fade.duration = 350; fade.restart()   // _startOffAnimation 0.35
        }
    }
    NumberAnimation { id: fade; target: glow; property: "visibility"; easing.type: Easing.InOutQuad }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            var dt = Math.min(frameTime, 0.05)
            root.volSmooth += (root.voiceLevel - root.volSmooth) * Math.min(1, dt * 12)
            var vol = root.volSmooth
            // SUICLightPhysics time
            root.physTime += dt * (0.7 * 0.5 + 0.8 * 0.5 * Math.min(25, 2.5 * vol * 10))
            var L = [], i
            for (i = 0; i < 6; i++) L.push(root.lightPos(i))
            glow.lightsA = Qt.vector4d(L[0].x, L[0].y, L[1].x, L[1].y)
            glow.lightsB = Qt.vector4d(L[2].x, L[2].y, L[3].x, L[3].y)
            glow.lightsC = Qt.vector4d(L[4].x, L[4].y, L[5].x, L[5].y)
            // [0x128] = spring(0.7 + 0.7*power^2) * 0.07
            glow.lightLevel = 0.07 * (0.7 + 0.7 * vol * vol)
            // EdgeLight noise drift + rotation
            var nx = root.noiseOff.x + 0.007 * dt
            var ny = root.noiseOff.y - 0.011 * dt
            var nz = root.noiseOff.z + (0.06 + 0.1675 * vol) * dt
            if (nx > 1) nx -= 1; if (ny < 0) ny += 1; if (nz > 1) nz -= 1
            root.noiseOff = Qt.vector3d(nx, ny, nz)
            root.noiseRot -= 0.1 * dt
            if (root.noiseRot < 0) root.noiseRot += 2 * Math.PI
            glow.noiseOffset = root.noiseOff
            glow.noiseRotation = root.noiseRot
            glow.time = root.burstStart < 0 ? 10 : Math.max(0, Math.min(10, Date.now() / 1000 - root.burstStart))
            glow.falloffScale = 0.85 + 0.35 * vol
            glow.flameScaleDucked = root.flameScale / (0.7 + 0.3 * glow.visibility)
        }
    }

    ShaderEffect {
        id: glow
        anchors.fill: parent
        property real visibility: 0
        property vector4d lightsA
        property vector4d lightsB
        property vector4d lightsC
        property real lightLevel: 0
        readonly property real hw: root.height / Math.max(1, root.width)
        property vector2d lightScale: Qt.vector2d(1.5, 1.5 * hw)
        property vector2d lightOffset: Qt.vector2d(0, 0)
        property vector2d noiseScale: Qt.vector2d(0.5, 0.5 * hw)
        property vector3d noiseOffset
        property vector2d burstCenter: Qt.vector2d(0, 0.5 * hw)     // bottom centre
        property vector2d direction: Qt.vector2d(0, 0)
        property real directionRadius: 10
        property real falloffScale: 0.85
        property real time: 10
        property real noiseRotation: 0
        property real defaultFlameOpacity: 0.9
        property vector2d resolution: Qt.vector2d(root.width, root.height)
        property real yxRatio: hw
        property real screenRadiusRatio: root.screenCornerRadius / Math.max(1, root.width / 2)
        property real flameScaleDucked: root.flameScale
        property real burstOpacity: 1
        property real contrast: 1
        property var noiseAtlas: Image {
            source: Qt.resolvedUrl("../../assets/siri/il_noise_atlas.png")
            smooth: true
            visible: false
        }
        fragmentShader: Qt.resolvedUrl("shaders/siriglow.frag.qsb")
    }
}
