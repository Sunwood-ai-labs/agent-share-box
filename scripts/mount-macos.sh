#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${AGENT_SHARE_MACOS_CONFIG:-${HOME}/.config/agent-share-box/macos.env}"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
fi

: "${AGENT_SHARE_URL:=http://192.168.11.250:3923/}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:=}"
: "${AGENT_SHARE_MOUNT_LINK:=${HOME}/agent-share-box}"

volume_path() {
  python3 - "$AGENT_SHARE_URL" <<'PY'
import sys
from urllib.parse import urlparse

host = urlparse(sys.argv[1]).hostname
if not host:
    raise SystemExit("could not parse AGENT_SHARE_URL")
print(f"/Volumes/{host}")
PY
}

VOLUME_PATH="$(volume_path)"

if ! mount | grep -Fq " on ${VOLUME_PATH} "; then
  if [[ -n "${AGENT_SHARE_PASSWORD}" ]]; then
    export AGENT_SHARE_URL AGENT_SHARE_USERNAME AGENT_SHARE_PASSWORD
    osascript <<'APPLESCRIPT' >/dev/null
set shareUrl to system attribute "AGENT_SHARE_URL"
set shareUser to system attribute "AGENT_SHARE_USERNAME"
set sharePassword to system attribute "AGENT_SHARE_PASSWORD"
mount volume shareUrl as user name shareUser with password sharePassword
APPLESCRIPT
  else
    python3 - "${AGENT_SHARE_URL}" "${VOLUME_PATH}" <<'PY'
import os
import signal
import subprocess
import sys
from urllib.parse import urlparse

url, volume_path = sys.argv[1:3]
host = urlparse(url).hostname or "agent-share-box"
cmd = ["/sbin/mount_webdav", "-S", "-v", host, url, volume_path]

try:
    proc = subprocess.Popen(cmd, preexec_fn=os.setsid)
    proc.wait(timeout=15)
    if proc.returncode:
        raise subprocess.CalledProcessError(proc.returncode, cmd)
except subprocess.TimeoutExpired:
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    raise SystemExit(
        "anonymous WebDAV mount timed out; use browser/curl without auth, "
        "or enable AGENT_SHARE_AUTH=1 for macOS Finder mounting"
    )
PY
  fi
fi

if [[ -L "${AGENT_SHARE_MOUNT_LINK}" || -e "${AGENT_SHARE_MOUNT_LINK}" ]]; then
  if [[ "$(readlink "${AGENT_SHARE_MOUNT_LINK}" 2>/dev/null || true)" != "${VOLUME_PATH}" ]]; then
    echo "Refusing to replace existing path: ${AGENT_SHARE_MOUNT_LINK}" >&2
    exit 1
  fi
else
  ln -s "${VOLUME_PATH}" "${AGENT_SHARE_MOUNT_LINK}"
fi

echo "Mounted: ${VOLUME_PATH}"
echo "Link: ${AGENT_SHARE_MOUNT_LINK}"
