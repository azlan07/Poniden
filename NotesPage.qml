pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    property string selected: ""
    property bool loading: false

    function select(noteId, content) {
        loading = true
        selected = noteId
        editor.text = content
        editor.cursorPosition = content.length
        loading = false
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Catatan"; color: PoniTheme.ink; font.pixelSize: 17; font.bold: true }
        Item { Layout.fillWidth: true }
        PoniButton {
            text: "+ Catatan"
            onClicked: {
                page.select(page.service.newNote(), "")
                editor.forceActiveFocus()
            }
        }
        PoniButton {
            text: "Hapus"
            enabled: page.selected !== ""
            onClicked: confirm.open()
        }
    }

    Dialog {
        id: confirm
        title: "Hapus catatan ini?"
        anchors.centerIn: Overlay.overlay
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            const noteId = page.selected
            page.select("", "")
            page.service.removeNote(noteId)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        ListView {
            Layout.preferredWidth: 145
            Layout.fillHeight: true
            clip: true
            spacing: 3
            model: page.service.notes
            ScrollBar.vertical: ScrollBar {}
            delegate: PoniButton {
                required property var modelData
                width: ListView.view.width - 10
                text: modelData.title
                highlighted: modelData.id === page.selected
                onClicked: page.select(modelData.id, modelData.text)
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea {
                id: editor
                enabled: page.selected !== ""
                placeholderText: enabled ? "Baris pertama menjadi judul" : "Pilih atau buat catatan"
                Accessible.name: "Isi catatan"
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                onTextChanged: {
                    if (!page.loading && page.selected)
                        page.service.saveNote(page.selected, text)
                }
            }
        }
    }
    Text { text: "Tersimpan otomatis di perangkat ini"; color: PoniTheme.muted; font.pixelSize: 11 }
}
