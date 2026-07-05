# Phase 3 — Dashboard Polish

## Summary

Update Homepage config to organize services into groups and add missing widgets.

## Changes

### services.yaml
- **Infrastructure** group: Homepage, Portainer (exist)
- **Monitoring** group: Prometheus, Grafana, Node Exporter (new)
- Placeholder groups for Storage, Automation, Media, AI (empty, ready for future stacks)

### widgets.yaml
- Add Docker widget (docker socket already configured in docker.yaml)
- CPU/Memory/Disk resources and search widget already exist — keep as is

## Open Items
- Weather/Calendar widgets skipped (optional, needs API keys)
- Node Exporter has no web UI — listed as "no dashboard" in group
