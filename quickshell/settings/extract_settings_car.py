#!/usr/bin/env python3
import os, re, struct, zlib, subprocess
CAR = "/mnt/sysv/root/System/Applications/System Settings.app/Contents/Resources/Assets.car"
BLK = "/home/revo/.config/quickshell/settings/assets/car_blocks"
OUT = "/home/revo/.config/quickshell/settings/assets/icons"
os.makedirs(BLK, exist_ok=True)
os.makedirs(OUT, exist_ok=True)

d = open(CAR, 'rb').read()
assert d[:8] == b'BOMStore', "not a BOMStore car"
version = struct.unpack('>I', d[8:12])[0]
btOff   = struct.unpack('>I', d[16:20])[0]   # 1068304
btSize  = struct.unpack('>I', d[20:24])[0]   # 2072  -> 259 entries of 8 bytes
nent = btSize // 8
blocks = []
for i in range(nent):
    o = btOff + i*8
    off, ln = struct.unpack('>II', d[o:o+8])
    if ln == 0 or off == 0 or off + ln > len(d):
        blocks.append(None)
    else:
        blocks.append((off, ln))
valid = sum(1 for b in blocks if b)
print(f"version={version} btOff={btOff} btSize={btSize} entries={nent} valid={valid}")

# dump blocks
for i, b in enumerate(blocks):
    if not b:
        continue
    off, ln = b
    open(os.path.join(BLK, f"block_{i:04d}.bin"), 'wb').write(d[off:off+ln])

# ---- carve images from dumped blocks ----
SIGS = [
    (b'%PDF', b'%%EOF', 'pdf'),
    (b'\xff\xd8\xff', b'\xff\xd9', 'jpg'),
    (b'\x89PNG\r\n\x1a\n', b'IEND', 'png'),
    (b'II*\x00', None, 'tiff'),
    (b'MM\x00*', None, 'tiff'),
    (b'GIF8', b'\x00;', 'gif'),
]
def carve(blob):
    out = []
    for magic, term, ext in SIGS:
        start = 0
        while True:
            i = blob.find(magic, start)
            if i == -1: break
            if ext == 'pdf':
                e = blob.find(b'%%EOF', i)
                if e == -1: start = i+1; continue
                data = blob[i:e+5]
            elif ext == 'jpg':
                e = blob.find(b'\xff\xd9', i)
                if e == -1: start = i+1; continue
                data = blob[i:e+2]
            elif ext == 'png':
                e = blob.find(b'IEND', i)
                if e == -1: start = i+1; continue
                data = blob[i:e+8]
            elif ext == 'gif':
                e = blob.find(b'\x00;', i)
                data = blob[i:e+2] if e != -1 else blob[i:]
            else:
                nxt = blob.find(magic, i+1)
                data = blob[i: nxt if nxt != -1 else i+2_000_000]
            out.append((ext, data))
            start = i + len(magic)
    return out
def try_zlib(blob):
    res = []
    i = 0
    while True:
        i = blob.find(b'\x78', i)
        if i == -1 or i > len(blob)-4: break
        try:
            d2 = zlib.decompress(blob[i:i+200000])
            if len(d2) > 1000 and (b'%PDF' in d2 or b'\x89PNG' in d2 or b'\xff\xd8\xff' in d2):
                res.append(d2)
        except Exception:
            pass
        i += 1
    return res
def names_in(blob):
    out = []
    for m in re.findall(rb'[A-Za-z0-9_./+-]{3,48}\.(?:pdf|png|tiff|jpg|svg|carbin|mstore|heic)', blob):
        out.append(m.decode('latin1'))
    seen=set(); res=[]
    for x in out:
        if x not in seen: seen.add(x); res.append(x)
    return res[:6]

manifest = []
total = 0
for f in sorted(os.listdir(BLK)):
    blob = open(os.path.join(BLK, f), 'rb').read()
    bidx = f.replace('block_','').replace('.bin','')
    pieces = carve(blob)
    for nb in try_zlib(blob):
        pieces += carve(nb)
    nm = names_in(blob)
    for k, (ext, data) in enumerate(pieces):
        if len(data) < 64: continue
        fn = f"icon_{bidx}_{k}.{ext}"
        open(os.path.join(OUT, fn), 'wb').write(data)
        manifest.append((fn, ext, len(data), ",".join(nm), bidx))
        total += 1

# rasterize PDFs -> PNG
okpdf = 0
for fn, ext, sz, nm, bidx in [m for m in manifest if m[1]=='pdf']:
    srcp = os.path.join(OUT, fn)
    dst = os.path.join(OUT, fn.rsplit('.',1)[0] + '.png')
    try:
        subprocess.run(['pdftoppm','-r','256','-png',srcp,dst.replace('.png','')], check=True, capture_output=True, timeout=30)
        okpdf += 1
    except Exception as e:
        pass

# manifest
with open(os.path.join(OUT, 'MAP.txt'),'w') as mf:
    mf.write(f"Source: {CAR}\nversion={version} entries={nent} valid={valid}\n")
    mf.write(f"carved={total} pdf_rasterized={okpdf}\n\n")
    mf.write("file                 ext   bytes   block  names\n")
    for fn,ext,sz,nm,bidx in manifest:
        mf.write(f"{fn:22s} {ext:5s} {sz:7d}  {bidx:>5}  {nm}\n")

print(f"carved {total} payloads; pdf->png {okpdf}; out={OUT}")
print("PNG count:", sum(1 for m in manifest if m[1]=='png'))
print("PDF count:", sum(1 for m in manifest if m[1]=='pdf'))
