#!/usr/bin/env python3
"""Send one alert byte to the local PyAlert daemon socket."""
from __future__ import annotations

import socket
import sys

SOCKET_PATH = "/tmp/pyalert.sock"


def main() -> int:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            s.connect(SOCKET_PATH)
            s.sendall(b"E")
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
