#!/usr/bin/env python3
"""Backend B for the Computer Networks project."""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json


BACKEND = "B"
PORT = 3002


class BackendHandler(BaseHTTPRequestHandler):
    server_version = "CNBackend/1.0"

    def _send(self, status, content_type, body):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Backend", BACKEND)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            self._send(200, "text/plain; charset=utf-8", b"Backend B\n")
        elif self.path == "/api/status":
            body = (json.dumps({"backend": BACKEND, "status": "ok"}) + "\n").encode("utf-8")
            self._send(200, "application/json; charset=utf-8", body)
        else:
            self._send(404, "text/plain; charset=utf-8", b"Not found\n")

    def do_HEAD(self):
        self.do_GET()


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), BackendHandler)
    print(f"Backend {BACKEND} listening on 0.0.0.0:{PORT}", flush=True)
    server.serve_forever()
