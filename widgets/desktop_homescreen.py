#!/usr/bin/env python3
"""
Antigravity Dedicated Home Screen Overlay
- Full-screen dashboard overlay toggled via Super+\
- Frosted glassmorphism with GPU blur via Hyprland layer rules
- Native 144Hz vsync-throttled drag-and-drop physics
- Desktop System Monitor, Clock, Media Player, and Apps Grid
- Immediate app launching, context menus, and persistence
"""

import os
import sys
import re
import json
import time
import socket
import signal
import shutil
import warnings
import datetime
import threading
import subprocess
import psutil

warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", category=PendingDeprecationWarning)

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, Gio, GLib, Pango, GtkLayerShell

# Paths
POS_FILE_ICONS = os.path.expanduser("~/.config/hypr/widgets/desktop_positions.json")
POS_FILE_WIDGET = os.path.expanduser("~/.config/hypr/widgets/position.json")
CSS_FILE = os.path.expanduser("~/.config/hypr/widgets/style.css")
SOCKET_FILE = f"/run/user/{os.getuid()}/desktop_homescreen.sock"

# Layout Constants
CELL_W = 92
CELL_H = 100
GRID_W = 108
GRID_H = 114

class DesktopHomeScreen(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.desktop_dir = os.path.expanduser("~/Desktop")
        os.makedirs(self.desktop_dir, exist_ok=True)

        self.is_open = False
        self.selected_widget = None
        self.debounce_timer = None

        # Drag Engine State (Frame-Throttled)
        self.drag_candidate = False
        self.is_dragging = False
        self.drag_target = None       # "icon" or "widget"
        self.drag_item = None
        self.drag_widget = None
        self.drag_cell_box = None
        self.drag_fname = None
        self.drag_orig_x = 0
        self.drag_orig_y = 0
        self.drag_grab_x = 0
        self.drag_grab_y = 0
        self.drag_start_win_x = 0
        self.drag_start_win_y = 0
        self.mouse_curr_x = 0
        self.mouse_curr_y = 0
        self.drag_tick_scheduled = False

        # Screen Dimensions
        self.screen_w = 1920
        self.screen_h = 1080
        self.detect_screen_bounds()

        # Load Saved Positions
        self.icon_config = self.load_icon_config()
        self.icon_positions = self.icon_config.get("positions", {})
        self.active_items = {}
        self.widget_x, self.widget_y = self.load_widget_position()

        # Setup Layer Shell Surface on OVERLAY layer for clean instant toggle
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_namespace(self, "desktop-homescreen")

        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)

        GtkLayerShell.set_exclusive_zone(self, 0)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_app_paintable(True)
        screen = Gdk.Screen.get_default()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.get_style_context().add_class("homescreen-overlay")

        # Events
        self.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK |
            Gdk.EventMask.KEY_PRESS_MASK
        )
        self.connect("motion-notify-event", self.on_motion)
        self.connect("button-release-event", self.on_release)
        self.connect("button-press-event", self.on_background_press)
        self.connect("key-press-event", self.on_key_press)
        self.connect("size-allocate", self.on_size_allocate)

        # Main Layout: Overlay Backdrop + Fixed Canvas
        self.fixed = Gtk.Fixed()
        self.add(self.fixed)

        # Load CSS
        self.load_css()

        # Seed shortcuts if empty
        self.seed_initial_shortcuts()

        # Build UI
        self.build_top_bar()
        self.build_desktop_widget()
        self.reload_desktop_items()

        # File monitor on ~/Desktop
        desktop_gio = Gio.File.new_for_path(self.desktop_dir)
        self.monitor = desktop_gio.monitor_directory(Gio.FileMonitorFlags.NONE, None)
        self.monitor.connect("changed", self.on_dir_changed)

        # Timers
        GLib.timeout_add(1000, self.update_clock)
        GLib.timeout_add(2000, self.update_system_stats)
        GLib.timeout_add(1500, self.update_media)

        self.update_clock()
        self.update_system_stats()
        self.update_media()

        # Start IPC Server
        self.start_socket_server()
        signal.signal(signal.SIGUSR1, lambda s, f: GLib.idle_add(self.toggle_overlay))

    def detect_screen_bounds(self):
        display = Gdk.Display.get_default()
        if display:
            monitor = display.get_primary_monitor() or (display.get_n_monitors() > 0 and display.get_monitor(0))
            if monitor:
                geom = monitor.get_geometry()
                self.screen_w = geom.width
                self.screen_h = geom.height

    def on_size_allocate(self, widget, alloc):
        self.screen_w = alloc.width
        self.screen_h = alloc.height

    def load_css(self):
        css_data = b"""
        window.homescreen-overlay {
            background-color: rgba(15, 17, 26, 0.78);
        }
        .top-bar-box {
            background: rgba(26, 27, 38, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.10);
            border-radius: 18px;
            padding: 10px 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
        }
        .top-bar-title {
            font-size: 15px;
            font-weight: 800;
            color: #89b4fa;
            letter-spacing: 0.5px;
        }
        .top-bar-hint {
            font-size: 12px;
            font-weight: 500;
            color: #a6adc8;
        }
        .close-btn {
            background: rgba(243, 139, 168, 0.15);
            border: 1px solid rgba(243, 139, 168, 0.35);
            border-radius: 12px;
            padding: 6px 14px;
            color: #f38ba8;
            font-weight: 800;
            font-size: 13px;
            transition: all 0.2s ease;
        }
        .close-btn:hover {
            background: #f38ba8;
            color: #11111b;
            box-shadow: 0 0 16px rgba(243, 139, 168, 0.45);
        }
        .desktop-icon-cell {
            border-radius: 16px;
            padding: 10px 6px;
            min-width: 92px;
            min-height: 100px;
            background-color: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.05);
            transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .desktop-icon-cell:hover {
            background-color: rgba(137, 180, 250, 0.18);
            border-color: rgba(137, 180, 250, 0.45);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45), 0 0 14px rgba(137, 180, 250, 0.25);
        }
        .desktop-icon-selected {
            background-color: rgba(137, 180, 250, 0.32);
            border: 1px solid #89b4fa;
            box-shadow: 0 8px 28px rgba(0, 0, 0, 0.5);
        }
        .desktop-icon-dragging {
            opacity: 0.95;
            background-color: rgba(137, 180, 250, 0.45);
            border: 2px dashed #89b4fa;
            box-shadow: 0 16px 36px rgba(0, 0, 0, 0.75), 0 0 24px rgba(137, 180, 250, 0.4);
        }
        .desktop-icon-label {
            color: #cdd6f4;
            font-family: "JetBrainsMono Nerd Font", sans-serif;
            font-size: 11px;
            font-weight: 700;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.9);
            margin-top: 4px;
        }
        .add-app-cell {
            background-color: rgba(166, 227, 161, 0.06);
            border: 1px dashed rgba(166, 227, 161, 0.3);
        }
        .add-app-cell:hover {
            background-color: rgba(166, 227, 161, 0.18);
            border-color: #a6e3a1;
            box-shadow: 0 8px 24px rgba(166, 227, 161, 0.3);
        }
        .add-app-icon {
            font-size: 28px;
            color: #a6e3a1;
        }
        .add-app-label {
            color: #a6e3a1;
            font-size: 11px;
            font-weight: 700;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css_data)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        if os.path.exists(CSS_FILE):
            p2 = Gtk.CssProvider()
            try:
                p2.load_from_path(CSS_FILE)
                Gtk.StyleContext.add_provider_for_screen(
                    Gdk.Screen.get_default(), p2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                )
            except Exception as e:
                print("Error loading custom style.css:", e)

    # -------------------------------------------------------------
    # Config & Position Persistence
    # -------------------------------------------------------------
    def load_icon_config(self):
        if os.path.exists(POS_FILE_ICONS):
            try:
                with open(POS_FILE_ICONS, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return {"grid_snap": True, "positions": {}}

    def save_icon_positions(self):
        try:
            with open(POS_FILE_ICONS, "w") as f:
                json.dump({"grid_snap": True, "positions": self.icon_positions}, f, indent=2)
        except Exception:
            pass

    def load_widget_position(self):
        if os.path.exists(POS_FILE_WIDGET):
            try:
                with open(POS_FILE_WIDGET, "r") as f:
                    d = json.load(f)
                    return d.get("x", 80), d.get("y", 120)
            except Exception:
                pass
        return 80, 120

    def save_widget_position(self):
        try:
            with open(POS_FILE_WIDGET, "w") as f:
                json.dump({"x": self.widget_x, "y": self.widget_y}, f)
        except Exception:
            pass

    # -------------------------------------------------------------
    # UI Structure: Top Navigation Bar
    # -------------------------------------------------------------
    def build_top_bar(self):
        self.top_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        self.top_bar.get_style_context().add_class("top-bar-box")
        self.top_bar.set_size_request(820, 52)

        icon_lbl = Gtk.Label(label="󰀻")
        icon_lbl.get_style_context().add_class("top-bar-title")
        title_lbl = Gtk.Label(label="Home Screen Dashboard")
        title_lbl.get_style_context().add_class("top-bar-title")

        hint_lbl = Gtk.Label(label="󰆑 Drag to rearrange • Double-click to launch • Esc to close")
        hint_lbl.get_style_context().add_class("top-bar-hint")

        close_btn = Gtk.Button(label="󰅖 Close")
        close_btn.get_style_context().add_class("close-btn")
        close_btn.connect("clicked", lambda b: self.hide_overlay())

        self.top_bar.pack_start(icon_lbl, False, False, 0)
        self.top_bar.pack_start(title_lbl, False, False, 0)
        self.top_bar.pack_start(hint_lbl, True, True, 0)
        self.top_bar.pack_end(close_btn, False, False, 0)

        # Center top bar horizontally at top of screen
        top_bar_x = max(10, (self.screen_w - 820) // 2)
        self.fixed.put(self.top_bar, top_bar_x, 24)

    # -------------------------------------------------------------
    # UI Structure: Desktop Widget (Clock, System, Media)
    # -------------------------------------------------------------
    def build_desktop_widget(self):
        self.widget_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.widget_box.get_style_context().add_class("main-container")

        # Header Card (Clock & Greeting & Drag Handle)
        header_card = self.create_header_card()
        self.widget_box.pack_start(header_card, False, False, 0)

        # Bottom Row: System Monitor + Media Player
        bottom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        self.widget_box.pack_start(bottom_row, False, False, 0)

        sys_card = self.create_system_card()
        bottom_row.pack_start(sys_card, True, True, 0)

        media_card = self.create_media_card()
        bottom_row.pack_start(media_card, True, True, 0)

        self.fixed.put(self.widget_box, self.widget_x, self.widget_y)

    def create_header_card(self):
        eb = Gtk.EventBox()
        eb.set_visible_window(False)
        eb.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK)
        eb.connect("button-press-event", self.on_header_press)
        eb.connect("enter-notify-event", lambda w, e: self.set_window_cursor("grab"))
        eb.connect("leave-notify-event", lambda w, e: self.set_window_cursor(None))

        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("header-card")

        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.greeting_label = Gtk.Label(label="", xalign=0)
        self.greeting_label.get_style_context().add_class("greeting-text")

        self.date_label = Gtk.Label(label="", xalign=0)
        self.date_label.get_style_context().add_class("date-text")

        drag_hint = Gtk.Label(label="󰆑 Drag widget to move", xalign=0)
        drag_hint.get_style_context().add_class("drag-hint")

        left_box.pack_start(self.greeting_label, False, False, 0)
        left_box.pack_start(self.date_label, False, False, 0)
        left_box.pack_start(drag_hint, False, False, 0)
        card.pack_start(left_box, True, True, 0)

        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        right_box.set_valign(Gtk.Align.CENTER)
        self.clock_label = Gtk.Label(label="", xalign=1)
        self.clock_label.get_style_context().add_class("clock-text")
        right_box.pack_start(self.clock_label, True, True, 0)
        card.pack_end(right_box, False, False, 0)

        eb.add(card)
        return eb

    def create_system_card(self):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("sys-card")

        title = Gtk.Label(label="System Monitor", xalign=0)
        title.get_style_context().add_class("section-title")
        card.pack_start(title, False, False, 0)

        # CPU
        cpu_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        cpu_head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        cpu_title = Gtk.Label(label="  CPU Usage", xalign=0)
        cpu_title.get_style_context().add_class("stat-label")
        self.cpu_val = Gtk.Label(label="0%", xalign=1)
        self.cpu_val.get_style_context().add_class("stat-value")
        cpu_head.pack_start(cpu_title, True, True, 0)
        cpu_head.pack_end(self.cpu_val, False, False, 0)

        self.cpu_bar = Gtk.ProgressBar()
        self.cpu_bar.get_style_context().add_class("cpu-bar")
        cpu_box.pack_start(cpu_head, False, False, 0)
        cpu_box.pack_start(self.cpu_bar, False, False, 0)
        card.pack_start(cpu_box, False, False, 0)

        # RAM
        ram_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        ram_head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        ram_title = Gtk.Label(label="  Memory", xalign=0)
        ram_title.get_style_context().add_class("stat-label")
        self.ram_val = Gtk.Label(label="0 GB", xalign=1)
        self.ram_val.get_style_context().add_class("stat-value")
        ram_head.pack_start(ram_title, True, True, 0)
        ram_head.pack_end(self.ram_val, False, False, 0)

        self.ram_bar = Gtk.ProgressBar()
        self.ram_bar.get_style_context().add_class("ram-bar")
        ram_box.pack_start(ram_head, False, False, 0)
        ram_box.pack_start(self.ram_bar, False, False, 0)
        card.pack_start(ram_box, False, False, 0)

        # Disk
        disk_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        disk_head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        disk_title = Gtk.Label(label="󰋊  Disk Storage", xalign=0)
        disk_title.get_style_context().add_class("stat-label")
        self.disk_val = Gtk.Label(label="0 GB", xalign=1)
        self.disk_val.get_style_context().add_class("stat-value")
        disk_head.pack_start(disk_title, True, True, 0)
        disk_head.pack_end(self.disk_val, False, False, 0)

        self.disk_bar = Gtk.ProgressBar()
        self.disk_bar.get_style_context().add_class("disk-bar")
        disk_box.pack_start(disk_head, False, False, 0)
        disk_box.pack_start(self.disk_bar, False, False, 0)
        card.pack_start(disk_box, False, False, 0)

        # Boost Button
        self.clear_cache_btn = Gtk.Button()
        self.clear_cache_btn.get_style_context().add_class("clear-cache-btn")
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_box.set_halign(Gtk.Align.CENTER)
        self.clear_cache_icon = Gtk.Label(label="󰃢")
        self.clear_cache_icon.get_style_context().add_class("clear-cache-icon")
        self.clear_cache_lbl = Gtk.Label(label="Boost & Clear Cache")
        self.clear_cache_lbl.get_style_context().add_class("clear-cache-label")
        btn_box.pack_start(self.clear_cache_icon, False, False, 0)
        btn_box.pack_start(self.clear_cache_lbl, False, False, 0)
        self.clear_cache_btn.add(btn_box)
        self.clear_cache_btn.connect("clicked", self.on_clear_cache_clicked)
        card.pack_start(self.clear_cache_btn, False, False, 0)

        return card

    def on_clear_cache_clicked(self, btn):
        if getattr(self, "is_clearing", False):
            return
        self.is_clearing = True
        self.clear_cache_btn.set_sensitive(False)
        self.clear_cache_btn.get_style_context().add_class("clearing")
        self.clear_cache_icon.set_text("󱑑")
        self.clear_cache_lbl.set_text("Clearing Cache...")

        def run_clean():
            script = os.path.expanduser("~/.config/hypr/scripts/clear_cache.sh")
            try:
                subprocess.run(["bash", script], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                print("Error clearing cache:", e)
            GLib.idle_add(self.on_clear_cache_finished)

        threading.Thread(target=run_clean, daemon=True).start()

    def on_clear_cache_finished(self):
        self.update_system_stats()
        self.clear_cache_btn.get_style_context().remove_class("clearing")
        self.clear_cache_btn.get_style_context().add_class("done")
        self.clear_cache_icon.set_text("󰄬")
        self.clear_cache_lbl.set_text("System Boosted!")

        def reset_btn():
            self.clear_cache_btn.get_style_context().remove_class("done")
            self.clear_cache_icon.set_text("󰃢")
            self.clear_cache_lbl.set_text("Boost & Clear Cache")
            self.clear_cache_btn.set_sensitive(True)
            self.is_clearing = False
            return False

        GLib.timeout_add(2500, reset_btn)

    def create_media_card(self):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("media-card")

        top_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        title = Gtk.Label(label="Now Playing", xalign=0)
        title.get_style_context().add_class("section-title")
        self.media_source = Gtk.Label(label="  Spotify", xalign=1)
        self.media_source.get_style_context().add_class("media-source-label")
        top_box.pack_start(title, True, True, 0)
        top_box.pack_end(self.media_source, False, False, 0)
        card.pack_start(top_box, False, False, 0)

        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.track_title = Gtk.Label(label="No Media Playing", xalign=0)
        self.track_title.get_style_context().add_class("media-title")
        self.track_title.set_ellipsize(Pango.EllipsizeMode.END)

        self.track_artist = Gtk.Label(label="Enjoy your music", xalign=0)
        self.track_artist.get_style_context().add_class("media-artist")
        self.track_artist.set_ellipsize(Pango.EllipsizeMode.END)

        info_box.pack_start(self.track_title, False, False, 0)
        info_box.pack_start(self.track_artist, False, False, 0)
        card.pack_start(info_box, True, True, 0)

        ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        ctrl_box.set_halign(Gtk.Align.CENTER)

        btn_prev = Gtk.Button(label="󰒮")
        btn_prev.get_style_context().add_class("media-ctrl-btn")
        btn_prev.connect("clicked", lambda b: self.run_player_cmd("previous"))

        self.btn_play = Gtk.Button(label="󰐊")
        self.btn_play.get_style_context().add_class("media-ctrl-btn")
        self.btn_play.get_style_context().add_class("media-play-btn")
        self.btn_play.connect("clicked", lambda b: self.run_player_cmd("play-pause"))

        btn_next = Gtk.Button(label="󰒭")
        btn_next.get_style_context().add_class("media-ctrl-btn")
        btn_next.connect("clicked", lambda b: self.run_player_cmd("next"))

        ctrl_box.pack_start(btn_prev, False, False, 0)
        ctrl_box.pack_start(self.btn_play, False, False, 0)
        ctrl_box.pack_start(btn_next, False, False, 0)
        card.pack_start(ctrl_box, False, False, 0)

        return card

    def update_clock(self):
        now = datetime.datetime.now()
        hour = now.hour
        if hour < 12:
            greet = "Good Morning, Zen ☀️"
        elif hour < 17:
            greet = "Good Afternoon, Zen 🌤️"
        elif hour < 21:
            greet = "Good Evening, Zen 🌙"
        else:
            greet = "Good Night, Zen ✨"

        self.greeting_label.set_text(greet)
        self.date_label.set_text(now.strftime("%A, %B %d, %Y"))
        self.clock_label.set_markup(now.strftime('%I:%M <span font_size="16pt" font_weight="bold" color="#89dceb">%p</span>'))
        return True

    def update_system_stats(self):
        try:
            cpu = psutil.cpu_percent()
            self.cpu_val.set_text(f"{int(cpu)}%")
            self.cpu_bar.set_fraction(cpu / 100.0)

            vm = psutil.virtual_memory()
            used_gb = vm.used / (1024 ** 3)
            total_gb = vm.total / (1024 ** 3)
            self.ram_val.set_text(f"{used_gb:.1f} / {total_gb:.1f} GB ({int(vm.percent)}%)")
            self.ram_bar.set_fraction(vm.percent / 100.0)

            du = psutil.disk_usage('/')
            free_gb = du.free / (1024 ** 3)
            self.disk_val.set_text(f"{free_gb:.1f} GB Free ({int(du.percent)}% used)")
            self.disk_bar.set_fraction(du.percent / 100.0)
        except Exception:
            pass
        return True

    def update_media(self):
        try:
            out = subprocess.check_output(
                ["playerctl", "metadata", "--format", "{{status}}:::{{title}}:::{{artist}}"],
                stderr=subprocess.DEVNULL,
                timeout=0.2
            ).decode().strip()

            if out:
                parts = out.split(":::")
                status = parts[0] if len(parts) > 0 else "Paused"
                title = parts[1] if len(parts) > 1 and parts[1] else "No Media Playing"
                artist = parts[2] if len(parts) > 2 and parts[2] else "Spotify is idle"

                if status == "Playing":
                    self.btn_play.set_label("󰏤")
                else:
                    self.btn_play.set_label("󰐊")

                self.track_title.set_text(title)
                self.track_artist.set_text(artist)
                return True
        except Exception:
            pass

        self.track_title.set_text("No Media Playing")
        self.track_artist.set_text("Spotify is idle")
        self.btn_play.set_label("󰐊")
        return True

    def run_player_cmd(self, cmd):
        try:
            subprocess.Popen(["playerctl", cmd])
            GLib.timeout_add(200, self.update_media)
        except Exception:
            pass

    # -------------------------------------------------------------
    # UI Structure: Desktop Applications Grid
    # -------------------------------------------------------------
    def seed_initial_shortcuts(self):
        existing = [f for f in os.listdir(self.desktop_dir) if f.endswith(".desktop")]
        if not existing:
            candidates = [
                "/usr/share/applications/brave-browser.desktop",
                "/usr/share/applications/discord.desktop",
                "/usr/share/applications/com.microsoft.VSCode.desktop",
                "/usr/share/applications/kitty.desktop",
                "/usr/share/applications/caja.desktop",
                "/usr/share/applications/spotify.desktop",
                "/usr/share/applications/firefox.desktop",
            ]
            for src in candidates:
                if os.path.exists(src):
                    dst = os.path.join(self.desktop_dir, os.path.basename(src))
                    try:
                        shutil.copy2(src, dst)
                        os.chmod(dst, 0o755)
                    except Exception:
                        pass

    def on_dir_changed(self, monitor, file, other_file, event_type):
        if self.debounce_timer:
            GLib.source_remove(self.debounce_timer)
        self.debounce_timer = GLib.timeout_add(150, self._do_reload)

    def _do_reload(self):
        self.debounce_timer = None
        self.reload_desktop_items()
        return False

    def reload_desktop_items(self):
        items = self.scan_desktop_folder()

        for it_data in self.active_items.values():
            self.fixed.remove(it_data["widget"])
        self.active_items.clear()

        # Remove previous "+ Add App" card if present
        if hasattr(self, "add_app_widget") and self.add_app_widget in self.fixed.get_children():
            self.fixed.remove(self.add_app_widget)

        # Apps Grid Origin (to the right of Widget by default or user positions)
        grid_start_x = 800
        grid_start_y = 120

        occupied_slots = set()
        for it in items:
            fname = it["filename"]
            if fname in self.icon_positions:
                pos = self.icon_positions[fname]
                occupied_slots.add((pos["x"], pos["y"]))

        max_rows = max(3, (self.screen_h - 180) // GRID_H)

        for it in items:
            fname = it["filename"]
            if fname in self.icon_positions:
                x = self.icon_positions[fname]["x"]
                y = self.icon_positions[fname]["y"]
            else:
                x, y = self.find_next_free_slot(occupied_slots, grid_start_x, grid_start_y, max_rows)
                self.icon_positions[fname] = {"x": x, "y": y}
                occupied_slots.add((x, y))

            widget = self.create_icon_widget(it)
            self.fixed.put(widget, x, y)
            self.active_items[fname] = {
                "widget": widget,
                "item": it,
                "x": x,
                "y": y
            }

        # Add the "+ Add Application" tile at next free slot
        add_x, add_y = self.find_next_free_slot(occupied_slots, grid_start_x, grid_start_y, max_rows)
        self.add_app_widget = self.create_add_app_tile()
        self.fixed.put(self.add_app_widget, add_x, add_y)

        self.save_icon_positions()
        self.fixed.show_all()

    def find_next_free_slot(self, occupied_slots, start_x, start_y, max_rows):
        col = 0
        while True:
            for row in range(max_rows):
                gx = start_x + col * GRID_W
                gy = start_y + row * GRID_H
                if (gx, gy) not in occupied_slots:
                    return gx, gy
            col += 1

    def scan_desktop_folder(self):
        items = []
        try:
            files = sorted(os.listdir(self.desktop_dir), key=lambda x: (not x.endswith(".desktop"), x.lower()))
        except Exception:
            return items

        for fname in files:
            if fname.startswith("."):
                continue
            path = os.path.join(self.desktop_dir, fname)

            if fname.endswith(".desktop"):
                try:
                    info = Gio.DesktopAppInfo.new_from_filename(path)
                    if info:
                        name = info.get_name() or fname[:-8]
                        gicon = info.get_icon()
                        cmd = info.get_commandline() or info.get_executable()
                        is_term = info.get_string("Terminal") == "true"
                        items.append({
                            "type": "app",
                            "name": name,
                            "path": path,
                            "filename": fname,
                            "gicon": gicon,
                            "icon_name": gicon.to_string() if gicon else "application-x-executable",
                            "cmd": cmd,
                            "is_term": is_term,
                            "info": info
                        })
                        continue
                except Exception:
                    pass

            if os.path.isdir(path):
                items.append({
                    "type": "directory",
                    "name": fname,
                    "path": path,
                    "filename": fname,
                    "gicon": Gio.ThemedIcon.new("folder"),
                    "icon_name": "folder"
                })
                continue

            if os.path.isfile(path):
                content_type, _ = Gio.content_type_guess(path)
                gicon = Gio.content_type_get_icon(content_type)
                items.append({
                    "type": "file",
                    "name": fname,
                    "path": path,
                    "filename": fname,
                    "gicon": gicon,
                    "icon_name": gicon.to_string() if gicon else "text-x-generic"
                })

        return items

    def create_icon_widget(self, item):
        eb = Gtk.EventBox()
        eb.set_visible_window(False)
        eb.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK)

        cell_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        cell_box.get_style_context().add_class("desktop-icon-cell")
        cell_box.set_size_request(CELL_W, CELL_H)
        cell_box.set_halign(Gtk.Align.CENTER)
        cell_box.set_valign(Gtk.Align.CENTER)

        if item.get("gicon"):
            img = Gtk.Image.new_from_gicon(item["gicon"], Gtk.IconSize.DIALOG)
        else:
            img = Gtk.Image.new_from_icon_name(item.get("icon_name", "application-x-executable"), Gtk.IconSize.DIALOG)
        img.set_pixel_size(48)
        img.set_halign(Gtk.Align.CENTER)
        cell_box.pack_start(img, False, False, 0)

        lbl = Gtk.Label(label=item["name"])
        lbl.get_style_context().add_class("desktop-icon-label")
        lbl.set_line_wrap(True)
        lbl.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR)
        lbl.set_justify(Gtk.Justification.CENTER)
        lbl.set_max_width_chars(11)
        lbl.set_ellipsize(Pango.EllipsizeMode.END)
        lbl.set_lines(2)
        cell_box.pack_start(lbl, False, False, 0)

        eb.add(cell_box)

        eb.connect("button-press-event", self.on_icon_press, item, eb, cell_box)
        eb.connect("enter-notify-event", lambda w, e: self.set_window_cursor("pointer"))
        eb.connect("leave-notify-event", lambda w, e: self.set_window_cursor(None))

        return eb

    def create_add_app_tile(self):
        eb = Gtk.EventBox()
        eb.set_visible_window(False)
        eb.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK)

        cell_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        cell_box.get_style_context().add_class("desktop-icon-cell")
        cell_box.get_style_context().add_class("add-app-cell")
        cell_box.set_size_request(CELL_W, CELL_H)
        cell_box.set_halign(Gtk.Align.CENTER)
        cell_box.set_valign(Gtk.Align.CENTER)

        icon_lbl = Gtk.Label(label="➕")
        icon_lbl.get_style_context().add_class("add-app-icon")
        cell_box.pack_start(icon_lbl, True, True, 0)

        text_lbl = Gtk.Label(label="Add App")
        text_lbl.get_style_context().add_class("add-app-label")
        cell_box.pack_start(text_lbl, False, False, 0)

        eb.add(cell_box)
        eb.connect("button-press-event", lambda w, e: self.open_add_app_dialog())
        eb.connect("enter-notify-event", lambda w, e: self.set_window_cursor("pointer"))
        eb.connect("leave-notify-event", lambda w, e: self.set_window_cursor(None))
        return eb

    def set_window_cursor(self, name):
        if not self.is_dragging:
            win = self.get_window()
            if win:
                if name:
                    win.set_cursor(Gdk.Cursor.new_from_name(Gdk.Display.get_default(), name))
                else:
                    win.set_cursor(None)

    def launch_item(self, item):
        item_type = item.get("type")
        path = item.get("path")

        # Hide overlay on launch
        self.hide_overlay()

        if item_type == "app":
            cmd = item.get("cmd")
            if not cmd and item.get("info"):
                cmd = item["info"].get_executable()

            if cmd:
                cleaned = re.sub(r'%[a-zA-Z]', '', cmd).strip()
                if item.get("is_term"):
                    exec_list = ["kitty", "-e"] + cleaned.split()
                else:
                    exec_list = cleaned
                subprocess.Popen(exec_list, shell=isinstance(exec_list, str), start_new_session=True)
            elif item.get("info"):
                item["info"].launch([], None)

        elif item_type == "directory":
            subprocess.Popen(["caja", path], start_new_session=True)

        elif item_type == "file":
            subprocess.Popen(["xdg-open", path], start_new_session=True)

    def show_context_menu(self, event, item):
        menu = Gtk.Menu()

        item_open = Gtk.MenuItem(label=f"🚀  Launch '{item['name']}'")
        item_open.connect("activate", lambda m: self.launch_item(item))
        menu.append(item_open)

        menu.append(Gtk.SeparatorMenuItem())

        item_add = Gtk.MenuItem(label="➕  Add Application to Home Screen...")
        item_add.connect("activate", lambda m: self.open_add_app_dialog())
        menu.append(item_add)

        item_refresh = Gtk.MenuItem(label="🔄  Refresh Home Screen")
        item_refresh.connect("activate", lambda m: self.reload_desktop_items())
        menu.append(item_refresh)

        item_caja = Gtk.MenuItem(label="📂  Open Desktop Folder")
        item_caja.connect("activate", lambda m: subprocess.Popen(["caja", self.desktop_dir], start_new_session=True))
        menu.append(item_caja)

        menu.append(Gtk.SeparatorMenuItem())

        item_del = Gtk.MenuItem(label=f"🗑️  Remove '{item['name']}'")
        item_del.connect("activate", lambda m: self.delete_item(item))
        menu.append(item_del)

        menu.show_all()
        menu.popup_at_pointer(event)

    def delete_item(self, item):
        path = item.get("path")
        if path and os.path.exists(path):
            try:
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
            except Exception as e:
                print("Error deleting item:", e)
        fname = item.get("filename")
        if fname in self.icon_positions:
            del self.icon_positions[fname]
            self.save_icon_positions()
        self.reload_desktop_items()

    def open_add_app_dialog(self):
        script = os.path.expanduser("~/.config/hypr/widgets/add_desktop_app.py")
        if os.path.exists(script):
            subprocess.Popen(["python3", script], start_new_session=True)

    # -------------------------------------------------------------
    # High-Performance Frame-Throttled Drag Engine
    # -------------------------------------------------------------
    def on_icon_press(self, widget, event, item, eb_widget, cell_box):
        fname = item["filename"]

        if self.selected_widget and self.selected_widget != cell_box:
            self.selected_widget.get_style_context().remove_class("desktop-icon-selected")
        self.selected_widget = cell_box
        self.selected_widget.get_style_context().add_class("desktop-icon-selected")

        # Double click to launch immediately
        if event.type == Gdk.EventType._2BUTTON_PRESS and event.button == 1:
            self.drag_candidate = False
            self.launch_item(item)
            return True

        # Right-click context menu
        if event.button == 3:
            self.drag_candidate = False
            self.show_context_menu(event, item)
            return True

        if event.button == 1:
            cur_pos = self.icon_positions.get(fname, {"x": 800, "y": 120})
            orig_x = cur_pos["x"]
            orig_y = cur_pos["y"]

            self.drag_target = "icon"
            self.drag_item = item
            self.drag_widget = eb_widget
            self.drag_cell_box = cell_box
            self.drag_fname = fname
            self.drag_orig_x = orig_x
            self.drag_orig_y = orig_y
            self.drag_grab_x = event.x
            self.drag_grab_y = event.y
            self.drag_start_win_x = orig_x + event.x
            self.drag_start_win_y = orig_y + event.y
            self.mouse_curr_x = self.drag_start_win_x
            self.mouse_curr_y = self.drag_start_win_y
            self.drag_candidate = True
            self.is_dragging = False
            return True

        return False

    def on_header_press(self, widget, event):
        if event.button == 1:
            header_alloc = widget.get_allocation()
            grab_x = header_alloc.x + event.x
            grab_y = header_alloc.y + event.y

            self.drag_target = "widget"
            self.drag_item = None
            self.drag_widget = self.widget_box
            self.drag_cell_box = None
            self.drag_fname = None
            self.drag_orig_x = self.widget_x
            self.drag_orig_y = self.widget_y
            self.drag_grab_x = grab_x
            self.drag_grab_y = grab_y
            self.drag_start_win_x = self.widget_x + grab_x
            self.drag_start_win_y = self.widget_y + grab_y
            self.mouse_curr_x = self.drag_start_win_x
            self.mouse_curr_y = self.drag_start_win_y
            self.drag_candidate = True
            self.is_dragging = False
            return True
        return False

    def on_motion(self, widget, event):
        if not self.drag_candidate or not self.drag_widget:
            return False

        self.mouse_curr_x = event.x
        self.mouse_curr_y = event.y

        # Throttle layout updates to display refresh rate
        if not self.drag_tick_scheduled:
            self.drag_tick_scheduled = True
            GLib.idle_add(self._process_drag_frame)

        return True

    def _process_drag_frame(self):
        self.drag_tick_scheduled = False

        if not self.drag_candidate or not self.drag_widget:
            return False

        dx = self.mouse_curr_x - self.drag_start_win_x
        dy = self.mouse_curr_y - self.drag_start_win_y

        if not self.is_dragging:
            if (dx * dx + dy * dy) >= 16:
                self.is_dragging = True
                if self.drag_target == "icon" and self.drag_cell_box:
                    self.drag_cell_box.get_style_context().add_class("desktop-icon-dragging")
                elif self.drag_target == "widget":
                    self.widget_box.get_style_context().add_class("widget-dragging")

                win = self.get_window()
                if win:
                    win.set_cursor(Gdk.Cursor.new_from_name(Gdk.Display.get_default(), "grabbing"))

        if self.is_dragging:
            target_x = int(self.mouse_curr_x - self.drag_grab_x)
            target_y = int(self.mouse_curr_y - self.drag_grab_y)

            if self.drag_target == "icon":
                target_x = max(10, min(self.screen_w - CELL_W - 10, target_x))
                target_y = max(80, min(self.screen_h - CELL_H - 10, target_y))
                self.fixed.move(self.drag_widget, target_x, target_y)
                self.icon_positions[self.drag_fname] = {"x": target_x, "y": target_y}

            elif self.drag_target == "widget":
                w_alloc = self.widget_box.get_allocation()
                ww = max(660, w_alloc.width)
                wh = max(250, w_alloc.height)
                target_x = max(10, min(self.screen_w - ww - 10, target_x))
                target_y = max(80, min(self.screen_h - wh - 10, target_y))
                self.fixed.move(self.widget_box, target_x, target_y)
                self.widget_x = target_x
                self.widget_y = target_y

        return False

    def on_release(self, widget, event):
        if event.button == 1 and (self.drag_candidate or self.is_dragging):
            self.finish_drag()
            return True
        return False

    def finish_drag(self):
        if self.is_dragging:
            if self.drag_target == "icon" and self.drag_widget and self.drag_fname:
                if self.drag_cell_box:
                    self.drag_cell_box.get_style_context().remove_class("desktop-icon-dragging")

                fname = self.drag_fname
                pos = self.icon_positions.get(fname, {"x": self.drag_orig_x, "y": self.drag_orig_y})
                target_x = pos["x"]
                target_y = pos["y"]

                # Native Grid Snapping
                snapped_x = self.snap_coord(target_x, 800, GRID_W, 10, self.screen_w - CELL_W - 10)
                snapped_y = self.snap_coord(target_y, 120, GRID_H, 80, self.screen_h - CELL_H - 10)

                conflict = None
                for other_fname, opos in self.icon_positions.items():
                    if other_fname != fname and opos.get("x") == snapped_x and opos.get("y") == snapped_y:
                        conflict = other_fname
                        break

                if conflict and conflict in self.active_items:
                    self.icon_positions[conflict] = {"x": self.drag_orig_x, "y": self.drag_orig_y}
                    self.fixed.move(self.active_items[conflict]["widget"], self.drag_orig_x, self.drag_orig_y)

                self.fixed.move(self.drag_widget, snapped_x, snapped_y)
                self.icon_positions[fname] = {"x": snapped_x, "y": snapped_y}
                self.save_icon_positions()

            elif self.drag_target == "widget":
                self.widget_box.get_style_context().remove_class("widget-dragging")
                self.save_widget_position()

        self.drag_candidate = False
        self.is_dragging = False
        self.drag_target = None
        self.drag_widget = None
        self.drag_item = None
        self.drag_cell_box = None
        self.drag_fname = None

        win = self.get_window()
        if win:
            win.set_cursor(None)

    def snap_coord(self, val, offset, step, min_val, max_val):
        idx = round((val - offset) / step)
        snapped = offset + idx * step
        return max(min_val, min(max_val, snapped))

    def on_background_press(self, widget, event):
        # Click on empty background dismisses overlay
        if event.button == 1 and not self.drag_candidate:
            pass
        return False

    def on_key_press(self, widget, event):
        # Escape dismisses overlay or cancels drag
        if event.keyval == Gdk.KEY_Escape:
            if self.is_dragging:
                self.cancel_drag()
            else:
                self.hide_overlay()
            return True
        return False

    def cancel_drag(self):
        if self.is_dragging:
            if self.drag_target == "icon" and self.drag_widget and self.drag_fname:
                if self.drag_cell_box:
                    self.drag_cell_box.get_style_context().remove_class("desktop-icon-dragging")
                self.fixed.move(self.drag_widget, self.drag_orig_x, self.drag_orig_y)
                self.icon_positions[self.drag_fname] = {"x": self.drag_orig_x, "y": self.drag_orig_y}
            elif self.drag_target == "widget":
                self.widget_box.get_style_context().remove_class("widget-dragging")
                self.widget_x = self.drag_orig_x
                self.widget_y = self.drag_orig_y
                self.fixed.move(self.widget_box, self.widget_x, self.widget_y)

        self.drag_candidate = False
        self.is_dragging = False
        self.drag_target = None
        self.drag_widget = None
        self.drag_item = None
        self.drag_cell_box = None
        self.drag_fname = None

        win = self.get_window()
        if win:
            win.set_cursor(None)

    # -------------------------------------------------------------
    # Overlay Visibility & IPC Management
    # -------------------------------------------------------------
    def show_overlay(self):
        self.is_open = True
        self.show_all()
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)
        self.present()

    def hide_overlay(self):
        self.is_open = False
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        self.hide()

    def toggle_overlay(self):
        if self.is_open:
            self.hide_overlay()
        else:
            self.show_overlay()
        return False

    def start_socket_server(self):
        if os.path.exists(SOCKET_FILE):
            try:
                os.remove(SOCKET_FILE)
            except OSError:
                pass

        def server_thread():
            server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            server.bind(SOCKET_FILE)
            server.listen(5)
            while True:
                try:
                    conn, _ = server.accept()
                    data = conn.recv(1024).decode().strip()
                    if data == "toggle":
                        GLib.idle_add(self.toggle_overlay)
                        conn.sendall(b"OK\n")
                    elif data == "show":
                        GLib.idle_add(self.show_overlay)
                        conn.sendall(b"OK\n")
                    elif data == "hide":
                        GLib.idle_add(self.hide_overlay)
                        conn.sendall(b"OK\n")
                    elif data == "reload":
                        GLib.idle_add(self.reload_desktop_items)
                        conn.sendall(b"OK\n")
                    elif data == "quit":
                        conn.sendall(b"OK\n")
                        conn.close()
                        GLib.idle_add(Gtk.main_quit)
                        break
                    else:
                        conn.sendall(b"UNKNOWN\n")
                    conn.close()
                except Exception:
                    pass

        threading.Thread(target=server_thread, daemon=True).start()

def send_ipc_command(cmd):
    if os.path.exists(SOCKET_FILE):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(0.5)
            s.connect(SOCKET_FILE)
            s.sendall(f"{cmd}\n".encode())
            resp = s.recv(1024).decode().strip()
            s.close()
            return resp == "OK"
        except Exception:
            pass
    return False

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)

    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg in ("--toggle", "-t"):
            if send_ipc_command("toggle"):
                sys.exit(0)
        elif arg in ("--show", "-s"):
            if send_ipc_command("show"):
                sys.exit(0)
        elif arg in ("--hide", "-h"):
            if send_ipc_command("hide"):
                sys.exit(0)
        elif arg in ("--reload", "-r"):
            if send_ipc_command("reload"):
                sys.exit(0)

    # Check if already running
    if send_ipc_command("toggle"):
        sys.exit(0)

    app = DesktopHomeScreen()
    app.show_overlay()
    Gtk.main()

if __name__ == "__main__":
    main()
