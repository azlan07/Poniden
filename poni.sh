#!/bin/sh
cd -- "$(dirname -- "$0")" || exit 1
export QT_WAYLAND_SHELL_INTEGRATION=layer-shell
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"
export PYTHONDONTWRITEBYTECODE=1
exec /usr/bin/python3 ./poni.py
