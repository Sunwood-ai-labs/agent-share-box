#!/usr/bin/env bash
set -euo pipefail

: "${AGENT_SHARE_PORT:=3923}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required}"
: "${AGENT_SHARE_DATA_DIR:=/srv/agent-share-box}"
: "${AGENT_SHARE_STATE_DIR:=/var/lib/agent-share-box}"
: "${AGENT_SHARE_TITLE:=Agent Share Box}"
: "${AGENT_SHARE_ALLOWED_IPS:=}"

mkdir -p "${AGENT_SHARE_STATE_DIR}/hist"

args=(
  --usernames
  --http-only
  --no-crt
  -i 0.0.0.0
  -p "${AGENT_SHARE_PORT}"
  --hist "${AGENT_SHARE_STATE_DIR}/hist"
  --name "${AGENT_SHARE_TITLE}"
  -a "${AGENT_SHARE_USERNAME}:${AGENT_SHARE_PASSWORD}"
  -v "${AGENT_SHARE_DATA_DIR}::A,${AGENT_SHARE_USERNAME}"
)

if [[ -n "${AGENT_SHARE_ALLOWED_IPS}" ]]; then
  args+=(--ipa "${AGENT_SHARE_ALLOWED_IPS}")
fi

exec /opt/agent-share-box/venv/bin/copyparty "${args[@]}"

