pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property var activity
    required property string remaining
    readonly property color phaseColor: [PoniTheme.ink, "#43641e", "#43518c"][activity.phaseIndex]
    spacing: 5

    RowLayout {
        Layout.fillWidth: true
        Text { text: page.activity.phase; color: PoniTheme.ink; font.pixelSize: 17; font.bold: true }
        Item { Layout.fillWidth: true }
        Repeater {
            model: 4
            Rectangle {
                required property int index
                width: 9; height: 9; radius: 5
                color: index < page.activity.completedRounds ? PoniTheme.lime : PoniTheme.edge
                border.color: PoniTheme.ink
            }
        }
        Text { text: page.activity.sessionsToday + " sesi hari ini"; color: PoniTheme.muted }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: page.remaining
        color: page.phaseColor
        font.pixelSize: 36
        font.family: "monospace"
    }

    PoniProgress {
        Layout.fillWidth: true
        to: page.activity.focusTotal
        value: to - page.activity.remaining
    }

    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["Fokus", "Jeda pendek", "Jeda panjang"]
            PoniButton {
                required property int index
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                highlighted: page.activity.phaseIndex === index
                onClicked: { if (!highlighted) page.service.selectPhase(index) }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        PoniButton {
            text: page.activity.running ? "Ⅱ Jeda" : "▶ Mulai"
            onClicked: page.service.focusAction("toggle")
        }
        PoniButton { text: "↻ Ulangi"; onClicked: page.service.focusAction("reset") }
        PoniButton { text: "» Lewati"; onClicked: page.service.focusAction("skip") }
        Item { Layout.fillWidth: true }
        Text { text: "Menit fokus / jeda"; color: PoniTheme.muted; font.pixelSize: 11 }
        PoniSpin {
            id: focusMinutes
            Layout.preferredWidth: 70
            from: 1; to: 120; value: page.activity.focusMinutes
            enabled: !page.activity.running
            Accessible.name: "Menit fokus"
            onValueModified: page.service.setFocus(value, rest.value)
        }
        PoniSpin {
            id: rest
            Layout.preferredWidth: 70
            from: 1; to: 60; value: page.activity.breakMinutes
            enabled: !page.activity.running
            Accessible.name: "Menit istirahat"
            onValueModified: page.service.setFocus(focusMinutes.value, value)
        }
    }
}
