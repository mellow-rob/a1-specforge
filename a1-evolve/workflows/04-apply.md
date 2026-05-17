# Phase 4: Apply

Show each proposal in detail and apply on user confirmation.

## Per-proposal flow

For each proposal from Phase 3:

### 4a. Show full diff
Present the exact before/after change clearly.

### 4b. Ask for decision
```
Apply this change? 
[y] Apply  [n] Skip  [e] Edit first  [a] Apply all remaining
```

### 4c. Apply if confirmed
Use Edit tool to make the exact change.

### 4d. Verify change is syntactically correct
Quick read-back to confirm the edit landed cleanly.

## After all proposals processed

### Update learnings-index.md
```bash
cat > ~/.claude/skills/_shared/learnings-index.md << EOF
# Learning Index

Last synthesis: $(date +%Y-%m-%d)
Total patterns analyzed: <N>
Applied changes: <count>
Skipped: <count>

## Pattern History

| Pattern | Count | Status | Last seen | Change applied |
|---|---|---|---|---|
| missing_wiring | 8 | ✅ applied | 2026-05-17 | a1-planner.md +wiring checklist |
| wave_ordering | 3 | ✅ applied | 2026-05-17 | a1-planner.md +wave rules |
| vague_action | 2 | 👀 monitoring | 2026-05-17 | below threshold |
EOF
```

### Commit applied changes
```bash
git -C ~/code/a1-skills add agents/ */SKILL.md */workflows/
git -C ~/code/a1-skills commit -m "evolve: apply <N> skill improvements from <M> observations

Patterns addressed:
- missing_wiring (8 occurrences) → a1-planner.md
- wave_ordering (3 occurrences) → a1-planner.md
"
```

### Final report
```
━━━ Evolution Complete ━━━━━━━━━━━━━━━━━━

Applied: <N> improvements
Skipped: <N>
Monitoring: <N> patterns (below threshold)

Skills improved:
- agents/a1-planner.md (+2 sections)

Committed: feat(<hash>)

Next evolution: after ~5 more skill runs.
```
