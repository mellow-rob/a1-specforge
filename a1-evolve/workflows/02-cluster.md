# Phase 2: Cluster

Group observations by pattern and identify what to improve.

## Clustering logic

### 2a. Group by pattern tag
From all observations, group by the `pattern` field:

```
missing_wiring: [obs1, obs2, obs3, obs4, obs5]
wave_ordering:  [obs1, obs2, obs3]
vague_action:   [obs1, obs2]
missing_import: [obs1]
```

### 2b. Group by affected skill/agent
For each pattern cluster, identify which skill/agent file is responsible:

| Pattern | Root cause | File to fix |
|---|---|---|
| `missing_wiring` | Planner doesn't include wiring as must-have | `agents/a1-planner.md` |
| `wiring_gap` | Planner misses "wire to router" task | `agents/a1-planner.md` |
| `wave_ordering` | Planner puts dependent tasks in same wave | `agents/a1-planner.md` |
| `vague_action` | Plan task actions aren't specific enough | `agents/a1-planner.md` |
| `missing_migration` | Researcher doesn't check for schema changes | `agents/a1-researcher.md` |
| `env_var_undocumented` | Planner/executor doesn't add env var doc task | `agents/a1-executor.md` |
| `research_stale` | Researcher uses cached/old library knowledge | `agents/a1-researcher.md` |
| `test_gap` | Planner doesn't include test tasks | `agents/a1-planner.md` |
| `type_error_cascade` | Wave 1 type changes break Wave 2 | `agents/a1-planner.md` (wave design) |

### 2c. Score by impact

For each cluster, compute:
- **Frequency**: count of occurrences
- **Severity score**: minor=1, major=3, critical=5
- **Impact score**: frequency × average severity

Sort by impact score descending.

### 2d. Build cluster report

```
Pattern Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 missing_wiring (impact: 24)
   Occurrences: 8 | Avg severity: major
   Affected: a1-planner.md
   Sample: "Router wiring not in plan — had to add manually"
   
🟡 wave_ordering (impact: 9)
   Occurrences: 3 | Avg severity: major
   Affected: a1-planner.md
   Sample: "Wave 2 task depended on Wave 2 output from different task"

🟢 missing_import (impact: 3)
   Occurrences: 3 | Avg severity: minor
   Affected: a1-executor.md (handling ok, just noting)
   → Below threshold for change (minor severity, executor handles it)
```

Only patterns with impact score ≥ 6 proceed to Phase 3.
