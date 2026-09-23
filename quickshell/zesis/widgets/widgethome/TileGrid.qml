pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../music"
import "../notifications"
import "../sound"
import "../config"
import "../network"
import "../home"
import "../storage"
import "../../"

Item {
    id: root
    signal widgetRequested(int index, string title)

    property int selectedRow: -1
    property int selectedCol: -1
    readonly property bool anySelected: selectedRow !== -1
    onAnySelectedChanged: WidgetHomeService.anySelected = anySelected

    readonly property real pad: Math.round(20 * UIScale.value)
    readonly property real colGap: Math.round(10 * UIScale.value)
    readonly property real rowGap: Math.round(10 * UIScale.value)
    readonly property real collapsedH: Math.round(52 * UIScale.value)
    readonly property real headerH: Math.round(40 * UIScale.value)
    readonly property real collapsedW: (root.width - 2 * pad - colGap) / 2
    readonly property real expandedW: root.width - 2 * pad
    readonly property real expandedH: contentArea.height

    // Each entry: [label, icon codepoint (Material Icons), widgetIndex]
    readonly property var layout: [[[I18n.t("widgethome.music"), "", 0], [I18n.t("widgethome.notifs"), "", 1]], [[I18n.t("widgethome.sound"), "", 2], [I18n.t("widgethome.scale"), "", 3]], [[I18n.t("widgethome.network"), "", 4], [I18n.t("widgethome.storage"), "", 5]]]

    readonly property var widgetComponents: [musicComp, notifComp, soundComp, configComp, networkComp, storageComp]
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
    Component {
        id: networkComp
        NetworkTile {}
    }
    Component {
        id: storageComp
        Storage {}
    }

    // Header
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: UIScale.spacingMd
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: Math.round(40 * UIScale.value)
        opacity: root.anySelected ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: Anim.fast
            }
        }

        Text {
            text: I18n.t("widgethome.title")
            color: Colors.text
            font.bold: true
            font.pixelSize: UIScale.fontLead
        }

        Item {
            Layout.fillWidth: true
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            MouseArea {
                id: expandMouseAreaBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    WidgetHomeService.open = false;
                    HomePanelService.open = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Material Icons"
                font.pixelSize: Math.round((expandMouseAreaBtn.containsMouse ? 20 : 16) * UIScale.value)
                color: expandMouseAreaBtn.containsMouse ? Colors.accent : Colors.muted
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on font.pixelSize {
                    NumberAnimation {
                        duration: Anim.fast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            MouseArea {
                id: xMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WidgetHomeService.open = false
            }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: xMouseArea.containsMouse ? Colors.accent : Colors.muted
                font.pixelSize: Math.round((xMouseArea.containsMouse ? 20 : 16) * UIScale.value)
                scale: xMouseArea.containsMouse ? 1.15 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on font.pixelSize {
                    NumberAnimation {
                        duration: Anim.fast
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Anim.fast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Rectangle {
        id: separator
        anchors.top: header.bottom
        anchors.topMargin: UIScale.spacingMd
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: 1
        color: Colors.withAlpha(Colors.accent, 0.12)
        opacity: root.anySelected ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: Anim.fast
            }
        }
    }

    // Measures available height, expandedH binds to this
    Item {
        id: contentArea
        anchors.top: separator.bottom
        anchors.topMargin: UIScale.spacingMd
        anchors.bottom: parent.bottom
        anchors.bottomMargin: UIScale.spacingMd
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedW

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.anySelected ? 0 : root.rowGap

            Behavior on spacing {
                NumberAnimation {
                    duration: Anim.morph
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.spatial
                }
            }

            Repeater {
                model: root.layout

                delegate: Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    readonly property bool isThisRowSelected: root.selectedRow === rowItem.index
                    readonly property real rowCollapsedW: {
                        var n = rowItem.modelData.length;
                        return n > 0 ? (root.expandedW - (n - 1) * root.colGap) / n : root.expandedW;
                    }

                    width: root.expandedW
                    height: isThisRowSelected ? root.expandedH : (root.anySelected ? 0 : root.collapsedH)
                    opacity: root.anySelected && !isThisRowSelected ? 0 : 1

                    Behavior on height {
                        NumberAnimation {
                            duration: Anim.morph
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.spatial
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: root.anySelected ? 0 : root.colGap

                        Behavior on spacing {
                            NumberAnimation {
                                duration: Anim.morph
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Anim.spatial
                            }
                        }

                        Repeater {
                            model: rowItem.modelData

                            delegate: Item {
                                id: btn
                                required property var modelData
                                required property int index

                                readonly property string label: btn.modelData[0]
                                readonly property string icon: btn.modelData[1]
                                readonly property int widgetIndex: btn.modelData[2]
                                readonly property bool isSelected: root.selectedRow === rowItem.index && root.selectedCol === btn.index
                                readonly property bool siblingSelected: rowItem.isThisRowSelected && !isSelected

                                width: isSelected ? root.expandedW : (root.anySelected ? 0 : rowItem.rowCollapsedW)
                                height: isSelected ? root.expandedH : root.collapsedH
                                property real _siblingOpacity: siblingSelected ? 0.0 : 1.0
                                Behavior on _siblingOpacity {
                                    NumberAnimation {
                                        duration: Anim.fast
                                    }
                                }
                                property real _introOpacity: 1.0
                                opacity: Math.min(_siblingOpacity, _introOpacity)
                                property real _introY: 0.0
                                transform: Translate {
                                    y: btn._introY
                                }
                                clip: true

                                SequentialAnimation {
                                    id: introAnim
                                    PauseAnimation {
                                        duration: (rowItem.index * 2 + btn.index) * 60
                                    }
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: btn
                                            property: "_introOpacity"
                                            from: 0.0
                                            to: 1.0
                                            duration: Anim.medium
                                        }
                                        NumberAnimation {
                                            target: btn
                                            property: "_introY"
                                            from: 10.0
                                            to: 0.0
                                            duration: Anim.slow
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.emphasizedDecel
                                        }
                                    }
                                }

                                readonly property bool _panelOpen: WidgetHomeService.open
                                on_PanelOpenChanged: {
                                    if (_panelOpen) {
                                        btn._introOpacity = 0.0;
                                        btn._introY = 10.0;
                                        introAnim.restart();
                                    }
                                }

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Anim.morph
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Anim.spatial
                                    }
                                }
                                Behavior on height {
                                    NumberAnimation {
                                        duration: Anim.morph
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Anim.spatial
                                    }
                                }
                                Rectangle {
                                    id: pill
                                    anchors.centerIn: parent
                                    width: btn.isSelected ? root.expandedW : (root.anySelected ? 0 : rowItem.rowCollapsedW)
                                    height: btn.isSelected ? root.expandedH : (root.anySelected ? 0 : root.collapsedH)
                                    radius: btn.isSelected ? UIScale.radiusLg : root.collapsedH / 2
                                    topLeftRadius: btn.isSelected ? 0 : root.collapsedH / 2
                                    topRightRadius: btn.isSelected ? 0 : root.collapsedH / 2
                                    color: btn.isSelected ? Colors.bg : Colors.accent
                                    border.color: btn.isSelected ? Colors.outline : "transparent"
                                    border.width: 1
                                    clip: true
                                    scale: !btn.isSelected && expandMouseArea.containsMouse ? 1.06 : 1.0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Anim.fast
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Anim.morph
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.spatial
                                        }
                                    }
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: Anim.morph
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.spatial
                                        }
                                    }
                                    Behavior on radius {
                                        NumberAnimation {
                                            duration: Anim.morph
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.spatialFast
                                        }
                                    }
                                    Behavior on topLeftRadius {
                                        NumberAnimation {
                                            duration: Anim.morph
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.spatialFast
                                        }
                                    }
                                    Behavior on topRightRadius {
                                        NumberAnimation {
                                            duration: Anim.morph
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Anim.spatialFast
                                        }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: Anim.morph
                                        }
                                    }

                                    // Expand (collapsed state)
                                    MouseArea {
                                        id: expandMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !btn.isSelected
                                        onClicked: {
                                            root.selectedRow = rowItem.index;
                                            root.selectedCol = btn.index;
                                        }
                                    }

                                    // Collapse (expanded state), border ring, sits under the Loader.
                                    // Must be MouseArea (not TapHandler) so child MouseAreas in the
                                    // widget content can consume interior events and block this.
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: btn.isSelected
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedRow = -1;
                                            root.selectedCol = -1;
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "white"
                                        opacity: expandMouseArea.containsMouse ? 0.08 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    // Orange header strip, own radius rounds the top corners,
                                    // inner rect fills the bottom curves to keep the bottom edge flat.
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: root.headerH
                                        radius: Math.round(16 * UIScale.value)
                                        color: Colors.accent
                                        visible: btn.isSelected

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: Math.round(16 * UIScale.value)
                                            color: Colors.accent
                                        }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: UIScale.spacingMd
                                            spacing: UIScale.spacingSm

                                            Text {
                                                text: btn.icon
                                                color: Colors.bg
                                                font.family: "Material Icons"
                                                font.pixelSize: Math.round(19 * UIScale.value)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: btn.label
                                                color: Colors.bg
                                                font.pixelSize: UIScale.fontBody
                                                font.weight: Font.Medium
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    // Icon + label, hidden once expanded
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: UIScale.spacingSm
                                        opacity: btn.isSelected ? 0 : 1
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            text: btn.icon
                                            color: Colors.bg
                                            font.family: "Material Icons"
                                            font.pixelSize: Math.round(20 * UIScale.value)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: btn.label
                                            color: Colors.bg
                                            font.pixelSize: UIScale.fontBody
                                            font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Absorbs any interior clicks that fall through transparent
                                    // areas of the widget content, so the collapse MouseArea below
                                    // never fires inside the content region.
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.topMargin: root.headerH
                                        enabled: btn.isSelected
                                    }

                                    // Widget content, declared last for highest event priority.
                                    // Only top margin exposes the collapse strip; left/right/bottom flush.
                                    Loader {
                                        anchors.fill: parent
                                        anchors.topMargin: root.headerH
                                        active: btn.isSelected
                                        sourceComponent: btn.isSelected ? root.widgetComponents[btn.widgetIndex] : null
                                        opacity: btn.isSelected ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.medium
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
