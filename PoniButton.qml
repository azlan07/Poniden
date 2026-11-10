import QtQuick
import QtQuick.Controls.Basic

Button {
    id: button
    implicitHeight: 31
    implicitWidth: Math.max(34, contentItem.implicitWidth + 18)
    leftPadding: 7
    rightPadding: 10
    bottomPadding: 5
    font.pixelSize: 12
    font.weight: Font.DemiBold

    contentItem: Text {
        text: button.text
        font: button.font
        color: button.enabled ? PoniTheme.ink : PoniTheme.muted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        transform: Translate { x: face.x; y: face.y }
    }
    background: Item {
        Rectangle {
            x: 2; y: 2
            width: parent.width - 2
            height: parent.height - 2
            color: PoniTheme.ink
        }
        Rectangle {
            id: face
            x: button.down ? 2 : 0
            y: button.down ? 2 : button.hovered && button.enabled ? -1 : 0
            width: parent.width - 2
            height: parent.height - 2
            color: !button.enabled ? PoniTheme.edge : button.checked || button.highlighted
                ? PoniTheme.lime : button.hovered ? PoniTheme.lilac : PoniTheme.light
            border.width: button.visualFocus ? 3 : 2
            border.color: PoniTheme.ink
            Behavior on x { enabled: PoniTheme.motionEnabled; NumberAnimation { duration: 90 } }
            Behavior on y { enabled: PoniTheme.motionEnabled; NumberAnimation { duration: 90 } }
        }
    }
}
