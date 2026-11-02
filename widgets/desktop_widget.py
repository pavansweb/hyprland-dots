#!/usr/bin/env python3
import os
import sys
import json
import signal
import subprocess
import datetime
import psutil

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell

class DesktopWidget(Gtk.Window):
    def __init__(self):
        super().__init__()

        # Load saved position or default to x: 80, y: 50
        self.current_x, self.current_y = self.load_position()
        self.dragging = False
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.orig_x = self.current_x
        self.orig_y = self.current_y

        # Setup GtkLayerShell: ALWAYS PINNED TO DESKTOP (BOTTOM LAYER)
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BOTTOM)
        GtkLayerShell.set_namespace(self, "desktop-widget")
        
        # Position on Desktop: Top-Left with dynamic/saved margins
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, self.current_y)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, self.current_x)
        
        # Non-exclusive so tiled windows appear over the wallpaper/widgets
        GtkLayerShell.set_exclusive_zone(self, 0)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        self.set_app_paintable(True)
        self.get_style_context().add_class("widget-window")

        # Main Layout Box
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        main_box.get_style_context().add_class("main-container")
        self.add(main_box)

        # 1. Header Card (Greeting, Clock, Date, and Drag Handle)
        header_card = self.create_header_card()
        main_box.pack_start(header_card, False, False, 0)

        # 2. Quick Launch Grid (Brave, Kitty, Projects Folder, Code)
        launcher_card = self.create_launchers_card()
        main_box.pack_start(launcher_card, False, False, 0)

        # 3. Two-Column Row (System Monitor + Media Player)
        bottom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        main_box.pack_start(bottom_row, False, False, 0)

        sys_card = self.create_system_card()
        bottom_row.pack_start(sys_card, True, True, 0)

        media_card = self.create_media_card()
        bottom_row.pack_start(media_card, True, True, 0)

        # Load CSS Styles
        self.load_css()

        # Update Timers
        GLib.timeout_add(1000, self.update_clock)
        GLib.timeout_add(2000, self.update_system_stats)
        GLib.timeout_add(1500, self.update_media)

        # Initial Updates
        self.update_clock()
        self.update_system_stats()
        self.update_media()

    def load_position(self):
        pos_file = os.path.expanduser("~/.config/hypr/widgets/position.json")
        if os.path.exists(pos_file):
            try:
                with open(pos_file, "r") as f:
                    data = json.load(f)
                    return data.get("x", 80), data.get("y", 50)
            except Exception:
                pass
        return 80, 50

    def save_position(self):
        pos_file = os.path.expanduser("~/.config/hypr/widgets/position.json")
        try:
            with open(pos_file, "w") as f:
                json.dump({"x": self.current_x, "y": self.current_y}, f)
        except Exception:
            pass

    def load_css(self):
        css_file = os.path.expanduser("~/.config/hypr/widgets/style.css")
        if os.path.exists(css_file):
            css_provider = Gtk.CssProvider()
            css_provider.load_from_path(css_file)
            screen = Gdk.Screen.get_default()
            style_context = Gtk.StyleContext()
            style_context.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def create_header_card(self):
        # EventBox wraps the header card so it can be clicked & dragged with mouse
        eb = Gtk.EventBox()
        eb.set_visible_window(False)
        eb.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK |
            Gdk.EventMask.ENTER_NOTIFY_MASK |
            Gdk.EventMask.LEAVE_NOTIFY_MASK
        )

        eb.connect("button-press-event", self.on_drag_start)
        eb.connect("button-release-event", self.on_drag_end)
        eb.connect("motion-notify-event", self.on_drag_motion)
        eb.connect("enter-notify-event", self.on_mouse_enter)
        eb.connect("leave-notify-event", self.on_mouse_leave)

        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("header-card")

        # Left: Greeting & Date + Drag Hint
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.greeting_label = Gtk.Label(label="", xalign=0)
        self.greeting_label.get_style_context().add_class("greeting-text")
        
        self.date_label = Gtk.Label(label="", xalign=0)
        self.date_label.get_style_context().add_class("date-text")

        drag_hint = Gtk.Label(label="󰆑 Drag to move anywhere", xalign=0)
        drag_hint.get_style_context().add_class("drag-hint")

        left_box.pack_start(self.greeting_label, False, False, 0)
        left_box.pack_start(self.date_label, False, False, 0)
        left_box.pack_start(drag_hint, False, False, 0)
        card.pack_start(left_box, True, True, 0)

        # Right: Clock (12-hour format)
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        right_box.set_valign(Gtk.Align.CENTER)
        self.clock_label = Gtk.Label(label="", xalign=1)
        self.clock_label.get_style_context().add_class("clock-text")
        right_box.pack_start(self.clock_label, True, True, 0)
        card.pack_end(right_box, False, False, 0)

        eb.add(card)
        return eb

    # Mouse Dragging Handlers
    def on_mouse_enter(self, widget, event):
        win = self.get_window()
        if win:
            display = Gdk.Display.get_default()
            win.set_cursor(Gdk.Cursor.new_from_name(display, "grab"))
        return False

    def on_mouse_leave(self, widget, event):
        if not self.dragging:
            win = self.get_window()
            if win:
                win.set_cursor(None)
        return False

    def on_drag_start(self, widget, event):
        if event.button == 1: # Left click
            self.dragging = True
            self.drag_start_x = event.x_root
            self.drag_start_y = event.y_root
            self.orig_x = self.current_x
            self.orig_y = self.current_y
            win = self.get_window()
            if win:
                display = Gdk.Display.get_default()
                win.set_cursor(Gdk.Cursor.new_from_name(display, "grabbing"))
            return True
        return False

    def on_drag_motion(self, widget, event):
        if self.dragging:
            dx = int(event.x_root - self.drag_start_x)
            dy = int(event.y_root - self.drag_start_y)
            new_x = max(10, min(1920 - 700, self.orig_x + dx))
            new_y = max(10, min(1080 - 450, self.orig_y + dy))
            self.current_x = new_x
            self.current_y = new_y
            GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, new_x)
            GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, new_y)
            return True
        return False

    def on_drag_end(self, widget, event):
        if event.button == 1 and self.dragging:
            self.dragging = False
            win = self.get_window()
            if win:
                display = Gdk.Display.get_default()
                win.set_cursor(Gdk.Cursor.new_from_name(display, "grab"))
            self.save_position()
            return True
        return False

    def create_launchers_card(self):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("launcher-card")

        title = Gtk.Label(label="Quick Launch", xalign=0)
        title.get_style_context().add_class("section-title")
        card.pack_start(title, False, False, 0)

        # Grid of launch buttons
        grid = Gtk.Grid()
        grid.set_column_spacing(12)
        grid.set_row_spacing(10)
        grid.set_column_homogeneous(True)
        card.pack_start(grid, True, True, 0)

        launchers = [
            ("󰈹", "Brave", "Browser", ["brave"], "launcher-brave"),
            ("󰞷", "Kitty", "Terminal", ["kitty"], "launcher-kitty"),
            ("󰉋", "Projects", "~/Projects", ["caja", os.path.expanduser("~/Projects")], "launcher-projects"),
            ("󰨞", "VS Code", "Code Editor", ["code"], "launcher-code"),
        ]

        for i, (icon, name, desc, cmd, css_class) in enumerate(launchers):
            btn = self.create_app_button(icon, name, desc, cmd, css_class)
            grid.attach(btn, i, 0, 1, 1)

        return card

    def create_app_button(self, icon, name, desc, cmd, css_class):
        btn = Gtk.Button()
        btn.get_style_context().add_class("app-button")
        btn.get_style_context().add_class(css_class)
        btn.connect("clicked", lambda b: self.launch_cmd(cmd))

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        icon_lbl = Gtk.Label(label=icon)
        icon_lbl.get_style_context().add_class("app-icon")

        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        name_lbl = Gtk.Label(label=name, xalign=0)
        name_lbl.get_style_context().add_class("app-name")
        desc_lbl = Gtk.Label(label=desc, xalign=0)
        desc_lbl.get_style_context().add_class("app-desc")

        text_box.pack_start(name_lbl, False, False, 0)
        text_box.pack_start(desc_lbl, False, False, 0)

        box.pack_start(icon_lbl, False, False, 0)
        box.pack_start(text_box, True, True, 0)
        btn.add(box)
        return btn

    def create_system_card(self):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.get_style_context().add_class("card")
        card.get_style_context().add_class("sys-card")

        title = Gtk.Label(label="System Monitor", xalign=0)
        title.get_style_context().add_class("section-title")
        card.pack_start(title, False, False, 0)

        # CPU Row
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

        # RAM Row
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

        # Disk Row
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

        # Clear Cache / System Boost Button
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

        import threading

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

        # Title
        top_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        title = Gtk.Label(label="Now Playing", xalign=0)
        title.get_style_context().add_class("section-title")
        self.media_source = Gtk.Label(label="  Spotify", xalign=1)
        self.media_source.get_style_context().add_class("media-source-label")
        top_box.pack_start(title, True, True, 0)
        top_box.pack_end(self.media_source, False, False, 0)
        card.pack_start(top_box, False, False, 0)

        # Info Box
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.track_title = Gtk.Label(label="No Media Playing", xalign=0)
        self.track_title.get_style_context().add_class("media-title")
        self.track_title.set_ellipsize(3) # Pango.EllipsizeMode.END

        self.track_artist = Gtk.Label(label="Enjoy your music", xalign=0)
        self.track_artist.get_style_context().add_class("media-artist")
        self.track_artist.set_ellipsize(3)

        info_box.pack_start(self.track_title, False, False, 0)
        info_box.pack_start(self.track_artist, False, False, 0)
        card.pack_start(info_box, True, True, 0)

        # Controls Row
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
            # CPU
            cpu = psutil.cpu_percent()
            self.cpu_val.set_text(f"{int(cpu)}%")
            self.cpu_bar.set_fraction(cpu / 100.0)

            # RAM
            vm = psutil.virtual_memory()
            used_gb = vm.used / (1024 ** 3)
            total_gb = vm.total / (1024 ** 3)
            self.ram_val.set_text(f"{used_gb:.1f} / {total_gb:.1f} GB ({int(vm.percent)}%)")
            self.ram_bar.set_fraction(vm.percent / 100.0)

            # Disk
            du = psutil.disk_usage('/')
            free_gb = du.free / (1024 ** 3)
            self.disk_val.set_text(f"{free_gb:.1f} GB Free ({int(du.percent)}% used)")
            self.disk_bar.set_fraction(du.percent / 100.0)
        except Exception:
            pass
        return True

    def update_media(self):
        try:
            # Check player status
            status = subprocess.check_output(
                ["playerctl", "status"], stderr=subprocess.DEVNULL
            ).decode().strip()
            
            if status == "Playing":
                self.btn_play.set_label("󰏤")
            else:
                self.btn_play.set_label("󰐊")

            # Check title & artist
            title = subprocess.check_output(
                ["playerctl", "metadata", "title"], stderr=subprocess.DEVNULL
            ).decode().strip()
            artist = subprocess.check_output(
                ["playerctl", "metadata", "artist"], stderr=subprocess.DEVNULL
            ).decode().strip()

            self.track_title.set_text(title if title else "Music Player")
            self.track_artist.set_text(artist if artist else "Playing")
        except Exception:
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

    def launch_cmd(self, cmd):
        subprocess.Popen(cmd, start_new_session=True)

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    app = DesktopWidget()
    app.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
