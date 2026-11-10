import json
import math
import time
from datetime import UTC, date, datetime, timedelta
from functools import lru_cache
from pathlib import Path
from uuid import uuid4

from PySide6.QtCore import QMimeData, QObject, Property, QSettings, QTimer, QUrl, Signal, Slot, Qt
from PySide6.QtGui import QDesktopServices, QDrag


CITIES = {
    "Jakarta": (-6.18, 106.83, 7),
    "Padang": (-0.947, 100.417, 7),
    "Bandung": (-6.92, 107.62, 7),
    "Surabaya": (-7.25, 112.75, 7),
    "Denpasar": (-8.65, 115.22, 8),
    "Makassar": (-5.15, 119.43, 8),
    "Jayapura": (-2.54, 140.72, 9),
}


@lru_cache(maxsize=16)
def prayer_times(day, city):
    # NOAA solar approximation, Indonesian twilight angles, and one shadow length for Asar.
    lat, lon, zone = CITIES[city]
    lat = math.radians(lat)
    angle = 2 * math.pi * (day.timetuple().tm_yday - 1) / 365
    c, s = math.cos, math.sin
    equation = 229.18 * (0.000075 + 0.001868*c(angle) - 0.032077*s(angle)
                         - 0.014615*c(2*angle) - 0.040849*s(2*angle))
    dec = (0.006918 - 0.399912*c(angle) + 0.070257*s(angle)
           - 0.006758*c(2*angle) + 0.000907*s(2*angle)
           - 0.002697*c(3*angle) + 0.00148*s(3*angle))
    noon = 720 - 4 * lon - equation + zone * 60

    def offset(altitude):
        ratio = (s(altitude) - s(lat)*s(dec)) / (c(lat)*c(dec))
        return 4 * math.degrees(math.acos(ratio))

    asar = math.atan(1 / (1 + math.tan(abs(lat - dec))))
    return [(name, round(minute + 2)) for name, minute in (
        ("Subuh", noon - offset(math.radians(-20))),
        ("Zuhur", noon),
        ("Asar", noon + offset(asar)),
        ("Magrib", noon + offset(math.radians(-0.833))),
        ("Isya", noon + offset(math.radians(-18))),
    )]


class Activities(QObject):
    changed = Signal()
    listsChanged = Signal()
    notesChanged = Signal()
    reminder = Signal(str, str)

    def __init__(self):
        super().__init__()
        self.settings = QSettings("Poni", "Activities")
        self.state = {
            "phase": 0, "rounds": 0, "focus_minutes": 25, "break_minutes": 5,
            "remaining": 1500, "deadline": 0, "files": [], "tasks": [], "notes": [],
            "focus_day": "", "focus_sessions": 0,
            "city": "Jakarta", "prayer_alerts": False, "last_prayer": "",
            "hide_fullscreen": True, "small_notch": False, "show_eyes": True,
            "show_battery": True, "animate_notch": True,
        }
        try:
            saved = json.loads(self.settings.value("data", "{}"))
            if isinstance(saved, dict):
                self.state.update(saved)
        except (TypeError, ValueError):
            pass
        self.snapshot = {}
        self.last_battery_read = float("-inf")
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh)
        self.refresh(check_reminders=False)
        QTimer.singleShot(0, self.refresh)

    @Property("QVariantMap", notify=changed)
    def view(self):
        return self.snapshot

    @Property("QVariantList", notify=listsChanged)
    def shelfFiles(self):
        return self.snapshot["files"]

    @Property("QVariantList", notify=listsChanged)
    def todoItems(self):
        return self.snapshot["tasks"]

    def save(self):
        self.settings.setValue("data", json.dumps(self.state))
        self.settings.sync()
        self.refresh()

    def advance(self, completed=False):
        s = self.state
        if s["phase"] == 0:
            if completed:
                today = date.today().isoformat()
                if s["focus_day"] != today:
                    s.update(focus_day=today, focus_sessions=0)
                s["focus_sessions"] += 1
                s["rounds"] += 1
            s["phase"] = 2 if completed and s["rounds"] % 4 == 0 else 1
        else:
            s["phase"] = 0
        s["remaining"] = self.phase_seconds()
        s["deadline"] = 0

    def phase_seconds(self):
        s = self.state
        return (s["focus_minutes"], s["break_minutes"], s["break_minutes"] * 3)[s["phase"]] * 60

    @Slot()
    def refreshBattery(self):
        self.refresh(refresh_battery=True)

    def refresh(self, check_reminders=True, refresh_battery=False):
        s = self.state
        now = int(time.time())
        alerts = []
        if check_reminders and s["deadline"] and now >= s["deadline"]:
            was_focus = s["phase"] == 0
            self.advance(completed=True)
            if was_focus:
                s["deadline"] = now + s["remaining"]
            alerts.append(("Fokus", "Waktunya istirahat." if was_focus else "Jeda selesai. Siap fokus lagi?"))
        for task in s["tasks"] if check_reminders else ():
            if task["due"] and not task["done"] and not task["notified"] and task["due"] <= now:
                task["notified"] = True
                alerts.append(("To-do", task["title"]))

        today = date.today().isoformat()
        city = s["city"]
        city_now = datetime.now(UTC) + timedelta(hours=CITIES[city][2])
        city_day = city_now.date()
        minute_now = city_now.hour * 60 + city_now.minute
        prayers = prayer_times(city_day, city)
        for name, minute in prayers:
            key = f"{city}/{city_day}/{name}"
            if check_reminders and s["prayer_alerts"] and minute == minute_now and s["last_prayer"] != key:
                s["last_prayer"] = key
                alerts.append(("Salat", f"Waktunya {name} di {city}."))

        remaining = max(0, s["deadline"] - now) if s["deadline"] else s["remaining"]
        clock = time.monotonic()
        if refresh_battery or clock - self.last_battery_read >= 15:
            battery = self.battery()
            self.last_battery_read = clock
        else:
            battery = self.snapshot["battery"]
        next_task = min((task["due"] for task in s["tasks"]
                         if not task["done"] and 0 < task["due"] - now <= 3600), default=now)
        interval = 1000 if s["deadline"] or next_task > now else 15000
        next_prayer, prayer_minute = next(
            ((name, minute) for name, minute in prayers if minute > minute_now),
            ("Subuh besok", 24 * 60),
        )
        if s["prayer_alerts"]:
            until_prayer = (prayer_minute - minute_now) * 60_000
            until_prayer -= city_now.second * 1000 + city_now.microsecond // 1000
            interval = min(interval, max(100, until_prayer))
        if not self.timer.isActive() or self.timer.interval() != interval:
            self.timer.start(interval)
        values = {
            "nextTask": next_task - now,
            "phaseIndex": s["phase"],
            "completedRounds": s["rounds"] % 4 or (4 if s["rounds"] and s["phase"] == 2 else 0),
            "sessionsToday": s["focus_sessions"] if s["focus_day"] == today else 0,
            "phase": ("Fokus", "Istirahat", "Istirahat panjang")[s["phase"]],
            "running": bool(s["deadline"]), "remaining": remaining,
            "round": s["rounds"] % 4 + 1 if s["phase"] == 0 else (s["rounds"] - 1) % 4 + 1,
            "focusMinutes": s["focus_minutes"], "breakMinutes": s["break_minutes"],
            "focusTotal": self.phase_seconds(),
            "files": [{"url": QUrl.fromLocalFile(p).toString(), "name": Path(p).name,
                       "exists": Path(p).exists()} for p in s["files"]],
            "tasks": [{**task, "index": i,
                       "when": datetime.fromtimestamp(task["due"]).strftime("%d/%m %H:%M") if task["due"] else ""}
                      for i, task in enumerate(s["tasks"])],
            "city": city, "cities": list(CITIES), "prayerAlerts": s["prayer_alerts"],
            "prayers": [{"name": name, "time": f"{minute // 60:02}:{minute % 60:02}"}
                        for name, minute in prayers],
            "nextPrayer": next_prayer,
            "battery": battery, "hideFullscreen": s["hide_fullscreen"],
            "smallNotch": s["small_notch"], "showEyes": s["show_eyes"],
            "showBattery": s["show_battery"], "animateNotch": s["animate_notch"],
        }
        if values != self.snapshot:
            lists_changed = any(values[key] != self.snapshot.get(key) for key in ("files", "tasks"))
            self.snapshot = values
            self.changed.emit()
            if lists_changed:
                self.listsChanged.emit()
        if alerts:
            self.settings.setValue("data", json.dumps(s))
            self.settings.sync()
            for title, message in alerts:
                self.reminder.emit(title, message)

    @staticmethod
    def battery():
        supplies = Path("/sys/class/power_supply")

        def read(path):
            try:
                return path.read_text().strip()
            except OSError:
                return ""

        batteries = [p for p in supplies.glob("*") if read(p / "type") == "Battery"]
        levels = [int(level) for p in batteries if (level := read(p / "capacity")).isdigit()]
        if not levels:
            return ""
        ac = any(read(p / "online") == "1" for p in supplies.glob("*"))
        return f"{'⚡ ' if ac else ''}{round(sum(levels)/len(levels))}%"

    @Slot(str)
    def focusAction(self, action):
        s = self.state
        if action == "toggle":
            if s["deadline"]:
                s["remaining"] = max(1, s["deadline"] - int(time.time()))
                s["deadline"] = 0
            else:
                s["deadline"] = int(time.time()) + s["remaining"]
        elif action == "skip":
            self.advance()
        elif action == "reset":
            s["deadline"] = 0
            s["remaining"] = self.phase_seconds()
        self.save()

    @Slot(int)
    def selectPhase(self, phase):
        if 0 <= phase <= 2:
            self.state["phase"] = phase
            self.focusAction("reset")

    @Slot(int, int)
    def setFocus(self, focus, rest):
        s = self.state
        if not s["deadline"] and 1 <= focus <= 120 and 1 <= rest <= 60:
            s["focus_minutes"], s["break_minutes"] = focus, rest
            self.focusAction("reset")

    @Slot(str, str)
    def addTask(self, title, minutes):
        title = title.strip()[:160]
        minutes = minutes.strip()
        if not title or (minutes and (not minutes.isdecimal() or not 1 <= int(minutes) <= 10080)):
            return
        due = int(time.time()) + int(minutes) * 60 if minutes else 0
        self.state["tasks"].append({"title": title, "due": due, "done": False, "notified": False})
        self.save()

    @Slot(int, bool)
    def markTask(self, index, done):
        if 0 <= index < len(self.state["tasks"]):
            self.state["tasks"][index]["done"] = done
            self.save()

    @Slot(int)
    def removeTask(self, index):
        if 0 <= index < len(self.state["tasks"]):
            self.state["tasks"].pop(index)
            self.save()

    @Property("QVariantList", notify=notesChanged)
    def notes(self):
        return [
            {**note, "title": note["text"].strip().split("\n", 1)[0] or "Catatan baru"}
            for note in self.state["notes"]
        ]

    @Slot(result=str)
    def newNote(self):
        note_id = uuid4().hex
        self.state["notes"].insert(0, {"id": note_id, "text": ""})
        self.save()
        self.notesChanged.emit()
        return note_id

    @Slot(str, str)
    def saveNote(self, note_id, text):
        notes = self.state["notes"]
        for i, note in enumerate(notes):
            if note["id"] == note_id and note["text"] != text:
                note["text"] = text
                notes.insert(0, notes.pop(i))
                self.save()
                self.notesChanged.emit()
                break

    @Slot(str)
    def removeNote(self, note_id):
        self.state["notes"] = [note for note in self.state["notes"] if note["id"] != note_id]
        self.save()
        self.notesChanged.emit()

    @Slot(str, bool)
    def setPrayer(self, city, alerts):
        if city in CITIES:
            self.state.update(city=city, prayer_alerts=alerts)
            self.save()

    @Slot(bool)
    def hideFullscreen(self, enabled):
        if self.state["hide_fullscreen"] != enabled:
            self.state["hide_fullscreen"] = enabled
            self.save()

    @Slot(str, bool)
    def setAppearance(self, option, enabled):
        if option in {"small_notch", "show_eyes", "show_battery", "animate_notch"}:
            self.state[option] = enabled
            self.save()

    @staticmethod
    def local_file(url):
        url = QUrl(url)
        path = Path(url.toLocalFile()) if url.isLocalFile() and url.host() in ("", "localhost") else None
        return path if path and path.is_absolute() and path.exists() else None

    @Slot("QVariantList", result=bool)
    def canDropFiles(self, urls):
        return any(self.local_file(url) for url in urls)

    @Slot("QVariantList", result=bool)
    def addFiles(self, urls):
        files = self.state["files"]
        paths = [str(path) for url in urls if (path := self.local_file(url))]
        new_files = list(dict.fromkeys(path for path in paths if path not in files))
        if new_files:
            files.extend(new_files)
            self.save()
        return bool(paths)

    @Slot(str)
    def removeFile(self, url):
        path = QUrl(url).toLocalFile()
        if path in self.state["files"]:
            self.state["files"].remove(path)
            self.save()

    @Slot(str)
    def openFile(self, url):
        if self.local_file(url):
            QDesktopServices.openUrl(QUrl(url))

    @Slot(QObject, str)
    def dragFile(self, source, url):
        if self.local_file(url):
            mime = QMimeData()
            mime.setUrls([QUrl(url)])
            drag = QDrag(source)
            drag.setMimeData(mime)
            drag.exec(Qt.DropAction.CopyAction)
            drag.deleteLater()
