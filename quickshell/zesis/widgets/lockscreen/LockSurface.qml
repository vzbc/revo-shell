pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../../"
import "../shared"
import "../user"

WlSessionLockSurface {
    id: surface

    required property WlSessionLock lock

    property string inputBuffer: ""
    property bool authError: false
    property bool unlocking: false
    property real _vx: 0
    property real _vy: 0
    property string _roastMessage: ""

    color: Colors.bg

    Item {
        id: fadeRoot
        anchors.fill: parent
        opacity: 0

        NumberAnimation on opacity {
            to: 1
            duration: 500
            easing.type: Easing.OutCubic
            running: true
        }

        Image {
            anchors.fill: parent
            source: ThemeState.lastWallpaper !== "" ? ("file://" + ThemeState.lastWallpaper) : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                autoPaddingEnabled: false
            }
        }

        // Dark scrim
        Rectangle {
            anchors.fill: parent
            color: Colors.bg
            opacity: 0.5
        }

        Item {
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (surface.unlocking || pam.active)
                    return;
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (surface.inputBuffer === "please") {
                        surface._roastMessage = I18n.t("lockscreen.roastNo");
                        surface.inputBuffer = "";
                        roastTimer.restart();
                        return;
                    }
                    if (surface.inputBuffer === "password") {
                        surface._roastMessage = I18n.t("lockscreen.roastSeriously");
                        surface.inputBuffer = "";
                        roastTimer.restart();
                        return;
                    }
                    if (surface.inputBuffer.length > 0)
                        pam.start();
                    return;
                }
                if (event.key === Qt.Key_Backspace) {
                    if (event.modifiers & Qt.ControlModifier)
                        surface.inputBuffer = "";
                    else
                        surface.inputBuffer = surface.inputBuffer.slice(0, -1);
                    return;
                }
                if (event.text && event.text.length > 0)
                    surface.inputBuffer += event.text;
            }
        }

        Pendant {
            id: pendant
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: Math.round(clockDial._stringLen * 0.6)
            height: clockDial.y + Math.round(40 * UIScale.value)
            z: 0

            endX: clockDial._dropX
            endY: clockDial.y + clockDial._dropY + clockDial._attachY

            opacity: clockDial.spinClicks >= 7 ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }

        HangingChain {
            x: parent.width / 2 - Math.round(290 * UIScale.value) - width / 2
            y: 0
            z: 0
            topGap: 110
            rings: [
                {
                    r: 58,
                    gap: 0
                },
                {
                    r: 28,
                    gap: 18
                }
            ]
        }

        HangingChain {
            x: parent.width / 2 + Math.round(268 * UIScale.value) - width / 2
            y: 0
            z: 0
            topGap: 90
            rings: [
                {
                    r: 26,
                    gap: 0
                },
                {
                    r: 15,
                    gap: 14
                },
                {
                    r: 15,
                    gap: 14
                }
            ]
        }

        // Decorative rosette, top-centre, behind the greeting
        Rosette {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            z: 0
            outerRadius: 160
            spokes: 18
            rings: 4
            halfCircle: true
            alpha: 0.14
        }

        Item {
            id: greetingSection
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - Math.round(396 * UIScale.value) - height - Math.round(24 * UIScale.value)
            width: Math.round(300 * UIScale.value)
            height: greetingCol.implicitHeight

            Column {
                id: greetingCol
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(10 * UIScale.value)

                UserAvatar {
                    size: Math.round(64 * UIScale.value)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var h = new Date().getHours();
                        var g = h < 12 ? I18n.t("lockscreen.goodMorning") : h < 17 ? I18n.t("lockscreen.goodAfternoon") : I18n.t("lockscreen.goodEvening");
                        return UserService.name !== "" ? g + ", " + UserService.name : g;
                    }
                    color: Colors.text
                    font.pixelSize: UIScale.fontSubhead
                    font.weight: Font.DemiBold
                    opacity: 0.88
                }
            }
        }

        ClockDial {
            id: clockDial
            x: (parent.width - width) / 2
            y: parent.height / 2 - Math.round(396 * UIScale.value)
            discRadius: Math.round(240 * UIScale.value)
            alwaysExpanded: true
            unlocking: surface.unlocking
            opacity: _dropStarted ? 1 : 0

            readonly property real _stringLen: clockDial.y
            readonly property real _attachY: Math.round(30 * UIScale.value)
            property real _dropX: 0
            property real _dropY: 0
            property real _prevX: 0
            property real _prevY: 0
            property bool _dropSettled: true
            property bool _stringTaut: false
            property int _dropTick: 0
            property bool _dropStarted: false

            transform: [
                Rotation {
                    origin.x: clockDial.width / 2
                    origin.y: clockDial._attachY
                    angle: clockDial._stringTaut ? Math.atan2(-clockDial._dropX, clockDial._dropY + clockDial._stringLen) * 180 / Math.PI : 0
                },
                Translate {
                    x: clockDial._dropX
                    y: clockDial._dropY
                }
            ]

            function maybeStartDrop() {
                if (clockDial._dropStarted || surface.width <= 0 || surface.height <= 0)
                    return;
                clockDial._dropStarted = true;

                var jitter = (Math.random() * 2 - 1) * clockDial._stringLen * 0.2;
                clockDial._dropX = jitter;
                clockDial._dropY = -clockDial._stringLen - clockDial.height;
                clockDial._prevX = clockDial._dropX;
                clockDial._prevY = clockDial._dropY;
                clockDial._dropTick = 0;
                clockDial._dropSettled = false;
                clockDial._stringTaut = false;
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: clockDial.maybeStartDrop()
            }

            onSpinClicksChanged: {
                if (spinClicks === 7) {
                    surface._vx = (Math.random() > 0.5 ? 1 : -1) * (6 + Math.random() * 4);
                    surface._vy = -(14 + Math.random() * 6);
                    clockDial._spinStep *= 3;
                }
            }
        }

        Rectangle {
            id: inputPill
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + Math.round(152 * UIScale.value)
            width: Math.round(260 * UIScale.value)
            height: Math.round(44 * UIScale.value)
            radius: height / 2
            color: surface.authError ? Colors.withAlpha("#d05555", 0.25) : pam.active ? Colors.withAlpha(Colors.accent, 0.12) : Colors.withAlpha(Colors.surface, 0.9)
            border.color: surface.authError ? "#d05555" : pam.active ? Colors.withAlpha(Colors.accent, 0.7) : Colors.withAlpha(Colors.accent, 0.35)
            border.width: 1.5

            Behavior on color {
                ColorAnimation {
                    duration: Anim.medium
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: Anim.medium
                }
            }

            transform: Translate {
                id: shakeOffset
            }

            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: -7
                    duration: 45
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 7
                    duration: 45
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 0
                    duration: 45
                }
            }

            Text {
                anchors.centerIn: parent
                text: surface._roastMessage !== "" ? surface._roastMessage : surface.inputBuffer.length > 0 ? Array(Math.min(surface.inputBuffer.length, 14) + 1).join("●") : I18n.t("lockscreen.typeToUnlock")
                color: surface._roastMessage !== "" ? Colors.muted : surface.inputBuffer.length > 0 ? Colors.accent : Colors.muted
                font.pixelSize: surface._roastMessage !== "" || surface.inputBuffer.length === 0 ? UIScale.fontBody : Math.round(11 * UIScale.value * UIScale.fontScale)
                font.letterSpacing: surface._roastMessage !== "" || surface.inputBuffer.length === 0 ? 0 : Math.round(4 * UIScale.value)
                opacity: surface.unlocking ? 0 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.medium
                    }
                }
            }
        }
    } // fadeRoot

    PamContext {
        id: pam
        config: "quickshell"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(surface.inputBuffer);
                surface.inputBuffer = "";
            }
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                surface.unlocking = true;
                unlockTimer.start();
            } else {
                surface.authError = true;
                shakeAnim.start();
                errorTimer.start();
            }
        }
    }

    Timer {
        id: dropTimer
        interval: 16
        repeat: true
        running: !clockDial._dropSettled
        onTriggered: {
            var physicsTicks = 300; // fall/catch/swing
            var lerpTicks = 250; // lerp clock into place

            clockDial._dropTick++;

            if (clockDial._dropTick <= physicsTicks) {
                var L = clockDial._stringLen;
                var pivotY = -L;
                var gravity = 0.85 * UIScale.value;
                var airDamp = 0.995; // velocity retained per tick (air/pivot friction)
                var stiffness = 0.5; // fraction of overshoot corrected per tick (soft-ish string)
                var bleed = 0.75; // fraction of the correction also removed as energy loss

                var vx = (clockDial._dropX - clockDial._prevX) * airDamp;
                var vy = (clockDial._dropY - clockDial._prevY) * airDamp;

                var nx = clockDial._dropX + vx;
                var ny = clockDial._dropY + vy + gravity;

                clockDial._prevX = clockDial._dropX;
                clockDial._prevY = clockDial._dropY;
                clockDial._dropX = nx;
                clockDial._dropY = ny;

                // String constraint. Only pulls, so only correct when taut
                var rx = clockDial._dropX;
                var ry = clockDial._dropY - pivotY;
                var dist = Math.hypot(rx, ry);
                if (dist >= L)
                    clockDial._stringTaut = true;
                if (dist > L) {
                    var stretch = dist - L;
                    var nxr = rx / dist, nyr = ry / dist;
                    var corr = stretch * stiffness;
                    clockDial._dropX -= nxr * corr;
                    clockDial._dropY -= nyr * corr;
                    clockDial._prevX += nxr * corr * bleed;
                    clockDial._prevY += nyr * corr * bleed;
                }
            } else if (clockDial._dropTick <= physicsTicks + lerpTicks) {
                clockDial._dropX += (0 - clockDial._dropX) * 0.03;
                clockDial._dropY += (0 - clockDial._dropY) * 0.03;
            } else {
                clockDial._dropX = 0;
                clockDial._dropY = 0;
                clockDial._dropSettled = true;
            }
        }
    }

    Timer {
        id: roastTimer
        interval: 2000
        onTriggered: surface._roastMessage = ""
    }

    Timer {
        id: errorTimer
        interval: 1500
        onTriggered: {
            surface.authError = false;
            surface.inputBuffer = "";
        }
    }

    Timer {
        id: unlockTimer
        interval: 1300
        onTriggered: surface.lock.locked = false
    }

    Timer {
        id: beybladeTimer
        interval: 16
        repeat: true
        running: clockDial.spinClicks >= 7 && !surface.unlocking
        onTriggered: {
            var r = clockDial.discRadius;
            var grip = 0.7;
            var restitution = 0.82;
            // omega snapped once per tick; contact velocity = linear + spin tangential
            var omega = clockDial._spinStep * Math.PI / 180;
            var J, vc;

            surface._vy += 0.5;
            clockDial.x += surface._vx;
            clockDial.y += surface._vy;

            var maxX = surface.width - clockDial.width;
            var maxY = surface.height - clockDial.height;

            // floor: contact at bottom (0,+r), tangential = x
            // spin: CW bottom moves left  -> v_spin_x = -omega*r
            // torque from J_x at bottom:  Δω = -2*J/r  (rightward J -> CCW)
            if (clockDial.y > maxY) {
                clockDial.y = maxY;
                surface._vy = -Math.abs(surface._vy) * restitution;
                vc = surface._vx - omega * r;
                J = -grip * vc / 3;
                surface._vx += J;
                clockDial._spinStep -= 2 * J / r * (180 / Math.PI);
            }
            // ceiling: contact at top (0,-r), tangential = x
            // spin: CW top moves right    -> v_spin_x = +omega*r
            // torque from J_x at top:     Δω = +2*J/r
            if (clockDial.y < 0) {
                clockDial.y = 0;
                surface._vy = Math.abs(surface._vy) * restitution;
                vc = surface._vx + omega * r;
                J = -grip * vc / 3;
                surface._vx += J;
                clockDial._spinStep += 2 * J / r * (180 / Math.PI);
            }
            // right wall: contact at right (+r,0), tangential = y
            // spin: CW right moves down   -> v_spin_y = +omega*r
            // torque from J_y at right:   Δω = +2*J/r  (upward J -> CCW)
            if (clockDial.x > maxX) {
                clockDial.x = maxX;
                surface._vx = -Math.abs(surface._vx);
                vc = surface._vy + omega * r;
                J = -grip * vc / 3;
                surface._vy += J;
                clockDial._spinStep += 2 * J / r * (180 / Math.PI);
            }
            // left wall: contact at left (-r,0), tangential = y
            // spin: CW left moves up      -> v_spin_y = -omega*r
            // torque from J_y at left:    Δω = -2*J/r
            if (clockDial.x < 0) {
                clockDial.x = 0;
                surface._vx = Math.abs(surface._vx);
                vc = surface._vy - omega * r;
                J = -grip * vc / 3;
                surface._vy += J;
                clockDial._spinStep -= 2 * J / r * (180 / Math.PI);
            }
        }
    }
}
