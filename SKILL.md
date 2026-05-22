---
name: agent-share-box
description: Use when setting up, deploying, operating, or troubleshooting Agent Share Box, lightweight LAN file sharing, WebDAV mounts, Markdown article previews, shared image attachments, giobox, Proxmox, or PC-to-PC agent file exchange.
---

# Agent Share Box

## Overview

Agent Share Box is the preferred lightweight LAN file-sharing pattern for agent workflows: Dockerized `nginx + copyparty`, a capped loop-mounted ext4 data volume, minimal browser UI, WebDAV/curl access, and macOS local mounting.

Use this repository as the implementation source:

```text
/Users/admin/Prj/agent-share-box
https://github.com/Sunwood-ai-labs/agent-share-box
```

## When To Use

- User wants a small file-sharing server for Markdown articles, screenshots, generated images, attachments, or agent handoff files.
- User mentions `giobox`, Proxmox, LAN-only sharing, WebDAV, local mount, `/Users/admin/agent-share-box`, or browser preview.
- User asks why pages like `Manage`, `Recent`, or Markdown preview still look like copyparty.
- User wants server and client setup instructions, deploy verification, resize, backup, or auth/no-auth changes.

Do not use this for cloud storage, public internet hosting, secrets storage, or collaborative editing suites.

## Current Known Instance

| Item | Value |
| --- | --- |
| Host | `giobox` |
| URL | `http://192.168.11.250:3923/` |
| Service | `agent-share-box.service` |
| Data mount | `/srv/agent-share-box` |
| Data image | `/var/lib/agent-share-box/share.img` |
| Size | `50G` requested, about `49G` usable |
| Auth | `AGENT_SHARE_AUTH=0` by default for LAN |
| macOS link | `/Users/admin/agent-share-box -> /Volumes/192.168.11.250` |

## Server Setup

From the repo:

```bash
cd /Users/admin/Prj/agent-share-box
./scripts/deploy-giobox.sh
```

Useful overrides:

```bash
AGENT_SHARE_HOST=giobox \
AGENT_SHARE_SIZE=50G \
AGENT_SHARE_PORT=3923 \
AGENT_SHARE_DATA_DIR=/srv/agent-share-box \
./scripts/deploy-giobox.sh
```

Enable Basic auth only when needed:

```bash
AGENT_SHARE_AUTH=1 AGENT_SHARE_PASSWORD='<password>' ./scripts/deploy-giobox.sh
```

The installer provisions Docker, builds `agent-share-box:local`, creates or reuses the loop ext4 image, writes `/etc/agent-share-box/agent-share-box.env`, installs systemd, and restarts the container.

## Client Setup

macOS local mount:

```bash
cd /Users/admin/Prj/agent-share-box
./scripts/configure-macos-mount.sh
./scripts/mount-macos.sh
./scripts/status-macos.sh
```

Default symlink:

```text
/Users/admin/agent-share-box
```

Unmount:

```bash
./scripts/unmount-macos.sh
```

curl upload:

```bash
curl -T article.md http://192.168.11.250:3923/articles/article.md
```

Browser surfaces:

| URL | Purpose |
| --- | --- |
| `/` | Minimal file browser |
| `/manage` | Minimal upload/folder page |
| `/recent` | Recent files |
| `/view/.../*.md` | Minimal Markdown article preview |
| `/browse/.../*.md` | Also intercepted by custom Markdown preview |
| `/party/?h` | Advanced copyparty UI fallback |

## Verification

Run after any deploy or UI change:

```bash
cd /Users/admin/Prj/agent-share-box
AGENT_SHARE_URL=http://192.168.11.250:3923 ./scripts/smoke-test.sh
ssh giobox 'systemctl is-active agent-share-box'
ssh giobox 'docker ps --filter name=agent-share-box'
ssh giobox 'df -h /srv/agent-share-box'
./scripts/status-macos.sh
```

For UI changes, verify in a real browser:

- `/`
- `/manage`
- `/recent`
- `/browse/articles/demo/draft.md`
- `/browse/?h` redirects to `/manage`
- `/browse/?ru` redirects to `/recent`

## Operations

Status/logs:

```bash
ssh giobox 'systemctl status agent-share-box --no-pager'
ssh giobox 'journalctl -u agent-share-box -n 100 --no-pager'
ssh giobox 'docker logs --tail 120 agent-share-box'
```

Resize:

```bash
ssh giobox 'systemctl stop agent-share-box'
ssh giobox 'umount /srv/agent-share-box'
ssh giobox 'truncate -s 80G /var/lib/agent-share-box/share.img'
ssh giobox 'e2fsck -f /var/lib/agent-share-box/share.img'
ssh giobox 'resize2fs /var/lib/agent-share-box/share.img'
ssh giobox 'mount /srv/agent-share-box'
ssh giobox 'systemctl start agent-share-box'
```

Backup:

```bash
rsync -av --info=progress2 giobox:/srv/agent-share-box/ ./agent-share-backup/
```

## Common Mistakes

- Styling only copyparty: top UI may change, but `/browse/.../*.md`, `?h`, and `?ru` remain old. Intercept those routes in `docker/nginx.conf`.
- Forgetting `docker/` in deploy payload: `scripts/deploy-giobox.sh` must include it.
- Verifying with curl only after UI work: use the Browser plugin or real browser screenshot.
- Treating LAN no-auth as public safe: keep it private LAN only, or set `AGENT_SHARE_AUTH=1`.
- Breaking macOS mount with auth assumptions: default scripts must work with empty `AGENT_SHARE_PASSWORD`.
