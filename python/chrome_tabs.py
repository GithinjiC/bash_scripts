#!/usr/bin/env python3
"""
Auto-scroll through Chrome tabs at a reading pace.

Logs to both stdout and a file so you can tail it from anywhere:
  tail -f /tmp/chrome_scroller.log
"""

import pyautogui
import pywinctl as pwc
import time
import platform
import sys
import os
import signal
import atexit
import logging
from datetime import datetime

# --- Configuration ---
SCROLLS_PER_TAB = 8
SCROLL_AMOUNT = -300
PAUSE_BETWEEN_SCROLLS = 2.5
PAUSE_BETWEEN_TABS = 1.0
PAUSE_BETWEEN_WINDOWS = 1.5
STARTUP_DELAY = 4
LOOP_FOREVER = False
MAX_TABS_PER_WINDOW = 100
ALL_WINDOWS = True
PID_FILE = "/tmp/chrome_scroller.pid"
LOG_FILE = "/tmp/chrome_scroller.log"

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.1

IS_MAC = platform.system() == "Darwin"
_should_stop = False


def setup_logging():
    """Configure logging to both stdout (unbuffered) and a log file."""
    # Force stdout to be line-buffered so each print appears immediately.
    sys.stdout.reconfigure(line_buffering=True)

    logger = logging.getLogger("scroller")
    logger.setLevel(logging.DEBUG)

    fmt = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )

    # Console handler
    sh = logging.StreamHandler(sys.stdout)
    sh.setLevel(logging.DEBUG)
    sh.setFormatter(fmt)
    logger.addHandler(sh)

    # File handler — overwrites each run so the log reflects only this run.
    fh = logging.FileHandler(LOG_FILE, mode="w")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    return logger


log = setup_logging()


def run_diagnostics():
    """Verify everything works before we drive anything. Logs each check."""
    log.info("=" * 60)
    log.info("Starting diagnostics")
    log.info("=" * 60)
    log.info(f"Python:    {sys.version.split()[0]}")
    log.info(f"Platform:  {platform.system()} {platform.release()}")
    log.info(f"PID:       {os.getpid()}")
    log.info(f"Log file:  {LOG_FILE}")

    # 1. Can we read screen size? (pyautogui sanity check)
    try:
        size = pyautogui.size()
        log.info(f"Screen size: {size.width}x{size.height}")
    except Exception as e:
        log.error(f"pyautogui.size() failed: {e}")
        return False

    # 2. Can we read mouse position? (no permission needed for this)
    try:
        pos = pyautogui.position()
        log.info(f"Mouse position: ({pos.x}, {pos.y})")
    except Exception as e:
        log.error(f"pyautogui.position() failed: {e}")
        return False

    # 3. Can pywinctl enumerate windows?
    try:
        all_windows = pwc.getAllWindows()
        log.info(f"pywinctl sees {len(all_windows)} window(s) total")
    except Exception as e:
        log.error(f"pywinctl.getAllWindows() failed: {e}")
        log.error("On macOS, grant your terminal Accessibility + Screen Recording")
        log.error("permissions in System Settings > Privacy & Security.")
        return False

    # 4. Can we read the active window title?
    try:
        active = pwc.getActiveWindow()
        if active:
            log.info(f"Active window: {active.title[:80]!r}")
        else:
            log.warning("No active window detected — focus a window first.")
    except Exception as e:
        log.error(f"pywinctl.getActiveWindow() failed: {e}")
        return False

    # 5. Are there any Chrome windows?
    chrome_windows = find_chrome_windows()
    log.info(f"Chrome windows found: {len(chrome_windows)}")
    for i, w in enumerate(chrome_windows, 1):
        log.info(f"  [{i}] {(w.title or '<no title>')[:80]}")

    if not chrome_windows:
        log.error("No Chrome windows detected. Open Chrome before running.")
        return False

    log.info("All diagnostic checks passed.")
    log.info("=" * 60)
    return True


def handle_stop_signal(signum, frame):
    global _should_stop
    log.warning(f"Received signal {signum}; stopping after current step.")
    _should_stop = True


def write_pid_file():
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE) as f:
                existing_pid = int(f.read().strip())
            os.kill(existing_pid, 0)
            log.error(f"Another instance is running (PID {existing_pid}).")
            log.error(f"Stop it:  kill {existing_pid}")
            log.error(f"Or remove stale file:  rm {PID_FILE}")
            sys.exit(1)
        except (ValueError, ProcessLookupError, PermissionError):
            log.info(f"Removing stale PID file at {PID_FILE}")

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    log.info(f"PID {os.getpid()} -> {PID_FILE}")
    log.info(f"Stop with:  kill $(cat {PID_FILE})")


def cleanup_pid_file():
    try:
        if os.path.exists(PID_FILE):
            with open(PID_FILE) as f:
                if f.read().strip() == str(os.getpid()):
                    os.remove(PID_FILE)
                    log.info("PID file removed.")
    except Exception as e:
        log.warning(f"Could not clean up PID file: {e}")


def check_stop():
    if _should_stop:
        raise KeyboardInterrupt("Stop requested via signal")


def next_tab_hotkey():
    return ("command", "option", "right") if IS_MAC else ("ctrl", "tab")


def first_tab_hotkey():
    return ("command", "1") if IS_MAC else ("ctrl", "1")


def countdown(seconds):
    log.info(f"Starting in {seconds}s. Focus the first Chrome window now.")
    for i in range(seconds, 0, -1):
        log.info(f"  {i}...")
        time.sleep(1)
    log.info("Go!")


def find_chrome_windows():
    windows = []
    for w in pwc.getAllWindows():
        title = (w.title or "").lower()
        try:
            app = (w.getAppName() or "").lower()
        except Exception:
            app = ""
        if "chrome" in title or "chrome" in app:
            windows.append(w)
    return windows


def get_active_window_title():
    try:
        w = pwc.getActiveWindow()
        return w.title if w else ""
    except Exception as e:
        log.warning(f"Could not read active window title: {e}")
        return ""


def scroll_current_tab():
    for i in range(SCROLLS_PER_TAB):
        check_stop()
        log.debug(f"      scroll {i + 1}/{SCROLLS_PER_TAB}")
        try:
            pyautogui.scroll(SCROLL_AMOUNT)
        except Exception as e:
            log.error(f"scroll failed: {e}")
            raise
        time.sleep(PAUSE_BETWEEN_SCROLLS)


def cycle_tabs_in_focused_window():
    log.info("    jumping to tab 1")
    pyautogui.hotkey(*first_tab_hotkey())
    time.sleep(PAUSE_BETWEEN_TABS)

    first_title = get_active_window_title()
    log.info(f"    tab 1: {first_title[:60]}")
    scroll_current_tab()

    tabs_visited = 1
    while tabs_visited < MAX_TABS_PER_WINDOW:
        check_stop()
        log.debug("    pressing next-tab hotkey")
        pyautogui.hotkey(*next_tab_hotkey())
        time.sleep(PAUSE_BETWEEN_TABS)

        current_title = get_active_window_title()
        if current_title == first_title:
            log.info(f"    cycled back to start after {tabs_visited} tab(s).")
            return

        log.info(f"    tab {tabs_visited + 1}: {current_title[:60]}")
        scroll_current_tab()
        tabs_visited += 1

    log.warning(f"    hit MAX_TABS_PER_WINDOW cap ({MAX_TABS_PER_WINDOW})")


def run_once():
    if ALL_WINDOWS:
        windows = find_chrome_windows()
        if not windows:
            log.error("No Chrome windows. Open Chrome and retry.")
            return
        log.info(f"Cycling through {len(windows)} Chrome window(s).")

        for idx, window in enumerate(windows, start=1):
            check_stop()
            log.info(f"Window {idx}/{len(windows)}: {window.title[:60]}")
            try:
                window.activate()
            except Exception as e:
                log.warning(f"  could not focus window: {e}")
                continue
            time.sleep(PAUSE_BETWEEN_WINDOWS)
            cycle_tabs_in_focused_window()
    else:
        cycle_tabs_in_focused_window()


def main():
    signal.signal(signal.SIGTERM, handle_stop_signal)
    signal.signal(signal.SIGINT, handle_stop_signal)
    atexit.register(cleanup_pid_file)

    if not run_diagnostics():
        log.error("Diagnostics failed. Fix the issues above and retry.")
        sys.exit(2)

    write_pid_file()
    countdown(STARTUP_DELAY)

    try:
        if LOOP_FOREVER:
            pass_num = 1
            while not _should_stop:
                log.info(f"=== Pass {pass_num} ===")
                run_once()
                pass_num += 1
        else:
            run_once()
        log.info("Done.")
    except pyautogui.FailSafeException:
        log.warning("Aborted via failsafe (mouse to corner).")
        sys.exit(1)
    except KeyboardInterrupt:
        log.info("Stopped cleanly via signal/Ctrl-C.")
        sys.exit(0)
    except Exception as e:
        log.exception(f"Unhandled error: {e}")
        sys.exit(3)


if __name__ == "__main__":
    main()