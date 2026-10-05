# Mac 3 backends — Phase 1

- Mac 3 LAN IP: `10.7.5.129` (`en0`)
- Bind address: `0.0.0.0` (all IPv4 interfaces, including the LAN address)
- Backend A port: `3001`
- Backend B port: `3002`
- Runtime: the existing Homebrew Python 3 at `/opt/homebrew/bin/python3`; no packages were installed.
- The server avoids Python's startup hostname lookup, so it does not depend on or change the current DNS configuration.

## Endpoints

| Backend | Root endpoint | Status endpoint |
| --- | --- | --- |
| A | `http://10.7.5.129:3001/` | `http://10.7.5.129:3001/api/status` |
| B | `http://10.7.5.129:3002/` | `http://10.7.5.129:3002/api/status` |

Every response includes the matching `X-Backend` header. The status endpoints return JSON such as `{"backend":"A","status":"ok"}`.

## Service controls

Run these from any directory:

```sh
/Users/kunalvats/cn-project/backend-a/start.sh
/Users/kunalvats/cn-project/backend-a/stop.sh
/Users/kunalvats/cn-project/backend-a/status.sh

/Users/kunalvats/cn-project/backend-b/start.sh
/Users/kunalvats/cn-project/backend-b/stop.sh
/Users/kunalvats/cn-project/backend-b/status.sh
```

Each backend runs as its own `launchd` user agent with a unique label and log (`backend.log`). This avoids shell-session termination of the services and makes them independently startable and stoppable. The status scripts report the active process PID from `launchctl`.

The services enable normal TCP address reuse so a backend can be stopped and immediately restarted after serving requests.

## Local verification commands

```sh
curl -i http://127.0.0.1:3001/
curl -i http://127.0.0.1:3001/api/status
curl -i http://127.0.0.1:3002/
curl -i http://127.0.0.1:3002/api/status

curl -i http://10.7.5.129:3001/
curl -i http://10.7.5.129:3001/api/status
curl -i http://10.7.5.129:3002/
curl -i http://10.7.5.129:3002/api/status

lsof -nP -iTCP:3001 -sTCP:LISTEN
lsof -nP -iTCP:3002 -sTCP:LISTEN
```

## Limitation

The Mac 2 test must be run on Mac 2 (`10.7.27.180`), for example with `curl -i http://10.7.5.129:3001/`; this Mac cannot perform that remote-host test.
