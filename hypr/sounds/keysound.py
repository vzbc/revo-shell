import evdev
import subprocess

devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
keyboard = None
for dev in devices:
    caps = dev.capabilities()
    if evdev.ecodes.EV_KEY in caps:
        keys = caps[evdev.ecodes.EV_KEY]
        if evdev.ecodes.KEY_A in keys and evdev.ecodes.KEY_ENTER in keys:
            keyboard = dev
            break

if not keyboard:
    for dev in devices:
        if 'keyboard' in dev.name.lower() or 'kbd' in dev.name.lower():
            keyboard = dev
            break

if not keyboard:
    exit(1)

sound_dir = "/home/revo/.config/hypr/sounds/"

ignored_keys = {
    evdev.ecodes.KEY_LEFTSHIFT, evdev.ecodes.KEY_RIGHTSHIFT,
    evdev.ecodes.KEY_LEFTCTRL, evdev.ecodes.KEY_RIGHTCTRL,
    evdev.ecodes.KEY_LEFTALT, evdev.ecodes.KEY_RIGHTALT,
    evdev.ecodes.KEY_LEFTMETA, evdev.ecodes.KEY_RIGHTMETA,
    evdev.ecodes.KEY_CAPSLOCK, evdev.ecodes.KEY_NUMLOCK
}

current_player = None

def play_sound(sound_file):
    global current_player
    if current_player and current_player.poll() is None:
        try:
            current_player.terminate()
        except Exception:
            pass
    current_player = subprocess.Popen(["mpv", "--no-video", "--really-quiet", sound_dir + sound_file])

for event in keyboard.read_loop():
    # 1 تعني الضغط، و 2 تعني الاستمرار بالضغط (Hold / Repeat)
    if event.type == evdev.ecodes.EV_KEY and event.value in (1, 2):
        if event.code == evdev.ecodes.KEY_BACKSPACE or event.code == evdev.ecodes.KEY_DELETE:
            play_sound("remove.ogg")
        elif event.code == evdev.ecodes.KEY_ENTER or event.code == evdev.ecodes.KEY_KPENTER:
            play_sound("send.ogg")
        elif event.code not in ignored_keys:
            play_sound("type.ogg")
