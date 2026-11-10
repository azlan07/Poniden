pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property string brand
    readonly property var preferences: service.view
    spacing: 4

    Text {
        text: page.brand
        color: PoniTheme.ink
        font.pixelSize: 18
        font.bold: true
        Accessible.role: Accessible.Heading
    }
    Text { text: "Pengaturan tampilan"; color: PoniTheme.muted; font.pixelSize: 12 }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        uniformCellWidths: true
        columnSpacing: 12
        rowSpacing: 3

        CheckBox {
            Layout.preferredHeight: 29
            text: "Sembunyikan saat jendela penuh"
            checked: page.preferences.hideFullscreen
            onToggled: page.service.hideFullscreen(checked)
        }
        CheckBox {
            Layout.preferredHeight: 29
            text: "Notch lebih kecil"
            checked: page.preferences.smallNotch
            onToggled: page.service.setAppearance("small_notch", checked)
        }
        CheckBox {
            Layout.preferredHeight: 29
            text: "Mata saat idle"
            checked: page.preferences.showEyes
            onToggled: page.service.setAppearance("show_eyes", checked)
        }
        CheckBox {
            Layout.preferredHeight: 29
            text: "Baterai saat hover"
            checked: page.preferences.showBattery
            onToggled: page.service.setAppearance("show_battery", checked)
        }
        CheckBox {
            Layout.preferredHeight: 29
            text: "Animasi"
            checked: page.preferences.animateNotch
            onToggled: page.service.setAppearance("animate_notch", checked)
        }
    }

    Text { text: "Tema warna"; color: PoniTheme.ink; font.bold: true }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: PoniTheme.palettes
            delegate: ColumnLayout {
                id: swatch
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 11
                    color: swatch.modelData.paper
                    border.color: PoniTheme.ink
                    Rectangle {
                        anchors.right: parent.right
                        width: parent.width / 2
                        height: parent.height
                        color: swatch.modelData.idleAccent
                        border.color: PoniTheme.ink
                    }
                }
                PoniButton {
                    Layout.fillWidth: true
                    text: swatch.modelData.name
                    highlighted: page.preferences.theme === swatch.index
                    Accessible.name: "Tema " + text
                    onClicked: page.service.setTheme(swatch.index)
                }
            }
        }
    }
    Item { Layout.fillHeight: true }
}
