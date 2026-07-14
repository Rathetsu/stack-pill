#!/usr/bin/env bash
#
# stack-pill: keep the team's stackdrop-marketplace plugins up to date.
#
# Third-party marketplace auto-update is OFF by default in Claude Code (only
# toggleable via the /plugin UI or org-managed settings), so teammates would
# otherwise never receive stack-pill improvements. This hook refreshes the
# stackdrop marketplace and updates the plugins that ship from it once a day.
# Updates apply on the next session restart, which is fine for background pulls.
#
# Only the stackdrop-marketplace plugins are touched here. Playwright,
# skill-creator, chrome-devtools-mcp, and coderabbit come from the official
# Anthropic marketplace and already auto-update by default; ponytail is upstream.
#
# Invoked from hooks/hooks.json on SessionStart as:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-stack-pill.sh"
# (run via `bash`, so no execute bit is required.)
#
# Design notes (mirrors scripts/install-graphify.sh):
#   - Returns immediately; the update runs fully detached so it never blocks
#     session start.
#   - Throttled: at most one check per day via a timestamp file.
#   - Concurrency-guarded by a lockfile with stale reclaim.
#   - Opt-out: STACK_PILL_SKIP_UPDATE=1 or an `update-skip` marker file.
#
# ponytail: shelling `claude plugin update` from a hook is undocumented; the full
# detach + daily throttle keeps it low-risk. Swap to the native autoUpdate
# marketplace setting once it's documented for user (not just managed) settings.

set -u

# --- Resolve a persistent data dir (survives plugin updates) ----------------
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/stack-pill}"
mkdir -p "$DATA_DIR" 2>/dev/null || true

SKIP_FILE="$DATA_DIR/update-skip"
STAMP="$DATA_DIR/last-update-check"
LOCK="$DATA_DIR/update.lock"
LOG="$DATA_DIR/update.log"
export DATA_DIR STAMP LOCK LOG

# --- Opt-out ----------------------------------------------------------------
if [ "${STACK_PILL_SKIP_UPDATE:-0}" = "1" ] || [ -f "$SKIP_FILE" ]; then
  exit 0
fi

# --- Daily throttle ---------------------------------------------------------
# Skip if we checked within the last 24h (1440 min).
if [ -f "$STAMP" ] && [ -n "$(find "$STAMP" -mmin -1440 2>/dev/null)" ]; then
  exit 0
fi

# --- PATH discovery ---------------------------------------------------------
# Hook subprocesses do not inherit the login shell's PATH; the `claude` CLI
# commonly lives in these locations.
for d in "$HOME/.local/bin" "$HOME/.claude/local" "/opt/homebrew/bin" "/usr/local/bin"; do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) [ -d "$d" ] && PATH="$d:$PATH" ;;
  esac
done
export PATH

command -v claude >/dev/null 2>&1 || exit 0

# --- Concurrency guard ------------------------------------------------------
# Respect a fresh lock (an update genuinely in progress), reclaim a stale one
# (>30 min) from a crashed run so we never get permanently stuck.
if [ -f "$LOCK" ]; then
  if [ -n "$(find "$LOCK" -mmin +30 2>/dev/null)" ]; then
    rm -f "$LOCK"
  else
    exit 0
  fi
fi
: > "$LOCK"

# Stamp now so a failing run still respects the daily throttle (no retry storm).
touch "$STAMP"

# --- Worker -----------------------------------------------------------------
run_update() {
  echo "[stack-pill] $(date 2>/dev/null) checking for stackdrop updates..."
  claude plugin marketplace update stackdrop || true
  for p in stack-pill superpowers impeccable; do
    claude plugin update "$p@stackdrop" || true
  done
  echo "[stack-pill] update check done. New versions apply on next Claude Code restart."
  rm -f "$LOCK"
}

# --- Detached, non-blocking -------------------------------------------------
if command -v setsid >/dev/null 2>&1; then
  setsid bash -c "$(declare -f run_update); run_update" </dev/null >>"$LOG" 2>&1 &
else
  # macOS has no setsid; nohup + & is enough to outlive the hook.
  nohup bash -c "$(declare -f run_update); run_update" </dev/null >>"$LOG" 2>&1 &
fi

exit 0
