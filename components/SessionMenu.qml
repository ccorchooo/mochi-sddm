import QtQuick

// Rounded menu listing desktop sessions; grows from its bottom-right corner.
Rectangle {
    id: menu
    property var sessions: []
    property int currentIndex: 0
    property bool open: false
    signal picked(int index)

    width: 280
    height: Math.min(sessions.length * 50 + 14, 360)
    radius: Theme.cornerXL
    color: Theme.surfaceContainer
    transformOrigin: Item.BottomLeft
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.6
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Theme.durShort * 1.5; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        model: menu.sessions
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: item
            required property int index
            required property var modelData
            readonly property bool sel: index === menu.currentIndex
            width: list.width
            height: 48
            Rectangle {
                anchors.fill: parent
                radius: item.sel ? Theme.cornerL : height / 2
                color: item.sel ? Theme.secondaryContainer : (ma.containsMouse ? Theme.alpha(Theme.fgSurface, 0.08) : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                Behavior on radius { NumberAnimation { duration: Theme.durMedium } }
            }
            Icon {
                id: check
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                name: item.sel ? "check" : "desktop_windows"
                size: 20
                color: item.sel ? Theme.fgSecondaryContainer : Theme.fgSurfaceVariant
            }
            Text {
                id: label
                anchors.left: check.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData
                width: item.width - x - 16
                elide: Text.ElideRight
                color: item.sel ? Theme.fgSecondaryContainer : Theme.fgSurface
                font.family: Theme.sans
                font.pixelSize: 15
                font.weight: item.sel ? Font.DemiBold : Font.Normal
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: menu.picked(item.index)
            }
        }
    }
}
