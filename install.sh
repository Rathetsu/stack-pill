#!/usr/bin/env bash
#
# stack-pill: one-shot installer for the Stackdrop team.
#
# One command installs the whole bundle:
#   1. registers the `stackdrop` marketplace
#   2. installs the `stack-pill` plugin (which auto-installs Superpowers + Impeccable)
#   3. installs the official + third-party plugins by name from their own
#      marketplaces (Playwright, skill-creator, chrome-devtools-mcp, CodeRabbit,
#      and ponytail) -- idempotent and non-fatal, so re-runs are safe.
#   4. bootstraps the non-plugin tools in the foreground (so they're ready when
#      this script returns): Graphify, the mattpocock skills, and Context7.
#
# Usage:
#   bash install.sh                      # from the cloned repo (uses ./ as the marketplace)
#   bash install.sh StackdropCO/stack-pill # from a GitHub marketplace
#   bash install.sh /path/to/stack-pill  # from a local path
#   bash install.sh --extras-only        # skip marketplace+stack-pill; run only steps 3-4
#                                        # (the README one-liner uses this after installing stack-pill)
#
# Requires the `claude` CLI (>= v2.1.143). Graphify also needs uv or pipx +
# Python 3; the mattpocock skills and Context7 need Node.js >= 18 (npx).

set -euo pipefail

# --- Args: --extras-only, or the marketplace source -------------------------
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
EXTRAS_ONLY=0
MARKET_SRC="$SELF_DIR"
case "${1:-}" in
  --extras-only) EXTRAS_ONLY=1 ;;
  "") ;;
  *) MARKET_SRC="$1" ;;
esac

if ! command -v claude >/dev/null 2>&1; then
  echo "error: the 'claude' CLI is not on PATH. Install Claude Code first." >&2
  exit 1
fi

# --- Idempotent, non-fatal helpers ------------------------------------------
# claude CLI idempotency/exit codes are undocumented, so we check first and
# never let a single failure abort the rest of the install.
have_market() { claude plugin marketplace list 2>/dev/null | grep -q "$1"; }
have_plugin() { claude plugin list 2>/dev/null | grep -q "$1"; }

ensure_market() { # <add-arg> <name>
  if have_market "$2"; then
    echo "    marketplace $2 already registered"
  else
    echo "    adding marketplace $2"
    claude plugin marketplace add "$1" || echo "warning: failed to add marketplace $1" >&2
  fi
}

ensure_plugin() { # <name@marketplace>
  if have_plugin "$1"; then
    echo "    $1 already installed"
  else
    echo "    installing $1"
    claude plugin install "$1" || echo "warning: failed to install $1" >&2
  fi
}

bootstrap() { # <script-name> <label>
  local script
  script="$(ls -dt "$HOME"/.claude/plugins/cache/stackdrop/stack-pill/*/scripts/"$1" 2>/dev/null | head -1 || true)"
  # Prefer the cached copy; fall back to this repo's own scripts dir.
  [ -z "${script:-}" ] && [ -f "$SELF_DIR/scripts/$1" ] && script="$SELF_DIR/scripts/$1"
  if [ -n "${script:-}" ] && [ -f "$script" ]; then
    bash "$script" --wait
  else
    echo "warning: could not locate $1; $2 will set up automatically on your next Claude Code session instead." >&2
  fi
}

# --- 1-2. Marketplace + stack-pill (skipped in --extras-only) ---------------
if [ "$EXTRAS_ONLY" -eq 0 ]; then
  echo "==> Adding marketplace: $MARKET_SRC"
  claude plugin marketplace add "$MARKET_SRC"

  echo "==> Installing stack-pill (pulls Superpowers + Impeccable)"
  claude plugin install stack-pill@stackdrop
fi

# --- 3. Bundled plugins (by name, from their own marketplaces) --------------
echo "==> Installing bundled plugins"
ensure_market anthropics/claude-plugins-official claude-plugins-official
for p in playwright skill-creator chrome-devtools-mcp coderabbit; do
  ensure_plugin "$p@claude-plugins-official"
done
ensure_market DietrichGebert/ponytail ponytail
ensure_plugin ponytail@ponytail

# --- 4. Non-plugin tool bootstraps (foreground) -----------------------------
echo "==> Installing Graphify (foreground)"
bootstrap install-graphify.sh Graphify

echo "==> Installing mattpocock skills (foreground)"
bootstrap install-matt-skills.sh "the mattpocock skills"

echo "==> Setting up Context7 (foreground)"
bootstrap install-ctx7.sh Context7

echo
echo "Done. Start (or restart) Claude Code."
echo "Installed: Superpowers, Impeccable, Graphify, mattpocock skills, Context7,"
echo "           Playwright, skill-creator, chrome-devtools-mcp, CodeRabbit, ponytail."
echo
echo "Next steps:"
echo "  • CodeRabbit needs a one-time free sign-in — run /coderabbit (or 'coderabbit auth')."
echo "  • Run /setup-matt-pocock-skills once (issue tracker, triage labels, docs location)."
echo "  • Optional: 'npx ctx7@latest login' for a higher Context7 docs quota."
echo "  • In a git project, ask about the codebase and Claude will offer to build a Graphify graph (/graphify .)."
