pragma Singleton

import QtQuick
import Quickshell

// Singleton: QuickShell base type for process-global singletons.
// Unlike QtObject, it has a default property so child objects (like SystemClock) work.
Singleton {
    // Expose the raw date object and individual time components so consumers
    // can either use `format()` for custom strings or read values directly.
    readonly property date date:    clock.date
    readonly property int  hours:   clock.hours
    readonly property int  minutes: clock.minutes
    readonly property int  seconds: clock.seconds

    // Pre-formatted strings used by the bar clock.
    // Qt.formatDateTime accepts SystemClock.date directly (QDateTime under the hood).
    // "HH:mm" = 24-hour time, zero-padded. Change to "hh:mm:A" for 12-hour + AM/PM.
    readonly property string timeStr: format("HH:mm")
    readonly property string dateStr: format("dddd, MMMM d")

    // General-purpose formatter — any Qt date format string works here.
    // e.g. Time.format("yyyy-MM-dd"), Time.format("HH:mm:ss")
    function format(fmt) {
        return Qt.formatDateTime(clock.date, fmt)
    }

    SystemClock {
        id: clock
        // Ticks once per second. Switch to SystemClock.Minutes if you never
        // display seconds, to avoid unnecessary binding re-evaluations.
        precision: SystemClock.Seconds
    }
}
