#!/usr/bin/env bash
set -e

PROJECT_ROOT="/home/pi/athena-deck-v2"
COMPOSE_DIR="$PROJECT_ROOT/docker"
STATE_FILE="/tmp/mode"

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  COMPOSE="docker compose"
fi

usage() {
  echo "Usage: mode {vision|ai|dev|red|proxy|stop|status}"
  exit 1
}

stop_all() {
  echo "Stopping all running containers..."
  if [ -d "$COMPOSE_DIR" ]; then
    for f in "$COMPOSE_DIR"/compose.*.yml; do
      [ -f "$f" ] || continue
      $COMPOSE -f "$f" down >/dev/null 2>&1 || true
    done
  fi
}

set_mode() {
  echo "$1" > "$STATE_FILE"
}

get_mode() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "none"
  fi
}

case "$1" in
  vision)
    stop_all
    set_mode "vision"
    echo "Current mode set to: vision"
    echo "Launching Athena Vision HUD..."
    /usr/local/bin/athena-vision
    ;;

  ai)
    stop_all
    set_mode "ai"
    echo "Current mode set to: ai"
    if [ -f "$COMPOSE_DIR/compose.ai.yml" ]; then
      (cd "$COMPOSE_DIR" && $COMPOSE -f compose.ai.yml up -d)
    else
      echo "Warning: $COMPOSE_DIR/compose.ai.yml not found."
    fi
    ;;

  dev)
    stop_all
    set_mode "dev"
    echo "Current mode set to: dev"
    if [ -f "$COMPOSE_DIR/compose.dev.yml" ]; then
      (cd "$COMPOSE_DIR" && $COMPOSE -f compose.dev.yml up -d)
    else
      echo "Warning: $COMPOSE_DIR/compose.dev.yml not found."
    fi
    ;;

  red)
    stop_all
    set_mode "red"
    echo "Current mode set to: red"
    if [ -f "$COMPOSE_DIR/compose.red.yml" ]; then
      (cd "$COMPOSE_DIR" && $COMPOSE -f compose.red.yml up -d)
    else
      echo "Warning: $COMPOSE_DIR/compose.red.yml not found."
    fi
    ;;

  proxy)
    stop_all
    set_mode "proxy"
    echo "Current mode set to: proxy"
    if [ -f "$COMPOSE_DIR/compose.proxy.yml" ]; then
      (cd "$COMPOSE_DIR" && $COMPOSE -f compose.proxy.yml up -d)
    else
      echo "Warning: $COMPOSE_DIR/compose.proxy.yml not found."
    fi
    ;;

  stop)
    stop_all
    set_mode "none"
    echo "All modes stopped."
    ;;

  status)
    echo "Current mode: $(get_mode)"
    echo
    echo "Docker containers:"
    docker ps
    ;;

  *)
    usage
    ;;
esac
