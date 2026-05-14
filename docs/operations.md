# Operations

## Service

```bash
ssh giobox 'systemctl status agent-share-box --no-pager'
ssh giobox 'systemctl restart agent-share-box'
ssh giobox 'journalctl -u agent-share-box -n 100 --no-pager'
ssh giobox 'docker ps --filter name=agent-share-box'
```

## Storage

The default installer creates a loop-mounted ext4 filesystem:

```text
/var/lib/agent-share-box/share.img -> /srv/agent-share-box
```

Check capacity:

```bash
ssh giobox 'df -h /srv/agent-share-box'
```

Check actual host usage:

```bash
ssh giobox 'du -h /var/lib/agent-share-box/share.img'
```

## Resize

Stop the service, unmount the share, grow the image, check the filesystem, and
restart:

```bash
ssh giobox 'systemctl stop agent-share-box'
ssh giobox 'umount /srv/agent-share-box'
ssh giobox 'truncate -s 80G /var/lib/agent-share-box/share.img'
ssh giobox 'e2fsck -f /var/lib/agent-share-box/share.img'
ssh giobox 'resize2fs /var/lib/agent-share-box/share.img'
ssh giobox 'mount /srv/agent-share-box'
ssh giobox 'systemctl start agent-share-box'
```

Do this only when the host filesystem has enough free space.

## Backup

```bash
rsync -av --info=progress2 giobox:/srv/agent-share-box/ ./agent-share-backup/
```

## Credentials

Authentication is disabled by default. Enable it by setting
`AGENT_SHARE_AUTH=1` and `AGENT_SHARE_PASSWORD` on the server, then restart:

```bash
ssh giobox 'sudo cat /etc/agent-share-box/agent-share-box.env'
ssh giobox 'sudoedit /etc/agent-share-box/agent-share-box.env'
ssh giobox 'systemctl restart agent-share-box'
```

Disable it again by setting:

```text
AGENT_SHARE_AUTH=0
AGENT_SHARE_PASSWORD=
```

## Uninstall

This removes the service but leaves the data image in place:

```bash
ssh giobox 'systemctl disable --now agent-share-box'
ssh giobox 'rm -f /etc/systemd/system/agent-share-box.service'
ssh giobox 'systemctl daemon-reload'
```

To remove data too, unmount `/srv/agent-share-box`, remove the matching fstab
line, then delete `/var/lib/agent-share-box/share.img`.
