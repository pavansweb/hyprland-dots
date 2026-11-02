#!/usr/bin/env python3
import sys
import os
import subprocess
import signal

def is_running():
    try:
        out = subprocess.check_output(["pgrep", "-f", "desktop_widget.py"]).decode().strip()
        pids = [int(p) for p in out.splitlines() if int(p) != os.getpid()]
        return pids
    except subprocess.CalledProcessError:
        return []

pids = is_running()
if pids:
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
else:
    widget_script = os.path.expanduser("~/.config/hypr/widgets/desktop_widget.py")
    subprocess.Popen(["python3", widget_script], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
