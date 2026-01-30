#!/bin/sh
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

# Trap SIGTERM and SIGINT
shutdown_gracefully() {
    set +e
    echo "Shutdown request received! Sending 'exit' to Terraria..."
    echo "exit" > /tmp/terraria_input
    if [ -n "${SERVER_PID:-}" ]; then
        wait "${SERVER_PID}"
    fi
    exit 0
}
trap 'shutdown_gracefully' TERM INT

# Setup input pipe
mkfifo /tmp/terraria_input
# Keep pipe open with a sleep holding the write end
sleep infinity > /tmp/terraria_input &
SLEEP_PID=$!
# Forward stdin to pipe for interactive use
cat > /tmp/terraria_input &

# Start the server
echo -e "\nStarting Terraria Server..."
if [ "${TARGETARCH:-amd64}" = "amd64" ]; then
    ./TerrariaServer $ARGS < /tmp/terraria_input &
else
    mono ./TerrariaServer.exe $ARGS < /tmp/terraria_input &
fi
SERVER_PID=$!

# Wait for the server process to exit
wait $SERVER_PID
kill $SLEEP_PID 2>/dev/null