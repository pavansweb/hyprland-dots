-- Hyprland Lua Configuration
-- Converted for Hyprland 0.57+

---@module 'hl'

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_SCALE_FACTOR", 1)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GRIMBLAST_HIDE_CURSOR", 0)
hl.env("MOZ_ENABLE_WAYLAND", 1)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA configuration
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("NVD_BACKEND", "direct")
hl.env("WLR_NO_HARDWARE_CURSORS", 1)
hl.env("AQ_NO_HARDWARE_CURSORS", 1)
hl.env("WLR_DRM_NO_ATOMIC", 1)
hl.env("WLR_DRM_DEVICES", "/dev/dri/card1")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor layan-white-cursors 24")
    hl.exec_cmd(scriptsDir .. "/startup.sh")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("swaync")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd(scriptsDir .. "/polkit.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pypr &")
end)

hl.on("config.reloaded", function()
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme TokyoNight")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme TokyoNight")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme perfect-dark")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        col = {
            active_border = "rgba(8cc6c8FF)",
            inactive_border = "rgba(9C5759FF)",
        },
    },

    decoration = {
        rounding = 8,
        rounding_power = 2,
        fullscreen_opacity = 1.0,
        dim_strength = 0.1,
        dim_special = 0.8,
        shadow = {
            enabled = false,
            range = 0,
            render_power = 4,
            color = "rgba(8cc6c8FF)",
            color_inactive = "rgba(9C5759FF)",
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            special = true,
            popups = true,
        },
    },

    input = {
        kb_layout = "us",
        repeat_rate = 50,
        repeat_delay = 300,
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = true,
            tap_to_click = true,
            drag_lock = false,
        },
        sensitivity = 0,
    },

    gestures = {
        workspace_swipe_distance = 400,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = true,
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.config({
    animations = {
        enabled = 1,
    },
})

hl.curve("fluent_decel",   { type = "bezier", points = { {0.1, 1}, {0, 1} } })
hl.curve("md3_decel",       { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("md3_accel",       { type = "bezier", points = { {0.3, 0}, {0.8, 0.15} } })
hl.curve("elegant_bounce",  { type = "bezier", points = { {0.55, 1.07}, {0.28, 1.12} } })
hl.curve("backward",        { type = "bezier", points = { {0.49, 0.09}, {0.38, 1.24} } })
hl.curve("linear",          { type = "bezier", points = { {1, 1}, {1, 1} } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "elegant_bounce", style = "slide down" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "md3_accel", style = "slide up" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "fluent_decel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "md3_decel", style = "slidefadevert 15%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "md3_accel", style = "slide" })

----------------------
---- WINDOW RULES ----
----------------------
local floating_classes = {
    "^(org.kde.polkit-kde-authentication-agent-1)$",
    "^(xfce-polkit)$",
    "^([Tt]hunar)$",
    "^(pavucontrol|org.pulseaudio.pavucontrol)$",
    "^(nwg-look|qt5ct|qt6ct)$",
    "^(file-roller|org.gnome.FileRoller)$",
    "^([Kk]vantummanager)$",
    "^([Ll]xappearance)$",
    "^(eog)$",
    "^([Gg]nome-disks)$",
    "^(com.obsproject.Studio)$",
    "^(org.kde.kcalc)$",
    "^(org.telegram.desktop)$",
    "^(org.kde.partitionmanager)$",
    "^(org.kde.gwenview)$",
    "^(localsend)$",
    "^(com.gabm.satty)$",
    "^(org.gnome.Nautilus|caja)$",
    "^(xdg-desktop-portal-gtk)$",
}

for idx, cls in ipairs(floating_classes) do
    hl.window_rule({
        name = "float_rule_" .. idx,
        match = { class = cls },
        float = true,
        center = true,
    })
end

hl.window_rule({
    name = "kitty_floating_dialogs",
    match = { class = "^(kitty)$", title = "(update|floating|yazi|monitor|browser)" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "brave_messenger_call",
    match = { class = "^(brave-browser)$", title = "(Messenger call)" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "caja_size",
    match = { class = "^(caja)$" },
    size = { 1728, 972 },
    center = true,
    opacity = "0.8 0.7",
})

hl.window_rule({
    name = "workspace_kitty_main",
    match = { class = "(kitty)$", title = "(main)" },
    workspace = 1,
})

hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true })
hl.layer_rule({ match = { namespace = "desktop-widget" }, blur = true })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Core Apps & Actions
hl.bind(mainMod .. " + q", hl.dsp.window.close())
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty --title main"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty --title floating"))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + e", hl.dsp.exec_cmd("caja"))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.exec_cmd("kitty --title yazi -e yazi"))
hl.bind(mainMod .. " + c", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + d", hl.dsp.exec_cmd(scriptsDir .. "/menu.sh || pkill rofi"))
hl.bind("XF86Search", hl.dsp.exec_cmd(scriptsDir .. "/menu.sh || pkill rofi"))
hl.bind(mainMod .. " + SHIFT + m", hl.dsp.exit())

-- Windows & Tiling
hl.bind(mainMod .. " + v", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + v", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(mainMod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + g", hl.dsp.group.toggle())
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.exec_cmd(scriptsDir .. "/screenshot.sh --area"))
hl.bind(mainMod .. " + ALT + s", hl.dsp.exec_cmd(scriptsDir .. "/screenshot.sh --edit"))
hl.bind("print", hl.dsp.exec_cmd(scriptsDir .. "/screenshot.sh"))

-- Wallpapers & Themes
hl.bind(mainMod .. " + w", hl.dsp.exec_cmd(scriptsDir .. "/WallRandom.sh"))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperSelect.sh thm1"))
hl.bind(mainMod .. " + CTRL + SHIFT + w", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperSelect.sh thm2"))
hl.bind(mainMod .. " + t", hl.dsp.exec_cmd(scriptsDir .. "/theme_select.sh"))
hl.bind(mainMod .. " + ALT + t", hl.dsp.exec_cmd(scriptsDir .. "/toggle_dark_light.sh"))
hl.bind(mainMod .. " + ALT + d", hl.dsp.exec_cmd(scriptsDir .. "/rofi_theme.sh"))

-- Menus, Tools, Clipboard
hl.bind(mainMod .. " + x", hl.dsp.exec_cmd(scriptsDir .. "/wlogout.sh 2"))
hl.bind(mainMod .. " + ALT + x", hl.dsp.exec_cmd(scriptsDir .. "/wlogout.sh 1"))
hl.bind(mainMod .. " + ALT + c", hl.dsp.exec_cmd(scriptsDir .. "/cliphist.sh c"))
hl.bind(mainMod .. " + ALT + w", hl.dsp.exec_cmd(scriptsDir .. "/cliphist.sh w"))
hl.bind(mainMod .. " + SHIFT + d", hl.dsp.exec_cmd(scriptsDir .. "/rofi-emoji.sh"))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.exec_cmd(scriptsDir .. "/keybinds.sh"))
hl.bind(mainMod .. " + s", hl.dsp.exec_cmd("kitty --title browser sh -c '" .. scriptsDir .. "/settings.sh'"))

-- Waybar controls
hl.bind("CTRL + ESCAPE", hl.dsp.exec_cmd(scriptsDir .. "/waybar-reload.sh --toggle"))
hl.bind("CTRL + ALT + ESCAPE", hl.dsp.exec_cmd(scriptsDir .. "/waybar-reload.sh --reload"))
hl.bind(mainMod .. " + CTRL + w", hl.dsp.exec_cmd(scriptsDir .. "/waybar-layout.sh"))
hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/widgets/toggle_widget.sh"))

-- Lockscreen
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + ALT + l", hl.dsp.exec_cmd(scriptsDir .. "/hyprlock.sh"))

-- Reload
hl.bind(mainMod .. " + CTRL + r", hl.dsp.exec_cmd("hyprctl reload && notify-send 'Done' 'Hyprland reload'"))
hl.bind(mainMod .. " + SHIFT + r", hl.dsp.exec_cmd(scriptsDir .. "/startup.sh &> /dev/null"))

-- Window switching
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/themes/rofi-window.rasi"))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())

-- Move focus (arrows + vim keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h",     hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k",     hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j",     hl.dsp.focus({ direction = "down" }))

-- Move window with Super + Ctrl + vim keys
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "down" }))

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key,       hl.dsp.exec_cmd("hyprctl dispatch movetoworkspacesilent " .. i))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Drag / resize windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Pyprland integration
hl.bind(mainMod .. " + a",         hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + SHIFT + b", hl.dsp.exec_cmd("pypr expose"))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.exec_cmd("pypr change_workspace -1"))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.exec_cmd("pypr change_workspace +1"))
hl.bind(mainMod .. " + n",         hl.dsp.exec_cmd("pypr toggle_special minimized"))
hl.bind(mainMod .. " + SHIFT + n", hl.dsp.workspace.toggle_special("minimized"))
hl.bind(mainMod .. " + SHIFT + o", hl.dsp.exec_cmd("pypr shift_monitors +1"))
hl.bind(mainMod .. " + SHIFT + z", hl.dsp.exec_cmd("pypr zoom ++0.5"))
hl.bind(mainMod .. " + z",         hl.dsp.exec_cmd("pypr zoom"))

-- Custom App Shortcuts
hl.bind("F2",                    hl.dsp.exec_cmd('brave "https://mail.google.com"'))
hl.bind("XF86Mail",              hl.dsp.exec_cmd('brave "https://mail.google.com"'))
hl.bind("F3",                    hl.dsp.exec_cmd("brave --incognito"))
hl.bind("F5",                    hl.dsp.exec_cmd("spotify"))
hl.bind("XF86AudioMedia",        hl.dsp.exec_cmd("spotify"))
hl.bind("XF86Music",             hl.dsp.exec_cmd("spotify"))

-- Multimedia & Laptop keys
hl.bind("F11",                  hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --inc"), { locked = true, repeating = true })
hl.bind("F10",                  hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --dec"), { locked = true, repeating = true })
hl.bind("F9",                   hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --toggle"), { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(scriptsDir .. "/volumecontrol.sh --toggle-mic"), { locked = true })
hl.bind("F6",                   hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("F7",                   hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("F8",                   hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioStop",        hl.dsp.exec_cmd("playerctl stop"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/brightness.sh up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/brightness.sh down"))
