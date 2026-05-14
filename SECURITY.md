# Security

Agent Share Box is intended for trusted personal or lab networks.

## Secrets

Do not commit real credentials, generated environment files, data directories,
logs, backups, or copied user content. The deploy script writes live credentials
only to:

```text
/etc/agent-share-box/agent-share-box.env
```

## Exposure

The default deployment listens on plain HTTP port `3923`. Use it on a trusted
LAN, over SSH tunneling, or behind a TLS reverse proxy. Do not expose the
service directly to the public internet without adding TLS, stronger access
controls, and monitoring.

## Reporting

For security issues in this repository, open a private advisory or contact the
repository owner before publishing exploit details.

