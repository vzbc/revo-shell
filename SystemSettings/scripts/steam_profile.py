import json, os, re

# Game Center ↔ the signed-in Steam account (System Settings › Game Center)
d = os.path.expanduser('~/.local/share/Steam')
o = {}
try:
    s = open(d + '/config/loginusers.vdf', errors='ignore').read()
    best = None
    for sid, b in re.findall(r'"(\d{17})"\s*\{([^}]*)\}', s):
        m = re.search(r'"timestamp"\s*"(\d+)"', b)
        ts = int(m.group(1)) if m else 0
        if not best or ts > best[2]:
            best = (sid, b, ts)
    if best:
        sid, b, _ = best
        g = lambda k: (re.search(r'"' + k + r'"\s*"([^"]*)"', b) or [0, ''])[1] if re.search(r'"' + k + r'"\s*"([^"]*)"', b) else ''
        o = {'id': sid, 'name': g('PersonaName'), 'friends': 0}
        try:
            c = open(d + '/userdata/%d/config/localconfig.vdf' % (int(sid) - 76561197960265728), errors='ignore').read()
            i = c.find('"friends"')
            o['friends'] = len(re.findall(r'"\d{6,}"\s*\{\s*"name"', c[i:i + 400000])) if i >= 0 else 0
        except Exception:
            pass
except Exception:
    pass
print(json.dumps(o))
