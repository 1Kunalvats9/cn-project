#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PID_FILE="$SCRIPT_DIR/backend.pid"
LOG_FILE="$SCRIPT_DIR/backend.log"
PYTHON_BIN="/opt/homebrew/bin/python3"

is_our_process() {
    [ -s "$PID_FILE" ] || return 1
    PID=$(cat "$PID_FILE")
    kill -0 "$PID" 2>/dev/null || return 1
    ps -p "$PID" -o command= | grep -F "$SCRIPT_DIR/server.py" >/dev/null 2>&1
}

if is_our_process; then
    echo "Backend B is already running (PID $(cat "$PID_FILE"))."
    exit 0
fi

rm -f "$PID_FILE"
nohup "$PYTHON_BIN" "$SCRIPT_DIR/server.py" >>"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" >"$PID_FILE"
sleep 1

if is_our_process; then
    echo "Backend B started (PID $PID)."
else
    echo "Backend B failed to start; see $LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
fi
