#!/usr/bin/env bash
# Install Athena Deck mode switcher icons to Desktop
# This script deploys .desktop launchers and icons for easy mode switching

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="/home/pi/Desktop"
ICONS_DIR="$SCRIPT_DIR/icons"

echo "=== Athena Deck Desktop Icons Installer ==="
echo

# Verify Desktop directory exists
if [ ! -d "$DESKTOP_DIR" ]; then
    echo "Creating Desktop directory..."
    mkdir -p "$DESKTOP_DIR"
fi

# Copy .desktop files to Desktop
echo "Installing mode switcher icons..."
for mode in vision ai dev red retro proxy stop; do
    if [ -f "$SCRIPT_DIR/${mode}.desktop" ]; then
        cp "$SCRIPT_DIR/${mode}.desktop" "$DESKTOP_DIR/"
        chmod +x "$DESKTOP_DIR/${mode}.desktop"
        echo "  - ${mode}.desktop installed"
    else
        echo "  ! Warning: ${mode}.desktop not found"
    fi
done

echo
echo "Desktop icons installed to: $DESKTOP_DIR"
echo "Icon assets located at: $ICONS_DIR"
echo
echo "You can now click the mode icons on your desktop to switch modes."
echo "Icons will appear as large colored buttons with labels."
echo
