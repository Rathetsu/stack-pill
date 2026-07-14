# Graph Report - stack-pill  (2026-07-14)

## Corpus Check
- 14 files · ~6,601 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 53 nodes · 52 edges · 11 communities (5 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2d048dfa`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]

## God Nodes (most connected - your core abstractions)
1. `Stackdrop toolkit — when to reach for what` - 7 edges
2. `install.sh script` - 6 edges
3. `stack-pill` - 4 edges
4. `owner` - 3 edges
5. `have_market()` - 3 edges
6. `have_plugin()` - 3 edges
7. `ensure_market()` - 3 edges
8. `ensure_plugin()` - 3 edges
9. `metadata` - 2 edges
10. `bootstrap()` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (11 total, 6 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.40
Nodes (4): Adding a team skill, Install, stack-pill, What's installed

### Community 1 - "Community 1"
Cohesion: 0.62
Nodes (6): bootstrap(), ensure_market(), ensure_plugin(), have_market(), have_plugin(), install.sh script

### Community 2 - "Community 2"
Cohesion: 0.22
Nodes (8): metadata, description, name, owner, email, name, plugins, $schema

### Community 3 - "Community 3"
Cohesion: 0.25
Nodes (7): Graphify — codebase/docs → queryable knowledge graph, Impeccable — frontend design & UX (`/impeccable <command>`), mattpocock skills — complementary workflows, More installed tools, Overlaps — which to prefer, Stackdrop toolkit — when to reach for what, Superpowers — the default development methodology

### Community 9 - "Community 9"
Cohesion: 0.25
Nodes (7): 1. Confirm you're in the stack-pill checkout, 2. Work out the skill's name and description, 3. Create `skills/<name>/SKILL.md`, 4. Bump the version in lockstep, 5. Add it to the usage guide, 6. Validate, 7. Show, commit, push

## Knowledge Gaps
- **25 isolated node(s):** `$schema`, `name`, `name`, `email`, `description` (+20 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `$schema`, `name`, `name` to the rest of the system?**
  _25 weakly-connected nodes found - possible documentation gaps or missing edges._