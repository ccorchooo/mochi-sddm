import QtQuick

// Material Symbols Rounded glyph (ligature name, e.g. "power_settings_new").
Text {
    id: icon
    property string name: ""
    property real size: 24
    property real fill: 0
    property real weight: 500

    text: name
    color: Theme.fgSurface
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight, "GRAD": 0, "opsz": Math.max(20, Math.min(48, size)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering

    Behavior on fill { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.durShort } }
}
