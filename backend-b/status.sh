#!/bin/sh
set -eu

DOMAIN="gui/$(id -u)"
LABEL="edu.cnproject.backend-b"
SERVICE="$DOMAIN/$LABEL"
PID=$(/bin/launchctl print "$SERVICE" 2>/dev/null | /usr/bin/awk '/^[[:space:]]*pid = / {print $3; exit}')

if [ -n "$PID" ]; then
    echo "Backend B is running (PID $PID)."
    exit 0
fi

echo "Backend B is stopped."
exit 1
