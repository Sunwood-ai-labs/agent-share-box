#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="agent-share-box"
SERVICE_USER="agent-share"
INSTALL_DIR="/opt/agent-share-box"
CONFIG_DIR="/etc/agent-share-box"
STATE_DIR="/var/lib/agent-share-box"
DATA_DIR="/srv/agent-share-box"
PORT="3923"
SIZE="50G"
USERNAME="agent"
TITLE="Agent Share Box"
COPYPARTY_SPEC="${COPYPARTY_SPEC:-copyparty==1.20.14}"

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  --data-dir PATH       Shared data mountpoint (default: /srv/agent-share-box)
  --size SIZE           Loop filesystem size, for example 50G (default: 50G)
  --port PORT           HTTP/WebDAV port (default: 3923)
  --user USERNAME       Login username (default: agent)
  --title TITLE         Browser title (default: Agent Share Box)

Password is read from AGENT_SHARE_PASSWORD.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --data-dir)
      DATA_DIR="$2"; shift 2 ;;
    --size)
      SIZE="$2"; shift 2 ;;
    --port)
      PORT="$2"; shift 2 ;;
    --user)
      USERNAME="$2"; shift 2 ;;
    --title)
      TITLE="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ "$(id -u)" != "0" ]]; then
  echo "install.sh must run as root" >&2
  exit 1
fi

: "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_PATH="${STATE_DIR}/share.img"
FSTAB_MARKER="# ${SERVICE_NAME} managed share image"

echo "[1/8] Installing OS packages"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv python3-pip curl

echo "[2/8] Creating service account and directories"
if ! id "${SERVICE_USER}" >/dev/null 2>&1; then
  useradd --system --home "${STATE_DIR}" --shell /usr/sbin/nologin "${SERVICE_USER}"
fi
mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${STATE_DIR}" "${DATA_DIR}"

echo "[3/8] Creating ${SIZE} share image if needed"
if [[ ! -e "${IMAGE_PATH}" ]]; then
  truncate -s "${SIZE}" "${IMAGE_PATH}"
  mkfs.ext4 -F -L "${SERVICE_NAME}" "${IMAGE_PATH}"
fi

if ! grep -Fq "${IMAGE_PATH} ${DATA_DIR} ext4" /etc/fstab; then
  cp /etc/fstab "/etc/fstab.${SERVICE_NAME}.$(date +%Y%m%d%H%M%S).bak"
  printf '%s\n%s %s ext4 loop,nofail,x-systemd.device-timeout=10 0 2\n' \
    "${FSTAB_MARKER}" "${IMAGE_PATH}" "${DATA_DIR}" >> /etc/fstab
elif grep -F "${IMAGE_PATH} ${DATA_DIR} ext4" /etc/fstab | grep -Fq "x-systemd.automount"; then
  cp /etc/fstab "/etc/fstab.${SERVICE_NAME}.$(date +%Y%m%d%H%M%S).bak"
  sed -i "\#${IMAGE_PATH} ${DATA_DIR} ext4#s#,x-systemd.automount##" /etc/fstab
fi

if ! findmnt -rn --target "${DATA_DIR}" >/dev/null 2>&1; then
  mount -o loop "${IMAGE_PATH}" "${DATA_DIR}"
fi

echo "[4/8] Installing copyparty runtime"
python3 -m venv "${INSTALL_DIR}/venv"
"${INSTALL_DIR}/venv/bin/python" -m pip install --upgrade pip wheel
"${INSTALL_DIR}/venv/bin/python" -m pip install "${COPYPARTY_SPEC}"

echo "[5/8] Installing service files"
install -m 0755 "${PROJECT_ROOT}/config/run-copyparty.sh" "${INSTALL_DIR}/run-copyparty.sh"
install -m 0644 "${PROJECT_ROOT}/config/agent-share-box.service" "/etc/systemd/system/${SERVICE_NAME}.service"

cat > "${CONFIG_DIR}/agent-share-box.env" <<EOF
AGENT_SHARE_PORT=${PORT}
AGENT_SHARE_USERNAME=${USERNAME}
AGENT_SHARE_PASSWORD=${AGENT_SHARE_PASSWORD}
AGENT_SHARE_DATA_DIR=${DATA_DIR}
AGENT_SHARE_STATE_DIR=${STATE_DIR}
AGENT_SHARE_TITLE=${TITLE}
AGENT_SHARE_ALLOWED_IPS=
EOF
chmod 0600 "${CONFIG_DIR}/agent-share-box.env"

echo "[6/8] Setting ownership"
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${STATE_DIR}" "${DATA_DIR}"
chmod 0750 "${STATE_DIR}"
chmod 0770 "${DATA_DIR}"

echo "[7/8] Starting service"
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.service"

echo "[8/8] Status"
systemctl --no-pager --full status "${SERVICE_NAME}.service" || true
echo
echo "Agent Share Box is installed."
echo "URL: http://$(hostname -I | awk '{print $1}'):${PORT}/"
echo "Username: ${USERNAME}"
echo "Data: ${DATA_DIR}"
echo "Size cap: ${SIZE}"
