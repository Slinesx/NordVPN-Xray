# ────────────────────────────────────────────────────────────────────────────
# Builder: download & unpack Xray
# ────────────────────────────────────────────────────────────────────────────
FROM alpine:3.18 AS builder

RUN apk add --no-cache curl unzip

RUN curl -fsSL \
      https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
      -o /tmp/xray.zip \
    && unzip /tmp/xray.zip -d /tmp \
    && mv /tmp/xray /usr/local/bin/xray \
    && chmod +x /usr/local/bin/xray

# ────────────────────────────────────────────────────────────────────────────
# Final: minimal runtime
# ────────────────────────────────────────────────────────────────────────────
FROM alpine:3.18

RUN apk add --no-cache \
      openvpn \
      iproute2 \
      iptables \
      bash \
      tini

COPY --from=builder /usr/local/bin/xray /usr/local/bin/xray
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 1080/tcp 1080/udp

ENTRYPOINT ["/sbin/tini","--","/entrypoint.sh"]
