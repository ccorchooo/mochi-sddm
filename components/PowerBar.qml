import QtQuick

// Bottom-right cluster: session picker chip + sleep / hibernate / restart / power off.
Item {
    id: bar
    property var sessions: []
    property int sessionIndex: 0
    property alias menuOpen: menu.open
    signal sessionPicked(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10

        Chip {
            id: sessionChip
            visible: bar.sessions.length > 0
            anchors.verticalCenter: parent.verticalCenter
            h: 56
            icon: "desktop_windows"
            text: bar.sessions[bar.sessionIndex] || ""
            trailingIcon: menu.open ? "expand_more" : "expand_less"
            onClicked: menu.open = !menu.open
        }

        Item { width: 6; height: 1 }

        IconButton {
            icon: "bedtime"; tooltip: qsTr("Sleep")
            onClicked: sddm.suspend()
        }
        IconButton {
            visible: sddm.canHibernate
            icon: "mode_standby"; tooltip: qsTr("Hibernate")
            onClicked: sddm.hibernate()
        }
        IconButton {
            icon: "restart_alt"; tooltip: qsTr("Restart")
            onClicked: sddm.reboot()
        }
        IconButton {
            icon: "power_settings_new"; tooltip: qsTr("Shut down")
            bg: Theme.alpha(Theme.errorContainer, 0.9); fg: Theme.fgErrorContainer
            onClicked: sddm.powerOff()
        }
    }

    SessionMenu {
        id: menu
        x: row.x + sessionChip.x
        y: row.y - height - 12
        sessions: bar.sessions
        currentIndex: bar.sessionIndex
        onPicked: function(i) { bar.sessionPicked(i); menu.open = false }
    }
}
