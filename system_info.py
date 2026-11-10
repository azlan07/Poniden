import os
import shutil
import time
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot


def read_text(path):
    try:
        return Path(path).read_text()
    except OSError:
        return ""


class SystemInfo(QObject):
    changed = Signal()

    def __init__(self):
        super().__init__()
        self.snapshot = {}
        self.previous = None

    @Property("QVariantMap", notify=changed)
    def view(self):
        return self.snapshot

    @Slot()
    def resetSample(self):
        self.previous = None
        self.refresh()

    @Slot()
    def refresh(self):
        clock = time.monotonic()
        cpu_line = read_text("/proc/stat").splitlines()
        ticks = [int(value) for value in cpu_line[0].split()[1:9]] if cpu_line else [0] * 8
        total, idle = sum(ticks), sum(ticks[3:5])
        memory = {row.split(":")[0]: int(row.split()[1]) for row in
                  read_text("/proc/meminfo").splitlines() if row.startswith(("MemTotal:", "MemAvailable:"))}
        mem_total = memory.get("MemTotal", 0)
        mem_used = max(0, mem_total - memory.get("MemAvailable", mem_total))
        disk = shutil.disk_usage("/")
        counters = {}
        for row in read_text("/proc/net/dev").splitlines()[2:]:
            name, _, values = row.partition(":")
            if (Path("/sys/class/net") / name.strip() / "device").exists():
                fields = values.split()
                counters[name] = (int(fields[0]), int(fields[8]))

        cpu = down = up = 0
        sampled = self.previous is not None and bool(cpu_line)
        if self.previous:
            then, old_total, old_idle, old_counters = self.previous
            if total > old_total:
                cpu = 100 * (1 - (idle - old_idle) / (total - old_total))
            for name in counters.keys() & old_counters.keys():
                elapsed = max(0.001, clock - then)
                down += max(0, counters[name][0] - old_counters[name][0]) / elapsed
                up += max(0, counters[name][1] - old_counters[name][1]) / elapsed
        self.previous = clock, total, idle, counters

        temperatures = []
        for sensor in Path("/sys/class/hwmon").glob("hwmon*"):
            if read_text(sensor / "name").strip() in {"coretemp", "k10temp", "zenpower", "cpu_thermal"}:
                for probe in sensor.glob("temp*_input"):
                    value = read_text(probe).strip()
                    if value.lstrip("-").isdigit():
                        temperatures.append(int(value) / 1000)

        snapshot = {
            "cpu": round(max(0, min(100, cpu))),
            "threads": os.cpu_count() or 0,
            "memory": round(100 * mem_used / mem_total) if mem_total else 0,
            "memoryUsed": mem_used / 1024**2,
            "memoryTotal": mem_total / 1024**2,
            "disk": round(100 * disk.used / disk.total) if disk.total else 0,
            "diskFree": disk.free / 1024**3,
            "down": round(down),
            "up": round(up),
            "networkAvailable": bool(counters),
            "temperature": round(max(temperatures)) if temperatures else None,
            "sampled": sampled,
        }
        if snapshot != self.snapshot:
            self.snapshot = snapshot
            self.changed.emit()
