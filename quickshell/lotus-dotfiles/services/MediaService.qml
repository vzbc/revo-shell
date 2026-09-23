import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    property bool initialized: false
    readonly property var player: choosePlayer()
    readonly property bool available: player !== null
    readonly property bool playing: available && player.isPlaying
    readonly property string title: available && player.trackTitle.length > 0 ? player.trackTitle : (available ? player.identity : "No media")
    readonly property string artist: available && player.trackArtist.length > 0 ? player.trackArtist : (available ? player.identity : "Start a player")
    readonly property string artworkUrl: available ? player.trackArtUrl : ""
    readonly property string identity: available ? player.identity : ""
    readonly property bool canTogglePlaying: available && player.canTogglePlaying
    readonly property bool canGoPrevious: available && player.canGoPrevious
    readonly property bool canGoNext: available && player.canGoNext
    readonly property bool canRaise: available && player.canRaise
    readonly property string playbackStatus: !available ? "Idle" : (playing ? "Playing" : (player.playbackState === MprisPlaybackState.Paused ? "Paused" : "Stopped"))

    function choosePlayer() {
        const players = Mpris.players.values;
        if (players.length === 0)
            return null;

        for (const candidate of players) {
            if (candidate !== null && candidate.isPlaying)
                return candidate;

        }
        for (const candidate of players) {
            if (candidate !== null && candidate.playbackState === MprisPlaybackState.Paused)
                return candidate;

        }
        return players[0];
    }

    function previous() {
        if (canGoPrevious)
            player.previous();

    }

    function togglePlaying() {
        if (canTogglePlaying)
            player.togglePlaying();

    }

    function next() {
        if (canGoNext)
            player.next();

    }

    function raisePlayer() {
        if (canRaise)
            player.raise();

    }

    Component.onCompleted: Qt.callLater(() => {
        root.initialized = true;
    })
}
