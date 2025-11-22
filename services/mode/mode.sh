#!/usr/bin/env bash
set -e

REPO_ROOT="/home/pi/athena-deck-v2"
COMPOSE_DIR="$REPO_ROOT/docker"
MODE_FILE="/tmp/mode"

set_mode() {
  echo "$1" > "$MODE_FILE"
}

get_mode() {
  if [ -f "$MODE_FILE" ]; then
    cat "$MODE_FILE"
  else
    echo "none"
  fi
}

usage() {
  echo "Usage: mode {vision|ai|dev|red|retro|proxy|stop|status|list|help}"
  echo
  echo "Commands:"
  echo "  vision   - Full-screen camera HUD on FNK0100"
  echo "  ai       - Start AI stack (Ollama) via docker/compose.ai.yml"
  echo "  dev      - Dev stack placeholder via docker/compose.dev.yml"
  echo "  red      - Kali Linux red team environment via docker/compose.red.yml"
  echo "  retro    - Retro gaming with RetroArch via docker/compose.retro.yml"
  echo "  proxy    - Caddy reverse proxy via docker/compose.proxy.yml"
  echo "  stop     - Stop all docker stacks and clear current mode"
  echo "  status   - Show current mode + running containers"
  echo "  list     - List all modes and their descriptions"
  echo "  help     - Show this help"
  exit 1
}

list_modes() {
  echo "Available modes:"
  echo
  echo "  vision   - Full-screen camera HUD on FNK0100 (800x480, rpicam-hello)"
  echo "  ai       - AI node: Ollama on port 11434 (docker/compose.ai.yml)"
  echo "  dev      - Dev stack placeholder (safe to customize later)"
  echo "  red      - Kali Linux red team environment (access via kali-shell)"
  echo "  retro    - Retro gaming with RetroArch emulator (ROMs in ~/athena-deck-v2/roms/)"
  echo "  proxy    - Caddy reverse proxy on ports 80/443)"
  echo
  echo "Utility commands:"
  echo
  echo "  stop     - Stop all docker stacks and clear current mode"
  echo "  status   - Show current mode and running containers"
  echo
  echo "Use 'mode help' for detailed usage."
}

stop_all() {
  echo "Stopping all docker stacks..."
  if [ -d "$COMPOSE_DIR" ]; then
    for f in "$COMPOSE_DIR"/compose.*.yml; do
      [ -e "$f" ] || continue
      echo "  - docker compose -f $f down"
      docker compose -f "$f" down || true
    done
  else
    echo "  (compose directory $COMPOSE_DIR does not exist)"
  fi
  set_mode "none"
}

CMD="$1"

case "$CMD" in
  vision)
    echo "Switching to vision mode..."
    stop_all
    set_mode "vision"
    export DISPLAY=:0
    export XAUTHORITY=/home/pi/.Xauthority
    echo "Starting Athena Vision Detection HUD on FNK0100 (800x480)..."
    echo "Features: Object Detection, Face Detection, OCR, Crosshairs"
    echo "Press 'q' to exit vision mode."
    echo
    echo "Controls:"
    echo "  'q' - Quit"
    echo "  'f' - Toggle face detection"
    echo "  'o' - Toggle object detection"
    echo "  't' - Toggle OCR text detection"
    echo "  'c' - Toggle crosshairs"
    echo
    # Use athena-vision-detect for full detection capabilities
    /usr/local/bin/athena-vision-detect
    ;;

  ai)
    echo "Switching to AI mode..."
    stop_all
    set_mode "ai"

    AI_COMPOSE="$COMPOSE_DIR/compose.ai.yml"
    if [ ! -f "$AI_COMPOSE" ]; then
      echo "ERROR: AI compose file not found at $AI_COMPOSE"
      set_mode "none"
      exit 1
    fi

    echo "Starting AI stack with $AI_COMPOSE ..."
    if docker compose -f "$AI_COMPOSE" up -d; then
      echo "Checking Ollama on http://127.0.0.1:11434 ..."
      sleep 3
      if curl -sSf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        PI_IP=$(hostname -I | awk '{print $1}')
        echo "✓ Ollama is responding."
        echo
        echo "Ollama API:"
        echo "  Local:   http://127.0.0.1:11434"
        echo "  Network: http://$PI_IP:11434"
        echo
        echo "Open WebUI:"
        echo "  Local:   http://127.0.0.1:3000"
        echo "  Network: http://$PI_IP:3000"
        echo
        echo "NOTE: AI mode runs headless (no GUI auto-launch)."
        echo "      To access via browser, visit the URLs above."
      else
        echo "WARNING: Ollama did not respond on http://127.0.0.1:11434"
        echo "         Run 'docker ps' and 'docker logs ollama' to debug."
      fi
    else
      echo "ERROR: Failed to start AI stack via $AI_COMPOSE"
      set_mode "none"
      exit 1
    fi
    ;;

  dev)
    echo "Switching to dev mode..."
    stop_all
    set_mode "dev"

    DEV_COMPOSE="$COMPOSE_DIR/compose.dev.yml"
    if [ ! -f "$DEV_COMPOSE" ]; then
      echo "ERROR: Dev compose file not found at $DEV_COMPOSE"
      set_mode "none"
      exit 1
    fi

    if docker compose -f "$DEV_COMPOSE" up -d; then
      echo "Dev stack started."
    else
      echo "ERROR: Failed to start dev stack"
      set_mode "none"
      exit 1
    fi
    ;;

  red)
    echo "Switching to red mode..."
    stop_all
    set_mode "red"

    RED_COMPOSE="$COMPOSE_DIR/compose.red.yml"
    if [ ! -f "$RED_COMPOSE" ]; then
      echo "ERROR: Red compose file not found at $RED_COMPOSE"
      set_mode "none"
      exit 1
    fi

    echo "Starting Kali Linux container..."
    echo "(First run will download kalilinux/kali-rolling image and install tools - this may take 10-15 minutes)"
    echo ""

    if docker compose -f "$RED_COMPOSE" up -d; then
      echo "✓ Kali container 'athena-kali' started."
      echo ""
      echo "The container is installing kali-linux-default in the background."
      echo "You can monitor progress with:"
      echo "  docker logs -f athena-kali"
      echo ""
      echo "To access the Kali shell once ready:"
      echo "  docker exec -it athena-kali bash"
      echo "  OR use: kali-shell"
      echo ""
      echo "To check if installation is complete:"
      echo "  docker exec athena-kali which nmap"
      echo ""
    else
      echo "ERROR: Failed to start red stack"
      set_mode "none"
      exit 1
    fi
    ;;

  retro)
    echo "Switching to retro gaming mode..."
    stop_all
    set_mode "retro"

    RETRO_COMPOSE="$COMPOSE_DIR/compose.retro.yml"
    if [ ! -f "$RETRO_COMPOSE" ]; then
      echo "ERROR: Retro compose file not found at $RETRO_COMPOSE"
      set_mode "none"
      exit 1
    fi

    echo "Starting RetroArch on FNK0100 display (800x480)..."
    echo "(First run will download RetroArch image - may take a few minutes)"
    echo ""

    if docker compose -f "$RETRO_COMPOSE" up -d; then
      echo "✓ RetroArch container 'athena-retro' started."
      echo ""
      echo "ROMs directory: /home/pi/athena-deck-v2/roms/"
      echo "Add your ROM files there to play games."
      echo ""
      echo "RetroArch should appear on your FNK0100 display."
      echo "Use F1 to access the RetroArch menu."
      echo ""
      echo "To stop retro mode: mode stop"
    else
      echo "ERROR: Failed to start retro stack"
      set_mode "none"
      exit 1
    fi
    ;;

  proxy)
    echo "Switching to proxy mode..."
    stop_all
    set_mode "proxy"

    PROXY_COMPOSE="$COMPOSE_DIR/compose.proxy.yml"
    if [ ! -f "$PROXY_COMPOSE" ]; then
      echo "ERROR: Proxy compose file not found at $PROXY_COMPOSE"
      set_mode "none"
      exit 1
    fi

    if docker compose -f "$PROXY_COMPOSE" up -d; then
      echo "Caddy reverse proxy stack started."
    else
      echo "ERROR: Failed to start proxy stack"
      set_mode "none"
      exit 1
    fi
    ;;

  stop)
    echo "Stopping all modes and docker stacks..."
    stop_all
    ;;

  status)
    current_mode="$(get_mode)"
    echo "Current mode: ${current_mode:-none}"
    echo
    echo "Active docker-compose stacks (by file):"
    if [ -d "$COMPOSE_DIR" ]; then
      ls "$COMPOSE_DIR"/compose.*.yml 2>/dev/null || echo "  (none found in $COMPOSE_DIR)"
    else
      echo "  (compose directory $COMPOSE_DIR does not exist)"
    fi
    echo
    echo "Docker containers:"
    docker ps
    ;;

  list)
    list_modes
    ;;

  help|"")
    usage
    ;;

  *)
    usage
    ;;
esac
