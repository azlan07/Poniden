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
            text: "Sembunyikan saat jendela penuh"
            checked: page.preferences.hideFullscreen
            onToggled: page.service.hideFullscreen(checked)
        }
        CheckBox {
            text: "Notch lebih kecil"
            checked: page.preferences.smallNotch
            onToggled: page.service.setAppearance("small_notch", checked)
        }
        CheckBox {
            text: "Mata saat idle"
            checked: page.preferences.showEyes
            onToggled: page.service.setAppearance("show_eyes", checked)
        }
        CheckBox {
            text: "Baterai saat hover"
            checked: page.preferences.showBattery
            onToggled: page.service.setAppearance("show_battery", checked)
        }
        CheckBox {
            text: "Animasi"
            checked: page.preferences.animateNotch
            onToggled: page.service.setAppearance("animate_notch", checked)
        }
    }

    Item { Layout.fillHeight: true }
}
