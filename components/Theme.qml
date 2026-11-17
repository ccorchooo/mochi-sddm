pragma Singleton
import QtQuick
import "Colors.js" as C

// Shared design tokens: Material You color roles, type, shape and motion.
QtObject {
    id: theme

    // ---- color -----------------------------------------------------------
    property real seedHue: 255
    property real seedChroma: 0.09
    property string variant: "tonalspot"
    property string mode: "dark"
    readonly property var s: C.scheme(seedHue, seedChroma, variant, mode)

    readonly property color primary: s.primary
    readonly property color fgPrimary: s.onPrimary
    readonly property color primaryContainer: s.primaryContainer
    readonly property color fgPrimaryContainer: s.onPrimaryContainer
    readonly property color inversePrimary: s.inversePrimary
    readonly property color secondary: s.secondary
    readonly property color fgSecondary: s.onSecondary
    readonly property color secondaryContainer: s.secondaryContainer
    readonly property color fgSecondaryContainer: s.onSecondaryContainer
    readonly property color tertiary: s.tertiary
    readonly property color fgTertiary: s.onTertiary
    readonly property color tertiaryContainer: s.tertiaryContainer
    readonly property color fgTertiaryContainer: s.onTertiaryContainer
    readonly property color surface: s.surface
    readonly property color surfaceDim: s.surfaceDim
    readonly property color surfaceContainerLowest: s.surfaceContainerLowest
    readonly property color surfaceContainerLow: s.surfaceContainerLow
    readonly property color surfaceContainer: s.surfaceContainer
    readonly property color surfaceContainerHigh: s.surfaceContainerHigh
    readonly property color surfaceContainerHighest: s.surfaceContainerHighest
    readonly property color fgSurface: s.onSurface
    readonly property color fgSurfaceVariant: s.onSurfaceVariant
    readonly property color outline: s.outline
    readonly property color outlineVariant: s.outlineVariant
    readonly property color inverseSurface: s.inverseSurface
    readonly property color inverseOnSurface: s.inverseOnSurface
    readonly property color error: s.error
    readonly property color fgError: s.onError
    readonly property color errorContainer: s.errorContainer
    readonly property color fgErrorContainer: s.onErrorContainer

    function role(name) { return s[name] !== undefined ? s[name] : s.onSurface }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // ---- type ------------------------------------------------------------
    // Bundled fonts (fetched by install.sh into ../fonts) win; otherwise the
    // first installed system family from each list is used.
    property FontLoader _sans:   FontLoader { source: Qt.resolvedUrl("../fonts/GoogleSansFlex.ttf") }
    property FontLoader _round:  FontLoader { source: Qt.resolvedUrl("../fonts/Fredoka.ttf") }
    property FontLoader _mono:   FontLoader { source: Qt.resolvedUrl("../fonts/JetBrainsMono.ttf") }
    property FontLoader _dots:   FontLoader { source: Qt.resolvedUrl("../fonts/Doto.ttf") }
    property FontLoader _serif:  FontLoader { source: Qt.resolvedUrl("../fonts/DMSerifDisplay.ttf") }
    property FontLoader _thin:   FontLoader { source: Qt.resolvedUrl("../fonts/Outfit.ttf") }
    property FontLoader _icons:  FontLoader { source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf") }

    property string uiFontOverride: ""

    function _pick(loader, candidates) {
        if (loader.status === FontLoader.Ready) return loader.name
        var fams = Qt.fontFamilies()
        for (var i = 0; i < candidates.length; i++)
            if (fams.indexOf(candidates[i]) >= 0) return candidates[i]
        return candidates[candidates.length - 1]
    }

    readonly property string sans:    uiFontOverride !== "" ? uiFontOverride
                                      : _pick(_sans, ["Google Sans Flex", "Google Sans", "Product Sans", "Rubik", "Inter", "Adwaita Sans", "sans-serif"])
    readonly property string rounded: _pick(_round, ["Fredoka", "Nunito", "Varela Round", "Rubik", sans])
    readonly property string mono:    _pick(_mono, ["JetBrains Mono", "JetBrainsMono Nerd Font Mono", "Adwaita Mono", "monospace"])
    readonly property string dots:    _pick(_dots, ["Doto", "Silkscreen", mono])
    readonly property string serif:   _pick(_serif, ["DM Serif Display", "Fraunces", "C059", "serif"])
    readonly property string thin:    _pick(_thin, ["Outfit", "Rubik", sans])
    readonly property string icons:   _pick(_icons, ["Material Symbols Rounded", "Material Symbols Outlined", "Material Icons Round"])

    function family(key) {
        switch (key) {
        case "rounded": return rounded
        case "mono": return mono
        case "dots": return dots
        case "serif": return serif
        case "thin": return thin
        default: return sans
        }
    }

    // ---- shape -----------------------------------------------------------
    readonly property real cornerXS: 4
    readonly property real cornerS: 8
    readonly property real cornerM: 12
    readonly property real cornerL: 16
    readonly property real cornerXL: 28
    readonly property real cornerXXL: 40

    // ---- motion (Material 3 Expressive) -----------------------------------
    property real speed: 1.0
    function ms(v) { return Math.round(v / Math.max(0.1, speed)) }
    readonly property int durShort: ms(150)
    readonly property int durMedium: ms(350)
    readonly property int durLong: ms(550)
    readonly property int durXLong: ms(850)
    // emphasized decelerate / accelerate, plus a springy "spatial" curve
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15, 1, 1]
    readonly property var spring: [0.38, 1.21, 0.22, 1.0, 1, 1]
    readonly property var springSoft: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1, 1]
}
