import os
import sys
from collections import deque
from pathlib import Path

from PySide6.QtCore import QLockFile, QProcess, QSettings, QStandardPaths, QTimer, QUrl, Qt
from PySide6.QtGui import QColor, QIcon, QPalette, QPainter, QPainterPath, QPixmap, QRegion
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickItem
from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

from shiboken6 import delete

from activities import Activities
from dashboard import Dashboard
from system_info import SystemInfo


folder = Path(__file__).resolve().parent
app = QApplication(sys.argv)
brand = "poniden by utiedev"
app.setApplicationName(brand)
app.setQuitOnLastWindowClosed(False)
palette = app.palette()
for role, color in {
    "Window": "#fff7e5", "Base": "#fffdf5", "Button": "#d8cdff",
    "Text": "#151519", "WindowText": "#151519", "ButtonText": "#151519",
    "PlaceholderText": "#51485a", "Highlight": "#c7fa67", "HighlightedText": "#151519",
}.items():
    palette.setColor(getattr(QPalette.ColorRole, role), QColor(color))
app.setPalette(palette)
config = Path(QStandardPaths.writableLocation(QStandardPaths.StandardLocation.GenericConfigLocation))
profile = config / "Poni"
profile.mkdir(parents=True, exist_ok=True)
instance_lock = QLockFile(str(profile / "poniden.lock"))
instance_lock.setStaleLockTime(0)
if not instance_lock.tryLock(0):
    if instance_lock.error() == QLockFile.LockError.LockFailedError:
        print("Poniden sudah berjalan untuk profil ini.", file=sys.stderr)
        raise SystemExit(0)
    raise SystemExit("Poniden tidak bisa mengunci profil pengaturan.")

desktop = QSettings(str(config / "kdeglobals"), QSettings.Format.IniFormat)
try:
    motion_enabled = float(desktop.value("KDE/AnimationDurationFactor", 1)) > 0
except (TypeError, ValueError):
    motion_enabled = True

activities = Activities()
engine = QQmlApplicationEngine()
metrics = SystemInfo()
dashboard = Dashboard()
engine.setInitialProperties({
    "brand": brand, "service": activities, "metrics": metrics, "dashboard": dashboard,
    "motionEnabled": motion_enabled,
})
engine.warnings.connect(lambda warnings: [print(error.toString(), file=sys.stderr) for error in warnings])
engine.load(QUrl.fromLocalFile(str(folder / "Poni.qml")))
if not engine.rootObjects():
    raise SystemExit(1)

window = engine.rootObjects()[0]
notch = window.findChild(QQuickItem, "notch")


def update_input_region():
    # The hidden Qt Quick content can still have width zero before the first Wayland map.
    left = (window.width() - notch.width()) / 2
    right = left + notch.width()
    bottom = notch.height()
    radius = notch.property("bottomLeftRadius")
    diameter = 2 * radius

    outline = QPainterPath()
    outline.moveTo(left, 0)
    outline.lineTo(right, 0)
    outline.arcTo(right - diameter, bottom - diameter, diameter, diameter, 0, -90)
    outline.arcTo(left, bottom - diameter, diameter, diameter, 270, -90)
    outline.closeSubpath()
    window.setMask(QRegion(outline.toFillPolygon().toPolygon()))


# Apply one input region after all notch geometry bindings settle.
mask_update = QTimer(window, interval=0, singleShot=True)
mask_update.timeout.connect(update_input_region)
notch.widthChanged.connect(mask_update.start)
notch.heightChanged.connect(mask_update.start)
window.widthChanged.connect(mask_update.start)
update_input_region()

pixmap = QPixmap(32, 32)
pixmap.fill(Qt.GlobalColor.transparent)
painter = QPainter(pixmap)
painter.setRenderHint(QPainter.RenderHint.Antialiasing)
painter.setPen(Qt.PenStyle.NoPen)
painter.setBrush(QColor("#151519"))
painter.drawRoundedRect(1, 1, 30, 30, 8, 8)
painter.setBrush(QColor("#c7fa67"))
painter.drawEllipse(8, 10, 6, 12)
painter.drawEllipse(18, 10, 6, 12)
painter.end()

tray = QSystemTrayIcon(QIcon(pixmap))
tray.setToolTip(brand)
menu = QMenu()
def open_panel():
    window.setProperty("page", 0)
    window.setProperty("pinned", True)


menu.addAction("Buka " + brand, open_panel)
fullscreen = menu.addAction("Sembunyikan saat jendela penuh")
fullscreen.setCheckable(True)
fullscreen.setChecked(activities.view["hideFullscreen"])
fullscreen.toggled.connect(activities.hideFullscreen)
activities.changed.connect(lambda: fullscreen.setChecked(activities.view["hideFullscreen"]))
autostart = menu.addAction("Jalankan saat masuk KDE")
autostart.setCheckable(True)
entry = config / "autostart" / "io.poni.desktop"
autostart.setChecked(entry.is_file())


def write_autostart(content):
    temporary = entry.with_name("io.poni.desktop.tmp")
    temporary.write_text(content, encoding="utf-8")
    os.replace(temporary, entry)


def set_autostart(enabled):
    try:
        if enabled:
            launcher = str(folder / "poni.sh").replace("%", "%%")
            for char in ('\\', '"', '`', '$'):
                launcher = launcher.replace(char, '\\' + char)
            launcher = launcher.replace('\\', '\\\\')
            entry.parent.mkdir(parents=True, exist_ok=True)
            write_autostart(f'[Desktop Entry]\nType=Application\nName={brand}\n'
                            f'Exec=/bin/sh "{launcher}"\nOnlyShowIn=KDE;\n')
        else:
            entry.unlink(missing_ok=True)
    except OSError as error:
        autostart.blockSignals(True)
        autostart.setChecked(entry.is_file())
        autostart.blockSignals(False)
        tray.showMessage(brand, str(error))


autostart.toggled.connect(set_autostart)
menu.addSeparator()
menu.addAction("Keluar", app.quit)
tray.setContextMenu(menu)
tray.activated.connect(lambda reason: open_panel()
                       if reason == QSystemTrayIcon.ActivationReason.Trigger else None)
alert_sounds = {"Fokus": folder / "alarm-clock-elapsed.oga", "Salat": folder / "azan-mekkah.oga"}
pending_alerts = deque()
sound = QProcess(app)
sound.setProcessChannelMode(QProcess.ProcessChannelMode.ForwardedErrorChannel)
alert_hold = QTimer(app, interval=8000, singleShot=True)


def show_next_alert():
    if not pending_alerts or window.property("alerting") or sound.state() != QProcess.NotRunning:
        return
    title, message = pending_alerts.popleft()
    window.setProperty("alertMessage", message)
    window.setProperty("alertTitle", "Pomodoro" if title == "Fokus" else "Waktu salat")
    alert_hold.start()
    volume = activities.view["focusVolume" if title == "Fokus" else "prayerVolume"]
    if volume:
        sound.start("pw-play", ["--media-role", "Notification", "--volume",
                                f"{volume / 100:.2f}", str(alert_sounds[title])])


def finish_alert():
    if not alert_hold.isActive() and sound.state() == QProcess.NotRunning:
        window.setProperty("alertTitle", "")
        show_next_alert()


def dismiss_alert():
    alert_hold.stop()
    window.setProperty("alertTitle", "")
    if sound.state() != QProcess.NotRunning:
        sound.kill()
    else:
        show_next_alert()


def show_reminder(title, message):
    if title in alert_sounds:
        pending_alerts.append((title, message))
        show_next_alert()
    else:
        tray.showMessage(title, message)


alert_hold.timeout.connect(finish_alert)
sound.stateChanged.connect(
    lambda state: QTimer.singleShot(0, finish_alert) if state == QProcess.NotRunning else None
)
window.dismissAlert.connect(dismiss_alert)
activities.reminder.connect(show_reminder)
tray.show()
try:
    if entry.is_file() and not entry.is_symlink():
        legacy_entry = entry.read_text(encoding="utf-8")
        branded_entry = legacy_entry.replace("\nName=Poni\n", f"\nName={brand}\n", 1)
        if legacy_entry != branded_entry:
            write_autostart(branded_entry)
except (OSError, UnicodeError) as error:
    tray.showMessage(brand, str(error))

window.setProperty("ready", True)
result = app.exec()
pending_alerts.clear()
if sound.state() != QProcess.NotRunning:
    sound.kill()
    sound.waitForFinished(1000)
tray.hide()
delete(engine)
instance_lock.unlock()
raise SystemExit(result)
