# Backend (Task C)

One Python file, standard library only (Python 3.9+). No installs.

| Backend | Runs on | Command |
|---|---|---|
| A | Mac 3 | `python3 backend/backend.py A 3001` |
| B | Mac 1 | `python3 backend/backend.py B 3002` |

Run it from the project folder in a Terminal window you keep open. Stop it with Ctrl+C.
The first time, macOS may ask whether Python can accept incoming connections: click **Allow**.

It listens on `0.0.0.0`, so it answers on the Mac's LAN IP, not just localhost.

## Endpoints

| Path | Body | Cache-Control | Notes |
|---|---|---|---|
| `GET /` | JSON hello with backend id | `no-store` | |
| `GET /api/status` | JSON: status, backend, host, port, time | `no-store` | Never cached, so round robin A/B stays visible |
| `GET /api/info` | JSON, **identical on A and B** | `public, max-age=60` | Sends `ETag`; returns **304** if `If-None-Match` matches |
| anything else | JSON error | `no-store` | 404 |

Every response (including 304, 404 and HEAD) has `X-Backend: A` or `X-Backend: B`.
Each request is logged with the client IP. Behind nginx, that IP should be the edge (Mac 2).

## Quick check

```bash
curl -i http://<this-mac-ip>:3001/api/status
```

```bash
curl -i -H 'If-None-Match: "7915c1338b1a8a11"' http://<this-mac-ip>:3001/api/info
```

The second command should return `304 Not Modified`. The ETag is printed when the backend starts.

## Why /api/info must be identical on A and B

With round robin, the first request may hit A and the revalidation may hit B.
If the bodies (and therefore the ETags) differed, B would never answer 304.
