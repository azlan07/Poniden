import QtQuick
import QtQuick.Controls.Basic

ProgressBar {
    id: bar
    implicitHeight: 6
    background: Rectangle {
        implicitHeight: 6
        radius: 3
        color: PoniTheme.edge
    }
    contentItem: Item {
        Rectangle {
            width: parent.width * bar.visualPosition
            height: parent.height
            x: bar.mirrored ? parent.width - width : 0
            radius: 3
            color: PoniTheme.ink
        }
    }
}
