# Architecture

Agent Share Box keeps the control plane in Git and the data plane on giobox.

```text
local repo
  scripts/
  config/
  docs/

giobox
  /opt/agent-share-box/venv        copyparty runtime
  /etc/agent-share-box/            private environment file
  /var/lib/agent-share-box/        state and 50GB image
  /srv/agent-share-box/            mounted shared files
```

The service is intentionally small:

- `copyparty` provides browser upload/download and WebDAV-style operations.
- `systemd` keeps it running.
- A loop-mounted ext4 image caps the share at the configured size.
- Passwords are generated at deploy time and never written to the public repo.

The first deployment target is a Proxmox host where Docker is not required.
That keeps host changes small and avoids adding another daemon to the
hypervisor.

