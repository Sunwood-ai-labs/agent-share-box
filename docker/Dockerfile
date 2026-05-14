FROM python:3.12-alpine

ARG COPYPARTY_VERSION=1.20.14

RUN apk add --no-cache nginx openssl tini \
  && python -m pip install --no-cache-dir "copyparty==${COPYPARTY_VERSION}" \
  && rm -f /etc/nginx/http.d/default.conf

COPY docker/entrypoint.sh /usr/local/bin/agent-share-box
COPY docker/nginx.conf /etc/nginx/http.d/agent-share-box.conf
COPY docker/ui/ /opt/agent-share-box/ui/

RUN chmod 0755 /usr/local/bin/agent-share-box

EXPOSE 3923

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/agent-share-box"]
