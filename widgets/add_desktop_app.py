#!/usr/bin/env python3
import os
import sys
import shutil
import warnings
import subprocess

warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", category=PendingDeprecationWarning)
from gi.repository import Gtk, Gdk, Gio, GLib, Pango

class AddDesktopAppDialog(Gtk.Window):
    def __init__(self):
        super().__init__(title="Add Application to Home Screen")
        self.set_default_size(540, 620)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_modal(True)
        self.desktop_dir = os.path.expanduser("~/Desktop")
        os.makedirs(self.desktop_dir, exist_ok=True)

        self.get_style_context().add_class("app-chooser-window")

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        main_box.set_margin_top(18)
        main_box.set_margin_bottom(18)
        main_box.set_margin_left(20)
        main_box.set_margin_right(20)
        self.add(main_box)

        # Header Title
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_label = Gtk.Label(label="Add to Home Screen", xalign=0)
        title_label.get_style_context().add_class("dialog-title")
        subtitle_label = Gtk.Label(label="Select an application to create a desktop shortcut", xalign=0)
        subtitle_label.get_style_context().add_class("dialog-subtitle")
        title_box.pack_start(title_label, False, False, 0)
        title_box.pack_start(subtitle_label, False, False, 0)
        main_box.pack_start(title_box, False, False, 0)

        # Search Entry
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search applications (e.g. Brave, Discord, Steam)...")
        self.search_entry.connect("search-changed", self.on_search_changed)
        main_box.pack_start(self.search_entry, False, False, 0)

        # Scrolled List Box
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.IN)
        scrolled.get_style_context().add_class("app-list-scrolled")

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.listbox.connect("row-activated", self.on_row_activated)
        scrolled.add(self.listbox)
        main_box.pack_start(scrolled, True, True, 0)

        # Footer Buttons
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        footer.set_halign(Gtk.Align.END)

        btn_cancel = Gtk.Button(label="Cancel")
        btn_cancel.get_style_context().add_class("dialog-btn-secondary")
        btn_cancel.connect("clicked", lambda b: self.destroy())

        self.btn_add = Gtk.Button(label="Add to Desktop")
        self.btn_add.get_style_context().add_class("dialog-btn-primary")
        self.btn_add.connect("clicked", self.on_add_clicked)

        footer.pack_start(btn_cancel, False, False, 0)
        footer.pack_start(self.btn_add, False, False, 0)
        main_box.pack_start(footer, False, False, 0)

        self.load_css()
        self.apps = self.load_installed_apps()
        self.populate_list(self.apps)

        self.connect("key-press-event", self.on_key_press)

    def load_css(self):
        css = b"""
        window.app-chooser-window {
            background-color: #1e1e2e;
            color: #cdd6f4;
            font-family: "JetBrainsMono Nerd Font", "Cantarell", sans-serif;
        }
        .dialog-title {
            font-size: 18px;
            font-weight: 800;
            color: #89b4fa;
        }
        .dialog-subtitle {
            font-size: 12px;
            color: #a6adc8;
        }
        searchentry {
            background-color: #181825;
            color: #cdd6f4;
            border: 1px solid #313244;
            border-radius: 10px;
            padding: 8px 12px;
            font-size: 13px;
        }
        searchentry:focus {
            border-color: #89b4fa;
        }
        .app-list-scrolled {
            background-color: #181825;
            border: 1px solid #313244;
            border-radius: 12px;
        }
        list row {
            padding: 8px 12px;
            border-bottom: 1px solid rgba(49, 50, 68, 0.5);
            background: transparent;
            transition: all 150ms ease;
        }
        list row:hover {
            background-color: rgba(137, 180, 250, 0.12);
        }
        list row:selected {
            background-color: rgba(137, 180, 250, 0.25);
            border-radius: 8px;
        }
        .app-item-title {
            font-size: 14px;
            font-weight: 700;
            color: #cdd6f4;
        }
        .app-item-desc {
            font-size: 11px;
            color: #a6adc8;
        }
        .dialog-btn-secondary {
            background-color: #313244;
            color: #cdd6f4;
            border: none;
            border-radius: 8px;
            padding: 8px 18px;
            font-weight: 600;
        }
        .dialog-btn-secondary:hover {
            background-color: #45475a;
        }
        .dialog-btn-primary {
            background-color: #89b4fa;
            color: #11111b;
            border: none;
            border-radius: 8px;
            padding: 8px 20px;
            font-weight: 700;
        }
        .dialog-btn-primary:hover {
            background-color: #b4befe;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def load_installed_apps(self):
        apps = []
        seen = set()
        dirs = [
            os.path.expanduser("~/.local/share/applications"),
            "/usr/share/applications"
        ]

        theme = Gtk.IconTheme.get_default()

        for d in dirs:
            if not os.path.exists(d):
                continue
            for fname in os.listdir(d):
                if not fname.endswith(".desktop"):
                    continue
                path = os.path.join(d, fname)
                try:
                    info = Gio.DesktopAppInfo.new_from_filename(path)
                    if not info or not info.should_show():
                        continue
                    name = info.get_name()
                    if not name or name in seen:
                        continue
                    seen.add(name)

                    desc = info.get_description() or info.get_display_name() or ""
                    gicon = info.get_icon()
                    icon_name = gicon.to_string() if gicon else "application-x-executable"

                    apps.append({
                        "name": name,
                        "desc": desc,
                        "path": path,
                        "filename": fname,
                        "icon_name": icon_name,
                        "gicon": gicon
                    })
                except Exception:
                    pass

        apps.sort(key=lambda x: x["name"].lower())
        return apps

    def populate_list(self, apps):
        # Clear existing
        for child in self.listbox.get_children():
            self.listbox.remove(child)

        for app in apps:
            row = Gtk.ListBoxRow()
            row.app_data = app

            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
            box.set_margin_top(4)
            box.set_margin_bottom(4)

            # Icon
            if app["gicon"]:
                img = Gtk.Image.new_from_gicon(app["gicon"], Gtk.IconSize.DND)
            else:
                img = Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DND)
            img.set_pixel_size(36)
            box.pack_start(img, False, False, 0)

            # Text
            text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            lbl_name = Gtk.Label(label=app["name"], xalign=0)
            lbl_name.get_style_context().add_class("app-item-title")

            lbl_desc = Gtk.Label(label=app["desc"] if app["desc"] else app["filename"], xalign=0)
            lbl_desc.get_style_context().add_class("app-item-desc")
            lbl_desc.set_ellipsize(Pango.EllipsizeMode.END)
            lbl_desc.set_max_width_chars(42)

            text_box.pack_start(lbl_name, False, False, 0)
            text_box.pack_start(lbl_desc, False, False, 0)
            box.pack_start(text_box, True, True, 0)

            row.add(box)
            self.listbox.add(row)

        self.listbox.show_all()

    def on_search_changed(self, entry):
        query = entry.get_text().strip().lower()
        if not query:
            filtered = self.apps
        else:
            filtered = [
                a for a in self.apps
                if query in a["name"].lower() or query in a["desc"].lower() or query in a["filename"].lower()
            ]
        self.populate_list(filtered)

    def on_row_activated(self, listbox, row):
        if row and hasattr(row, "app_data"):
            self.add_app_to_desktop(row.app_data)

    def on_add_clicked(self, btn):
        row = self.listbox.get_selected_row()
        if row and hasattr(row, "app_data"):
            self.add_app_to_desktop(row.app_data)

    def add_app_to_desktop(self, app_data):
        src = app_data["path"]
        dst_filename = app_data["filename"]
        dst = os.path.join(self.desktop_dir, dst_filename)

        try:
            shutil.copy2(src, dst)
            # Make executable
            os.chmod(dst, 0o755)

            # Send desktop notification
            try:
                subprocess.Popen([
                    "notify-send",
                    "-i", app_data["icon_name"],
                    "Home Screen",
                    f"Added {app_data['name']} to home screen!"
                ])
            except Exception:
                pass

            self.destroy()
        except Exception as e:
            try:
                subprocess.Popen(["notify-send", "Error", f"Failed to add shortcut: {e}"])
            except Exception:
                pass

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

def main():
    win = AddDesktopAppDialog()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
