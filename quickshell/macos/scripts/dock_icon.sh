#!/bin/bash
# Given an appId, print the path of a suitable icon (or empty).
id="$1"
[ -z "$id" ] && exit 0

BASE="$(cd "$(dirname "$0")/../assets/icons" && pwd)"
DARK="$BASE/dark"
LIGHT="$BASE/light"
CUSTOM="$BASE/custom"

# Look up a mac icon name (e.g. "Finder", "App Store") and print the path.
# Prefers dark theme, falls back to light, then custom (Zed).
mac_icon() {
    local name="$1"
    [ -z "$name" ] && return 1
    for d in "$DARK" "$LIGHT" "$CUSTOM"; do
        local f="$d/$name.png"
        [ -f "$f" ] && { echo "$f"; return 0; }
    done
    return 1
}

# Look up a name inside the top-level icons dir (curated app icons like
# discord.png, Spotify.png, org.kde.dolphin.png, ...).
root_icon() {
    local name="$1"
    [ -z "$name" ] && return 1
    local f="$BASE/$name.png"
    [ -f "$f" ] && { echo "$f"; return 0; }
    return 1
}

# Map appId -> mac icon name. Keys are normalized: lowercase, no dots,
# spaces or dashes. A fixed table gives the real macOS dock mapping
# (the one Reem uses in her FancyTasksNG launchers).
map_mac() {
    local key="${1,,}"
    key="${key//[-._ ]/}"
    key="${key#com}"
    key="${key#org}"
    key="${key#net}"
    case "$key" in
        dolphin|files|filelight)                     echo "Finder"; return 0 ;;
        nautilus|thunar|pcmanfm|ranger)              echo "Finder"; return 0 ;;
        pafari|firefox|chrome|chromium) echo "Safari"; return 0 ;;
        discord) echo "discord"; return 0 ;;
        spotify) echo "Spotify"; return 0 ;;
        steam|steampipe|comvalvesoftwaresteam) echo "steam"; return 0 ;;
        telegramdesktop|telegram) echo "org.telegram.desktop"; return 0 ;;
        blender) echo "blender"; return 0 ;;
        *zen*) echo "zen-browser"; return 0 ;;
        code|codium|codeoss|vscodium|visualstudiocodeoss) echo "code"; return 0 ;;
        visualstudio*|zed) echo "Xcode"; return 0 ;;
        kitty|konsole|console|alacritty|gnometerminal|wezterm|tilix) echo "Terminal"; return 0 ;;
        gwenview|shotwell|eom|loupe)                 echo "Photos"; return 0 ;;
        geary|thunderbird|evolution|mailspring)      echo "Mail"; return 0 ;;
        signal|whatsapp) echo "Messages"; return 0 ;;
        jitsi|zoom|webex|teams)                      echo "FaceTime"; return 0 ;;
        maps|gnomemaps)                              echo "Maps"; return 0 ;;
        calendar|korganizer|gnomecalendar|khal)      echo "Calendar"; return 0 ;;
        contacts|kaddressbook|gnomecontacts)         echo "Contacts"; return 0 ;;
        notes|gnomenotes)                            echo "Notes"; return 0 ;;
        calculator|kcalc|gnomecalculator)            echo "Calculator"; return 0 ;;
        siriassistant|siri)                          echo "Siri"; return 0 ;;
        appstore|discover|pamac|gnomesoftware)       echo "App Store"; return 0 ;;
        iphonemirroring)                             echo "iPhone Mirroring"; return 0 ;;
        settings|systemsettings|pearossettings*)      echo "System Settings"; return 0 ;;
        reminders|gnomereminders)                    echo "Reminders"; return 0 ;;
        podcasts)                                    echo "Podcasts"; return 0 ;;
        music|amarok)                                echo "Music"; return 0 ;;
        gnomebooks|calibre)                          echo "Books"; return 0 ;;
        gnomepasswords|kwalletmanager|bitwarden)     echo "Passwords"; return 0 ;;
        news|gnomefeeds)                             echo "News"; return 0 ;;
        weather|gnomeweather)                        echo "Weather"; return 0 ;;
        preview|okular|gimp)                         echo "Preview"; return 0 ;;
        quicktime|vlc|mpv|celluloid|haruna)          echo "Quicktime"; return 0 ;;
        pages|libreoffice*)                          echo "Pages"; return 0 ;;
        numbers)                                     echo "Numbers"; return 0 ;;
        keynote|impress)                             echo "Keynote"; return 0 ;;
        imovie|kdenlive|openshot)                    echo "iMovie"; return 0 ;;
        gamecenter|lutris)                           echo "Game Center"; return 0 ;;
        activitymonitor|ksysguard|gnomesystemmonitor) echo "System Information"; return 0 ;;
        airdrop|localsearch|spotlight)               echo "Airdrop"; return 0 ;;
        homenas|kdeconnect|nfs)                      echo "Home"; return 0 ;;
        findmy|orgnomefindmy)                        echo "Find My"; return 0 ;;
        textedit|gedit|mousepad|kwrite)              echo "TextEdit"; return 0 ;;
        photobooth|cheese)                           echo "Photo Booth"; return 0 ;;
        stickies|gnometodo|gnotes)                   echo "Stickies"; return 0 ;;
        translate|gnometranslate)                    echo "Translate"; return 0 ;;
        tips|gnometips)                              echo "Tips"; return 0 ;;
        *) return 1 ;;
    esac
}

# 1) Fixed mac mapping first. Try the full id, the last path segment
#    (org.kde.dolphin -> dolphin), and the second-to-last segment
#    (com.visualstudio.code.oss -> code).
for cand in "$id" "${id##*.}" "${id%.*}"; do
    if name="$(map_mac "$cand")"; then
        # map_mac may return either a mac icon name ("Finder") or a full path.
        if [ -f "$name" ]; then
            echo "$name"
            exit 0
        fi
        if f="$(mac_icon "$name")" || f="$(root_icon "$name")"; then
            echo "$f"
            exit 0
        fi
    fi
done

# 2) Direct match: normalize the appId and look for a matching icon inside
#    the mac icon folders and the top-level icons dir.
norm="${id//[-._ ]/}"
norm="${norm,,}"
for d in "$DARK" "$LIGHT" "$CUSTOM" "$BASE"; do
    for f in "$d"/*.png; do
        [ -f "$f" ] || continue
        b="$(basename "$f" .png)"
        b="${b,,}"
        b="${b//[-._ ]/}"
        if [ "$b" = "$norm" ] || [ "$b" = "${id##*.}" ] || [ "$b" = "${norm%%$'\n'*}" ]; then
            echo "$f"
            exit 0
        fi
    done
done

# 3) Fall back to the system icon theme.
seen=""
find_icon() {
    local base="$1"
    for ext in svg png xpm; do
        for s in "$id" "${id##*.}" "${id,,}" "${id##*.}" "${id##*.}"; do
            local f="$base/$s.$ext"
            if [ -f "$f" ] && [[ "$seen" != *"|$f|"* ]]; then
                seen+="|$f|"
                echo "$f"
                return 0
            fi
        done
    done
    return 1
}

for d in /usr/share/icons/hicolor/{scalable,512x512,256x256,128x128,96x96,72x72,64x64,48x48,32x32}/apps \
         "$HOME/.local/share/icons/hicolor/{scalable,512x512,256x256,128x128,96x96,72x72,64x64,48x48,32x32}/apps" \
         /usr/share/icons/breeze/apps \
         /usr/share/icons/Papirus/{scalable,64x64,48x48,32x32}/apps \
         /usr/share/icons/Adwaita/{scalable,256x256,128x128,64x64,48x48,32x32}/apps \
         /usr/share/pixmaps; do
    [ -d "$d" ] && find_icon "$d" && exit 0
done

# 4) Look inside .desktop files.
for d in /usr/share/applications "$HOME/.local/share/applications"; do
    [ -d "$d" ] || continue
    for de in "$d"/*.desktop; do
        [ -f "$de" ] || continue
        fuzzy="${id//[._-]/[ ._-]}"
        if grep -qiE "(^Exec=.*[ /]$id([ ./]|$))|(^StartupWMClass[[:space:]]*=[[:space:]]*$fuzzy$)" "$de"; then
            ico=$(grep -m1 "^Icon=" "$de" | cut -d= -f2- | tr -d '\r')
            [ -z "$ico" ] && continue
            [ -f "$ico" ] && { echo "$ico"; exit 0; }
            IFS=/ read -ra segs <<< "$ico"
            for s in "${segs[@]}"; do short=$s; done
            for d2 in /usr/share/icons/hicolor/{scalable,256x256,128x128,96x96,72x72,64x64,48x48,32x32}/apps \
                      "$HOME/.local/share/icons/hicolor/{scalable,256x256,128x128,96x96,72x72,64x64,48x48,32x32}/apps" \
                      /usr/share/icons/breeze/apps \
                      /usr/share/pixmaps; do
                [ -d "$d2" ] || continue
                for ext in svg png xpm; do
                    for cand in "$d2/$ico.$ext" "$d2/$short.$ext"; do
                        [ -f "$cand" ] && { echo "$cand"; exit 0; }
                    done
                done
            done
            exit 0
        fi
    done
done

exit 0
