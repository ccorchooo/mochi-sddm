import QtQuick

// Fullscreen login: user selector on the left, password + unlock on the right,
// floating directly on the blurred wallpaper (no card / window).
FocusScope {
    id: panel

    property var users: []               // [{ name, realName, icon }]
    property int userIndex: 0
    property string avatarShape: "cookie"
    property bool shown: false
    property bool busy: false
    property string message: ""
    property bool error: false
    property bool capsLock: false

    readonly property var user: users.length ? users[Math.max(0, Math.min(userIndex, users.length - 1))] : ({ name: "", realName: "", icon: "" })
    readonly property string displayName: user.realName && user.realName.length ? user.realName : user.name
    property alias password: field.text

    signal submit(string userName, string password)
    signal dismissed()

    function focusPassword() { field.focusInput() }
    function insert(t) { field.insert(t) }
    function clear() { field.clear() }
    function shake() { field.shake() }
    function selectUser(i) {
        if (users.length === 0) return
        i = (i + users.length) % users.length
        if (i === userIndex) return
        userIndex = i
        field.clear()
        panel.error = false
        panel.message = ""
        avatarPop.restart()
    }

    implicitWidth: 880
    implicitHeight: 360

    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: panel.shown ? Theme.durMedium : Theme.durShort; easing.type: Easing.OutCubic } }

    // thin divider between the two halves, grows from the middle
    Rectangle {
        anchors.horizontalCenter: left.right
        anchors.horizontalCenterOffset: 40
        anchors.verticalCenter: parent.verticalCenter
        width: 1.5
        height: parent.height * 0.62 * right._in
        radius: 1
        color: Theme.alpha(Theme.outlineVariant, 0.8)
    }

    // ---------------- left: user selector -----------------------------------
    Item {
        id: left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Math.round(parent.width * 0.4)

        property real _in: panel.shown ? 1 : 0
        Behavior on _in { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

        Column {
            id: userCol
            anchors.centerIn: parent
            anchors.verticalCenterOffset: panel.users.length > 1 ? -33 : 0
            spacing: 6
            opacity: left._in
            transform: Translate { x: (1 - left._in) * -40 }

            Item {
                width: 200; height: 200
                anchors.horizontalCenter: parent.horizontalCenter
                Avatar {
                    id: avatar
                    anchors.centerIn: parent
                    width: 184; height: 184
                    source: panel.user.icon || ""
                    label: panel.displayName
                    shape: panel.avatarShape
                    spinSpeed: panel.busy ? 2 : 1
                    morph: panel.error ? 0 : 1
                }
                SequentialAnimation {
                    id: avatarPop
                    ParallelAnimation {
                        NumberAnimation { target: avatar; property: "scale"; to: 0.7; duration: 120; easing.type: Easing.InQuad }
                        NumberAnimation { target: avatar; property: "rotation"; to: -25; duration: 120 }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: avatar; property: "scale"; to: 1; duration: Theme.durLong; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                        NumberAnimation { target: avatar; property: "rotation"; to: 0; duration: Theme.durXLong; easing.type: Easing.OutElastic; easing.period: 0.5 }
                    }
                }
            }
            Item { width: 1; height: 8 }
            Text {
                id: nameText
                anchors.horizontalCenter: parent.horizontalCenter
                width: left.width - 40
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: panel.displayName
                color: Theme.fgSurface
                font.family: Theme.sans
                font.pixelSize: 32
                font.variableAxes: ({ "wght": 560, "ROND": 100 })
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: panel.user.realName && panel.user.realName !== panel.user.name
                text: "@" + panel.user.name
                color: Theme.fgSurfaceVariant
                font.family: Theme.sans
                font.pixelSize: 15
                font.letterSpacing: 0.4
            }
        }

        // other users
        ListView {
            id: picker
            visible: panel.users.length > 1
            anchors.top: userCol.bottom
            anchors.topMargin: 22
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(panel.users.length * 52 - 8, parent.width - 40)
            height: 44
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            model: panel.users
            currentIndex: panel.userIndex
            highlightMoveDuration: Theme.durMedium
            opacity: left._in
            delegate: Item {
                id: pd
                required property int index
                required property var modelData
                readonly property bool sel: index === panel.userIndex
                width: 44; height: 44
                Rectangle {
                    anchors.fill: parent
                    radius: pd.sel ? 14 : 22
                    color: "transparent"
                    border.width: pd.sel ? 2.5 : 0
                    border.color: Theme.primary
                    Behavior on radius { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                }
                Avatar {
                    anchors.centerIn: parent
                    width: 34; height: 34
                    shape: pd.sel ? "squircle" : "circle"
                    spinning: false
                    source: pd.modelData.icon || ""
                    label: pd.modelData.realName || pd.modelData.name
                    tint: pd.sel ? Theme.primaryContainer : Theme.secondaryContainer
                    tintFg: pd.sel ? Theme.fgPrimaryContainer : Theme.fgSecondaryContainer
                    scale: pma.pressed ? 0.85 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutBack } }
                }
                MouseArea { id: pma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.selectUser(pd.index); panel.focusPassword() } }
            }
        }
    }

    // ---------------- right: password -----------------------------------------
    Item {
        id: right
        anchors.left: left.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 80
        anchors.rightMargin: 0

        property real _in: panel.shown ? 1 : 0
        Behavior on _in { SequentialAnimation {
            PauseAnimation { duration: panel.shown ? 70 : 0 }
            NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring }
        } }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 0
            opacity: right._in
            transform: Translate { x: (1 - right._in) * 50 }

            Text {
                text: {
                    var h = new Date().getHours()
                    var first = panel.displayName.split(" ")[0]
                    return (h < 5 ? qsTr("Still up") : h < 12 ? qsTr("Good morning") : h < 18 ? qsTr("Good afternoon") : qsTr("Good evening")) + ", " + first
                }
                width: parent.width
                elide: Text.ElideRight
                color: Theme.fgSurface
                font.family: Theme.sans
                font.pixelSize: 44
                font.variableAxes: ({ "wght": 480, "ROND": 100, "opsz": 48 })
            }
            Item { width: 1; height: 6 }
            Text {
                text: panel.busy ? qsTr("Signing in…") : qsTr("Enter your password to continue")
                color: Theme.fgSurfaceVariant
                font.family: Theme.sans
                font.pixelSize: 17
            }
            Item { width: 1; height: 32 }

            Row {
                width: Math.min(parent.width, 560)
                spacing: 12
                PasswordField {
                    id: field
                    width: parent.width - go.width - 12
                    focus: true
                    error: panel.error
                    enabled: !panel.busy
                    onAccepted: panel.submit(panel.user.name, field.text)
                    onDismissed: panel.dismissed()
                    onPrevUser: panel.selectUser(panel.userIndex - 1)
                    onNextUser: panel.selectUser(panel.userIndex + 1)
                    onTextChanged: if (text.length) { panel.error = false; panel.message = "" }
                }
                IconButton {
                    id: go
                    size: 64
                    filled: true
                    iconSize: 28
                    icon: "arrow_forward"
                    busy: panel.busy
                    tooltip: qsTr("Unlock")
                    activeFocusOnTab: false
                    onClicked: panel.submit(panel.user.name, field.text)
                }
            }

            Item { width: 1; height: 16 }

            // status line: error / caps lock
            Item {
                width: parent.width
                height: 32
                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        id: errChip
                        visible: opacity > 0
                        opacity: panel.message !== "" ? 1 : 0
                        scale: panel.message !== "" ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
                        Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutBack } }
                        height: 32
                        width: errRow.implicitWidth + 24
                        radius: 16
                        color: Theme.errorContainer
                        Row { id: errRow; anchors.centerIn: parent; spacing: 6
                            Icon { name: "error"; size: 18; fill: 1; color: Theme.fgErrorContainer; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: panel.message; color: Theme.fgErrorContainer; font.family: Theme.sans; font.pixelSize: 13; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    Rectangle {
                        visible: opacity > 0
                        opacity: panel.capsLock ? 1 : 0
                        scale: panel.capsLock ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
                        Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutBack } }
                        height: 32
                        width: capsRow.implicitWidth + 24
                        radius: 10
                        color: Theme.tertiaryContainer
                        Row { id: capsRow; anchors.centerIn: parent; spacing: 6
                            Icon { name: "keyboard_capslock"; size: 18; color: Theme.fgTertiaryContainer; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: qsTr("Caps Lock is on"); color: Theme.fgTertiaryContainer; font.family: Theme.sans; font.pixelSize: 13; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }
    }
}
