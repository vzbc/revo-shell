#!/bin/sh
export LD_PRELOAD="/home/revo/.local/lib/libkgxui.so${LD_PRELOAD:+:$LD_PRELOAD}"
exec /usr/bin/kgx "$@"
