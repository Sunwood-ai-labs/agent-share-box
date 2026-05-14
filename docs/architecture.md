# Architecture

Agent Share Box keeps the control plane in Git and the data plane on giobox.

```text
local repo
  scripts/
  config/
  docs/

giobox
  /opt/agent-share-box/            systemd container runner
  /etc/agent-share-box/            private environment file
  /var/lib/agent-share-box/        container state and 50GB image
  /srv/agent-share-box/            mounted shared files
```

The service is intentionally small:

- `nginx` serves the custom minimal browser viewer at `/`.
- `copyparty` provides the full browser manager at `/browse/` and
  WebDAV-style operations.
- A single lightweight Docker image contains nginx, Python, and copyparty.
- `systemd` keeps it running.
- A loop-mounted ext4 image caps the share at the configured size.
- Authentication is disabled by default for LAN use. If `AGENT_SHARE_AUTH=1`,
  passwords are generated at deploy time and never written to the public repo.

The first deployment target is a Proxmox host. Docker keeps the runtime
replaceable and avoids leaving Python package state directly on the host.
