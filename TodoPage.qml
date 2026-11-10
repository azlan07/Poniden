pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property var tasks
    spacing: 5

    Text { text: "To-do"; color: PoniTheme.ink; font.pixelSize: 17; font.bold: true }

    RowLayout {
        TextField {
            id: title
            Layout.fillWidth: true
            placeholderText: "Tugas baru"
            Accessible.name: "Tugas baru"
            maximumLength: 160
            selectByMouse: true
            onAccepted: { if (add.enabled) add.clicked() }
        }
        TextField {
            id: due
            Layout.preferredWidth: 94
            placeholderText: "Menit (ops.)"
            Accessible.name: "Pengingat dalam menit, opsional"
            maximumLength: 5
            validator: IntValidator { bottom: 1; top: 10080 }
            onAccepted: { if (add.enabled) add.clicked() }
        }
        PoniButton {
            id: add
            text: "Tambah"
            enabled: title.text.trim().length > 0 && (due.text.length === 0 || due.acceptableInput)
            onClicked: {
                page.service.addTask(title.text, due.text)
                title.clear()
                due.clear()
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 3
        model: page.tasks
        ScrollBar.vertical: ScrollBar {}
        delegate: RowLayout {
            id: row
            required property var modelData
            width: ListView.view.width - 12
            CheckBox {
                id: done
                checked: row.modelData.done
                Accessible.name: "Selesai: " + row.modelData.title
                onToggled: page.service.markTask(row.modelData.index, checked)
            }
            Text {
                Layout.fillWidth: true
                text: row.modelData.title
                elide: Text.ElideRight
                font.strikeout: row.modelData.done
                color: row.modelData.done ? PoniTheme.muted : PoniTheme.ink
            }
            Text { text: row.modelData.when; color: PoniTheme.muted; font.pixelSize: 11 }
            PoniButton {
                text: "×"
                Accessible.name: "Hapus " + row.modelData.title
                onClicked: page.service.removeTask(row.modelData.index)
            }
        }
    }
}
