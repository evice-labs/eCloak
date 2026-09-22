import QtQuick 2.15

QtObject {
    id: theme

    // =========================================================================
    // Backgrounds & Surfaces
    // =========================================================================
    readonly property color bgRail: "#141414" 
    readonly property color bgSidebar: "#141414"          
    readonly property color bgChat: "#1C1C1C"             
    readonly property color bgHover: "#2F2F2F"              
    readonly property color bgActive: "#232323"             
    readonly property color bgInput: "#1F1F1F"              
    readonly property color bgCard: "#232323"               
    readonly property color bgCardInner: "#171717"          
    readonly property color bgCardHover: "#2F2F2F"          
    readonly property color bgTooltip: "#232323"            
    readonly property color bgModal: "#1C1C1C"              
    readonly property color bgModalOverlay: "#80000000"    
    readonly property color bgRecessed: "#1F1F1F"           
    readonly property color bgRaised: "#232323"             

    // =========================================================================
    // Text Colors
    // =========================================================================
    readonly property color textHeader: "#FFFFFF"          
    readonly property color textNormal: "#A4A4A4"           
    readonly property color textSubtle: "#A9A9A9"           
    readonly property color textTertiary: "#969696"         
    readonly property color textMuted: "#717784"            
    readonly property color textInteractive: "#A4A4A4"      
    readonly property color textInteractiveActive: "#FFFFFF"

    // Primary Color (Solid Vibrant Blue)
    readonly property color primary: "#256FE6"
    readonly property color primaryHover: "#1B5DCA"
    readonly property color primaryPressed: "#134499"
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
    readonly property color accentEvice: primary
    readonly property color accentEviceHover: primaryHover
    readonly property color accentLogos: primary
    readonly property color accentLogosHover: primaryHover

    // =========================================================================
    // Status & Utility Colors
    // =========================================================================
    readonly property color accentSuccess: "#49F563"       
    readonly property color accentSuccessHover: "#6CCC93"  
    readonly property color accentSuccessBg: "#14301C"      
    readonly property color accentDanger: "#FB3748"         
    readonly property color accentDangerHover: "#FF736A"    
    readonly property color accentDangerBg: "#361517"       
    readonly property color accentWarning: "#FEBC2E"        
    readonly property color accentWarningHover: "#FFA726"   
    readonly property color accentWarningBg: "#362811"      
    readonly property color accentInfo: "#4A90E2"          

    // =========================================================================
    // Borders & Dividers 
    // =========================================================================
    readonly property color border: "#434343"               
    readonly property color borderSubtle: "#333333"         
    readonly property color borderDark: "#2F2F2F"          
    readonly property color borderStrong: "#515151"         
    readonly property color borderCard: "#333333"
    readonly property color divider: "#333333"

    // =========================================================================
    // Radii & Spacing 
    // =========================================================================
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusSquircle: 16
    readonly property int radiusCircle: 24

    // =========================================================================
    // Typography 
    // =========================================================================
    readonly property string fontFamily: "Public Sans, Inter, -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif"
    readonly property string fontFamilyMono: "'SF Mono', 'Roboto Mono', 'Fira Code', 'DejaVu Sans Mono', monospace"

    // Durations
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
