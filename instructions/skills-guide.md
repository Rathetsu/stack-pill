# Stackdrop toolkit — when to reach for what

stack-pill installs four toolkits. Use this as a quick router; invoke the
underlying skill/command for the full instructions when one applies.

| If the task is… | Reach for | How |
|---|---|---|
| Any non-trivial coding work (plan → build → verify) | **Superpowers** | auto-triggers, or `/superpowers:<skill>` |
| Anything visible in the browser (UI / UX) | **Impeccable** | `/impeccable <command>` |
| Understanding a large/unfamiliar codebase or docs | **Graphify** | `/graphify .`, then `/graphify query "…"` |
| Requirements alignment, PRDs, issues, triage, refactor reports | **mattpocock skills** | `/grill-me`, `/to-prd`, `/triage`, … |
| Browser/E2E testing, perf profiling, code review, authoring skills, fresh docs | **More tools** (below) | `playwright`, `chrome-devtools-mcp`, `coderabbit`, `ponytail`, `skill-creator`, `ctx7` |

## Superpowers — the default development methodology
Skills auto-trigger at the right moment (and you can call `/superpowers:<skill>`):
- **Before building anything:** `brainstorming` → `writing-plans` (don't jump to code).
- **While implementing:** `test-driven-development`; `using-git-worktrees` for isolation; `subagent-driven-development` / `executing-plans` for plans.
- **When something breaks:** `systematic-debugging` (root-cause before fixing).
- **Before claiming done:** `verification-before-completion`; then `requesting-code-review` / `receiving-code-review` and `finishing-a-development-branch`.
Reach for Superpowers on essentially all coding work — it's the process layer.

## Impeccable — frontend design & UX (`/impeccable <command>`)
- **Build:** `init` (project setup), `craft` (end-to-end), `shape` (plan UX first), `document`, `extract` (tokens/components → design system).
- **Evaluate:** `critique` (UX heuristics), `audit` (a11y / perf / responsive).
- **Refine:** `polish`, `bolder`, `quieter`, `distill`, `harden` (errors/edge cases/i18n), `onboard` (first-run/empty states).
- **Enhance:** `animate`, `colorize`, `typeset`, `layout`, `delight`.
- **Fix:** `clarify` (copy/labels/errors), `adapt` (responsive), `optimize` (perf).
- **Iterate:** `live` (pick elements in the browser, generate variants).
Reach for Impeccable for any production-grade UI — it ships real, committed code, not prototypes.

## Graphify — codebase/docs → queryable knowledge graph
- **Build:** `/graphify .` (one-time full build of the current project), `/graphify <path|github-url>`.
- **Use an existing graph:** `/graphify query "how does auth work?"`, `/graphify path "A" "B"`, `/graphify explain "Name"`.
Reach for Graphify before diving into a big/unfamiliar codebase, or to trace "what calls what / who depends on whom." If `graphify-out/graph.json` exists, prefer querying it over re-reading the whole tree. (stack-pill already offers to build one in git projects that lack a graph.)

## mattpocock skills — complementary workflows
These are plain user skills (invoke as `/name`, no namespace):
- **Align & specify:** `/grill-me`, `/grill-with-docs` (requirements + domain docs), `/to-prd`, `/to-issues`.
- **Manage & improve:** `/triage` (move issues through states), `/improve-codebase-architecture` (refactor report), `/handoff` (compact a conversation for another agent), `/teach`.
- **Model-invoked (auto):** `prototype`, `diagnosing-bugs`, `tdd`, `domain-modeling`, `codebase-design`, `grilling`.
- **First time only:** run `/setup-matt-pocock-skills` to pick your issue tracker (GitHub/Linear/local), triage labels, and where docs are saved. `/triage` and the issue/PRD skills depend on this.

## More installed tools
- **Browser / E2E & debugging:** `playwright` — write and run browser tests (navigate, click, fill, assert, screenshot); reach for it for end-to-end / UI test automation. `chrome-devtools-mcp` — drive a live Chrome with full DevTools (performance traces, Lighthouse, network, console, device emulation); reach for it to profile performance or debug a real page.
- **Code review:** `coderabbit` (`/coderabbit`) — deep AST + static-analysis review of a diff/PR for bugs and security (free; needs a one-time sign-in). `ponytail` (`/ponytail-review`, `/ponytail-audit`) — flags over-engineering and proposes deletions/simplifications.
- **Authoring skills:** `skill-creator` (`/skill-creator`) — create, eval, improve, and benchmark Claude Code skills. Reach for it when building a new skill.
- **Up-to-date docs:** Context7 — the `ctx7` CLI + MCP (and the `find-docs` / `context7-mcp` skills). Use it to fetch current library/API docs instead of relying on memory whenever the user asks about a library, framework, SDK, or CLI.

## Overlaps — which to prefer
Superpowers and mattpocock both ship TDD and debugging skills. Default to
**Superpowers' process skills** as the primary methodology (planning, TDD,
systematic-debugging, review, verification). Use **mattpocock** for what's unique
to it: grilling/requirements, PRDs, issues, triage, domain modeling, and
architecture/refactor reports.

For **code review**, pick by intent: Superpowers `code-review` / `requesting-code-review`
for general review and merge-readiness; **CodeRabbit** for deep automated bug/security
analysis; **ponytail** for simplification / removing over-engineering. For **fresh
library docs**, prefer Context7 over guessing. Don't run two overlapping tools for the
same step.
