#!/usr/bin/env bash
#
# stack-pill: one-time, idempotent, non-blocking setup of Context7.
#
# Context7 (by Upstash) provides up-to-date library/API documentation to coding
# agents via an MCP server. `ctx7 setup --claude` registers that MCP server in
# Claude Code's config. This is not a Claude Code plugin -- it's the `ctx7` npm
# CLI -- so, like Graphify and the mattpocock skills, we bootstrap it from a
# SessionStart hook (and install.sh runs it in the foreground).
#
# Invoked from hooks/hooks.json on SessionStart as:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-ctx7.sh"
# (run via `bash`, so no execute bit is required.)
#
# Design notes (mirrors scripts/install-matt-skills.sh):
#   - Returns immediately; the npx setup runs fully detached so it never blocks
#     session start.
#   - Idempotent: a sentinel short-circuits it; a lockfile prevents concurrent
#     runs.
#   - Non-interactive: `ctx7 setup` prompts by default, so we pass --yes and
#     close stdin; OAuth/login is optional (only for higher quota) and is left
#     to the user via `npx ctx7@latest login`.
#   - Safe: only Node/npx (already required by Impeccable's hook). Node >= 18.
#   - Opt-out: STACK_PILL_SKIP_CTX7=1 or a `ctx7-skip` marker file.
#
# Foreground mode:
#   Pass `--wait` (or set STACK_PILL_CTX7_WAIT=1) to run setup in the foreground
#   and stream progress, returning only when done. install.sh / the install
#   one-liner use this so Context7 is set up as part of installing stack-pill.
#   The SessionStart hook calls it without --wait (detached).

set -u

# --- Foreground mode flag ---------------------------------------------------
WAIT=0
case "${1:-}" in --wait | -w) WAIT=1 ;; esac
[ "${STACK_PILL_CTX7_WAIT:-0}" = "1" ] && WAIT=1

# --- Resolve a persistent data dir (survives plugin updates) ----------------
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/stack-pill}"
mkdir -p "$DATA_DIR" 2>/dev/null || true

SENTINEL="$DATA_DIR/ctx7-installed"
SKIP_FILE="$DATA_DIR/ctx7-skip"
LOCK="$DATA_DIR/ctx7-install.lock"
LOG="$DATA_DIR/ctx7-install.log"
# Export so the detached `setsid bash -c` worker (a fresh shell) inherits them.
export DATA_DIR SENTINEL SKIP_FILE LOCK LOG

# --- Opt-out ----------------------------------------------------------------
if [ "${STACK_PILL_SKIP_CTX7:-0}" = "1" ] || [ -f "$SKIP_FILE" ]; then
  exit 0
fi

# --- PATH discovery ---------------------------------------------------------
# Hook subprocesses do not inherit the login shell's PATH. node/npx commonly
# live in these locations; prepend them so `command -v` can find them. nvm
# installs are best-effort (newest versioned bin dir, if present).
for d in "$HOME/.local/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) [ -d "$d" ] && PATH="$d:$PATH" ;;
  esac
done
if [ -d "$HOME/.nvm/versions/node" ]; then
  nvm_bin="$(ls -dt "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | head -1 || true)"
  case ":$PATH:" in *":$nvm_bin:"*) ;; *) [ -n "$nvm_bin" ] && PATH="$nvm_bin:$PATH" ;; esac
fi
export PATH

# --- Already done? ----------------------------------------------------------
if [ -f "$SENTINEL" ]; then
  [ "$WAIT" = "1" ] && echo "stack-pill: Context7 already set up."
  exit 0
fi

# --- Concurrency guard ------------------------------------------------------
# Respect a fresh lock (a setup genuinely in progress), but reclaim a stale one
# (>30 min) left behind by a crashed run, so we never get permanently stuck.
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
  echo "[stack-pill] $(date 2>/dev/null) setting up Context7 (npm: ctx7, 'ctx7 setup --claude')..."

  if ! command -v npx >/dev/null 2>&1; then
    echo "[stack-pill] 'npx' not found. Install Node.js >= 18 (https://nodejs.org), then restart Claude Code."
    echo "[stack-pill] (Context7 setup needs Node/npx; nothing was changed.)"
    rm -f "$LOCK"
    return 0
  fi

  # Non-interactive: --yes skips prompts; stdin closed as belt-and-suspenders.
  if npx --yes ctx7@latest setup --claude --yes </dev/null; then
    touch "$SENTINEL"
    echo "[stack-pill] Context7 MCP registered for Claude Code."
    echo "[stack-pill] Optional: run 'npx ctx7@latest login' for a higher docs quota."
  else
    echo "[stack-pill] Context7 setup did not complete (npx ctx7 setup returned non-zero)."
    echo "[stack-pill] Will retry next session. Manual: npx ctx7@latest setup --claude"
  fi

  rm -f "$LOCK"
}

# --- Foreground (--wait): stream progress, block until done -----------------
if [ "$WAIT" = "1" ]; then
  echo "stack-pill: setting up Context7 now…"
  run_install 2>&1 | tee -a "$LOG"
  if [ -f "$SENTINEL" ]; then
    echo "stack-pill: Context7 setup complete."
  else
    echo "stack-pill: Context7 setup did not complete — see $LOG"
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

echo "stack-pill: setting up Context7 in the background (first run only)."
exit 0
