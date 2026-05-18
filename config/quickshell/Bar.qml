import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Top bar — a wlr-layer-shell surface anchored to the top edge of the screen.
// All bar components (Workspaces, ActiveWindow, Clock) live inside the RowLayout.
// Components in the same directory (bar/) are available as types without imports.
PanelWindow {
    anchors {
        top:   true
        left:  true
        right: true
    }

    // exclusiveZone: reserves this many pixels at the top edge.
    // Prevents windows from being placed under the bar.
    exclusiveZone: implicitHeight
    implicitHeight: 40

    color: Colours.base

    RowLayout {
        anchors {
            fill:        parent
            leftMargin:  12
            rightMargin: 12
        }
        spacing: 8

        // Left section: workspace pills.
        Workspaces {}

        // Center section: active window title, stretches to fill available space.
        // Layout.fillWidth pushes Clock to the right edge.
        ActiveWindow {
            Layout.fillWidth: true
        }

        // Right section: clock.
        Clock {}
    }
}
