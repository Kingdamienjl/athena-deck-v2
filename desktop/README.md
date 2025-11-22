# Athena Deck Desktop Mode Switcher

Large, clickable icons for easy mode switching on the FNK0100 DSI display.

## Features

- **6 Large Mode Icons**: One-click access to all Athena Deck modes
- **Color-Coded**: Each mode has a distinctive color and symbol
- **SVG Graphics**: Scalable vector icons for crisp display at any size
- **Desktop Integration**: Standard .desktop launchers for compatibility

## Installation

Run the installation script to deploy icons to your desktop:

```bash
cd /home/pi/athena-deck-v2/desktop
bash install-desktop-icons.sh
```

This will copy all 6 mode switcher icons to `/home/pi/Desktop/`.

## Available Icons

| Icon | Mode | Color | Function |
|------|------|-------|----------|
| **VISION** | `vision` | Blue | Camera HUD with object/face detection, OCR, and crosshairs |
| **AI** | `ai` | Purple | Start Ollama LLM server |
| **DEV** | `dev` | Green | Start development environment |
| **RED** | `red` | Red | Start red team tools |
| **RETRO** | `retro` | Cyan | RetroArch gaming emulator |
| **PROXY** | `proxy` | Orange | Start Caddy reverse proxy |
| **STOP** | `stop` | Dark Red | Stop all services |

## Usage

Simply click any icon on your desktop to switch to that mode. The system will:
1. Stop any running modes/containers
2. Update `/tmp/mode` with the new mode
3. Start the selected mode's services
4. Update the OLED status display

## File Structure

```
desktop/
├── icons/
│   ├── vision.svg    # Camera/eye icon (blue)
│   ├── ai.svg        # Neural network icon (purple)
│   ├── dev.svg       # Code brackets icon (green)
│   ├── red.svg       # Security shield icon (red)
│   ├── retro.svg     # Game controller icon (cyan)
│   ├── proxy.svg     # Network routing icon (orange)
│   └── stop.svg      # Stop square icon (dark red)
├── vision.desktop    # Vision mode launcher
├── ai.desktop        # AI mode launcher
├── dev.desktop       # Dev mode launcher
├── red.desktop       # Red team mode launcher
├── retro.desktop     # Retro gaming mode launcher
├── proxy.desktop     # Proxy mode launcher
├── stop.desktop      # Stop all launcher
├── install-desktop-icons.sh  # Installation script
└── README.md         # This file
```

## Customization

### Changing Icon Graphics

Edit the SVG files in `icons/` to customize the appearance. SVG files are text-based and easy to modify.

### Changing Icon Behavior

Edit the `.desktop` files to change what happens when you click an icon:

```ini
[Desktop Entry]
Exec=/usr/local/bin/mode [mode-name]  # Change this line
Icon=/path/to/icon.svg                 # Or this line
```

### Adding New Mode Icons

1. Create a new SVG icon in `icons/`
2. Create a new `.desktop` file
3. Update `install-desktop-icons.sh` to include the new icon
4. Run the installation script

## Troubleshooting

### Icons Don't Appear on Desktop
- Ensure Desktop directory exists: `ls /home/pi/Desktop`
- Check .desktop files are executable: `ls -l /home/pi/Desktop/*.desktop`
- Verify icons are in place: `ls /home/pi/athena-deck-v2/desktop/icons/`

### Icons Don't Launch Modes
- Verify mode command is installed: `which mode`
- Test mode command manually: `mode status`
- Check .desktop file permissions: `chmod +x /home/pi/Desktop/*.desktop`

### Icons Look Wrong
- SVG rendering depends on the file manager/desktop environment
- Test SVG files directly: `display icons/vision.svg` (requires ImageMagick)
- Icons should be 200×200 pixels

## Integration with Athena Deck

Desktop icons are integrated with the existing mode system:
- Uses same `/usr/local/bin/mode` command
- Updates same `/tmp/mode` state file
- Works alongside command-line mode switching
- OLED display reflects mode changes immediately

No configuration needed - icons work out of the box after installation.
