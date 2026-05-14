# Agent Share Box

Lightweight file sharing for agent workflows.

This repo deploys a small [copyparty](https://github.com/9001/copyparty)-based
share that works from browsers, curl, WebDAV clients, and automation scripts.
It is meant for Markdown articles, screenshots, generated images, and other
handoff files between PCs.

## Default Deployment

- Host: `giobox`
- Service: `agent-share-box.service`
- URL: `http://<giobox-ip>:3923/`
- Data path: `/srv/agent-share-box`
- Quota shape: 50 GB loop-mounted ext4 image at
  `/var/lib/agent-share-box/share.img`
- Runtime: Python venv + systemd, no Docker required

The 50 GB size is a good fit for article drafts and image attachments on the
current giobox root disk. The installer keeps the shared filesystem capped at
that size so agents do not accidentally fill the host with one directory.

## Deploy To giobox

From this repo:

```bash
./scripts/deploy-giobox.sh
```

The script generates a random password unless `AGENT_SHARE_PASSWORD` is already
set. Credentials are not committed; they are stored on the server in:

```text
/etc/agent-share-box/agent-share-box.env
```

Useful overrides:

```bash
AGENT_SHARE_HOST=giobox \
AGENT_SHARE_SIZE=50G \
AGENT_SHARE_PORT=3923 \
AGENT_SHARE_USERNAME=agent \
./scripts/deploy-giobox.sh
```

## Smoke Test

After deploy, use the values printed by the deploy script:

```bash
AGENT_SHARE_URL=http://<giobox-ip>:3923 \
AGENT_SHARE_USERNAME=agent \
AGENT_SHARE_PASSWORD='<password>' \
./scripts/smoke-test.sh
```

The smoke test uploads a Markdown file with curl/WebDAV semantics, downloads it
again, and checks the content matches.

## Daily Use

Browser:

```text
http://<giobox-ip>:3923/
```

curl upload:

```bash
curl -u agent:'<password>' -T article.md \
  http://<giobox-ip>:3923/articles/article.md
```

macOS Finder WebDAV:

```text
http://<giobox-ip>:3923/
```

Use "Connect to Server" in Finder, then authenticate with the generated
username and password.

## Operations

```bash
ssh giobox 'systemctl status agent-share-box --no-pager'
ssh giobox 'journalctl -u agent-share-box -n 80 --no-pager'
ssh giobox 'df -h /srv/agent-share-box'
ssh giobox 'du -sh /srv/agent-share-box'
```

See [docs/operations.md](docs/operations.md) for backup, resizing, and
uninstall notes.

