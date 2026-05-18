import QtQuick

// Shows the title of the currently focused window.
// Fades out when no window is focused (activeToplevel is null).
Text {
    // ?. is null-safe access: returns undefined when activeToplevel is null.
    // ?? "" converts undefined/null to empty string so `text` is never undefined.
    readonly property string title: Hypr.activeToplevel?.title ?? ""

    // Truncate long titles at 60 chars with an ellipsis.
    // The unicode ellipsis (…) is one character vs three dots (...).
    text:  title.length > 60 ? title.slice(0, 57) + "…" : title

    color: Colours.subtext0
    font.pixelSize:      13
    elide:               Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment:   Text.AlignVCenter

    // Fade in/out when switching between focused and unfocused state.
    // Behavior attaches an animation to any change in `opacity`.
    opacity: title.length > 0 ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
}
