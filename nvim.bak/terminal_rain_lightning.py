#!/usr/bin/env python3

import argparse
import curses
import os
import random
import time

# MODIFIED: Throttled frame rate to 20 FPS (1 / 0.05 = 20)
UPDATE_INTERVAL = 0.02 # Original value was 0.015

# --- Rain Configuration ---
RAIN_CHARS = ['|', '.', '`']
COLOR_PAIR_RAIN_NORMAL = 1
COLOR_PAIR_LIGHTNING = 4

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
    def __init__(self, x, y, speed, char):
        self.x = x
        self.y = y
        self.speed = speed
        self.char = char


# --- Lightning ---
LIGHTNING_COLOR_ATTR = None
LIGHTNING_CHANCE = 0.015 # Increased from 0.005
LIGHTNING_CHARS = ['*', '+', '#']
LIGHTNING_GROWTH_DELAY = 0.002
LIGHTNING_MAX_BRANCHES = 2
LIGHTNING_BRANCH_CHANCE = 0.3
FORK_CHANCE = 0.15
FORK_HORIZONTAL_SPREAD = 3
SEGMENT_LIFESPAN = 0.8


class LightningBolt:
    def __init__(self, start_row, start_col, max_y, max_x):
        self.start_col = start_col
        self.target_length = random.randint(max_y // 2, max_y - 2)
        self.segments = [(start_row, start_col, time.time())]
        self.last_growth_time = time.time()
        self.is_growing = True
        self.max_y = max_y
        self.max_x = max_x

    def update(self):
        current_time = time.time()

        # Growth
        if self.is_growing and (current_time - self.last_growth_time >= LIGHTNING_GROWTH_DELAY):
            self.last_growth_time = current_time
            new_segments_this_step = []
            added_segment = False
            last_y, last_x, _ = self.segments[-1]

            if len(self.segments) < self.target_length and last_y < self.max_y - 1:
                branches = 1
                if random.random() < LIGHTNING_BRANCH_CHANCE:
                    branches = random.randint(1, LIGHTNING_MAX_BRANCHES + 1)

                current_x = last_x
                next_primary_x = current_x
                for i in range(branches):
                    offset = random.randint(-2, 2)
                    next_x = max(0, min(self.max_x - 1, current_x + offset))
                    next_y = min(self.max_y - 1, last_y + 1)
                    new_segments_this_step.append((next_y, next_x, current_time))
                    if i == 0: next_primary_x = next_x
                    current_x = next_x
                    added_segment = True

                if random.random() < FORK_CHANCE:
                    fork_offset = random.randint(-FORK_HORIZONTAL_SPREAD, FORK_HORIZONTAL_SPREAD)
                    if fork_offset == 0: fork_offset = random.choice([-1, 1])
                    fork_x = max(0, min(self.max_x - 1, last_x + fork_offset))
                    fork_y = min(self.max_y - 1, last_y + 1)
                    if fork_x != next_primary_x:
                        new_segments_this_step.append((fork_y, fork_x, current_time))
                        added_segment = True

            if not added_segment or len(self.segments) >= self.target_length or last_y >= self.max_y - 1:
                self.is_growing = False

            if new_segments_this_step:
                unique_new = list({(s[0], s[1]): s for s in new_segments_this_step}.values())
                self.segments.extend(unique_new)

        # Check for Removal
        all_expired = True
        if not self.segments:
            return False

        for _, _, creation_time in self.segments:
            if (current_time - creation_time) <= SEGMENT_LIFESPAN:
                all_expired = False
                break
        return not all_expired

    def draw(self, stdscr):
        current_time = time.time()
        max_char_index = len(LIGHTNING_CHARS) - 1

        for y, x, creation_time in self.segments:
            segment_age = current_time - creation_time
            char = ' '

            if segment_age <= SEGMENT_LIFESPAN:
                norm_age = segment_age / SEGMENT_LIFESPAN
                if norm_age < 0.33:
                    char_index = 2
                elif norm_age < 0.66:
                    char_index = 1
                else:
                    char_index = 0
                char = LIGHTNING_CHARS[char_index]
            else:
                continue

            attr = LIGHTNING_COLOR_ATTR
            try:
                max_r, max_c = stdscr.getmaxyx()
                if y < max_r and x < max_c:
                    stdscr.addstr(int(y), int(x), char, attr)
            except curses.error:
                pass


def setup_colors(rain_color_str='cyan', lightning_color_str='yellow'):
    """Initializes color pairs for the rain and lightning based on input strings."""
    global LIGHTNING_COLOR_ATTR
    if curses.has_colors():
        curses.start_color()
        # MODIFIED: Use the terminal's default background for transparency
        curses.use_default_colors()
        bg = -1 # Set background to -1 for transparency

        rain_fg = CURSES_COLOR_MAP.get(rain_color_str.lower(), curses.COLOR_CYAN)
        lightning_fg = CURSES_COLOR_MAP.get(lightning_color_str.lower(), curses.COLOR_YELLOW)

        curses.init_pair(COLOR_PAIR_RAIN_NORMAL, rain_fg, bg)
        curses.init_pair(COLOR_PAIR_LIGHTNING, lightning_fg, bg)
        LIGHTNING_COLOR_ATTR = curses.color_pair(COLOR_PAIR_LIGHTNING) | curses.A_BOLD
        return True
    else:
        # Fallback for terminals without color support
        curses.init_pair(COLOR_PAIR_RAIN_NORMAL, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_LIGHTNING, curses.COLOR_WHITE, curses.COLOR_BLACK)
        LIGHTNING_COLOR_ATTR = curses.color_pair(COLOR_PAIR_LIGHTNING) | curses.A_BOLD
        return False

def simulate_rain(stdscr, rain_color_str='cyan', lightning_color_str='yellow'):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.timeout(1)

    has_colors = setup_colors(rain_color_str, lightning_color_str)
    raindrops = []
    active_bolts = []
    rows, cols = stdscr.getmaxyx()
    is_thunderstorm = True

    last_update_time = time.time()

    while True:
        key = stdscr.getch()
        if key == curses.KEY_RESIZE:
            rows, cols = stdscr.getmaxyx()
            stdscr.clear()
            raindrops.clear()
            active_bolts.clear()
        elif key in [ord('q'), ord('Q'), 27]: # 27 is the Escape key
            break
        elif key in [ord('t'), ord('T')]:
            is_thunderstorm = not is_thunderstorm
            stdscr.clear()

        current_time = time.time()
        delta_time = current_time - last_update_time
        if delta_time < UPDATE_INTERVAL:
            time.sleep(UPDATE_INTERVAL - delta_time)
        last_update_time = time.time()

        # Update Lightning Bolts
        next_bolts = []
        if is_thunderstorm and len(active_bolts) < 3 and random.random() < LIGHTNING_CHANCE:
            start_col = random.randint(cols // 4, 3 * cols // 4)
            start_row = random.randint(0, rows // 5)
            active_bolts.append(LightningBolt(start_row, start_col, rows, cols))

        for bolt in active_bolts:
            if bolt.update():
                next_bolts.append(bolt)
        active_bolts = next_bolts

        # Update Raindrops
        generation_chance = 0.5 if is_thunderstorm else 0.3
        max_new_drops = cols // 8 if is_thunderstorm else cols // 15
        min_speed = 0.3 if is_thunderstorm else 0.3
        max_speed = 1.0 if is_thunderstorm else 0.6

        if random.random() < generation_chance:
            num_new_drops = random.randint(1, max(1, max_new_drops))
            for _ in range(num_new_drops):
                x = random.randint(0, cols - 1)
                y = 0
                speed = random.uniform(min_speed, max_speed)
                char = random.choice(RAIN_CHARS)
                raindrops.append(Raindrop(x, y, speed, char))

        next_raindrops = []
        for drop in raindrops:
            drop.y += drop.speed
            if int(drop.y) < rows:
                next_raindrops.append(drop)
        raindrops = next_raindrops

        # Drawing
        stdscr.clear()

        for bolt in active_bolts:
            bolt.draw(stdscr)

        for drop in raindrops:
            try:
                attr = curses.color_pair(COLOR_PAIR_RAIN_NORMAL)
                if is_thunderstorm:
                    attr |= curses.A_BOLD
                elif drop.speed < 0.8:
                    attr |= curses.A_DIM
                if int(drop.y) < rows:
                    stdscr.addstr(int(drop.y), drop.x, drop.char, attr)
            except curses.error:
                pass
                
        stdscr.noutrefresh()
        curses.doupdate()


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
        try: curses.endwin()
        except Exception: pass
        print(f"\nA curses error occurred: {e}")
        print("Terminal might not fully support curses features (like color/attributes).")
        print("Try resizing the terminal or using a different terminal emulator.")
    except KeyboardInterrupt:
        print("\nExiting...")
    except Exception as e:
        try: curses.endwin()
        except Exception: pass
        print(f"\nAn unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
