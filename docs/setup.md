# Setup Guide

This guide splits Agent Share Box setup into server-side and client-side work.

## Server: giobox / Proxmox

Deploy the service from this repo:

```bash
cd /Users/admin/Prj/agent-share-box
./scripts/deploy-giobox.sh
```

Default server behavior:

- Installs `docker.io` and `curl` if needed.
- Builds the local Docker image `agent-share-box:local`.
- Creates or reuses `/var/lib/agent-share-box/share.img`.
- Mounts it at `/srv/agent-share-box`.
- Installs `agent-share-box.service`.
- Runs the service on port `3923`.
- Uses LAN no-auth mode by default.

Useful overrides:

```bash
AGENT_SHARE_HOST=giobox \
AGENT_SHARE_SIZE=50G \
AGENT_SHARE_PORT=3923 \
AGENT_SHARE_DATA_DIR=/srv/agent-share-box \
./scripts/deploy-giobox.sh
```

Enable Basic auth:

```bash
AGENT_SHARE_AUTH=1 AGENT_SHARE_PASSWORD='<password>' ./scripts/deploy-giobox.sh
```

Verify the server:

```bash
AGENT_SHARE_URL=http://192.168.11.250:3923 ./scripts/smoke-test.sh
ssh giobox 'systemctl is-active agent-share-box'
ssh giobox 'docker ps --filter name=agent-share-box'
ssh giobox 'df -h /srv/agent-share-box'
```

## Client: macOS

Configure and mount the share:

```bash
cd /Users/admin/Prj/agent-share-box
./scripts/configure-macos-mount.sh
./scripts/mount-macos.sh
./scripts/status-macos.sh
```

Default local path:

```text
/Users/admin/agent-share-box
```

Unmount:

```bash
./scripts/unmount-macos.sh
```

Upload with curl:

```bash
curl -T article.md http://192.168.11.250:3923/articles/article.md
```

## Browser UI

Use these URLs on the LAN:

| URL | Purpose |
| --- | --- |
| `http://192.168.11.250:3923/` | Minimal file browser |
| `http://192.168.11.250:3923/manage` | Upload and create folders |
| `http://192.168.11.250:3923/recent` | Recent files |
| `http://192.168.11.250:3923/view/.../*.md` | Minimal Markdown preview |
| `http://192.168.11.250:3923/party/?h` | Advanced copyparty fallback |

Legacy copyparty shortcuts are redirected:

- `/browse/?h` -> `/manage`
- `/browse/?ru` -> `/recent`

## Codex Skill

The local Codex skill is installed at:

```text
/Users/admin/.codex/skills/agent-share-box/SKILL.md
```

Use `$agent-share-box` in future threads when deploying, operating, mounting,
or troubleshooting this share.
