import QtQuick

// Assist chip: pill with leading icon + label (+ optional trailing icon).
Item {
    id: root
    property string icon: ""
    property string text: ""
    property string trailingIcon: ""
    property color bg: Theme.alpha(Theme.surfaceContainerHigh, 0.82)
    property color fg: Theme.fgSurface
    property real h: 48
    property bool interactive: true
    readonly property bool hovered: ma.containsMouse
    signal clicked()

    implicitHeight: h
    implicitWidth: row.implicitWidth + 32
    Behavior on implicitWidth { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    Rectangle {
        anchors.fill: parent
        radius: root.hovered && !ma.pressed ? height * 0.32 : height / 2
        color: root.bg
        scale: ma.pressed ? 0.95 : 1
        Behavior on radius { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: root.fg; opacity: root.hovered ? 0.08 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.durShort } } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon { visible: root.icon !== ""; name: root.icon; size: 20; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: root.text
            color: root.fg
            font.family: Theme.sans
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Icon { visible: root.trailingIcon !== ""; name: root.trailingIcon; size: 20; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
