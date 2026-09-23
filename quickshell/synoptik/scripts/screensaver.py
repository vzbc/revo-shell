#!/usr/bin/env python3
"""
Synoptik Screensaver - Floating Bouncing DVD Logo for Shell / Terminal
Part of the Synoptik Quickshell desktop environment.
"""

import argparse
import curses
import os
import signal
import sys
import time
from datetime import datetime

# ASCII Art Banners for retro DVD / Synoptik display
BANNERS = {
    "DVD": [
        r" ____  _     ____ ",
        r"|  _ \ \ \  / /  _ \ ",
        r"| | | | \ \/ /| | | |",
        r"| |_| |  \  / | |_| |",
        r"|____/    \/  |____/ ",
        r"   V I D E O         ",
    ],
    "SYNOPTIK": [
        r" _____ _   _ _   _ _____ ____ _____ ___ _  __",
        r"/  ___| | | | \ | |  _  |  _ \_   _|_ _| |/ /",
        r"\ `--.| |_| |  \| | | | | |_) || |   | || ' / ",
        r" `--. \  _  | . ` | | | |  __/ | |   | || . \ ",
        r"/\__/ / | | | |\  \ \_/ / |    | |  _| || |\ \\",
        r"\____/\_| |_\_| \_/\___/|_|    \_/ |___|\_| \_/",
    ],
}


def build_color_palette():
    """Initialize curses color pairs."""
    curses.use_default_colors()

    # Standard terminal colors
    palette_colors = [
        curses.COLOR_CYAN,
        curses.COLOR_MAGENTA,
        curses.COLOR_YELLOW,
        curses.COLOR_GREEN,
        curses.COLOR_BLUE,
        curses.COLOR_RED,
    ]

    # If 256 colors are supported, add vibrant neon colors
    if curses.can_change_color() or curses.COLORS >= 256:
        extra_colors = [45, 51, 81, 118, 198, 201, 208, 214, 220, 226]
        pair_id = 1
        for c in palette_colors:
            curses.init_pair(pair_id, c, -1)
            pair_id += 1
        for ec in extra_colors:
            if ec < curses.COLORS:
                curses.init_pair(pair_id, ec, -1)
                pair_id += 1
        return list(range(1, pair_id))
    else:
        for i, c in enumerate(palette_colors, 1):
            curses.init_pair(i, c, -1)
        return list(range(1, len(palette_colors) + 1))


def draw_object(stdscr, y, x, lines, color_attr, max_y, max_x):
    """Draws multi-line text safely within screen boundaries."""
    for idx, line in enumerate(lines):
        target_y = y + idx
        if 0 <= target_y < max_y:
            # Clip horizontal string to fit within screen
            if x < max_x:
                visible_text = line
                start_col = x
                if start_col < 0:
                    visible_text = line[-start_col:]
                    start_col = 0
                visible_text = visible_text[: max_x - start_col]
                if visible_text:
                    try:
                        stdscr.addstr(
                            target_y, start_col, visible_text, color_attr
                        )
                    except curses.error:
                        pass


def run_screensaver(stdscr, args):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.keypad(True)

    color_pairs = build_color_palette()
    num_pairs = len(color_pairs)
    color_idx = 0

    # Determine display lines
    raw_text = args.text.strip()
    is_banner = args.banner

    if args.activate:
        lines = [
            "  Activate Linux  ",
            "  Go to Settings to activate Linux  "
        ]
        get_lines = lambda: lines
    elif args.clock:

        def get_lines():
            now_str = datetime.now().strftime("%H:%M:%S")
            date_str = datetime.now().strftime("%a, %b %d")
            return [f"  {now_str}  ", f"  {date_str}  "]

    elif is_banner:
        key = raw_text.upper()
        if key in BANNERS:
            lines = BANNERS[key]
        else:
            lines = [f"[ {raw_text} ]"]
        get_lines = lambda: lines
    else:
        lines = [f" {raw_text} "]
        get_lines = lambda: lines

    # Initial state
    y, x = 2, 2
    dy, dx = 1, 1
    corner_hits = 0
    flash_frames = 0

    while True:
        # Check for user input / keypress to exit
        ch = stdscr.getch()
        if ch != -1:
            break

        max_y, max_x = stdscr.getmaxyx()
        current_lines = get_lines()
        obj_height = len(current_lines)
        obj_width = max(len(l) for l in current_lines)

        # Collision detection
        hit_v = False
        hit_h = False

        if y + dy + obj_height > max_y:
            dy = -1
            hit_v = True
        elif y + dy < 0:
            dy = 1
            hit_v = True

        if x + dx + obj_width > max_x:
            dx = -1
            hit_h = True
        elif x + dx < 0:
            dx = 1
            hit_h = True

        # Check corner hit easter egg!
        if hit_v and hit_h:
            corner_hits += 1
            flash_frames = 6  # flash on corner hit

        # Update color on bounce
        if hit_v or hit_h:
            color_idx = (color_idx + 1) % num_pairs

        y = max(0, min(max_y - obj_height, y + dy))
        x = max(0, min(max_x - obj_width, x + dx))

        stdscr.erase()

        # Choose color attribute
        current_pair = color_pairs[color_idx]
        attr = curses.color_pair(current_pair) | curses.A_BOLD
        if flash_frames > 0:
            attr |= curses.A_REVERSE
            flash_frames -= 1

        draw_object(stdscr, y, x, current_lines, attr, max_y, max_x)

        # Subtle corner hits indicator (bottom right) if any recorded
        if args.show_stats and corner_hits > 0 and max_y > 2:
            stats_str = f" Corner Hits: {corner_hits} "
            try:
                stdscr.addstr(
                    max_y - 1,
                    max(0, max_x - len(stats_str) - 1),
                    stats_str,
                    curses.A_DIM,
                )
            except curses.error:
                pass

        stdscr.refresh()
        time.sleep(args.speed)


def main():
    parser = argparse.ArgumentParser(
        description="Synoptik Screensaver - Floating Bouncing DVD Logo"
    )
    parser.add_argument(
        "-t",
        "--text",
        default="SYNOPTIK",
        help="Text to display (default: 'SYNOPTIK')",
    )
    parser.add_argument(
        "-b",
        "--banner",
        action="store_true",
        help="Render stylized ASCII banner for text (supports 'SYNOPTIK', 'DVD')",
    )
    parser.add_argument(
        "-a",
        "--activate",
        action="store_true",
        help="Display 'Activate Linux - Go to Settings to activate Linux'",
    )
    parser.add_argument(
        "-c",
        "--clock",
        action="store_true",
        help="Display bouncing digital clock and date",
    )
    parser.add_argument(
        "-s",
        "--speed",
        type=float,
        default=0.035,
        help="Frame delay in seconds (default: 0.035 ~ 30 FPS)",
    )
    parser.add_argument(
        "--show-stats",
        action="store_true",
        default=True,
        help="Show corner hit statistics counter",
    )

    args = parser.parse_args()

    # Signal handlers for clean exit
    def sig_handler(signum, frame):
        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    try:
        curses.wrapper(lambda stdscr: run_screensaver(stdscr, args))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
