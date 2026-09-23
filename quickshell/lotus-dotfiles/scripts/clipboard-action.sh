#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
entry_id="${2:-}"

case "$action" in
  copy)
    [[ -n "$entry_id" ]]
    printf '%s\n' "$entry_id" | cliphist decode | wl-copy
    ;;
  delete)
    [[ -n "$entry_id" ]]
    printf '%s\n' "$entry_id" | cliphist delete
    ;;
  wipe)
    cliphist wipe
    ;;
  *)
    printf 'Unknown clipboard action: %s\n' "$action" >&2
    exit 2
    ;;
esac
