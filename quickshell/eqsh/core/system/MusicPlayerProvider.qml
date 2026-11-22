pragma Singleton

import QtQuick
import qs
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: mpris
    // playerctld is a proxy that also registers on MPRIS (often empty, and it
    // may sort last), so it never counts as a player of its own.
    property var players: Mpris.players.values.filter(p => String(p.dbusName || "").indexOf("playerctld") < 0)
    // the playing player wins; otherwise the last one used, otherwise any with a track
    property var lastPlayer: null
    property var activePlayer: {
        const ps = mpris.players;
        for (let i = ps.length - 1; i >= 0; i--)
            if (ps[i].isPlaying) return ps[i];
        if (mpris.lastPlayer && ps.indexOf(mpris.lastPlayer) >= 0) return mpris.lastPlayer;
        for (let i = ps.length - 1; i >= 0; i--)
            if (ps[i].trackTitle) return ps[i];
        return ps.length ? ps[ps.length - 1] : null;
    }
    onActivePlayerChanged: { const p = activePlayer; if (p && p.trackTitle) Qt.callLater(() => { if (mpris.lastPlayer !== p) mpris.lastPlayer = p }) }
    property string title: mpris.activePlayer?.trackTitle || Translation.tr("Not Playing")
    property string artist: mpris.activePlayer?.trackArtist || ""
    property string album: mpris.activePlayer?.trackAlbum || ""
    property url thumbnail: mpris.activePlayer?.trackArtUrl || ""
    property bool isPlaying: mpris.activePlayer?.isPlaying || false
    property int duration: mpris.activePlayer?.length || 0
    property int position: mpris.activePlayer?.position || 0
    property bool isAvailable: (mpris.activePlayer?.trackTitle || false) ? true : false
    // 4x a second so synced lyrics follow the song closely
    Timer {
        interval: 250
        repeat: true
        running: !!mpris.activePlayer
        onTriggered: {
            mpris.position = mpris.activePlayer?.position || 0
        }
    }
    property real exactPosition: 0      // fractional seconds for lyrics
    Timer {
        interval: 250
        repeat: true
        running: !!mpris.activePlayer
        onTriggered: mpris.exactPosition = mpris.activePlayer ? mpris.activePlayer.position : 0
    }
    // index of the line being sung (-1 before the first line / unsynced)
    readonly property int lyricsIndex: {
        if (!lyricsSynced || lyricsLines.length === 0) return -1;
        const t = exactPosition + 0.25;
        let c = -1;
        for (let i = 0; i < lyricsLines.length; i++) { if (lyricsLines[i].t <= t) c = i; else break; }
        return c;
    }
    readonly property string lyricsCurrent: lyricsIndex >= 0 ? (lyricsLines[lyricsIndex].text || "") : ""
    property bool available: false

    // ── lyrics (LRCLIB, fetched on demand while the lock screen lyrics view is open) ──
    property bool lyricsWanted: false
    property var lyricsLines: []        // [{ t: seconds (-1 = not synced), text }]
    property bool lyricsSynced: false
    property string lyricsState: "idle" // idle | loading | ok | none | offline
    property int lyricsTries: 0
    readonly property string trackKey: mpris.activePlayer
        ? (mpris.title + "|" + mpris.artist + "|" + mpris.album + "|" + Math.round(mpris.duration || 0))
        : ""

    onTrackKeyChanged: {
        lyricsLines = []; lyricsSynced = false; lyricsState = "idle"; lyricsTries = 0;
        if (lyricsWanted) lyricsFetchDelay.restart();
    }
    onLyricsWantedChanged: if (lyricsWanted && lyricsState === "idle") lyricsFetchDelay.restart()

    Timer { id: lyricsFetchDelay; interval: 500; onTriggered: mpris.fetchLyrics() }
    Timer { id: lyricsRetry; interval: 12000; onTriggered: mpris.fetchLyrics() }

    function fetchLyrics() {
        if (!lyricsWanted || !mpris.activePlayer || mpris.title === "") return;
        if (lrcProc.running) return;
        lyricsState = "loading";
        var a = mpris.artist || "", t = mpris.title || "", al = mpris.album || "";
        var d = mpris.durationSupported ? String(Math.round(mpris.duration || 0)) : "0";
        lrcProc.running = false;
        lrcProc.command = ["sh", "-c", mpris.lyrScript, "sh", a, t, al, d];
        lrcProc.running = true;
    }

    readonly property string lyrScript: [
        'a="$1"; t="$2"; al="$3"; d="${4:-0}"; c="$HOME/.cache/maclock/lyrics"; mkdir -p "$c"',
        'k=$(printf "%s|%s" "$a" "$t" | md5sum | cut -c1-16); f="$c/$k.json"',
        '[ -s "$f" ] && { cat "$f"; exit 0; }',
        'tmp=$(mktemp); answered=0; r=""',
        'bare=$(printf "%s" "$t" | sed -E "s/ *[(\\[][^)\\]]*[)\\]]//g; s/ +- +(.*[Rr]emaster.*|[Ll]ive.*|[Rr]adio [Ee]dit.*)$//")',
        'ua="MacLock/1.0 (https://github.com/0-ss/Macshell)"; api=https://lrclib.net/api',
        'req() { n=0; while [ $n -lt 2 ]; do code=$(curl -s --max-time 8 -A "$ua" -o "$tmp" -w "%{http_code}" -G "$@"); case "$code" in 200) answered=1; return 0;; 404) answered=1; return 1;; 429) n=$((n+1)); sleep 1.5;; *) return 1;; esac; done; return 1; }',
        'pick=\'[.[] | select(.syncedLyrics != null or .plainLyrics != null) | select($d == 0 or (((.duration // 0) - $d) | fabs) <= 4)] | ([.[] | select(.syncedLyrics != null)][0] // .[0]) // empty\'',
        'lsearch() { req "$api/search" "$@" && r=$(jq -c --argjson d "$d" "$pick" "$tmp"); }',
        '[ -z "$r" ] && lsearch --data-urlencode "track_name=$t" --data-urlencode "artist_name=$a"',
        '[ -z "$r" ] && [ "$bare" != "$t" ] && lsearch --data-urlencode "track_name=$bare" --data-urlencode "artist_name=$a"',
        '[ -z "$r" ] && lsearch --data-urlencode "q=$a $bare"',
        'rm -f "$tmp"',
        'if [ -n "$r" ]; then printf "%s" "$r" | jq -c "{synced: .syncedLyrics, plain: .plainLyrics, instrumental: .instrumental}" | tee "$f"',
        'elif [ "$answered" = 1 ]; then echo "{}" | tee "$f"',
        'else echo "{\\"retry\\":true}"; fi'
    ].join("\n")

    Process {
        id: lrcProc
        stdout: StdioCollector {
            onStreamFinished: {
                var o = {};
                try { o = JSON.parse(text || "{}"); } catch (e) { o = {}; }
                var out = [], i, m;
                if (o.synced) {
                    var ls2 = o.synced.split("\n");
                    for (i = 0; i < ls2.length; i++) {
                        var line = ls2[i], tags = [], re = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
                        while ((m = re.exec(line)) !== null) tags.push(parseInt(m[1]) * 60 + parseFloat(m[2]));
                        var txt = line.replace(/\[[^\]]*\]/g, "").trim();
                        if (/^(制作人|作词|作曲|编曲|混音|母带|制作|和声|吉他|贝斯|鼓|录音|监制|出品|发行|OP|SP|Producer|Lyricist|Composer|Lyrics|Composed|Written)\s*[:：]/i.test(txt)) continue;
                        for (var j = 0; j < tags.length; j++) out.push({ t: tags[j], text: txt });
                    }
                    out.sort(function (a, b) { return a.t - b.t; });
                    mpris.lyricsLines = out; mpris.lyricsSynced = true;
                    mpris.lyricsState = out.length > 0 ? "ok" : "none";
                } else if (o.plain) {
                    var pl = o.plain.split("\n");
                    for (i = 0; i < pl.length; i++) out.push({ t: -1, text: pl[i].trim() });
                    mpris.lyricsLines = out; mpris.lyricsSynced = false; mpris.lyricsState = "ok";
                } else if (o.retry) {
                    if (mpris.lyricsTries < 4) { mpris.lyricsTries++; mpris.lyricsState = "loading"; lyricsRetry.restart(); }
                    else { mpris.lyricsLines = []; mpris.lyricsState = "offline"; }
                } else if (o.instrumental) {
                    mpris.lyricsLines = []; mpris.lyricsState = "none";
                } else {
                    mpris.lyricsLines = []; mpris.lyricsState = "none";
                }
            }
        }
    }

    function togglePlay() {
        if (mpris.activePlayer) {
            if (mpris.isPlaying) {
                mpris.activePlayer.pause()
            } else {
                mpris.activePlayer.play()
            }
        }
    }
    function next() {
        if (mpris.activePlayer) {
            mpris.activePlayer.next()
        }
    }
    function previous() {
        if (mpris.activePlayer) {
            mpris.activePlayer.previous()
        }
    }

    IpcHandler {
        target: "music"
        function togglePlay() {
            mpris.togglePlay()
        }
        function next() {
            mpris.next()
        }
        function previous() {
            mpris.previous()
        }
        function getData(): object {
            return {
                "title": mpris.title,
                "artist": mpris.artist,
                "album": mpris.album,
                "thumbnail": mpris.thumbnail,
                "isPlaying": mpris.isPlaying,
                "duration": mpris.duration,
                "position": mpris.position
            }
        }
    }
}