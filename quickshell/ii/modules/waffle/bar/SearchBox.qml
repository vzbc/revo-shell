import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Windows 11 style search box:
// - chamfered (slanted) edges instead of a plain rounded rectangle
// - a Search Highlights orb that always spins on the right side
// - a periodic "gleam" shine that sweeps across the pill
WButton {
    id: root

    text: Translation.tr("Search")
    checkable: true
    checked: GlobalStates.searchOpen && LauncherSearch.query !== ""

    colBackground: ColorUtils.transparentize(Looks.colors.bg2, 0.08)
    colBackgroundHover: Looks.colors.bg2Hover
    colBackgroundActive: Looks.colors.bg2Active
    colForeground: Looks.colors.fg1

    property color colBackgroundBorder: ColorUtils.transparentize(Looks.colors.bg2Border, 0.5)
    readonly property real chamfer: Math.min(9, Math.max(4, height * 0.26))

    Layout.preferredWidth: 220
    Layout.preferredHeight: 36
    Layout.alignment: Qt.AlignVCenter
    horizontalPadding: 12
    buttonSpacing: 10

    onClicked: {
        GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }

    background: Shape {
        id: bgShape
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            id: outlinePath
            fillColor: root.color
            strokeColor: root.colBackgroundBorder
            strokeWidth: 1
            joinStyle: ShapePath.MiterJoin

            Behavior on fillColor {
                ColorAnimation { duration: 80 }
            }

            startX: root.chamfer
            startY: 0
            PathLine { x: bgShape.width - root.chamfer; y: 0 }
            PathLine { x: bgShape.width; y: root.chamfer }
            PathLine { x: bgShape.width; y: bgShape.height - root.chamfer }
            PathLine { x: bgShape.width - root.chamfer; y: bgShape.height }
            PathLine { x: root.chamfer; y: bgShape.height }
            PathLine { x: 0; y: bgShape.height - root.chamfer }
            PathLine { x: 0; y: root.chamfer }
            PathLine { x: root.chamfer; y: 0 }
        }
    }

    contentItem: Item {
        anchors.fill: parent
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            spacing: root.buttonSpacing

            FluentIcon {
                Layout.alignment: Qt.AlignVCenter
                icon: "search-visual"
                implicitSize: 15
                color: root.fgColor
            }

            WText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                text: root.text
                font: root.font
                color: root.fgColor
                horizontalAlignment: Text.AlignLeft
            }

            SearchHighlightsOrb {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 2
            }
        }
    }

    // Gleam: a light band that periodically sweeps across the box
    Rectangle {
        id: gleamClip
        anchors.fill: parent
        color: "transparent"
        clip: true
        z: 2
        visible: root.enabled

        Rectangle {
            id: band
            width: gleamClip.width * 0.55
            height: gleamClip.height * 2.4
            x: -gleamClip.width * 0.7
            y: -gleamClip.height * 0.8
            rotation: -18
            opacity: 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.30) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: -gleamClip.width * 0.7; to: gleamClip.width * 1.35; duration: 850 }
                NumberAnimation { to: -gleamClip.width * 0.7; duration: 1 }
                PauseAnimation { duration: 3600 }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: 0; to: 0.9; duration: 150 }
                PauseAnimation { duration: 650 }
                NumberAnimation { to: 0; duration: 250 }
                PauseAnimation { duration: 3450 }
            }
        }
    }

    BarToolTip {
        id: tooltip
        text: Translation.tr("Search")
        extraVisibleCondition: root.shouldShowTooltip
    }

    // Search Highlights orb: a colorful globe that always rotates
    component SearchHighlightsOrb: Item {
        id: orb
        implicitWidth: 16
        implicitHeight: 16

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                var size = width;
                var r = size / 2;
                var cx = r;
                var cy = r;
                ctx.clearRect(0, 0, size, size);

                var segs = 18;
                for (var i = 0; i < segs; i++) {
                    var a0 = (i / segs) * 2 * Math.PI;
                    var a1 = ((i + 1) / segs) * 2 * Math.PI;
                    var t = i / segs;
                    ctx.fillStyle = Qt.hsla(t, 0.75, 0.55, 1);
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, r, a0, a1);
                    ctx.closePath();
                    ctx.fill();
                }

                var gloss = ctx.createRadialGradient(cx - r * 0.35, cy - r * 0.4, r * 0.05, cx, cy, r * 1.05);
                gloss.addColorStop(0, Qt.rgba(1, 1, 1, 0.9));
                gloss.addColorStop(0.3, Qt.rgba(1, 1, 1, 0.3));
                gloss.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                ctx.fillStyle = gloss;
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fill();

                var shade = ctx.createRadialGradient(cx - r * 0.2, cy - r * 0.2, r * 0.4, cx, cy, r * 1.1);
                shade.addColorStop(0, Qt.rgba(0, 0, 0, 0));
                shade.addColorStop(1, Qt.rgba(0, 0, 0, 0.35));
                ctx.fillStyle = shade;
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fill();
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        rotation: 0
        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 2600
            loops: Animation.Infinite
            running: true
        }
    }
}
