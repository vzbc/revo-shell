pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../"

ComboBox {
    id: root

    property var selectedValue
    property real popupWidth: 0
    signal chosen(var value)

    textRole: "label"
    valueRole: "value"

    function _syncIndex() {
        for (var i = 0; i < root.model.length; i++) {
            if (root.model[i].value === root.selectedValue) {
                root.currentIndex = i;
                return;
            }
        }
        root.currentIndex = -1;
    }

    Component.onCompleted: _syncIndex()
    onModelChanged: _syncIndex()
    onSelectedValueChanged: _syncIndex()

    onActivated: index => root.chosen(root.model[index].value)

    padding: 0

    implicitHeight: Math.round(32 * UIScale.value)
    implicitWidth: labelMetrics.width + indicator.implicitWidth + UIScale.spacingSm * 3

    TextMetrics {
        id: labelMetrics
        font.pixelSize: UIScale.fontBody
        text: root.displayText
    }

    FontMetrics {
        id: rowFontMetrics
        font.pixelSize: UIScale.fontBody
    }

    readonly property real _maxLabelWidth: {
        var max = 0;
        for (var i = 0; i < root.model.length; i++) {
            var w = rowFontMetrics.advanceWidth(root.model[i].label);
            if (w > max)
                max = w;
        }
        return max;
    }

    background: Rectangle {
        radius: UIScale.spacingSm
        color: Colors.surface

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.accent
            opacity: root.down ? 0.12 : (root.hovered ? 0.08 : 0)
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.standard
                }
            }
        }
    }

    indicator: Text {
        x: root.width - width - UIScale.spacingSm
        y: root.height / 2 - height / 2
        text: "▾"
        color: Colors.textDim
        font.pixelSize: UIScale.fontTiny
        rotation: root.popup.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
    }

    contentItem: Text {
        leftPadding: UIScale.spacingSm
        rightPadding: root.indicator.width + UIScale.spacingSm
        text: root.displayText
        color: Colors.text
        font.pixelSize: UIScale.fontBody
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    delegate: ItemDelegate {
        id: itemDelegate
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: Math.round(32 * UIScale.value)

        padding: 0

        highlighted: root.highlightedIndex === itemDelegate.index

        background: Rectangle {
            radius: UIScale.spacingSm
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.accent
                opacity: root.currentIndex === itemDelegate.index ? 0.15 : (itemDelegate.hovered ? 0.08 : 0)
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Anim.standard
                    }
                }
            }
        }

        contentItem: Text {
            leftPadding: UIScale.spacingSm
            rightPadding: UIScale.spacingSm
            text: itemDelegate.modelData.label
            color: root.currentIndex === itemDelegate.index ? Colors.accent : Colors.text
            font.pixelSize: UIScale.fontBody
            font.weight: root.currentIndex === itemDelegate.index ? Font.Medium : Font.Normal
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    popup: Popup {
        y: root.height + UIScale.spacingXs
        width: Math.max(root.width, root.popupWidth, root._maxLabelWidth + UIScale.spacingSm * 2)
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }

        background: Rectangle {
            radius: UIScale.radiusMd
            color: Colors.surface
            border.color: Colors.withAlpha(Colors.outline, 0.6)
            border.width: 1
        }

        contentItem: ListView {
            clip: true
            width: root.popup.availableWidth
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
}
