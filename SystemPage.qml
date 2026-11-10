pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject metrics
    required property bool monitoring
    readonly property var stats: metrics.view
    spacing: 8

    function rate(bytes) {
        return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MiB/s"
                                : (bytes / 1024).toFixed(1) + " KiB/s"
    }

    onMonitoringChanged: { if (monitoring) metrics.resetSample() }
    Timer {
        interval: 1500
        running: page.monitoring
        repeat: true
        onTriggered: page.metrics.refresh()
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Informasi sistem"
            color: PoniTheme.ink
            font.pixelSize: 18
            font.bold: true
            Accessible.role: Accessible.Heading
        }
        Item { Layout.fillWidth: true }
        Text {
            text: "LIVE · 1,5 dtk"
            color: PoniTheme.muted
            font.family: "monospace"
            font.pixelSize: 10
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: ["CPU", "RAM", "Disk /"]
            delegate: Rectangle {
                id: card
                required property string modelData
                required property int index
                readonly property var levels: [page.stats.cpu, page.stats.memory, page.stats.disk]
                readonly property int level: levels[index] ?? 0
                Layout.fillWidth: true
                Layout.preferredWidth: 150
                Layout.preferredHeight: 73
                color: PoniTheme.light
                border.color: PoniTheme.ink
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 1
                    Text {
                        text: card.modelData
                        color: PoniTheme.muted
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: card.index === 0 && !page.stats.sampled ? "—" : card.level + "%"
                        color: PoniTheme.ink
                        font.pixelSize: 19
                        font.bold: true
                    }
                    PoniProgress {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        to: 100
                        value: card.level
                    }
                    Text {
                        Layout.fillWidth: true
                        text: card.index === 0 ? (page.stats.threads ?? 0) + " thread"
                            : card.index === 1 ? (page.stats.memoryUsed ?? 0).toFixed(1) + " / "
                                + (page.stats.memoryTotal ?? 0).toFixed(1) + " GiB"
                            : (page.stats.diskFree ?? 0).toFixed(1) + " GiB kosong"
                        color: PoniTheme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        color: PoniTheme.lilac
        border.color: PoniTheme.ink
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "JARINGAN"; color: PoniTheme.muted; font.pixelSize: 10; font.bold: true }
                Text {
                    text: !page.stats.networkAvailable ? "Adaptor fisik tidak tersedia"
                        : !page.stats.sampled ? "Mengukur…"
                        : "↓ " + page.rate(page.stats.down) + "    ↑ " + page.rate(page.stats.up)
                    color: PoniTheme.ink
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: PoniTheme.ink }
            ColumnLayout {
                Layout.preferredWidth: 112
                spacing: 2
                Text { text: "SUHU CPU"; color: PoniTheme.muted; font.pixelSize: 10; font.bold: true }
                Text {
                    text: page.stats.temperature == null ? "Sensor tidak tersedia" : page.stats.temperature + " °C"
                    color: PoniTheme.ink
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
