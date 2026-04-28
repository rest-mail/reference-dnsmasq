# reference-dnsmasq

A small, generic [dnsmasq](https://thekelleylabs.com/dnsmasq/) container with overlay-config support. Built on Alpine, supervised by `tini`, multi-arch (`linux/amd64` + `linux/arm64`), shipped under MIT.

Meant to be useful as a standalone DNS sandbox or as the DNS layer of a larger testbed. No assumptions about what zones, records, or upstreams you need — supply them via mounted config.

## Image

```
ghcr.io/rest-mail/reference-dnsmasq:latest          # always newest
ghcr.io/rest-mail/reference-dnsmasq:YYYY.MM.DD      # immutable calver tag
```

## Quick start (standalone)

```bash
docker run --rm -p 5353:53/udp -p 5353:53/tcp \
  ghcr.io/rest-mail/reference-dnsmasq:latest

# In another terminal:
dig @127.0.0.1 -p 5353 version.bind chaos txt
```

The default config has no zones — it'll start, accept queries, and return `REFUSED` / `NXDOMAIN` until you mount config.

## Adding records (overlay)

The entrypoint loads any files in `/etc/dnsmasq-overlay/` via dnsmasq's `--conf-dir`. Mount a directory of `.conf` snippets:

```bash
# my-zones.conf
address=/example.test/10.0.0.1
mx-host=example.test,example.test,10
txt-record=example.test,"v=spf1 ip4:10.0.0.1 -all"

# Run:
docker run --rm -p 5353:53/udp \
  -v $(pwd)/my-zones.conf:/etc/dnsmasq-overlay/my-zones.conf:ro \
  ghcr.io/rest-mail/reference-dnsmasq:latest
```

Multiple files are fine — dnsmasq concatenates everything in the conf-dir.

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DNSMASQ_OVERLAY_DIR` | no | `/etc/dnsmasq-overlay` | Directory of additional config snippets, loaded via `--conf-dir` |
| `DNSMASQ_LOG_LEVEL` | no | `info` | `debug` (full query log + debug), `info` (query log only), `warn`/`error` (silent) |

## Healthcheck

```bash
dig @127.0.0.1 version.bind chaos txt +short +time=2 +tries=1
```

A successful response (any non-error) means dnsmasq is up and answering. Returns `dnsmasq-X.YY` on success.

## Signals

- **SIGTERM** → graceful shutdown (handled by `tini` + dnsmasq)
- **SIGHUP** → reload `/etc/hosts` and the conf-dir without restart (native dnsmasq behavior)

## Defaults

The baked-in `/etc/dnsmasq.conf`:

- `listen-address=0.0.0.0` (and `::`) — all interfaces inside the container
- `no-resolv` — no upstream forwarding by default; image is meant to be authoritative for whatever you configure
- `no-hosts` — ignores `/etc/hosts`
- `cache-size=1000`

Override anything via overlay snippets.

## Layout

```
.
├── Dockerfile
├── entrypoint.sh
├── defaults/
│   └── dnsmasq.conf       # baked-in defaults; overlay overrides
├── .github/workflows/
│   └── build.yml          # multi-arch GHCR publish on push to master
└── tests/
    └── smoke.sh           # spin up + dig + verify
```

## Building locally

```bash
docker build -t reference-dnsmasq:dev .
docker run --rm -p 5353:53/udp reference-dnsmasq:dev
```

## License

MIT.

## See also

- [`rest-mail/conventions`](https://github.com/rest-mail/conventions) — the contract every `reference-*` image follows (overlay paths, env var naming, signal handling, calver tagging)
- [`rest-mail/testbed`](https://github.com/rest-mail/testbed) — where this image gets composed alongside `reference-certgen` and the reference mail-server pair to form a full local-internet sandbox
