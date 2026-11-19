#!/usr/bin/env python3
import os, re, sys, subprocess, hashlib
from PIL import Image

DECODE_BIN = "/mnt/storage/spotlight_car/decode_lzfse"
BLK = "/home/revo/.config/quickshell/settings/assets/car_blocks"
OUT = "/home/revo/.config/quickshell/settings/assets/icons"
os.makedirs(OUT, exist_ok=True)

TOK = re.compile(r'(WiFi|Wi-?Fi|Bluetooth|Network|VPN|Battery|General|Notif|Sound|Focus|ScreenTime|Lock|Privacy|Touch|User|Internet|Game|iCloud|Wallet|Passw|Keyboard|Mouse|Trackpad|Printer|Family|Apple|Display|Wallpaper|Dock|Appear|Access|Update|Storage|Language|Sharing|TimeMachine|Startup|Profile|AirDrop|Siri|Spotlight|VPN|Display|Wallpaper)', re.I)

def carve(buf):
    res = []
    for magic, ext in [(b'\xff\xd8\xff', 'jpg'), (b'%PDF', 'pdf'), (b'\x89PNG\r\n\x1a\n', 'png')]:
        s = 0
        while True:
            pp = buf.find(magic, s)
            if pp == -1: break
            if ext == 'jpg':
                e = buf.find(b'\xff\xd9', pp); data = buf[pp:e+2] if e != -1 else None
            elif ext == 'pdf':
                e = buf.find(b'%%EOF', pp); data = buf[pp:e+5] if e != -1 else None
            else:
                e = buf.find(b'IEND', pp); data = buf[pp:e+8] if e != -1 else None
            if data and len(data) > 200:
                res.append((ext, data, pp))
            s = pp + 1
    return res

def near_token(blob, pos):
    lo = max(0, pos-20000); hi = min(len(blob), pos+20000)
    best = None
    for m in re.finditer(rb'[0-9A-Za-z_./+-]{3,48}', blob[lo:hi]):
        s = m.group().decode('latin1','ignore')
        if TOK.search(s) or re.search(r'(?i)\.(png|pdf|jpg|heic|tiff)$', s):
            best = s; break
    return best

def best_rgba_dim(d):
    for dim in [1024,512,256,128,64,48,32,24,16]:
        if len(d) >= dim*dim*4:
            return dim
    return None

manifest = []
seen = set(); count = 0; rawbuf = 0
for f in sorted(os.listdir(BLK)):
    if not f.endswith('.bin'): continue
    b = open(os.path.join(BLK, f), 'rb').read()
    idx = re.sub(r'[^0-9]', '', f)
    positions = [m.start() for m in re.finditer(b'bvx2', b)]
    if not positions:
        # also try raw carve
        for ext, data, pos in carve(b):
            h = hashlib.md5(data).hexdigest()
            if h in seen: continue
            seen.add(h)
            fn = f"raw_{ext}_{idx}_{h[:6]}.{ext}"; open(os.path.join(OUT,fn),'wb').write(data)
            if ext=='pdf':
                subprocess.run(['pdftoppm','-r','256','-png',os.path.join(OUT,fn),os.path.join(OUT,fn.replace('.pdf',''))],capture_output=True,timeout=30)
            count += 1; manifest.append((fn, ext, len(data), idx, ""))
        continue
    for j, p in enumerate(positions):
        end = positions[j+1] if j+1 < len(positions) else len(b)
        frame = b[p:end]
        open('/tmp/_fr.bin','wb').write(frame)
        r = subprocess.run([DECODE_BIN,'/tmp/_fr.bin','/tmp/_fr.dec'],capture_output=True)
        if r.returncode != 0 or not os.path.exists('/tmp/_fr.dec') or os.path.getsize('/tmp/_fr.dec')==0:
            # try whole rest
            open('/tmp/_fr.bin','wb').write(b[p:])
            r = subprocess.run([DECODE_BIN,'/tmp/_fr.bin','/tmp/_fr.dec'],capture_output=True)
            if r.returncode != 0 or not os.path.exists('/tmp/_fr.dec') or os.path.getsize('/tmp/_fr.dec')==0:
                continue
        dec = open('/tmp/_fr.dec','rb').read()
        nm = near_token(b, p) or ""
        for ext, data, pos in carve(dec):
            h = hashlib.md5(data).hexdigest()
            if h in seen: continue
            seen.add(h)
            safe = re.sub(r'[^0-9A-Za-z_.-]','_',nm)[:40]
            fn = f"{safe}_{ext}_{idx}_{j}_{h[:6]}.{ext}"
            open(os.path.join(OUT,fn),'wb').write(data)
            if ext=='pdf':
                subprocess.run(['pdftoppm','-r','256','-png',os.path.join(OUT,fn),os.path.join(OUT,fn.replace('.pdf',''))],capture_output=True,timeout=30)
            count += 1; manifest.append((fn, ext, len(data), idx, nm))
        dim = best_rgba_dim(dec)
        if dim:
            h = hashlib.md5(dec[:dim*dim*4]).hexdigest()
            if h not in seen:
                seen.add(h)
                safe = re.sub(r'[^0-9A-Za-z_.-]','_',nm)[:40]
                im = Image.frombytes('RGBA',(dim,dim),dec[:dim*dim*4])
                fn = f"icon_{safe}_{idx}_{j}_{dim}.png"
                im.save(os.path.join(OUT,fn)); rawbuf+=1; count+=1
                manifest.append((fn,'rgba',dim*dim*4,idx,nm))

with open(os.path.join(OUT,'MAP.txt'),'w') as mf:
    mf.write(f"source: Settings.app Assets.car via LZFSE decode\n")
    mf.write(f"total images={count} (raw-rgba icons={rawbuf})\n\n")
    mf.write("file                                   ext    bytes   block frame name\n")
    for fn,ext,sz,idx,nm in manifest:
        mf.write(f"{fn:39s} {ext:5s} {sz:7d}  {idx:>5} {j if False else ''} {nm}\n")

print(f"decoded {count} images ({rawbuf} raw-rgba) -> {OUT}")
print("png:", sum(1 for m in manifest if m[1]=='png'))
print("pdf:", sum(1 for m in manifest if m[1]=='pdf'))
print("jpg:", sum(1 for m in manifest if m[1]=='jpg'))
print("rgba:", sum(1 for m in manifest if m[1]=='rgba'))
