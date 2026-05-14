#!/usr/bin/env sh
set -eu

: "${AGENT_SHARE_PORT:=3923}"
: "${AGENT_SHARE_COPYPARTY_PORT:=3924}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required}"
: "${AGENT_SHARE_TITLE:=Agent Share Box}"
: "${AGENT_SHARE_DATA_DIR:=/share}"
: "${AGENT_SHARE_STATE_DIR:=/state}"

mkdir -p \
  "${AGENT_SHARE_STATE_DIR}/hist" \
  "${AGENT_SHARE_STATE_DIR}/nginx" \
  /run/nginx

COPYPARTY_CONFIG="${AGENT_SHARE_STATE_DIR}/copyparty.conf"
HTPASSWD="${AGENT_SHARE_STATE_DIR}/nginx/htpasswd"

cat > "${COPYPARTY_CONFIG}" <<EOF
[global]
  usernames
  http-only
  no-crt
  i: 127.0.0.1
  p: ${AGENT_SHARE_COPYPARTY_PORT}
  hist: ${AGENT_SHARE_STATE_DIR}/hist
  name: ${AGENT_SHARE_TITLE}
  doctitle: ${AGENT_SHARE_TITLE}
  bname: ${AGENT_SHARE_TITLE}

[accounts]
  ${AGENT_SHARE_USERNAME}: ${AGENT_SHARE_PASSWORD}

[/]
  ${AGENT_SHARE_DATA_DIR}
  accs:
    A: ${AGENT_SHARE_USERNAME}
EOF

printf '%s:%s\n' \
  "${AGENT_SHARE_USERNAME}" \
  "$(openssl passwd -apr1 "${AGENT_SHARE_PASSWORD}")" > "${HTPASSWD}"
chmod 0644 "${HTPASSWD}"
chmod 0600 "${COPYPARTY_CONFIG}"

python -m copyparty -c "${COPYPARTY_CONFIG}" &
copyparty_pid="$!"

cleanup() {
  kill "${copyparty_pid}" 2>/dev/null || true
}
trap cleanup INT TERM

exec nginx -g "daemon off;"
