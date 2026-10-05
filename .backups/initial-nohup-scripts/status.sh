#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PID_FILE="$SCRIPT_DIR/backend.pid"

if [ -s "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null && ps -p "$PID" -o command= | grep -F "$SCRIPT_DIR/server.py" >/dev/null 2>&1; then
        echo "Backend B is running (PID $PID)."
        exit 0
    fi
fi

echo "Backend B is stopped."
exit 1
