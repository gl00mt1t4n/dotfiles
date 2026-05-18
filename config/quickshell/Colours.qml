// Catppuccin Mocha color palette — the single source of truth for every color in the shell.
// Every component reads from this; nothing has hardcoded hex strings anywhere else.
//
// pragma Singleton: QML creates exactly one instance of this object for the whole process.
// Anywhere you write `Colours.base`, it reads from that same instance — no imports needed.
// QuickShell auto-detects pragma Singleton files and registers them without a qmldir file.
pragma Singleton

import QtQuick

// QtObject: the lightest QML base type. No visual component, no layout, no rendering.
// Used here because this is pure data — a property bag, not a UI element.
QtObject {

    // --- Base surfaces (darkest to mid) ---
    // Used for window backgrounds, panel fill, deep container backgrounds.
    readonly property color crust:    "#11111b"  // darkest — rarely used directly
    readonly property color mantle:   "#181825"  // underneath base
    readonly property color base:     "#1e1e2e"  // primary background for the bar and windows

    // --- Surface layers (mid tones) ---
    // Used for cards, secondary panels, hover states.
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    // --- Overlay layers (used for borders and muted UI chrome) ---
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay2: "#9399b2"

    // --- Text layers ---
    // subtext for secondary labels, text for primary content.
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color text:     "#cdd6f4"  // primary text color

    // --- Accent colors ---
    // Used for highlights, active states, workspace pills, icons, alerts.
    readonly property color rosewater: "#f5e0dc"
    readonly property color flamingo:  "#f2cdcd"
    readonly property color pink:      "#f5c2e7"
    readonly property color mauve:     "#cba6f7"  // good for focused/active accents
    readonly property color red:       "#f38ba8"  // errors, critical notifications
    readonly property color maroon:    "#eba0ac"
    readonly property color peach:     "#fab387"
    readonly property color yellow:    "#f9e2af"  // warnings
    readonly property color green:     "#a6e3a1"  // success, connected, active
    readonly property color teal:      "#94e2d5"
    readonly property color sky:       "#89dceb"
    readonly property color sapphire:  "#74c7ec"
    readonly property color blue:      "#89b4fa"  // primary accent — active workspace pill
    readonly property color lavender:  "#b4befe"
}
