#!/usr/bin/env python3
import sys
import os
import subprocess

script = os.path.expanduser("~/.config/hypr/widgets/desktop_homescreen.py")

# Try to toggle running homescreen
res = subprocess.run(["python3", script, "--toggle"])
if res.returncode != 0:
    subprocess.Popen(
        ["python3", script],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL
    )
