#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${AGENT_SHARE_MACOS_CONFIG:-${HOME}/.config/agent-share-box/macos.env}"
: "${AGENT_SHARE_URL:=http://192.168.11.250:3923/}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:=}"
: "${AGENT_SHARE_MOUNT_LINK:=${HOME}/agent-share-box}"

mkdir -p "$(dirname "${CONFIG_FILE}")"
umask 077
quote() {
  printf "%q" "$1"
}

cat > "${CONFIG_FILE}" <<EOF
AGENT_SHARE_URL=$(quote "${AGENT_SHARE_URL}")
AGENT_SHARE_USERNAME=$(quote "${AGENT_SHARE_USERNAME}")
AGENT_SHARE_PASSWORD=$(quote "${AGENT_SHARE_PASSWORD}")
AGENT_SHARE_MOUNT_LINK=$(quote "${AGENT_SHARE_MOUNT_LINK}")
EOF

chmod 0600 "${CONFIG_FILE}"
echo "Wrote ${CONFIG_FILE}"
echo "Mount link: ${AGENT_SHARE_MOUNT_LINK}"
if [[ -z "${AGENT_SHARE_PASSWORD}" ]]; then
  echo "Auth: disabled"
else
  echo "Auth: enabled"
fi
