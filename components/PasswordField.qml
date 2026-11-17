import QtQuick

// Pill password field. Each typed character pops in as a little Material shape
// (circle, rounded square, diamond, pill) instead of a plain bullet.
FocusScope {
    id: root

    property alias text: input.text
    property bool error: false
    property bool busy: false
    property bool reveal: false
    property string placeholder: qsTr("Password")

    signal accepted()
    signal dismissed()
    signal prevUser()
    signal nextUser()

    implicitHeight: 64
    implicitWidth: 360

    function clear() { input.text = "" }
    function insert(t) { input.insert(input.cursorPosition, t) }
    function shake() { shakeAnim.restart() }
    function focusInput() { input.forceActiveFocus() }

    property real _shakeX: 0
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "_shakeX"; to: -18; duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: 16; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: -12; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: 8; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: 0; duration: 260; easing.type: Easing.OutElastic }
    }
    transform: Translate { x: root._shakeX }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: root.error ? Theme.alpha(Theme.errorContainer, 0.9) : Theme.alpha(Theme.surfaceContainerHighest, 0.9)
        border.width: input.activeFocus ? 2 : 0
        border.color: root.error ? Theme.error : Theme.primary
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
        Behavior on border.width { NumberAnimation { duration: Theme.durShort } }
    }

    Icon {
        id: lock
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        name: root.error ? "error" : (input.length ? "lock_open" : "lock")
        fill: input.activeFocus ? 1 : 0
        size: 24
        color: root.error ? Theme.fgErrorContainer : Theme.fgSurfaceVariant
    }

    Item {
        id: area
        anchors.left: lock.right
        anchors.leftMargin: 14
        anchors.right: eye.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        TextInput {
            id: input
            anchors.fill: parent
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            passwordCharacter: "•"
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorVisible: false
            cursorDelegate: Item {}
            focus: true
            font.pixelSize: 20
            onTextChanged: root._syncDots()
            Keys.onReturnPressed: root.accepted()
            Keys.onEnterPressed: root.accepted()
            Keys.onEscapePressed: root.dismissed()
            Keys.onUpPressed: root.prevUser()
            Keys.onDownPressed: root.nextUser()
            Keys.onTabPressed: function(ev) { ev.accepted = false }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: root.error ? Theme.fgErrorContainer : Theme.fgSurfaceVariant
            font.family: Theme.sans
            font.pixelSize: 17
            opacity: input.length === 0 ? 0.85 : 0
            x: input.length === 0 ? 0 : 20
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
            Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        }

        // revealed text
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: implicitWidth > parent.width ? parent.right : undefined
            visible: root.reveal
            text: input.text
            color: Theme.fgSurface
            font.family: Theme.mono
            font.pixelSize: 19
        }

        // shape dots
        ListView {
            id: dots
            visible: !root.reveal
            anchors.verticalCenter: parent.verticalCenter
            height: 22
            width: parent.width
            orientation: ListView.Horizontal
            spacing: 8
            interactive: false
            model: ListModel { id: dotModel }
            onCountChanged: positionViewAtEnd()
            delegate: Rectangle {
                required property int kind
                width: kind === 3 ? 26 : 18
                height: 18
                y: (dots.height - height) / 2
                radius: kind === 0 ? 9 : kind === 3 ? 9 : 5
                rotation: kind === 2 ? 45 : 0
                scale: kind === 2 ? 0.8 : 1
                color: root.error ? Theme.fgErrorContainer
                     : kind % 2 ? Theme.primary : Theme.tertiary
                Behavior on color { ColorAnimation { duration: Theme.durMedium } }
            }
            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "scale"; from: 0; duration: Theme.durLong; easing.type: Easing.OutBack; easing.overshoot: 3 }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durShort }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "scale"; to: 0; duration: Theme.durShort * 1.3; easing.type: Easing.InBack }
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort * 1.3 }
                }
            }
            displaced: Transition { NumberAnimation { properties: "x"; duration: Theme.durMedium; easing.type: Easing.OutCubic } }
        }
    }

    function _syncDots() {
        var n = input.length
        if (n === 0 && dotModel.count > 6) { dotModel.clear(); return }
        while (dotModel.count < n) dotModel.append({ kind: Math.floor(Math.random() * 4) })
        while (dotModel.count > n) dotModel.remove(dotModel.count - 1)
    }

    IconButton {
        id: eye
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        size: 48
        iconSize: 22
        bg: "transparent"
        fg: root.error ? Theme.fgErrorContainer : Theme.fgSurfaceVariant
        icon: root.reveal ? "visibility_off" : "visibility"
        activeFocusOnTab: false
        onClicked: { root.reveal = !root.reveal; input.forceActiveFocus() }
    }
}
