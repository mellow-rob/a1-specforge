---
name: a1-evolve
description: >
  Self-optimization engine for the a1 skill set. Reads accumulated observations
  (`.a1/phases/*/observations.jsonl`) and per-skill _learning.md files plus the
  Obsidian Vault `areas/a1-learnings/*.md`, clusters recurring patterns, scores
  by impact (frequency × severity), and proposes concrete diff-level
  improvements to agent files and SKILL.md / workflow files. Four phases:
  Collect → Cluster → Propose → Apply (with user confirmation per diff).
  Confidence thresholds: 1-2 occurrences = monitor, 3-4 = propose, 5+ =
  high-confidence. Commits applied changes to ~/code/a1-skills/. MUST trigger
  when the user says: "a1-evolve", "skills verbessern", "learnings auswerten",
  "was können wir verbessern", "skill optimization", "retros auswerten",
  "synthesize learnings", "pattern analysis", "improve the a1 skills",
  "evolve the agents", or when a1-execute reports 5+ accumulated learnings
  since last synthesis. Scope: only edits files in ~/code/a1-skills/ — never
  touches ~/.claude/rules/ (user-authored). Do NOT activate for: a single
  retro entry (just write it via the host skill's Retro block), planning new
  features (use a1-new-feature), or routine project execution.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# a1-evolve — Self-Optimization Engine

Reads what went wrong and right across all a1 skill runs, then proposes precise, targeted
improvements to skill and agent files.

**Philosophy:** Skills improve through use, not through theorizing. Every observation is a
data point. Patterns that appear 3+ times across different projects are signal — not noise.

## Input sources

| Source | What it contains |
|--------|-----------------|
| `~/.claude/skills/<skill>/_learning.md` | Per-run retros with structured observations |
| `.a1/phases/*/observations.jsonl` | Raw inline observations from agents |
| `~/.claude/skills/_shared/learnings-index.md` | Cross-skill pattern index (maintained by this skill) |

## Workflow

See `workflows/01-collect.md` → `02-cluster.md` → `03-propose.md` → `04-apply.md`

## Output

1. **Pattern report** — what's recurring, how often, what impact
2. **Diff proposals** — concrete edits to specific files with before/after
3. **Applied changes** — on user approval, commits to repo

## Confidence thresholds

| Occurrences | Action |
|---|---|
| 1-2 | Log in index, monitor |
| 3-4 | Propose improvement (user reviews) |
| 5+ | Propose with "high confidence" flag — suggest direct apply |

## Scope

a1-evolve only proposes changes to files in `~/code/a1-skills/`:
- `agents/*.md` — agent instructions
- `*/SKILL.md` — skill definitions
- `*/workflows/*.md` — workflow steps

It never auto-modifies `~/.claude/rules/` — those are user-authored.
