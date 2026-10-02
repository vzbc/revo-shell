import QtQuick

Item {
    id: row

    property string title: ""
    property string iconFile: ""
    property string appName: ""
    property bool separator: false
    property bool showSwitch: false
    property bool switchOn: false
    property bool showPicker: false
    property string pickerValue: ""
    property var pickerOptions: []
    property bool showButton: false
    property string buttonLabel: ""
    property bool showInfo: false
    property bool chevron: false

    signal clicked
    signal toggled(bool checked)
    signal pickerAccepted(string value)
    signal buttonClicked
    signal infoClicked

    x: 0
    width: parent ? parent.width : 100
    height: Theme.detailRowHeight

    Rectangle {
        visible: row.separator
        anchors.top: parent.top
        x: 27
        width: parent.width - 39
        height: 1
        color: Theme.separator
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    Image {
        visible: row.iconFile.length > 0 && row.appName.length === 0
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        source: Theme.icon(row.iconFile, 24)
        width: 24
        height: 24
        asynchronous: true
        mipmap: true
    }

    AppTile {
        visible: row.appName.length > 0
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        label: row.appName
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 57
        anchors.verticalCenter: parent.verticalCenter
        text: row.title.length > 0 ? row.title : row.appName
        font.family: Theme.fontText
        font.pixelSize: 13
        color: Theme.textPrimary
    }

    Canvas {
        id: chev
        visible: row.chevron
        x: parent.width - 19
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 12

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = "#B4B4B8"
            ctx.lineWidth = 1.4
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(0.7, 1)
            ctx.lineTo(5.5, 6)
            ctx.lineTo(0.7, 11)
            ctx.stroke()
        }

        Component.onCompleted: requestPaint()
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BlueLink {
            visible: row.showButton
            anchors.verticalCenter: parent.verticalCenter
            label: row.buttonLabel
            onClicked: row.buttonClicked()
        }

        MacPicker {
            visible: row.showPicker
            anchors.verticalCenter: parent.verticalCenter
            value: row.pickerValue
            options: row.pickerOptions
            onAccepted: (v) => row.pickerAccepted(v)
        }

        MacToggle {
            visible: row.showSwitch
            anchors.verticalCenter: parent.verticalCenter
            checked: row.switchOn
            onToggled: (checked) => row.toggled(checked)
        }

        InfoDot {
            visible: row.showInfo
            anchors.verticalCenter: parent.verticalCenter
            onClicked: row.infoClicked()
        }
    }
}
