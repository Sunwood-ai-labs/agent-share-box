#!/usr/bin/env bash
set -euo pipefail

: "${AGENT_SHARE_URL:?AGENT_SHARE_URL is required, for example http://192.168.1.10:3923}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required}"

URL="${AGENT_SHARE_URL%/}"
AUTH="${AGENT_SHARE_USERNAME}:${AGENT_SHARE_PASSWORD}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOCAL_FILE="${TMP_DIR}/agent-share-smoke.md"
REMOTE_URL="${URL}/smoke/agent-share-smoke.md"
DOWNLOADED="${TMP_DIR}/downloaded.md"

cat > "${LOCAL_FILE}" <<EOF
# Agent Share Smoke

Created: ${STAMP}

This Markdown file verifies browser/WebDAV-style upload and download.
EOF

curl -fsS -u "${AUTH}" "${URL}/" >/dev/null
curl -fsS -u "${AUTH}" -X MKCOL "${URL}/smoke" >/dev/null || true
curl -fsS -u "${AUTH}" -T "${LOCAL_FILE}" "${REMOTE_URL}" >/dev/null
curl -fsS -u "${AUTH}" "${REMOTE_URL}" -o "${DOWNLOADED}"
cmp "${LOCAL_FILE}" "${DOWNLOADED}"

echo "Smoke test passed: ${REMOTE_URL}"

