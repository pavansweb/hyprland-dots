#!/usr/bin/env python3
import os
import sys

hs = os.path.expanduser("~/.config/hypr/widgets/desktop_homescreen.py")
if __name__ == "__main__":
    args = [sys.executable, hs] + sys.argv[1:]
    os.execv(sys.executable, args)
