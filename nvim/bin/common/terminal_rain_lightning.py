#!/usr/bin/env python3

import argparse
import curses
import os
import random
import time

# Frame interval for 20 FPS (prevents terminal event-loop saturation in Neovim)
UPDATE_INTERVAL = 0.05

# --- Rain Configuration ---
RAIN_CHARS = ['│', '|', ':', '·', '.']
COLOR_PAIR_RAIN = 1
COLOR_PAIR_RAIN_DIM = 2
COLOR_PAIR_LIGHTNING = 3

# Defined curses color names (lowercase) for argument parsing
CURSES_COLOR_MAP = {
    'black': curses.COLOR_BLACK,
    'red': curses.COLOR_RED,
    'green': curses.COLOR_GREEN,
    'yellow': curses.COLOR_YELLOW,
    'blue': curses.COLOR_BLUE,
    'magenta': curses.COLOR_MAGENTA,
    'cyan': curses.COLOR_CYAN,
    'white': curses.COLOR_WHITE,
}


class Raindrop:
    __slots__ = ('x', 'y', 'speed', 'char', 'attr')

    def __init__(self, x, y, speed, char, attr):
        self.x = x
        self.y = y
        self.speed = speed
        self.char = char
        self.attr = attr


# --- Lightning ---
LIGHTNING_CHANCE = 0.035
LIGHTNING_CHARS = ['*', '+', '#']


class LightningBolt:
    __slots__ = ('segments', 'created_at', 'lifespan')

    def __init__(self, start_row, start_col, max_y, max_x):
        self.segments = []
        self.created_at = time.time()
        self.lifespan = random.uniform(0.40, 0.60)  # Visible for 400-600ms (~8-12 frames)

        # Generate the full lightning branch tree instantly on strike
        cur_x = start_col
        cur_y = start_row
        target_len = random.randint(max_y * 2 // 3, max_y - 1)

        while cur_y < target_len and cur_y < max_y - 1:
            self.segments.append((cur_y, cur_x))
            # Branching
            if random.random() < 0.22:
                fork_x = max(0, min(max_x - 1, cur_x + random.choice([-2, -1, 1, 2])))
                self.segments.append((cur_y + 1, fork_x))
            cur_x = max(0, min(max_x - 1, cur_x + random.randint(-1, 1)))
            cur_y += 1

    def is_alive(self, now):
        return (now - self.created_at) < self.lifespan

    def draw(self, stdscr, now, attr_bold, attr_norm, attr_dim, max_r, max_c):
        age = now - self.created_at
        progress = age / self.lifespan

        # Multi-stage realistic lightning decay with natural flicker
        if progress < 0.25:
            # Stage 1: Main intense strike
            char = '#'
            attr = attr_bold
        elif progress < 0.50:
            # Stage 2: Discharge flicker
            char = '+' if (int(age * 20) % 2 == 0) else '#'
            attr = attr_bold
        elif progress < 0.75:
            # Stage 3: Afterglow
            char = '*'
            attr = attr_norm
        else:
            # Stage 4: Dissipating ionization trail
            char = '·'
            attr = attr_dim

        for y, x in self.segments:
            if 0 <= y < max_r and 0 <= x < max_c:
                try:
                    stdscr.addstr(y, x, char, attr)
                except curses.error:
                    pass


def setup_colors(rain_color_str='cyan', lightning_color_str='yellow'):
    """Initializes color pairs for rain and lightning."""
    if curses.has_colors():
        curses.start_color()
        curses.use_default_colors()
        bg = -1  # Transparent background

        rain_fg = CURSES_COLOR_MAP.get(rain_color_str.lower(), curses.COLOR_CYAN)
        lightning_fg = CURSES_COLOR_MAP.get(lightning_color_str.lower(), curses.COLOR_YELLOW)

        curses.init_pair(COLOR_PAIR_RAIN, rain_fg, bg)
        curses.init_pair(COLOR_PAIR_RAIN_DIM, rain_fg, bg)
        curses.init_pair(COLOR_PAIR_LIGHTNING, lightning_fg, bg)
        return True
    else:
        curses.init_pair(COLOR_PAIR_RAIN, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_RAIN_DIM, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_LIGHTNING, curses.COLOR_WHITE, curses.COLOR_BLACK)
        return False


def simulate_rain(stdscr, rain_color_str='cyan', lightning_color_str='yellow'):
    curses.curs_set(0)
    stdscr.nodelay(True)
    setup_colors(rain_color_str, lightning_color_str)

    # Pre-cache attributes to avoid calling curses.color_pair inside per-drop loops
    attr_rain_bold = curses.color_pair(COLOR_PAIR_RAIN) | curses.A_BOLD
    attr_rain_norm = curses.color_pair(COLOR_PAIR_RAIN)
    attr_rain_dim = curses.color_pair(COLOR_PAIR_RAIN_DIM) | curses.A_DIM

    attr_lt_bold = curses.color_pair(COLOR_PAIR_LIGHTNING) | curses.A_BOLD
    attr_lt_norm = curses.color_pair(COLOR_PAIR_LIGHTNING)
    attr_lt_dim = curses.color_pair(COLOR_PAIR_LIGHTNING) | curses.A_DIM

    raindrops = []
    active_bolts = []
    rows, cols = stdscr.getmaxyx()
    is_thunderstorm = True

    while True:
        frame_start = time.perf_counter()

        # Handle keyboard input
        key = stdscr.getch()
        if key == curses.KEY_RESIZE:
            rows, cols = stdscr.getmaxyx()
            stdscr.erase()
            raindrops.clear()
            active_bolts.clear()
        elif key in (ord('q'), ord('Q'), 27):
            break
        elif key in (ord('t'), ord('T')):
            is_thunderstorm = not is_thunderstorm
            stdscr.erase()

        now = time.time()

        # Update Lightning Bolts
        if is_thunderstorm and len(active_bolts) < 2 and random.random() < LIGHTNING_CHANCE:
            start_col = random.randint(cols // 4, 3 * cols // 4)
            start_row = random.randint(0, rows // 6)
            active_bolts.append(LightningBolt(start_row, start_col, rows, cols))

        active_bolts = [b for b in active_bolts if b.is_alive(now)]

        # Spawn Raindrops (controlled density with natural falling speeds)
        max_spawn = max(2, cols // 25 if is_thunderstorm else cols // 35)
        spawn_count = random.randint(1, max_spawn)
        min_speed = 1.2 if is_thunderstorm else 0.8
        max_speed = 2.2 if is_thunderstorm else 1.5

        for _ in range(spawn_count):
            x = random.randint(0, cols - 1)
            speed = random.uniform(min_speed, max_speed)
            char = random.choice(RAIN_CHARS)
            if is_thunderstorm:
                attr = attr_rain_bold if speed > 1.7 else attr_rain_norm
            else:
                attr = attr_rain_norm if speed > 1.1 else attr_rain_dim
            raindrops.append(Raindrop(x, 0.0, speed, char, attr))

        # Update Raindrops
        next_raindrops = []
        for drop in raindrops:
            drop.y += drop.speed
            if int(drop.y) < rows:
                next_raindrops.append(drop)
        raindrops = next_raindrops

        # Draw using erase() instead of clear() to avoid clearok full-screen resets
        stdscr.erase()

        for bolt in active_bolts:
            bolt.draw(stdscr, now, attr_lt_bold, attr_lt_norm, attr_lt_dim, rows, cols)

        for drop in raindrops:
            iy = int(drop.y)
            if 0 <= iy < rows and 0 <= drop.x < cols:
                try:
                    stdscr.addstr(iy, drop.x, drop.char, drop.attr)
                except curses.error:
                    pass

        stdscr.noutrefresh()
        curses.doupdate()

        # Precise frame interval pacing
        elapsed = time.perf_counter() - frame_start
        sleep_time = UPDATE_INTERVAL - elapsed
        if sleep_time > 0:
            time.sleep(sleep_time)


def main():
    if not os.isatty(1) or os.environ.get('TERM') == 'dumb':
        print("Error: This script requires a TTY with curses support.")
        return

    parser = argparse.ArgumentParser(description="Simulates rain and thunderstorms in the terminal.")
    valid_colors = list(CURSES_COLOR_MAP.keys())
    parser.add_argument(
        '--rain-color',
        type=str,
        default='cyan',
        choices=valid_colors,
        help=f"Color for the rain. Default: cyan. Choices: {', '.join(valid_colors)}"
    )
    parser.add_argument(
        '--lightning-color',
        type=str,
        default='yellow',
        choices=valid_colors,
        help=f"Color for the lightning. Default: yellow. Choices: {', '.join(valid_colors)}"
    )
    args = parser.parse_args()

    try:
        curses.wrapper(simulate_rain, args.rain_color, args.lightning_color)
    except curses.error as e:
        try:
            curses.endwin()
        except Exception:
            pass
        print(f"\nA curses error occurred: {e}")
    except KeyboardInterrupt:
        print("\nExiting...")
    except Exception as e:
        try:
            curses.endwin()
        except Exception:
            pass
        print(f"\nAn unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
