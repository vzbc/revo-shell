#!/usr/bin/env python3
# Note: Claude Code helped me understand and partially write this
# AAP protocol constants and packet structure based on reverse-engineering
# documented in kavishdevar/librepods (GPL-3.0).
# https://github.com/kavishdevar/librepods
"""
AirPods battery daemon.
Connects via AAP (L2CAP PSM 0x1001), does the handshake, then prints a JSON
line to stdout whenever battery or ear-detection state changes.

Output format (one JSON line per change):
  {"left": 48, "right": 47, "case": 45,
   "left_charging": false, "right_charging": false, "case_charging": false,
   "left_ear": true, "right_ear": true, "connected": true}

Usage:
  python airpods_battery.py <MAC>
  python airpods_battery.py          # auto-detect first paired AirPods

Requires root or CAP_NET_RAW for raw L2CAP sockets.
"""

import json
import re
import socket
import subprocess
import sys
import time

# AAP protocol constants (from LibrePods / kavishdevar)

AAP_PSM = 0x1001

HANDSHAKE    = bytes.fromhex("00000400010002000000000000000000")
SET_FEATURES = bytes.fromhex("040004004d00d700000000000000")
REQ_NOTIFS   = bytes.fromhex("040004000f00ffffffffff")

H_HANDSHAKE_ACK = bytes.fromhex("01000400")
H_FEATURES_ACK  = bytes.fromhex("040004002b00")
H_BATTERY        = bytes.fromhex("040004000400")
H_EAR            = bytes.fromhex("040004000600")

COMPONENT = {0x01: "headset", 0x02: "right", 0x04: "left", 0x08: "case"}
STATUS    = {0x01: "charging", 0x02: "discharging", 0x04: "disconnected"}

def find_adapter() -> str:
    """Return BD address of the busiest (most TX bytes) local HCI adapter."""
    out = subprocess.run(["hciconfig", "-a"], capture_output=True, text=True).stdout
    blocks = re.split(r"\n(?=hci\d)", out.strip())
    best_addr, best_tx = "00:00:00:00:00:00", -1
    for block in blocks:
        addr = re.search(r"BD Address:\s+([0-9A-Fa-f:]{17})", block)
        tx   = re.search(r"TX bytes:(\d+)", block)
        if addr and tx and int(tx.group(1)) > best_tx:
            best_tx   = int(tx.group(1))
            best_addr = addr.group(1)
    return best_addr


def find_airpods_mac() -> str | None:
    """Return MAC of first paired AirPods (vendor 004C = Apple) via bluetoothctl."""
    out = subprocess.run(["bluetoothctl", "devices"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        # line: "Device AA:BB:CC:DD:EE:FF Name"
        m = re.match(r"Device ([0-9A-Fa-f:]{17})", line)
        if m:
            mac  = m.group(1)
            info = subprocess.run(
                ["bluetoothctl", "info", mac], capture_output=True, text=True
            ).stdout
            if "74ec2172-0bad-4d01-8f77-997b2be0722a" in info:
                return mac
    return None


def parse_battery(data: bytes) -> dict | None:
    if not data.startswith(H_BATTERY):
        return None
    count = data[6]
    if count > 3 or len(data) != 7 + 5 * count:
        return None
    result = {}
    for i in range(count):
        o      = 7 + 5 * i
        name   = COMPONENT.get(data[o], f"comp_{data[o]:02x}")
        level  = data[o + 2]
        status = STATUS.get(data[o + 3], "unknown")
        result[name] = {"level": level, "charging": status == "charging",
                        "connected": status != "disconnected"}
    return result


def parse_ear(data: bytes) -> dict | None:
    if not data.startswith(H_EAR) or len(data) < 8:
        return None
    def in_ear(b): return b == 0x00
    return {"left_ear": in_ear(data[6]), "right_ear": in_ear(data[7])}

class State:
    def __init__(self):
        self.left           = 0
        self.right          = 0
        self.case           = 0
        self.left_charging  = False
        self.right_charging = False
        self.case_charging  = False
        self.left_ear       = False
        self.right_ear      = False
        self.connected      = False

    def update_battery(self, parsed: dict) -> bool:
        changed = False
        for comp, info in parsed.items():
            if comp == "left":
                if self.left != info["level"] or self.left_charging != info["charging"]:
                    self.left, self.left_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "right":
                if self.right != info["level"] or self.right_charging != info["charging"]:
                    self.right, self.right_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "case":
                if info["connected"] and (self.case != info["level"] or self.case_charging != info["charging"]):
                    self.case, self.case_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "headset":
                # AirPods Max, map to left for simplicity
                if self.left != info["level"] or self.left_charging != info["charging"]:
                    self.left, self.left_charging = info["level"], info["charging"]
                    changed = True
        return changed

    def update_ear(self, parsed: dict) -> bool:
        changed = (self.left_ear != parsed["left_ear"] or
                   self.right_ear != parsed["right_ear"])
        self.left_ear  = parsed["left_ear"]
        self.right_ear = parsed["right_ear"]
        return changed

    def emit(self):
        print(json.dumps({
            "connected":      self.connected,
            "left":           self.left,
            "right":          self.right,
            "case":           self.case,
            "left_charging":  self.left_charging,
            "right_charging": self.right_charging,
            "case_charging":  self.case_charging,
            "left_ear":       self.left_ear,
            "right_ear":      self.right_ear,
        }), flush=True)

# main loop

RECONNECT_DELAY = 5

def connect(mac: str, local: str) -> socket.socket:
    sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)
    sock.settimeout(10.0)
    sock.bind((local, 0))
    sock.connect((mac, AAP_PSM))
    return sock


def run(mac: str):
    local = find_adapter()
    print(f"# adapter={local}  airpods={mac}", file=sys.stderr)

    state = State()

    while True:
        try:
            sock = connect(mac, local)
        except OSError as e:
            print(f"# connect failed: {e} - retrying in {RECONNECT_DELAY}s", file=sys.stderr)
            time.sleep(RECONNECT_DELAY)
            continue

        print(f"# connected", file=sys.stderr)
        state.connected = True
        state.emit()
        step = "handshake"
        sock.send(HANDSHAKE)

        try:
            while True:
                try:
                    data = sock.recv(4096)
                except TimeoutError:
                    continue

                if not data:
                    print("# device closed connection", file=sys.stderr)
                    break

                if step == "handshake" and data.startswith(H_HANDSHAKE_ACK):
                    sock.send(SET_FEATURES)
                    step = "features"

                elif step == "features" and data.startswith(H_FEATURES_ACK):
                    sock.send(REQ_NOTIFS)
                    step = "listening"

                elif step == "listening":
                    if data.startswith(H_BATTERY):
                        parsed = parse_battery(data)
                        if parsed and state.update_battery(parsed):
                            state.emit()

                    elif data.startswith(H_EAR):
                        parsed = parse_ear(data)
                        if parsed and state.update_ear(parsed):
                            state.emit()

        except OSError as e:
            print(f"# socket error: {e}", file=sys.stderr)
        finally:
            sock.close()

        state.connected = False
        state.emit()
        print(f"# disconnected - retrying in {RECONNECT_DELAY}s", file=sys.stderr)
        time.sleep(RECONNECT_DELAY)


if __name__ == "__main__":
    if len(sys.argv) == 2:
        mac = sys.argv[1]
    else:
        mac = find_airpods_mac()
        if not mac:
            print("No paired AirPods found. Pass MAC as argument.", file=sys.stderr)
            sys.exit(1)
        print(f"# auto-detected: {mac}", file=sys.stderr)

    try:
        run(mac)
    except KeyboardInterrupt:
        print("\n# interrupted", file=sys.stderr)
