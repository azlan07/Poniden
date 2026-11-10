pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: eyes
    width: 36
    height: 24
    property real opening: 1
    property real gaze: 0
    property real wink: 1
    readonly property bool moving: visible && PoniTheme.motionEnabled

    onMovingChanged: {
        if (!moving) {
            gaze = 0
            opening = 1
            wink = 1
        }
    }

    Repeater {
        model: 2
        delegate: Item {
            required property int index
            x: index * 16 + eyes.gaze
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

    SequentialAnimation {
        running: eyes.moving
        loops: Animation.Infinite

        PauseAnimation { duration: 2350 }
        NumberAnimation { target: eyes; property: "gaze"; to: -4; duration: 180; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 340 }
        NumberAnimation { target: eyes; property: "gaze"; to: 4; duration: 240; easing.type: Easing.InOutCubic }
        PauseAnimation { duration: 330 }
        NumberAnimation { target: eyes; property: "gaze"; to: 0; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: eyes; property: "wink"; to: 0.12; duration: 75 }
        PauseAnimation { duration: 110 }
        NumberAnimation { target: eyes; property: "wink"; to: 1; duration: 125 }
        PauseAnimation { duration: 180 }
        NumberAnimation { target: eyes; property: "opening"; to: 0.14; duration: 65 }
        PauseAnimation { duration: 40 }
        NumberAnimation { target: eyes; property: "opening"; to: 1; duration: 110 }
    }
}
