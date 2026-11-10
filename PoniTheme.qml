pragma Singleton
import QtQuick

QtObject {
    readonly property var palettes: [
        { name: "Klasik", paper: "#fff7e5", light: "#fffdf5", ink: "#151519", lime: "#c7fa67", lilac: "#d8cdff", muted: "#51485a", edge: "#d9cfbd", idleAccent: "#c7fa67" },
        { name: "Terang", paper: "#eaf5ff", light: "#ffffff", ink: "#172b40", lime: "#ffd782", lilac: "#bad6ff", muted: "#40556c", edge: "#c5d7e7", idleAccent: "#bad6ff" },
        { name: "Gelap", paper: "#20232d", light: "#2b303c", ink: "#faf5ff", lime: "#285842", lilac: "#503b75", muted: "#d3c9e0", edge: "#3b404f", idleAccent: "#9ef4ba" },
        { name: "Brutal", paper: "#ffe852", light: "#fff6b6", ink: "#1c1222", lime: "#ff8ad5", lilac: "#7ff4e2", muted: "#533637", edge: "#dcbe48", idleAccent: "#ff8ad5" }
    ]
    property int index: 0
    readonly property var selected: palettes[index] || palettes[0]
    readonly property color ink: selected.ink
    readonly property color paper: selected.paper
    readonly property color light: selected.light
    readonly property color lime: selected.lime
    readonly property color lilac: selected.lilac
    readonly property color muted: selected.muted
    readonly property color edge: selected.edge
    readonly property color idleFill: "#151519"
    readonly property color idleAccent: selected.idleAccent
    readonly property color shadow: index === 2 ? "#101019" : ink
    readonly property int buttonBorder: index === 3 ? 3 : 2
    readonly property int buttonOffset: index === 3 ? 3 : 2
    property bool motionEnabled: true
}
