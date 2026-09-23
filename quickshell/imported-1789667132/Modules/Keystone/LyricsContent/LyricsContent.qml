import QtQuick
import Clavis.Lyrics
import qs.Services

Item {
    id: root

    required property var player
    property bool active: false
    property bool vertical: false
    property string edge: "top"
    readonly property var lyricsModel: Lyrics.lyrics
    readonly property string artUrl: player ? player.trackArtUrl || "" : ""
    readonly property string spectrumToken: "keystone-lyrics"
    readonly property int currentLineIndex: {
        const lines = Lyrics.lyrics;
        if (!root.player || !Lyrics.hasSynchronizedLyrics || !lines || lines.length === 0)
            return -1;

        const position = root.player === MediaManager.active ? MediaManager.currentPosition : Math.max(0, Number(root.player.position) || 0);
        return Lyrics.indexForTime(position);
    }
    readonly property string currentLyric: currentLineIndex >= 0 && currentLineIndex < lyricsModel.length ? String(lyricsModel[currentLineIndex].text || "") : lyricsModel && lyricsModel.length > 0 ? String(lyricsModel[0].text || "") : ""

    implicitWidth: presenter.item ? presenter.item.implicitWidth : 0
    implicitHeight: presenter.item ? presenter.item.implicitHeight : 0
    Component.onCompleted: {
        if (active)
            AudioSpectrum.acquire(spectrumToken);

    }
    Component.onDestruction: AudioSpectrum.release(spectrumToken)
    onActiveChanged: {
        if (active)
            AudioSpectrum.acquire(spectrumToken);
        else
            AudioSpectrum.release(spectrumToken);
    }

    Loader {
        id: presenter

        anchors.fill: parent
        sourceComponent: root.vertical ? verticalComponent : horizontalComponent
    }

    Component {
        id: horizontalComponent

        HorizontalLyricsLayout {
            lyricsModel: root.lyricsModel
            currentLineIndex: root.currentLineIndex
            artUrl: root.artUrl
            active: root.active
            status: Lyrics.status
            errorText: Lyrics.error
        }

    }

    Component {
        id: verticalComponent

        VerticalLyricsLayout {
            lyric: root.currentLyric
            artUrl: root.artUrl
            active: root.active
            edge: root.edge
            status: Lyrics.status
            errorText: Lyrics.error
        }

    }

}
