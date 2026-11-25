#!/bin/sh
# Start / stop / check Backend A on Mac 3 (runs in the background via launchd).
#   scripts/backend-a.sh start    start it (keeps running after Terminal closes)
#   scripts/backend-a.sh stop     stop it  (use this for the "one backend down" demo)
#   scripts/backend-a.sh status   is it listening on :3001?
#   scripts/backend-a.sh log      follow the request log (Ctrl+C to quit)
set -eu

LABEL="edu.cnproject.mac3-backend-a"
DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/$LABEL"
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLIST="$DIR/$LABEL.plist"
LOG="$DIR/../backend/backend-a.log"

loaded() { /bin/launchctl print "$SERVICE" >/dev/null 2>&1; }

status() {
    if loaded; then echo "launchd: loaded"; else echo "launchd: not loaded (stopped)"; fi
    if /usr/sbin/lsof -nP -iTCP:3001 -sTCP:LISTEN >/dev/null 2>&1; then
        /usr/sbin/lsof -nP -iTCP:3001 -sTCP:LISTEN | tail -n +2 | awk '{print "listening: " $9 " (pid " $2 ")"}'
    else
        echo "listening: nothing on :3001"
    fi
}

case "${1:-status}" in
    start)
        if loaded; then echo "Backend A is already running."; else
            /bin/launchctl bootstrap "$DOMAIN" "$PLIST"; sleep 1; echo "Backend A started."; fi
        status ;;
    stop)
        if loaded; then /bin/launchctl bootout "$SERVICE"; echo "Backend A stopped."; else
            echo "Backend A was not running."; fi ;;
    status) status ;;
    log) tail -f "$LOG" ;;
    *) echo "usage: $0 start|stop|status|log"; exit 1 ;;
esac
