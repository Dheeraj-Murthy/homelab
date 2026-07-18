# Homepage Greeting Dashboard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add greeting, weather, and system resources widgets to the Homepage dashboard, and clean up the service card layout.

**Architecture:** Modify three YAML config files in the existing Homepage stack. No new containers, no new dependencies. Homepage hot-reloads on file save.

**Tech Stack:** Homepage (gethomepage.dev), YAML configuration, Docker Compose

## Global Constraints

- All volume paths are relative (`./config`, `../../shared`) — never hardcode absolute host paths
- `.env` files hold real secrets and are gitignored; `.env.example` holds committed placeholders
- No changes to docker-compose.yml, custom.css, bookmarks.yaml, or docker.yaml
- Existing services and their widgets must continue working unchanged

---

## Task 1: Update widgets.yaml — Replace Glances with Resources, add Greeting and Weather

**Files:**
- Modify: `stacks/homepage/config/widgets.yaml`

- [ ] **Step 1: Read the current widgets.yaml**

```bash
cat stacks/homepage/config/widgets.yaml
```

Confirm current contents: datetime, search, glances (cpu/mem/disk).

- [ ] **Step 2: Write the new widgets.yaml**

Replace the entire file with:

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

- [ ] **Step 3: Verify the file was written correctly**

```bash
cat stacks/homepage/config/widgets.yaml
```

Confirm all 5 widgets present: greeting, resources, datetime, search, openmeteo.

- [ ] **Step 4: Commit**

```bash
git add stacks/homepage/config/widgets.yaml
git commit -m "homepage: add greeting, resources, and weather widgets

Replace Glances info widget with Resources (adds network speed and uptime).
Add Open-Meteo weather for Bangalore. Add time-of-day greeting."
```

---

## Task 2: Update settings.yaml — Add layout grid, remove placeholder API keys

**Files:**
- Modify: `stacks/homepage/config/settings.yaml`

- [ ] **Step 1: Read the current settings.yaml**

```bash
cat stacks/homepage/config/settings.yaml
```

Confirm current contents: title, background, theme, color, statusStyle, etc.
Note the placeholder weather API keys at the bottom.

- [ ] **Step 2: Write the new settings.yaml**

Replace the entire file with:

```yaml
title: Homelab

background:
  image: /images/Dracula.png
  blur: sm
  brightness: 50

theme: dark
color: gray

statusStyle: dot
useEqualHeightCards: true
headerStyle: clean
hideVersion: true
target: _blank

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

Key changes:
- Removed placeholder `providers` section (Open-Meteo needs no API key)
- Added `layout` section for structured grid arrangement of service groups

- [ ] **Step 3: Verify the file was written correctly**

```bash
cat stacks/homepage/config/settings.yaml
```

Confirm: title, background, theme, color, statusStyle, layout sections present.
Confirm: no `providers` section with placeholder API keys.

- [ ] **Step 4: Commit**

```bash
git add stacks/homepage/config/settings.yaml
git commit -m "homepage: add layout grid, remove placeholder weather API keys

Add structured layout for 3 service groups. Remove unused OpenWeatherMap/
WeatherAPI placeholder keys (replaced by Open-Meteo which needs no key)."
```

---

## Task 3: Verify services.yaml — No changes needed

**Files:**
- Read only: `stacks/homepage/config/services.yaml`

- [ ] **Step 1: Read services.yaml and confirm no changes needed**

```bash
cat stacks/homepage/config/services.yaml
```

Confirm the file has 3 groups (Infrastructure, Monitoring, Storage) with existing
services. No modifications required — this task is verification only.

- [ ] **Step 2: Confirm existing service widgets are intact**

Check that these widget configurations still exist and are unchanged:
- Portainer widget: `type: portainer`, `url: http://portainer:9000`
- AdGuard widget: `type: adguard`, `url: http://adguard:80`
- Grafana widget: `type: grafana`, `url: http://host.docker.internal:3001`
- Prometheus widget: `type: prometheus`, `url: http://host.docker.internal:9090`
- Glances widgets: `type: glances`, `url: http://glances:61208`

No commit needed — no changes made.

---

## Task 4: Restart Homepage and verify

**Files:**
- Read only: all modified files from Tasks 1-2

- [ ] **Step 1: Restart Homepage container**

```bash
docker compose -f stacks/homepage/docker-compose.yml up -d --force-recreate
```

Wait for container to be healthy:

```bash
docker compose -f stacks/homepage/docker-compose.yml logs -f
```

Look for "Ready" or similar startup message, then Ctrl+C.

- [ ] **Step 2: Verify the dashboard loads**

Open `http://<tailscale-hostname>:3000` in a browser.

Check:
- [ ] Greeting text "Good Evening, Dheeraj" appears in the top bar
- [ ] Resources widget shows CPU, memory, disk, network, uptime
- [ ] Datetime widget shows current day and date
- [ ] Search bar is present
- [ ] Weather widget shows Bangalore temperature/conditions
- [ ] Infrastructure group has 3 cards (Homepage, Portainer, AdGuard)
- [ ] Monitoring group has 5 cards (Grafana, Prometheus, Glances, CPU History, Memory History)
- [ ] Storage group has 3 cards (File Browser, PairDrop, Samba)
- [ ] Portainer widget shows container count
- [ ] AdGuard widget shows DNS stats
- [ ] Grafana widget shows datasource count
- [ ] Prometheus widget shows target count
- [ ] Glances widgets show charts
- [ ] Dracula theme is intact (dark background, purple/pink accents)

- [ ] **Step 3: Commit any fixups if needed**

If anything looks wrong, fix it and commit:

```bash
git add stacks/homepage/config/
git commit -m "homepage: fix [describe what was fixed]"
```

---

## Task 5: Update story.md — Mark Phase 3 widgets as done

**Files:**
- Modify: `story.md`

- [ ] **Step 1: Read story.md and find the Homepage section**

```bash
grep -n -A 30 "Homepage" story.md
```

- [ ] **Step 2: Update the widget checklist**

Find the widgets TODO section and update:

```
- [x] CPU, Memory, Disk (via Resources widget)
- [x] Network speed (via Resources widget)
- [x] Uptime (via Resources widget)
- [x] Weather (via Open-Meteo widget)
- [x] Greeting (via Greeting widget)
```

- [ ] **Step 3: Commit**

```bash
git add story.md
git commit -m "story: mark Phase 3 homepage widgets as complete"
```
