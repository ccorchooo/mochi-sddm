import QtQuick

// Big center clock with switchable type styles. Click it to cycle styles.
Item {
    id: clock

    // Every style: font family key, layout, size, variable-font axes, digit motion and color roles.
    readonly property var allStyles: [
        { id: "flex",    name: "Flex",    family: "sans",    stacked: true,  size: 1.00, axes: { wght: 640, ROND: 100, opsz: 144, wdth: 100 }, motion: "slide",  hc: "primary",  mc: "onSurface", tracking: -0.04 },
        { id: "squishy", name: "Squishy", family: "rounded", stacked: true,  size: 0.98, axes: { wght: 620, wdth: 115 },                        motion: "squish", hc: "primary",  mc: "tertiary",  tracking: -0.02, breathe: true },
        { id: "mono",    name: "Mono",    family: "mono",    stacked: false, size: 0.62, axes: { wght: 300 },                                   motion: "roll",   hc: "onSurface", mc: "primary",  tracking: -0.02, blink: true },
        { id: "dots",    name: "Dots",    family: "dots",    stacked: false, size: 0.78, axes: { wght: 900, ROND: 100 },                        motion: "pop",    hc: "primary",  mc: "tertiary",  tracking: 0.02 },
        { id: "serif",   name: "Serif",   family: "serif",   stacked: true,  size: 0.92, axes: {},                                              motion: "fade",   hc: "tertiary", mc: "onSurface", tracking: -0.01 },
        { id: "thin",    name: "Thin",    family: "thin",    stacked: false, size: 0.86, axes: { wght: 120 },                                   motion: "slide",  hc: "onSurface", mc: "primary",  tracking: -0.03 },
        { id: "wide",    name: "Wide",    family: "sans",    stacked: false, size: 0.58, axes: { wght: 330, wdth: 151, ROND: 100, opsz: 144 }, motion: "slide",  hc: "primary",  mc: "onSurface", tracking: 0.0 }
    ]

    property var enabledIds: []          // empty = all
    readonly property var styles: {
        if (!enabledIds || enabledIds.length === 0) return allStyles
        var out = []
        for (var i = 0; i < enabledIds.length; i++)
            for (var j = 0; j < allStyles.length; j++)
                if (allStyles[j].id === enabledIds[i]) out.push(allStyles[j])
        return out.length ? out : allStyles
    }
    property int styleIndex: 0
    readonly property var style: styles[Math.max(0, Math.min(styleIndex, styles.length - 1))]

    property real baseSize: 240          // glyph pixel size for size 1.0
    property real weightShift: 0          // added to the wght axis (thinner when unlocking)
    property bool use24h: true
    property bool interactive: true

    signal styleSwapped(string name)

    function setStyleById(id) {
        for (var i = 0; i < styles.length; i++) if (styles[i].id === id) { styleIndex = i; return }
    }
    function nextStyle() { if (!swap.running) swap.restart() }
    function jiggle() { for (var i = 0; i < digits.length; i++) digits[i].jiggle(i * 45) }

    // ---- time -------------------------------------------------------------
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: clock.now = new Date() }
    readonly property int _h: use24h ? now.getHours() : ((now.getHours() + 11) % 12) + 1
    readonly property string hh: (_h < 10 ? (use24h ? "0" : " ") : "") + _h
    readonly property string mm: (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()
    readonly property string ampm: now.getHours() < 12 ? "AM" : "PM"

    // ---- derived look -------------------------------------------------------
    readonly property string fam: Theme.family(style.family)
    readonly property real px: baseSize * style.size
    readonly property var axes: {
        var a = {}
        for (var k in style.axes) a[k] = style.axes[k]
        if (a.wght !== undefined) a.wght = Math.max(100, Math.min(1000, a.wght + weightShift))
        return a
    }
    readonly property color hColor: Theme.role(style.hc)
    readonly property color mColor: Theme.role(style.mc)
    readonly property real gap: px * style.tracking

    readonly property var digits: [h1, h2, m1, m2, s1, s2]

    implicitWidth: content.width
    implicitHeight: content.height
    width: implicitWidth
    height: implicitHeight
    Behavior on width { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    Item {
        id: content
        anchors.centerIn: parent
        width: col.width
        height: col.height
        transformOrigin: Item.Center
        Behavior on scale { enabled: !swap.running; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

        Column {
            id: col
            spacing: clock.style.stacked ? -clock.px * 0.02 : 0

            Row {
                id: row1
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: clock.gap
                Digit { id: h1; value: clock.hh.charAt(0) === " " ? "" : clock.hh.charAt(0); visible: value !== ""
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.hColor; motion: clock.style.motion
                        breathe: !!clock.style.breathe; breatheDuration: 2100; cellFactor: clock.style.stacked ? 1.1 : 1.2 }
                Digit { id: h2; value: clock.hh.charAt(1)
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.hColor; motion: clock.style.motion
                        breathe: !!clock.style.breathe; breatheDuration: 2350; cellFactor: clock.style.stacked ? 1.1 : 1.2 }
                Text {
                    id: colon
                    visible: !clock.style.stacked
                    text: ":"
                    color: clock.mColor
                    font.family: clock.fam; font.pixelSize: clock.px; font.variableAxes: clock.axes
                    renderType: Text.QtRendering
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -clock.px * 0.06
                    opacity: clock.style.blink ? (clock.now.getSeconds() % 2 ? 0.25 : 1) : 1
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
                Digit { id: m1; visible: !clock.style.stacked; value: clock.mm.charAt(0)
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.mColor; motion: clock.style.motion; cellFactor: 1.2 }
                Digit { id: m2; visible: !clock.style.stacked; value: clock.mm.charAt(1)
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.mColor; motion: clock.style.motion; cellFactor: 1.2 }
                Text {
                    visible: !clock.use24h && !clock.style.stacked
                    text: clock.ampm
                    color: clock.mColor
                    font.family: clock.fam; font.pixelSize: clock.px * 0.2; font.variableAxes: clock.axes
                    anchors.bottom: parent.bottom; anchors.bottomMargin: clock.px * 0.2
                    leftPadding: clock.px * 0.06
                }
            }
            Row {
                id: row2
                visible: clock.style.stacked
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: clock.gap
                Digit { id: s1; value: clock.mm.charAt(0)
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.mColor; motion: clock.style.motion
                        breathe: !!clock.style.breathe; breatheDuration: 2600; cellFactor: 1.1 }
                Digit { id: s2; value: clock.mm.charAt(1)
                        family: clock.fam; pixelSize: clock.px; axes: clock.axes; color: clock.mColor; motion: clock.style.motion
                        breathe: !!clock.style.breathe; breatheDuration: 1900; cellFactor: 1.1 }
            }
            Text {
                visible: !clock.use24h && clock.style.stacked
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.ampm
                color: clock.mColor
                font.family: clock.fam; font.pixelSize: clock.px * 0.16; font.variableAxes: clock.axes
            }
        }
    }

    // swap styles: shrink + fade out, switch, spring back in
    SequentialAnimation {
        id: swap
        ParallelAnimation {
            NumberAnimation { target: content; property: "scale"; to: 0.82; duration: Theme.durShort * 1.4; easing.type: Easing.InCubic }
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: Theme.durShort * 1.4; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { clock.styleIndex = (clock.styleIndex + 1) % clock.styles.length; clock.styleSwapped(clock.style.name) } }
        ParallelAnimation {
            NumberAnimation { target: content; property: "scale"; from: 1.12; to: 1; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring }
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: Theme.durMedium; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: clock.jiggle() }
    }

    MouseArea {
        anchors.fill: parent
        enabled: clock.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: clock.nextStyle()
        onPressed: content.scale = 0.96
        onReleased: content.scale = 1
        onCanceled: content.scale = 1
    }
    Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
}
