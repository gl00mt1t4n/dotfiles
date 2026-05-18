import QtQuick
import QtQuick.Layouts

// Row of workspace indicator pills.
// Only workspaces that exist in Hyprland are shown (workspaces are created on first visit).
// Clicking a pill dispatches a workspace switch command to Hyprland.
RowLayout {
    spacing: 5

    Repeater {
        // .values converts QuickShell's ObjectModel<HyprlandWorkspace> to a reactive
        // QML list. Repeater re-runs when workspaces are created or destroyed.
        model: Hypr.workspaces.values

        delegate: Rectangle {
            // `required` makes the delegate explicitly declare which model properties
            // it reads. modelData is the HyprlandWorkspace object for this item.
            required property var modelData

            // isActive: this workspace is the one currently visible on the focused monitor.
            // Drives the pill's accent color and bold text.
            readonly property bool isActive: modelData.id === Hypr.activeWsId

            // isOccupied: workspace has at least one open window.
            // lastIpcObject is the raw JSON from Hyprland IPC — `windows` is the count.
            // Falls back to 0 if the property isn't populated yet.
            readonly property bool isOccupied: (modelData.lastIpcObject?.windows ?? 0) > 0

            implicitWidth:  28
            implicitHeight: 28
            radius:          8

            // Three visual states:
            //   active   → blue pill (Catppuccin accent)
            //   occupied → surface0 (mid-tone, has windows but not focused)
            //   empty    → overlay0 (subtle, no windows)
            color: isActive   ? Colours.blue    :
                   isOccupied ? Colours.surface0 :
                                Colours.overlay0

            // Animate color changes so workspace switches don't snap harshly.
            // ColorAnimation interpolates between the old and new color values.
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            // Workspace number label.
            Text {
                anchors.centerIn: parent
                text:           modelData.id
                font.pixelSize: 11
                font.bold:      parent.isActive

                // Invert text color on active pill so it stays readable against blue.
                color: parent.isActive ? Colours.base : Colours.subtext0
            }

            // Click handler: dispatch "workspace N" to Hyprland, same as SUPER+N.
            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Hypr.dispatch("workspace " + modelData.id)
            }
        }
    }
}
