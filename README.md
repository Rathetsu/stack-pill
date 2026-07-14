# stack-pill

One command sets up the base skills and plugins every Stackdrop project should
start with.

## What's installed

| Tool | What it brings |
|---|---|
| [Superpowers](https://github.com/obra/superpowers) | Core dev skills — TDD, systematic debugging, planning, and verification. |
| [Impeccable](https://github.com/pbakaus/impeccable) | Frontend design & UX fluency for production-grade UIs. |
| [Graphify](https://pypi.org/project/graphifyy) | Turns any codebase or docs into a queryable knowledge graph. |
| [mattpocock skills](https://github.com/mattpocock/skills) | Requirements grilling, PRDs, issues, triage, and architecture reviews. |
| [Context7](https://context7.com) | Up-to-date library and API docs on demand. |
| [Playwright](https://github.com/microsoft/playwright-mcp) | Browser automation and end-to-end testing. |
| [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | Drives a live Chrome for performance traces and debugging. |
| [CodeRabbit](https://docs.coderabbit.ai) | AI code review across 40+ static analyzers. |
| [skill-creator](https://github.com/anthropics/claude-plugins-official) | Create, evaluate, and improve Claude Code skills. |
| [ponytail](https://github.com/DietrichGebert/ponytail) | Anti-over-engineering reviewer that flags complexity and proposes deletions. |

## Install

One command:

```bash
curl -fsSL https://raw.githubusercontent.com/Rathetsu/stack-pill/master/install.sh | bash -s -- Rathetsu/stack-pill
```

This registers the `stackdrop` marketplace, installs `stack-pill`, then installs
the bundled plugins and bootstraps the CLI tools. It is idempotent, so re-running
it is safe. Restart Claude Code when it finishes.

> **Windows:** run this in **Git Bash** or **WSL**, not PowerShell.

**Already installed?** To pull the newest version now:

```bash
claude plugin marketplace update stackdrop && claude plugin update stack-pill@stackdrop
```

Then restart Claude Code. (Once you're on a version with the auto-update hook,
this happens on its own, about once a day at session start.)

<details>
<summary>Prefer to run the steps yourself?</summary>

```bash
claude plugin marketplace add Rathetsu/stack-pill
claude plugin install stack-pill@stackdrop
bash "$(ls -dt "$HOME"/.claude/plugins/cache/stackdrop/stack-pill/*/install.sh | head -1)" --extras-only
```

Add the marketplace by its GitHub slug (`Rathetsu/stack-pill`), not a local
clone path: a local path pins updates to that directory and disables
auto-update.

</details>

## Adding a team skill

Custom skills live in this repo under `skills/`. To add one and ship it to the
whole team:

```bash
git clone https://github.com/Rathetsu/stack-pill && cd stack-pill
# then, in Claude Code:
/stack-pill:add-skill my-skill "what it does and when to use it"
```

The command scaffolds `skills/my-skill/SKILL.md`, bumps the version, updates the
usage guide, and commits + pushes. Teammates receive it automatically at their
next session start (the auto-update hook, ~once a day) after a restart. For
deeper skill authoring/evaluation, use the bundled `skill-creator`; `add-skill`
handles packaging and release.
