#!/usr/bin/env bash
set -e

PROJECT_ROOT="/home/pi/athena-deck-v2"
COMPOSE_DIR="$PROJECT_ROOT/docker"

echo "[1/6] Installing base packages..."
sudo apt update
sudo apt install -y \
  python3-venv python3-pip \
  python3-opencv \
  python3-libcamera \
  python3-pil python3-psutil \
  i2c-tools \
  docker.io

echo "[2/6] Adding 'pi' to docker group (log out/in or reboot to take effect)..."
sudo usermod -aG docker pi || true

echo "[3/6] Creating OLED Python venv..."
cd /home/pi
python3 -m venv oledenv
source /home/pi/oledenv/bin/activate
pip install --upgrade pip
pip install adafruit-blinka adafruit-circuitpython-ssd1306 pillow psutil
deactivate

echo "[4/6] Enabling I2C via raspi-config (non-interactive)..."
# This enables I2C in /boot/firmware/config.txt using raspi-config batch mode
sudo raspi-config nonint do_i2c 0 || true

echo "[5/6] Installing Athena scripts (mode + athena-vision)..."
sudo cp "$PROJECT_ROOT/bin/athena-vision" /usr/local/bin/athena-vision
sudo chmod +x /usr/local/bin/athena-vision

sudo cp "$PROJECT_ROOT/services/mode/mode.sh" /usr/local/bin/mode
sudo chmod +x /usr/local/bin/mode

echo "[6/6] Installing OLED systemd service..."
sudo cp "$PROJECT_ROOT/services/oled/oled.service" /etc/systemd/system/oled.service
sudo systemctl daemon-reload
sudo systemctl enable oled.service
sudo systemctl start oled.service

echo
echo "Done."
echo "- Use 'mode vision' for full-screen camera HUD."
echo "- OLED should now show mode + system stats."
