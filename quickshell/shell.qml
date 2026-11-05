import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.styles
import qs.config
import qs.services
import qs.components

ShellRoot {
    id: shellRoot

    // Instantiation for each connected screen
    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            // Dock on each monitor (layer-shell bottom layer)
            LeftDock {
                screen: screenScope.modelData
            }

            // Desktop Canvas for widgets & desktop apps (layer-shell background layer, behind all apps)
            PanelWindow {
                id: desktopCanvas
                screen: screenScope.modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0

                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "nothing-desktop:canvas"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                // Only intercept input on active widgets & app launcher; empty desktop passes through
                mask: Region {
                    Region { item: desktopIcons }
                    Region { item: clockWidget }
                    Region { item: systemMonitor }
                    Region { item: weatherWidget }
                    Region { item: musicWidget }
                    Region { item: notesWidget }
                }

                // Desktop Applications Launcher / Icons
                DesktopIcons {
                    id: desktopIcons
                }

                // Clock Widget
                ClockWidget {
                    id: clockWidget
                }

                // System Monitor Widget
                SystemMonitor {
                    id: systemMonitor
                }

                // Weather Widget
                WeatherWidget {
                    id: weatherWidget
                }

                // Music / Media Widget
                MusicWidget {
                    id: musicWidget
                }

                // Persistent Notes Widget
                NotesWidget {
                    id: notesWidget
                }
            }
        }
    }
}
