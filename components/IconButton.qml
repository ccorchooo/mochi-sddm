import QtQuick

// Expressive icon button: round at rest, morphs to a rounded square on hover,
// squishes wider when pressed. Optional tooltip label above it.
Item {
    id: root

    property string icon: ""
    property string tooltip: ""
    property real size: 56
    property bool filled: false              // filled = primary, else tonal
    property color bg: filled ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, 0.82)
    property color fg: filled ? Theme.fgPrimary : Theme.fgSurface
    property real iconSize: size * 0.43
    property bool busy: false
    readonly property bool hovered: ma.containsMouse
    readonly property bool pressed: ma.pressed

    signal clicked()

    implicitWidth: size * (pressed ? 1.28 : 1)
    implicitHeight: size
    width: implicitWidth
    height: implicitHeight
    Behavior on implicitWidth { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        id: shapeBg
        anchors.fill: parent
        radius: (root.hovered || root.activeFocus) && !root.pressed ? root.height * 0.32 : root.height / 2
        color: root.bg
        Behavior on radius { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.primary

        // state layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.fg
            opacity: root.pressed ? 0.16 : root.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        name: root.busy ? "progress_activity" : root.icon
        size: root.iconSize
        color: root.fg
        fill: root.hovered ? 1 : 0
        rotation: 0
        RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        onNameChanged: if (!root.busy) rotation = 0
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // tooltip
    Rectangle {
        visible: root.tooltip !== "" && opacity > 0
        opacity: root.hovered && !root.pressed ? 1 : 0
        scale: root.hovered ? 1 : 0.8
        anchors.bottom: parent.top
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: tipText.implicitWidth + 24
        height: 32
        radius: 16
        color: Theme.inverseSurface
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.tooltip
            color: Theme.inverseOnSurface
            font.family: Theme.sans
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}
