# PyAlert rebuilt installer

This package installs:
- a background daemon using `systemd --user`
- shell hooks for bash and zsh
- support for commands like:
  - `python3 ll.py`
  - `python ll.py`
  - `/home/mazo/.local/bin/python3.14 ll.py`

It sends `E` over the Unix socket to the daemon, and the daemon writes `b"E"` to the Arduino serial port.

Install:
```bash
bash install.sh
```

Uninstall:
```bash
bash uninstall.sh
```
