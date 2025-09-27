'''
python3 -m venv <env_name>
source <env_name>/bin/activate
pip install pyautogui
nohup python cursor.py &> output.log &
jobs -l -> get the background jobs pid
kill <PID>
deactivate
'''

import pyautogui
import time
import math
import logging
import signal
import sys
import os
from open_app import check_and_run_app

logging.basicConfig(
    filename='output.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    filemode='w'  # Clear the file each time the script starts
)

# Define a signal handler to clear the log file on termination
def handle_signal(signum, frame):
    logging.info(f'Process terminated gracefully with {signum}. Will clear log file on next run.')
    sys.stdout.flush()
    sys.exit(0)

# Register signal handler for termination signals
signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

# Move the mouse cursor in a circle around the center of the screen
def move_mouse_in_circle(radius=30, steps=30):
    screen_width, screen_height = pyautogui.size()
    center_x, center_y = screen_width // 2, screen_height // 2
    
    # Move the mouse in a circle (parametric equation for a circle)
    for i in range(steps):
        angle = 2 * math.pi * (i / steps)
        x = center_x + int(radius * math.cos(angle))
        y = center_y + int(radius * math.sin(angle))
        pyautogui.moveTo(x, y, duration=0.1)

if __name__ == "__main__":
    pid = os.getpid()
    logging.info(f"Script started with PID {pid}.")
    check_and_run_app("Microsoft Teams", "/Applications/Microsoft Teams.app")
    time.sleep(10)
    sys.stdout.flush()
    try:
        while True:
            logging.info("Running script logic.")
            move_mouse_in_circle()
            time.sleep(240)  # Wait 4 minutes
    except KeyboardInterrupt:
        handle_signal(signal.SIGINT, None)
