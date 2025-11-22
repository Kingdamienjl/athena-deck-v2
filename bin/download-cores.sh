#!/usr/bin/env bash
# Download popular RetroArch cores directly from buildbot

set -e

echo "========================================="
echo "RetroArch Core Downloader for Athena Deck"
echo "========================================="
echo ""
echo "This will download popular emulator cores"
echo "from the RetroArch buildbot directly."
echo ""

# Detect architecture
ARCH="aarch64"  # Raspberry Pi 5/4 is 64-bit ARM
BUILDBOT_URL="https://buildbot.libretro.com/nightly/linux/${ARCH}/latest"

# Get the Docker volume path for cores
CORE_DIR="/var/lib/docker/volumes/athena_retroarch_config/_data/retroarch/cores"

# Create cores directory if it doesn't exist
sudo mkdir -p "$CORE_DIR"

# List of popular cores with their exact filenames
declare -A CORES=(
    ["mgba_libretro.so.zip"]="Game Boy / GBC / GBA"
    ["nestopia_libretro.so.zip"]="NES (Nintendo)"
    ["snes9x_libretro.so.zip"]="SNES (Super Nintendo)"
    ["genesis_plus_gx_libretro.so.zip"]="Genesis / Mega Drive"
    ["mupen64plus_next_libretro.so.zip"]="Nintendo 64"
    ["pcsx_rearmed_libretro.so.zip"]="PlayStation 1"
    ["fbneo_libretro.so.zip"]="Arcade (FinalBurn Neo)"
    ["stella_libretro.so.zip"]="Atari 2600"
    ["prosystem_libretro.so.zip"]="Atari 7800"
    ["gambatte_libretro.so.zip"]="Game Boy / GBC (alt)"
)

# Download and extract cores
echo "Downloading cores from RetroArch buildbot..."
echo ""

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

for core in "${!CORES[@]}"; do
    echo "→ Downloading: ${CORES[$core]} ($core)"

    if wget -q --show-progress "${BUILDBOT_URL}/${core}" 2>&1; then
        # Extract the .so file
        unzip -q -o "$core"
        CORE_FILE="${core%.zip}"

        # Move to cores directory
        sudo mv "$CORE_FILE" "$CORE_DIR/" 2>/dev/null || true
        sudo chmod 644 "$CORE_DIR/$CORE_FILE" 2>/dev/null || true

        echo "  ✓ Installed: $CORE_FILE"
    else
        echo "  ✗ Failed to download $core"
    fi
    echo ""
done

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "========================================="
echo "✓ Core download complete!"
echo "========================================="
echo ""
echo "Installed cores:"
sudo ls -lh "$CORE_DIR"/*.so 2>/dev/null | awk '{print "  -", $9}' || echo "  (No cores found - check for errors above)"
echo ""
echo "Restart retro mode to use the new cores:"
echo "  mode stop"
echo "  mode retro"
echo ""
echo "Then press F1 in RetroArch → Load Core"
