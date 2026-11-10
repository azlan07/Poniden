pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property var files
    spacing: 5

    RowLayout {
        Text { text: "File shelf · " + page.files.length; color: PoniTheme.ink; font.pixelSize: 17; font.bold: true }
        Item { Layout.fillWidth: true }
        PoniButton { text: "Tambah file"; onClicked: chooser.open() }
    }

    FileDialog {
        id: chooser
        title: "Pilih file untuk Shelf"
        fileMode: FileDialog.OpenFiles
        onAccepted: page.service.addFiles(selectedFiles.map(url => url.toString()))
    }

    Text {
        Layout.fillWidth: true
        text: "Drop file atau folder ke notch. Klik untuk buka, tarik untuk pakai di aplikasi lain."
        wrapMode: Text.Wrap
        color: PoniTheme.muted
        font.pixelSize: 11
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: page.files
        ScrollBar.vertical: ScrollBar {}
        delegate: RowLayout {
            id: row
            required property var modelData
            width: ListView.view.width - 12
            PoniButton {
                id: entry
                Layout.fillWidth: true
                enabled: row.modelData.exists
                text: row.modelData.name + (enabled ? "" : " · File dipindah atau hilang")
                onClicked: page.service.openFile(row.modelData.url)
                DragHandler {
                    target: null
                    enabled: entry.enabled
                    onActiveChanged: {
                        if (active)
                            Qt.callLater(page.service.dragFile, entry, row.modelData.url)
                    }
                }
            }
            PoniButton {
                text: "×"
                Accessible.name: "Keluarkan " + row.modelData.name + " dari Shelf"
                onClicked: page.service.removeFile(row.modelData.url)
            }
        }
    }
}
