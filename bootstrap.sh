#!/usr/bin/env bash
# One-shot setup for a fresh clone of this repo on a new machine.
# Safe to re-run: skips anything already configured/running.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

random_secret() { openssl rand -base64 12 | tr -d '/+=' | cut -c1-16; }

echo "==> Docker network"
if ! docker network inspect homelab >/dev/null 2>&1; then
  docker network create homelab
  echo "  created 'homelab'"
else
  echo "  'homelab' already exists"
fi

echo "==> Shared folder (File Browser / Samba / PairDrop)"
mkdir -p shared stacks/filebrowser/config stacks/filebrowser/database

echo "==> Detecting hostname"
HOSTNAME_GUESS=$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//' | cut -d. -f1)
if [[ -z "$HOSTNAME_GUESS" ]]; then
  HOSTNAME_GUESS=$(hostname)
fi
echo "  using: $HOSTNAME_GUESS (edit stacks/homepage/.env HOMEPAGE_VAR_HOSTNAME if wrong)"

echo "==> Secrets (.env files)"
for stack in homepage samba coturn; do
  dir="stacks/$stack"
  if [[ -f "$dir/.env" ]]; then
    echo "  $dir/.env already exists, leaving it alone"
  elif [[ -f "$dir/.env.example" ]]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "  generated $dir/.env from template"
  fi
done

# Only touch freshly-templated placeholder values, never a real configured value
grep -q "your-tailscale-hostname" stacks/homepage/.env 2>/dev/null &&
  sed -i "s/your-tailscale-hostname/$HOSTNAME_GUESS/" stacks/homepage/.env
grep -q "^SAMBA_PASSWORD=changeme" stacks/samba/.env 2>/dev/null &&
  sed -i "s/^SAMBA_PASSWORD=changeme/SAMBA_PASSWORD=$(random_secret)/" stacks/samba/.env
grep -q "^TURN_PASSWORD=changeme" stacks/coturn/.env 2>/dev/null &&
  sed -i "s/^TURN_PASSWORD=changeme/TURN_PASSWORD=$(random_secret)/" stacks/coturn/.env

echo "==> PairDrop TURN config (regenerated from coturn's .env every run)"
TURN_USER=$(grep '^TURN_USER=' stacks/coturn/.env | cut -d= -f2)
TURN_PASSWORD=$(grep '^TURN_PASSWORD=' stacks/coturn/.env | cut -d= -f2)
mkdir -p stacks/pairdrop/config
cat > stacks/pairdrop/config/rtc_config.json <<EOF
{
  "sdpSemantics": "unified-plan",
  "iceServers": [
    { "urls": "stun:${HOSTNAME_GUESS}:3478" },
    {
      "urls": "turn:${HOSTNAME_GUESS}:3478",
      "username": "${TURN_USER}",
      "credential": "${TURN_PASSWORD}"
    }
  ]
}
EOF

echo "==> Starting all stacks"
for compose in stacks/*/docker-compose.yml; do
  dir=$(dirname "$compose")
  echo "  -> $dir"
  (cd "$dir" && docker compose up -d)
done

cat <<EOF

==> Done. Manual first-time steps (need a browser, can't be scripted):
  - Grafana      http://${HOSTNAME_GUESS}:3001   log in admin/admin, set a real password,
                 then update HOMEPAGE_VAR_GRAFANA_USERNAME/PASSWORD in stacks/homepage/.env
  - Portainer    https://${HOSTNAME_GUESS}:9443  create your admin account, then generate
                 an API token (My account -> Access tokens) and note your environment ID,
                 set HOMEPAGE_VAR_PORTAINER_KEY/ENV in stacks/homepage/.env
  - File Browser http://${HOSTNAME_GUESS}:8090   log in admin/admin and change the password
                 (see AGENTS.md for the CLI command - the UI has no "change password" for admin)

  After updating stacks/homepage/.env, apply it with:
    (cd stacks/homepage && docker compose up -d --force-recreate)
EOF
