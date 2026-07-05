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

Three things can't be scripted (need a browser, first-login flows) and are printed at the end of
`bootstrap.sh`: setting the Grafana admin password, generating a Portainer API token, and changing
the File Browser admin password. After doing those, update `stacks/homepage/.env` to match and run
`(cd stacks/homepage && docker compose up -d --force-recreate)`.

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

Stacks using `network_mode: host` (prometheus, node-exporter) ignore this network entirely.

## Ports

| Service     | Port      |
| ----------- | --------- |
| Homepage    | 3000      |
| Grafana     | 3001      |
| Portainer   | 9443      |
| Prometheus  | 9090      |
| Glances     | 61208     |
| File Browser| 8090      |
| PairDrop    | 8082      |
| Samba       | 139, 445  |
| Coturn      | 3478, 49160-49200 |

## Stack Conventions

- Each stack is self-contained with its own `docker-compose.yml`
- Config goes in `config/`, persistent data in `data/`
- `data/`, `backups/`, and `shared/` are gitignored — do not commit runtime data
- Volume paths are relative (`./config`, `../../shared`) — never hardcode absolute host paths,
  they break portability to a new machine/user
- `.env` files hold real secrets and are gitignored; `.env.example` holds the committed template
  with placeholder values — keep them in sync when adding a new secret
- No backup strategy yet (deliberately deferred — see story.md Phase 4)

## Key Files

- `story.md` — roadmap, progress tracking, architecture notes
- `stacks/homepage/config/` — Homepage dashboard config (services.yaml, docker.yaml, widgets.yaml, etc.)

## No CI/CD, tests, linting, or typechecking

This is a simple infrastructure-as-code repo. No build/test/format runners.

## Homelab Hostname

Services reference the host via its Tailscale hostname. This lives in one place —
`HOMEPAGE_VAR_HOSTNAME` in `stacks/homepage/.env` — and is used both for Homepage's own
`{{HOMEPAGE_VAR_HOSTNAME}}` template substitution in `services.yaml` and for Docker Compose's
`${HOMEPAGE_VAR_HOSTNAME}` substitution in `docker-compose.yml` (`HOMEPAGE_ALLOWED_HOSTS`).
`bootstrap.sh` auto-detects it via `tailscale status`. Container-to-container calls (e.g. Grafana
→ Prometheus) use `host.docker.internal` instead, which doesn't need the hostname at all.
