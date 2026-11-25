#!/usr/bin/env python3
"""Tiny REST backend for the Computer Networks project (Python standard library only).

Usage:
    python3 backend.py A 3001      # Backend A on Mac 3
    python3 backend.py B 3002      # Backend B on Mac 1

Endpoints
    GET /            JSON hello, Cache-Control: no-store
    GET /api/status  JSON with the backend id, Cache-Control: no-store
                     (never cached, so load balancing stays visible)
    GET /api/info    JSON that is IDENTICAL on A and B, Cache-Control: max-age=60
                     plus an ETag; replies 304 when If-None-Match matches
    anything else    404 JSON

Every response (200, 304, 404, HEAD) carries "X-Backend: <id>".
"""

import hashlib
import json
import socket
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

if len(sys.argv) != 3 or not sys.argv[2].isdigit():
    sys.exit("usage: python3 backend.py <ID> <PORT>   e.g. python3 backend.py A 3001")

BACKEND_ID = sys.argv[1]
PORT = int(sys.argv[2])
HOSTNAME = socket.gethostname()  # local name only, no DNS lookup

# /api/info must be byte-for-byte the same on A and B: no backend id, no time.
# Otherwise the ETag would differ between backends and a 304 could never happen
# under round robin.
INFO_BODY = (json.dumps({
    "service": "Private Network Service Platform",
    "version": "1.0",
    "endpoints": ["/", "/api/status", "/api/info"],
    "note": "This response is cacheable and identical on every backend.",
}, indent=2) + "\n").encode()
INFO_ETAG = '"' + hashlib.sha256(INFO_BODY).hexdigest()[:16] + '"'


class BackendServer(ThreadingHTTPServer):
    """Threaded server that skips Python's socket.getfqdn() at startup.

    The default server_bind() does a reverse-DNS lookup of the bind address.
    When this Mac's DNS points at the team server (or the server is down) that
    lookup can hang for seconds, so we bind directly instead.
    """

    allow_reuse_address = True
    daemon_threads = True

    def server_bind(self):
        self.socket.bind(self.server_address)
        self.server_name = HOSTNAME
        self.server_port = self.server_address[1]


class Handler(BaseHTTPRequestHandler):
    server_version = "CNBackend/2.0"

    # ---------- helpers ----------
    def _send(self, status, body=b"", cache="no-store", extra=None):
        self.send_response(status)
        self.send_header("X-Backend", BACKEND_ID)
        self.send_header("Cache-Control", cache)
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        if status != 304:  # a 304 has no body and no content headers
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD" and status != 304:
            self.wfile.write(body)

    @staticmethod
    def _json(obj):
        return (json.dumps(obj, indent=2) + "\n").encode()

    def _etag_matches(self):
        header = self.headers.get("If-None-Match")
        if not header:
            return False
        if header.strip() == "*":
            return True
        # the header may hold a list, and weak tags look like W/"..."
        tags = [t.strip().removeprefix("W/") for t in header.split(",")]
        return INFO_ETAG in tags

    # ---------- routes ----------
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._send(200, self._json({
                "service": "Private Network Service Platform",
                "backend": BACKEND_ID,
                "message": f"Hello from Backend {BACKEND_ID}",
            }))
        elif path == "/api/status":
            self._send(200, self._json({
                "status": "ok",
                "backend": BACKEND_ID,
                "host": HOSTNAME,
                "port": PORT,
                "time": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            }))
        elif path == "/api/info":
            cache = "public, max-age=60"
            if self._etag_matches():
                self._send(304, cache=cache, extra={"ETag": INFO_ETAG})
            else:
                self._send(200, INFO_BODY, cache=cache, extra={"ETag": INFO_ETAG})
        else:
            self._send(404, self._json({"error": "not found", "path": path, "backend": BACKEND_ID}))

    def do_HEAD(self):  # curl -I sends HEAD: same headers, no body
        self.do_GET()

    def log_message(self, fmt, *args):
        # one line per request; client IP shows who called us (should be nginx)
        stamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{stamp}] backend={BACKEND_ID} client={self.client_address[0]} {fmt % args}",
              flush=True)


if __name__ == "__main__":
    server = BackendServer(("0.0.0.0", PORT), Handler)
    print(f"Backend {BACKEND_ID} listening on 0.0.0.0:{PORT}  (/api/info ETag {INFO_ETAG})",
          flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\nBackend {BACKEND_ID} stopped", flush=True)
