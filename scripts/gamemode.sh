#!/usr/bin/env bash

# Performance / Game Mode Toggle for Hyprland
# Cuts GPU compositor load to 0% for gaming, heavy rendering, or battery saving

STATE_FILE="$HOME/.config/hypr/.cache/.gamemode"
mkdir -p "$(dirname "$STATE_FILE")"

if [ -f "$STATE_FILE" ]; then
    # Currently in Game Mode -> Restore eye candy
    rm -f "$STATE_FILE"
    hyprctl dispatch 'function()
        hl.config({
            animations = { enabled = 1 },
            decoration = {
                rounding = 8,
                blur = { enabled = true }
            }
        })
    end'
    notify-send -u low -i preferences-desktop-theme "Performance Mode" "Visual Effects Restored (Blur & Animations ON)"
else
    # Enter Game Mode -> Max performance
    touch "$STATE_FILE"
    hyprctl dispatch 'function()
        hl.config({
            animations = { enabled = 0 },
            decoration = {
                rounding = 0,
                blur = { enabled = false }
            }
        })
    end'
    notify-send -u low -i applications-games "Performance Mode" "Game Mode Active (Zero GPU blur & animations for maximum FPS)"
fi
