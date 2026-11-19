#!/usr/bin/env python3
"""Generate macOS-style list icons: a white SF Symbol on a coloured
continuous-corner square, like the rows in System Settings.

  gen_symbol_icons.py <out_dir> name=glyph:#RRGGBB [...]

<glyph> is a named glyph of SF Pro (the "<symbol>.tag.color" glyphs are the
filled symbols) or "bars" (chart bars). Writes <name>.png and @24/@32/@64/@84.
"""
import sys
import numpy as np
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
from PIL import Image, ImageDraw

FONT = '/usr/share/fonts/OTF/SF-Pro-Text-Semibold.otf'
S = 336                      # render size (4× of 84)


class PolyPen(BasePen):
    def __init__(self, gs):
        super().__init__(gs)
        self.polys, self.cur = [], []

    def _moveTo(self, p):
        self.cur = [p]

    def _lineTo(self, p):
        self.cur.append(p)

    def _curveToOne(self, p1, p2, p3):
        p0 = self.cur[-1]
        for i in range(1, 13):
            t = i / 12; mt = 1 - t
            self.cur.append((mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
                             mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1]))

    def _closePath(self):
        if self.cur:
            self.polys.append(self.cur)
        self.cur = []


def glyph_mask(gs, name, box):
    """White glyph, even-odd filled, fitted into a box×box square, centred."""
    pen = PolyPen(gs)
    gs[name].draw(pen)
    pts = [p for poly in pen.polys for p in poly]
    x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
    y0, y1 = min(p[1] for p in pts), max(p[1] for p in pts)
    sc = box / max(x1 - x0, y1 - y0)
    ox = (S - (x1 - x0) * sc) / 2
    oy = (S - (y1 - y0) * sc) / 2
    acc = np.zeros((S, S), np.uint8)
    for poly in pen.polys:
        m = Image.new('L', (S, S), 0)
        ImageDraw.Draw(m).polygon([((x - x0) * sc + ox, S - ((y - y0) * sc + oy)) for x, y in poly], fill=255)
        acc ^= np.array(m)
    return Image.fromarray(acc)


def bars_mask(box):
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    w = box * 0.24; gap = box * 0.14
    x = (S - (3 * w + 2 * gap)) / 2
    base = (S + box) / 2
    for h in (0.45, 1.0, 0.7):
        d.rounded_rectangle((x, base - box * h, x + w, base), radius=w * 0.28, fill=255)
        x += w + gap
    return m


def icon(mask, colour):
    top = tuple(int(colour[i:i + 2], 16) for i in (1, 3, 5))
    bot = tuple(int(c * 0.86) for c in top)
    grad = np.zeros((S, S, 4), np.uint8)
    t = np.linspace(0, 1, S)[:, None]
    for c in range(3):
        grad[..., c] = (top[c] + (bot[c] - top[c]) * t).astype(np.uint8)
    grad[..., 3] = 255
    bg = Image.fromarray(grad, 'RGBA')
    sq = Image.new('L', (S, S), 0)
    ImageDraw.Draw(sq).rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.225), fill=255)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(bg, (0, 0), sq)
    out.paste(Image.new('RGBA', (S, S), 'white'), (0, 0), mask)
    return out


if __name__ == '__main__':
    out_dir = sys.argv[1]
    gs = TTFont(FONT).getGlyphSet()
    for spec in sys.argv[2:]:
        name, rest = spec.split('=', 1)
        glyph, colour = rest.rsplit(':', 1)
        mask = bars_mask(S * 0.52) if glyph == 'bars' else glyph_mask(gs, glyph, S * 0.56)
        img = icon(mask, colour)
        for px in (24, 32, 64, 84):
            img.resize((px, px), Image.LANCZOS).save(f'{out_dir}/{name}@{px}.png')
        img.resize((84, 84), Image.LANCZOS).save(f'{out_dir}/{name}.png')
        print('ok', name)
