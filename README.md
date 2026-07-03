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

```bash
claude plugin marketplace add StackdropCO/stack-pill \
  && claude plugin install stack-pill@stackdrop \
  && bash "$(ls -dt "$HOME"/.claude/plugins/cache/stackdrop/stack-pill/*/install.sh | head -1)" --extras-only
```
