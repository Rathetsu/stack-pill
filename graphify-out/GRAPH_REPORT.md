# Graph Report - stack-pill  (2026-07-06)

## Corpus Check
- 13 files · ~5,322 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 11 nodes · 14 edges · 3 communities (2 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `514bf224`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]

## God Nodes (most connected - your core abstractions)
1. `install.sh script` - 4 edges
2. `stack-pill` - 3 edges
3. `ensure_market()` - 3 edges
4. `ensure_plugin()` - 3 edges
5. `have_market()` - 2 edges
6. `have_plugin()` - 2 edges
7. `bootstrap()` - 2 edges
8. `What's installed` - 1 edges
9. `Install` - 1 edges

## Surprising Connections (you probably didn't know these)
- `install.sh script` --calls--> `ensure_plugin()`  [EXTRACTED]
  install.sh → install.sh  _Bridges community 1 → community 2_

## Import Cycles
- None detected.

## Communities (3 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.50
Nodes (3): Install, stack-pill, What's installed

### Community 1 - "Community 1"
Cohesion: 0.70
Nodes (4): bootstrap(), ensure_market(), have_market(), install.sh script

## Knowledge Gaps
- **2 isolated node(s):** `What's installed`, `Install`
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `install.sh script` connect `Community 1` to `Community 2`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **What connects `What's installed`, `Install` to the rest of the system?**
  _2 weakly-connected nodes found - possible documentation gaps or missing edges._