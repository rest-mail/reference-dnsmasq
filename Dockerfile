FROM alpine:3.20

# gettext provides envsubst, used by the render-fragment subcommand.
RUN apk add --no-cache dnsmasq bind-tools tini gettext

COPY defaults/dnsmasq.conf /etc/dnsmasq.conf
COPY defaults/render-fragment.tmpl /usr/local/share/render-fragment/default.tmpl
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/render-fragment /usr/local/bin/render-fragment
COPY bin/remove-fragment /usr/local/bin/remove-fragment
RUN chmod +x /usr/local/bin/entrypoint.sh \
              /usr/local/bin/render-fragment \
              /usr/local/bin/remove-fragment

EXPOSE 53/tcp 53/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD dig @127.0.0.1 version.bind chaos txt +short +time=2 +tries=1 >/dev/null || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
