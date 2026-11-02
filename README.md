# My Hyprland Setup

My personal Arch Linux + Hyprland setup. Features a vertical floating Waybar dock on the left, custom GTK desktop HUD widgets (clock, system stats, music card, app shortcuts, and one-click memory boost), plus custom shortcuts.

## Quick Install (One Command)

Open your terminal on a fresh Arch install and run this:

```bash
git clone https://github.com/pavansweb/hyprland-dots.git ~/.dots-temp && \
sudo pacman -S --needed --noconfirm hyprland waybar rofi-wayland swww playerctl brightnessctl grim slurp satty cliphist hyprsunset python python-gobject gtk3 gtk-layer-shell base-devel && \
mkdir -p ~/.config/hypr ~/.config/waybar ~/.local/bin ~/Pictures/wallpapers && \
cp -r ~/.dots-temp/{confs,pypr,scripts,widgets,icons,lockscreens,assets,hyprland.lua,hypridle.conf,hyprlock.conf,.keybinds} ~/.config/hypr/ && \
cp -r ~/.dots-temp/waybar/* ~/.config/waybar/ && \
cp -r ~/.dots-temp/Wallpapers/* ~/Pictures/wallpapers/ 2>/dev/null || true && \
[ -f ~/.dots-temp/brave-flags.conf ] && cp ~/.dots-temp/brave-flags.conf ~/.config/ && \
[ -f ~/.dots-temp/.zshrc ] && cp ~/.dots-temp/.zshrc ~/ && \
chmod +x ~/.config/hypr/scripts/* ~/.config/hypr/widgets/*.py ~/.config/hypr/widgets/*.sh 2>/dev/null || true && \
gcc -shared -fPIC -O2 -o ~/.config/hypr/scripts/libwaybar_hypr_lua.so ~/.config/hypr/scripts/libwaybar_hypr_lua.c -ldl && \
printf '#!/bin/bash\nexport LD_PRELOAD="'"$HOME"'/.config/hypr/scripts/libwaybar_hypr_lua.so:$LD_PRELOAD"\nexec /usr/bin/waybar "$@"\n' > ~/.local/bin/waybar && \
chmod +x ~/.local/bin/waybar && \
rm -rf ~/.dots-temp && \
echo "Done! You can now log into Hyprland."
```

---

## What's in Here?

- **Compositor**: Hyprland (configured via `hyprland.lua`)
- **Dock**: Vertical Waybar on the left with blur, dynamic workspace switching, audio, night light, caffeine toggle, and notifications
- **Desktop Widget**: Custom Python GTK3 widget pinned to the desktop (draggable with mouse, 12-hour clock, system monitor, music card, quick launchers, and a cache clear button)
- **App Launcher**: Rofi
- **Screenshots**: Grimblast + Satty (annotate & copy directly)
- **Night Light**: `hyprsunset` integration with toggle & scroll temperature adjustment directly in Waybar

---

## Key Shortcuts I Use

| Shortcut | Action |
|---|---|
| `SUPER + Return` | Open Kitty terminal |
| `SUPER + B` | Open Brave |
| `SUPER + C` | Open VS Code |
| `SUPER + E` | Open Caja file manager |
| `SUPER + D` | Application launcher (Rofi) |
| `SUPER + Q` | Close active window |
| `SUPER + V` | Toggle floating mode (Super+drag to move/resize) |
| `SUPER + W` | Random wallpaper change |
| `SUPER + Delete` | Free RAM, flush dirty writes & clear bloated caches |
| `SUPER + \` | Toggle desktop widgets HUD |
| `SUPER + Shift + S` | Area screenshot |
| `SUPER + Alt + C` | Clipboard history manager |

### Media & Function Keys
- `F2` / `Fn + F2`: Open Gmail in Brave
- `F3` / `Fn + F3`: Open Brave in Incognito
- `F5` / `Fn + F5`: Open Spotify
- `F6` / `Fn + F6`: Previous track
- `F7` / `Fn + F7`: Play / Pause
- `F8` / `Fn + F8`: Next track
- `F9` / `Fn + F9`: Mute / Unmute
- `F10` / `Fn + F10`: Decrease volume
- `F11` / `Fn + F11`: Increase volume

---

## Note for Other Monitors

If you install this on another machine, run:
```bash
hyprctl monitors
```
If your display isn't `HDMI-A-1` (e.g. `eDP-1` on laptops), just change the monitor line at the top of `~/.config/hypr/hyprland.lua` to match your screen.
