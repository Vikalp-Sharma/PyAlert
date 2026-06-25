#!/usr/bin/env python3
"""
PyAlert daemon: listens on a Unix socket and sends b"E" to Arduino over serial.
Keeps running in the background as a user service.
"""

from __future__ import annotations

import glob
import os
import socket
import sys
import time
from typing import Optional

try:
    import serial  # type: ignore
except Exception:
    print("[PyAlert] pyserial is missing. Install with: pip install pyserial", file=sys.stderr)
    sys.exit(1)

SOCKET_PATH = "/tmp/pyalert.sock"
BAUD_RATE = 9600
BOOT_WAIT = 2.0
RETRY_SECONDS = 2.0


def find_arduino_port() -> Optional[str]:
    patterns = (
        "/dev/ttyACM*",
        "/dev/ttyUSB*",
        "/dev/cu.usbmodem*",
        "/dev/cu.usbserial*",
    )
    candidates: list[str] = []
    for pattern in patterns:
        candidates.extend(sorted(glob.glob(pattern)))
    return candidates[0] if candidates else None


def open_serial():
    port = find_arduino_port()
    if not port:
        return None, None
    try:
        ser = serial.Serial(port, BAUD_RATE, timeout=1)
        time.sleep(BOOT_WAIT)
        print(f"[PyAlert] Connected to Arduino on {port}")
        return ser, port
    except Exception as exc:
        print(f"[PyAlert] Serial open failed on {port}: {exc}")
        return None, None


def ensure_serial(state):
    ser, port = state["ser"], state["port"]
    if ser is not None:
        try:
            if ser.is_open:
                return state
        except Exception:
            pass
        try:
            ser.close()
        except Exception:
            pass
        state["ser"] = None
        state["port"] = None

    ser, port = open_serial()
    state["ser"] = ser
    state["port"] = port
    return state


def send_alert(state):
    ensure_serial(state)
    ser = state["ser"]
    if ser is None:
        print("[PyAlert] No Arduino found; alert not sent.")
        return

    try:
        ser.write(b"E")
        ser.flush()
        print("[PyAlert] E sent to Arduino.")
    except Exception as exc:
        print(f"[PyAlert] Serial write failed: {exc}")
        try:
            ser.close()
        except Exception:
            pass
        state["ser"] = None
        state["port"] = None


def make_socket():
    if os.path.exists(SOCKET_PATH):
        try:
            os.unlink(SOCKET_PATH)
        except Exception:
            pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(8)
    os.chmod(SOCKET_PATH, 0o777)
    return server


def main():
    state = {"ser": None, "port": None}
    server = make_socket()
    print(f"[PyAlert] Listening on {SOCKET_PATH}")
    
    last_alert_time = 0.0

    try:
        while True:
            conn, _ = server.accept()
            try:
                data = conn.recv(16)
                if data:
                    now = time.time()
                    if now - last_alert_time > 1.0:
                        send_alert(state)
                        last_alert_time = time.time()
                    else:
                        print("[PyAlert] Ignored duplicate alert (debounce).")
            except Exception as exc:
                print(f"[PyAlert] Socket handling error: {exc}")
            finally:
                try:
                    conn.close()
                except Exception:
                    pass
    except KeyboardInterrupt:
        print("[PyAlert] Shutting down.")
    finally:
        try:
            server.close()
        except Exception:
            pass
        if os.path.exists(SOCKET_PATH):
            try:
                os.unlink(SOCKET_PATH)
            except Exception:
                pass
        if state["ser"] is not None:
            try:
                state["ser"].close()
            except Exception:
                pass


if __name__ == "__main__":
    main()
