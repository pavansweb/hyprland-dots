#!/bin/bash

scriDir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
theme=$(cat "$HOME/.config/hypr/.cache/.theme")
wallDIR="/home/zen/Pictures/wallpapers"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Transition config
FPS=60
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

if command -v awww &> /dev/null; then
    ENGINE=awww
elif command -v swww &> /dev/null; then
    ENGINE=swww
fi


# Retrieve image files
readarray -t PICS < <(find "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \))
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command ( style )
rofi_command1="rofi -show -dmenu -config ~/.config/rofi/themes/rofi-wall.rasi"
rofi_command2="rofi -show -dmenu -config ~/.config/rofi/themes/rofi-wall-2.rasi"

menu() {
  for i in "${!PICS[@]}"; do
    filename=$(basename "${PICS[$i]}")
    # Displaying .gif to indicate animated images
    if [[ -z $(echo "$filename" | grep .gif$) ]]; then
      printf "$(echo "$filename" | cut -d. -f1)\x00icon\x1f${PICS[$i]}\n"
    else
      printf "$filename\n"
    fi
  done

  printf "$RANDOM_PIC_NAME\n"
}

case $1 in
    thm1)
        choice=$(menu | ${rofi_command1})
        ;;
    thm2)
        choice=$(menu | ${rofi_command2})
        ;;
esac

# No choice case
if [[ -z $choice ]]; then
  exit 0
fi

# Random choice case
if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
    ${ENGINE} img "${RANDOM_PIC}" $AWWW_PARAMS
  exit 0
fi

# Find the index of the selected file
pic_index=-1
for i in "${!PICS[@]}"; do
  filename=$(basename "${PICS[$i]}")
  if [[ "$filename" == "$choice"* ]]; then
    pic_index=$i
    break
  fi
done

if [[ $pic_index -ne -1 ]]; then
    notify-send -i "${PICS[$pic_index]}" "Changing wallpaper" -t 1500
    ${ENGINE} img "${PICS[$pic_index]}" $AWWW_PARAMS

    ln -sf "${PICS[$pic_index]}" "$cache_dir/current_wallpaper.png"
    basename="$(basename "${PICS[$pic_index]}")"
    wallName="${basename%.*}"
    echo "$wallName" > "$wallCache"

else
    echo "Image not found."
    exit 1
fi

sleep 0.5
"$scriDir/wallcache.sh"
"$scriDir/themes.sh"
