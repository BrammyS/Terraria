#!/bin/bash
set -eu

# Build CLI args string
ARGS="-config $TERRARIA_CONFIG"

apply_override() {
  # $1 = flag
  # $2 = value
  if [ -n "$2" ]; then
    ARGS="$ARGS $1 $2"
  fi
}

apply_flag() {
  # $1 = flag
  # $2 = enabled (1/0)
  if [ "${2:-0}" = "1" ]; then
    ARGS="$ARGS $1"
  fi
}

apply_override "-password" "${TERRARIA_PASSWORD:-}"
apply_override "-port" "${TERRARIA_PORT:-}"
apply_override "-maxplayers" "${TERRARIA_MAXPLAYERS:-}"
apply_override "-motd" "${TERRARIA_MOTD:-}"
apply_override "-autocreate" "${TERRARIA_AUTOCREATE:-}"
apply_override "-banlist" "${TERRARIA_BANLIST:-}"
apply_override "-ip" "${TERRARIA_IP:-}"
apply_override "-forcepriority" "${TERRARIA_FORCEPRIORITY:-}"
apply_override "-announcementboxrange" "${TERRARIA_ANNOUNCEMENTBOXRANGE:-}"
apply_override "-seed" "${TERRARIA_SEED:-}"
apply_flag "-secure" "${TERRARIA_SECURE:-0}"
apply_flag "-noupnp" "${TERRARIA_NOUPNP:-0}"
apply_flag "-disableannouncementbox" "${TERRARIA_DISABLEANNOUNCEMENTBOX:-0}"

if [ -n "${TERRARIA_WORLD:-}" ]; then
  apply_override "-world" "${WORLD_PATH}/${TERRARIA_WORLD}.wld"
  apply_override "-worldname" "${TERRARIA_WORLD}"
fi

# Allow for extra args for future compatibility
if [ -n "${TERRARIA_EXTRA_ARGS:-}" ]; then
  ARGS="$ARGS ${TERRARIA_EXTRA_ARGS}"
fi

# Print used config overrides
if [ -n "${TERRARIA_PASSWORD:-}" ]; then
    SAFE_ARGS=$(echo "$ARGS" | sed "s|$TERRARIA_PASSWORD|******|g")
else
    SAFE_ARGS="$ARGS"
fi
echo "Configuring the server with the following arguments:"
echo "$SAFE_ARGS" | xargs -n 2 echo

# Setup input pipe
rm -f /tmp/terraria_input
mkfifo /tmp/terraria_input
chmod 666 /tmp/terraria_input
sleep infinity > /tmp/terraria_input &
SLEEP_PID=$!

# Trap exit signals from Docker
shutdown_gracefully() {
    set +e
    echo "Shutdown request received! Stopping Terraria server gracefully..."
    echo "exit" > /tmp/terraria_input
    if [ -n "${SERVER_PID:-}" ]; then
        wait "${SERVER_PID}"
    fi
    kill "${SLEEP_PID}" 2>/dev/null
    echo "Terraria server has stopped"
    exit 0
}
trap 'shutdown_gracefully' SIGTERM SIGINT

# Start the server
echo -e "\nStarting Terraria Server..."
if [ "${TARGETARCH:-amd64}" = "amd64" ]; then
    ./TerrariaServer $ARGS < /tmp/terraria_input &
else
    mono ./TerrariaServer.exe $ARGS < /tmp/terraria_input &
fi
SERVER_PID=$!

# Forward stdin to pipe (blocking, so no SIGTTIN) and handle EOF
set +e
while read -r line; do
    echo "$line" > /tmp/terraria_input
done
set -e

# If input closes, wait for server
wait $SERVER_PID
kill $SLEEP_PID 2>/dev/null