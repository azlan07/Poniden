pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import org.kde.layershell as LayerShell
import org.kde.plasma.private.mpris as Media
import org.kde.taskmanager as Tasks

Window {
    id: island
    required property string brand
    required property QtObject service
    required property QtObject metrics
    property bool motionEnabled: true
    readonly property bool animate: motionEnabled && activity.animateNotch
        && Qt.styleHints.accessibility.motionPreference !== Qt.ReducedMotion
    Binding {
        target: PoniTheme
        property: "motionEnabled"
        value: island.animate
    }
    title: brand
    color: "transparent"
    palette.window: PoniTheme.paper
    palette.windowText: PoniTheme.ink
    palette.base: PoniTheme.light
    palette.text: PoniTheme.ink
    palette.placeholderText: PoniTheme.muted
    palette.button: PoniTheme.lilac
    palette.buttonText: PoniTheme.ink
    palette.mid: PoniTheme.ink
    palette.highlight: PoniTheme.lime
    palette.highlightedText: PoniTheme.ink
    flags: Qt.FramelessWindowHint
    width: 548
    height: 290
    visible: ready && (alerting || !(activity.hideFullscreen && fullscreenDetected))

    LayerShell.Window.anchors: LayerShell.Window.AnchorTop
    LayerShell.Window.layer: alerting ? LayerShell.Window.LayerOverlay : LayerShell.Window.LayerTop
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: expanded
        ? LayerShell.Window.KeyboardInteractivityOnDemand
        : LayerShell.Window.KeyboardInteractivityNone

    property bool ready: false
    property bool pinned: false
    property bool fullscreenDetected: false
    property string alertTitle: ""
    property string alertMessage: ""
    readonly property bool alerting: alertTitle.length > 0
    signal dismissAlert()
    property int page: 0
    property int previousPage: 0
    property date now: new Date()
    readonly property var activity: service.view
    readonly property var pages: ["Media", "Fokus", "Shelf", "To-do", "Salat", "Catatan", "Sistem"]
    readonly property int settingsIndex: pages.length
    readonly property bool idleFace: visible && !alerting && !compact && !expanded && !liveStatus && !dropping
    readonly property string liveStatus: activity.running ? "◷ " + elapsed(activity.remaining * 1000000)
        : activity.nextTask ? "✓ " + elapsed(activity.nextTask * 1000000) : ""
    readonly property bool dropping: fileDrop.containsDrag
    readonly property bool expanded: pinned && !alerting
    readonly property bool showClock: visible && (compact || expanded)
    readonly property bool compact: !alerting && !expanded && hover.hovered
    readonly property var player: media.currentPlayer
    readonly property string track: player?.track || ""
    readonly property string artist: player?.artist || ""
    readonly property bool playing: player?.playbackStatus === Media.PlaybackStatus.Playing
    readonly property bool seekable: !!player?.canSeek && player.length > 0

    function updateClock() {
        now = new Date()
        clockTick.interval = 60000 - now.getSeconds() * 1000 - now.getMilliseconds()
        clockTick.restart()
    }

    onShowClockChanged: {
        if (showClock)
            updateClock()
        else
            clockTick.stop()
    }

    function elapsed(us) {
        const seconds = Math.max(0, Math.floor(us / 1000000))
        return Math.floor(seconds / 60).toString().padStart(2, "0") + ":"
            + (seconds % 60).toString().padStart(2, "0")
    }

    function updateFullscreen() {
        for (let i = 0; i < fullscreenWindows.count; ++i) {
            if (fullscreenWindows.objectAt(i)?.blocksNotch) {
                fullscreenDetected = true
                return
            }
        }
        fullscreenDetected = false
    }

    onCompactChanged: { if (compact) service.refreshBattery() }
    Shortcut {
        sequence: "Escape"
        enabled: island.expanded || island.alerting
        onActivated: {
            if (island.alerting)
                island.dismissAlert()
            else
                island.pinned = false
        }
    }

    Media.Mpris2Model { id: media }
    Tasks.TasksModel {
        id: tasks
        filterByCurrentVirtualDesktop: true
        filterByScreen: true
        groupMode: Tasks.TasksModel.GroupDisabled
        screenGeometry: Qt.rect(island.screen.virtualX, island.screen.virtualY,
                                island.screen.width, island.screen.height)
    }
    Instantiator {
        id: fullscreenWindows
        model: tasks
        delegate: QtObject {
            required property var model
            readonly property bool blocksNotch: !model.IsMinimized
                && (model.IsFullScreen || (model.IsMaximized && model.IsActive))
            onBlocksNotchChanged: Qt.callLater(island.updateFullscreen)
        }
        onObjectAdded: Qt.callLater(island.updateFullscreen)
        onObjectRemoved: Qt.callLater(island.updateFullscreen)
    }

    Timer {
        interval: 1000
        running: island.visible && island.expanded && island.playing && island.page === 0
        repeat: true
        triggeredOnStart: true
        onTriggered: island.player?.updatePosition()
    }
    Timer {
        id: clockTick
        onTriggered: { if (island.showClock) island.updateClock() }
    }

    Rectangle {
        id: notch
        objectName: "notch"
        anchors.horizontalCenter: parent.horizontalCenter
        width: island.alerting ? 420 : island.expanded ? island.width
            : island.compact || island.liveStatus || island.dropping ? (island.activity.smallNotch ? 182 : 220)
            : (island.activity.smallNotch ? 132 : 164)
        height: island.alerting ? 68 : island.expanded ? island.height : island.compact ? 46 : 34
        color: island.alerting ? PoniTheme.paper : island.dropping ? PoniTheme.lilac : island.expanded ? PoniTheme.paper
            : island.compact ? PoniTheme.lime : PoniTheme.ink
        border.color: island.alerting || island.expanded || island.compact ? PoniTheme.ink : PoniTheme.lime
        border.width: 2
        bottomLeftRadius: 6
        bottomRightRadius: bottomLeftRadius
        antialiasing: true
        clip: true

        // The animation changes the artwork and pointer region inside the fixed Wayland window.
        Behavior on width {
            enabled: island.visible && island.animate
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: island.visible && island.animate
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        HoverHandler { id: hover }

        DropArea {
            id: fileDrop
            anchors.fill: parent
            enabled: !island.alerting
            onEntered: drag => {
                drag.accepted = !!(drag.supportedActions & Qt.CopyAction) && drag.hasUrls
                    && island.service.canDropFiles(drag.urls.map(url => url.toString()))
            }
            onDropped: drop => {
                if ((drop.supportedActions & Qt.CopyAction) && drop.hasUrls
                    && island.service.addFiles(drop.urls.map(url => url.toString()))) {
                    island.page = 2
                    island.pinned = true
                    drop.accept(Qt.CopyAction)
                }
            }
        }

        PoniEyes {
            objectName: "eyes"
            anchors.centerIn: parent
            visible: island.idleFace && island.activity.showEyes
        }

        Text {
            anchors.centerIn: parent
            visible: island.idleFace && !island.activity.showEyes
            text: "poniden"
            color: PoniTheme.lime
            font.bold: true
            font.pixelSize: 13
        }

        RowLayout {
            id: status
            objectName: "status"
            anchors.centerIn: parent
            spacing: 18
            opacity: island.compact ? 1 : 0
            visible: opacity > 0 && !island.alerting && !island.expanded && !island.dropping
            Behavior on opacity {
                enabled: island.animate
                NumberAnimation { duration: 120 }
            }

            Text {
                text: Qt.formatTime(island.now, "HH:mm")
                color: PoniTheme.ink
                font.family: "monospace"
                font.pixelSize: 20
                font.bold: true
            }

            Rectangle {
                visible: island.activity.showBattery
                Layout.preferredWidth: batteryRow.implicitWidth + 14
                Layout.preferredHeight: 26
                color: PoniTheme.lilac
                radius: 5
                border.width: 1
                border.color: PoniTheme.ink

                RowLayout {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "BAT"
                        color: PoniTheme.ink
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        objectName: "batteryStatus"
                        text: island.activity.battery || "N/A"
                        color: PoniTheme.ink
                        font.pixelSize: 13
                        font.bold: true
                        Accessible.name: "Baterai " + text
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !island.alerting && !island.expanded && (island.dropping || (!island.compact && !!island.liveStatus))
            text: island.dropping ? "▣  Lepas ke Shelf" : island.liveStatus
            color: island.dropping ? PoniTheme.ink : PoniTheme.lime
            font.bold: true
            font.pixelSize: 13
        }

        MouseArea {
            anchors.fill: parent
            enabled: !island.expanded && !island.alerting
            visible: enabled
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: "Buka panel " + island.brand
            Accessible.onPressAction: island.pinned = true
            onClicked: island.pinned = true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10
            visible: island.alerting
            Accessible.role: Accessible.AlertMessage

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: island.alertTitle
                    color: PoniTheme.ink
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: island.alertMessage
                    color: PoniTheme.ink
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
            PoniButton {
                text: "Tutup"
                Accessible.name: "Hentikan suara dan tutup pengingat"
                onClicked: island.dismissAlert()
            }
        }

        ColumnLayout {
            id: expandedPanel
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: island.width - 38
            height: island.height - 25
            spacing: 5
            enabled: island.expanded
            opacity: island.expanded ? 1 : 0
            visible: opacity > 0 && !island.alerting
            transform: Translate {
                y: island.expanded ? 0 : -6
                Behavior on y {
                    enabled: island.animate
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }
            Behavior on opacity {
                enabled: island.animate
                NumberAnimation { duration: 160 }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 29

                Text {
                    anchors.centerIn: parent
                    objectName: "headerDate"
                    text: island.now.toLocaleString(Qt.locale("id_ID"), "dddd, d MMM yyyy   HH:mm")
                    color: PoniTheme.ink
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: island.activity.battery
                    color: PoniTheme.ink
                    font.pixelSize: 12
                }

                PoniButton {
                    objectName: "settingsButton"
                    anchors.right: closeButton.left
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 27
                    text: "⚙"
                    highlighted: island.page === island.settingsIndex
                    Accessible.name: "Pengaturan tampilan"
                    onClicked: {
                        if (island.page === island.settingsIndex) {
                            island.page = island.previousPage
                        } else {
                            island.previousPage = island.page
                            island.page = island.settingsIndex
                        }
                    }
                }

                PoniButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 27
                    text: "×"
                    Accessible.name: "Tutup panel"
                    onClicked: island.pinned = false
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 81
                    anchors.verticalCenter: parent.verticalCenter
                    text: island.dropping ? "Lepas ke Shelf" : island.liveStatus
                    color: PoniTheme.ink
                    font.pixelSize: 12
                }
            }

            StackLayout {
                id: panel
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: island.page

                Component {
                    id: mediaPage
                    ColumnLayout {
                        spacing: 5
                        RowLayout {
                            spacing: 14
                            Rectangle {
                                Layout.preferredWidth: 68
                                Layout.preferredHeight: 68
                                color: PoniTheme.lilac
                                clip: true
                                Image {
                                    id: cover
                                    anchors.fill: parent
                                    source: island.player?.artUrl || ""
                                    sourceSize.width: 136
                                    sourceSize.height: 136
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: cover.status !== Image.Ready
                                    text: "♫"
                                    font.pixelSize: 27
                                    color: PoniTheme.ink
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: PoniTheme.ink
                                    border.width: 2
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: island.track || "Belum ada musik"
                                    color: PoniTheme.ink
                                    font.pixelSize: 19
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: island.artist || "Putar lagu untuk mulai"
                                    color: PoniTheme.muted
                                    font.pixelSize: 13
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: island.elapsed(island.player?.position ?? 0); color: PoniTheme.ink }
                            Slider {
                                id: timeline
                                Layout.fillWidth: true
                                Accessible.name: "Posisi lagu"
                                enabled: island.seekable
                                live: false
                                to: island.player?.length > 0 ? island.player.length : 1
                                value: island.player?.position ?? 0
                                onMoved: {
                                    if (!pressed && island.seekable)
                                        island.player.position = Math.round(value)
                                }
                                onPressedChanged: {
                                    if (!pressed && island.seekable)
                                        island.player.position = Math.round(from + position * (to - from))
                                }
                                background: Rectangle {
                                    x: timeline.leftPadding
                                    y: (timeline.height - height) / 2
                                    width: timeline.availableWidth
                                    height: 6
                                    border.width: 1
                                    border.color: PoniTheme.ink
                                    color: PoniTheme.edge
                                    Rectangle {
                                        width: parent.width * timeline.visualPosition
                                        height: parent.height
                                        color: PoniTheme.ink
                                    }
                                }
                                handle: Rectangle {
                                    x: timeline.leftPadding + timeline.visualPosition * (timeline.availableWidth - width)
                                    y: (timeline.height - height) / 2
                                    width: 12; height: 12
                                    border.width: 2
                                    border.color: PoniTheme.ink
                                    color: timeline.visualFocus ? PoniTheme.lilac : PoniTheme.lime
                                    visible: timeline.enabled
                                }
                            }
                            Text {
                                text: "−" + island.elapsed((island.player?.length ?? 0) - (island.player?.position ?? 0))
                                color: PoniTheme.ink
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            PoniButton {
                                text: "⏮"; Accessible.name: "Lagu sebelumnya"
                                enabled: !!island.player?.canGoPrevious
                                onClicked: island.player.Previous()
                            }
                            PoniButton {
                                text: island.playing ? "⏸" : "▶"
                                Accessible.name: island.playing ? "Jeda" : "Putar"
                                enabled: island.playing ? !!island.player?.canPause : !!island.player?.canPlay
                                onClicked: island.player.PlayPause()
                            }
                            PoniButton {
                                text: "⏭"; Accessible.name: "Lagu berikutnya"
                                enabled: !!island.player?.canGoNext
                                onClicked: island.player.Next()
                            }
                        }
                    }
                }

                Component { id: focusPage; FocusPage { service: island.service; activity: island.activity; remaining: island.elapsed(island.activity.remaining * 1000000) } }
                Component { id: shelfPage; ShelfPage { service: island.service; files: island.service.shelfFiles } }
                Component { id: todoPage; TodoPage { service: island.service; tasks: island.service.todoItems } }
                Component { id: prayerPage; PrayerPage { service: island.service; activity: island.activity } }
                Component { id: notesPage; NotesPage { service: island.service } }
                Component { id: systemPage; SystemPage { objectName: "systemPage"; metrics: island.metrics; monitoring: island.expanded && island.visible && island.page === 6 } }

                Component { id: settingsPage; SettingsPage { service: island.service; brand: island.brand } }

                Repeater {
                    model: [mediaPage, focusPage, shelfPage, todoPage,
                            prayerPage, notesPage, systemPage, settingsPage]
                    delegate: Loader {
                        required property Component modelData
                        required property int index
                        objectName: "pageLoader"
                        readonly property bool selected: island.expanded && island.visible && island.page === index
                        property bool visited: false
                        // Keep drafts and selections in visited tabs. Media and System have no draft to retain.
                        active: selected || (visited && modelData !== mediaPage && modelData !== systemPage && modelData !== settingsPage)
                        onSelectedChanged: { if (selected) visited = true }
                        sourceComponent: modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PoniTheme.edge
            }

            GridLayout {
                Layout.fillWidth: true
                columns: island.pages.length
                uniformCellWidths: true
                columnSpacing: 6
                rowSpacing: 4
                Repeater {
                    model: island.pages
                    PoniButton {
                        required property string modelData
                        required property int index
                        text: modelData
                        Layout.preferredHeight: 28
                        Layout.fillWidth: true
                        highlighted: island.page === index
                        onClicked: island.page = index
                    }
                }
            }
        }
    }
}
