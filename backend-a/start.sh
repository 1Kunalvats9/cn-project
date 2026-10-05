#!/bin/sh
set -eu

DOMAIN="gui/$(id -u)"
LABEL="edu.cnproject.backend-a"
SERVICE="$DOMAIN/$LABEL"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLIST="$SCRIPT_DIR/$LABEL.plist"

if /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
    echo "Backend A is already loaded."
    exec "$SCRIPT_DIR/status.sh"
fi

/bin/launchctl bootstrap "$DOMAIN" "$PLIST"
sleep 1
exec "$SCRIPT_DIR/status.sh"
