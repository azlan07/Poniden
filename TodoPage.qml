pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property QtObject service
    required property var tasks
    readonly property int completed: tasks.reduce((count, task) => count + (task.done ? 1 : 0), 0)
    spacing: 8

    function addTask() {
        if (add.enabled && service.addTask(title.text, due.text)) {
            title.clear()
            due.clear()
            title.forceActiveFocus()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "To-do"
            color: PoniTheme.ink
            font.pixelSize: 18
            font.bold: true
            Accessible.role: Accessible.Heading
        }
        Item { Layout.fillWidth: true }
        Text {
            text: (page.tasks.length - page.completed) + " aktif  ·  " + page.completed + " selesai"
            color: PoniTheme.muted
            font.pixelSize: 11
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        TextField {
            id: title
            objectName: "taskTitle"
            Layout.fillWidth: true
            Layout.preferredHeight: 33
            placeholderText: "Tugas baru"
            Accessible.name: "Tugas baru"
            maximumLength: 160
            selectByMouse: true
            onAccepted: page.addTask()
        }
        TextField {
            id: due
            objectName: "taskDue"
            Layout.preferredWidth: 95
            Layout.preferredHeight: 33
            placeholderText: "Menit (ops.)"
            Accessible.name: "Pengingat dalam menit, opsional"
            maximumLength: 5
            inputMethodHints: Qt.ImhDigitsOnly
            validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,5}$/ }
            onAccepted: page.addTask()
        }
        PoniButton {
            id: add
            objectName: "addTask"
            Layout.preferredHeight: 33
            text: "+ Tambah"
            Accessible.name: "Tambah tugas"
            enabled: title.text.trim().length > 0
                && (!due.text || (due.acceptableInput && Number(due.text) >= 1 && Number(due.text) <= 10080))
            onClicked: page.addTask()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: page.tasks.length === 0
        color: PoniTheme.light
        border.color: PoniTheme.edge

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Daftar masih kosong"
                color: PoniTheme.ink
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tambah tugas dan atur pengingat bila perlu."
                color: PoniTheme.muted
                font.pixelSize: 11
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: page.tasks.length > 0
        clip: true
        spacing: 5
        model: page.tasks
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            id: row
            required property var modelData
            width: ListView.view.width - 10
            height: 43
            color: modelData.done ? PoniTheme.paper : PoniTheme.light
            border.color: PoniTheme.edge

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 7
                spacing: 5

                CheckBox {
                    objectName: "taskDone"
                    checked: row.modelData.done
                    Accessible.name: "Selesai: " + row.modelData.title
                    onToggled: page.service.markTask(row.modelData.index, checked)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.strikeout: row.modelData.done
                        font.weight: Font.DemiBold
                        color: row.modelData.done ? PoniTheme.muted : PoniTheme.ink
                    }
                    Text {
                        visible: row.modelData.when !== ""
                        text: "Pengingat " + row.modelData.when
                        color: PoniTheme.muted
                        font.pixelSize: 10
                    }
                }
                PoniButton {
                    objectName: "deleteTask"
                    icon.source: "icons/x.svg"
                    Layout.preferredWidth: 31
                    Layout.preferredHeight: 27
                    Accessible.name: "Hapus " + row.modelData.title
                    ToolTip.visible: hovered
                    ToolTip.text: "Hapus tugas"
                    onClicked: page.service.removeTask(row.modelData.index)
                }
            }
        }
    }
}
