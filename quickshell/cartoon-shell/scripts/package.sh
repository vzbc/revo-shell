pacman -Q | awk '{print $1}' | while read -r p; do
  reason=$(pacman -Qi "$p" 2>/dev/null | awk -F': ' '/Install Reason/ {print $2}')
  echo "$p"
done | while read -r p; do
  info=$(pacman -Qi "$p")

  size_raw=$(awk -F': ' '/Installed Size/ {print $2}' <<<"$info")

  size_mb=0

  if [[ $size_raw =~ ([0-9.]+)\ ([KMGT]?)i?B ]]; then
    value=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}

    case "$unit" in
    K) size_mb=$(awk "BEGIN {print $value / 1024}") ;;
    M) size_mb=$value ;;
    G) size_mb=$(awk "BEGIN {print $value * 1024}") ;;
    T) size_mb=$(awk "BEGIN {print $value * 1024 * 1024}") ;;
    *) size_mb=0 ;;
    esac
  fi

  # ceil + integer
  size_mb=$(awk "BEGIN {
  v=$size_mb
  print (v == int(v)) ? v : int(v)+1
}")

  case "$p" in
  glibc | systemd | bash | pacman | util-linux | coreutils | filesystem | tzdata)
    group="SYSTEM"
    ;;
  lib* | zlib | openssl | bzip2 | xz | lz4 | zstd | icu | pcre*)
    group="LIBS"
    ;;
  qt* | gtk* | kde* | gnome* | libadwaita | dconf | gsettings*)
    group="DESKTOP"
    ;;
  pipewire | ffmpeg | mpv | gstreamer | alsa* | pulseaudio*)
    group="MEDIA"
    ;;
  gcc | make | cmake | meson | ninja | binutils | git | python* | node* | java* | go*)
    group="DEV"
    ;;
  networkmanager | curl | openssh | iproute* | iptables | nftables | dbus*)
    group="NETWORK"
    ;;
  *)
    group="MISC"
    ;;
  esac

  printf '{"group":"%s","package":"%s","size_mb":%s}\n' "$group" "$p" "$size_mb"
done | jq -s 'group_by(.group) | map({
  group: .[0].group,
  packages: map({name: .package, size: .size_mb})
})'
