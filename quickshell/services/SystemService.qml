pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property real cpuUsage: 0.0
    property string memUsed: "0.0"
    property string memTotal: "0.0"
    property real memPercent: 0.0
    property string uptime: "0m"
    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    property real _prevCpuTotal: 0
    property real _prevCpuIdle: 0

    property var _sysProc: Process {
        id: proc
        command: [
            "awk",
            "/^cpu / {for(i=2;i<=NF;i++) t+=$i; id=$5+$6; print \"CPU:\" t \":\" id} /^MemTotal:/ {tot=$2} /^MemAvailable:/ {avail=$2} END {used=tot-avail; print \"MEM:\" used \":\" tot; getline < \"/proc/uptime\"; print \"UPTIME:\" $1}",
            "/proc/stat",
            "/proc/meminfo"
        ]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var line = data.trim();
                if (!line) return;

                if (line.startsWith("CPU:")) {
                    var parts = line.split(":");
                    if (parts.length >= 3) {
                        var total = parseFloat(parts[1]);
                        var idle = parseFloat(parts[2]);
                        if (root._prevCpuTotal > 0) {
                            var diffTotal = total - root._prevCpuTotal;
                            var diffIdle = idle - root._prevCpuIdle;
                            if (diffTotal > 0) {
                                var usage = Math.max(0, Math.min(100, Math.round((1 - (diffIdle / diffTotal)) * 100)));
                                root.cpuUsage = usage;

                                var hist = root.cpuHistory.slice();
                                hist.push(usage);
                                if (hist.length > 20) hist.shift();
                                root.cpuHistory = hist;
                            }
                        }
                        root._prevCpuTotal = total;
                        root._prevCpuIdle = idle;
                    }
                } else if (line.startsWith("MEM:")) {
                    var mParts = line.split(":");
                    if (mParts.length >= 3) {
                        var usedKb = parseFloat(mParts[1]);
                        var totKb = parseFloat(mParts[2]);
                        if (totKb > 0) {
                            root.memUsed = (usedKb / 1048576).toFixed(1);
                            root.memTotal = (totKb / 1048576).toFixed(1);
                            root.memPercent = Math.max(0, Math.min(100, Math.round((usedKb / totKb) * 100)));
                        }
                    }
                } else if (line.startsWith("UPTIME:")) {
                    var uSec = parseFloat(line.substring(7));
                    if (!isNaN(uSec)) {
                        var days = Math.floor(uSec / 86400);
                        var hours = Math.floor((uSec % 86400) / 3600);
                        var mins = Math.floor((uSec % 3600) / 60);
                        if (days > 0) {
                            root.uptime = days + "d " + hours + "h " + mins + "m";
                        } else if (hours > 0) {
                            root.uptime = hours + "h " + mins + "m";
                        } else {
                            root.uptime = mins + "m";
                        }
                    }
                }
            }
        }
    }

    property var _timer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }
}
