// MorphingText.qml - Words morph into each other (Magic UI MorphingText → QML)
import QtQuick

Item {
    id: root

    property var texts: []
    property int intervalMs: 2200
    property int morphMs: 500
    property int pixelSize: 56
    property color color: "#FFFFFF"
    property bool bold: true
    property int currentIndex: 0
    property bool running: true

    readonly property string currentText: texts.length > 0
                                          ? texts[currentIndex % texts.length] : ""

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: root.currentText
        font.pixelSize: root.pixelSize
        font.family: "SF Pro Display"
        font.bold: root.bold
        color: root.color
        opacity: 1
        scale: 1

        Behavior on text {
            enabled: false
        }

        SequentialAnimation on opacity {
            id: morphOut
            running: false
            NumberAnimation { to: 0; duration: root.morphMs / 2; easing.type: Easing.InCubic }
            ScriptAction {
                script: {
                    root.currentIndex++
                    morphIn.restart()
                }
            }
        }

        SequentialAnimation {
            id: morphIn
            NumberAnimation {
                target: label
                property: "opacity"
                from: 0
                to: 1
                duration: root.morphMs / 2
                easing.type: Easing.OutCubic
            }
            ParallelAnimation {
                NumberAnimation {
                    target: label
                    property: "scale"
                    from: 0.92
                    to: 1
                    duration: root.morphMs / 2
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
        }
    }

    Timer {
        interval: root.intervalMs
        repeat: true
        running: root.running && root.texts.length > 1
        onTriggered: morphOut.restart()
    }

    Component.onCompleted: {
        if (texts.length > 0)
            currentIndex = 0
    }
}
