import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls.impl

Button {
    id: button
    implicitHeight: 31
    implicitWidth: Math.max(34, contentItem.implicitWidth + 18)
    leftPadding: 7
    rightPadding: 10
    bottomPadding: 5
    font.pixelSize: 12
    font.weight: Font.DemiBold

    contentItem: Item {
        implicitWidth: button.icon.source.toString() ? 19 : caption.implicitWidth
        implicitHeight: Math.max(19, caption.implicitHeight)
        transform: Translate { x: face.x; y: face.y }

        ColorImage {
            anchors.centerIn: parent
            source: button.icon.source
            visible: source.toString() !== ""
            color: button.enabled ? PoniTheme.ink : PoniTheme.muted
            sourceSize: Qt.size(19, 19)
        }
        Text {
            id: caption
            anchors.fill: parent
            visible: button.icon.source.toString() === ""
            text: button.text
            font: button.font
            color: button.enabled ? PoniTheme.ink : PoniTheme.muted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
    background: Item {
        Rectangle {
            x: PoniTheme.buttonOffset; y: PoniTheme.buttonOffset
            width: parent.width - PoniTheme.buttonOffset
            height: parent.height - PoniTheme.buttonOffset
            color: PoniTheme.shadow
        }
        Rectangle {
            id: face
            x: button.down ? PoniTheme.buttonOffset : 0
            y: button.down ? PoniTheme.buttonOffset : button.hovered && button.enabled ? -1 : 0
            width: parent.width - PoniTheme.buttonOffset
            height: parent.height - PoniTheme.buttonOffset
            color: !button.enabled ? PoniTheme.edge : button.checked || button.highlighted
                ? PoniTheme.lime : button.hovered ? PoniTheme.lilac : PoniTheme.light
            border.width: button.visualFocus ? PoniTheme.buttonBorder + 1 : PoniTheme.buttonBorder
            border.color: PoniTheme.ink
            Behavior on x { enabled: PoniTheme.motionEnabled; NumberAnimation { duration: 90 } }
            Behavior on y { enabled: PoniTheme.motionEnabled; NumberAnimation { duration: 90 } }
        }
    }
}
