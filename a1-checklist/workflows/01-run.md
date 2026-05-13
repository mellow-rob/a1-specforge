# Run Checklist — Pre-Flight Readiness Gate

**Goal:** Run the 8 deterministic readiness checks for a feature's wave-plan
and translate the structured result into a German user-facing report with a
concrete next-step suggestion.

**Sub-agent:** none. All logic is in the CLI.

## Step 1 — Collect input

You need ONE value: a target string in either form:

- `<project-slug>/<feature-id>` — exact, e.g. `niimo/003-login` or `niimo/003`
- `<project-slug>` only — latest spec is auto-resolved

If the user did not provide a target, ask **one** German question:

> "Für welches Feature soll ich die Pre-Flight-Checkliste laufen lassen?
> (Projekt-Slug oder Slug/Feature-ID, z.B. `niimo/003-login`)"

Do not enumerate features from disk unless the user explicitly asks.

## Step 2 — Run the gate

Use the **Bash** tool to call the CLI in human format:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs checklist run <target> --format human
```

Capture stdout AND the exit code. Stdout already contains the German
report; the exit code drives what comes next.

If the user explicitly asked you to save the audit trail, add `--save`:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs checklist run <target> --format human --save
```

If a vault override is needed (`$A1_VAULT_ROOT` not set, or user gave
`--vault <path>`), forward it. Default is `~/Documents/Obsidian Vault`.

## Step 3 — Branch on exit code

### Exit 0 — PASS or PASS_WITH_WARNINGS

Show the user the German stdout verbatim. Then re-run the CLI with
`--format json` to read the structured `status` field:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs checklist run <target> --format json
```

Parse the JSON.

- If `status == "PASS"`:
  > "Alles grün. Der Wave-Plan ist implementierungs-bereit. Möchtest du
  > jetzt mit der Implementation starten?"

- If `status == "PASS_WITH_WARNINGS"`:
  List the failed MAJOR/MINOR checks (from `.checks[]` where
  `result == "FAIL"`), then:
  > "Der Plan ist grundsätzlich implementierungs-bereit, aber es gibt
  > {N} MAJOR und {M} MINOR Hinweise. Soll ich die Punkte vor dem Start
  > adressieren, oder direkt mit der Implementation beginnen?"

### Exit 1 — FAIL (one or more BLOCKER)

Show the user the German stdout verbatim. Re-run with `--format json`,
parse, find the failed BLOCKER checks (`severity == "BLOCKER"` AND
`result == "FAIL"`).

Map each failed BLOCKER to a fix-path suggestion:

| Failed Check | Suggestion (German) |
|---|---|
| `spec_status_clarified` | "Die Spec ist noch nicht im Status `clarified`. Soll ich `rene-requirement-engineer` für die Klärung anstoßen?" |
| `wave_plan_exists` | "Es gibt noch keinen Wave-Plan unter `projects/<slug>/plans/`. Soll ich `vincente-vibe-optimizer` für die Plan-Erstellung anstoßen — oder `a1-new-feature` Phase 4 starten?" |
| `wave_dependencies_dag` | "Die Wave-Abhängigkeiten enthalten einen Zyklus. Das muss manuell aufgelöst werden — möchtest du, dass ich `vincente-vibe-optimizer` für eine Plan-Überarbeitung anstoße?" |

Then stop. Do not auto-trigger the suggested agent — wait for user consent.

### Exit 2 — ERROR (setup)

Show the user the German stdout verbatim. Then:

> "Die Checkliste konnte nicht laufen, weil Artifacts fehlen oder das
> Frontmatter nicht parsebar ist. Bitte die genannten Pfade prüfen und
> reparieren. Danach einfach erneut aufrufen."

Stop. Do not propose any agent re-entry — the problem is below that level.

## Hard rules for this workflow

- Never edit any file from this workflow. The gate is read-only.
- Always pass `--format human` first for user display, then re-run with
  `--format json` only when you need the structured fields to drive the
  follow-up question.
- Never combine multiple gate invocations in one command line. One target
  per run.
- If the user provided a `--vault <path>` override (or `$A1_VAULT_ROOT`
  is set), forward it.

## When this workflow ends

- After PASS confirmation and user decision on implementation start, or
- After FAIL with the user's decision on whether to invoke a fix-path
  agent, or
- After ERROR with the user acknowledging the setup issue.

The skill does not maintain state between invocations.
