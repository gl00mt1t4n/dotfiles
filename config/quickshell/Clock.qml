import QtQuick

// Displays the current time from the Time singleton.
// font.family "monospace" prevents the clock width from jumping as digits change
// (e.g. "10:00" vs "9:59" differ in width in proportional fonts).
Text {
    text:             Time.timeStr
    color:            Colours.text
    font.pixelSize:   14
    font.family:      "monospace"
    verticalAlignment: Text.AlignVCenter
}
