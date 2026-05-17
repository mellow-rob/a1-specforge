# Phase 3: Verify

Spawn a1-verifier to validate the completed work.

## Prompt template

```
Verify that the phase goal was achieved.

<files_to_read>
- .a1/phases/<phase_name>/PLAN.md
- .a1/phases/<phase_name>/STATUS.md
- <spec_path> (if available)
</files_to_read>

**Output path:** .a1/phases/<phase_name>/VERIFICATION.md
```

## Routing by verdict

### PASS
```
✅ Phase complete: <goal>

All <N> success criteria verified.
Build: ✓  Tests: ✓  TypeScript: ✓

Commits: <list>

What's next?
- Deploy: use a1-checklist then Dirk/Dennis
- New phase: use a1-plan
- Check project status: use a1-progress
```

### PARTIAL
```
⚠ Phase mostly complete — <N> gaps remain:

<gap list>

Options:
1. Fix gaps now (I'll spawn a1-executor for the specific missing pieces)
2. Accept and move on (gaps are minor)
3. Show full VERIFICATION.md
```

### FAIL
```
❌ Phase incomplete — <N> criteria not met:

<failure list>

I recommend targeted re-execution. Which gaps should I fix first?
```

For FAIL/PARTIAL re-execution: spawn a1-executor with a targeted prompt listing only the missing work, not the full plan.

---

## Retro-Capture (always — after verdict is shown)

After presenting the verdict, write a learning entry to `~/.claude/skills/a1-execute/_learning.md`:

```bash
LEARNING_FILE="$HOME/.claude/skills/a1-execute/_learning.md"
OBS_FILE=".a1/phases/<phase_name>/observations.jsonl"

# Count observations
OBS_COUNT=$(wc -l < "$OBS_FILE" 2>/dev/null || echo 0)
# Count major+ observations
MAJOR_COUNT=$(grep -c '"severity":"major\|critical"' "$OBS_FILE" 2>/dev/null || echo 0)

cat >> "$LEARNING_FILE" << ENTRY

## $(date +%Y-%m-%d) — <project_name> / <phase_name>

**Skill:** a1-execute
**Outcome:** <PASS|PARTIAL|FAIL> (<gaps count> gaps)
**Project type:** <detected stack, e.g. Next.js + Postgres>
**Observations:** $OBS_COUNT total, $MAJOR_COUNT major+

### Observations summary
$(cat "$OBS_FILE" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        o = json.loads(line)
        print(f'- [{o[\"agent\"]}/W{o.get(\"wave\",\"?\")}/{o[\"severity\"]}] {o[\"msg\"]} (pattern: {o[\"pattern\"]})')
    except: pass
" 2>/dev/null || echo "- (no observations file)")

### Retro
<3-5 honest bullets — what went well, what didn't, one improvement suggestion>
ENTRY
```

**Retro format (fill in honestly):**
```
✅ <what worked well — specific>
✅ <what worked well>
⚠️ <what didn't work / took extra effort>
⚠️ <pattern that keeps recurring>
💡 Suggestion: <one concrete improvement to a skill/agent file>
```

**Learning threshold check:**
After writing, count total entries in `_learning.md`:
```bash
ENTRY_COUNT=$(grep -c "^## 20" "$LEARNING_FILE" 2>/dev/null || echo 0)
```
If `$ENTRY_COUNT` is a multiple of 5 (5, 10, 15...): surface to user:
> "📚 5 neue Learnings akkumuliert. `a1-evolve` ausführen um Skill-Verbesserungen vorzuschlagen?"
