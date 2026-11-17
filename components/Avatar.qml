import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

// Profile picture masked into a Material 3 Expressive shape.
// shape: "cookie" (scalloped, slowly rotating), "circle", "squircle", "flower".
Item {
    id: root

    property url source: ""
    property string label: "?"
    property string shape: "cookie"
    property bool spinning: true
    property real spinSpeed: 1           // >1 while authenticating
    property real morph: 1               // 0 = circle, 1 = full shape
    property color tint: Theme.primaryContainer
    property color tintFg: Theme.fgPrimaryContainer

    implicitWidth: 128
    implicitHeight: 128

    readonly property bool hasImage: img.status === Image.Ready
    readonly property int lobes: shape === "flower" ? 8 : 9
    readonly property real amp: (shape === "flower" ? 0.09 : shape === "cookie" ? 0.055 : 0) * morph

    Behavior on morph { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    // ---- content (image or initial) -----------------------------------------
    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; color: root.tint }
        Text {
            anchors.centerIn: parent
            visible: !root.hasImage
            text: root.label.length ? root.label.charAt(0).toUpperCase() : "?"
            color: root.tintFg
            font.family: Theme.rounded
            font.pixelSize: root.height * 0.46
            font.variableAxes: ({ "wght": 600, "ROND": 100 })
        }
        Image {
            id: img
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.width * 2, root.height * 2)
            asynchronous: true
            smooth: true
            mipmap: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
        }
    }

    // ---- mask ----------------------------------------------------------------
    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        Rectangle {
            anchors.fill: parent
            visible: root.shape === "squircle"
            radius: width * (0.5 - 0.22 * root.morph)
            color: "white"
        }
        Shape {
            id: blob
            anchors.fill: parent
            visible: root.shape !== "squircle"
            preferredRendererType: Shape.CurveRenderer
            rotation: root._angle
            ShapePath {
                strokeWidth: -1
                fillColor: "white"
                PathPolyline { path: root._points }
            }
        }
    }

    property real _angle: 0
    NumberAnimation on _angle {
        running: root.spinning && root.shape !== "squircle" && root.amp > 0
        from: 0; to: 360
        loops: Animation.Infinite
        duration: 40000
    }
    // extra spin while authenticating
    property real _boost: 0
    NumberAnimation on _boost {
        running: root.spinSpeed > 1
        from: 0; to: 360; loops: Animation.Infinite; duration: 1100
    }
    onSpinSpeedChanged: if (spinSpeed <= 1) boostReset.restart()
    NumberAnimation { id: boostReset; target: root; property: "_boost"; to: Math.ceil(root._boost / 40) * 40; duration: 500; easing.type: Easing.OutBack }

    readonly property var _points: {
        var pts = [], n = 160
        var R = Math.min(width, height) / 2, cx = width / 2, cy = height / 2
        var rot = (_boost) * Math.PI / 180
        for (var i = 0; i <= n; i++) {
            var t = i / n * Math.PI * 2
            var r = R * (1 - amp + amp * Math.cos(lobes * (t + rot)))
            pts.push(Qt.point(cx + r * Math.cos(t), cy + r * Math.sin(t)))
        }
        return pts
    }

    MultiEffect {
        anchors.fill: parent
        source: content
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.6
    }
}
