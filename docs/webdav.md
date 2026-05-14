# WebDAV Notes

Agent Share Box exposes the same authenticated endpoint to browser users and
WebDAV clients.

## curl

Upload:

```bash
curl -u agent:'<password>' -T article.md \
  http://<giobox-ip>:3923/articles/article.md
```

Download:

```bash
curl -u agent:'<password>' \
  http://<giobox-ip>:3923/articles/article.md \
  -o article.md
```

Create a folder:

```bash
curl -u agent:'<password>' -X MKCOL \
  http://<giobox-ip>:3923/articles
```

## macOS Finder

1. Finder -> Go -> Connect to Server.
2. Enter `http://<giobox-ip>:3923/`.
3. Login with the generated username and password.

## Suggested Layout

```text
articles/
  2026-05/
    post-name/
      draft.md
      images/
incoming/
  <agent-name>/
scratch/
  expires-soon/
```

