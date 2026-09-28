#!/bin/sh
NAUT_BIN="/home/revo/nautilus-src/_build/src/nautilus"
if [ -z "$NAUT_NOUI" ]; then
  exec env LD_PRELOAD="/home/revo/.local/lib/libnautui.so${LD_PRELOAD:+:$LD_PRELOAD}" "$NAUT_BIN" "$@"
fi
exec "$NAUT_BIN" "$@"
