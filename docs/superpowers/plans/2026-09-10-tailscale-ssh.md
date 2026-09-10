# Tailscale SSH Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable SSH access to the homelab host via Tailscale SSH so `dheeraj` can log in from tailnet devices (MacBook Pro, phone) with zero key management.

**Architecture:** Enable Tailscale's built-in SSH server inside the already-running `tailscaled` daemon via the additive `tailscale set --ssh` command (which preserves exit-node advertising). Auth is tailnet identity; OpenSSH's `sshd` stays disabled.

**Tech Stack:** Tailscale (CLI v1.98.x), no code changes.

## Global Constraints

- The node MUST keep advertising itself as an exit node — use `tailscale set` (additive), NEVER `tailscale up`, which would drop the `--advertise-exit-node` flag (and any other existing flags).
- `dheeraj` has NO passwordless sudo. Any `sudo` command must be run by the user with their own password; do not attempt `sudo -n`.
- OpenSSH `sshd` remains `disabled` — Tailscale SSH owns port 22 on the tailnet interface; do not start or enable sshd.
- No CI/tests/linting in this repo (per AGENTS.md); verification is operational.

---

### Task 1: Enable Tailscale SSH on the node

**Files:** none (no repo file is created or modified by this feature)

**Interfaces:**
- Consumes: `tailscale` CLI on the host (1.98.10)
- Produces: Node `acap` containing `["ssh-behavior-v1", "ssh-env-vars", ...]` and a listener on 100.99.178.72:22

- [ ] **Step 1: Confirm the additive command is correct**

Run: `tailscale set --help | grep -E "\-\-ssh"`
Expected: prints `--ssh, --ssh=false` and the help line `run an SSH server, permitting access per tailnet admin's declared policy`

- [ ] **Step 2: Have the user enable SSH (needs their password)**

Ask the user to run:

```bash
sudo tailscale set --ssh
```

Expected: no output, command exits 0. (All existing node flags — including `--advertise-exit-node` — are preserved; `set` only applies the flags passed.)

- [ ] **Step 3: Verify the node now advertises SSH**

```bash
tailscale status --json | jq -r '.Self.acap'
```

Expected: JSON array containing `"ssh-behavior-v1"` (not `null`).

- [ ] **Step 4: Verify port 22 is listening on the tailnet IP**

```bash
timeout 3 bash -c 'echo > /dev/tcp/100.99.178.72/22' && echo "port 22 OPEN" || echo "port 22 closed"
```

Expected: prints `port 22 OPEN`.

---

### Task 2: Verify SSH login, handle policy denial

**Files:** none

**Interfaces:**
- Consumes: Task 1's enabled SSH server
- Produces: A confirmed-working `tailscale ssh` login as `dheeraj`

- [ ] **Step 1: Self-test SSH login from the host**

Run: `tailscale ssh dheeraj@macbook-air-intel whoami`

Expected: prints `dheeraj`.

- [ ] **Step 2: If login is refused by tailnet policy**

Have the user open the Tailscale admin console (tailscale.com/admin → Enable SSH, or Access Controls → toggle SSH) and re-run Step 1. If the first device prompt appears, the owner approves it once in the console.

- [ ] **Step 3: Confirm sshd is still off (no port conflict)**

Run: `systemctl is-enabled sshd`
Expected: `disabled` (not `enabled`).

---

### Task 3: Verify from the user's devices (user-side)

**Files:** none

**Interfaces:**
- Consumes: Task 2's working server
- Produces: Confirmed client access from MacBook Pro (and optionally phone)

- [ ] **Step 1: Verify from the MacBook Pro**

On the MacBook Pro: `ssh dheeraj@macbook-air-intel` (or `ssh dheeraj@100.99.178.72`).
Expected: logs in as `dheeraj` after the one-time device approval in the admin console.

- [ ] **Step 2: (Optional) Verify from the phone**

Any SSH client (e.g. Termius) → `dheeraj@macbook-air-intel`.
Expected: logs in as `dheeraj` after one-time device approval.

- [ ] **Step 3: Confirm nothing else changed**

Run: `tailscale status`
Expected: host still listed, exit node still offered; all homelab stacks still reachable (e.g. `curl -sI http://macbook-air-intel:3000` returns HTTP 200).