#!/usr/bin/env python3
"""Bake a monochrome tint into the shell's icon artwork (macOS "Tinted" style).

usage: tint_icons.py <hex-color> <dir>[:<dir>...] <outdir>

PNGs are tinted in place (same file name); SVGs are rasterised with
rsvg-convert first and stored as <name>.png. One icon file name per line is
printed on stdout; status goes to stderr.
"""
import collections
import glob
import os
import subprocess
import sys
import time
import warnings

warnings.filterwarnings('ignore', category=DeprecationWarning)

from PIL import Image

RASTER_SIZE = 160


def parse_hex(hexs):
    h = str(hexs).strip().lstrip('#')
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    if len(h) != 6:
        return None
    try:
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    except ValueError:
        return None


def load_image(src):
    if src.lower().endswith('.svg'):
        tmp = src + '.tint.png'
        try:
            subprocess.run(['rsvg-convert', '-w', str(RASTER_SIZE), '-h',
                            str(RASTER_SIZE), '-o', tmp, src], check=False,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if not os.path.exists(tmp):
                return None
            im = Image.open(tmp)
            im.load()
            os.remove(tmp)
            return im
        except Exception:
            try:
                os.remove(tmp)
            except OSError:
                pass
            return None
    try:
        im = Image.open(src)
        im.load()
        return im
    except Exception:
        return None


def tint_file(src, dst, rgb):
    im = load_image(src)
    if im is None:
        return False
    if im.mode != 'RGBA':
        im = im.convert('RGBA')
    gray = im.convert('L')
    alpha = im.getchannel('A')
    g = list(gray.getdata())
    a = list(alpha.getdata())
    visible = sorted(gv for gv, av in zip(g, a) if av > 24)
    if visible:
        lo = visible[max(0, int(len(visible) * 0.02))]
        hi = visible[min(len(visible) - 1, int(len(visible) * 0.98))]
    else:
        lo, hi = 0, 255
    n_vis = len(visible)
    if n_vis:
        lo = visible[max(0, int(n_vis * 0.01))]
        hi = visible[min(n_vis - 1, int(n_vis * 0.99))]
        anchor = collections.Counter(visible).most_common(1)[0][0]
    else:
        lo, anchor, hi = 0, 128, 255
    lo = min(lo, anchor)
    hi = max(hi, anchor + 1)
    # macOS-style duotone ramp anchored on the icon's dominant tone: that tone
    # becomes exactly the chosen colour, highlights (glyphs) fade to white and
    # shadows fall off to a darker shade of the same colour.
    luts = []
    for c in rgb:
        tbl = []
        for v in range(256):
            if v <= anchor:
                d = (anchor - v) / float(max(1, anchor - lo))
                d = 0.0 if d < 0 else (1.0 if d > 1 else d)
                out_v = c * (1.0 - 0.32 * d)
            else:
                w = (v - anchor) / float(hi - anchor)
                w = 0.0 if w < 0 else (1.0 if w > 1 else w)
                out_v = c + (255 - c) * w
            tbl.append(min(255, int(out_v + 0.5)))
        luts.append(tbl)
    out = Image.merge('RGBA', (gray.point(luts[0]), gray.point(luts[1]),
                               gray.point(luts[2]), alpha))
    out.save(dst)
    return True


def main():
    if len(sys.argv) < 4:
        print('usage: tint_icons.py <hex> <dirs> <outdir>', file=sys.stderr)
        return 2
    rgb = parse_hex(sys.argv[1])
    if rgb is None:
        print('bad color %r' % sys.argv[1], file=sys.stderr)
        return 2
    dirs = [d for d in sys.argv[2].split(':') if d]
    dst = sys.argv[3]

    marker = os.path.join(dst, '.tint')
    os.makedirs(dst, exist_ok=True)

    need = True
    try:
        with open(marker) as fh:
            need = fh.read().strip().lower() != sys.argv[1].strip().lower()
    except OSError:
        pass

    if need:
        t0 = time.time()
        n = 0
        seen = set()
        for d in dirs:
            for pat in ('*.png', '*.PNG', '*.svg', '*.SVG'):
                for f in glob.glob(os.path.join(d, pat)):
                    base = os.path.splitext(os.path.basename(f))[0]
                    if base in seen:
                        continue
                    seen.add(base)
                    if tint_file(f, os.path.join(dst, base + '.png'), rgb):
                        n += 1
        with open(marker, 'w') as fh:
            fh.write(sys.argv[1].strip().lower())
        print('tinted %d icons in %.2fs' % (n, time.time() - t0), file=sys.stderr)

    for name in sorted(os.listdir(dst)):
        if name.lower().endswith('.png'):
            print(name)
    return 0


if __name__ == '__main__':
    sys.exit(main())
