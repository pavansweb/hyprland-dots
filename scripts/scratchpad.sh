#!/usr/bin/env bash

# Lightweight native scratchpad manager for Hyprland
# Window rules place windows automatically into special workspaces

cmd="$1"

case "$cmd" in
    term)
        if ! hyprctl clients -j | grep -q "\"initialClass\": \"kitty-dropterm\""; then
            kitty --class kitty-dropterm &
            sleep 0.1
        fi
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratch_term")'
        ;;

    calc)
        if ! hyprctl clients -j | grep -q "\"initialClass\": \"kitty-calc\""; then
            kitty --class kitty-calc --title "Python Calculator" -e python3 -q &
            sleep 0.1
        fi
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratch_calc")'
        ;;

    volume)
        if ! hyprctl clients -j | grep -q "\"initialClass\": \"pavucontrol\""; then
            pavucontrol &
            sleep 0.1
        fi
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratch_volume")'
        ;;

    minimize)
        hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", silent = true })'
        notify-send -u low -i window-new "Hyprland" "Window minimized (Super+Shift+N to view)"
        ;;

    restore)
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("minimized")'
        ;;

    *)
        echo "Usage: $0 {term|calc|volume|minimize|restore}"
        exit 1
        ;;
esac
