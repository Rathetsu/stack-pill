# Graph Report - stack-pill  (2026-07-14)

## Corpus Check
- 13 files · ~5,322 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 41 nodes · 40 edges · 9 communities (4 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a163d240`
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

## God Nodes (most connected - your core abstractions)
1. `Stackdrop toolkit — when to reach for what` - 7 edges
2. `install.sh script` - 4 edges
3. `owner` - 3 edges
4. `ensure_market()` - 3 edges
5. `ensure_plugin()` - 3 edges
6. `stack-pill` - 3 edges
7. `metadata` - 2 edges
8. `have_market()` - 2 edges
9. `have_plugin()` - 2 edges
10. `bootstrap()` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (9 total, 5 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.50
Nodes (3): Install, stack-pill, What's installed

### Community 1 - "Community 1"
Cohesion: 0.52
Nodes (6): bootstrap(), ensure_market(), ensure_plugin(), have_market(), have_plugin(), install.sh script

### Community 2 - "Community 2"
Cohesion: 0.22
Nodes (8): metadata, description, name, owner, email, name, plugins, $schema

### Community 3 - "Community 3"
Cohesion: 0.25
Nodes (7): Graphify — codebase/docs → queryable knowledge graph, Impeccable — frontend design & UX (`/impeccable <command>`), mattpocock skills — complementary workflows, More installed tools, Overlaps — which to prefer, Stackdrop toolkit — when to reach for what, Superpowers — the default development methodology

## Knowledge Gaps
- **16 isolated node(s):** `$schema`, `name`, `name`, `email`, `description` (+11 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `$schema`, `name`, `name` to the rest of the system?**
  _16 weakly-connected nodes found - possible documentation gaps or missing edges._