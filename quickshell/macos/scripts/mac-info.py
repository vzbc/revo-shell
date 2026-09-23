#!/usr/bin/env python3
import json, random, string

serial = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))

info = {
    "vendor": "MacBook Pro",
    "model": "16-inch, M5",
    "year": "",
    "chip": "Apple M5",
    "cores": "",
    "memory": "64 GB",
    "graphics": "",
    "disk": "",
    "network": "",
    "serial": serial,
    "os": "Tahoe 26.5",
    "theme_version": ""
}

print(json.dumps(info))
