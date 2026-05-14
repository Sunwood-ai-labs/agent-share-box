#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${AGENT_SHARE_MACOS_CONFIG:-${HOME}/.config/agent-share-box/macos.env}"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
fi

: "${AGENT_SHARE_URL:=http://192.168.11.250:3923/}"
: "${AGENT_SHARE_MOUNT_LINK:=${HOME}/agent-share-box}"

VOLUME_PATH="$(python3 - "$AGENT_SHARE_URL" <<'PY'
import sys
from urllib.parse import urlparse
print(f"/Volumes/{urlparse(sys.argv[1]).hostname}")
PY
)"

if mount | grep -F " on ${VOLUME_PATH} " >/dev/null; then
  echo "mounted: ${VOLUME_PATH}"
else
  echo "not mounted: ${VOLUME_PATH}"
fi

if [[ -L "${AGENT_SHARE_MOUNT_LINK}" ]]; then
  echo "link: ${AGENT_SHARE_MOUNT_LINK} -> $(readlink "${AGENT_SHARE_MOUNT_LINK}")"
elif [[ -e "${AGENT_SHARE_MOUNT_LINK}" ]]; then
  echo "link path exists but is not a symlink: ${AGENT_SHARE_MOUNT_LINK}"
else
  echo "link missing: ${AGENT_SHARE_MOUNT_LINK}"
fi

