pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property var activity
    spacing: 7

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Jadwal salat"; color: PoniTheme.ink; font.pixelSize: 17; font.bold: true }
        Item { Layout.fillWidth: true }
        ComboBox {
            Layout.preferredWidth: 128
            Accessible.name: "Kota"
            model: page.activity.cities
            currentIndex: Math.max(0, page.activity.cities.indexOf(page.activity.city))
            onActivated: page.service.setPrayer(currentText, alerts.checked)
        }
        CheckBox {
            id: alerts
            text: "Pengingat azan"
            checked: page.activity.prayerAlerts
            onToggled: page.service.setPrayer(page.activity.city, checked)
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: page.activity.prayers
            Rectangle {
                id: card
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                border.width: 2
                border.color: PoniTheme.ink
                color: page.activity.nextPrayer === modelData.name ? PoniTheme.lime : PoniTheme.lilac
                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.modelData.name; color: PoniTheme.muted }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.modelData.time; color: PoniTheme.ink; font.bold: true }
                }
            }
        }
    }
    Text {
        text: "Berikutnya: " + page.activity.nextPrayer + "  ·  Perkiraan lokal"
        color: PoniTheme.muted
        font.pixelSize: 11
    }
}
