#!/usr/bin/env bash
#
# stack-pill: per-project Graphify setup, run on SessionStart.
#
# This hook is SYNCHRONOUS and FAST. Its stdout is added to Claude's context
# (SessionStart additionalContext), so it is used to *nudge* Claude to offer a
# knowledge-graph build when the current git project doesn't have one yet.
#
# It does NOT build a graph itself: the full /graphify build is agent-driven
# (it needs the model for doc/image extraction + community labels), so we only
# suggest it. We also install Graphify's free git post-commit hook once per repo
# so the graph stays fresh (AST-only) after the first build.
#
# Invoked via `bash` (no execute bit needed). Always exits 0 (never blocks).
#
# Opt-out: STACK_PILL_SKIP_GRAPHIFY=1, ${CLAUDE_PLUGIN_DATA}/graphify-skip,
#          or a `.graphify-skip` file in the project root.

set -u

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/stack-pill}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"

# --- Global opt-out ---------------------------------------------------------
if [ "${STACK_PILL_SKIP_GRAPHIFY:-0}" = "1" ] || [ -f "$DATA_DIR/graphify-skip" ]; then
  exit 0
fi

# --- Git repos only ---------------------------------------------------------
# Run only inside a git work tree; never build graphs in random folders.
if ! git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi
# Resolve to the repo root so markers/paths are stable per repo.
PROJECT="$(git -C "$PROJECT" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT")"

# --- Per-project opt-out ----------------------------------------------------
if [ -f "$PROJECT/.graphify-skip" ]; then
  exit 0
fi

# --- PATH discovery (find graphify if installed) ----------------------------
for d in "$HOME/.local/bin" "$HOME/.cargo/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) [ -d "$d" ] && PATH="$d:$PATH" ;;
  esac
done
export PATH

# --- Nudge: offer to build a graph if this repo has none --------------------
# stdout on a SessionStart hook becomes additionalContext for Claude.
if [ ! -f "$PROJECT/graphify-out/graph.json" ]; then
  cat <<'EOF'
[stack-pill] This git project has no Graphify knowledge graph yet (no graphify-out/graph.json).
If the user asks about this codebase's architecture, structure, dependencies, or how parts connect,
offer to build one first by invoking the graphify skill: run `/graphify .` (a one-time, full build).
Do not build it unprompted — just offer when it would help. If the user declines, don't ask again this session.
EOF
fi

# --- Ensure Graphify's git post-commit hook is installed (once per repo) -----
# Free, AST-only rebuild on each commit. Skipped if graphify isn't installed yet
# (first session, tool install may still be running) — self-heals next session.
if command -v graphify >/dev/null 2>&1; then
  # Stable per-repo marker so we only run `graphify hook install` once.
  if command -v shasum >/dev/null 2>&1; then
    repo_hash="$(printf '%s' "$PROJECT" | shasum | awk '{print $1}')"
  elif command -v sha1sum >/dev/null 2>&1; then
    repo_hash="$(printf '%s' "$PROJECT" | sha1sum | awk '{print $1}')"
  else
    repo_hash="$(printf '%s' "$PROJECT" | cksum | awk '{print $1}')"
  fi
  marker_dir="$DATA_DIR/repo-hooks"
  marker="$marker_dir/$repo_hash"
  if [ ! -f "$marker" ]; then
    mkdir -p "$marker_dir" 2>/dev/null || true
    # Detach so a slow/quirky hook install never delays session start.
    if command -v setsid >/dev/null 2>&1; then
      setsid bash -c "cd \"$PROJECT\" && graphify hook install >/dev/null 2>&1" </dev/null >/dev/null 2>&1 &
    else
      nohup bash -c "cd \"$PROJECT\" && graphify hook install >/dev/null 2>&1" </dev/null >/dev/null 2>&1 &
    fi
    : > "$marker" 2>/dev/null || true
  fi
fi

exit 0
