# Tailscale SSH Access

## Goal

Get SSH access to the homelab host (the Arch Linux box, hostname
`macbook-air-intel`) from the user's devices, authenticated by tailnet identity.
Scope is a shell on the host itself — not into Docker containers.

## Constraints

- `dheeraj` has no passwordless sudo; privileged one-time steps run with the
  user's password.
- The repo precedent is to scope sensitive services to the tailnet (AdGuard
  binds to the Tailscale IP only). SSH must not listen on the LAN.
- OpenSSH `sshd` is installed but disabled — leave it that way (no port 22
  conflict with Tailscale SSH, no LAN exposure).
- `tailscale up` replaces ALL node flags, which would drop exit-node
  advertising; use `tailscale set` (additive) instead.

## Design

### 1. Enable Tailscale SSH on the node

Run (with `sudo`, additive — preserves `--advertise-exit-node` and anything
else already set):

```
sudo tailscale set --ssh
```

Tailscale's built-in SSH server (inside `tailscaled`) then listens on port 22
of the tailnet interface only. Authentication and authorization come from the
tailnet ACL policy (owner `dcompany2004@`); no SSH keys, no passwords, no
firewall changes.

### 2. Admin console toggle (only if policy denies)

Tailscale SSH is also gated by the tailnet's "Enable SSH" setting
(tailscale.com/admin → Enable SSH). If the first login is refused despite the
node flag, toggle it on there. After that, the first `ssh` from a device
prompts the owner to approve it in the admin console (one-time per device).

### 3. Verify

- From the host itself: `tailscale ssh dheeraj@macbook-air-intel whoami`
  should print `dheeraj`.
- From the MacBook Pro: `ssh dheeraj@macbook-air-intel` (or
  `ssh dheeraj@100.99.178.72`).
- Phone: any SSH client (e.g. Termius) → `dheeraj@macbook-air-intel`.

## Data flow

Device (MacBook Pro / phone) → `tailscale ssh` client → tailscaled's SSH
server on the node → shell as `dheeraj`. Identity = tailnet login; access is
limited to nodes/devices allowed by the tailnet ACL policy.

## Error handling

- Login refused although `set --ssh` succeeded → enable SSH in the admin
  console (one click), retry.
- Exit-node breaks → `set` is additive; nothing else was changed. Re-apply is
  never needed, but if it ever is: `sudo tailscale set --ssh --advertise-exit-node`.

## Out of scope

- SSH into individual containers (`docker exec` unaffected; not a separate
  feature).
- OpenSSH server, key management, port forwarding, alternate ports.
- LAN-reachable SSH (intentionally excluded).
- ACL policy authoring by non-owner (tailnet owner does that in console).

## Verification

1. `tailscale ssh dheeraj@macbook-air-intel whoami` (from host) prints
   `dheeraj`.
2. `tailscale status --json | jq -r '.Self.acap'` lists `ssh*` capabilities.
3. (User) `ssh dheeraj@macbook-air-intel` works from the MacBook Pro.
4. Server's own services unaffected; `sshd` still disabled.