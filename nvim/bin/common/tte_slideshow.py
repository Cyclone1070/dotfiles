#!/usr/bin/env python3
"""Interactive TerminalTextEffects sequential reviewer with live performance stats."""

import os
import sys
import time
import select
import signal
import shutil
import termios
import tty
import psutil
import gc
import re
import random
import json
import wcwidth

# Add terminaltexteffects repo to sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
submodule_path = os.path.join(SCRIPT_DIR, "terminaltexteffects")
if os.path.exists(submodule_path) and submodule_path not in sys.path:
    sys.path.insert(0, submodule_path)
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

try:
    import importlib.metadata

    _orig_version = importlib.metadata.version

    def _safe_version(pkg):
        try:
            return _orig_version(pkg)
        except Exception:
            return "0.15.0"

    importlib.metadata.version = _safe_version

    from terminaltexteffects.__main__ import build_parser
    from terminaltexteffects.engine.terminal import TerminalConfig
except ImportError:
    print(
        f"Error: terminaltexteffects package not found in {SCRIPT_DIR}",
        file=sys.stderr,
    )
    sys.exit(1)

## Tier 1 + Tier 2 animations (Tier 3 excluded: beams, smoke, synthgrid)
ACTIVE_EFFECTS = [
    # Tier 1 (> 10.0 FPS)
    "blackhole",
    "bubbles",
    # "errorcorrect",  # excluded
    # "highlight", # excluded: lame
    # "matrix",  # excluded: slow
    "middleout",
    "orbittingvolley",
    "pour",
    "print",
    "rain",
    "randomsequence",
    "slice",
    "slide",
    "spotlights",
    "spray",
    "unstable",
    # "wipe", # excluded: lame
    # Tier 2 (6.0 - 10.0 FPS)
    "binarypath",
    "bouncyballs",
    "burn",
    "colorshift",
    "crumble",
    "decrypt",
    "expand",
    "fireworks",
    "laseretch",
    # "overflow", # exclude: epilepsy induced
    "rings",
    "scattered",
    "swarm",
    "sweep",
    "thunderstorm",
    "vhstape",
    "waves",
]

# Tier 3 animations (< 6.0 FPS) - excluded:
# "beams", "smoke", "synthgrid"


def clear_all_caches():
    """Clear geometry and graphics LRU caches to prevent unbounded memory growth."""
    try:
        from terminaltexteffects.utils import geometry, graphics, easing

        for mod in (geometry, graphics, easing):
            for attr in dir(mod):
                obj = getattr(mod, attr)
                if hasattr(obj, "cache_clear"):
                    obj.cache_clear()
    except Exception:
        pass


ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")


def str_width(s):
    try:
        w = wcwidth.wcswidth(s)
        return w if w >= 0 else len(s)
    except Exception:
        return len(s)


class TopBarReviewer:
    def __init__(
        self,
        include_startup=False,
        extra_text=None,
        fps=15.0,
        step=4,
        delay=1.0,
        start_effect=None,
        all_effects=False,
        shuffle=True,
        title_idx=None,
        custom_logos=None,
    ):
        self.include_startup = include_startup
        self.extra_text = extra_text
        self.fps = float(fps)
        self.step = step if step is not None else 4
        self.delay = float(delay)
        self.shuffle = shuffle
        self.fixed_title_idx = title_idx
        _, self.effect_resource_map = build_parser()
        if all_effects:
            available = sorted(list(self.effect_resource_map.keys()))
        else:
            available = sorted(
                [e for e in ACTIVE_EFFECTS if e in self.effect_resource_map]
            )
        self.available_effects = available

        if self.shuffle:
            self.effects = self._generate_shuffled_playlist(start_effect=start_effect)
        else:
            self.effects = list(available)

        if start_effect and start_effect in self.effects:
            self.effect_idx = self.effects.index(start_effect)
        else:
            self.effect_idx = 0

        # Smart shuffled playlist for titles
        if custom_logos and isinstance(custom_logos, list):
            self.available_titles = [
                logo.strip("\n") for logo in custom_logos if logo.strip("\n")
            ]
        else:
            self.available_titles = []

        if self.fixed_title_idx is not None and 0 <= self.fixed_title_idx < len(
            self.available_titles
        ):
            self.title_playlist = [self.available_titles[self.fixed_title_idx]]
            self.title_idx = 0
        elif self.shuffle:
            self.title_playlist = self._generate_shuffled_title_playlist()
            self.title_idx = 0
        else:
            self.title_playlist = list(self.available_titles)
            self.title_idx = 0

        self.running = True
        self.old_term = None
        self.proc = psutil.Process(os.getpid())
        self.proc.cpu_percent(interval=None)  # Prime CPU measurement

    def _generate_shuffled_playlist(self, prev_last=None, start_effect=None):
        pool = list(self.available_effects)
        random.shuffle(pool)
        if start_effect and start_effect in pool:
            pool.remove(start_effect)
            pool.insert(0, start_effect)
        elif prev_last and len(pool) > 1 and pool[0] == prev_last:
            pool[0], pool[-1] = pool[-1], pool[0]
        return pool

    def _generate_shuffled_title_playlist(self, prev_last=None):
        pool = list(self.available_titles)
        random.shuffle(pool)
        if prev_last and len(pool) > 1 and pool[0] == prev_last:
            pool[0], pool[-1] = pool[-1], pool[0]
        return pool

    def advance_effect(self, step=1):
        if self.shuffle:
            next_idx = self.effect_idx + step
            if next_idx >= len(self.effects):
                prev_last = self.effects[-1]
                self.effects = self._generate_shuffled_playlist(prev_last=prev_last)
                self.effect_idx = 0
            elif next_idx < 0:
                self.effect_idx = len(self.effects) - 1
            else:
                self.effect_idx = next_idx

            # Also advance title playlist on next effect (unless fixed)
            if self.fixed_title_idx is None and self.title_playlist:
                next_title_idx = self.title_idx + 1
                if next_title_idx >= len(self.title_playlist):
                    prev_last_title = self.title_playlist[-1]
                    self.title_playlist = self._generate_shuffled_title_playlist(
                        prev_last=prev_last_title
                    )
                    self.title_idx = 0
                else:
                    self.title_idx = next_title_idx
        else:
            self.effect_idx = (self.effect_idx + step) % len(self.effects)
            if self.fixed_title_idx is None and self.title_playlist:
                self.title_idx = (self.title_idx + 1) % len(self.title_playlist)

    def get_title_text(self):
        title = (
            self.title_playlist[self.title_idx].strip("\n")
            if self.title_playlist
            else ""
        )
        title_width = (
            max(str_width(line) for line in title.splitlines()) if title else 0
        )

        raw_extra = None
        if self.extra_text:
            raw_extra = self.extra_text.strip("\n")
        elif self.include_startup:
            raw_extra = " Neovim loaded 46/46 plugins in 38.42ms"

        if raw_extra:
            padded_lines = []
            for line in raw_extra.split("\n"):
                stripped = line.strip()
                if stripped:
                    w = str_width(stripped)
                    pad = max((title_width - w) // 2, 0)
                    padded_lines.append(f"{' ' * pad}{stripped}")
                else:
                    padded_lines.append("")
            return f"{title}\n\n" + "\n".join(padded_lines)
        return title

    def setup_terminal(self):
        if sys.stdin.isatty():
            self.old_term = termios.tcgetattr(sys.stdin)
            tty.setcbreak(sys.stdin.fileno())
        sys.stdout.write("[?25l[H[2J")
        sys.stdout.flush()

    def restore_terminal(self):
        sys.stdout.write("[?25h[0m")
        sys.stdout.flush()
        if self.old_term and sys.stdin.isatty():
            try:
                termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old_term)
            except Exception:
                pass

    def check_key(self):
        if not sys.stdin.isatty():
            return None
        r, _, _ = select.select([sys.stdin], [], [], 0)
        if not r:
            return None
        data = os.read(sys.stdin.fileno(), 16)
        if data in (
            b"\x1b[C",
            b"l",
            b" ",
            b"\r",
            b"\n",
        ):  # Right / l / Space / Enter = Next
            return "next"
        elif data in (b"\x1b[D", b"h"):  # Left / h = Prev
            return "prev"
        elif data in (b"r", b"R"):  # r = Replay
            return "replay"
        elif data in (b"q", b"Q", b"\x1b", b"\x03"):  # q / Esc / Ctrl-C = Quit
            return "quit"
        return None

    def get_window_title_seq(self, cpu, ram, kbs, fps):
        eff_name = self.effects[self.effect_idx]
        title = (
            f"[{self.effect_idx + 1:02d}/{len(self.effects):02d}] {eff_name} | "
            f"CPU: {cpu:.1f}% | RAM: {ram:.1f}MB | {kbs:.1f} KB/s | {fps:.1f} FPS"
        )
        return f"]0;{title}"

    def run(self):
        self.setup_terminal()
        try:
            while self.running:
                eff_name = self.effects[self.effect_idx]
                eff_cls, eff_conf_cls = self.effect_resource_map[eff_name]
                title_payload = self.get_title_text()

                # Live terminal size detection
                cols, rows = shutil.get_terminal_size(fallback=(120, 35))

                # Canvas responsive to terminal window
                canvas_w = max(cols, 60)
                canvas_h = max(rows, 10)
                row_offset = 1

                t_conf = TerminalConfig._build_config()
                t_conf.frame_rate = (
                    0  # Disable internal TTE sleeping; timing is enforced by runner
                )
                t_conf.canvas_width = canvas_w
                t_conf.canvas_height = canvas_h
                t_conf.anchor_canvas = "c"
                t_conf.anchor_text = "c"

                e_conf = eff_conf_cls._build_config()
                if eff_name == "slice":
                    e_conf.slice_direction = "diagonal"

                if eff_name == "slide":
                    e_conf.merge = True

                if eff_name == "swarm":
                    e_conf.swarm_size = 0.2

                if eff_name == "binarypath":
                    e_conf.movement_speed = 1.5

                if eff_name == "spotlights":
                    if hasattr(e_conf, "beam_width_ratio"):
                        e_conf.beam_width_ratio = 5.0

                    from terminaltexteffects.effects.effect_spotlights import (
                        SpotlightsIterator,
                    )
                    from terminaltexteffects.utils.geometry import (
                        Coord,
                        find_length_of_line,
                    )

                    orig_make = SpotlightsIterator.make_spotlights

                    def bounded_make_spotlights(it_self, num_spotlights: int):
                        c = it_self.terminal.canvas
                        pad_x = 4
                        pad_y = 2
                        min_x = max(c.text_left - pad_x, 1)
                        max_x = min(c.text_right + pad_x, c.right)
                        min_y = max(c.text_bottom - pad_y, 1)
                        max_y = min(c.text_top + pad_y, c.top)
                        min_dist = max(min(max_x - min_x, max_y - min_y) // 3, 2)

                        old_random = c.random_coord
                        old_find = it_self.find_coord_at_minimum_distance

                        def text_coord(outside_scope=False):
                            if outside_scope:
                                return old_random(outside_scope=True)
                            return Coord(
                                random.randint(min_x, max_x),
                                random.randint(min_y, max_y),
                            )

                        def bounded_find_coord(
                            origin_coord: Coord, minimum_distance: int
                        ) -> Coord:
                            for _ in range(50):
                                coord = Coord(
                                    random.randint(min_x, max_x),
                                    random.randint(min_y, max_y),
                                )
                                if find_length_of_line(origin_coord, coord) >= min_dist:
                                    return coord
                            return Coord(
                                random.randint(min_x, max_x),
                                random.randint(min_y, max_y),
                            )

                        c.random_coord = text_coord
                        it_self.find_coord_at_minimum_distance = bounded_find_coord
                        try:
                            return orig_make(it_self, num_spotlights)
                        finally:
                            c.random_coord = old_random
                            it_self.find_coord_at_minimum_distance = old_find

                    SpotlightsIterator.make_spotlights = bounded_make_spotlights

                effect = eff_cls(title_payload, e_conf, t_conf)

                # Clear alternate screen
                sys.stdout.write("\033[H\033[2J")

                # Initial performance state
                cur_cpu = self.proc.cpu_percent(interval=None)
                cur_ram = self.proc.memory_info().rss / (1024 * 1024)
                cur_kbs = 0.0
                cur_fps = 0.0

                w_title = self.get_window_title_seq(cur_cpu, cur_ram, cur_kbs, cur_fps)
                sys.stdout.write(w_title)
                sys.stdout.flush()

                interrupted_action = None
                target_frame_delay = 1.0 / self.fps
                last_frame_time = time.monotonic()

                # Metric sampling window
                metric_window = 0.25  # Update top bar stats every 250ms
                last_metric_time = time.monotonic()
                window_bytes = 0
                window_frames = 0
                prev_lines = None

                gc.disable()
                it = iter(effect)
                while self.running:
                    # Advance generator by `step` frames per render tick
                    frame = None
                    try:
                        for _ in range(self.step):
                            frame = next(it)
                    except StopIteration:
                        pass

                    if frame is None:
                        break

                    lines = frame.split("\n")
                    buf = []

                    # Periodic metric update
                    now = time.monotonic()
                    dt_m = now - last_metric_time
                    if dt_m >= metric_window:
                        cur_cols, cur_rows = shutil.get_terminal_size(
                            fallback=(cols, rows)
                        )
                        if cur_cols != cols or cur_rows != rows:
                            cols, rows = cur_cols, cur_rows
                            prev_lines = None  # Force full repaint on terminal resize
                        cur_cpu = self.proc.cpu_percent(interval=None)
                        cur_ram = self.proc.memory_info().rss / (1024 * 1024)
                        cur_kbs = (window_bytes / 1024.0) / dt_m
                        cur_fps = window_frames / dt_m
                        last_metric_time = now
                        window_bytes = 0
                        window_frames = 0
                        buf.append(
                            self.get_window_title_seq(
                                cur_cpu, cur_ram, cur_kbs, cur_fps
                            )
                        )

                    # Subtiling: dirty-line diff (only write lines that changed)
                    if prev_lines is None:
                        for r_idx, line in enumerate(lines):
                            target_r = row_offset + r_idx
                            if target_r <= rows:
                                buf.append(f"\033[{target_r};1H{line}")
                    else:
                        for r_idx, line in enumerate(lines):
                            target_r = row_offset + r_idx
                            if target_r <= rows:
                                if (
                                    r_idx >= len(prev_lines)
                                    or line != prev_lines[r_idx]
                                ):
                                    buf.append(f"\033[{target_r};1H{line}")

                    prev_lines = lines

                    out = "".join(buf)
                    n_bytes = len(out.encode("utf-8"))
                    window_bytes += n_bytes
                    window_frames += 1

                    if out:
                        sys.stdout.write(out)
                        sys.stdout.flush()

                    key = self.check_key()
                    if key:
                        interrupted_action = key
                        break

                    # Fixed-interval timing: prevents timer drift and jitter
                    target_time = last_frame_time + target_frame_delay
                    now = time.monotonic()
                    if now < target_time:
                        time.sleep(target_time - now)
                        last_frame_time = target_time
                    else:
                        last_frame_time = now

                gc.enable()
                del effect
                del it
                clear_all_caches()
                gc.collect()

                if interrupted_action:
                    self.handle_action(interrupted_action)
                    continue

                if not self.running:
                    break

                # Delay at end of animation before next
                t_end = time.monotonic() + self.delay
                delay_action = None
                while time.monotonic() < t_end:
                    key = self.check_key()
                    if key:
                        delay_action = key
                        break
                    time.sleep(0.02)

                if delay_action:
                    self.handle_action(delay_action)
                else:
                    self.advance_effect(1)

        finally:
            self.restore_terminal()

    def handle_action(self, action):
        if action == "quit":
            self.running = False
        elif action == "next":
            self.advance_effect(1)
        elif action == "prev":
            self.advance_effect(-1)
        elif action == "replay":
            pass


def main():
    import argparse
    import base64

    parser = argparse.ArgumentParser(
        description="TTE Reviewer & Neovim Dashboard Runner"
    )
    parser.add_argument(
        "--startup", action="store_true", help="Include Neovim startup time text"
    )
    parser.add_argument(
        "--extra",
        type=str,
        default=None,
        help="Extra text below title (e.g. startup stats)",
    )
    parser.add_argument(
        "--extra-b64", type=str, default=None, help="Base64-encoded extra text"
    )
    parser.add_argument(
        "--logos-b64",
        type=str,
        default=None,
        help="Base64-encoded JSON array of logos from Lua",
    )
    parser.add_argument(
        "--fps", type=float, default=15.0, help="Target framerate (default: 15)"
    )
    parser.add_argument(
        "--step", type=int, default=4, help="Frames to step per tick (default: 4)"
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=1.0,
        help="Pause in seconds between animation loops",
    )
    parser.add_argument(
        "--effect", type=str, default=None, help="Specific effect to start at"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        default=False,
        help="Include all effects, including slow ones (<10 FPS)",
    )
    parser.add_argument(
        "--shuffle",
        action="store_true",
        default=True,
        help="Shuffle playlist order (default: True)",
    )
    parser.add_argument(
        "--no-shuffle",
        action="store_false",
        dest="shuffle",
        help="Sequential alphabetical order",
    )
    parser.add_argument("--logo-idx", type=int, default=None, help="Fixed logo index")
    args = parser.parse_args()

    extra_text = args.extra
    if args.extra_b64:
        try:
            extra_text = base64.b64decode(args.extra_b64.encode("utf-8")).decode(
                "utf-8"
            )
        except Exception:
            extra_text = args.extra

    custom_logos = None
    if args.logos_b64:
        try:
            decoded = base64.b64decode(args.logos_b64.encode("utf-8")).decode("utf-8")
            custom_logos = json.loads(decoded)
        except Exception:
            custom_logos = None

    reviewer = TopBarReviewer(
        include_startup=args.startup,
        extra_text=extra_text,
        fps=args.fps,
        step=args.step,
        delay=args.delay,
        start_effect=args.effect,
        all_effects=args.all,
        shuffle=args.shuffle,
        title_idx=args.logo_idx,
        custom_logos=custom_logos,
    )

    def handle_signal(sig, frame):
        reviewer.running = False
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    reviewer.run()


if __name__ == "__main__":
    main()
