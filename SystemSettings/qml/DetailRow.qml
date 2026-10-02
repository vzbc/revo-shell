import QtQuick

Item {
    id: row

    property string title: ""
    property string subtitle: ""
    property string iconFile: ""
    property string value: ""
    property bool chevron: false
    property bool separator: false
    property bool showSwitch: false
    property bool switchOn: false
    property bool showInfo: false
    property color titleColor: Theme.textPrimary
    property bool dimmed: false
    property var pickerOptions: []
    property bool isSlider: false
    property real sliderValue: 0
    property real sliderMax: 1

    signal clicked
    signal toggled(bool checked)
    signal infoClicked
    signal picked(string value)
    signal moved(real value)

    x: 0
    width: parent ? parent.width : 100
    height: subtitle.length > 0 ? 62 : Theme.detailRowHeight

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
        cursorShape: row.chevron || row.showSwitch ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    Image {
        id: icon
        visible: row.iconFile.length > 0
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        source: Theme.icon(row.iconFile, 24)
        width: 24
        height: 24
        asynchronous: true
        mipmap: true
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: row.iconFile.length > 0 ? 57 : 16
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - anchors.leftMargin - (row.isSlider ? Math.max(150, parent.width * 0.42) + 34 : (row.pickerOptions.length > 0 ? 130 : 70))
        spacing: 2

        Text {
            text: row.title
            font.family: Theme.fontText
            font.pixelSize: 13
            color: row.dimmed ? Theme.textSecondary : row.titleColor
        }

        Text {
            visible: row.subtitle.length > 0
            text: row.subtitle
            font.family: Theme.fontText
            font.pixelSize: 12
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    Text {
        visible: row.value.length > 0 && row.pickerOptions.length === 0 && !row.isSlider
        anchors.right: parent.right
        anchors.rightMargin: row.chevron ? 36 : 16
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        font.family: Theme.fontText
        font.pixelSize: 13
        color: Theme.textSecondary
    }

    MacPicker {
        visible: row.pickerOptions.length > 0
        anchors.right: parent.right
        anchors.rightMargin: row.chevron ? 32 : 16
        anchors.verticalCenter: parent.verticalCenter
        options: row.pickerOptions
        value: row.value
        pill: true
        onAccepted: (v) => row.picked(v)
    }

    MacSlider {
        visible: row.isSlider
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(150, parent.width * 0.42)
        from: 0
        to: 1
        value: row.sliderValue
        onMoved: (v) => row.moved(v)
    }

    MacToggle {
        visible: row.showSwitch
        anchors.right: parent.right
        anchors.rightMargin: row.showInfo ? 34 : (row.chevron ? 32 : 16)
        anchors.verticalCenter: parent.verticalCenter
        checked: row.switchOn
        onToggled: (checked) => row.toggled(checked)
    }

    InfoDot {
        visible: row.showInfo
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        onClicked: row.infoClicked()
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
}
