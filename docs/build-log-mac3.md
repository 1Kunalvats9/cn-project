# Build log: Mac 3 (Member 3)

## 2026-11-25, Phase 1, Part 1

- **Inventory (Task A):** en0, `10.7.27.76/19`, gateway `10.7.0.1`, Private Wi-Fi MAC `b6:d8:ae:24:f5:f1`.
  macOS firewall off and stealth mode off, so ping will get replies.
  Evidence: `evidence/phase1/A-lan/01-mac3-inventory.txt`.
- **IP changed since October** (`10.7.5.129` → `10.7.27.76`): DHCP gave a new address.
  To do: set Private Wi-Fi address to **Fixed**, and ask for a DHCP reservation or use a manual IP before the demo.
- **Wrote `backend/backend.py`** (standard library only, `python3 backend.py <ID> <PORT>`):
  - `ThreadingHTTPServer` on `0.0.0.0`; skips the startup reverse-DNS lookup so it never hangs when DNS changes.
  - `/` and `/api/status`: JSON, `Cache-Control: no-store`.
  - `/api/info`: identical on A and B, `max-age=60`, `ETag "7915c1338b1a8a11"`, 304 on `If-None-Match`.
  - `X-Backend` on every response, HEAD support, 404 JSON, logs the client IP.
- **Local tests passed:** 200, 304 (from both A and B with the same ETag), HEAD, 404.
  Evidence: `evidence/phase1/C-backends/01-local-tests.txt`.
- **Backend A running** on `*:3001` and answering on the LAN IP.
  Evidence: `evidence/phase1/C-backends/02-backend-a-on-lan.txt`.
- The old `backend-a/` and `backend-b/` folders (October version, both backends on Mac 3) are kept but superseded by `backend/`.
