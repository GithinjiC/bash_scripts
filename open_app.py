import psutil
import subprocess
import logging

logging.basicConfig(
    filename='output.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    filemode='w'  # Clear the file each time the script starts
)

def is_app_running(app_name):
    for proc in psutil.process_iter(['name']):
        if app_name.lower() in proc.info['name'].lower():
            return proc.pid
    return None

def is_app_in_foreground(app_name):
    """For macOS."""
    script = """
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
    end tell
    """
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    return app_name.lower() in result.stdout.strip().lower()

def bring_to_foreground(app_name):
    if not is_app_in_foreground(app_name):
        script = f"""
        tell application "{app_name}"
            activate
        end tell
        """
        subprocess.run(["osascript", "-e", script])
    else:
        logging.info(f"{app_name} is already in the foreground.")

def open_app(app_path):
    subprocess.Popen(["open", app_path])

def check_and_run_app(app_name, app_path):
    pid = is_app_running(app_name)

    if pid:
        logging.info(f"{app_name} is already running with PID {pid}. Bringing to the foreground.")
        bring_to_foreground(app_name)
    else:
        logging.info(f"{app_name} is not running. Opening it now and bringing to the foreground.")
        open_app(app_path)

# check_and_run_app(app_name, app_path)
