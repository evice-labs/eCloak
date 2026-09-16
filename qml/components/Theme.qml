import QtQuick 2.15

QtObject {
    id: theme

    // =========================================================================
    // Backgrounds & Surfaces (Derived from Logos Design System / Logos Chat)
    // =========================================================================
    readonly property color bgRail: "#141414"               // Logos Theme.palette.backgroundInset (gray925)
    readonly property color bgSidebar: "#141414"            // Changed to match serverRail (#141414)
    readonly property color bgChat: "#1C1C1C"               // Changed to previous sidebar color (#1C1C1C)
    readonly property color bgHover: "#2F2F2F"              // Logos Theme.palette.backgroundButton (gray340)
    readonly property color bgActive: "#232323"             // Logos Theme.palette.surfaceRaised (gray360)
    readonly property color bgInput: "#1F1F1F"              // Logos Theme.palette.surfaceRecessed (gray370)
    readonly property color bgCard: "#232323"               // Logos Theme.palette.surfaceRaised (gray360)
    readonly property color bgCardInner: "#171717"          // Inner card background
    readonly property color bgCardHover: "#2F2F2F"          // Logos Theme.palette.surfaceInteractiveHover (gray300)
    readonly property color bgTooltip: "#0E121B"            // Logos Theme.palette.backgroundElevated (gray950)
    readonly property color bgModal: "#1C1C1C"              // Logos Theme.palette.backgroundTertiary (gray875)
    readonly property color bgModalOverlay: "#80000000"      // Logos Theme.palette.scrim (blackOpacity50)
    readonly property color bgRecessed: "#1F1F1F"           // Logos Theme.palette.surfaceRecessed
    readonly property color bgRaised: "#232323"             // Logos Theme.palette.surfaceRaised

    // =========================================================================
    // Text Colors (Logos Design System Typography Palette)
    // =========================================================================
    readonly property color textHeader: "#FFFFFF"           // Logos Theme.palette.text (white)
    readonly property color textNormal: "#A4A4A4"           // Logos Theme.palette.textSecondary (gray400)
    readonly property color textSubtle: "#A9A9A9"           // Logos Theme.palette.textSubtle (gray390)
    readonly property color textTertiary: "#969696"         // Logos Theme.palette.textTertiary (gray500)
    readonly property color textMuted: "#717784"            // Logos Theme.palette.textPlaceholder (gray600)
    readonly property color textInteractive: "#A4A4A4"      // Logos Theme.palette.textSecondary
    readonly property color textInteractiveActive: "#FFFFFF"// Logos Theme.palette.text

    // Primary Color
    readonly property color primary: "#5390E7"              // Equivalent of orange300 #ED7B58 (L*=64.1)
    readonly property color primaryHover: "#256FE6"         // Equivalent of orange500 #F55702 (L*=58.3)
    readonly property color primaryPressed: "#134499"       // Equivalent of orange800 #8F3C03 (L*=36.1)
    readonly property color primarySoft: "#C4DBFF"          // Equivalent of peach100 #FFD5C0 (L*=88.3)
    readonly property color primaryBorder: Qt.rgba(0.325, 0.565, 0.906, 0.4) // 40% opacity accent
    readonly property color focus: "#4080F0"                // Equivalent of orange400 #FF8800 (L*=68.7)

    // Aliases mapped to the unified Blue accent
    readonly property color accentPrimary: primary
    readonly property color accentPrimaryHover: primaryHover
    readonly property color accentPrimaryPressed: primaryPressed
    readonly property color accentPrimarySoft: primarySoft
    readonly property color accentBlurple: primary
    readonly property color accentBlurpleHover: primaryHover
    readonly property color accentLogos: primary
    readonly property color accentLogosHover: primaryHover

    // =========================================================================
    // Status & Utility Colors (Logos Design System)
    // =========================================================================
    readonly property color accentSuccess: "#49F563"        // Logos Theme.palette.success (green500)
    readonly property color accentSuccessHover: "#6CCC93"   // Logos Theme.palette.successHover (green400)
    readonly property color accentSuccessBg: "#14301C"      // Recessed success tint
    readonly property color accentDanger: "#FB3748"         // Logos Theme.palette.error (red500)
    readonly property color accentDangerHover: "#FF736A"    // Logos Theme.palette.errorHover (red400)
    readonly property color accentDangerBg: "#361517"       // Recessed error tint
    readonly property color accentWarning: "#FEBC2E"        // Logos Theme.palette.warning (yellow400)
    readonly property color accentWarningHover: "#FFA726"   // Logos Theme.palette.warningHover (yellow500)
    readonly property color accentWarningBg: "#362811"      // Recessed warning tint
    readonly property color accentInfo: "#4A90E2"           // Logos Theme.palette.info (blue400)

    // =========================================================================
    // Borders & Dividers (Logos Design System)
    // =========================================================================
    readonly property color border: "#434343"               // Logos Theme.palette.border (gray300)
    readonly property color borderSubtle: "#333333"         // Logos Theme.palette.borderSubtle (gray330)
    readonly property color borderDark: "#2F2F2F"           // Logos Theme.palette.borderDark (gray340)
    readonly property color borderStrong: "#515151"         // Logos Theme.palette.borderStrong (gray350)
    readonly property color borderCard: "#333333"
    readonly property color divider: "#333333"

    // =========================================================================
    // Radii & Spacing (Logos Design System)
    // =========================================================================
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusSquircle: 16
    readonly property int radiusCircle: 24

    // =========================================================================
    // Typography (Logos uses Public Sans / Inter)
    // =========================================================================
    readonly property string fontFamily: "Public Sans, Inter, -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif"
    readonly property string fontFamilyMono: "'SF Mono', 'Roboto Mono', 'Fira Code', 'DejaVu Sans Mono', monospace"

    // Durations
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
