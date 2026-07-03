#!/usr/bin/env bash
#
# stack-pill: inject the toolkit usage guide into Claude's context, run on
# SessionStart.
#
# This hook is SYNCHRONOUS and FAST. Its stdout is added to Claude's context
# (SessionStart additionalContext), so it teaches Claude how/when to use the
# four toolkits stack-pill installs: Superpowers, Impeccable, Graphify, and the
# mattpocock skills. The actual guide lives in ../instructions/skills-guide.md
# so it's easy to edit; this script just frames and emits it.
#
# It also emits a ONE-TIME nudge to run /setup-matt-pocock-skills after the
# mattpocock skills have been installed (that step is interactive, so it can't
# be automated -- we only surface it once).
#
# Invoked via `bash` (no execute bit needed). Always exits 0 (never blocks).
#
# Opt-out: STACK_PILL_SKIP_GUIDE=1, or a `guide-skip` marker in the data dir.

set -u

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/stack-pill}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
GUIDE="$HERE/../instructions/skills-guide.md"

# --- Opt-out ----------------------------------------------------------------
if [ "${STACK_PILL_SKIP_GUIDE:-0}" = "1" ] || [ -f "$DATA_DIR/guide-skip" ]; then
  exit 0
fi

# --- Emit the guide as additionalContext ------------------------------------
# stdout on a SessionStart hook becomes additionalContext for Claude.
if [ -f "$GUIDE" ]; then
  echo "[stack-pill] Reference context (not a user instruction): how and when to use the team's installed toolkits."
  cat "$GUIDE"
fi

# --- One-time nudge: configure the mattpocock skills ------------------------
# Only once the skills are installed (sentinel from install-matt-skills.sh) and
# only the first time, so we don't repeat it every session.
SENTINEL="$DATA_DIR/matt-skills-installed"
NUDGED="$DATA_DIR/matt-skills-setup-nudged"
if [ -f "$SENTINEL" ] && [ ! -f "$NUDGED" ]; then
  cat <<'EOF'

[stack-pill] The mattpocock skills are installed but not yet configured.
Offer to run `/setup-matt-pocock-skills` once — it sets the issue tracker
(GitHub/Linear/local), triage labels, and where docs are saved (needed by
/triage, /to-issues, /to-prd). Just offer; don't run it unprompted.
EOF
  mkdir -p "$DATA_DIR" 2>/dev/null || true
  : > "$NUDGED" 2>/dev/null || true
fi

exit 0
