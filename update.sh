#!/usr/bin/env bash
# revo-shell update: bring every installed shell (and hypr, SystemSettings, Siri,
# plugins…) up to the latest revo-shell commit.
#
# Works with or without a repo on disk:
#   - inside a git checkout of revo-shell: git pull, then re-run its install.sh
#   - anywhere else (the GUI installer deletes its staging copy; install.sh puts
#     this script at ~/.local/bin/revo-shell-update): download the latest commit
#     as a tarball, run its install.sh, remove the download.
# The installed commit is kept in ~/.local/state/revo-shell/commit, so
# `--check` can tell whether anything changed upstream.
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")" && pwd)"
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/vzbc/revo-shell.git}"
BRANCH="${REVO_BRANCH:-main}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/revo-shell"
STATE="$STATE_DIR/commit"
SKIP_PULL="${SKIP_PULL:-0}"
CHECK=0
FORCE=0

log()  { printf '[update] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: revo-shell-update [options]   (or ./update from a revo-shell checkout)

Updates all installed revo-shell shells to the latest commit and re-applies
the install (hypr config, Quickshell shells, SystemSettings, Siri, plugins).
Your default shell and monitor setup are kept.

Options:
  --check           only report: prints "status: up-to-date|available|unknown",
                    the installed and latest commits, and the new commit titles
  --force           update even if already on the latest commit
  --shells LIST     forwarded to install.sh (comma-separated shell ids)
  --no-pull         skip fetching, only re-apply the local checkout
  -h, --help        show this help

Environment:
  DRY_RUN=1         print commands without changing the system
  DOTFILES_REPO_URL override the GitHub repository URL
  REVO_BRANCH       branch to follow (default main)
  NO_SHELL_PROMPT=0 set to 0 to get the interactive shell menu
EOF
}

FWD=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --force) FORCE=1; shift ;;
    --no-pull) SKIP_PULL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) FWD+=("$1"); shift ;;
  esac
done

# owner/repo from the GitHub URL
SLUG="$(printf '%s' "$REPO_URL" | sed -E 's#^(https?://|git@)github\.com[:/]##; s#\.git/?$##; s#/$##')"
API="https://api.github.com/repos/$SLUG"

is_checkout() { [[ -e "$ROOT/.git" && -f "$ROOT/install.sh" ]] && have git; }

local_commit() {
  if [[ -s "$STATE" ]]; then tr -d ' \n' < "$STATE"; return; fi
  if is_checkout; then git -C "$ROOT" rev-parse HEAD 2>/dev/null; return; fi
  [[ -s "$ROOT/.revo-commit" ]] && tr -d ' \n' < "$ROOT/.revo-commit"
}

remote_commit() {
  local sha=""
  if have git; then
    sha="$(GIT_TERMINAL_PROMPT=0 timeout 15 git ls-remote "$REPO_URL" "refs/heads/$BRANCH" 2>/dev/null | cut -f1)"
  fi
  if [[ -z "$sha" ]] && have curl; then
    sha="$(curl -fsSL -m 15 -H 'Accept: application/vnd.github.sha' "$API/commits/$BRANCH" 2>/dev/null || true)"
  fi
  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] && printf '%s' "$sha"
}

# titles of the commits between two shas (newest first, at most 20)
new_commits() {
  have curl && have python3 || return 0
  curl -fsSL -m 15 "$API/compare/$1...$2" 2>/dev/null | python3 -c '
import json, sys
try:
    cs = json.load(sys.stdin).get("commits", [])
except Exception:
    sys.exit(0)
for c in reversed(cs[-20:]):
    print("- " + c["commit"]["message"].splitlines()[0])
' || true
}

record() { mkdir -p "$STATE_DIR" && printf '%s\n' "$1" > "$STATE"; }

LOCAL="$(local_commit || true)"
REMOTE=""
[[ "$SKIP_PULL" == "1" ]] || REMOTE="$(remote_commit || true)"

# ── --check ───────────────────────────────────────────────────
if [[ "$CHECK" == "1" ]]; then
  if [[ -z "$REMOTE" ]]; then status=unknown
  elif [[ "$LOCAL" == "$REMOTE" ]]; then status=up-to-date
  else status=available; fi
  echo "status: $status"
  echo "installed: ${LOCAL:-unknown}"
  echo "latest: ${REMOTE:-unknown}"
  if [[ "$status" == available && -n "$LOCAL" ]]; then new_commits "$LOCAL" "$REMOTE"; fi
  exit 0
fi

if [[ -n "$REMOTE" && "$LOCAL" == "$REMOTE" && "$FORCE" != "1" ]]; then
  log "already up to date (${REMOTE:0:7}) — use --force to re-apply anyway"
  exit 0
fi
if [[ -n "$REMOTE" && -n "$LOCAL" && "$LOCAL" != "$REMOTE" ]]; then
  log "changes since ${LOCAL:0:7}:"; new_commits "$LOCAL" "$REMOTE" | sed 's/^/  /'
fi

run_install() {   # $1 = source tree
  log "applying ${REMOTE:+${REMOTE:0:7} }from $1 (all shells, keeps your default shell)"
  NO_SHELL_PROMPT="${NO_SHELL_PROMPT:-1}" bash "$1/install.sh" ${FWD[@]+"${FWD[@]}"}
}

# ── 1) a git checkout: pull it, apply it ──────────────────────
if is_checkout; then
  cd "$ROOT"
  if [[ "$SKIP_PULL" != "1" ]]; then
    log "pulling $REPO_URL ($BRANCH)"
    if ! out="$(GIT_TERMINAL_PROMPT=0 git pull --ff-only "$REPO_URL" "$BRANCH" 2>&1)"; then
      log "pull failed (offline or local edits) — applying the local files"
      printf '%s\n' "$out" | tail -5 | sed 's/^/  /'
    fi
    # the pulled update.sh may be newer than the one running: let it apply
    REVO_UPDATE_REEXEC=1 SKIP_PULL=1 exec bash "$ROOT/update.sh" --force ${FWD[@]+"${FWD[@]}"}
  fi
  run_install "$ROOT"
  [[ "${DRY_RUN:-0}" == "1" ]] || record "$(git -C "$ROOT" rev-parse HEAD)"
  log "done"
  exit 0
fi

# ── 2) no checkout: download the latest commit and apply it ───
[[ "$SKIP_PULL" == "1" ]] && { log "--no-pull needs a revo-shell checkout"; exit 1; }
[[ -n "$REMOTE" ]] || { log "cannot reach $REPO_URL (offline?) — nothing changed"; exit 1; }
have curl && have tar || { log "curl and tar are needed"; exit 1; }
WORK="$(mktemp -d "${TMPDIR:-/tmp}/revo-shell-update.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
log "downloading ${REMOTE:0:7}"
curl -fL --retry 2 -m 900 -o "$WORK/src.tar.gz" "https://codeload.github.com/$SLUG/tar.gz/$REMOTE"
mkdir -p "$WORK/src"
tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
[[ -f "$WORK/src/install.sh" && -d "$WORK/src/quickshell" ]] || { log "download looks incomplete — nothing changed"; exit 1; }
printf '%s\n' "$REMOTE" > "$WORK/src/.revo-commit"
run_install "$WORK/src"
[[ "${DRY_RUN:-0}" == "1" ]] || record "$REMOTE"
log "done"
