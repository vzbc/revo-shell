#!/usr/bin/env python3
"""Read the ACPI lid switch (SW_LID) and forward edges to the macduo shell.

Primary path: evdev events on the Lid Switch device (we are in the input
group). Fallback/desync guard: poll /proc/acpi/button/lid every loop.
"""
import select
import subprocess
import sys
import time


def log(*a):
    line = " ".join(str(x) for x in a)
    print("[lidwatch]", line, file=sys.stderr, flush=True)
    try:
        with open("/tmp/macduo_lid.log", "a") as f:
            f.write(line + "\n")
    except OSError:
        pass

SHELL = "/home/revo/.config/quickshell/macduo"
PROC_STATE = "/proc/acpi/button/lid/LID0/state"

try:
    import evdev
except ImportError:
    evdev = None

_last_sent = None
_last_time = 0.0


def send(state: str) -> None:
    global _last_sent, _last_time
    now = time.monotonic()
    if state == _last_sent or now - _last_time < 0.15:
        return
    _last_sent = state
    _last_time = now
    log("send", state)
    subprocess.run(
        ["qs", "ipc", "-p", SHELL, "call", "macduo", "lid", state],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
    )
    log("send rc")


def proc_state():
    try:
        with open(PROC_STATE) as f:
            return f.read().split()[1]  # "open" / "closed"
    except Exception:
        return None


def find_lid_device():
    if evdev is None:
        return None
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except OSError:
            continue
        if dev.name == "Lid Switch":
            return dev
        dev.close()
    return None


def main():
    global _last_sent

    initial = proc_state()
    _last_sent = initial  # no animation for a state we did not witness change

    log("initial proc state:", initial)
    dev = find_lid_device()
    log("device:", dev.path if dev else None, dev.name if dev else None)
    if dev is not None:
        while True:
            r, _, _ = select.select([dev.fd], [], [], 1.0)
            if r:
                try:
                    for event in dev.read():
                        if (event.type == evdev.ecodes.EV_SW
                                and event.code == evdev.ecodes.SW_LID):
                            log("EV_SW event value=", event.value)
                            send("closed" if event.value else "open")
                except OSError:
                    dev = None
                    break
            state = proc_state()
            if state is not None and state != _last_sent:
                log("proc sync:", state, "last:", _last_sent)
                send(state)

    # fallback: poll only
    while True:
        state = proc_state()
        if state is not None and state != _last_sent:
            send(state)
        time.sleep(0.3)


if __name__ == "__main__":
    main()
