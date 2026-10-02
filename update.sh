#!/usr/bin/env bash
# revo-shell update: pull the latest repo changes, then re-run install.sh so
# new additions (hyprpm plugins, plugin paths, SystemSettings, shells) land.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/vzbc/revo-shell.git}"
SKIP_PULL="${SKIP_PULL:-0}"
PULL_LOG="$(mktemp)"

log()  { printf '[update] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: ./update [options]

Pulls the latest revo-shell changes and re-runs install.sh to apply them:
hyprpm plugins (HyprGlass / hyprliquid / Hypr3D), plugin load paths,
SystemSettings build, shells and packages.

Options:
  --shells LIST     forwarded to install.sh (comma-separated shell ids)
  --no-pull         skip the git pull, only re-apply local files
  -h, --help        show this help

Environment:
  DRY_RUN=1         print commands without changing the system
  DOTFILES_REPO_URL override the git remote URL
  NO_SHELL_PROMPT=0 set to 0 to get the interactive shell menu
EOF
}

FWD=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull) SKIP_PULL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) FWD+=("$1"); shift ;;
  esac
done

cd "$ROOT"

# ── 1) pull ───────────────────────────────────────────────────
if [[ "$SKIP_PULL" == "1" ]]; then
  log "pull skipped (--no-pull)"
elif [[ -d "$ROOT/.git" ]] && have git; then
  log "pulling $REPO_URL"
  if git pull --ff-only "$REPO_URL" >"$PULL_LOG" 2>&1; then
    log "up to date"
  else
    log "pull failed (offline or local edits) — applying local files"
    sed 's/^/  /' "$PULL_LOG" | tail -5
  fi
else
  log "not a git checkout — skipping pull"
fi
rm -f "$PULL_LOG"

# ── 2) re-apply ───────────────────────────────────────────────
log "re-running install.sh (plugins, paths, SystemSettings, shells)"
NO_SHELL_PROMPT="${NO_SHELL_PROMPT:-1}" bash "$ROOT/install.sh" ${FWD[@]+"${FWD[@]}"}
