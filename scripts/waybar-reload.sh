#!/bin/bash

case "$1" in
    --reload)
        killall waybar 2>/dev/null || true
        sleep 0.3
        hyprctl dispatch 'hl.dsp.exec_cmd("/home/zen/.local/bin/waybar")' >/dev/null 2>&1
        sleep 0.3
        hyprctl reload
        ;;
    --toggle)
        if pidof waybar >/dev/null; then
            killall waybar
        else
            hyprctl dispatch 'hl.dsp.exec_cmd("/home/zen/.local/bin/waybar")' >/dev/null 2>&1
        fi
        sleep 0.5
        hyprctl reload
        ;;
esac
