#!/usr/bin/env bash
#
# stack-pill: one-time, idempotent, non-blocking bootstrap for Graphify.
#
# Graphify is not a Claude Code plugin -- it is the Python package `graphifyy`
# that ships a Claude skill. This script installs it from upstream (PyPI) using
# an isolated installer (uv or pipx) and then runs `graphify install` to drop in
# the Claude skill. Nothing is vendored into stack-pill; upstream stays the
# source of truth.
#
# Invoked from hooks/hooks.json on SessionStart as:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-graphify.sh"
# (run via `bash`, so no execute bit is required.)
#
# Design notes:
#   - Returns immediately; the heavy install runs fully detached so it never
#     blocks session start.
#   - Idempotent: a sentinel + an existing `graphify` on PATH short-circuit it,
#     and a lockfile prevents concurrent runs.
#   - Safe: only isolated installers (uv/pipx). It never touches system pip.
#   - Opt-out: STACK_PILL_SKIP_GRAPHIFY=1 or a `graphify-skip` marker file.
#
# Foreground mode:
#   Pass `--wait` (or set STACK_PILL_GRAPHIFY_WAIT=1) to run the install in the
#   foreground and stream progress, returning only when done. install.sh / the
#   install one-liner use this so Graphify is installed as part of installing
#   stack-pill. The SessionStart hook calls it without --wait (detached).

set -u

# --- Foreground mode flag ---------------------------------------------------
WAIT=0
case "${1:-}" in --wait | -w) WAIT=1 ;; esac
[ "${STACK_PILL_GRAPHIFY_WAIT:-0}" = "1" ] && WAIT=1

# --- Resolve a persistent data dir (survives plugin updates) ----------------
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/stack-pill}"
mkdir -p "$DATA_DIR" 2>/dev/null || true

SENTINEL="$DATA_DIR/graphify-installed"
SKIP_FILE="$DATA_DIR/graphify-skip"
LOCK="$DATA_DIR/graphify-install.lock"
LOG="$DATA_DIR/graphify-install.log"
# Export so the detached `setsid bash -c` worker (a fresh shell) inherits them.
export DATA_DIR SENTINEL SKIP_FILE LOCK LOG

# --- Opt-out ----------------------------------------------------------------
if [ "${STACK_PILL_SKIP_GRAPHIFY:-0}" = "1" ] || [ -f "$SKIP_FILE" ]; then
  exit 0
fi

# --- PATH discovery ---------------------------------------------------------
# Hook subprocesses do not inherit the login shell's PATH. uv/pipx commonly
# live in these locations; prepend them so `command -v` can find them.
for d in "$HOME/.local/bin" "$HOME/.cargo/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) [ -d "$d" ] && PATH="$d:$PATH" ;;
  esac
done
export PATH

# --- Already done? ----------------------------------------------------------
if command -v graphify >/dev/null 2>&1 || [ -f "$SENTINEL" ]; then
  [ "$WAIT" = "1" ] && echo "stack-pill: Graphify already installed."
  exit 0
fi

# --- Concurrency guard ------------------------------------------------------
# Respect a fresh lock (an install genuinely in progress), but reclaim a stale
# one (>30 min) left behind by a crashed run, so we never get permanently stuck.
if [ -f "$LOCK" ]; then
  if [ -n "$(find "$LOCK" -mmin +30 2>/dev/null)" ]; then
    rm -f "$LOCK"
  else
    exit 0
  fi
fi
: > "$LOCK"

# --- Worker -----------------------------------------------------------------
# Writes progress to stdout/stderr; the CALLER decides where that goes
# (the detached worker appends to $LOG; --wait mode tees it to the terminal).
run_install() {
  echo "[stack-pill] $(date 2>/dev/null) installing graphify (PyPI package: graphifyy)..."

  if command -v uv >/dev/null 2>&1; then
    echo "[stack-pill] using uv tool install"
    uv tool install graphifyy && uv tool update-shell >/dev/null 2>&1 || true
  elif command -v pipx >/dev/null 2>&1; then
    echo "[stack-pill] using pipx install"
    pipx install graphifyy || true
    pipx ensurepath >/dev/null 2>&1 || true
  else
    echo "[stack-pill] Neither 'uv' nor 'pipx' found."
    echo "[stack-pill] Install uv (https://docs.astral.sh/uv) or pipx, then restart Claude Code."
    echo "[stack-pill] (stack-pill does not touch system pip on purpose.)"
    rm -f "$LOCK"
    return 0
  fi

  # Re-resolve PATH in case the installer added a new bin dir this run.
  for d in "$HOME/.local/bin" "$HOME/.cargo/bin" "/opt/homebrew/bin"; do
    case ":$PATH:" in *":$d:"*) ;; *) [ -d "$d" ] && PATH="$d:$PATH" ;; esac
  done
  export PATH

  if command -v graphify >/dev/null 2>&1; then
    echo "[stack-pill] running 'graphify install' to add the Claude skill..."
    graphify install || true
    touch "$SENTINEL"
    echo "[stack-pill] graphify ready."
  else
    echo "[stack-pill] graphify not on PATH after install; see README prerequisites (PATH/uv shell setup)."
  fi

  rm -f "$LOCK"
}

# --- Foreground (--wait): stream progress, block until done -----------------
if [ "$WAIT" = "1" ]; then
  echo "stack-pill: installing Graphify now (this can take 1-2 min)…"
  run_install 2>&1 | tee -a "$LOG"
  if command -v graphify >/dev/null 2>&1 || [ -f "$SENTINEL" ]; then
    echo "stack-pill: Graphify install complete."
  else
    echo "stack-pill: Graphify install did not complete — see $LOG"
  fi
  exit 0
fi

# --- Default: detached, non-blocking ----------------------------------------
# nohup + setsid fully detach the worker from the hook's process group so it
# survives the hook returning (and any process-group SIGTERM on hook exit).
if command -v setsid >/dev/null 2>&1; then
  setsid bash -c "$(declare -f run_install); run_install" </dev/null >>"$LOG" 2>&1 &
else
  # macOS has no setsid; nohup + & is enough to outlive the hook.
  nohup bash -c "$(declare -f run_install); run_install" </dev/null >>"$LOG" 2>&1 &
fi

echo "stack-pill: setting up Graphify in the background (first run only)."
exit 0
