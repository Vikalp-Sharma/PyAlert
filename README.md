<div align="center">

```text
    ██████╗ ██╗   ██╗ █████╗ ██╗     ███████╗██████╗ ████████╗
    ██╔══██╗╚██╗ ██╔╝██╔══██╗██║     ██╔════╝██╔══██╗╚══██╔══╝
██████╔╝ ╚████╔╝ ███████║██║     █████╗  ██████╔╝   ██║
██╔═══╝   ╚██╔╝  ██╔══██║██║     ██╔══╝  ██╔══██╗   ██║
██║        ██║   ██║  ██║███████╗███████╗██║  ██║   ██║
╚═╝        ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝
```

### Python Error Alert System for Arduino

Detect Python crashes automatically and trigger a **servo movement** and **audio alert** on an Arduino.

![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Linux-supported-blue)
![Python](https://img.shields.io/badge/Python-3.x-yellow)
![Arduino](https://img.shields.io/badge/Arduino-Compatible-teal)
![systemd](https://img.shields.io/badge/systemd-user-orange)

</div>

---

# ✨ Features

* 🚨 Detects failed Python scripts automatically
* 🔌 Sends events to Arduino over Serial
* 🔔 Plays alert audio using DFPlayer Mini
* ⚙️ Runs as a `systemd --user` daemon
* 🐍 Supports:

  * `python file.py`
  * `python3 file.py`
  * `/path/to/python file.py`
  * virtual environments
* 🖥️ Bash support
* 🖥️ Zsh support
* 🎯 Lightweight and fast

---

# 📸 Hardware Setup

> Add your hardware image here:

```md
![PyAlert Setup](images/setup.jpg)
```

Example:

```
PyAlert/
├── images/
│   └── setup.jpg
└── README.md
```

---

# 🔧 Arduino Pins

```cpp
#define SERVO_PIN   9

#define DF_RX_PIN   10   // Arduino RX  <- DFPlayer TX
#define DF_TX_PIN   11   // Arduino TX  -> DFPlayer RX
```

---

# 🔌 Wiring Diagram

```text
                     Arduino

                +-------------+
                |             |
Servo Signal ---| D9          |
DFPlayer TX ----| D10         |
DFPlayer RX ----| D11         |
5V -------------| 5V          |
GND ------------| GND         |
                +-------------+
                       |
         +-------------+-------------+
         |                           |
         ▼                           ▼

     +--------+              +--------------+
     | Servo  |              | DFPlayer Mini|
     +--------+              +--------------+
                                    |
                                    ▼
                                Speaker
```

---

# 🎵 Audio Requirements

Place an audio file named:

```text
0001.mp3
```

in the root of the microSD card.

### Requirements

* Filename must be exactly:

```text
0001.mp3
```

* Stored in root directory
* MP3 format
* Under 4 seconds long

### Example SD Card

```text
SD Card
│
└── 0001.mp3
```

---

# ⚡ Installation

Copy and paste:

```bash
git clone https://github.com/YOUR_USERNAME/PyAlert.git
cd PyAlert

bash install.sh
```

Reload your shell:

```bash
source ~/.bashrc
```

or

```bash
source ~/.zshrc
```

Verify the service:

```bash
systemctl --user status pyalert.service --no-pager
```

---

# 🗑️ Uninstallation

```bash
bash uninstall.sh
```

---

# 🏗️ Architecture

```text
┌─────────────┐
│ Python App  │
└──────┬──────┘
       │ Error
       ▼
┌─────────────┐
│ Shell Hook  │
└──────┬──────┘
       │ "E"
       ▼
┌─────────────┐
│ Unix Socket │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│  PyAlert Daemon  │
└──────┬───────────┘
       │ b"E"
       ▼
┌──────────────────┐
│     Arduino      │
└───┬──────────┬───┘
    │          │
    ▼          ▼
 Servo      DFPlayer
              │
              ▼
           Speaker
```

---

# 🧪 Test

Create a file:

```python
raise Exception("PyAlert Test")
```

Run:

```bash
python3 test.py
```

Expected:

* Servo moves
* Audio plays
* Arduino receives `b"E"`

---

# 📁 Project Structure

```text
PyAlert/
├── install.sh
├── uninstall.sh
├── pyalert_daemon.py
├── README.md
├── images/
│   └── setup.jpg
└── shell_hooks/
    ├── bash_hook.sh
    └── zsh_hook.sh
```

---

# 🤝 Contributing

Pull requests are welcome.

For major changes, please open an issue first to discuss what you would like to change.

---

# 📄 License

License © Mazoitch

---

<div align="center">

### ⭐ If you find PyAlert useful, consider starring the repository ⭐

</div>
