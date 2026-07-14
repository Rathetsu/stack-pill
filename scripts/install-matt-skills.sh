#!/usr/bin/env bash
#
# stack-pill: one-time, idempotent, non-blocking install of the mattpocock skills.
#
# These are not a Claude Code plugin -- they are agent "skills" installed by
# Vercel Labs' `skills` CLI (npm package `skills`) from the upstream repo
# mattpocock/skills. We install them GLOBALLY (into ~/.claude/skills/) so they
# are available in every project and so a SessionStart hook can install them once
# regardless of the current directory. Nothing is vendored into stack-pill;
# upstream (mattpocock/skills) stays the source of truth.
#
# Invoked from hooks/hooks.json on SessionStart as:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-matt-skills.sh"
# (run via `bash`, so no execute bit is required.)
#
# Design notes (mirrors scripts/install-graphify.sh):
#   - Returns immediately; the npx install runs fully detached so it never
#     blocks session start.
#   - Idempotent: a sentinel (or an existing mattpocock entry in the global
#     skills lock file) short-circuits it; a lockfile prevents concurrent runs.
#   - Non-interactive: `skills add` is interactive by default and, with stdin
#     closed, CANCELS and exits 0 WITHOUT installing. We pass explicit flags
#     (--skill '*' --agent claude-code --global --yes) so no prompt is ever
#     reached, and we confirm success by checking the lock file rather than the
#     exit code.
#   - Safe: only Node/npx (already required by Impeccable's hook). Node >= 18.
#   - Opt-out: STACK_PILL_SKIP_MATT_SKILLS=1 or a `matt-skills-skip` marker file.
#
# Foreground mode:
#   Pass `--wait` (or set STACK_PILL_MATT_SKILLS_WAIT=1) to run the install in
#   the foreground and stream progress, returning only when done. install.sh /
#   the install one-liner use this so the skills are installed as part of
#   installing stack-pill. The SessionStart hook calls it without --wait.

set -u

# --- Foreground mode flag ---------------------------------------------------
WAIT=0
case "${1:-}" in --wait | -w) WAIT=1 ;; esac
[ "${STACK_PILL_MATT_SKILLS_WAIT:-0}" = "1" ] && WAIT=1

# --- Resolve a persistent data dir (survives plugin updates) ----------------
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/stack-pill}"
mkdir -p "$DATA_DIR" 2>/dev/null || true

SENTINEL="$DATA_DIR/matt-skills-installed"
SKIP_FILE="$DATA_DIR/matt-skills-skip"
LOCK="$DATA_DIR/matt-skills-install.lock"
LOG="$DATA_DIR/matt-skills-install.log"
# Global skills lock file written by the `skills` CLI; our success signal.
# The CLI writes to ~/.agents/.skill-lock.json (not an XDG path).
SKILL_LOCK="$HOME/.agents/.skill-lock.json"
# Export so the detached `setsid bash -c` worker (a fresh shell) inherits them.
export DATA_DIR SENTINEL SKIP_FILE LOCK LOG SKILL_LOCK

# --- Opt-out ----------------------------------------------------------------
if [ "${STACK_PILL_SKIP_MATT_SKILLS:-0}" = "1" ] || [ -f "$SKIP_FILE" ]; then
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
# Sentinel, or an existing mattpocock entry in the global skills lock file.
if [ -f "$SENTINEL" ] || { [ -f "$SKILL_LOCK" ] && grep -q "mattpocock/skills" "$SKILL_LOCK" 2>/dev/null; }; then
  [ "$WAIT" = "1" ] && echo "stack-pill: mattpocock skills already installed."
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
  echo "[stack-pill] $(date 2>/dev/null) installing mattpocock skills (npm: skills, repo: mattpocock/skills)..."

  if ! command -v npx >/dev/null 2>&1; then
    echo "[stack-pill] 'npx' not found. Install Node.js >= 18 (https://nodejs.org), then restart Claude Code."
    echo "[stack-pill] (mattpocock skills install needs Node/npx; nothing was changed.)"
    rm -f "$LOCK"
    return 0
  fi

  # Fully non-interactive: select all skills, target only Claude Code, global
  # scope, skip every confirmation. stdin closed as belt-and-suspenders.
  npx --yes skills@latest add mattpocock/skills \
    --skill '*' --agent claude-code --global --yes </dev/null || true

  # Success keys off the lock file, NOT the exit code: a cancelled interactive
  # run exits 0 but installs nothing.
  if [ -f "$SKILL_LOCK" ] && grep -q "mattpocock/skills" "$SKILL_LOCK" 2>/dev/null; then
    touch "$SENTINEL"
    echo "[stack-pill] mattpocock skills installed (global: ~/.claude/skills/)."
    echo "[stack-pill] Next: run /setup-matt-pocock-skills once to configure issue tracker / triage labels / docs location."
  else
    echo "[stack-pill] mattpocock skills install did not complete (no mattpocock/skills entry in $SKILL_LOCK)."
    echo "[stack-pill] Will retry next session. Manual: npx skills@latest add mattpocock/skills --skill '*' --agent claude-code --global --yes"
  fi

  rm -f "$LOCK"
}

# --- Foreground (--wait): stream progress, block until done -----------------
if [ "$WAIT" = "1" ]; then
  echo "stack-pill: installing mattpocock skills now…"
  run_install 2>&1 | tee -a "$LOG"
  if [ -f "$SENTINEL" ]; then
    echo "stack-pill: mattpocock skills install complete."
  else
    echo "stack-pill: mattpocock skills install did not complete — see $LOG"
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

echo "stack-pill: setting up mattpocock skills in the background (first run only)."
exit 0
