#!/usr/bin/env python3
"""macOS-like genie minimize for Hyprland.

Choreography mirrors the real macOS genie (Downloads/genie.D0sOVPm_.mp4):
the bottom edge is sucked into the Dock icon almost immediately, the whole
window collapses toward the icon (far edge races, near edge creeps), the
top edge anchors for a blink then slides down the funnel, ending on a point
fully behind the Dock surface so the hand-off to special:minimized is
invisible.

min     [ADDR]            genie-suck the window into its Dock icon, hide it on special:minimized
restore [ADDR] [nofocus]  genie-emit the window back to its original workspace/rect
list                      list minimized windows as JSON
clear                     forget saved state (windows stay hidden)

State: ~/.cache/hypr_minimized.json  (LIFO of {addr, ws, floating, at, size, class, title})

Hyprland 0.56 lua notes:
  hyprctl dispatch '<expr>'  -> wraps expr in hl.dispatch()
  hyprctl eval '<raw lua>'   -> runs raw multi-statement lua (batched resize+move per frame)
"""
import json
import os
import subprocess
import sys
import time
import traceback

STATE_PATH = os.path.expanduser("~/.cache/hypr_minimized.json")
LOG_PATH = os.path.expanduser("~/.cache/hypr_minimize.log")
SPECIAL = "special:minimized"
QSCFG = os.path.expanduser("~/.config/quickshell/macos")
DOCK_NS = "macos:dock"

# Genie timing measured from the real macOS effect
# (~/Downloads/genie.D0sOVPm_.mp4, 30fps: min gone by ~f10, restore f48->f62)
DUR_MIN = 0.36
DUR_RES = 0.45
STEP = 0.015          # frame budget ~66 fps; spring smooths between frames
SETTLE = 0.12         # let the spring settle behind the Dock before hiding
BOTTOM_LEAD = 0.20    # bottom edge reaches the Dock by 20% (ref: first 2-3 frames)
TOP_HOLD = 0.10       # top edge anchors briefly, then slides to the icon (ref)
ICON_W, ICON_H = 16, 16  # absorb point at the Dock icon (ref collapses to a point)


# ─────────────────────────── hyprctl plumbing ───────────────────────────

def log(msg):
    """executor spawns redirect stdout/stderr to /dev/null, so keep our own log."""
    try:
        if os.path.exists(LOG_PATH) and os.path.getsize(LOG_PATH) > 200_000:
            os.remove(LOG_PATH)
        with open(LOG_PATH, "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} {msg}\n")
    except Exception:
        pass


def hypr(args, as_json=False):
    cmd = ["hyprctl"]
    if as_json:
        cmd.append("-j")
    cmd.extend(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=8)
    except Exception:
        return None
    if as_json:
        try:
            return json.loads(r.stdout)
        except Exception:
            return None
    return (r.stdout or "").strip()


def eval_raw(code):
    """Run raw lua; returns hyprctl output so we can log plugin errors."""
    try:
        r = subprocess.run(["hyprctl", "eval", code],
                           capture_output=True, text=True, timeout=5)
        return ((r.stdout or "").strip() or (r.stderr or "").strip())
    except Exception:
        return None


def sel(addr):
    return f'"address:{addr}"'


def clients():
    out = hypr(["clients"], as_json=True)
    return out if isinstance(out, list) else []


def find(addr, cs=None):
    for c in (clients() if cs is None else cs):
        if c.get("address") == addr:
            return c
    return None


def focused_monitor():
    mons = hypr(["monitors"], as_json=True) or []
    for m in mons:
        if m.get("focused"):
            return m
    return mons[0] if mons else None


def active_workspace_id():
    ws = hypr(["activeworkspace"], as_json=True)
    return (ws or {}).get("id")


def workspace_ids():
    wss = hypr(["workspaces"], as_json=True) or []
    return {w.get("id") for w in wss}


def load_state():
    try:
        with open(STATE_PATH) as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except Exception:
        return []


def save_state(entries):
    os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
    tmp = STATE_PATH + ".tmp"
    with open(tmp, "w") as f:
        json.dump(entries, f, indent=1)
    os.replace(tmp, STATE_PATH)


def prune(entries):
    alive = {c.get("address") for c in clients()}
    kept = [e for e in entries if e.get("addr") in alive]
    if kept != entries:
        save_state(kept)
    return kept


def rect_of(c):
    at, size = c.get("at"), c.get("size")
    if not at or not size:
        return None
    return [int(at[0]), int(at[1]), int(size[0]), int(size[1])]


def set_rect(addr, r):
    x, y, w, h = (int(round(v)) for v in r)
    if w < 4 or h < 4:
        return
    s = sel(addr)
    # hl.dsp.* only BUILDS a dispatcher; hl.dispatch executes it.
    # resize anchors at the centre, so resize FIRST, then pin the exact top-left
    eval_raw(
        f"hl.dispatch(hl.dsp.window.resize({{ x = {w}, y = {h}, relative = false, window = {s} }}));"
        f"hl.dispatch(hl.dsp.window.move({{ x = {x}, y = {y}, relative = false, window = {s} }}))"
    )


def move_to_ws(addr, ws):
    w = ws if isinstance(ws, int) else f'"{ws}"'
    eval_raw(f"hl.dispatch(hl.dsp.window.move({{ workspace = {w}, follow = false, window = {sel(addr)} }}))")


def toggle_float(addr):
    eval_raw(f'hl.dispatch(hl.dsp.window.float({{ action = "toggle", window = {sel(addr)} }}))')


def focus_win(addr):
    eval_raw(f"hl.dispatch(hl.dsp.focus({{ window = {sel(addr)} }}))")


def genie_attach(addr, tip, hw, dur, direction):
    """Attach the CGenieTransformer (hl.plugin.genie.attach) — warps the live
    window content into the funnel toward the Dock icon.
    Returns False when the plugin is absent (plan A) so callers fall back to
    the proven rect-genie choreography."""
    tx, ty = tip
    out = eval_raw(
        f'return hl.plugin.genie.attach("{addr}", {tx:.2f}, {ty:.2f}, '
        f'{hw:.2f}, {dur:.3f}, "{direction}")')
    if out and out not in ("ok", ""):
        if "nil value (field 'genie')" in out:
            return False  # plugin disabled — expected, fall back silently
        log(f"genie_attach {addr} dir={direction} -> {out}")
    return out == "ok"


def genie_detach(addr):
    out = eval_raw(f'return hl.plugin.genie.detach("{addr}")')
    if out and out not in ("ok", ""):
        log(f"genie_detach {addr} -> {out}")
    return out == "ok"


# ───────────── quickshell pluginless genie (screencopy funnel) ─────────────

def qs_call(method, *args, timeout=3):
    try:
        r = subprocess.run(["qs", "-p", QSCFG, "ipc", "call", "genie", method, *map(str, args)],
                           capture_output=True, text=True, timeout=timeout)
        if r.returncode == 0:
            return (r.stdout or "").strip()
    except Exception as e:
        log(f"qs_call {method}: {e}")
    return ""


def qs_prepare(addr, rect, tip, direction):
    """Freeze the live window content inside quickshell; True when ready to play."""
    x, y, w, h = rect
    out = qs_call("prepare", addr, f"{x:.1f}", f"{y:.1f}", f"{w:.1f}", f"{h:.1f}",
                  f"{tip[0]:.1f}", f"{tip[1]:.1f}", direction)
    if out == "ok" and qs_ready():
        return True
    qs_cancel()
    if out != "ok":
        log(f"qs_prepare {addr} dir={direction} -> {out or 'no-reply'}")
    return False


def qs_ready(timeout=1.0):
    t0 = time.monotonic()
    while time.monotonic() - t0 < timeout:
        s = qs_call("status", timeout=1)
        if s == "ready":
            return True
        if s in ("", "idle"):
            return False
        time.sleep(0.015)
    return False


def qs_go():
    return qs_call("go") == "ok"


def qs_cancel():
    qs_call("cancel")


# ─────────────────────────── Dock geometry ───────────────────────────

def dock_rect():
    out = hypr(["layers"], as_json=True) or {}
    for _mon, payload in out.items():
        for _lvl, arr in (payload.get("levels") or {}).items():
            for lay in arr:
                if lay.get("namespace") == DOCK_NS:
                    return [lay["x"], lay["y"], lay["w"], lay["h"]]
    return None


def icon_center(cls, dock):
    """Global centre of the app's Dock icon (quickshell knows the layout)."""
    x, y, _w, _h = dock
    try:
        r = subprocess.run(["qs", "-p", QSCFG, "ipc", "call", "dock", "iconRect", cls or ""],
                           capture_output=True, text=True, timeout=3)
        if r.returncode == 0 and "," in (r.stdout or ""):
            lx, ly = r.stdout.strip().split(",")[:2]
            return [x + float(lx), y + float(ly)]
    except Exception:
        pass
    return [x + dock[2] / 2.0, y + dock[3] - 40.0]


def target_rect(cls):
    """Absorb rect: full-size icon box whose bottom sits flush with the Dock
    surface, so at s=1 the window is completely hidden behind the Dock."""
    dock = dock_rect()
    if not dock:
        mon = focused_monitor() or {"x": 0, "y": 0, "width": 2560, "height": 1600}
        cx = mon["x"] + mon["width"] // 2
        by = mon["y"] + mon["height"]
        return [cx - ICON_W // 2, by - ICON_H, ICON_W, ICON_H]
    cx, _cy = icon_center(cls, dock)
    left, right = dock[0] + 6, dock[0] + dock[2] - 6 - ICON_W
    x = min(max(cx - ICON_W / 2.0, left), max(left, right))
    y = dock[1] + dock[3] - ICON_H
    return [x, y, ICON_W, ICON_H]


# ─────────────────────────── genie math ───────────────────────────

def _lerp(a, b, t):
    return a + (b - a) * t


def _smooth(u):
    """Smootherstep: symmetric about (0.5, 0.5) so restore is the exact
    time-reverse of minimize."""
    if u <= 0.0:
        return 0.0
    if u >= 1.0:
        return 1.0
    return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)


def genie(s, r0, a):
    """Rect at genie progress s in [0, 1].

    s=0 -> original rect r0, s=1 -> absorb point a (at the Dock icon).
    Real-macOS choreography (see header):
      bottom edge -> Dock by s=BOTTOM_LEAD (leading edge sweeps in first)
      top edge    -> holds for TOP_HOLD, then slides to the icon
      x/width     -> scale toward the icon over the whole timeline, so the
                     far edge races while the near edge barely creeps
    """
    x0, y0, w0, h0 = r0
    xA, yA, wA, hA = a
    pb = _smooth(min(s / BOTTOM_LEAD, 1.0))
    pt = _smooth((s - TOP_HOLD) / (1.0 - TOP_HOLD))
    px = _smooth(s)

    bottom = _lerp(y0 + h0, yA + hA, pb)
    top = _lerp(y0, yA, pt)
    if bottom - top < 6.0:
        top = bottom - 6.0

    x = _lerp(x0, xA, px)
    w = _lerp(w0, wA, px)
    if w < 6.0:
        w = 6.0
    return [x, top, w, bottom - top]


def _pace(deadline):
    d = deadline - time.monotonic()
    if d > 0:
        time.sleep(d)


def animate(addr, r0, a, mode):
    dur = DUR_MIN if mode == "in" else DUR_RES
    steps = max(8, int(round(dur / STEP)))
    t0 = time.monotonic()
    for i in range(1, steps + 1):
        s = i / steps if mode == "in" else 1.0 - i / steps
        set_rect(addr, genie(s, r0, a))
        _pace(t0 + dur * i / steps)
    set_rect(addr, genie(1.0 if mode == "in" else 0.0, r0, a))


def animatable(c):
    if c.get("fullscreen"):
        return False
    if c.get("grouped"):
        return False
    if c.get("at") is None or c.get("size") is None:
        return False
    return True


# ─────────────────────────── commands ───────────────────────────

def cmd_min(addr=None):
    if addr:
        c = find(addr)
    else:
        aw = hypr(["activewindow"], as_json=True)
        addr = (aw or {}).get("address")
        c = find(addr) if addr else None
    if not c:
        return 0
    name = ((c.get("workspace") or {}).get("name")) or ""
    if name.startswith("special:"):
        log(f"min {addr} already on {name}, skip")
        return 0

    entries = prune(load_state())
    if any(e.get("addr") == addr for e in entries):
        log(f"min {addr} state entry exists, skip (in progress?)")
        return 0
    entry = {
        "addr": addr,
        "ws": (c.get("workspace") or {}).get("id"),
        "floating": bool(c.get("floating")),
        "fullscreen": c.get("fullscreen", 0),
        "at": rect_of(c),
        "size": list(c.get("size") or []),
        "class": c.get("class"),
        "title": c.get("title"),
        "ts": int(time.time()),
    }
    entries.append(entry)
    save_state(entries)

    qsv = False
    if animatable(c):
        r0 = rect_of(c)
        tgt = target_rect(entry.get("class"))
        tip = (tgt[0] + tgt[2] / 2.0, tgt[1] + tgt[3] / 2.0)
        log(f"min {addr} class={entry.get('class')} r0={r0} tip={tip}")
        if r0 and r0[2] > 2 and r0[3] > 2:
            # pluginless qs genie: rows carry the frozen content into the Dock
            # icon; the window is yanked right after the first covered frames
            if qs_prepare(addr, r0, tip, "in") and qs_go():
                qsv = True
                entry["qsv"] = True
                save_state(entries)
                time.sleep(0.04)
                move_to_ws(addr, SPECIAL)
                time.sleep(DUR_MIN + 0.06)
                log(f"min {addr} qs-warp done")
            if not qsv:
                # plan A fallback: proven rect-genie toward the Dock icon
                if not c.get("floating"):
                    toggle_float(addr)
                    c = find(addr) or c
                r0 = rect_of(c)
                animate(addr, r0, tgt, "in")
                time.sleep(SETTLE)
                log(f"min {addr} rect-anim done")
        else:
            log(f"min {addr} tiny rect, skip anim")
    else:
        log(f"min {addr} not animatable (fs/group)")

    if not qsv:
        move_to_ws(addr, SPECIAL)
    log(f"min {addr} hidden on {SPECIAL}")
    return 0


def cmd_restore(addr=None, nofocus=False):
    entries = prune(load_state())
    if not entries:
        save_state(entries)
        return 0
    if addr:
        picked = None
        for i, e in enumerate(entries):
            if e.get("addr") == addr:
                picked = entries.pop(i)
                break
        if picked is None:
            save_state(entries)
            return 0
    else:
        picked = entries.pop()
    save_state(entries)

    a = picked["addr"]
    c = find(a)
    if not c:
        log(f"restore {a} window gone")
        return 0
    # stale guard: only windows actually sitting in the minimized special workspace
    name = ((c.get("workspace") or {}).get("name")) or ""
    if not name.startswith("special:"):
        log(f"restore {a} not on special (on {name}), drop entry")
        return 0

    dest = picked.get("ws")
    if dest not in workspace_ids():
        dest = active_workspace_id()

    was_tiled = not picked.get("floating")
    r1 = None
    if picked.get("at") and picked.get("size"):
        r1 = picked["at"][:2] + picked["size"][:2]

    qsv = False
    rect_fallback = False
    tgt = None
    if animatable(c) and r1 and r1[2] > 2 and r1[3] > 2:
        # legacy entries (pre-warp script) park the window on a 16x16 point
        # while hidden — restore the real rect first (invisible: still on special)
        r_cur = rect_of(c)
        if r_cur and (r_cur[2] < r1[2] // 2 or r_cur[3] < r1[3] // 2):
            set_rect(a, r1)
            time.sleep(0.02)
        tgt = target_rect(picked.get("class"))
        tip = (tgt[0] + tgt[2] / 2.0, tgt[1] + tgt[3] / 2.0)
        log(f"restore {a} dest={dest} r1={r1} from={tip}")
        if picked.get("qsv"):
            # frozen frame ejects from the Dock icon; reveal only once it settles
            if qs_prepare(a, r1, tip, "out") and qs_go():
                qsv = True
        if not qsv:
            # legacy/park path: park at the icon while hidden, rect anim on reveal
            if not (find(a) or {}).get("floating"):
                toggle_float(a)  # cache-fail on a tiled window: rect anim needs float
            set_rect(a, tgt)
            rect_fallback = True

    if qsv:
        time.sleep(DUR_RES + 0.06)
        move_to_ws(a, dest)
        log(f"restore {a} qs-emit done")
    else:
        move_to_ws(a, dest)
        if rect_fallback:
            animate(a, r1, tgt, "out")
            log(f"restore {a} rect-anim done")

    if was_tiled:
        c = find(a)
        if c and c.get("floating"):
            toggle_float(a)

    if not nofocus:
        focus_win(a)
    log(f"restore {a} done ws={dest} tiled={was_tiled}")
    return 0


def _ids_match(cls, ids):
    if not cls:
        return False
    c = str(cls).lower()
    for i in ids:
        i = str(i or "").lower().strip()
        if not i:
            continue
        if i in c or c in i:
            return True
    return False


def cmd_hasmin(ids):
    """'1' if any minimized window matches these app ids/classes (dock click probe)."""
    entries = prune(load_state())
    print("1" if any(_ids_match(e.get("class"), ids) for e in entries) else "0")
    return 0


def cmd_clickrestore(ids):
    """Restore every minimized window belonging to the clicked dock app."""
    entries = prune(load_state())
    if not entries:
        return 0
    rc = 0
    for e in [e for e in entries if _ids_match(e.get("class"), ids)]:
        rc = cmd_restore(e.get("addr")) or rc
    return rc


def cmd_list():
    entries = prune(load_state())
    print(json.dumps(entries, indent=1))
    return 0


def cmd_clear():
    try:
        os.remove(STATE_PATH)
    except FileNotFoundError:
        pass
    return 0


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 1
    op = args[0]
    try:
        if op == "min":
            return cmd_min(args[1] if len(args) > 1 else None)
        if op == "restore":
            addr = None
            nofocus = False
            for a in args[1:]:
                if a == "nofocus":
                    nofocus = True
                else:
                    addr = a
            return cmd_restore(addr, nofocus)
        if op == "hasmin":
            return cmd_hasmin(args[1:])
        if op == "clickrestore":
            return cmd_clickrestore(args[1:])
        if op == "list":
            return cmd_list()
        if op == "clear":
            return cmd_clear()
    except Exception as ex:
        log(f"ERROR {op}: {ex}\n{traceback.format_exc()}")
        print(f"minimize_window: {ex}", file=sys.stderr)
        return 1
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
