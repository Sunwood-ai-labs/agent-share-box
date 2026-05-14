#!/usr/bin/env bash
set -euo pipefail

HOST="${AGENT_SHARE_HOST:-giobox}"
DATA_DIR="${AGENT_SHARE_DATA_DIR:-/srv/agent-share-box}"
WARN_PERCENT="${AGENT_SHARE_WARN_PERCENT:-80}"

ssh "${HOST}" "DATA_DIR='${DATA_DIR}' WARN_PERCENT='${WARN_PERCENT}' bash -s" <<'REMOTE'
set -euo pipefail

if ! findmnt -rn --target "${DATA_DIR}" >/dev/null 2>&1; then
  echo "not-mounted: ${DATA_DIR}" >&2
  exit 2
fi

df -h "${DATA_DIR}"
used="$(df -P "${DATA_DIR}" | awk 'NR==2 {gsub(/%/, "", $5); print $5}')"

if [[ "${used}" -ge "${WARN_PERCENT}" ]]; then
  echo "warning: ${DATA_DIR} is ${used}% full"
  exit 1
fi

echo "ok: ${DATA_DIR} is ${used}% full"
REMOTE

