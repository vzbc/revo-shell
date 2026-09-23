import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Ui.RaisedSurface {
    id: root

    required property QtObject mediaService

    implicitWidth: mediaService.available ? theme.mediaIslandActiveWidth : theme.mediaIslandIdleWidth
    implicitHeight: theme.mediaIslandHeight
    padding: theme.space2
    fill: theme.surface
    surfaceRadius: theme.radiusCard

    RowLayout {
        anchors.fill: parent
        spacing: root.theme.space2
        visible: root.mediaService.available

        ClippingRectangle {
            id: artworkFrame

            Layout.preferredWidth: root.theme.mediaArtworkSize
            Layout.preferredHeight: root.theme.mediaArtworkSize
            radius: root.theme.radiusControl
            color: root.theme.pink
            border.width: root.theme.borderWidth
            border.color: root.theme.ink

            Image {
                id: artwork

                anchors.fill: parent
                source: root.mediaService.artworkUrl
                sourceSize.width: 160
                sourceSize.height: 160
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                visible: status === Image.Ready
            }

            Image {
                anchors.centerIn: parent
                width: root.theme.iconMd
                height: root.theme.iconMd
                source: Quickshell.shellDir + "/assets/icons/music.svg"
                sourceSize.width: root.theme.iconMd
                sourceSize.height: root.theme.iconMd
                visible: artwork.status !== Image.Ready
                opacity: artwork.status === Image.Loading ? 0.55 : 1
            }

            TapHandler {
                enabled: root.mediaService.canRaise
                onTapped: root.mediaService.raisePlayer()
            }

            HoverHandler {
                enabled: root.mediaService.canRaise
                cursorShape: Qt.PointingHandCursor
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.mediaService.title
                elide: Text.ElideRight
                color: root.theme.ink
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textSm
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.mediaService.artist
                elide: Text.ElideRight
                color: root.theme.inkMuted
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
            }

            Text {
                Layout.fillWidth: true
                text: root.mediaService.playbackStatus
                color: root.mediaService.playing ? root.theme.ink : root.theme.outlineSoft
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

        }

        RowLayout {
            spacing: root.theme.space1

            Ui.IconButton {
                theme: root.theme
                controlSize: 28
                iconSource: Quickshell.shellDir + "/assets/icons/previous.svg"
                accessibleName: "Previous track"
                enabled: root.mediaService.canGoPrevious
                onClicked: root.mediaService.previous()
            }

            Ui.IconButton {
                theme: root.theme
                controlSize: root.theme.compactControlSize
                iconSource: Quickshell.shellDir + "/assets/icons/" + (root.mediaService.playing ? "pause.svg" : "play.svg")
                accessibleName: root.mediaService.playing ? "Pause " + root.mediaService.title : "Play " + root.mediaService.title
                fill: root.theme.green
                raised: true
                enabled: root.mediaService.canTogglePlaying
                onClicked: root.mediaService.togglePlaying()
            }

            Ui.IconButton {
                theme: root.theme
                controlSize: 28
                iconSource: Quickshell.shellDir + "/assets/icons/next.svg"
                accessibleName: "Next track"
                enabled: root.mediaService.canGoNext
                onClicked: root.mediaService.next()
            }

        }

    }

    RowLayout {
        anchors.fill: parent
        spacing: root.theme.space2
        visible: !root.mediaService.available

        Rectangle {
            Layout.preferredWidth: root.theme.compactControlSize
            Layout.preferredHeight: root.theme.compactControlSize
            radius: root.theme.radiusControl
            color: root.theme.pink
            border.width: root.theme.borderWidth
            border.color: root.theme.ink

            Image {
                anchors.centerIn: parent
                width: root.theme.iconMd
                height: root.theme.iconMd
                source: Quickshell.shellDir + "/assets/icons/music.svg"
                sourceSize.width: root.theme.iconMd
                sourceSize.height: root.theme.iconMd
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.mediaService.initialized ? "No media" : "Checking media"
                elide: Text.ElideRight
                color: root.theme.ink
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textSm
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.mediaService.initialized ? "Start a player" : "MPRIS"
                elide: Text.ElideRight
                color: root.theme.inkMuted
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
            }

        }

    }

}
