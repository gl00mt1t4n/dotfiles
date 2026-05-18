pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland IPC service — exposes workspace/window/monitor state to all shell components.
//
// QuickShell's built-in `Hyprland` singleton (from Quickshell.Hyprland) manages the
// socket connection automatically. This file wraps it with:
//   1. Clean property aliases so components only need `import "services"`
//   2. A Connections block that manually triggers targeted refreshes on IPC events —
//      this is what makes workspace pills and the active window title actually update.
//      Without these refresh calls the state would be stale after window/workspace changes.
Singleton {
    id: root

    readonly property var toplevels:  Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors:   Hyprland.monitors

    // focusedWorkspace / focusedMonitor: the workspace and monitor that currently have focus.
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor   focusedMonitor:   Hyprland.focusedMonitor

    // Convenience: the numeric ID of the active workspace (defaults to 1 if null).
    // Used by workspace pills to determine the active state.
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // activeToplevel: the window that currently has keyboard focus, or null if none.
    // The special-workspace filter (from caelestia) prevents a ghost title appearing
    // when toggling a special workspace with no windows on the regular workspace.
    readonly property HyprlandToplevel activeToplevel: {
        const t = Hyprland.activeToplevel
        return t?.workspace?.name.startsWith("special:") || Hyprland.focusedWorkspace?.toplevels.values.length > 0 ? t : null
    }

    // Send any command to Hyprland — equivalent to `hyprctl dispatch <cmd>`.
    // Used by workspace pills: Hypr.dispatch("workspace 3")
    // Used for scroll-to-switch: Hypr.dispatch("workspace e+1")
    function dispatch(cmd: string): void {
        Hyprland.dispatch(cmd)
    }

    // Listen to raw Hyprland IPC events and trigger targeted state refreshes.
    // Each event type only refreshes what it affects — no full reload on every event.
    // Without this, the shell's state goes stale after workspace/window changes.
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name

            // workspace / monitor events
            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces()
                Hyprland.refreshMonitors()
            // window open/close/move — also refreshes workspaces since windowCount changes
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels()
                Hyprland.refreshWorkspaces()
            // catch-all for other monitor/workspace/window events
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors()
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces()
            } else if (n.includes("window") || n.includes("group") ||
                       ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels()
            }
        }
    }
}
