pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls.impl
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
            Layout.preferredHeight: 31
            Accessible.name: "Kota"
            model: page.activity.cities
            currentIndex: Math.max(0, page.activity.cities.indexOf(page.activity.city))
            onActivated: page.service.setPrayer(currentText, alerts.checked)
        }
        CheckBox {
            id: alerts
            Layout.preferredHeight: 31
            text: "Pengingat azan"
            checked: page.activity.prayerAlerts
            onToggled: page.service.setPrayer(page.activity.city, checked)
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 58
        color: PoniTheme.lilac
        border.width: PoniTheme.buttonBorder
        border.color: PoniTheme.ink

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            ColumnLayout {
                spacing: 2
                Text { text: "BERIKUTNYA"; color: PoniTheme.muted; font.bold: true; font.pixelSize: 10 }
                Text {
                    text: page.activity.nextPrayer
                    color: PoniTheme.ink
                    font.bold: true
                    font.pixelSize: 19
                }
            }
            Item { Layout.fillWidth: true }
            ColorImage {
                objectName: "mosqueSketch"
                Layout.preferredWidth: 126
                Layout.preferredHeight: 46
                source: "art/mosque.svg"
                sourceSize: Qt.size(144, 52)
                fillMode: Image.PreserveAspectFit
                color: PoniTheme.ink
                Accessible.ignored: true
            }
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
                Layout.preferredHeight: 51
                border.width: 2
                border.color: PoniTheme.ink
                color: page.activity.nextPrayer === modelData.name ? PoniTheme.lime : PoniTheme.light
                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.modelData.name; color: PoniTheme.muted }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.modelData.time; color: PoniTheme.ink; font.bold: true }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text { text: "Perkiraan lokal"; color: PoniTheme.muted; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: "Volume azan"; color: PoniTheme.muted; font.pixelSize: 12 }
        PoniSpin {
            objectName: "prayerVolume"
            Layout.preferredWidth: 82
            from: 0; to: 100; stepSize: 5
            value: page.activity.prayerVolume
            Accessible.name: "Volume azan dalam persen"
            onValueModified: page.service.setAlertVolume("prayer", value)
        }
        Text { text: "%"; color: PoniTheme.muted; font.pixelSize: 12 }
    }
}
