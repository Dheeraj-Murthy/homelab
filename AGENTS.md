# Agents.md

## Overview

Single-user Docker Compose homelab (Arch Linux + Tailscale). Monorepo of standalone stacks under `stacks/`.

## Fresh Machine Setup

Git holds config only — no data, no secrets, no backups. To stand this up on a new machine:

```bash
git clone <repo> homelab && cd homelab
./bootstrap.sh
```

This creates the `homelab` docker network, the `shared/` folder, generates `.env` files from
`.env.example` templates (random passwords, detected Tailscale hostname), and starts every stack.
It's idempotent — re-running it skips anything already configured/running.

Four things can't be scripted (need a browser, first-login flows) and are printed at the end of
`bootstrap.sh`: setting the Grafana admin password, generating a Portainer API token, changing
the File Browser admin password, and running the AdGuard Home setup wizard. After doing those,
update `stacks/homepage/.env` to match and run
`(cd stacks/homepage && docker compose up -d --force-recreate)`.

File Browser has no "change password" UI for the admin user — use the CLI inside the container
(this is what `bootstrap.sh`'s final message points at, and the `-c` flag is required or it
targets the wrong database):

```bash
docker exec -it filebrowser filebrowser -c /config/settings.json users update admin -p <new-password>
```

All containers use `restart: unless-stopped` and `docker.service` is enabled at boot, so once
running, everything survives a reboot with no further action.

## Commands

```bash
# Start/stop a single stack
docker compose -f stacks/<name>/docker-compose.yml up -d
docker compose -f stacks/<name>/docker-compose.yml down

# View logs
docker compose -f stacks/<name>/docker-compose.yml logs -f

# Recreate after config changes
docker compose -f stacks/<name>/docker-compose.yml up -d --force-recreate
```

## Network

All stacks that use bridge networking connect to the shared external network `homelab`. Create it once:

```bash
docker network create homelab
```

Stacks using `network_mode: host` (prometheus, node-exporter, coturn) ignore this network entirely.

## Ports

| Service     | Port      |
| ----------- | --------- |
| Homepage    | 3000      |
| Grafana     | 3001      |
| Portainer   | 9443      |
| Prometheus  | 9090      |
| Node Exporter | 9100 (host, no published port) |
| Glances     | 61208     |
| File Browser| 8090      |
| PairDrop    | 8082      |
| Samba       | 139, 445  |
| Coturn      | 3478, 49160-49200 |
| AdGuard Home| 53 (DNS), 3053 (web UI) — Tailscale IP only |

## Stack Conventions

- Each stack is self-contained with its own `docker-compose.yml`
- Config goes in `config/`, persistent data in `data/` (exception: filebrowser keeps its DB in
  `database/`)
- Gitignored — do not commit: `data/`, `backups/`, `shared/`, all `.env`, plus
  `stacks/adguard/config/` (holds the admin password hash) and `stacks/pairdrop/config/rtc_config.json`
  (regenerated from coturn's `.env` every `bootstrap.sh` run). These are runtime state, not config.
- Volume paths are relative (`./config`, `../../shared`) — never hardcode absolute host paths,
  they break portability to a new machine/user
- `.env` files hold real secrets and are gitignored; `.env.example` holds the committed template
  with placeholder values — keep them in sync when adding a new secret
- No backup strategy yet (deliberately deferred — see story.md Phase 4)

## Key Files

- `story.md` — roadmap, progress tracking, architecture notes
- `docs/` — design docs and superpowers plans/specs for past features
- `stacks/homepage/config/` — Homepage dashboard config (services.yaml, docker.yaml, widgets.yaml, etc.)
- `stacks/autoheal/` — tiny stack that restarts any container labeled `autoheal=true` when unhealthy

## No CI/CD, tests, linting, or typechecking

This is a simple infrastructure-as-code repo. No build/test/format runners.

## Homelab Hostname

Services reference the host via its Tailscale hostname. This lives in one place —
`HOMEPAGE_VAR_HOSTNAME` in `stacks/homepage/.env` — and is used both for Homepage's own
`{{HOMEPAGE_VAR_HOSTNAME}}` template substitution in `services.yaml` and for Docker Compose's
`${HOMEPAGE_VAR_HOSTNAME}` substitution in `docker-compose.yml` (`HOMEPAGE_ALLOWED_HOSTS`).
`bootstrap.sh` auto-detects it via `tailscale status`. Container-to-container calls (e.g. Grafana
→ Prometheus) use `host.docker.internal` instead, which doesn't need the hostname at all. Note:
`HOMEPAGE_ALLOWED_HOSTS` in `stacks/homepage/docker-compose.yml` also lists a few hardcoded
device hostnames/IPs alongside `${HOMEPAGE_VAR_HOSTNAME}` — `bootstrap.sh` won't touch those, so
a device that changes its Tailscale name stops being able to reach the dashboard.

AdGuard Home is different: it needs an actual Tailscale *IP* (not hostname) to scope its published
ports (`stacks/adguard/.env` → `TAILSCALE_IP`), so only tailnet clients can reach its DNS/web UI —
never the LAN or `0.0.0.0`. `bootstrap.sh` detects it via `tailscale ip -4`. If Tailscale isn't up
yet at bootstrap time, it fails closed to `127.0.0.1` (nothing reachable) rather than opening it up
on all interfaces — re-run bootstrap or update `stacks/adguard/.env` manually once Tailscale is up.

**Exit-node DNS gotcha:** when a client uses this homelab as its Tailscale exit node, it routes ALL
DNS through the exit node — which is AdGuard Home here. AdGuard forwards MagicDNS names
(`*.taile000de.ts.net`) to its public upstream and gets NXDOMAIN, so every service shows "not
found" while the exit node is active. Fix: in AdGuard Home, Settings → DNS settings → Upstream DNS
servers, add `[/taile000de.ts.net/]100.100.100.100` ahead of the public upstream (100.100.100.100 is
Tailscale's MagicDNS resolver; the AdGuard container can reach it). Equivalent: add it as the first
entry of `dns.upstream_dns` in `stacks/adguard/config/AdGuardHome.yaml` and restart. This is a
manual step on every fresh machine (AdGuard's config is gitignored runtime state).
