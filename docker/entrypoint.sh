#!/usr/bin/env sh
set -eu

: "${AGENT_SHARE_PORT:=3923}"
: "${AGENT_SHARE_COPYPARTY_PORT:=3924}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:=}"
: "${AGENT_SHARE_AUTH:=0}"
: "${AGENT_SHARE_TITLE:=Agent Share Box}"
: "${AGENT_SHARE_DATA_DIR:=/share}"
: "${AGENT_SHARE_STATE_DIR:=/state}"

mkdir -p \
  "${AGENT_SHARE_STATE_DIR}/hist" \
  "${AGENT_SHARE_STATE_DIR}/nginx" \
  /run/nginx

COPYPARTY_CONFIG="${AGENT_SHARE_STATE_DIR}/copyparty.conf"
HTPASSWD="${AGENT_SHARE_STATE_DIR}/nginx/htpasswd"
NGINX_AUTH="${AGENT_SHARE_STATE_DIR}/nginx/auth.conf"

case "${AGENT_SHARE_AUTH}" in
  1|true|TRUE|yes|YES|on|ON)
    AUTH_ENABLED=1
    : "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required when AGENT_SHARE_AUTH is enabled}"
    ;;
  *)
    AUTH_ENABLED=0
    ;;
esac

cat > "${COPYPARTY_CONFIG}" <<EOF
[global]
  http-only
  no-crt
  i: 127.0.0.1
  p: ${AGENT_SHARE_COPYPARTY_PORT}
  hist: ${AGENT_SHARE_STATE_DIR}/hist
  name: ${AGENT_SHARE_TITLE}
  doctitle: ${AGENT_SHARE_TITLE}
  bname: ${AGENT_SHARE_TITLE}
EOF

if [ "${AUTH_ENABLED}" = "1" ]; then
  cat >> "${COPYPARTY_CONFIG}" <<'EOF'
  usernames

EOF

  cat >> "${COPYPARTY_CONFIG}" <<EOF
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
  cat > "${NGINX_AUTH}" <<EOF
auth_basic "Agent Share Box";
auth_basic_user_file ${HTPASSWD};
EOF
else
  cat >> "${COPYPARTY_CONFIG}" <<EOF
[/]
  ${AGENT_SHARE_DATA_DIR}
  accs:
    A: *
EOF

  cat > "${NGINX_AUTH}" <<'EOF'
auth_basic off;
EOF
fi

chmod 0600 "${COPYPARTY_CONFIG}"
chmod 0644 "${NGINX_AUTH}"

python -m copyparty -c "${COPYPARTY_CONFIG}" &
copyparty_pid="$!"

cleanup() {
  kill "${copyparty_pid}" 2>/dev/null || true
}
trap cleanup INT TERM

exec nginx -g "daemon off;"
