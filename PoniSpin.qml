import QtQuick
import QtQuick.Controls.Basic

SpinBox {
    id: spin
    editable: true
    leftPadding: 23
    rightPadding: 23
    implicitHeight: 34
    font.pixelSize: 11
    palette.text: PoniTheme.ink
    palette.highlight: PoniTheme.lime
    palette.highlightedText: PoniTheme.ink

    background: Rectangle {
        color: spin.activeFocus ? PoniTheme.lime : PoniTheme.light
        border.color: PoniTheme.ink
        border.width: 2
    }

    up.indicator: Rectangle {
        x: spin.width - width - 2
        y: 2
        width: 20
        height: spin.height - 4
        color: spin.up.pressed ? PoniTheme.lime : PoniTheme.lilac
        Text {
            anchors.centerIn: parent
            text: "+"
            color: spin.enabled && spin.value < spin.to ? PoniTheme.ink : PoniTheme.muted
        }
    }

    down.indicator: Rectangle {
        x: 2
        y: 2
        width: 20
        height: spin.height - 4
        color: spin.down.pressed ? PoniTheme.lime : PoniTheme.lilac
        Text {
            anchors.centerIn: parent
            text: "−"
            color: spin.enabled && spin.value > spin.from ? PoniTheme.ink : PoniTheme.muted
        }
    }
}
