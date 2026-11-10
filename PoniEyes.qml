pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: eyes
    property bool showEyes: true
    property bool playingAudio: false
    width: (showEyes ? 58 : 0) + (playingAudio ? (showEyes ? 32 : 18) : 0)
    height: 24
    property real opening: 1
    property real gaze: 0
    property real wink: 1
    readonly property bool moving: showEyes && visible && PoniTheme.motionEnabled

    property var remainingMoves: []
    property int lastMove: -1

    function waitForNextMove() {
        if (moving) {
            delay.interval = 2100 + Math.floor(Math.random() * 2101)
            delay.restart()
        }
    }

    onMovingChanged: {
        if (moving) {
            waitForNextMove()
        } else {
            delay.stop()
            glance.stop()
            blinkTwice.stop()
            winkOnce.stop()
            gaze = 0
            opening = 1
            wink = 1
        }
    }

    Repeater {
        model: eyes.showEyes ? 2 : 0
        delegate: Item {
            required property int index
            x: 11 + index * 16 + eyes.gaze
            width: 20
            height: 24
            transform: Scale {
                origin.x: 10
                origin.y: 12
                yScale: index === 1 ? Math.min(eyes.opening, eyes.wink) : eyes.opening
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: 10
                        centerY: 12
                        focalX: 10
                        focalY: 12
                        centerRadius: 10
                        GradientStop { position: 0.2; color: "#b075caff" }
                        GradientStop { position: 1; color: "#0075caff" }
                    }
                    PathRectangle { width: 20; height: 24 }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 12
                radius: width / 2
                color: "#f4fbff"
                antialiasing: true
            }
        }
    }

    Shape {
        objectName: "catWhiskers"
        visible: eyes.showEyes
        width: 58
        height: 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: PoniTheme.idleAccent
            strokeWidth: 1.2
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathSvg { path: "M 3 14 L 12 16 M 2 19 L 12 19 M 5 23 L 13 21 M 46 16 L 55 14 M 46 19 L 56 19 M 45 21 L 53 23" }
        }
    }

    Row {
        id: bars
        objectName: "audioIndicator"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: eyes.playingAudio
        height: 15
        spacing: 3
        property int beat: 0

        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: [5, 10, 15][(index + bars.beat) % 3]
                radius: 1.5
                color: PoniTheme.idleAccent
            }
        }
        Timer {
            running: bars.visible && PoniTheme.motionEnabled
            repeat: true
            interval: 240
            onTriggered: bars.beat = (bars.beat + 1) % 3
        }
    }

    Timer {
        id: delay
        onTriggered: {
            if (eyes.remainingMoves.length === 0) {
                eyes.remainingMoves = [0, 1, 2, 3]
                if (eyes.lastMove >= 0) {
                    eyes.remainingMoves.splice(eyes.lastMove, 1)
                    eyes.remainingMoves.push(eyes.lastMove)
                }
            }
            // On the first draw of a new round, skip the action that just ran.
            const count = eyes.remainingMoves.length
            const choices = count === 4 && eyes.lastMove >= 0 ? 3 : count
            const pick = Math.floor(Math.random() * choices)
            const action = eyes.remainingMoves.splice(pick, 1)[0]
            eyes.lastMove = action

            if (action < 2) {
                lookOut.to = action === 0 ? -4 : 4
                glance.start()
            } else if (action === 2) {
                blinkTwice.start()
            } else {
                winkOnce.start()
            }
        }
    }

    SequentialAnimation {
        id: glance
        onFinished: eyes.waitForNextMove()
        NumberAnimation {
            id: lookOut
            target: eyes
            property: "gaze"
            duration: 180
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: 460 }
        NumberAnimation { target: eyes; property: "gaze"; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: blinkTwice
        loops: 2
        onFinished: eyes.waitForNextMove()
        NumberAnimation { target: eyes; property: "opening"; to: 0.14; duration: 65 }
        PauseAnimation { duration: 40 }
        NumberAnimation { target: eyes; property: "opening"; to: 1; duration: 105 }
        PauseAnimation { duration: 105 }
    }

    SequentialAnimation {
        id: winkOnce
        onFinished: eyes.waitForNextMove()
        NumberAnimation { target: eyes; property: "wink"; to: 0.12; duration: 75 }
        PauseAnimation { duration: 135 }
        NumberAnimation { target: eyes; property: "wink"; to: 1; duration: 125 }
    }
}
