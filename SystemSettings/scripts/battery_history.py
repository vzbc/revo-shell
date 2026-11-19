import glob, json, os, time

# Battery usage history for System Settings › Battery, from UPower's own logs
# (/var/lib/upower/history-{charge,rate}-<battery>.dat: "<unix> <value> <state>").
def read(kind):
    files = [f for f in glob.glob('/var/lib/upower/history-%s-*.dat' % kind) if 'generic' not in f]
    files = [f for f in files if os.path.exists(f.replace('-%s-' % kind, '-charge-'))]
    # the laptop battery = the one that also has a rate log and the most samples
    best = max(files, key=os.path.getsize) if files else None
    rows = []
    if best:
        for line in open(best):
            p = line.split()
            if len(p) >= 3:
                try:
                    rows.append((int(p[0]), float(p[1]), p[2]))
                except ValueError:
                    pass
    return rows

now = int(time.time())
charge = [r for r in read('charge') if r[2] != 'unknown']
rate = read('rate')

def pct_at(t):
    v = None
    for ts, pct, st in charge:
        if ts > t:
            break
        v = (pct, st)
    return v

# Battery Level: last 24 h in 15-minute buckets (value at bucket end)
q = 900
start24 = now - 24 * 3600
level = []
for i in range(96):
    t1 = start24 + (i + 1) * q
    v = pct_at(t1)
    seen = any(start24 + i * q <= ts < t1 for ts, _, _ in charge + rate)
    level.append({'p': round(v[0]) if v and seen else -1,
                  'c': bool(v and v[1] in ('charging', 'fully-charged', 'pending-charge'))})

# Screen On Usage ≈ time the machine was awake: boot sessions from the journal
# (covers time on the charger, where UPower logs nothing) ∪ UPower activity
import subprocess
spans = []
try:
    boots = json.loads(subprocess.run(['journalctl', '--list-boots', '-o', 'json'], capture_output=True,
                                      text=True, timeout=5).stdout or '[]')
    spans += [(b['first_entry'] // 1000000, b['last_entry'] // 1000000) for b in boots]
except Exception:
    pass
pts = sorted(ts for ts, _, _ in rate + charge)
spans += [(a, b) for a, b in zip(pts, pts[1:]) if b - a <= 600]
spans.sort()
merged = []
for a, b in spans:
    if merged and a <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], b)
    else:
        merged.append([a, b])

def awake_seconds(t0, t1):
    return sum(max(0, min(b, t1) - max(a, t0)) for a, b in merged)

# show the level for every 15 minutes the Mac was awake
for i, b in enumerate(level):
    if b['p'] < 0 and awake_seconds(start24 + i * q, start24 + (i + 1) * q) > 60:
        v = pct_at(start24 + (i + 1) * q)
        if v:
            b['p'] = round(v[0])
            b['c'] = v[1] in ('charging', 'fully-charged', 'pending-charge')

hourly = [round(awake_seconds(start24 + h * 3600, start24 + (h + 1) * 3600) / 60) for h in range(24)]
day0 = time.mktime(time.localtime(now)[:3] + (0, 0, 0, 0, 0, -1))
daily, used = [], []
for d in range(9, -1, -1):
    a = int(day0 - d * 86400)
    b = a + 86400
    daily.append(round(awake_seconds(a, b) / 3600, 1))
    drop, prev = 0.0, None
    for ts, pct, st in charge:
        if a <= ts < b:
            if prev is not None and st == 'discharging' and pct < prev:
                drop += prev - pct
            prev = pct
    used.append(round(drop))

last = None
for ts, pct, st in charge:
    if st in ('charging', 'fully-charged'):
        last = (ts, pct)
print(json.dumps({'now': now, 'start24': start24, 'level': level, 'hourly': hourly,
                  'day0': int(day0), 'daily': daily, 'used': used,
                  'lastCharged': {'t': last[0], 'p': round(last[1])} if last else None}))
