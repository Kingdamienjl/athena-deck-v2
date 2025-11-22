# Athena Deck v2 – Raspberry Pi Tactical HUD System

**A mode-switching command center for Raspberry Pi with FNK0100 800×480 DSI display and SSD1306 OLED status monitor.**

---

## System Overview

Athena Deck provides:

- **Mode Switching**: Single command to switch between operational modes
- **Full-Screen Camera HUD**: Direct framebuffer rendering on DSI display
- **OLED Status Display**: Real-time system metrics (mode, CPU, temp, RAM, IP)
- **Docker Stacks**: Containerized environments for AI, development, proxy, and red team work

---

## Hardware Requirements

- Raspberry Pi 4/5
- FNK0100 800×480 DSI touchscreen (primary display)
- SSD1306 128×32 I2C OLED display (0x3C address)
- Pi Camera Module (for vision mode)

---

## Installation

```bash
cd /home/pi
unzip athena-deck-v2.zip -d athena-deck-v2
cd athena-deck-v2
chmod +x scripts/install_athena_deck.sh
sudo bash scripts/install_athena_deck.sh
```

**Post-install:**
- Log out and back in (or reboot) for Docker group permissions to take effect
- I2C will be enabled automatically
- OLED service starts on boot

---

## Desktop Mode Switcher

**Large clickable icons for easy mode switching on the DSI touchscreen.**

Located in `desktop/` directory. Install with:

```bash
cd /home/pi/athena-deck-v2/desktop
bash install-desktop-icons.sh
```

**Features:**
- 7 large mode icons (Vision, AI, Dev, Red, Retro, Proxy, Stop)
- Color-coded with distinctive symbols
- One-click mode switching
- Works alongside command-line `mode` command

See `desktop/README.md` for details.

---

## Mode Command Reference

### Available Modes

| Command | Description | Action |
|---------|-------------|--------|
| `mode vision` | Camera HUD | Full-screen camera with object detection, face detection, OCR, and crosshairs |
| `mode ai` | AI Stack | Ollama LLM server (port 11434) |
| `mode dev` | Development | Placeholder for dev tools |
| `mode red` | Red Team | Kali Linux container for security tools |
| `mode retro` | Retro Gaming | RetroArch emulator for classic games |
| `mode proxy` | Reverse Proxy | Caddy server (ports 80/443) |
| `mode stop` | Shutdown | Stop all containers and services |
| `mode status` | Status Check | Display current mode and running containers |

### Usage Examples

```bash
# Start camera HUD
mode vision

# Switch to AI mode
mode ai

# Check what's running
mode status

# Stop everything
mode stop
```

---

## Docker Compose Stacks

Located in `docker/`:

### `compose.ai.yml`
- **Service**: Ollama (LLM inference server)
- **Port**: 11434
- **Volume**: Persistent model storage in `ollama_data`
- **Use case**: Run local language models

### `compose.proxy.yml`
- **Service**: Caddy (reverse proxy)
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Volumes**: `caddy_data`, `caddy_config` (persistent)
- **Use case**: SSL/TLS termination, routing

### `compose.dev.yml`
- **Service**: Alpine container (placeholder)
- **Status**: Placeholder for development tools
- **Logs**: "Athena Dev Mode" every 60s

### `compose.red.yml`
- **Service**: Alpine container (placeholder)
- **Status**: Placeholder for security/pentesting tools
- **Logs**: "Red Team Sandbox" every 60s

---

## OLED Status Display

**Auto-starts on boot** via systemd service.

**Display Layout** (128×32 SSD1306):
```
Line 1: M:[mode] CPU:[%]
Line 2: T:[°C] MEM:[%]
Line 3: IP:[address]
```

**Service Control:**
```bash
# Check status
sudo systemctl status oled

# Restart
sudo systemctl restart oled

# View logs
journalctl -u oled -f
```

---

## Vision Mode Technical Details

**Script**: `/usr/local/bin/athena-vision-detect`

**Key Features:**
- **Object Detection**: MobileNet SSD identifies 20+ object classes (person, car, bottle, etc.)
- **Face Detection**: Haar Cascade fast face recognition
- **OCR Text Detection**: Tesseract reads text in camera view
- **Crosshairs Overlay**: Center-screen targeting reticle
- **Full-Screen HUD**: 800×480 OpenCV window on FNK0100 DSI display
- **Real-Time Stats**: FPS, detection counts displayed on screen

**Interactive Controls:**
- `q` - Quit vision mode
- `f` - Toggle face detection on/off
- `o` - Toggle object detection on/off
- `t` - Toggle OCR text detection on/off
- `c` - Toggle crosshairs on/off

**How it works:**
1. Uses Picamera2 for camera capture at 800×480
2. Processes frames with OpenCV computer vision
3. MobileNet SSD for object detection
4. Haar Cascade for face detection
5. Tesseract for OCR text recognition
6. Renders fullscreen with detection overlays

**Requirements:**
- Tesseract OCR: `sudo apt install tesseract-ocr`
- MobileNet models: Run `/home/pi/athena-deck-v2/scripts/download_models.py`
- OpenCV and dependencies (auto-installed)

---

## File Structure

```
athena-deck-v2/
├── bin/
│   └── athena-vision          # Camera HUD launcher script
├── desktop/
│   ├── icons/                 # SVG icons for mode switcher
│   │   ├── vision.svg
│   │   ├── ai.svg
│   │   ├── dev.svg
│   │   ├── red.svg
│   │   ├── retro.svg
│   │   ├── proxy.svg
│   │   └── stop.svg
│   ├── *.desktop              # Desktop launcher files (7 modes)
│   ├── install-desktop-icons.sh  # Desktop icons installer
│   └── README.md              # Desktop switcher docs
├── docker/
│   ├── compose.ai.yml         # Ollama AI stack
│   ├── compose.dev.yml        # Development placeholder
│   ├── compose.red.yml        # Red team placeholder
│   └── compose.proxy.yml      # Caddy reverse proxy
├── scripts/
│   └── install_athena_deck.sh # System installation script
├── services/
│   ├── mode/
│   │   └── mode.sh            # Mode switching logic
│   └── oled/
│       ├── oled_monitor.py    # OLED display driver
│       └── oled.service       # Systemd service unit
└── README.md
```

---

## Customizing Docker Stacks

To modify or extend the Docker stacks:

1. Edit the compose file in `docker/`
2. Test manually:
   ```bash
   cd docker
   docker compose -f compose.ai.yml up -d
   ```
3. Use `mode [name]` to switch via the mode command

**Adding new services:**
- Add to existing compose files or create new ones
- Follow naming convention: `compose.[mode].yml`
- Update `mode.sh` if adding new modes

---

## Troubleshooting

### Vision mode shows window instead of fullscreen
- Verify `/usr/local/bin/athena-vision` uses `--drm-preview` (not `--qt-preview`)
- Check DSI display is detected: `xrandr | grep DSI-1`

### OLED not displaying
- Check I2C enabled: `ls /dev/i2c-*`
- Detect OLED address: `sudo i2cdetect -y 1` (should show 0x3C)
- Check service: `sudo systemctl status oled`

### Docker permission denied
- Ensure user is in docker group: `groups | grep docker`
- Log out and back in, or reboot

### Camera not detected
- Check camera connection: `rpicam-hello --list-cameras`
- Verify camera enabled in `raspi-config`

---

## State Management

- Current mode stored in: `/tmp/mode`
- Read via: `cat /tmp/mode`
- Modified by: `mode [command]`

---

## Development Notes

**Extending the system:**
- Docker stacks are intentionally minimal
- `dev` and `red` modes are placeholders for custom tooling
- Add your own services to compose files as needed

**Vision HUD customization:**
- Modify `bin/athena-vision` to change camera parameters
- See `rpicam-hello --help` for available options
- Consider `rpicam-vid` for video recording

---

## Credits

Built for FNK0100 DSI display + Raspberry Pi tactical computing.

**Components:**
- `rpicam-hello`: Raspberry Pi camera preview tool
- Docker Compose: Container orchestration
- Adafruit SSD1306: OLED driver library
- Caddy: Modern reverse proxy
- Ollama: Local LLM inference
