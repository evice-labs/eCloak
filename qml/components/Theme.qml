import QtQuick 2.15

QtObject {
    id: theme

    // Backgrounds (Discord Dark Theme Palette)
    readonly property color bgRail: "#1e1f22"
    readonly property color bgSidebar: "#2b2d31"
    readonly property color bgChat: "#313338"
    readonly property color bgHover: "#35373c"
    readonly property color bgActive: "#404249"
    readonly property color bgInput: "#383a40"
    readonly property color bgCard: "#232428"
    readonly property color bgTooltip: "#111214"
    readonly property color bgModal: "#313338"
    readonly property color bgModalOverlay: "#cc000000"

    // Text Colors
    readonly property color textHeader: "#f2f3f5"
    readonly property color textNormal: "#dbdee1"
    readonly property color textMuted: "#949ba4"
    readonly property color textInteractive: "#b5bac1"
    readonly property color textInteractiveActive: "#ffffff"

    // Accent Colors
    readonly property color accentBlurple: "#5865f2"
    readonly property color accentBlurpleHover: "#4752c4"
    readonly property color accentLogos: "#00d4aa"
    readonly property color accentLogosHover: "#00b894"
    readonly property color accentDanger: "#f23f43"
    readonly property color accentDangerHover: "#da373c"
    readonly property color accentWarning: "#f0b232"
    readonly property color accentSuccess: "#23a55a"

    // Borders & Dividers
    readonly property color borderSubtle: "#3f4147"
    readonly property color divider: "#35363c"

    // Radii & Spacing
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusSquircle: 16
    readonly property int radiusCircle: 24

    // Durations
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
