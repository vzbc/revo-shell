import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Item {
    id: barRoot

    property string password: ""
    property var shapeItems: []
    property bool isAuthenticating: false
    property bool isError: false
    property bool isSuccess: false
    property bool capsLockActive: false
    property string placeholderText: "Enter password..."
    property string paletteMode: Config.lockscreenShapePalette || "vibrant"
    property string maskStyle: Config.lockscreenMaskStyle || "shapes"

    signal submitPassword(string pass)
    signal clearRequested()

    implicitWidth: 440
    implicitHeight: 58

    onIsErrorChanged: {
        if (isError) shakeAnimation.restart()
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: shakeContainer; property: "x"; to: -14; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 14; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -5; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 5; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
    }

    Item {
        id: shakeContainer
        anchors.fill: parent

        // Outer Glow
        RectangularGlow {
            anchors.fill: barBg
            glowRadius: barRoot.isError ? 16 : (barRoot.isSuccess ? 18 : 10)
            spread: 0.2
            color: barRoot.isError 
                ? Qt.rgba(239/255, 68/255, 68/255, 0.6) 
                : (barRoot.isSuccess 
                    ? Qt.rgba(16/255, 185/255, 129/255, 0.7) 
                    : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3))
            cornerRadius: barBg.radius
            visible: Config.clockShowGlow !== false

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on glowRadius { NumberAnimation { duration: 200 } }
        }

        // Main Bar Surface
        Rectangle {
            id: barBg
            anchors.fill: parent
            radius: 29
            color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.72)
            border.width: 1.5
            border.color: barRoot.isError 
                ? "#ef4444" 
                : (barRoot.isSuccess 
                    ? "#10b981" 
                    : (barRoot.password.length > 0 ? Config.accent : Qt.rgba(255, 255, 255, 0.15)))

            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 10
                spacing: 10

                // Leading Icon
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    color: barRoot.isError 
                        ? Qt.rgba(239/255, 68/255, 68/255, 0.18) 
                        : (barRoot.isSuccess 
                            ? Qt.rgba(16/255, 185/255, 129/255, 0.2) 
                            : Qt.rgba(255, 255, 255, 0.08))

                    Text {
                        anchors.centerIn: parent
                        text: barRoot.isSuccess ? "lock_open" : (barRoot.isError ? "lock_reset" : "lock")
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: barRoot.isError ? "#ef4444" : (barRoot.isSuccess ? "#10b981" : Config.accent)

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Center Glyph Container
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Placeholder Text
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        visible: barRoot.password.length === 0
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 2
                            implicitHeight: 20
                            radius: 1
                            color: Config.accent

                            SequentialAnimation on opacity {
                                running: barRoot.password.length === 0
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.0; duration: 530; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.0; to: 1.0; duration: 530; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: barRoot.placeholderText
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.italic: true
                            opacity: 0.7
                        }
                    }

                    // Shapes Flow
                    Flickable {
                        id: shapesFlickable
                        anchors.fill: parent
                        contentWidth: shapesRow.width
                        contentHeight: parent.height
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: shapesRow.width > shapesFlickable.width
                        clip: true

                        Row {
                            id: shapesRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Repeater {
                                model: barRoot.shapeItems

                                delegate: LockscreenShapeGlyph {
                                    shapeIndex: modelData.shapeIndex !== undefined ? modelData.shapeIndex : 0
                                    shapeColor: modelData.color !== undefined ? modelData.color : Config.accent
                                    targetRotation: modelData.rotation !== undefined ? modelData.rotation : 0
                                    isOutline: modelData.isOutline !== undefined ? modelData.isOutline : false
                                    charGlyph: modelData.charGlyph !== undefined ? modelData.charGlyph : "*"
                                    maskStyle: modelData.maskStyle !== undefined ? modelData.maskStyle : barRoot.maskStyle
                                    isError: barRoot.isError
                                    isSuccess: barRoot.isSuccess
                                    isAuthenticating: barRoot.isAuthenticating
                                    animIndex: index
                                }
                            }

                            onWidthChanged: {
                                if (width > shapesFlickable.width) {
                                    shapesFlickable.contentX = width - shapesFlickable.width
                                } else {
                                    shapesFlickable.contentX = 0
                                }
                            }
                        }
                    }
                }

                // CAPS LOCK BADGE
                Rectangle {
                    visible: barRoot.capsLockActive
                    implicitWidth: capsRow.implicitWidth + 12
                    implicitHeight: 26
                    radius: 13
                    color: Qt.rgba(245/255, 158/255, 11/255, 0.2)
                    border.width: 1
                    border.color: "#f59e0b"

                    RowLayout {
                        id: capsRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "arrow_upward"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#f59e0b"
                        }

                        Text {
                            text: "CAPS"
                            font.family: Config.sysFont
                            font.pixelSize: 10
                            font.bold: true
                            color: "#f59e0b"
                        }
                    }
                }

                // CLEAR (X) BUTTON
                Rectangle {
                    id: clearBtn
                    visible: barRoot.password.length > 0 && !barRoot.isAuthenticating
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: clearMouse.containsMouse ? Qt.rgba(239/255, 68/255, 68/255, 0.2) : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "cancel"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: clearMouse.containsMouse ? "#ef4444" : Config.textMuted

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barRoot.clearRequested()
                    }
                }

                // SUBMIT BUTTON
                Rectangle {
                    id: submitBtn
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 20
                    color: submitMouse.containsMouse 
                        ? Config.accent 
                        : (barRoot.password.length > 0 ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Qt.rgba(255, 255, 255, 0.08))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Item {
                        anchors.centerIn: parent
                        width: 24
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            visible: barRoot.isAuthenticating
                            text: "progress_activity"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Config.bgBase

                            RotationAnimation on rotation {
                                running: barRoot.isAuthenticating
                                from: 0
                                to: 360
                                duration: 800
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !barRoot.isAuthenticating
                            text: "arrow_forward"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            font.bold: true
                            color: barRoot.password.length > 0 ? Config.bgBase : Config.textMuted
                        }
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (barRoot.password.length > 0 && !barRoot.isAuthenticating) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: barRoot.password.length > 0 && !barRoot.isAuthenticating
                        onClicked: barRoot.submitPassword(barRoot.password)
                    }
                }
            }
        }
    }
}