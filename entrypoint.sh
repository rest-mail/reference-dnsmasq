#!/bin/sh
set -eu

# Dispatch on first arg. Subcommands run instead of dnsmasq; otherwise the
# image runs the daemon (default behavior).
case "${1:-}" in
  render-fragment|remove-fragment)
    cmd="$1"
    shift
    exec "/usr/local/bin/$cmd" "$@"
    ;;
esac

# Default: run dnsmasq with overlay support.
# Files in /etc/dnsmasq-overlay/ become part of dnsmasq's config-dir.
OVERLAY_DIR="${DNSMASQ_OVERLAY_DIR:-/etc/dnsmasq-overlay}"
LOG_LEVEL="${DNSMASQ_LOG_LEVEL:-info}"

ARGS="--no-daemon --log-facility=-"

if [ -d "$OVERLAY_DIR" ] && [ -n "$(ls -A "$OVERLAY_DIR" 2>/dev/null || true)" ]; then
  ARGS="$ARGS --conf-dir=$OVERLAY_DIR"
fi

case "$LOG_LEVEL" in
  debug) ARGS="$ARGS --log-queries --log-debug" ;;
  info)  ARGS="$ARGS --log-queries" ;;
  warn|error) : ;;
esac

# SIGHUP reloads /etc/hosts and re-reads conf — dnsmasq handles this natively,
# so we just exec and the signal propagates.
exec dnsmasq $ARGS "$@"
