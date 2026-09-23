pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  readonly property var mprisPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

  function getArtUrl(player: MprisPlayer): string {
    if (!player)
    return "";
    if (player.trackArtUrl)
    return player.trackArtUrl;

    const url = player.metadata["xesam:url"] ?? "";
    if (url.startsWith("https://www.youtube.com/watch")) {
      // Fallback for youtube
      const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
      return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
    }
    return "";
  }
  function getProgress() {
    if (!root.mprisPlayer)
    return 0

    var pos = root.mprisPlayer.position ?? 0
    var len = root.mprisPlayer.length ?? 0

    if (len <= 0 || pos < 0)
    return 0

    var progress = pos / len

    return Math.max(0, Math.min(1, progress))
  }

  function formatTime(seconds) {
    if (isNaN(seconds) || seconds < 0)
    return "00:00"

    var totalSeconds = Math.floor(seconds)
    var minutes = Math.floor(totalSeconds / 60)
    var secs = totalSeconds % 60

    function pad(n) {
      return n < 10 ? "0" + n : n
    }

    return pad(minutes) + ":" + pad(secs)
  }

  function getActive(prop: string): string {
    const active = root.active;
    return active ? active[prop] ?? "Invalid property" : "No active player";
  }

  function list(): string {
    return root.list.map(p => root.getIdentity(p)).join("\n");
  }

  function play(): void {
    const active = root.active;
    if (active?.canPlay)
    active.play();
  }

  function pause(): void {
    const active = root.active;
    if (active?.canPause)
    active.pause();
  }

  function playPause(): void {
    const active = root.mprisPlayer;
    if (active?.canTogglePlaying)
    active.togglePlaying();
  }

  function previous(): void {
    const active = root.mprisPlayer;
    if (active?.canGoPrevious)
    active.previous();
  }

  function next(): void {
    const active = root.mprisPlayer;
    if (!active) {
      console.warn("Cannot go next: no active player");
      return;
    }
    if (active.canGoNext === true) {
      active.next();
    } else {
      console.warn("Cannot go next: canGoNext is false");
    }
  }

  function stop(): void {
    root.active?.stop();
  }

}
