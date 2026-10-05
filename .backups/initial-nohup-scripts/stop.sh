#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PID_FILE="$SCRIPT_DIR/backend.pid"

if [ ! -s "$PID_FILE" ]; then
    echo "Backend B is not running (no PID file)."
    exit 0
fi

PID=$(cat "$PID_FILE")
if ! kill -0 "$PID" 2>/dev/null || ! ps -p "$PID" -o command= | grep -F "$SCRIPT_DIR/server.py" >/dev/null 2>&1; then
    echo "Backend B is not running (removing stale PID file)."
    rm -f "$PID_FILE"
    exit 0
fi

kill "$PID"
COUNT=0
while kill -0 "$PID" 2>/dev/null && [ "$COUNT" -lt 50 ]; do
    sleep 0.1
    COUNT=$((COUNT + 1))
done

if kill -0 "$PID" 2>/dev/null; then
    echo "Backend B did not stop cleanly; PID $PID was left running." >&2
    exit 1
fi

rm -f "$PID_FILE"
echo "Backend B stopped."
