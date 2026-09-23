#!/usr/bin/env python3
"""Filter HYG v41 to naked-eye stars (mag<=6.5) and emit a QML JS pragma-library
module with flat arrays ready for ScatterInstancing.positions/colors/customData.

This script is invoked automatically by ensure_starfield.sh which in turn is
invoked by QML... let's call it seperation of concerns and pretend this is a
competent project, alright?

It could also be run directly: `python3 build_starfield.py [src.csv] [out.js]`,
defaulting to hygdata_v41.csv in the cwd and widgets/globe3d/RealStarField.js.

Color: B-V color index -> temperature (Ballesteros 2012) -> RGB (Tanner Helland's
fit of Mitchell Charity's blackbody dataset) -> linear->sRGB pre-encode.

Size/intensity: magnitude -> a 0..1 brightness curve.
"""
import csv
import math
import json
import os

import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else "hygdata_v41.csv"
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "widgets", "globe3d", "RealStarField.js")
MAG_LIMIT = 6.5


def bv_to_rgb(bv):
    # Clamp to the range the Ballesteros fit is stable over.
    bv = max(-0.4, min(2.0, bv))
    t = 4600.0 * (1.0 / (0.92 * bv + 1.7) + 1.0 / (0.92 * bv + 0.62))
    return kelvin_to_rgb(t)


def kelvin_to_rgb(temp_k):
    t = temp_k / 100.0

    if t <= 66:
        r = 255.0
    else:
        r = 329.698727446 * ((t - 60) ** -0.1332047592)

    if t <= 66:
        g = 99.4708025861 * math.log(t) - 161.1195681661
    else:
        g = 288.1221695283 * ((t - 60) ** -0.0755148492)

    if t >= 66:
        b = 255.0
    elif t <= 19:
        b = 0.0
    else:
        b = 138.5177312231 * math.log(t - 10) - 305.0447927307

    r = max(0.0, min(255.0, r)) / 255.0
    g = max(0.0, min(255.0, g)) / 255.0
    b = max(0.0, min(255.0, b)) / 255.0
    return r, g, b


def linear_to_srgb(c):
    c = max(0.0, min(1.0, c))
    if c <= 0.0031308:
        return 12.92 * c
    return 1.055 * (c ** (1.0 / 2.4)) - 0.055


def log_mix(a, b, t):
    return a * (b / a) ** t


def main():
    rows = []
    with open(SRC, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["id"] == "0":
                continue  # sol itself, not a background star
                # I will probably make a future special frag/vert
                # specifically for sol.
            try:
                mag = float(row["mag"])
            except ValueError:
                continue
            if mag > MAG_LIMIT:
                continue
            try:
                ra = float(row["rarad"])
                dec = float(row["decrad"])
            except ValueError:
                continue
            ci_raw = row["ci"].strip()
            ci = float(ci_raw) if ci_raw else 0.65 # whatever, it'll work
            rows.append((mag, ra, dec, ci))

    rows.sort(key=lambda r: r[0])  # brightest (lowest mag) first

    mag_bright = -1.5  # a little past "Sirius" (-1.46), gives headroom!
    mag_faint = MAG_LIMIT

    positions = []
    colors = []
    custom = []

    for mag, ra, dec, ci in rows:
        # Same convention as AssemblyGlobeView.qml's latLonToVec (dec<->lat,
        # ra<->lon, x negated for the same QtQuick3D handedness quirk that
        # function's comment warns about) so the globe's own rotation axis
        # lines up exactly with celestial north/south, and ra=0 (the vernal
        # equinox direction) lines up with lon=0 (Greenwich) as a fixed,
        # reference. In reality (spooooooky~), sidereal alignment drifts with
        # time of day/year, which... I just don't wanna deal with right now.
        # Best solution for that is to rotate the earth itself, instead of all
        # the stars.
        x = -math.cos(dec) * math.cos(ra)
        y = math.sin(dec)
        z = math.cos(dec) * math.sin(ra)
        positions.extend([round(x, 5), round(y, 5), round(z, 5)])

        r, g, b = bv_to_rgb(ci)
        colors.extend([
            round(linear_to_srgb(r), 4),
            round(linear_to_srgb(g), 4),
            round(linear_to_srgb(b), 4),
            1.0,
        ])

        t = (mag_faint - mag) / (mag_faint - mag_bright)
        t = max(0.0, min(1.0, t))
        size_scale = log_mix(0.5, 3.2, t)
        intensity_scale = log_mix(0.3, 2.8, t)
        custom.extend([round(size_scale, 4), round(intensity_scale, 4), 0.0, 0.0])

    with open(OUT, "w") as f:
        f.write(".pragma library\n\n")
        f.write(f"// Generated from HYG v41, {len(rows)} stars, mag<=%s.\n" % MAG_LIMIT)
        f.write("// Sorted brightest-first so callers can slice(0, n*STRIDE) for an N-brightest cutoff.\n")
        f.write("var STAR_COUNT = %d\n\n" % len(rows))
        f.write("var POSITIONS = " + json.dumps(positions, separators=(",", ":")) + "\n\n")
        f.write("var COLORS = " + json.dumps(colors, separators=(",", ":")) + "\n\n")
        f.write("var CUSTOM_DATA = " + json.dumps(custom, separators=(",", ":")) + "\n")

    print(f"{len(rows)} stars written to {OUT}")


if __name__ == "__main__":
    main()
