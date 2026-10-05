#!/bin/sh
set -eu

DOMAIN="gui/$(id -u)"
LABEL="edu.cnproject.backend-a"
SERVICE="$DOMAIN/$LABEL"
PID=$(/bin/launchctl print "$SERVICE" 2>/dev/null | /usr/bin/awk '/^[[:space:]]*pid = / {print $3; exit}')

if [ -n "$PID" ]; then
    echo "Backend A is running (PID $PID)."
    exit 0
fi

echo "Backend A is stopped."
exit 1
