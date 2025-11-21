#!/usr/bin/env python3
import time
import os
import socket
import subprocess
import psutil

from pathlib import Path

import board
import busio
from digitalio import DigitalInOut, Direction, Pull
from adafruit_ssd1306 import SSD1306_I2C
from PIL import Image, ImageDraw, ImageFont

MODE_FILE = Path("/tmp/mode")

def get_ip():
    try:
        # Use ip route to get default interface IP
        out = subprocess.check_output(
            "ip route get 1.1.1.1 | awk '{print $7; exit}'",
            shell=True,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return out or "0.0.0.0"
    except Exception:
        return "0.0.0.0"

def get_mode():
    try:
        if MODE_FILE.exists():
            return MODE_FILE.read_text().strip()
    except Exception:
        pass
    return "none"

def get_temp_c():
    try:
        out = subprocess.check_output(
            ["vcgencmd", "measure_temp"], text=True
        ).strip()
        # Example: temp=45.0'C
        if out.startswith("temp="):
            return float(out.split("=")[1].split("'")[0])
    except Exception:
        pass
    return 0.0

def main():
    # I2C + OLED init (assumes SSD1306 128x32 or 128x64 on default I2C pins)
    i2c = busio.I2C(board.SCL, board.SDA)
    width = 128
    height = 32
    oled = SSD1306_I2C(width, height, i2c)

    oled.fill(0)
    oled.show()

    image = Image.new("1", (width, height))
    draw = ImageDraw.Draw(image)

    # Use a basic built-in font
    font = ImageFont.load_default()

    while True:
        draw.rectangle((0, 0, width, height), outline=0, fill=0)

        cpu = psutil.cpu_percent(interval=None)
        mem = psutil.virtual_memory().percent
        temp = get_temp_c()
        mode = get_mode()
        ip = get_ip()

        # Line 1: Mode + CPU
        draw.text((0, 0), f"M:{mode[:6]} CPU:{cpu:3.0f}%", font=font, fill=255)
        # Line 2: Temp + Mem
        draw.text((0, 10), f"T:{temp:4.1f}C MEM:{mem:3.0f}%", font=font, fill=255)
        # Line 3: IP
        draw.text((0, 20), f"IP:{ip}", font=font, fill=255)

        oled.image(image)
        oled.show()

        time.sleep(1.0)

if __name__ == "__main__":
    main()
