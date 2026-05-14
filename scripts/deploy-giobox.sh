#!/usr/bin/env bash
set -euo pipefail

HOST="${AGENT_SHARE_HOST:-giobox}"
PORT="${AGENT_SHARE_PORT:-3923}"
SIZE="${AGENT_SHARE_SIZE:-50G}"
USERNAME="${AGENT_SHARE_USERNAME:-agent}"
DATA_DIR="${AGENT_SHARE_DATA_DIR:-/srv/agent-share-box}"
TITLE="${AGENT_SHARE_TITLE:-Agent Share Box}"
AUTH="${AGENT_SHARE_AUTH:-0}"
REMOTE_DIR="/tmp/agent-share-box-deploy"
INCLUDE_PATHS=(
  .github
  .gitignore
  LICENSE
  README.ja.md
  README.md
  SECURITY.md
  config
  deploy
  docker
  docs
  scripts
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

case "${AUTH}" in
  1|true|TRUE|yes|YES|on|ON)
    AUTH="1" ;;
  *)
    AUTH="0" ;;
esac

if [[ "${AUTH}" == "1" && -z "${AGENT_SHARE_PASSWORD:-}" ]]; then
  AGENT_SHARE_PASSWORD="$(openssl rand -base64 24 | tr -d '\n')"
  GENERATED_PASSWORD=1
else
  AGENT_SHARE_PASSWORD="${AGENT_SHARE_PASSWORD:-}"
  GENERATED_PASSWORD=0
fi

echo "Deploying Agent Share Box to ${HOST}"
echo "Port: ${PORT}"
echo "Data dir: ${DATA_DIR}"
echo "Size cap: ${SIZE}"
echo "Auth: ${AUTH}"

ssh "${HOST}" "rm -rf '${REMOTE_DIR}' && mkdir -p '${REMOTE_DIR}'"
tar -C "${PROJECT_ROOT}" -czf - "${INCLUDE_PATHS[@]}" | ssh "${HOST}" "tar -xzf - -C '${REMOTE_DIR}'"

ssh "${HOST}" \
  "AGENT_SHARE_AUTH='${AUTH}' AGENT_SHARE_PASSWORD='${AGENT_SHARE_PASSWORD}' bash '${REMOTE_DIR}/deploy/install.sh' --data-dir '${DATA_DIR}' --size '${SIZE}' --port '${PORT}' --user '${USERNAME}' --title '${TITLE}'"

REMOTE_IP="$(ssh "${HOST}" "hostname -I | awk '{print \$1}'")"

cat <<EOF

Deployment complete.
URL: http://${REMOTE_IP}:${PORT}/
Auth enabled: ${AUTH}
Username: ${USERNAME}
Password: ${AGENT_SHARE_PASSWORD:-<not required>}
Password was generated now: ${GENERATED_PASSWORD}

Run a smoke test:
AGENT_SHARE_URL=http://${REMOTE_IP}:${PORT} \\
./scripts/smoke-test.sh
EOF
