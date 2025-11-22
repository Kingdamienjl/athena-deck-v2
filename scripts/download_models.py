#!/usr/bin/env python3
"""
Download pre-trained models for Athena Vision Detection
Downloads MobileNet SSD model for object detection
"""

import urllib.request
import os
import sys

MODEL_DIR = "/home/pi/athena-deck-v2/models"

# MobileNet SSD model files
MODELS = {
    "MobileNetSSD_deploy.prototxt": "https://raw.githubusercontent.com/chuanqi305/MobileNet-SSD/master/deploy.prototxt",
    "MobileNetSSD_deploy.caffemodel": "https://github.com/chuanqi305/MobileNet-SSD/raw/master/mobilenet_iter_73000.caffemodel"
}

def download_file(url, dest_path):
    """Download a file with progress indication"""
    print(f"Downloading {os.path.basename(dest_path)}...")

    def progress_hook(count, block_size, total_size):
        percent = int(count * block_size * 100 / total_size)
        sys.stdout.write(f"\r  Progress: {percent}%")
        sys.stdout.flush()

    try:
        urllib.request.urlretrieve(url, dest_path, progress_hook)
        print(f"\n✓ Downloaded to {dest_path}")
        return True
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Athena Vision Detection - Model Downloader")
    print("=" * 60)
    print()

    # Create models directory
    if not os.path.exists(MODEL_DIR):
        os.makedirs(MODEL_DIR)
        print(f"✓ Created directory: {MODEL_DIR}")

    # Download models
    success = True
    for filename, url in MODELS.items():
        dest_path = os.path.join(MODEL_DIR, filename)

        # Skip if already exists
        if os.path.exists(dest_path):
            print(f"✓ {filename} already exists, skipping.")
            continue

        if not download_file(url, dest_path):
            success = False

    print()
    if success:
        print("=" * 60)
        print("✓ All models downloaded successfully!")
        print("=" * 60)
        print()
        print("Object detection is now ready to use.")
        print("Run: mode vision-detect")
    else:
        print("=" * 60)
        print("✗ Some downloads failed.")
        print("=" * 60)
        print()
        print("Please check your internet connection and try again.")
        sys.exit(1)

if __name__ == "__main__":
    main()
