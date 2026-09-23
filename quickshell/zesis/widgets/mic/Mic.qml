pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../"
import "../shared"

Item {
    id: root

    readonly property PwNode source: MicService.source
    readonly property real vol: MicService.vol
    readonly property bool muted: MicService.muted
    property bool sourceListOpen: false

    Connections {
        target: Pipewire
        function onDefaultAudioSourceChanged() {
            root.sourceListOpen = false;
        }
    }

    function micIcon(v, m) {
        if (m || v === 0)
            return "󰍭";
        return "󰍬";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("mic.breadcrumb")
            title: I18n.t("mic.title")
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: UIScale.spacingSm

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Master mic card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    radius: UIScale.radiusMd
                    color: Colors.surface
                    implicitHeight: masterInner.implicitHeight + Math.round(24 * UIScale.value)

                    ColumnLayout {
                        id: masterInner
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: UIScale.radiusMd
                        }
                        spacing: UIScale.spacingSm

                        RowLayout {
                            Layout.fillWidth: true

                            Item {
                                implicitWidth: micIconText.implicitWidth + UIScale.spacingSm
                                implicitHeight: Math.round(28 * UIScale.value)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: UIScale.radiusSm
                                    color: micIconHover.hovered ? Colors.withAlpha(Colors.accent, 0.12) : "transparent"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                Text {
                                    id: micIconText
                                    anchors.centerIn: parent
                                    text: root.micIcon(root.vol, root.muted)
                                    font.pixelSize: Math.round(20 * UIScale.value)
                                    color: root.muted ? Colors.muted : Colors.accent
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: micIconHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var a = root.source?.audio;
                                        if (a)
                                            a.muted = !a.muted;
                                    }
                                }
                            }

                            Text {
                                text: I18n.t("mic.input")
                                color: Colors.text
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Math.round(root.vol * 100) + "%"
                                color: Colors.accent
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.Bold
                                font.family: "monospace"
                            }
                        }

                        SettingSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            step: 1
                            value: Math.round(Math.min(root.vol, 1.0) * 100)
                            muted: root.muted
                            onMoved: function (v) {
                                var a = root.source?.audio;
                                if (a)
                                    a.volume = v / 100;
                            }
                            onWheeled: function (delta) {
                                var a = root.source?.audio;
                                if (a)
                                    a.volume = Math.max(0, Math.min(1.0, root.vol + delta / 1200.0));
                            }
                        }
                    }
                }

                // Per-app capture streams
                SectionLabel {
                    text: I18n.t("common.apps")
                    color: Colors.textDim
                    font.weight: Font.Medium
                    Layout.leftMargin: UIScale.spacingMd + UIScale.spacingXs
                    Layout.topMargin: UIScale.spacingXs
                    visible: Pipewire.ready
                }

                Repeater {
                    model: ScriptModel {
                        values: (() => {
                                if (!Pipewire.ready)
                                    return [];
                                const streams = Pipewire.nodes.values.filter(n => n.isStream && n.isSource);
                                return [...new Set(streams.map(n => n.name))];
                            })()
                    }

                    delegate: Item {
                        id: appGroup
                        required property string modelData

                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.spacingMd
                        Layout.rightMargin: UIScale.spacingMd
                        implicitHeight: groupCard.implicitHeight

                        readonly property var groupStreams: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isStream && n.isSource && n.name === appGroup.modelData) : []
                        readonly property string appIconName: groupStreams.length > 0 ? (groupStreams[0].properties["application.icon-name"] ?? "") : ""
                        readonly property bool groupAllMuted: groupStreams.length > 0 && groupStreams.every(n => n.audio?.muted ?? false)

                        PwObjectTracker {
                            objects: appGroup.groupStreams
                        }

                        Rectangle {
                            id: groupCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: Colors.surface
                            implicitHeight: groupInner.implicitHeight + Math.round(20 * UIScale.value)

                            ColumnLayout {
                                id: groupInner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: UIScale.spacingSm
                                }
                                spacing: UIScale.spacingSm

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: UIScale.spacingSm

                                    Rectangle {
                                        implicitWidth: Math.round(32 * UIScale.value)
                                        implicitHeight: Math.round(32 * UIScale.value)
                                        radius: UIScale.spacingSm
                                        color: appGroup.groupAllMuted ? Colors.surfaceHigh : (badgeHover.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.15))
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        IconImage {
                                            anchors.centerIn: parent
                                            implicitSize: Math.round(18 * UIScale.value)
                                            source: (!appGroup.groupAllMuted && appGroup.appIconName) ? "image://icon/" + appGroup.appIconName : ""
                                            smooth: true
                                            mipmap: true
                                            visible: !appGroup.groupAllMuted && appGroup.appIconName !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: appGroup.groupAllMuted ? "󰍭" : "󰍬"
                                            font.pixelSize: Math.round(16 * UIScale.value)
                                            color: appGroup.groupAllMuted ? Colors.muted : Colors.accent
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                            visible: appGroup.groupAllMuted || appGroup.appIconName === ""
                                        }

                                        HoverHandler {
                                            id: badgeHover
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const mute = !appGroup.groupAllMuted;
                                                for (const n of appGroup.groupStreams) {
                                                    if (n.audio)
                                                        n.audio.muted = mute;
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: appGroup.modelData
                                        color: Colors.text
                                        font.pixelSize: UIScale.fontSmall
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Repeater {
                                    model: ScriptModel {
                                        values: appGroup.groupStreams
                                    }

                                    delegate: ColumnLayout {
                                        id: streamItem
                                        required property PwNode modelData
                                        Layout.fillWidth: true
                                        spacing: UIScale.spacingXs

                                        readonly property real streamVol: streamItem.modelData.audio?.volume ?? 0
                                        readonly property bool streamMuted: streamItem.modelData.audio?.muted ?? false
                                        readonly property string streamLabel: streamItem.modelData.properties["media.name"] || ""

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: streamItem.streamLabel
                                                color: streamItem.streamMuted ? Colors.textDim : Colors.text
                                                font.pixelSize: UIScale.fontTiny
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            Text {
                                                text: streamItem.streamMuted ? I18n.t("mic.muted") : (Math.round(streamItem.streamVol * 100) + "%")
                                                color: streamItem.streamMuted ? Colors.textDim : Colors.accent
                                                font.pixelSize: UIScale.fontTiny
                                                font.family: "monospace"
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }
                                        }

                                        SettingSlider {
                                            Layout.fillWidth: true
                                            implicitHeight: Math.round(16 * UIScale.value)
                                            handleSize: Math.round(13 * UIScale.value)
                                            from: 0
                                            to: 100
                                            step: 1
                                            value: Math.round(Math.min(streamItem.streamVol, 1.0) * 100)
                                            muted: streamItem.streamMuted
                                            onMoved: function (v) {
                                                var a = streamItem.modelData.audio;
                                                if (a)
                                                    a.volume = v / 100;
                                            }
                                            onWheeled: function (delta) {
                                                var a = streamItem.modelData.audio;
                                                if (a)
                                                    a.volume = Math.max(0, Math.min(1.0, streamItem.streamVol + delta / 1200.0));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Input device selector
                Column {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingMd
                    spacing: Math.round(2 * UIScale.value)

                    Rectangle {
                        width: parent.width
                        height: Math.round(44 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: sourceHeaderHover.hovered ? Colors.surfaceHigh : Colors.surface
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: UIScale.spacingMd
                            anchors.rightMargin: UIScale.spacingMd
                            spacing: UIScale.spacingSm

                            Text {
                                text: "󰍬"
                                font.pixelSize: Math.round(16 * UIScale.value)
                                color: Colors.accent
                            }

                            Text {
                                text: I18n.t("mic.inputWithName", [root.source?.description || root.source?.name || I18n.t("mic.noInput")])
                                color: Colors.text
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.sourceListOpen ? "⌄" : "⌃"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        HoverHandler {
                            id: sourceHeaderHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sourceListOpen = !root.sourceListOpen
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: sourceCol.implicitHeight + UIScale.spacingSm
                        radius: UIScale.radiusMd
                        color: Colors.surface
                        visible: root.sourceListOpen
                        clip: true

                        Column {
                            id: sourceCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: UIScale.spacingXs
                            spacing: 0

                            Repeater {
                                model: ScriptModel {
                                    values: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isSource && !n.isStream) : []
                                }

                                delegate: Item {
                                    id: sourceRow
                                    required property PwNode modelData
                                    width: parent.width
                                    height: Math.round(36 * UIScale.value)

                                    readonly property bool active: Pipewire.defaultAudioSource === sourceRow.modelData

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: Math.round(2 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: sourceRow.active ? Colors.withAlpha(Colors.accent, 0.15) : (sourceMa.pressed ? Colors.surfaceHigh : "transparent")
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.micro
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: UIScale.radiusSm
                                        height: UIScale.radiusSm
                                        radius: UIScale.radiusSm / 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: UIScale.radiusMd
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: sourceRow.active ? Colors.accent : Colors.withAlpha(Colors.text, 0.22)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(26 * UIScale.value)
                                        anchors.right: parent.right
                                        anchors.rightMargin: UIScale.spacingSm
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sourceRow.modelData.description || sourceRow.modelData.name || ""
                                        color: sourceRow.active ? Colors.text : Colors.textDim
                                        font.pixelSize: UIScale.fontTiny
                                        font.weight: sourceRow.active ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: sourceMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
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
