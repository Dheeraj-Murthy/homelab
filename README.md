# Homelab

A single-user Docker Compose homelab running on Arch Linux, reachable remotely over Tailscale.
Every service lives in its own self-contained stack under `stacks/`. Git holds config only — no
data, no secrets, no backups.

## Quick Start

On a fresh machine:

```bash
git clone <repo-url> homelab && cd homelab
./bootstrap.sh
```

`bootstrap.sh` creates the shared Docker network, generates `.env` files from the committed
`.env.example` templates (random passwords, auto-detected Tailscale hostname), and starts every
stack. It's safe to re-run any time.

Four things need a one-time manual login (can't be scripted) and are printed at the end of the
script:

- **Grafana** — set the admin password
- **Portainer** — create your admin account, generate an API token
- **File Browser** — change the default admin password
- **AdGuard Home** — run the setup wizard, set the admin password

After those, update `stacks/homepage/.env` to match and run:

```bash
cd stacks/homepage && docker compose up -d --force-recreate
```

Everything uses `restart: unless-stopped` and Docker starts on boot, so once it's up, it survives
a reboot with no further action.

To actually use AdGuard Home as your tailnet's DNS resolver, set it as a custom nameserver in the
[Tailscale admin console](https://login.tailscale.com/admin/dns) — that's a one-time step on
Tailscale's side that can't be scripted from this repo.

## Services

| Service | Port | Purpose |
| --- | --- | --- |
| [Homepage](stacks/homepage) | 3000 | Dashboard — links + live widgets for everything below |
| [Grafana](stacks/grafana) | 3001 | Metrics dashboards |
| [Portainer](stacks/portainer) | 9443 | Docker container management |
| [Prometheus](stacks/prometheus) | 9090 | Metrics collection & storage |
| [Node Exporter](stacks/node-exporter) | (host) | Host CPU/RAM/disk/network metrics for Prometheus |
| [Glances](stacks/glances) | 61208 | Host + per-container resource stats |
| [File Browser](stacks/filebrowser) | 8090 | Web-based file manager |
| [Samba](stacks/samba) | 139, 445 | Network file share (mount as a drive on macOS/Windows/Android) |
| [PairDrop](stacks/pairdrop) | 8082 | AirDrop-style instant file & clipboard sharing between devices |
| [Coturn](stacks/coturn) | 3478, 49160-49200 | TURN relay so PairDrop works across Tailscale |
| [AdGuard Home](stacks/adguard) | 53, 3053 | DNS ad-blocking, reachable over Tailscale only |

File Browser, Samba, and PairDrop all share the same `shared/` folder at the repo root.

## Architecture

- Bridge-networked stacks join the shared external Docker network `homelab`.
- Host-networked stacks (Prometheus, Node Exporter, Coturn) use `network_mode: host` — they need
  real host visibility or ports that don't play well with Docker's NAT.
- The Tailscale hostname lives in one place, `HOMEPAGE_VAR_HOSTNAME` in `stacks/homepage/.env`,
  and is templated everywhere else it's needed. Container-to-container calls use
  `host.docker.internal` instead, so they don't depend on Tailscale DNS at all.
- AdGuard Home publishes its DNS (53) and web UI (3053) ports bound to the host's Tailscale IP
  only (`stacks/adguard/.env` → `TAILSCALE_IP`), so it's unreachable from the LAN or internet —
  only tailnet devices can use it.

## More Detail

- [`AGENTS.md`](AGENTS.md) — conventions for working in this repo (commands, networking, ports,
  stack layout)
- [`story.md`](story.md) — roadmap, what's done, what's next
