# Time Machine Backup Drive

## Goal

Dedicated external HDD for backing up the MacBook Pro (512GB, ~300GB used) via
macOS Time Machine over SMB. Keep roughly 1 backup at a time (macOS prunes
automatically). Existing `shared/` file storage must remain untouched and both
shares served from the same Samba container.

## Constraints

- Server is a MacBook Air 2015 running Arch Linux + Docker (USB-A 3.0).
- Existing Samba container (`stacks/samba/`) currently serves only `shared/`.
- External drive: 466GB, currently APFS (old backups, safe to wipe), connected
  via Initio INIC-1618L USB-SATA bridge — enumerated as `/dev/sdc`.
- No CI/tests; repo follows AGENTS.md conventions (relative volume paths,
  `.env` gitignored, `data/`/`shared/` never committed).

## Design

### 1. Format drive

- `wipefs -a /dev/sdc`
- GPT label, single ext4 partition `mkfs.ext4 /dev/sdc1`
- Drive label/size will be confirmed before wiping (APFS, no data to keep).

### 2. Mount on host

- Mount at `/mnt/timemachine`, owned by UID/GID 1000 (`dheeraj`).
- Add to `/etc/fstab` via the partition UUID so it auto-mounts on boot (arch
  standard `ext4` defaults entry). Mount point must be fixed for the Samba
  volume mount; do NOT use relative paths here — it is host storage, not part
  of the repo (this is the documented exception; repo volume mounts stay
  relative, the host mount is system-level).

### 3. Samba Time Machine share

- Add a second share to the existing samba container via `-s`:
  `-s "TimeMachine;/mnt/timemachine;yes;no;no;dheeraj"` plus Time Machine VFS
  options so macOS recognizes it as a Time Machine target:
  - `vfs objects = catia fruit streams_xattr`
  - `fruit:metadata = netatalk`
  - `fruit:model = MacSamba`
  - `fruit:posix_rename = yes`
  - `fruit:time machine = yes`
- Wire into compose: add `- /mnt/timemachine:/mnt/timemachine` volume, extend
  the command. Reuse the existing single Samba user `dheeraj` (same
  `SAMBA_PASSWORD`) — no new env var needed.

### 4. Recreate Samba

- `docker compose -f stacks/samba/docker-compose.yml up -d --force-recreate`
- Verify share list with the client or `docker exec samba smbstatus`.

## Data flow

MacBook Pro → Finder `smb://macbook-air-intel` → `TimeMachine` share → Samba
(fruit VFS) → ext4 partition on `/dev/sdc1` mounted at `/mnt/timemachine`.
Time Machine creates a sparse bundle disk image; oldest backups pruned per
macOS retention (1 backup + thin local snapshots).

## Error handling

- If USB drive is unplugged/replugged: fstab mount by UUID may fail if device
  reappears as a different node — set `nofail` option so boot continues.
- If Samba hasn't attached the drive yet (container started before mount), the
  share simply shows empty until the mount exists; recreate container if
  needed. Drive is permanent (plugged in), so this is low risk.
- macOS "backup failed" → check mount present (`mountpoint /mnt/timemachine`),
  share visible (`smbclient`), and macOS Date & Time/Time Machine settings.

## Out of scope

- Backups of the server itself / `shared/` (still deferred, story.md Phase 4).
- Borg/Restic scheduling.
- Sizing, quotas, or multi-backup retention tuning.

## Verification

1. `lsblk -f /dev/sdc` shows `ext4` partition, mounted at `/mnt/timemachine`.
2. Reboot-proof: fstab mount survives (or `nofail` boot passes).
3. Samba shows two shares: `Shared` and `TimeMachine`.
4. `docker exec samba testparm` contains the fruit/time machine lines.
5. (User) MacBook Pro sees the share and Time Machine accepts it as backup
   destination.