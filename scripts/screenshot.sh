#!/usr/bin/env bash

# Screenshot utility for Hyprland using grimblast and satty

if [ -z "$XDG_PICTURES_DIR" ]; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi

sound_file="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file="screenshot_$(date +'%-y%m%d_%H%M%S').png"
full_path="$save_dir/$save_file"

mkdir -p "$save_dir"

play_sound() {
    if [ -f "$sound_file" ]; then
        paplay "$sound_file" 2>/dev/null || pw-play "$sound_file" 2>/dev/null &
    fi
}

send_notification() {
    local file="$1"
    if [ -f "$file" ]; then
        (
            action=$(notify-send -a "Screenshot" \
                -i "$file" \
                -r 91190 \
                -t 6000 \
                -A edit="Edit / Annotate" \
                -A view="Open Image" \
                "Screenshot Captured" \
                "Copied to clipboard and saved to Screenshots")
            
            case "$action" in
                edit)
                    satty --filename "$file" --output-filename "$file" --save-after-copy --early-exit
                    ;;
                view)
                    xdg-open "$file" 2>/dev/null &
                    ;;
            esac
        ) &
    fi
}

snip_area() {
    if grimblast --freeze copysave area "$full_path"; then
        play_sound
        send_notification "$full_path"
    fi
}

snip_and_edit() {
    local temp_screenshot
    temp_screenshot=$(mktemp --suffix=.png /tmp/satty_XXXXXX)
    if grimblast --freeze save area "$temp_screenshot"; then
        play_sound
        satty --filename "$temp_screenshot" --output-filename "$full_path" --save-after-copy --early-exit
        rm -f "$temp_screenshot"
        if [ -f "$full_path" ]; then
            notify-send -a "Screenshot" -i "$full_path" -r 91190 -t 4000 "Screenshot Saved" "$save_file"
        fi
    else
        rm -f "$temp_screenshot"
    fi
}

fullscreen() {
    sleep "${1:-0.5}"
    if grimblast copysave screen "$full_path"; then
        play_sound
        send_notification "$full_path"
    fi
}

active_window() {
    sleep 0.5
    if grimblast copysave active "$full_path"; then
        play_sound
        send_notification "$full_path"
    fi
}

menu() {
    local opt1="󰹑  Selected area"
    local opt2="󰷄  Selected area (Edit/Annotate)"
    local opt3="󰍹  Fullscreen (delay 3 sec)"
    local opt4="󱂬  Active window"

    local options="$opt1\n$opt2\n$opt3\n$opt4"
    local choice
    choice=$(echo -e "$options" | rofi -dmenu -replace -config ~/.config/rofi/themes/rofi-screenshots.rasi -i -no-show-icons -l 4 -width 30 -p "Screenshot")

    case "$choice" in
        "$opt1")
            sleep 0.2 && snip_area
            ;;
        "$opt2")
            sleep 0.2 && snip_and_edit
            ;;
        "$opt3")
            fullscreen 3
            ;;
        "$opt4")
            sleep 0.2 && active_window
            ;;
        *)
            exit 0
            ;;
    esac
}

case "$1" in
    --area|-s|area|snip)
        snip_area
        ;;
    --edit|-e|edit|satty)
        snip_and_edit
        ;;
    --full|-f|full|screen)
        fullscreen "${2:-0.5}"
        ;;
    --window|-w|window|active)
        active_window
        ;;
    *)
        menu
        ;;
esac
