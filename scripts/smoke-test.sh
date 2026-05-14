#!/usr/bin/env bash
set -euo pipefail

: "${AGENT_SHARE_URL:?AGENT_SHARE_URL is required, for example http://192.168.1.10:3923}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:=}"

URL="${AGENT_SHARE_URL%/}"
AUTH="${AGENT_SHARE_USERNAME}:${AGENT_SHARE_PASSWORD}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

curl_auth() {
  if [[ -n "${AGENT_SHARE_PASSWORD}" ]]; then
    curl -fsS -u "${AUTH}" "$@"
  else
    curl -fsS "$@"
  fi
}

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STAMP_SAFE="$(date -u +%Y%m%dT%H%M%SZ)"
LOCAL_FILE="${TMP_DIR}/agent-share-smoke.md"
REMOTE_URL="${URL}/smoke/agent-share-smoke-${STAMP_SAFE}.md"
DOWNLOADED="${TMP_DIR}/downloaded.md"

cat > "${LOCAL_FILE}" <<EOF
# Agent Share Smoke

Created: ${STAMP}

This Markdown file verifies browser/WebDAV-style upload and download.
EOF

curl_auth "${URL}/" >/dev/null
curl_auth -X MKCOL "${URL}/smoke" >/dev/null 2>/dev/null || true
curl_auth -T "${LOCAL_FILE}" "${REMOTE_URL}" >/dev/null
curl_auth "${REMOTE_URL}" -o "${DOWNLOADED}"
cmp "${LOCAL_FILE}" "${DOWNLOADED}"

echo "Smoke test passed: ${REMOTE_URL}"
