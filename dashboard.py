import json
import time
from urllib.parse import urlencode

from PySide6.QtCore import QObject, Property, QSettings, QUrl, Signal, Slot
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkReply, QNetworkRequest

from activities import CITIES


def weather_label(code):
    if code == 0:
        return "Cerah"
    if code in (1, 2):
        return "Cerah berawan"
    if code == 3:
        return "Berawan"
    if code in (45, 48):
        return "Berkabut"
    if 51 <= code <= 57:
        return "Gerimis"
    if 71 <= code <= 77 or code in (85, 86):
        return "Salju"
    if 61 <= code <= 67 or 80 <= code <= 82:
        return "Hujan"
    return "Badai petir" if code >= 95 else "Cuaca terkini"


class Dashboard(QObject):
    changed = Signal()

    def __init__(self):
        super().__init__()
        self.settings = QSettings("Poni", "Dashboard")
        self.location = None
        self.network = None
        self.weather_reply = None
        self.location_reply = None
        self.weather = None
        self.refresh_at = 0
        self.weather_status = ""
        self.location_status = ""
        self.fallback_city = "Jakarta"
        try:
            saved = json.loads(self.settings.value("location", "null"))
            if saved:
                self.location = self.valid_location(*saved)
        except (ValueError, TypeError):
            pass

    @staticmethod
    def valid_location(city, lat, lon, approximate):
        lat, lon = float(lat), float(lon)
        if isinstance(city, str):
            city = city.strip()
            if (0 < len(city) <= 80 and all(char.isalnum() or char in " .,'-’" for char in city)
                    and -90 <= lat <= 90 and -180 <= lon <= 180):
                return city, round(lat, 3), round(lon, 3), bool(approximate)
        raise ValueError("Lokasi tidak valid")

    @Property("QVariantMap", notify=changed)
    def view(self):
        city, _, _, approximate = self.coordinates()
        return {
            "city": city, "approximate": approximate,
            "temperature": self.weather[0] if self.weather else None,
            "condition": self.weather[1] if self.weather else "",
            "weatherStatus": self.weather_status, "locationStatus": self.location_status,
            "locating": self.location_reply is not None,
        }

    def coordinates(self):
        lat, lon, _ = CITIES[self.fallback_city]
        return self.location or (self.fallback_city, lat, lon, False)

    def request(self, url):
        if self.network is None:
            self.network = QNetworkAccessManager(self)
        request = QNetworkRequest(QUrl(url))
        request.setTransferTimeout(8000)
        return self.network.get(request)

    @staticmethod
    def payload(reply):
        if reply.error() != QNetworkReply.NetworkError.NoError:
            return {}
        try:
            return json.loads(bytes(reply.readAll()))
        except ValueError:
            return {}

    @Slot(str)
    def open(self, fallback_city):
        if fallback_city in CITIES and fallback_city != self.fallback_city:
            self.fallback_city = fallback_city
            if self.location is None:
                self.reset_weather()
        self.refresh()

    def reset_weather(self):
        old, self.weather_reply = self.weather_reply, None
        if old:
            old.abort()
        self.weather = None
        self.refresh_at = 0

    def use_location(self, location):
        if location != self.location:
            self.location = location
            self.settings.setValue("location", json.dumps(location))
            self.reset_weather()
        self.location_status = ""
        self.refresh()

    @Slot(str)
    def selectCity(self, city):
        if city in CITIES:
            old, self.location_reply = self.location_reply, None
            if old:
                old.abort()
            lat, lon, _ = CITIES[city]
            self.use_location(self.valid_location(city, lat, lon, False))

    @Slot()
    def detect(self):
        if self.location_reply is not None:
            return
        reply = self.request("https://ipapi.co/json/")
        self.location_reply = reply
        self.location_status = "Mendeteksi kota…"
        self.changed.emit()

        def finished():
            if self.location_reply != reply:
                reply.deleteLater()
                return
            self.location_reply = None
            try:
                result = self.payload(reply)
                location = self.valid_location(result["city"], result["latitude"], result["longitude"], True)
            except (KeyError, TypeError, ValueError):
                self.location_status = "Lokasi IP tidak tersedia. Pilih kota."
                self.changed.emit()
            else:
                self.use_location(location)
            reply.deleteLater()

        reply.finished.connect(finished)

    @Slot()
    def refresh(self):
        if self.weather_reply is not None:
            return
        if time.monotonic() < self.refresh_at:
            self.changed.emit()
            return
        _, lat, lon, _ = self.coordinates()
        query = urlencode({"latitude": lat, "longitude": lon, "current": "temperature_2m,weather_code"})
        reply = self.request("https://api.open-meteo.com/v1/forecast?" + query)
        self.weather_reply = reply
        self.weather_status = "Memuat cuaca…"
        self.changed.emit()

        def finished():
            if self.weather_reply == reply:
                self.weather_reply = None
                try:
                    current = self.payload(reply)["current"]
                    temperature = round(float(current["temperature_2m"]))
                    self.weather = temperature, weather_label(int(current["weather_code"]))
                except (KeyError, TypeError, ValueError, OverflowError):
                    self.weather_status = "Cuaca tidak tersedia"
                    self.refresh_at = time.monotonic() + 60
                else:
                    self.refresh_at = time.monotonic() + 900
                    self.weather_status = ""
                self.changed.emit()
            reply.deleteLater()

        reply.finished.connect(finished)
