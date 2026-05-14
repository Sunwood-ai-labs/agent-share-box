#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${AGENT_SHARE_MACOS_CONFIG:-${HOME}/.config/agent-share-box/macos.env}"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
fi

: "${AGENT_SHARE_URL:=http://192.168.11.250:3923/}"

VOLUME_PATH="$(python3 - "$AGENT_SHARE_URL" <<'PY'
import sys
from urllib.parse import urlparse
print(f"/Volumes/{urlparse(sys.argv[1]).hostname}")
PY
)"

if mount | grep -F " on ${VOLUME_PATH} " >/dev/null; then
  diskutil unmount "${VOLUME_PATH}" >/dev/null
  echo "Unmounted: ${VOLUME_PATH}"
else
  echo "Already unmounted: ${VOLUME_PATH}"
fi

