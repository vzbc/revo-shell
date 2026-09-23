// Sidebar.qml - Always-visible project sidebar (shadcn Sidebar style → QML, English)
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool collapsed: false
    property int currentStage: 0
    property int stageCount: 5
    property var stageNames: [
        "Welcome",
        "Repository",
        "Shells",
        "Install",
        "Done"
    ]

    signal stageSelected(int index)
    signal toggleCollapse()

    width: collapsed ? 64 : 260
    color: "#0A0A0A"
    border.color: "#1A1A1A"
    border.width: 1

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: "#FFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: "R"
                    font.family: "SF Pro Display"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#000000"
                }
            }

            Text {
                visible: !root.collapsed
                text: "Revo Installer"
                font.family: "SF Pro Display"
                font.pixelSize: 15
                font.bold: true
                color: "#FFFFFF"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                visible: !root.collapsed
                width: 28
                height: 28
                radius: 6
                color: collapseHover.containsMouse ? "#1A1A1A" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "«"
                    font.family: "SF Pro Display"
                    font.pixelSize: 14
                    color: "#888888"
                }

                MouseArea {
                    id: collapseHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleCollapse()
                }
            }
        }

        Item { Layout.preferredHeight: 20 }

        // Stage label
        Text {
            visible: !root.collapsed
            text: "STAGES"
            font.family: "SF Pro Display"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: "#555555"
            Layout.leftMargin: 8
            Layout.bottomMargin: 8
            Layout.fillWidth: true
        }

        // Stage items
        Repeater {
            model: root.stageCount

            delegate: Rectangle {
                id: item
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 8
                color: item.index === root.currentStage ? "#161616"
                     : itemHover.containsMouse ? "#111111" : "transparent"
                border.width: item.index === root.currentStage ? 1 : 0
                border.color: "#222222"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    // Step indicator
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: item.index < root.currentStage ? "#22C55E"
                             : item.index === root.currentStage ? "#FFFFFF" : "#1A1A1A"
                        border.width: item.index > root.currentStage ? 1 : 0
                        border.color: "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: item.index < root.currentStage ? "✓" : String(item.index + 1)
                            font.family: "SF Pro Display"
                            font.pixelSize: 11
                            font.bold: true
                            color: item.index < root.currentStage ? "#000000"
                                 : item.index === root.currentStage ? "#000000" : "#666666"
                        }

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    Text {
                        visible: !root.collapsed
                        text: root.stageNames[item.index]
                        font.family: "SF Pro Display"
                        font.pixelSize: 14
                        font.weight: item.index === root.currentStage ? Font.DemiBold : Font.Normal
                        color: item.index === root.currentStage ? "#FFFFFF"
                             : item.index < root.currentStage ? "#A1A1A1" : "#666666"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: item.index <= root.currentStage
                    onClicked: root.stageSelected(item.index)
                }
            }
        }

        // Progress bar (always visible)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.topMargin: 16

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 8

                Text {
                    visible: !root.collapsed
                    text: "Progress"
                    font.family: "SF Pro Display"
                    font.pixelSize: 12
                    color: "#666666"
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#1A1A1A"

                    Rectangle {
                        width: parent.width * (root.stageCount > 0
                                               ? (root.currentStage + 1) / root.stageCount : 0)
                        height: parent.height
                        radius: 3
                        color: "#FFFFFF"

                        Behavior on width {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    visible: !root.collapsed
                    text: Math.round(((root.currentStage + 1) / root.stageCount) * 100) + "%"
                    font.family: "SF Pro Display"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#A1A1A1"
                }
            }
        }

        // Footer
        Text {
            visible: !root.collapsed
            text: "v1.0.0 · English"
            font.family: "SF Pro Display"
            font.pixelSize: 11
            color: "#444444"
            Layout.bottomMargin: 4
        }
    }

    // Expand handle when collapsed
    Rectangle {
        visible: root.collapsed
        width: 28
        height: 28
        radius: 14
        color: expandHover.containsMouse ? "#1A1A1A" : "#111111"
        border.width: 1
        border.color: "#222222"
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: -14
        z: 10

        Text {
            anchors.centerIn: parent
            text: "»"
            font.family: "SF Pro Display"
            font.pixelSize: 13
            color: "#AAAAAA"
        }

        MouseArea {
            id: expandHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleCollapse()
        }
    }
}
