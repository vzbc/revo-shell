import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Data as Dat

WlrLayershell {
    id: root

    required property ShellScreen modelData
    property real mouseOffsetX: 0.0
    property real mouseOffsetY: 0.0
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    layer: WlrLayer.Bottom
    namespace: "wallpaper.engine"
    screen: modelData

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Image {
        id: bgRaw
        source: Qt.resolvedUrl("../Assets/p3r imgs/bg.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: cloudMaskRaw
        source: Qt.resolvedUrl("../Assets/Depth masks/cloudmask.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: normalMapRipple
        source: Qt.resolvedUrl("../Assets/Depth masks/normalmaps/waterripplenormal.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: barsRaw
        source: Qt.resolvedUrl("../Assets/p3r imgs/bars.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: depthMapRaw
        source: Qt.resolvedUrl("../Assets/Depth masks/makotodepth.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    // ── Stage 0a: Ripple ──
    ShaderEffect {
        id: s0_bg_clouds
        anchors.fill: parent
        visible: true

        property var source: bgRaw
        property var normalMap: normalMapRipple
        property var depthMask: cloudMaskRaw
        property real time: 0
        property real flowStrength: 0.006
        property real speed: 2.5
        property real frequency: 1.0

        NumberAnimation on time {
            from: 0
            to: 10
            duration: 800000
            loops: Animation.Infinite
            running: true
        }

        vertexShader: Qt.resolvedUrl("../Assets/shaders/ripple/ripple.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/ripple/ripple.frag.qsb")
    }

    ShaderEffectSource {
        id: s0_clouds_out
        sourceItem: s0_bg_clouds
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

    // ── Stage 0b: Stars/Rain ──
    ShaderEffect {
        id: s0_bg_stars
        anchors.fill: parent
        visible: false

        property var source: s0_clouds_out
        property real time: 0
        property real strength: 50
        property real speed: 5.5
        property real frequency: 10.0

        NumberAnimation on time {
            from: 0
            to: 1000
            duration: 500000
            loops: Animation.Infinite
            running: true
        }

        vertexShader: Qt.resolvedUrl("../Assets/shaders/stars/stars.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/stars/stars.frag.qsb")
    }

    // ── Stage 1: Composite ──
    Item {
        id: s1_composite
        anchors.fill: parent
        visible: false

        ShaderEffectSource {
            id: s0_bg_out
            sourceItem: s0_bg_stars
            anchors.fill: parent
            hideSource: true
            live: true
        }

        ShaderEffect {
            id: s1_bars_motion
            anchors.fill: parent

            property var source: barsRaw
            property real time: 0
            property real speed: 1

            NumberAnimation on time {
                from: 0
                to: 10000
                duration: 10000000
                loops: Animation.Infinite
                running: true
            }

            vertexShader: Qt.resolvedUrl("../Assets/shaders/motion/motion.vert.qsb")
            fragmentShader: Qt.resolvedUrl("../Assets/shaders/motion/motion.frag.qsb")
        }

        CavaVisualizer {
            id: s1_cava
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: 0
            }
            height: 555
        }

        Image {
            id: s1_fg
            source: Qt.resolvedUrl("../Assets/p3r imgs/fg.png")
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
        }
    }

    // ── Composite output ──
    ShaderEffectSource {
        id: s1_out
        sourceItem: s1_composite
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

    // ── Stage 2: Parallax ──
    ShaderEffect {
        id: s2_parallax
        anchors.fill: parent
        visible: true

        property var source: s1_out
        property real offsetX: root.mouseOffsetX
        property real offsetY: root.mouseOffsetY
        property real parallaxStrength: 0.03
        property real aspectRatio: width / height
        property var depthMap: depthMapRaw

        vertexShader: Qt.resolvedUrl("../Assets/shaders/parallax/parallax.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/parallax/parallax.frag.qsb")
    }

    // ── Mouse tracking ──
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            root.mouseOffsetX = (mouse.x / width - 0.5) * 2.0;
            root.mouseOffsetY = (mouse.y / height - 0.5) * 2.0;
        }
    }
}
