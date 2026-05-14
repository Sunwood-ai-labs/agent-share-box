# Agent Share Box

Lightweight file sharing for agent workflows.

This repo deploys a small Dockerized
[copyparty](https://github.com/9001/copyparty)-based share behind nginx. The
browser root is a minimal read-only file dashboard, while `/browse/` exposes the
full copyparty interface and WebDAV/curl clients keep using the root URL. It is
meant for Markdown articles, screenshots, generated images, and other handoff
files between PCs.

## Default Deployment

- Host: `giobox`
- Service: `agent-share-box.service`
- URL: `http://<giobox-ip>:3923/`
- Data path: `/srv/agent-share-box`
- Quota shape: 50 GB loop-mounted ext4 image at
  `/var/lib/agent-share-box/share.img`
- Runtime: lightweight Docker image, systemd-managed
- Browser UI: custom minimal viewer at `/`, manager at `/manage`, recent at
  `/recent`, copyparty tools at `/party/`
- Auth: disabled by default for LAN use; set `AGENT_SHARE_AUTH=1` to require it

The 50 GB size is a good fit for article drafts and image attachments on the
current giobox root disk. The installer keeps the shared filesystem capped at
that size so agents do not accidentally fill the host with one directory.

## Deploy To giobox

From this repo:

```bash
./scripts/deploy-giobox.sh
```

The default deployment is open on the local network. To require Basic auth, set
`AGENT_SHARE_AUTH=1`; the script generates a random password unless
`AGENT_SHARE_PASSWORD` is already set. Credentials are not committed; they are
stored on the server in:

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

Enable auth:

```bash
AGENT_SHARE_AUTH=1 ./scripts/deploy-giobox.sh
```

## Smoke Test

After deploy, use the values printed by the deploy script:

```bash
AGENT_SHARE_URL=http://<giobox-ip>:3923 \
./scripts/smoke-test.sh
```

The smoke test uploads a Markdown file with curl/WebDAV semantics, downloads it
again, and checks the content matches.

## Daily Use

Browser:

```text
http://<giobox-ip>:3923/
```

The top page is intentionally minimal for checking and reading files. Use
`http://<giobox-ip>:3923/manage` for simple uploads and folder creation, or
`http://<giobox-ip>:3923/party/?h` for copyparty's advanced UI.

curl upload:

```bash
curl -T article.md http://<giobox-ip>:3923/articles/article.md
```

macOS Finder WebDAV:

```text
http://<giobox-ip>:3923/
```

Use "Connect to Server" in Finder. No username or password is needed in the
default LAN mode.

macOS local mount:

```bash
./scripts/configure-macos-mount.sh
./scripts/mount-macos.sh
./scripts/status-macos.sh
```

The helper uses macOS WebDAV mounting directly, so the default LAN mode does
not need a username or password.

By default this creates a convenient symlink at:

```text
~/agent-share-box -> /Volumes/<giobox-ip>
```

Unmount when needed:

```bash
./scripts/unmount-macos.sh
```

## Operations

```bash
ssh giobox 'systemctl status agent-share-box --no-pager'
ssh giobox 'journalctl -u agent-share-box -n 80 --no-pager'
ssh giobox 'df -h /srv/agent-share-box'
ssh giobox 'du -sh /srv/agent-share-box'
```

See [docs/operations.md](docs/operations.md) for backup, resizing, and
uninstall notes.
