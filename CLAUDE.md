# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Athena Deck v2** is a mode-switching command center for Raspberry Pi 5/4 with:
- FNK0100 800×480 DSI display (primary visual output)
- SSD1306 128×32 I²C OLED (status display)
- Pi Camera Module (for vision/HUD mode)

**Core Design Principle**: Single `mode` command controls all operational states. All functionality must integrate with this pattern, not bypass it.

## Architecture

### Mode System (Central Control)
- **Command**: `/usr/local/bin/mode` (installed from `services/mode/mode.sh`)
- **State File**: `/tmp/mode` - single source of truth for current operational mode
- **Behavior**: Each mode command stops conflicting services, writes mode name to `/tmp/mode`, then starts appropriate stack

Mode flow:
```
User runs: mode vision
  ↓
mode.sh stops all Docker stacks
  ↓
Writes "vision" to /tmp/mode
  ↓
Launches athena-vision script
  ↓
OLED reads /tmp/mode and displays "M:vision"
```

### Display Architecture
1. **Primary Display (FNK0100 DSI)**: 800×480 panel on `DSI-1` (DISPLAY=:0)
   - Vision mode uses `rpicam-hello --fullscreen` with X11/EGL preview
   - Must set `DISPLAY=:0` and `XAUTHORITY=/home/pi/.Xauthority` when calling from scripts/SSH

2. **Status Display (OLED)**: SSD1306 I²C at address 0x3C on I²C bus 1
   - Runs as systemd service: `oled.service`
   - Python script: `services/oled/oled_monitor.py`
   - Uses dedicated venv: `/home/pi/oledenv`
   - Polls `/tmp/mode` every 1 second to show current state

### Docker Stack Pattern
- Location: `docker/compose.[mode].yml`
- Controlled by: `services/mode/mode.sh`
- Pattern: Each mode file defines isolated service stack
- Current stacks:
  - `compose.ai.yml`: Ollama LLM server (port 11434)
  - `compose.proxy.yml`: Caddy reverse proxy (ports 80, 443)
  - `compose.dev.yml`: Placeholder for dev tools
  - `compose.red.yml`: Placeholder for red team tools

## Common Commands

### Mode Operations
```bash
# Switch modes (stops other stacks automatically)
mode vision    # Full-screen camera HUD
mode ai        # Start Ollama LLM
mode proxy     # Start Caddy reverse proxy
mode dev       # Development mode (placeholder)
mode red       # Red team mode (placeholder)
mode stop      # Stop all stacks
mode status    # Show current mode + running containers

# Check current mode
cat /tmp/mode
```

### OLED Service Management
```bash
# Check OLED status
sudo systemctl status oled.service

# Restart OLED display
sudo systemctl restart oled.service

# View live logs
journalctl -u oled.service -f

# Check I²C connection
sudo i2cdetect -y 1    # Should show 0x3C

# Reinstall OLED Python dependencies
source /home/pi/oledenv/bin/activate
pip install adafruit-blinka adafruit-circuitpython-ssd1306 pillow psutil
deactivate
sudo systemctl restart oled.service
```

### Camera/Vision Testing
```bash
# Test camera detection
rpicam-hello --list-cameras

# Test fullscreen preview manually (from SSH)
DISPLAY=:0 XAUTHORITY=/home/pi/.Xauthority rpicam-hello --fullscreen -t 0

# Test via athena-vision script
/usr/local/bin/athena-vision

# Stop camera preview
# Press Ctrl+C in terminal
```

### Docker Stack Management
```bash
# Manual stack control (mode command preferred)
cd /home/pi/athena-deck-v2/docker
docker compose -f compose.ai.yml up -d
docker compose -f compose.ai.yml down

# Check running containers
docker ps

# View logs
docker compose -f compose.ai.yml logs -f
```

### Installation
```bash
# Full system install (run once)
cd /home/pi/athena-deck-v2
sudo bash scripts/install_athena_deck.sh

# After install: log out/in or reboot for docker group to take effect
```

## Key Implementation Rules

### When Modifying Mode System
1. **Never bypass the mode command** - all new operational states must integrate as new mode cases
2. **Always update /tmp/mode** - this is the contract with the OLED and status system
3. **Stop conflicting stacks** - call `stop_all()` before starting new mode's services
4. **Follow the pattern**: Add case to `mode.sh`, create `compose.[newmode].yml` if using Docker

### When Working with Displays
1. **FNK0100 (Primary)**: Assumes X11 session on DISPLAY=:0
   - Camera preview requires: `DISPLAY=:0 XAUTHORITY=/home/pi/.Xauthority`
   - Target resolution: 800×480
   - Use `--fullscreen` flag for borderless rendering

2. **OLED (Status)**: Never modify OLED code to change mode - it only reads `/tmp/mode`
   - OLED update cycle: 1 second
   - Resolution: 128×32 pixels
   - I²C bus: 1 (GPIO 2/3)

### When Adding Docker Services
1. Create or extend `docker/compose.[mode].yml`
2. Use relative paths from `docker/` directory
3. Add persistent volumes for stateful services (follow Ollama pattern)
4. Update `mode.sh` case statement if adding new mode
5. Document exposed ports in compose file comments

### Hardware Assumptions
- **Board**: Raspberry Pi 5 (preferred) or Pi 4
- **OS**: Raspberry Pi OS (Debian Trixie) with desktop/X11
- **Camera**: Pi Camera Module (enabled via `raspi-config`)
- **I²C**: Enabled via `raspi-config` (bus 1, GPIO 2/3)
- **User**: `pi` with sudo access and docker group membership

### Python Virtual Environment
- OLED service uses dedicated venv at `/home/pi/oledenv`
- When editing OLED code, test with: `source /home/pi/oledenv/bin/activate`
- Systemd service automatically uses venv via `Environment="PATH=..."`

## Troubleshooting Patterns

### Camera Preview Issues
1. Verify X11 running: `ps aux | grep Xorg`
2. Check DISPLAY variable: `echo $DISPLAY` (set to `:0` if empty)
3. Test camera: `rpicam-hello --list-cameras`
4. Ensure running from graphical session (not pure SSH without X forwarding)

### OLED Not Updating
1. Check service running: `sudo systemctl status oled.service`
2. Verify I²C device: `sudo i2cdetect -y 1`
3. Check permissions: OLED service runs as user `pi`
4. View errors: `journalctl -u oled.service -n 50`

### Docker Permission Errors
1. Verify group membership: `groups | grep docker`
2. If missing: logout/login or reboot after install
3. Manual add: `sudo usermod -aG docker pi`

### Mode Not Switching
1. Check mode file: `cat /tmp/mode`
2. Verify mode script installed: `which mode`
3. Check Docker Compose installed: `docker compose version`
4. Ensure mode.sh has execute permissions: `ls -la /usr/local/bin/mode`

## File Locations (Post-Install)

| Component | Source Path | Installed Path |
|-----------|-------------|----------------|
| Mode command | `services/mode/mode.sh` | `/usr/local/bin/mode` |
| Vision script | `bin/athena-vision` | `/usr/local/bin/athena-vision` |
| OLED service | `services/oled/oled.service` | `/etc/systemd/system/oled.service` |
| OLED script | `services/oled/oled_monitor.py` | (runs from project dir) |
| Python venv | N/A | `/home/pi/oledenv` |
| State file | N/A | `/tmp/mode` |

## Extending the System

### Adding a New Mode
1. Create Docker stack: `docker/compose.newmode.yml`
2. Edit `services/mode/mode.sh`:
   ```bash
   newmode)
     stop_all
     set_mode "newmode"
     echo "Current mode set to: newmode"
     if [ -f "$COMPOSE_DIR/compose.newmode.yml" ]; then
       (cd "$COMPOSE_DIR" && $COMPOSE -f compose.newmode.yml up -d)
     fi
     ;;
   ```
3. Update usage function in `mode.sh`
4. Test: `mode newmode`, then `mode status`
5. OLED will automatically display "M:newmode"

### Modifying Vision HUD
- Edit `bin/athena-vision` to change camera parameters
- Available `rpicam-hello` flags: `--width`, `--height`, `--rotation`, `--timeout`
- Keep `--fullscreen` for borderless display
- Keep `DISPLAY=:0` and `XAUTHORITY` exports for X11 binding

### Customizing OLED Display
- Edit `services/oled/oled_monitor.py`
- Display dimensions: 128×32 pixels (3-4 lines of text max)
- Current layout: Mode, CPU, Temp, Memory, IP
- After changes: `sudo systemctl restart oled.service`
