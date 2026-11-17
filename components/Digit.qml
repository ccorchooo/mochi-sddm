import QtQuick

// One animated clock glyph. When `value` changes the old glyph leaves and the
// new one arrives using the style's motion ("slide", "squish", "roll", "pop", "fade").
Item {
    id: root

    property string value: "0"
    property string family: Theme.sans
    property real pixelSize: 200
    property var axes: ({})
    property color color: Theme.fgSurface
    property string motion: "slide"
    property bool breathe: false
    property int breatheDuration: 2200
    property real cellFactor: 1.14     // cell height relative to digit ink height
    property bool active: visible

    property string _last: ""
    property bool _ready: false

    implicitWidth: Math.max(1, cur.implicitWidth)
    implicitHeight: metrics.tightBoundingRect.height * cellFactor
    width: implicitWidth
    height: implicitHeight
    Behavior on width {
        enabled: root._ready
        NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
    }

    TextMetrics {
        id: metrics
        text: "0"
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.variableAxes: root.axes
    }

    // y that puts the digit's visual center in the middle of the cell
    readonly property real _inkCenter: metrics.tightBoundingRect.y + metrics.tightBoundingRect.height / 2

    // breathing wobble (squishy style)
    property real _breath: 0
    SequentialAnimation on _breath {
        running: root.breathe && root.active
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: root.breatheDuration; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: root.breatheDuration; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) root._breath = 0
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height
        yScale: 1 + root._breath * 0.045
        xScale: 1 - root._breath * 0.025
    }

    Text {
        id: prev
        property real ty: 0
        property real sx: 1
        property real sy: 1
        opacity: 0
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.variableAxes: root.axes
        renderType: Text.QtRendering
        x: (root.width - implicitWidth) / 2
        y: root.height / 2 - (baselineOffset + root._inkCenter) + ty
        transform: Scale { origin.x: prev.width / 2; origin.y: prev.baselineOffset; xScale: prev.sx; yScale: prev.sy }
    }

    Text {
        id: cur
        property real ty: 0
        property real sx: 1
        property real sy: 1
        text: root.value
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.variableAxes: root.axes
        renderType: Text.QtRendering
        x: (root.width - implicitWidth) / 2
        y: root.height / 2 - (baselineOffset + root._inkCenter) + ty
        transform: Scale { origin.x: cur.width / 2; origin.y: cur.baselineOffset; xScale: cur.sx; yScale: cur.sy }
    }


    onValueChanged: {
        if (!_ready) { _last = value; return }
        if (value === _last) return
        prev.text = _last
        _last = value
        anim.restart()
    }
    Component.onCompleted: { _last = value; _ready = true }

    readonly property real _d: root.height * 0.55

    SequentialAnimation {
        id: anim
        ScriptAction { script: {
            prev.opacity = 1; prev.ty = 0; prev.sx = 1; prev.sy = 1
            cur.opacity = 0; cur.sx = 1; cur.sy = 1; cur.ty = 0
        } }
        ParallelAnimation {
            // ---- outgoing ----
            NumberAnimation { target: prev; property: "opacity"; to: 0; duration: Theme.durMedium * 0.8; easing.type: Easing.OutCubic }
            NumberAnimation {
                target: prev; property: "ty"
                to: root.motion === "slide" || root.motion === "roll" ? -root._d : 0
                duration: root.motion === "roll" ? Theme.durShort * 2 : Theme.durMedium
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasizedAccel
            }
            NumberAnimation {
                target: prev; property: "sy"
                to: root.motion === "squish" ? 0.2 : root.motion === "pop" ? 0.4 : root.motion === "fade" ? 1.08 : 1
                duration: Theme.durMedium; easing.type: Easing.InBack
            }
            NumberAnimation {
                target: prev; property: "sx"
                to: root.motion === "squish" ? 1.35 : root.motion === "pop" ? 0.4 : root.motion === "fade" ? 1.08 : 1
                duration: Theme.durMedium; easing.type: Easing.InBack
            }
            // ---- incoming ----
            SequentialAnimation {
                PauseAnimation { duration: root.motion === "roll" ? 0 : Theme.durShort * 0.6 }
                ScriptAction { script: {
                    cur.ty = (root.motion === "slide" || root.motion === "roll") ? root._d : 0
                    cur.sy = root.motion === "squish" ? 0.35 : root.motion === "pop" ? 0.2 : root.motion === "fade" ? 0.92 : 1
                    cur.sx = root.motion === "squish" ? 1.3 : root.motion === "pop" ? 0.2 : root.motion === "fade" ? 0.92 : 1
                } }
                ParallelAnimation {
                    NumberAnimation { target: cur; property: "opacity"; to: 1; duration: Theme.durMedium; easing.type: Easing.OutCubic }
                    NumberAnimation {
                        target: cur; property: "ty"; to: 0
                        duration: root.motion === "roll" ? Theme.durShort * 2 : Theme.durLong
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring
                    }
                    NumberAnimation {
                        target: cur; property: "sy"; to: 1
                        duration: root.motion === "squish" ? Theme.durXLong : Theme.durLong
                        easing.type: root.motion === "squish" ? Easing.OutElastic : Easing.OutBack
                        easing.amplitude: 1.0; easing.period: 0.42; easing.overshoot: 2.2
                    }
                    NumberAnimation {
                        target: cur; property: "sx"; to: 1
                        duration: root.motion === "squish" ? Theme.durXLong : Theme.durLong
                        easing.type: root.motion === "squish" ? Easing.OutElastic : Easing.OutBack
                        easing.amplitude: 1.0; easing.period: 0.5; easing.overshoot: 2.2
                    }
                }
            }
        }
    }

    // a little jiggle on demand (used when the clock is tapped)
    function jiggle(delay) { jig.delay = delay; jig.restart() }
    SequentialAnimation {
        id: jig
        property int delay: 0
        PauseAnimation { duration: jig.delay }
        NumberAnimation { target: cur; property: "sy"; to: 0.78; duration: 110; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: cur; property: "sy"; to: 1; duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.35 }
            SequentialAnimation {
                NumberAnimation { target: cur; property: "sx"; to: 1.12; duration: 110 }
                NumberAnimation { target: cur; property: "sx"; to: 1; duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.35 }
            }
        }
    }
}
