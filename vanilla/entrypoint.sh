#!/bin/bash
set -euo pipefail

FIFO_PATH="/tmp/terraria_input"
ARGS=("-config" "${TERRARIA_CONFIG}")

add_param() {
  local flag="$1"
  local value="${2:-}"

  if [[ -n "$value" ]]; then
    ARGS+=("$flag" "$value")
  fi
}

add_flag() {
  local flag="$1"
  local enabled="${2:-0}"

  if [[ "$enabled" == "1" ]]; then
    ARGS+=("$flag")
  fi
}

add_param "-password" "${TERRARIA_PASSWORD:-}"
add_param "-port" "${TERRARIA_PORT:-}"
add_param "-maxplayers" "${TERRARIA_MAXPLAYERS:-}"
add_param "-motd" "${TERRARIA_MOTD:-}"
add_param "-autocreate" "${TERRARIA_AUTOCREATE:-}"
add_param "-banlist" "${TERRARIA_BANLIST:-}"
add_param "-ip" "${TERRARIA_IP:-}"
add_param "-forcepriority" "${TERRARIA_FORCEPRIORITY:-}"
add_param "-announcementboxrange" "${TERRARIA_ANNOUNCEMENTBOXRANGE:-}"
add_param "-seed" "${TERRARIA_SEED:-}"
add_flag "-secure" "${TERRARIA_SECURE:-0}"
add_flag "-noupnp" "${TERRARIA_NOUPNP:-0}"
add_flag "-disableannouncementbox" "${TERRARIA_DISABLEANNOUNCEMENTBOX:-0}"

if [[ -n "${TERRARIA_WORLD:-}" ]]; then
  add_param "-world" "${WORLD_PATH}/${TERRARIA_WORLD}.wld"
  add_param "-worldname" "${TERRARIA_WORLD}"
fi

if [[ -n "${TERRARIA_EXTRA_ARGS:-}" ]]; then
  read -r -a EXTRA_ARGS_ARRAY <<<"${TERRARIA_EXTRA_ARGS}"
  ARGS+=("${EXTRA_ARGS_ARRAY[@]}")
fi

print_effective_args() {
  local args_str="${ARGS[*]}"
  if [ -n "${TERRARIA_PASSWORD:-}" ]; then
      args_str=$(echo "$args_str" | sed "s|$TERRARIA_PASSWORD|******|g")
  fi
  echo "Configuring the server with the following arguments:"
  echo "$args_str" | xargs -n 2 echo
}

setup_fifo() {
  rm -f "$FIFO_PATH"
  mkfifo "$FIFO_PATH"
  chmod 666 "$FIFO_PATH"
  sleep infinity >"$FIFO_PATH" &
  SLEEP_PID=$!
}

shutdown_gracefully() {
  set +e
  echo "Shutdown request received! Stopping Terraria server gracefully..."

  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    timeout 10s bash -c 'echo "exit" >"$1"' _ "$FIFO_PATH" || true
    wait "${SERVER_PID}"
  fi

  kill "${SLEEP_PID:-}" 2>/dev/null
  echo "Terraria server has stopped"
  exit 0
}

watch_server_and_terminate_self() {
  (
    while kill -0 "${SERVER_PID}" 2>/dev/null; do
      sleep 1
    done
    kill -TERM "$$"
  ) &
}

start_server() {
  echo -e "\nStarting Terraria Server..."

  if [[ "${TARGETARCH:-amd64}" == "amd64" ]]; then
    ./TerrariaServer "${ARGS[@]}" <"$FIFO_PATH" &
  else
    mono ./TerrariaServer.exe "${ARGS[@]}" <"$FIFO_PATH" &
  fi

  SERVER_PID=$!
}

forward_stdin_to_fifo() {
  set +e
  while read -r line; do
    echo "$line" >"$FIFO_PATH"
  done
  set -e
}

trap 'shutdown_gracefully' SIGTERM SIGINT

print_effective_args
setup_fifo
start_server
watch_server_and_terminate_self
forward_stdin_to_fifo

wait "${SERVER_PID}"
kill "${SLEEP_PID}" 2>/dev/null
