pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../music"
import "../notifications"
import "../sound"
import "../config"
import "../../"

Item {
    id: root
    focus: true

    property string currentTitle: ""

    Keys.onEscapePressed: {
        if (stack.depth > 1)
            stack.pop();
        else
            WidgetHomeService.open = false;
    }

    function widgetComponent(index) {
        return [musicComp, notifComp, soundComp, configComp][index];
    }

    // Back header, floats over the stack, fades in when a widget is open
    RowLayout {
        id: backHeader
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: UIScale.spacingSm
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: Math.round(40 * UIScale.value)
        opacity: stack.depth > 1 ? 1 : 0
        enabled: stack.depth > 1
        Behavior on opacity {
            NumberAnimation {
                duration: Anim.fast
            }
        }

        Text {
            text: "<"
            color: backHover.hovered ? Colors.accent : Colors.muted
            font.pixelSize: UIScale.fontTitle
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            HoverHandler {
                id: backHover
            }
            MouseArea {
                anchors.fill: parent
                onClicked: stack.pop()
            }
        }

        Text {
            text: root.currentTitle
            color: Colors.text
            font.bold: true
            font.pixelSize: UIScale.fontBody
            leftPadding: UIScale.spacingSm
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        clip: true

        // Push: new view slides in from right + fades up
        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 40
                    to: 0
                    duration: Anim.medium
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.emphasizedDecel
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Anim.fast
                }
            }
        }
        // Push: old view exits to the left
        pushExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: -40
                    duration: Anim.medium
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.emphasizedAccel
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Anim.fast
                }
            }
        }
        // Pop: tile grid slides back in from the left
        popEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: -40
                    to: 0
                    duration: Anim.medium
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.emphasizedDecel
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Anim.fast
                }
            }
        }
        // Pop: widget exits to the right
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: 40
                    duration: Anim.medium
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.emphasizedAccel
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Anim.fast
                }
            }
        }

        initialItem: TileGrid {
            onWidgetRequested: function (index, title) {
                root.currentTitle = title;
                stack.push(widgetPage, {
                    "widgetComp": root.widgetComponent(index)
                });
            }
        }
    }

    // Wrapper that offsets widget content below the back header.
    // Outer Item has NO anchors so StackView can animate its x freely.
    Component {
        id: widgetPage
        Item {
            id: pageRoot
            required property Component widgetComp

            Loader {
                anchors.fill: parent
                anchors.topMargin: Math.round(48 * UIScale.value)
                sourceComponent: pageRoot.widgetComp
            }
        }
    }

    Component {
        id: musicComp
        MusicController {}
    }
    Component {
        id: notifComp
        NotifHistory {}
    }
    Component {
        id: soundComp
        Sound {}
    }
    Component {
        id: configComp
        Config {}
    }
}
