FROM alpine:3.20

RUN apk add --no-cache dnsmasq bind-tools tini

COPY defaults/dnsmasq.conf /etc/dnsmasq.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 53/tcp 53/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD dig @127.0.0.1 version.bind chaos txt +short +time=2 +tries=1 >/dev/null || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
