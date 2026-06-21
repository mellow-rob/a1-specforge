# Phase 03 — Analyze (parallel sub-agent dispatch)

Goal: get focus-specific findings from specialist sub-agents, in parallel where
independent, with strict Output-Contract. Output: analysis file with
`status: analyzed`, populated `findings[]` and `agents_dispatched[]`.

## Step 1 — Select sub-agents based on focus

Read the focus from frontmatter. Use this mapping:

| Focus | Agents to dispatch (parallel) |
|---|---|
| `general` | a1-marco-mapper, a1-reinhard-reviewer |
| `security` | a1-reinhard-reviewer (always), a1-ludwig-legal (only if compliance/DSGVO mentioned in Scope) |
| `architecture` | a1-alex-architekt |
| `quality` | a1-reinhard-reviewer, a1-marco-mapper |
| `onboarding` | a1-marco-mapper, a1-alex-architekt, plus stack-specialist: a1-aik-ai-engineer for AI-heavy, a1-walter-web-developer for web-heavy, felix-flutter-engineer (global) for Flutter |

The stack-specialist for `onboarding` is chosen from the discover `tech_stack`:
- If `tech_stack` contains `flutter`/`dart` → felix-flutter-engineer
- If `tech_stack` contains AI/ML markers (langchain, transformers, vector DBs) → a1-aik-ai-engineer
- Otherwise → a1-walter-web-developer

### Always-on lanes (every focus)

In addition to the focus-specific agents above, **every** analysis run also
dispatches two standing lanes in parallel. They run for all five focus modes —
they are not focus-gated:

| Lane | Agent / Command | What it produces |
|---|---|---|
| Simplify | `code-simplifier` agent (read-only mode) | Findings for redundancy, unnecessary complexity, dead abstractions — as `category: simplification` findings, **never** code edits |
| Security | the `security-review` skill (read-only) | Findings for the standard vuln classes on the analyzed tree — as `category: security` findings |

Both lanes are **read-only** in this skill (see Step 3b). They emit findings into
the same `findings[]` contract as the specialist agents; they must not modify
project files. Their output feeds the same Synthesize/Report phases, so a single
analysis run now always surfaces (a) focus-specific findings, (b) simplification
opportunities, and (c) a security pass — which is exactly what later
implementations should learn from.

## Step 2 — Build briefs from the template

For each selected agent, read `~/.claude/skills/a1-analyze/templates/agent-brief-template.md`
and construct the brief by substituting:

- `<AGENT_NAME>` — the agent name (e.g. `a1-reinhard-reviewer`)
- `<FOCUS_HUMAN>` — the focus label (Security / Architecture / Quality / Onboarding / General)
- `<PROJECT_SLUG>`, `<ANALYZED_PATH>` — from frontmatter
- `<TECH_STACK_LIST>`, `<LOC>`, `<FILE_COUNT>`, `<LAST_COMMIT>`, `<BRANCH>`, `<COMMIT_COUNT_30D>` — from `discover[]`
- `<ANALYSIS_PATH>` — absolute analysis file path
- `<FOCUS_SPECIFIC_PROMPT>` — the focus-specific paragraph from the template's table

All four brief sections (Project Context, Focus, Output Contract, Out of Scope)
MUST appear verbatim. No shortening.

## Step 3 — Dispatch in parallel

Use the Task tool with multiple invocations in a single turn (one Task call
per agent). This gives each sub-agent its own context window.

Always pass the actual agent name as `subagent_type` — every a1 agent has its
own dedicated definition under `~/.claude/agents/`:

```
Task(subagent_type="a1-reinhard-reviewer", description="security scan",
     prompt="<the full brief>")
Task(subagent_type="a1-alex-architekt", description="architecture review",
     prompt="<the full brief>")
Task(subagent_type="a1-marco-mapper", description="repo structure map",
     prompt="<the full brief>")
```

Do NOT fall back to `general-purpose`. If an agent is not available, surface
that as an error to the user and stop the phase.

## Step 3b — Dispatch the always-on Simplify + Security lanes (read-only)

In the SAME turn as Step 3, also dispatch the two standing lanes. Both are
read-only here: they look at the analyzed tree and return findings, never edits.

### Simplify lane — `code-simplifier` agent

The `code-simplifier` agent (Anthropic plugin `code-simplifier`, installed) is
normally a code-editing agent. In a1-analyze it runs in **report-only mode** — its
edit authority is suppressed by the brief, and it returns findings instead of
diffs:

```
Task(subagent_type="code-simplifier", description="simplify scan (read-only)",
     prompt="<brief below>")
```

Brief (substitute `<ANALYZED_PATH>`, `<TECH_STACK_LIST>` from frontmatter):

> READ-ONLY MODE. Do NOT edit, write, or modify any file. You are running inside
> the read-only a1-analyze pipeline.
> Target tree: `<ANALYZED_PATH>` (stack: `<TECH_STACK_LIST>`).
> Scan for: unnecessary complexity, redundant code, dead abstractions, over-nesting,
> nested ternaries, and clarity problems — per your normal simplification standards.
> For each opportunity, instead of editing, return ONE finding object:
> `{ "severity": "MINOR|MAJOR", "category": "simplification", "location": "<file:line>", "description": "<what is complex and why>", "recommendation": "<the simpler form, described — not applied>" }`
> Output ONLY a JSON array of such finding objects. No prose, no diffs, no edits.

If `code-simplifier` is not installed: record a Notes entry
("simplify lane skipped — code-simplifier agent unavailable") and continue. Never
block the phase on it.

### Security lane — `security-review` skill

Run the built-in `security-review` skill against the analyzed tree. It is designed
for "pending changes on the current branch"; in a1-analyze we point it at the whole
analyzed scope (read-only — it reports, it does not fix):

> Run a security review over `<ANALYZED_PATH>`. Cover the standard vuln classes
> (injection, authz/tenant-isolation, secrets, unsafe deserialization, SSRF,
> dependency risk). Return each issue as a finding object:
> `{ "severity": "BLOCKER|MAJOR|MINOR", "category": "security", "location": "<file:line>", "description": "<the vulnerability>", "recommendation": "<the fix, described — not applied>" }`
> Output ONLY a JSON array. Do not modify any file.

If the analysis `focus` is already `security`, the security lane and the
focus-specific a1-reinhard-reviewer pass overlap — that is fine; Phase 4
(Synthesize) dedups by `location` + `category`, so duplicates collapse.

Both lanes are read-only. If either returns a code edit instead of findings, it is
an Output-Contract violation — reject and re-ask once with "You are read-only in
a1-analyze; return findings only, no edits" (same as Step 4 below).

## Step 4 — Validate each agent's output

Each agent MUST return a JSON array of finding objects. Parse the response:

1. If the response contains a valid JSON array → continue.
2. If empty array `[]` → record agent dispatch but no findings.
3. If non-JSON / wrong shape → re-dispatch ONCE with a stricter brief reminder:
   "Last response was not a valid JSON array. Please retry with ONLY JSON per
   Output-Contract." If second attempt also fails → record the failure in the
   Notes section, skip this agent's findings.

Each finding object must have: `severity`, `category`, `location`, `description`.
`recommendation` is optional. Reject and re-ask if any required field is missing.

## Step 5 — Append findings to the analysis file

For each valid finding from each agent:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs analyze add-finding \
  "<analysis-path>" \
  <SEVERITY> \
  "<category>" \
  "<location>" \
  "<description>" \
  --recommendation "<recommendation if present>"
```

The helper auto-increments the ID (F-001, F-002, ...) and atomically appends to
the frontmatter `findings[]`.

## Step 6 — Record dispatch metadata

After all agents have completed:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs analyze update-status \
  "<analysis-path>" analyzed \
  --phase-data '{
    "agents_dispatched": [
      {"name": "a1-reinhard-reviewer", "focus": "security", "completed_at": "<ISO>"},
      {"name": "a1-alex-architekt", "focus": "architecture", "completed_at": "<ISO>"},
      {"name": "code-simplifier", "focus": "simplification", "completed_at": "<ISO>"},
      {"name": "security-review", "focus": "security", "completed_at": "<ISO>"}
    ]
  }'
```

The two always-on lanes (`code-simplifier`, `security-review`) are recorded here
too, so the audit trail shows they ran on every analysis. If a lane was skipped
(agent/command unavailable), record it with `"completed_at": null` and a matching
Notes entry instead of omitting it silently.

## Step 7 — Summarize for the user

> "Analyze complete. <n> findings from <m> sub-agents:
>  - a1-reinhard-reviewer: <k> findings (security)
>  - a1-alex-architekt: <k> findings (architecture)
>  - code-simplifier: <k> findings (simplification)   ← always-on lane
>  - security-review: <k> findings (security)         ← always-on lane
>  
>  Should I start Phase 4 (Synthesize — dedup, prioritization)?"

If yes: proceed to `04-synthesize.md`.
If no: stop. Status `analyzed` persists.

## Edge cases

- **All agents return empty:** that is a legitimate result (project is clean).
  Set status to `analyzed`; in Phase 4 the synthesis will reflect this
  ("no findings in this focus").
- **One agent timeout / no response:** record the failure, continue with the
  other agents. Don't block the phase on one slow agent.
- **Agent returns code edits instead of findings:** Output-Contract violation.
  Reject, re-ask once with "You are read-only, no code edits."
- **Sub-agent says "I need more context":** provide an explicit sub-path or
  file list in the re-dispatch. If that doesn't help, leave findings empty,
  add a Notes entry.
