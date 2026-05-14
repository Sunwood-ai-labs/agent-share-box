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
CONFIG_FILE="${AGENT_SHARE_STATE_DIR}/copyparty.conf"

umask 077
cat > "${CONFIG_FILE}" <<EOF
[global]
  usernames
  http-only
  no-crt
  i: 0.0.0.0
  p: ${AGENT_SHARE_PORT}
  hist: ${AGENT_SHARE_STATE_DIR}/hist
  name: ${AGENT_SHARE_TITLE}
EOF

if [[ -n "${AGENT_SHARE_ALLOWED_IPS}" ]]; then
  cat >> "${CONFIG_FILE}" <<EOF
  ipa: ${AGENT_SHARE_ALLOWED_IPS}
EOF
fi

cat >> "${CONFIG_FILE}" <<EOF

[accounts]
  ${AGENT_SHARE_USERNAME}: ${AGENT_SHARE_PASSWORD}

[/]
  ${AGENT_SHARE_DATA_DIR}
  accs:
    A: ${AGENT_SHARE_USERNAME}
EOF

exec /opt/agent-share-box/venv/bin/copyparty -c "${CONFIG_FILE}"
