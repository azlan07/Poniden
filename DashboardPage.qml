pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls.impl
import QtQuick.Layouts

ColumnLayout {
    id: home
    required property QtObject dashboard
    required property QtObject metrics
    required property var activity
    required property date now
    readonly property var location: dashboard.view
    readonly property var stats: metrics.view
    spacing: 9

    Component.onCompleted: {
        dashboard.open(activity.city)
        metrics.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: home.visible
        onTriggered: home.dashboard.refresh()
    }

    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                text: home.now.toLocaleString(Qt.locale("id_ID"), "dddd")
                color: PoniTheme.ink
                font.pixelSize: 29
                font.bold: true
                Accessible.role: Accessible.Heading
            }
            Text {
                text: home.now.toLocaleString(Qt.locale("id_ID"), "d MMMM yyyy")
                color: PoniTheme.muted
                font.pixelSize: 13
            }
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            Layout.preferredWidth: battery.implicitWidth + 22
            Layout.preferredHeight: 31
            color: PoniTheme.lime
            border.color: PoniTheme.ink
            border.width: 2
            Text {
                id: battery
                anchors.centerIn: parent
                text: "BATERAI  " + (home.activity.battery || "—")
                color: PoniTheme.ink
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 9

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 240
            color: PoniTheme.lilac
            border.color: PoniTheme.ink
            border.width: PoniTheme.buttonBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    ColorImage {
                        source: "icons/cloud-sun.svg"
                        sourceSize: Qt.size(18, 18)
                        color: PoniTheme.ink
                    }
                    Text { text: "LOKASI & CUACA"; color: PoniTheme.ink; font.bold: true; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    Text { text: "Open-Meteo"; color: PoniTheme.ink; font.pixelSize: 9 }
                }
                Text {
                    Layout.fillWidth: true
                    text: home.location.temperature == null ? "— °C" : home.location.temperature + " °C"
                    color: PoniTheme.ink
                    font.pixelSize: 23
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: home.location.weatherStatus || home.location.condition || "Cuaca belum tersedia"
                    color: PoniTheme.ink
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    ComboBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 29
                        model: home.activity.cities
                        currentIndex: model.indexOf(home.location.city)
                        displayText: home.location.city + (home.location.approximate ? " · IP" : "")
                        Accessible.name: "Pilih kota cuaca"
                        onActivated: home.dashboard.selectCity(currentText)
                        popup.height: Math.min(popup.implicitHeight, 122)
                        popup.y: -popup.height
                    }
                    PoniButton {
                        icon.source: "icons/map-pin.svg"
                        Accessible.name: "Deteksi perkiraan lokasi lewat IP"
                        ToolTip.visible: hovered
                        ToolTip.text: "Deteksi kota lewat IP dengan ipapi.co"
                        enabled: !home.location.locating
                        onClicked: home.dashboard.detect()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: home.location.locationStatus
                    color: PoniTheme.ink
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 240
            color: PoniTheme.light
            border.color: PoniTheme.ink
            border.width: PoniTheme.buttonBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                RowLayout {
                    ColorImage {
                        source: "icons/laptop-minimal.svg"
                        sourceSize: Qt.size(18, 18)
                        color: PoniTheme.ink
                    }
                    Text { text: "PERANGKAT"; color: PoniTheme.muted; font.bold: true; font.pixelSize: 11 }
                }
                Text {
                    Layout.fillWidth: true
                    text: home.metrics.deviceName
                    color: PoniTheme.ink
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: home.metrics.processorName
                    color: PoniTheme.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: PoniTheme.edge }
                Text {
                    Layout.fillWidth: true
                    text: (home.stats.memoryTotal ?? 0).toFixed(1) + " GiB RAM  ·  "
                        + (home.stats.diskFree ?? 0).toFixed(1) + " GiB disk kosong"
                    color: PoniTheme.ink
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
        }
    }
}
