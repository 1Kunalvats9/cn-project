# Build log: Mac 3 (Member 3)

## 2026-11-25, Phase 1, Part 1

- **Inventory (Task A):** en0, `10.7.27.76/19`, gateway `10.7.0.1`, Private Wi-Fi MAC `b6:d8:ae:24:f5:f1`.
  macOS firewall off and stealth mode off, so ping will get replies.
  Evidence: `evidence/phase1/A-lan/01-mac3-inventory.txt`.
- **IP changed since October** (`10.7.5.129` → `10.7.27.76`): DHCP gave a new address.
  - Checked System Settings → Wi-Fi → Rishihood_Learner → Details: Private Wi-Fi address is already **Fixed** (`b6:d8:ae:24:f5:f1`).
    So the change came from the DHCP lease, not from a rotating MAC.
  - DHCP lease: 18 h (`lease_time 0xfd20`), from DHCP server `10.1.0.2`. While the Mac stays connected, the lease renews and the IP normally stays the same.
  - No manual IP: this is a large campus network (/19, 2,500+ neighbours in ARP), so a hand-picked IP could clash with someone else's. Students can't get a DHCP reservation here.
  - Plan: on build or demo day, run `ipconfig getifaddr en0` on all 3 Macs first. If an IP moved, update the dnsmasq records (Mac 1) and the nginx upstream (Mac 2).
    Fallback if campus Wi-Fi moves IPs or blocks Mac-to-Mac traffic: a phone hotspot or our own router, where IPs stay stable.
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

## 2026-11-25, later

- Backend A died when its Terminal tab closed. It now runs as a launchd user agent (`scripts/backend-a.sh start|stop|status|log`), so it survives closed terminals and restarts after a crash.
  For the "one backend down" demo, use `scripts/backend-a.sh stop`, then `start`.
- Ping Mac 3 → Mac 1 (`10.7.27.215`): 4/4 replies, so campus Wi-Fi does not isolate clients.
  Evidence: `evidence/phase1/A-lan/02-ping-mac3-to-mac1.txt`.
- Mac 1's dnsmasq answers on TCP 53. Backend B (:3002) was not up yet at this point.
- Both backends checked from Mac 3 over the LAN: A (10.7.27.76:3001) and B (10.7.27.215:3002) return 200 with the right X-Backend, the same ETag and identical /api/info bodies, and both return 304. Mac 1 confirmed the same from its side.
  Evidence: `evidence/phase1/C-backends/03-both-backends-on-lan.txt`.
- Ping Mac 3 → Mac 2 (`10.7.8.240`): 4/4 replies. Evidence: `evidence/phase1/A-lan/03-ping-mac3-to-mac2.txt`.
- Mac 2's agent got "No route to host" connecting to both backends. But Mac 1 has reached Backend A (4 requests from 10.7.27.215 in the log), Mac 3 can ping Mac 2, and no request from 10.7.8.240 ever reached A. So the block is on Mac 2's side (agent sandbox or macOS Local Network permission), not the network or Mac 3.
