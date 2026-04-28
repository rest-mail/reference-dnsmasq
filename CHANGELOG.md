# Changelog

Calver-tagged. Newest on top.

## 2026.04.28

- Initial release.
- Alpine 3.20 + dnsmasq + bind-tools, supervised by tini.
- Overlay config via `/etc/dnsmasq-overlay/` (loaded with `--conf-dir`).
- `DNSMASQ_LOG_LEVEL` env var (debug/info/warn/error).
- Healthcheck: `dig @127.0.0.1 version.bind chaos txt`.
- Multi-arch publish: linux/amd64, linux/arm64.
