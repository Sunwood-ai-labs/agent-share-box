#!/usr/bin/env bash
set -euo pipefail

: "${AGENT_SHARE_PORT:=3923}"
: "${AGENT_SHARE_USERNAME:=agent}"
: "${AGENT_SHARE_PASSWORD:?AGENT_SHARE_PASSWORD is required}"
: "${AGENT_SHARE_DATA_DIR:=/srv/agent-share-box}"
: "${AGENT_SHARE_STATE_DIR:=/var/lib/agent-share-box}"
: "${AGENT_SHARE_TITLE:=Agent Share Box}"

mkdir -p "${AGENT_SHARE_STATE_DIR}/container"

exec /usr/bin/docker run --rm \
  --name agent-share-box \
  --publish "${AGENT_SHARE_PORT}:3923" \
  --env AGENT_SHARE_USERNAME \
  --env AGENT_SHARE_PASSWORD \
  --env AGENT_SHARE_TITLE \
  --env AGENT_SHARE_DATA_DIR=/share \
  --env AGENT_SHARE_STATE_DIR=/state \
  --volume "${AGENT_SHARE_DATA_DIR}:/share" \
  --volume "${AGENT_SHARE_STATE_DIR}/container:/state" \
  agent-share-box:local
