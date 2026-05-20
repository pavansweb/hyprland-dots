#!/bin/bash

# Path to temp art
ART_PATH="/tmp/spotify_album_art.png"
LAST_URL_PATH="/tmp/spotify_last_url.txt"

# Get metadata
PLAYER="spotify"
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)

if [ -z "$STATUS" ]; then
    echo "{\"text\": \"\", \"class\": \"stopped\"}"
    exit 0
fi

TITLE=$(playerctl -p $PLAYER metadata --format "{{title}}" 2>/dev/null)
ARTIST=$(playerctl -p $PLAYER metadata --format "{{artist}}" 2>/dev/null)
ARTURL=$(playerctl -p $PLAYER metadata --format "{{mpris:artUrl}}" 2>/dev/null)

# Download art if changed
LAST_URL=$(cat "$LAST_URL_PATH" 2>/dev/null)
if [ "$ARTURL" != "$LAST_URL" ]; then
    if [[ "$ARTURL" == http* ]]; then
        curl -s "$ARTURL" -o "$ART_PATH"
    elif [[ "$ARTURL" == file* ]]; then
        cp "${ARTURL#file://}" "$ART_PATH"
    fi
    echo "$ARTURL" > "$LAST_URL_PATH"
fi

# Flag handling
case "$1" in
    --art)
        echo "{\"text\": \"\"}"
        ;;
    --info)
        # Escape quotes for JSON
        TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
        ARTIST=$(echo "$ARTIST" | sed 's/"/\\"/g')
        echo "{\"text\": \"$TITLE - $ARTIST\", \"class\": \"$STATUS\"}"
        ;;
    --status)
        if [ "$STATUS" = "Playing" ]; then
            echo "{\"text\": \"󰏤\", \"class\": \"playing\"}"
        else
            echo "{\"text\": \"󰐊\", \"class\": \"paused\"}"
        fi
        ;;
    *)
        # Default legacy behavior if needed, but we use flags now
        TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
        ARTIST=$(echo "$ARTIST" | sed 's/"/\\"/g')
        echo "{\"text\": \"$TITLE - $ARTIST\", \"class\": \"$STATUS\"}"
        ;;
esac
