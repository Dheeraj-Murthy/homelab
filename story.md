# 🏠 Homelab Roadmap

> **Host:** MacBook Air 2015 (Arch Linux + Docker + Tailscale)
>
> **Goal:** Build a clean, production-like homelab for learning self-hosting, DevOps, networking, monitoring, automation, and AI.

---

# Overall Architecture

```
Internet
    │
Tailscale VPN
    │
MacBook Air (Arch Linux)
    │
Docker
    │
├── Infrastructure
├── Monitoring
├── Storage
├── Automation
├── Media
├── AI
└── Utilities
```

---

# Project Structure

```
homelab/
└── stacks/
    ├── homepage/
    │   ├── compose.yaml
    │   ├── README.md
    │   ├── .env
    │   ├── config/
    │   └── data/
    │
    ├── portainer/
    ├── prometheus/
    ├── grafana/
    ├── node-exporter/
    └── ...
```

For every service:

- compose.yaml
- README.md
- .env (optional)
- config/ (if needed)
- data/ (if needed)

---

# Phase 0 — Foundation ✅

## Operating System

- [x] Arch Linux
- [x] Docker
- [x] Docker Compose
- [x] Git

## Networking

- [x] Tailscale installed
- [x] MagicDNS working
- [x] Remote access from laptop
- [x] Remote access from phone

---

# Phase 1 — Infrastructure ✅

## Homepage

Status: ✅ Done

Features:

- Dashboard
- Docker integration
- Host validation configured
- Accessible over Tailscale

---

## Portainer

Status: ✅ Done

Features:

- Docker management
- Container logs
- Volumes
- Networks
- Images

---

# Phase 2 — Monitoring 🚧

## Node Exporter

Status: ✅ Done

Provides:

- CPU metrics
- RAM metrics
- Disk metrics
- Network metrics
- Filesystem metrics

---

## Prometheus

Status: ✅ Done

Features:

- Collects metrics
- Stores time-series database
- Scrapes Node Exporter

Current scrape targets:

- Prometheus
- Node Exporter

---

## Grafana

Status: ✅ Done

Completed:

- [x] Container running
- [x] Login page working
- [x] Login
- [x] Change admin password
- [x] Add Prometheus datasource
- [x] Import Node Exporter dashboard
- [x] Verify graphs
- [x] Provisioning via config files (datasource + dashboards)
- [x] Home dashboard set to Node Exporter Full

Recommended Dashboard IDs:

- 1860 — Node Exporter Full
- 893 — Docker
- 193 — Prometheus 2.0 Stats

---

# Phase 3 — Dashboard Polish

Homepage improvements:

- [x] Infrastructure group
- [x] Monitoring group
- [ ] Storage group (add when stacks exist)
- [ ] AI group (add when stacks exist)
- [ ] Media group (add when stacks exist)
- [ ] Automation group (add when stacks exist)

Widgets:

- [x] CPU (via Resources widget)
- [x] Memory (via Resources widget)
- [x] Disk (via Resources widget)
- [x] Network speed (via Resources widget)
- [x] Uptime (via Resources widget)
- [x] Docker
- [x] Weather (via Open-Meteo widget)
- [x] Greeting (via Greeting widget)
- [ ] Calendar (optional)

---

# Phase 4 — Storage

## File Browser

Status: ✅ Done

Purpose

- Web file manager
- Shares `shared/` at repo root, served at :8090
- Default login admin/admin — change on first login

---

## Samba

Status: ✅ Done

Purpose

- Network shares
- Access from macOS
- Access from Windows
- Access from Android
- Shares `shared/` at repo root over SMB (ports 139/445), user `dheeraj`, password in `stacks/samba/.env`

---

## PairDrop

Status: ✅ Done (not in original plan, added for AirDrop-style clipboard/file sharing)

Purpose

- Instant file + text/clipboard sharing between devices on the same Tailscale network
- No accounts, no folders — served at :8082
- Needed a TURN relay (see Coturn below) to actually work across Tailscale — direct
  WebRTC P2P fails because Chrome obfuscates local IPs via mDNS, which can't resolve
  across the Tailscale mesh

---

## Coturn

Status: ✅ Done (added to fix PairDrop over Tailscale)

Purpose

- TURN/STUN relay so PairDrop's WebRTC connections work when direct P2P fails
- `network_mode: host`, no TLS (traffic stays inside the private Tailscale network)
- Credentials in `stacks/coturn/.env`; referenced from `stacks/pairdrop/config/rtc_config.json`

---

## Backups

Status: ⏸️ Deliberately deferred (2026-07-05) — not needed yet, revisit later

Options

- Borg
- Restic

Goals

- Scheduled backups
- Easy restore

---

# Phase 4.5 — Portability & Reliability

Status: ✅ Done (2026-07-05)

Goals

- Fresh machine = `git clone` + `./bootstrap.sh`, nothing else
- Survive a reboot with zero manual steps
- Git holds config only — no data, no secrets, no backups

Done

- [x] `bootstrap.sh` — creates the `homelab` network, `shared/` dir, generates `.env` files from
      `.env.example` templates (random secrets, auto-detected Tailscale hostname via `tailscale
      status`), regenerates PairDrop's `rtc_config.json` from Coturn's credentials, brings up
      every stack. Idempotent — safe to re-run.
- [x] Removed all hardcoded absolute host paths (`/home/dheeraj/...`) from volume mounts in
      homepage, filebrowser, samba — replaced with relative paths so the repo isn't tied to one
      username/home directory
- [x] Added missing `restart: unless-stopped` to homepage (every other stack already had it)
- [x] Centralized the Tailscale hostname into one variable (`HOMEPAGE_VAR_HOSTNAME` in
      `stacks/homepage/.env`) instead of 8+ hardcoded copies across services.yaml/compose files
- [x] Grafana's Prometheus datasource switched from the Tailscale hostname to
      `host.docker.internal` — one less thing that needs reconfiguring on a new machine
- [x] Confirmed `docker.service` is enabled at boot — combined with `restart: unless-stopped` on
      every container, a reboot requires no manual intervention
- [x] Verified live: ran `bootstrap.sh` against the already-running setup, confirmed it's a no-op
      on secrets/network and only recreates containers whose compose file actually changed

Known limitation (accepted, not fixed)

- Grafana admin password, Portainer API key, and File Browser admin password can't be scripted —
  they require an interactive first login. `bootstrap.sh` prints these as manual next steps.

---

# Phase 5 — Utilities

Recommended:

- Vaultwarden
- Uptime Kuma
- Gitea / Forgejo
- Stirling PDF
- Mealie
- Linkding

---

# Phase 6 — Automation

Recommended:

- n8n
- Changedetection.io
- Watchtower (optional)

Ideas:

- Telegram notifications
- Scheduled backups
- RSS automation
- AI workflows

---

# Phase 7 — Media Server

Recommended:

- Jellyfin
- Jellyseerr
- Sonarr
- Radarr
- Prowlarr
- qBittorrent

(Optional)

---

# Phase 8 — AI

Recommended:

- Ollama
- Open WebUI
- LiteLLM
- AnythingLLM

Possible models:

- Llama
- Gemma
- Qwen
- DeepSeek

---

# Phase 9 — Networking

## AdGuard Home

Status: ✅ Done (2026-07-05)

Purpose

- Network-wide DNS ad/tracker blocking
- Grouped under Homepage's "Storage" section (not its own group) to keep the dashboard's 3-column
  row layout intact — a 4th group wraps awkwardly on narrower screens
- Bridge-networked (joins `homelab` like everything else, so Homepage can reach it internally at
  `http://adguard:3000`), but its host-published ports (53 DNS, 3053 web UI) are bound to the
  host's Tailscale IP only (`stacks/adguard/.env` → `TAILSCALE_IP`, detected by `bootstrap.sh` via
  `tailscale ip -4`) — never the LAN or `0.0.0.0`
- Fails closed: if Tailscale isn't up when `bootstrap.sh` runs, `TAILSCALE_IP` defaults to
  `127.0.0.1` rather than opening the ports up on all interfaces
- Admin credentials set via AdGuard's own first-run setup wizard (same category as Grafana/
  Portainer/File Browser's manual first-login steps) — its config dir
  (`stacks/adguard/config/`) stores the password hash, so it's gitignored, not committed
- To actually use it as the tailnet's DNS resolver, set it as a custom nameserver in the
  [Tailscale admin console](https://login.tailscale.com/admin/dns) — a one-time, non-scriptable
  step on Tailscale's side

Future additions:

- Nginx Proxy Manager
- Traefik
- SSL certificates
- Cloudflare Tunnel (optional)

---

# Phase 10 — Security

Goals:

- Least privilege containers
- Proper Docker networks
- Automatic backups
- SSH hardening
- Firewall
- Fail2ban (optional)

---

# Phase 11 — Observability

Future additions:

- Loki
- Promtail
- Alertmanager
- cAdvisor
- Docker metrics
- Log aggregation

---

# Phase 12 — Nice-to-Have

Ideas:

- Immich
- Paperless-ngx
- Audiobookshelf
- Navidrome
- Calibre-Web
- Home Assistant
- Minecraft server

---

# Technical Debt / Cleanup

Networking

- [x] Standardize Docker networking (bridge+homelab, or host for monitoring)
- [x] Decide Host vs Bridge networking
- [x] Create shared Docker network

Docker

- [ ] Decide when to use bind mounts
- [ ] Decide when to use named volumes

Recommendation:

- Config → Bind mount
- Databases → Named volumes
- Media → Bind mount

Documentation

- [ ] README for every service
- [x] Record ports (AGENTS.md)
- [ ] Record dependencies
- [ ] Record credentials

Homepage

- [ ] Add icons
- [ ] Add service descriptions
- [ ] Add monitoring widgets

---

# Current Progress

```
███████████████░░░░░░░░░░░░░░░░ 42%
```

Completed:

✅ Arch Linux

✅ Docker

✅ Tailscale

✅ Homepage

✅ Portainer

✅ Node Exporter

✅ Prometheus

✅ Grafana

---

# Guiding Principles

- Follow official documentation first.
- Understand every line of every compose file.
- Keep each service self-contained.
- Prefer simplicity over cleverness.
- Build reusable patterns.
- Document everything.
- Learn the "why", not just the "how".
