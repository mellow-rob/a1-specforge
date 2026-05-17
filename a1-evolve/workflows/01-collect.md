# Phase 1: Collect

Gather all learning data from all sources.

## Steps

### 1a. Read all _learning.md files
```bash
find ~/.claude/skills -name "_learning.md" | sort
```
Read each file. Extract:
- Date and project
- Skill used
- Outcome (PASS/PARTIAL/FAIL)
- Observations list
- Retro bullets
- Suggested improvements

### 1b. Read observations from current projects
```bash
find . -path "*/.a1/phases/*/observations.jsonl" 2>/dev/null
# Also check other common project locations
find ~/code -path "*/.a1/phases/*/observations.jsonl" -newer ~/.claude/skills/_shared/learnings-index.md 2>/dev/null | head -20
```
Parse JSONL. Collect all observation objects.

### 1c. Read existing learnings index
```bash
cat ~/.claude/skills/_shared/learnings-index.md 2>/dev/null
```
Note the "Last synthesis" date — only process observations newer than that date to avoid double-counting.

### 1d. Summarize what was collected
Output:
```
Collected:
- <N> learning entries across <M> skills
- <N> raw observations from <M> projects
- Date range: <oldest> to <newest>
- New since last synthesis: <N> entries
```

Proceed to Phase 2.
