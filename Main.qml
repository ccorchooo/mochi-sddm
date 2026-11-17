import QtQuick
import QtQuick.Effects
import "components"
import "components/Colors.js" as Colors

// mochi — a soft, rounded, Material You lock/login screen for SDDM (Qt 6).
Item {
    id: root
    width: 1920
    height: 1080

    // ---------------------------------------------------------------- config
    function cfg(key, fallback) {
        var v = config[key]
        return (v === undefined || v === null || String(v) === "") ? fallback : String(v)
    }
    function cfgBool(key, fallback) {
        var v = cfg(key, fallback ? "true" : "false").toLowerCase()
        return v === "true" || v === "1" || v === "yes" || v === "on"
    }
    function cfgReal(key, fallback) { var n = parseFloat(cfg(key, "")); return isNaN(n) ? fallback : n }

    readonly property string bgPath: {
        var p = cfg("background", "backgrounds/default.jpg")
        if (p.indexOf("://") > 0) return p
        return p.charAt(0) === "/" ? "file://" + p : Qt.resolvedUrl(p)
    }
    readonly property real dim: cfgReal("dimLevel", 0.28)
    readonly property real blurAmount: cfgReal("blur", 1.0)
    readonly property int idleSeconds: cfgReal("idleTimeout", 30)

    // ---------------------------------------------------------------- state
    property bool loginMode: false
    property bool ready: false
    property bool busy: false
    property bool leaving: false
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    function enterLogin(initialText) {
        idle.restart()
        if (!loginMode) {
            loginMode = true
            panel.focusPassword()
        }
        if (initialText) panel.insert(initialText)
    }
    function exitLogin() {
        if (busy) return
        loginMode = false
        powerBar.menuOpen = false
        panel.clear()
        panel.message = ""
        panel.error = false
        lockKeys.forceActiveFocus()
    }

    Component.onCompleted: {
        Theme.speed = cfgReal("animationSpeed", 1.0)
        Theme.variant = cfg("colorVariant", "tonalspot")
        Theme.mode = cfg("colorMode", "dark")
        Theme.uiFontOverride = cfg("font", "")
        var acc = cfg("accentColor", "")
        if (acc !== "") {
            var seed = Colors.seedFromColor(Qt.color(acc))
            Theme.seedHue = seed.hue; Theme.seedChroma = seed.chroma
            revealTimer.interval = 50
        }
        clock.enabledIds = cfg("clockStyles", "").split(",").map(function(s) { return s.trim() }).filter(function(s) { return s.length })
        clock.setStyleById(cfg("clockStyle", "flex"))
        lockKeys.forceActiveFocus()
    }

    // ---------------------------------------------------------------- models
    property var users: []
    property var sessions: []
    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                var ic = model.icon ? String(model.icon) : ""
                if (ic.indexOf("/.face.icon") >= 0 && ic.indexOf("/" + model.name + ".face.icon") < 0) ic = ""  // SDDM's generic default
                if (ic !== "" && ic.indexOf("://") < 0) ic = "file://" + ic
                var a = root.users.slice()
                a[index] = { name: model.name, realName: model.realName || "", icon: ic }
                root.users = a
            }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            Component.onCompleted: { var a = root.sessions.slice(); a[index] = model.name; root.sessions = a }
        }
    }

    // ---------------------------------------------------------------- color extraction
    // Sample the wallpaper on a tiny canvas and derive the Material You seed from it.
    Canvas {
        id: sampler
        width: 96; height: 54
        z: -10
        property bool done: false
        onPaint: {
            if (done || !isImageLoaded(root.bgPath)) return
            var ctx = getContext("2d")
            ctx.drawImage(root.bgPath, 0, 0, width, height)
            var img = ctx.getImageData(0, 0, width, height)
            var seed = Colors.extractSeed(img.data, width * height)
            if (root.cfg("accentColor", "") === "") {
                Theme.seedHue = seed.hue
                Theme.seedChroma = seed.chroma
            }
            done = true
            revealTimer.interval = 60
            revealTimer.restart()
        }
        onImageLoaded: requestPaint()
        Component.onCompleted: { loadImage(root.bgPath); if (isImageLoaded(root.bgPath)) requestPaint() }
    }
    // reveal once colors are known (or after a short fallback delay)
    Timer { id: revealTimer; interval: 900; running: true; onTriggered: root.ready = true }

    Rectangle { anchors.fill: parent; color: "black" }

    // ---------------------------------------------------------------- wallpaper
    Item {
        id: stage
        anchors.fill: parent
        opacity: root.ready && !root.leaving ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.leaving ? Theme.durMedium : Theme.durXLong; easing.type: Easing.OutCubic } }

        Item {
            id: wallWrap
            anchors.fill: parent
            scale: !root.ready ? 1.12 : root.leaving ? 1.2 : root.loginMode ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 1400; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

            Image {
                id: wall
                anchors.fill: parent
                source: root.bgPath
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(root.width, root.height)
                asynchronous: false
                smooth: true
                visible: false
            }
            Rectangle {
                // fallback when the wallpaper is missing: tinted gradient
                anchors.fill: parent
                visible: wall.status !== Image.Ready
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.primaryContainer }
                    GradientStop { position: 1; color: Theme.surfaceDim }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                visible: wall.status === Image.Ready
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: root.loginMode ? root.blurAmount : 0
                saturation: root.loginMode ? -0.1 : 0
                Behavior on blur { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on saturation { NumberAnimation { duration: Theme.durXLong } }
            }
        }

        // scrims for legibility
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceDim
            opacity: root.loginMode ? Math.min(0.85, root.dim + 0.22) : root.dim
            Behavior on opacity { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.OutCubic } }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.3
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.alpha(Theme.surfaceDim, 0.45) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.3
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Theme.alpha(Theme.surfaceDim, 0.5) }
            }
        }

        // click anywhere to wake
        MouseArea {
            anchors.fill: parent
            enabled: !root.loginMode
            onClicked: root.enterLogin("")
            onWheel: root.enterLogin("")
        }
        MouseArea {
            // click outside the card / menu while logging in
            anchors.fill: parent
            enabled: root.loginMode
            onClicked: { powerBar.menuOpen = false; panel.focusPassword(); idle.restart() }
        }

        // ------------------------------------------------------------ keyboard (lock state)
        Item {
            id: lockKeys
            focus: true
            Keys.onPressed: function(ev) {
                if (root.loginMode) return
                var printable = ev.text.length > 0 && ev.text.charCodeAt(0) >= 32 && ev.text !== " "
                              && !(ev.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                root.enterLogin(printable ? ev.text : "")
                ev.accepted = true
            }
        }

        // ------------------------------------------------------------ date (top-left)
        Column {
            id: dateBox
            x: 56 + (root.ready ? 0 : -60)
            y: 44
            spacing: 4
            opacity: root.ready ? 1 : 0
            Behavior on x { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
            Behavior on opacity { NumberAnimation { duration: Theme.durLong } }

            property date now: new Date()
            Timer { interval: 10000; running: true; repeat: true; onTriggered: dateBox.now = new Date() }

            Text {
                text: Qt.formatDate(dateBox.now, root.cfg("dateFormat", "dddd, MMMM d"))
                color: Theme.fgSurface
                font.family: Theme.sans
                font.pixelSize: 26
                font.variableAxes: ({ "wght": 520, "ROND": 100, "opsz": 28 })
            }
            Row {
                spacing: 6
                visible: root.cfgBool("showHostname", true) && sddm.hostName !== ""
                Icon { name: "computer"; size: 18; color: Theme.fgSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: sddm.hostName
                    color: Theme.fgSurfaceVariant
                    font.family: Theme.sans
                    font.pixelSize: 15
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ------------------------------------------------------------ clock (center)
        Clock {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            baseSize: root.height * 0.235
            use24h: root.cfg("clockFormat", "24h") !== "12h"
            interactive: !root.loginMode
            visible: opacity > 0.01

            // hidden while logging in: sinks back into the blur
            y: (root.height - height) / 2 - root.height * 0.02
            scale: !root.ready ? 0.85 : root.loginMode ? 0.86 : 1
            opacity: root.ready && !root.loginMode ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: root.loginMode ? Theme.emphasized : Theme.spring } }
            Behavior on opacity { NumberAnimation { duration: root.loginMode ? Theme.durShort * 1.5 : Theme.durLong; easing.type: Easing.OutCubic } }
            onStyleSwapped: function(name) { styleToast.show(name) }
        }

        // ------------------------------------------------------------ hint (lock state)
        Column {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56
            spacing: 10
            opacity: root.ready && !root.loginMode ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }

            property real bob: 0
            SequentialAnimation on bob {
                running: hint.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: -8; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: -8; to: 0; duration: 900; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 600 }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 52; height: 52
                radius: 18
                color: Theme.alpha(Theme.primaryContainer, 0.85)
                transform: Translate { y: hint.bob }
                Icon { anchors.centerIn: parent; name: "lock"; fill: 1; size: 24; color: Theme.fgPrimaryContainer }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Press any key to unlock")
                color: Theme.fgSurfaceVariant
                font.family: Theme.sans
                font.pixelSize: 15
                font.letterSpacing: 0.3
            }
        }

        // ------------------------------------------------------------ clock-style chip (bottom-left)
        Chip {
            id: styleChip
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 48 + (root.ready ? 0 : -60)
            anchors.bottomMargin: 48
            h: 56
            icon: "text_fields"
            text: clock.style.name
            opacity: root.ready && !root.loginMode && root.cfgBool("showStyleButton", true) ? 1 : 0
            visible: opacity > 0.01
            onClicked: { clock.nextStyle(); idle.restart() }
            Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
            Behavior on opacity { NumberAnimation { duration: Theme.durLong } }
        }

        // ------------------------------------------------------------ login (fullscreen, over the blur)
        LoginPanel {
            id: panel
            width: Math.min(1240, root.width * 0.84)
            height: Math.min(460, root.height * 0.6)
            anchors.centerIn: parent
            shown: root.loginMode
            users: root.users
            userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
            avatarShape: root.cfg("avatarShape", "cookie")
            busy: root.busy
            capsLock: keyboard.capsLock
            onSubmit: function(u, pw) {
                if (root.busy) return
                root.busy = true
                panel.message = ""
                sddm.login(u, pw, root.sessionIndex)
            }
            onDismissed: root.exitLogin()
            onPasswordChanged: idle.restart()
        }

        // ------------------------------------------------------------ power + session (bottom-right)
        PowerBar {
            id: powerBar
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 48 + (root.ready ? 0 : -60)
            anchors.bottomMargin: 48
            opacity: root.ready ? 1 : 0
            sessions: root.sessions
            sessionIndex: root.sessionIndex
            onSessionPicked: function(i) { root.sessionIndex = i; if (root.loginMode) panel.focusPassword() }
            Behavior on anchors.rightMargin { NumberAnimation { duration: Theme.durXLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
            Behavior on opacity { NumberAnimation { duration: Theme.durLong } }
        }

        // ------------------------------------------------------------ toast (style name)
        Rectangle {
            id: styleToast
            function show(t) { toastText.text = t; toastAnim.restart() }
            anchors.horizontalCenter: parent.horizontalCenter
            y: clock.y + clock.height * clock.scale + 24
            width: toastText.implicitWidth + 36
            height: 40
            radius: 20
            color: Theme.inverseSurface
            opacity: 0
            visible: opacity > 0
            Text { id: toastText; anchors.centerIn: parent; color: Theme.inverseOnSurface; font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.Medium }
            SequentialAnimation {
                id: toastAnim
                NumberAnimation { target: styleToast; property: "opacity"; to: 1; duration: Theme.durShort }
                PauseAnimation { duration: 1100 }
                NumberAnimation { target: styleToast; property: "opacity"; to: 0; duration: Theme.durMedium }
            }
        }
    }

    // ---------------------------------------------------------------- idle → back to lock
    Timer {
        id: idle
        interval: root.idleSeconds * 1000
        running: root.loginMode && root.idleSeconds > 0
        onTriggered: if (panel.password.length === 0 && !root.busy) root.exitLogin(); else restart()
    }

    // ---------------------------------------------------------------- sddm
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            panel.error = true
            panel.message = qsTr("Wrong password, try again")
            panel.clear()
            panel.shake()
            panel.focusPassword()
        }
        function onLoginSucceeded() {
            root.busy = false
            root.leaving = true
        }
    }
}
