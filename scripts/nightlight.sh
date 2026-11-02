#!/bin/bash

cache_dir="$HOME/.config/hypr/.cache"
mkdir -p "$cache_dir"
value_file="$cache_dir/.nightlight"
default=6500
min_temp=2500
max_temp=6500
step=500

get_temp() {
    local val
    val=$(cat "$value_file" 2>/dev/null)
    if [[ ! "$val" =~ ^[0-9]+$ ]] || [ "$val" -lt "$min_temp" ] || [ "$val" -gt "$max_temp" ]; then
        val=4500
    fi
    echo "$val"
}

is_active() {
    pgrep -x hyprsunset >/dev/null
}

stop_sunset() {
    pkill -x hyprsunset 2>/dev/null
    for i in {1..10}; do
        pgrep -x hyprsunset >/dev/null || break
        sleep 0.05
    done
}

apply_temp() {
    local temp="$1"
    stop_sunset
    if [ "$temp" -lt "$max_temp" ]; then
        echo "$temp" > "$value_file"
        hyprsunset -t "$temp" >/dev/null 2>&1 &
        notify-send -u low -i preferences-desktop-display-color "Night Light" "Screen temperature set to ${temp}K (Warmer)"
    else
        echo "$default" > "$value_file"
        notify-send -u low -i preferences-desktop-display-color "Night Light" "Reset to default daylight (${default}K)"
    fi
    pkill -RTMIN+11 waybar 2>/dev/null
}

case "$1" in
    --status)
        if is_active; then
            current=$(get_temp)
            echo "{\"text\": \"󰖔\", \"alt\": \"active\", \"tooltip\": \"Night Light: Active (${current}K)\nLeft Click: Turn Off\nScroll Up: Warmer\nScroll Down: Cooler\nRight Click: Reset\", \"class\": \"active\"}"
        else
            echo "{\"text\": \"󰖙\", \"alt\": \"inactive\", \"tooltip\": \"Night Light: Off (Normal 6500K)\nLeft Click: Turn On\nScroll Up: Warmer\nScroll Down: Cooler\", \"class\": \"inactive\"}"
        fi
        ;;
    --toggle)
        if is_active; then
            stop_sunset
            notify-send -u low -i preferences-desktop-display-color "Night Light" "Turned Off (Screen reset to 6500K)"
            pkill -RTMIN+11 waybar 2>/dev/null
        else
            current=$(get_temp)
            [ "$current" -ge "$max_temp" ] && current=4500
            apply_temp "$current"
        fi
        ;;
    --inc)
        # Cooler (higher Kelvin towards 6500)
        current=$(get_temp)
        new_temp=$((current + step))
        if [ "$new_temp" -ge "$max_temp" ]; then
            stop_sunset
            echo "$default" > "$value_file"
            notify-send -u low -i preferences-desktop-display-color "Night Light" "Reset to normal daylight (6500K)"
            pkill -RTMIN+11 waybar 2>/dev/null
        else
            apply_temp "$new_temp"
        fi
        ;;
    --dec)
        # Warmer (lower Kelvin towards 2500)
        current=$(get_temp)
        [ "$current" -ge "$max_temp" ] && current=5000
        new_temp=$((current - step))
        [ "$new_temp" -lt "$min_temp" ] && new_temp="$min_temp"
        apply_temp "$new_temp"
        ;;
    --def)
        stop_sunset
        echo "$default" > "$value_file"
        notify-send -u low -i preferences-desktop-display-color "Night Light" "Turned Off (Screen reset to 6500K)"
        pkill -RTMIN+11 waybar 2>/dev/null
        ;;
    *)
        echo "Usage: $0 {--status|--toggle|--inc|--dec|--def}"
        ;;
esac
