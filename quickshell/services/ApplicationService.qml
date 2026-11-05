pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

QtObject {
    id: root

    property int _appsVersion: 0

    // React to DesktopEntries changes
    property var _conn: Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root._appsVersion++;
        }
    }

    property var _modelConn: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root._appsVersion++;
        }
        function onObjectInsertedPost() {
            root._appsVersion++;
        }
    }

    // List of all valid, non-hidden DesktopEntry objects
    readonly property var allApps: {
        var _v = root._appsVersion;
        var raw = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        if (!raw || raw.length === 0) return [];

        var list = [];
        var seenNames = {};

        for (var i = 0; i < raw.length; i++) {
            var entry = raw[i];
            if (!entry || entry.noDisplay || !entry.name || entry.name.trim().length === 0) {
                continue;
            }
            var lowerName = entry.name.toLowerCase().trim();
            if (seenNames[lowerName]) {
                continue;
            }
            seenNames[lowerName] = true;
            list.push(entry);
        }

        list.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });

        return list;
    }

    // List of pinned DesktopEntry objects based on Settings.pinnedApps
    readonly property var pinnedApps: {
        var _v = root._appsVersion;
        var pinnedIds = Settings.pinnedApps;
        var list = [];
        for (var i = 0; i < pinnedIds.length; i++) {
            var id = pinnedIds[i];
            var entry = DesktopEntries.byId(id);
            if (!entry) {
                entry = DesktopEntries.byId(id + ".desktop");
            }
            if (!entry) {
                entry = DesktopEntries.heuristicLookup(id.replace(".desktop", ""));
            }
            if (entry && !entry.noDisplay) {
                list.push(entry);
            }
        }
        return list;
    }

    // List of dock apps based on Settings.dockPinnedApps
    readonly property var dockApps: {
        var _v = root._appsVersion;
        var ids = Settings.dockPinnedApps;
        var list = [];
        for (var i = 0; i < ids.length; i++) {
            var id = ids[i];
            var entry = DesktopEntries.byId(id);
            if (!entry) {
                entry = DesktopEntries.byId(id + ".desktop");
            }
            if (!entry) {
                entry = DesktopEntries.heuristicLookup(id.replace(".desktop", ""));
            }
            if (entry && !entry.noDisplay) {
                list.push(entry);
            }
        }
        return list;
    }

    function resolveIcon(entry, fallback) {
        if (!entry) return Quickshell.iconPath(fallback || "application-x-executable", "");
        var iconName = entry.icon || entry.startupClass || entry.name.toLowerCase();
        return Quickshell.iconPath(iconName, fallback || "application-x-executable");
    }

    // Check if an application is running in Hyprland
    function findToplevel(entry) {
        if (!entry || !Hyprland.toplevels) return null;
        var toplevels = Hyprland.toplevels.values;
        if (!toplevels) return null;

        var targetClass = (entry.startupClass || "").toLowerCase();
        var targetName = (entry.name || "").toLowerCase();
        var targetId = (entry.id || "").replace(".desktop", "").toLowerCase();

        for (var i = 0; i < toplevels.length; i++) {
            var top = toplevels[i];
            if (!top) continue;

            var appId = "";
            if (top.waylandHandle && top.waylandHandle.appId) {
                appId = top.waylandHandle.appId.toLowerCase();
            } else if (top.lastIpcObject && top.lastIpcObject.class) {
                appId = top.lastIpcObject.class.toLowerCase();
            }

            if (appId.length > 0) {
                if (targetClass && appId.indexOf(targetClass) !== -1) return top;
                if (targetId && appId.indexOf(targetId) !== -1) return top;
                if (targetName && appId.indexOf(targetName) !== -1) return top;
            }
        }
        return null;
    }

    function isRunning(entry) {
        return findToplevel(entry) !== null;
    }

    // Launch or focus application
    function activateApp(entry) {
        if (!entry) return;
        var runningTop = findToplevel(entry);
        if (runningTop && runningTop.address) {
            Hyprland.dispatch("focuswindow address:" + runningTop.address);
        } else {
            entry.execute();
        }
    }
}
