#!/usr/bin/env bash

# Toggle GTK / Desktop Dark and Light color scheme
current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")

if [ "$current" = "prefer-dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    notify-send -u low -i weather-clear "Color Scheme" "Switched to Light Mode"
else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    notify-send -u low -i weather-clear-night "Color Scheme" "Switched to Dark Mode (TokyoNight)"
fi
