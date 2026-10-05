#!/bin/sh
set -eu

DOMAIN="gui/$(id -u)"
LABEL="edu.cnproject.backend-b"
SERVICE="$DOMAIN/$LABEL"

if ! /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
    echo "Backend B is stopped."
    exit 0
fi

/bin/launchctl bootout "$SERVICE"
echo "Backend B stopped."
