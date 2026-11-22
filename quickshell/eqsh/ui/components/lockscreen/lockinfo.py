#!/usr/bin/env python3
"""Lock-screen info for the pills under the clock (Sapphire-style).

Prints one JSON object:
  weather  {temp, code, isDay, hi, lo, place, aqi, sunrise, sunset}   (Open-Meteo, cached 20 min)
  event    {title, start, minutes, ongoing}                          (next local calendar event, 24 h)
  awake    true when something holds an idle inhibitor ("caffeinated")

  lockinfo.py [city]      city defaults to the time-zone city (Asia/Baghdad -> Baghdad)
"""
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "maclock")


def tz_city():
    try:
        tz = subprocess.run(["timedatectl", "show", "-p", "Timezone", "--value"],
                            capture_output=True, text=True, timeout=3).stdout.strip()
    except Exception:
        tz = os.environ.get("TZ", "")
    return tz.split("/")[-1].replace("_", " ") if "/" in tz else ""


def get(url):
    with urllib.request.urlopen(url, timeout=8) as r:
        return json.load(r)


def weather(city):
    if not city:
        return None
    path = os.path.join(CACHE, "weather.json")
    try:
        c = json.load(open(path))
        if c.get("city") == city and time.time() - c.get("ts", 0) < 1200:
            return c
    except Exception:
        pass
    try:
        g = get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + urllib.parse.quote(city))["results"][0]
        lat, lon = g["latitude"], g["longitude"]
        w = get(f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
                "&current=temperature_2m,weather_code,is_day&daily=sunrise,sunset,temperature_2m_max,"
                "temperature_2m_min&timezone=auto&forecast_days=1")
        aqi = None
        try:
            aqi = get(f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}"
                      "&current=us_aqi")["current"]["us_aqi"]
        except Exception:
            pass
        out = {"ts": time.time(), "city": city, "place": g.get("name", city),
               "temp": w["current"]["temperature_2m"], "code": w["current"]["weather_code"],
               "isDay": w["current"]["is_day"] == 1, "aqi": aqi,
               "hi": w["daily"]["temperature_2m_max"][0], "lo": w["daily"]["temperature_2m_min"][0],
               "sunrise": w["daily"]["sunrise"][0][-5:], "sunset": w["daily"]["sunset"][0][-5:]}
        os.makedirs(CACHE, exist_ok=True)
        json.dump(out, open(path, "w"))
        return out
    except Exception:
        try:
            return json.load(open(path))      # stale beats nothing
        except Exception:
            return None


def parse_dt(value, params):
    """iCalendar DTSTART -> aware datetime (local tz for floating times)."""
    value = value.strip()
    local = dt.datetime.now().astimezone().tzinfo
    if params.get("VALUE") == "DATE" or re.fullmatch(r"\d{8}", value):
        d = dt.datetime.strptime(value[:8], "%Y%m%d")
        return d.replace(tzinfo=local), True
    if value.endswith("Z"):
        return dt.datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(tzinfo=dt.timezone.utc), False
    d = dt.datetime.strptime(value[:15], "%Y%m%dT%H%M%S")
    tzid = params.get("TZID")
    if tzid:
        try:
            from zoneinfo import ZoneInfo
            return d.replace(tzinfo=ZoneInfo(tzid)), False
        except Exception:
            pass
    return d.replace(tzinfo=local), False


def next_event():
    now = dt.datetime.now().astimezone()
    horizon = now + dt.timedelta(hours=24)
    best = None
    files = glob.glob(os.path.join(HOME, ".local/share/evolution/calendar/*/calendar.ics"))
    files += glob.glob(os.path.join(HOME, ".local/share/calendars/**/*.ics"), recursive=True)
    for path in files:
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        text = re.sub(r"\r?\n[ \t]", "", text)                 # unfold lines
        for block in re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", text, re.S):
            fields = {}
            for line in block.splitlines():
                if ":" not in line:
                    continue
                key, val = line.split(":", 1)
                name, *ps = key.split(";")
                params = dict(p.split("=", 1) for p in ps if "=" in p)
                fields.setdefault(name.upper(), (val, params))
            if "DTSTART" not in fields:
                continue
            try:
                start, allday = parse_dt(*fields["DTSTART"])
                end = parse_dt(*fields["DTEND"])[0] if "DTEND" in fields else start + dt.timedelta(hours=1)
            except Exception:
                continue
            if end < now or start > horizon or allday:
                continue
            if best is None or start < best[0]:
                title = fields.get("SUMMARY", ("Event", {}))[0].replace("\\,", ",").replace("\\n", " ")
                best = (start, end, title)
    if not best:
        return None
    start, end, title = best
    return {"title": title, "start": start.strftime("%H:%M"),
            "minutes": int((start - now).total_seconds() // 60), "ongoing": start <= now <= end}


def awake():
    try:
        out = subprocess.run(["systemd-inhibit", "--list", "--no-pager", "--no-legend"],
                             capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return False
    # columns: WHO UID USER PID COMM WHAT WHY MODE (WHO/WHY may contain spaces)
    return any(re.search(r"(^|[\s:])idle([\s:]|$)", l) and l.rstrip().endswith("block") for l in out.splitlines())


if __name__ == "__main__":
    city = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else tz_city()
    print(json.dumps({"weather": weather(city), "event": next_event(), "awake": awake()}))
