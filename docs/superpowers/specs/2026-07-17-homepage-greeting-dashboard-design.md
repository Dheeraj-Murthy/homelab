# Homepage Greeting Dashboard — Phase 1 Design

## Goal

Transform the current Homepage dashboard into a personal command center that greets
Dheeraj with system stats, weather, and organized service groups when opening the
browser.

## Scope (Phase 1)

Add greeting, weather, resources (CPU/RAM/disk/network/uptime), and clean up the
service card layout. Only modify existing files — no new stacks.

Future phases can add: GitHub contributions, LeetCode stats, Spotify, and new service
stacks (Jellyfin, Immich, Paperless, Gitea, Uptime Kuma).

## Top Bar (widgets.yaml)

| Order | Widget     | Details                                                    |
| ----- | ---------- | ---------------------------------------------------------- |
| 1     | Greeting   | "Good Evening, Dheeraj" (static text, hot-reload on edit)  |
| 2     | Resources  | CPU, memory, disk `/rootfs`, network, uptime               |
| 3     | Datetime   | Existing — day + date                                      |
| 4     | Search     | Existing — DuckDuckGo                                      |
| 5     | Open-Meteo | Weather for Bangalore (12.9716, 77.5946), metric units     |

The Glances info widget is replaced by the Resources widget, which shows the same
data (CPU, memory, disk) plus network speed and uptime — all without needing a
separate Glances service for the info bar.

## Service Cards (services.yaml)

Keep existing groups, clean up layout.

**Group 1: Infrastructure**
- Homepage — link only, no widget
- Portainer — portainer widget (existing)
- AdGuard Home — adguard widget (existing)

**Group 2: Monitoring**
- Grafana — grafana widget (existing)
- Prometheus — prometheus widget (existing)
- Glances — glances containers widget (existing)
- CPU History — glances cpu chart (existing, widget-only, no link)
- Memory History — glances memory chart (existing, widget-only, no link)

**Group 3: Storage**
- File Browser — link only (existing)
- PairDrop — link only (existing)
- Samba — link only (existing)

## Layout (settings.yaml)

Add `layout` key for structured grid:

```yaml
layout:
  Infrastructure:
    style: row
    columns: 3
  Monitoring:
    style: row
    columns: 3
  Storage:
    style: row
    columns: 3
```

## Files to Modify

### 1. `config/widgets.yaml`

Replace Glances info widget with Resources. Add greeting and Open-Meteo.

```yaml
- greeting:
    text_size: xl
    text: "Good Evening, Dheeraj"

- resources:
    label: Server
    cpu: true
    memory: true
    disk: /rootfs
    network: true
    uptime: true
    units: metric
    refresh: 5000

- datetime:
    text_format: dddd, MMMM Do
    locale: en

- search:
    provider: duckduckgo
    target: _blank

- openmeteo:
    label: Bangalore
    latitude: 12.9716
    longitude: 77.5946
    timezone: Asia/Kolkata
    units: metric
    cache: 5
```

### 2. `config/settings.yaml`

Add `layout` section. Keep existing theme/background/color. Remove placeholder
weather API keys (replaced by Open-Meteo which needs no key).

### 3. `config/services.yaml`

Keep existing 3 groups with existing services. No new services added.

## What Stays the Same

- Dracula theme (custom.css) — no changes
- Bookmarks (bookmarks.yaml) — no changes
- Docker integration (docker.yaml) — no changes
- Background image (Dracula.png) — no changes
- docker-compose.yml — no changes
- .env / .env.example — no changes

## Verification

1. `docker compose -f stacks/homepage/docker-compose.yml up -d --force-recreate`
2. Open `http://<hostname>:3000`
3. Verify greeting text appears in the top bar
4. Verify Resources widget shows CPU, memory, disk, network, uptime
5. Verify weather shows Bangalore conditions
6. Verify 3 service groups appear (Infrastructure, Monitoring, Storage)
7. Verify existing widgets still work (Portainer, AdGuard, Grafana, Prometheus, Glances)
8. Verify Dracula theme is intact
