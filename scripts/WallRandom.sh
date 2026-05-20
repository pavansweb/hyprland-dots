#!/bin/bash

# Directory containing wallpapers
wallDir="/home/zen/Pictures/wallpapers"
cacheDir="$HOME/.config/hypr/.cache"
scrDir="$HOME/.config/hypr/scripts"

# Transition config (standard for this setup)
FPS=60
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Determine engine
if command -v awww &> /dev/null; then
    ENGINE=awww
    DAEMON=awww-daemon
elif command -v swww &> /dev/null; then
    ENGINE=swww
    DAEMON=swww-daemon
else
    echo "Neither awww nor swww found."
    exit 1
fi

# Ensure daemon is running
if ! pgrep -x "$DAEMON" > /dev/null; then
    "$DAEMON" &
    sleep 1
fi

# Function to set a random wallpaper
set_random_wallpaper() {
    readarray -t PICS < <(find "${wallDir}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \))

    if [ ${#PICS[@]} -eq 0 ]; then
        echo "No images found in ${wallDir}"
        exit 1
    fi

    wallpaper=${PICS[ $RANDOM % ${#PICS[@]} ]}

    # Change wallpaper
    ${ENGINE} img "${wallpaper}" $AWWW_PARAMS

    # Update cache for persistence and other scripts
    ln -sf "${wallpaper}" "$cacheDir/current_wallpaper.png"
    baseName="$(basename "${wallpaper}")"
    echo "${baseName%.*}" > "$cacheDir/.wallpaper"

    # Refresh cache/theme if needed (optional, depends on system)
    if [ -f "$scrDir/wallcache.sh" ]; then
        "$scrDir/wallcache.sh"
    fi
}

# Check if loop argument is provided
if [ "$1" == "--loop" ]; then
    INTERVAL=${2:-300} # Default 5 minutes
    while true; do
        set_random_wallpaper
        sleep "$INTERVAL"
    done
else
    set_random_wallpaper
fi
