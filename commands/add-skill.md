---
description: Scaffold a new stack-pill team skill, bump the version, update the guide, and commit + push so the team receives it
argument-hint: <skill-name> [what it does / when to use it]
---

You are adding a new team skill to the **stack-pill** repo so every Stackdrop
teammate receives it automatically. Follow these steps exactly.

## 1. Confirm you're in the stack-pill checkout

Check that `.claude-plugin/marketplace.json` exists here and contains
`"name": "stackdrop"`. If not, STOP and tell the user:

> Run this from a clone of the stack-pill repo:
> `git clone https://github.com/Rathetsu/stack-pill && cd stack-pill`, then re-run `/stack-pill:add-skill`.

## 2. Work out the skill's name and description

From `$ARGUMENTS`:
- **name**: kebab-case (lowercase, hyphens). Reject anything else; derive it if needed.
- **description**: one sentence on what it does, followed by concrete "Use when …"
  triggers (the phrases/situations that should activate it). The description is
  how Claude decides whether to invoke the skill, so make the triggers specific.

If either is missing or vague, ask the user one short question before continuing.
If `skills/<name>/` already exists, ask whether to overwrite or pick a new name.

## 3. Create `skills/<name>/SKILL.md`

Use this template (fill every placeholder, delete none of the structure):

```markdown
---
name: <skill-name>
description: <What it does in one sentence>. Use when <concrete trigger situations and phrases>.
---

# <Skill Title>

## When to use
- <trigger 1>
- <trigger 2>

## Workflow
1. <step Claude follows>
2. <step Claude follows>
```

## 4. Bump the version in lockstep

Increment the PATCH number in **both** files, keeping them identical:
- `.claude-plugin/plugin.json` → `"version"`
- `.claude-plugin/marketplace.json` → the `stack-pill` entry's `"version"`

(They must match or `claude plugin validate` fails, and the cache dir is keyed
on this version.)

## 5. Add it to the usage guide

In `instructions/skills-guide.md`, add a row for the new skill under a
`## Team skills` section (create that section, with a short intro line, if it
doesn't exist yet). Give the invocation (`/stack-pill:<name>` for commands, or
"auto-triggers" for model-invoked skills) and one line on when to reach for it.

## 6. Validate

Run `claude plugin validate .` and fix anything it reports before committing.

## 7. Show, commit, push

Show the user the full diff. On their confirmation:
- `git add -A`
- `git commit -m "add skill: <name>"`
- `git push` (to the current branch; note if it isn't `master`)

Then tell them:

> Done. Teammates get `<name>` automatically at their next session start
> (within ~a day, via the auto-update hook) after a restart. To pull it right
> now: `claude plugin update stack-pill@stackdrop` and restart Claude Code.
