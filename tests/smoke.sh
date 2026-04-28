#!/usr/bin/env bash
# Minimal smoke test: build the image, run it with a tiny overlay,
# verify it answers a query for the overlay-defined name.
set -euo pipefail

IMAGE="${IMAGE:-reference-dnsmasq:smoke}"
PORT="${PORT:-15353}"
NAME="reference-dnsmasq-smoke"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d)
cat >"$TMPDIR/zones.conf" <<EOF
address=/smoke.test/10.99.99.99
EOF

docker build -t "$IMAGE" .

docker run -d --rm --name "$NAME" \
  -p "$PORT:53/udp" \
  -v "$TMPDIR/zones.conf:/etc/dnsmasq-overlay/zones.conf:ro" \
  "$IMAGE"

# Wait for healthcheck-equivalent.
for i in $(seq 1 10); do
  if dig @127.0.0.1 -p "$PORT" version.bind chaos txt +short +time=2 +tries=1 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

RESULT=$(dig @127.0.0.1 -p "$PORT" smoke.test +short +time=2 +tries=1)
if [ "$RESULT" != "10.99.99.99" ]; then
  echo "FAIL: expected 10.99.99.99, got '$RESULT'"
  docker logs "$NAME"
  exit 1
fi

echo "OK: smoke.test resolves to $RESULT"
