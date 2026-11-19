#!/usr/bin/env python3
import json, os, sys

CFG = "/home/revo/.config/quickshell/macos/userconfig.json"

def main():
    if len(sys.argv) < 3:
        sys.exit(1)
    key = sys.argv[1]
    raw = sys.argv[2]
    # value may be JSON-encoded (string, bool, number, nested)
    try:
        val = json.loads(raw)
    except Exception:
        val = raw
    d = {}
    if os.path.exists(CFG):
        try:
            d = json.load(open(CFG))
        except Exception:
            d = {}
    # support dotted keys e.g. menubar.wifi
    parts = key.split(".")
    cur = d
    for p in parts[:-1]:
        if not isinstance(cur.get(p), dict):
            cur[p] = {}
        cur = cur[p]
    cur[parts[-1]] = val
    json.dump(d, open(CFG, "w"), indent=2)
    print("ok", key, "=", val)

if __name__ == "__main__":
    main()
