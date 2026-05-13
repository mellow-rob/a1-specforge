# Run Check — Consistency Gate (manual invocation)

**Goal:** Run the deterministic spec ↔ wave-plan consistency check for one
feature and present the result to the user with a concrete fix-path
suggestion when needed.

**Sub-agent:** none. All logic is in the CLI.

## Step 1 — Collect inputs

You need two values:

- `<project-slug>` — the Obsidian Vault project folder name
- `<feature>` — the feature id in the form `<###>-<feature-slug>` (e.g. `001-login`)

If the user did not provide both, ask **one** German question for the missing one.
Do not ask both at once. Example:

> "Für welches Projekt soll ich den Konsistenz-Check laufen lassen?"

Do not infer the feature id from filesystem listings unless the user
explicitly asks you to list features. The check is cheap; ambiguity is the
real cost.

## Step 2 — Run the gate

Use the **Bash** tool to call the CLI in human-format mode:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs check <project-slug> \
  --feature <feature> --format human
```

Capture both stdout and the exit code. Stdout already contains the German
report; the exit code drives what comes next.

## Step 3 — Branch on exit code

### Exit 0 — PASS

Show the user the German stdout verbatim, then:

> "Spec und Wave-Plan sind konsistent. Du kannst Phase 5 (Implement) starten."

Stop. No further action.

### Exit 1 — FAIL (content inconsistency)

Show the user the German stdout verbatim. Then re-run the CLI with
`--format json` to read the structured diff:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs check <project-slug> \
  --feature <feature> --format json
```

Parse the JSON. Pick the fix-path suggestion from the table below based on
which diff fields are non-empty (multiple may apply — list all that match).

| Diff field | Suggestion (German) |
|---|---|
| `diffs.missing_in_plan` not empty | "Es fehlen FRs in den Waves. Soll ich `a1-new-feature` Phase 4 (Plan) erneut starten, damit Vincente den Wave-Plan überarbeitet?" |
| `diffs.duplicated_in_plan` not empty | "Eine oder mehrere FRs sind in mehreren Waves. Soll ich `a1-new-feature` Phase 4 starten, damit Vincente die Wave-Zuordnung korrigiert?" |
| `diffs.phantom_in_plan` not empty | "Der Wave-Plan referenziert FR-IDs, die in der Spec nicht existieren. Möchtest du Phase 3 (Clarify) erneut starten, um die fehlenden FRs in der Spec zu ergänzen — oder direkt im Plan die Phantome streichen?" |
| `checks.frontmatter_link == "FAIL"` | "Das Plan-Frontmatter zeigt auf eine falsche Spec. Soll ich den `spec_path` im Plan-Frontmatter direkt korrigieren?" |

If the user says **yes** to a suggestion: invoke the named action (e.g.
trigger `a1-new-feature` for the same project/feature; it will route into the
right phase based on spec status). If the user says **no** or wants to fix it
themselves, stop and let them work.

### Exit 2 — ERROR (setup)

Show the user the German stdout verbatim. Then:

> "Das Gate konnte den Check nicht ausführen, weil die Artifacts unvollständig
> sind. Bitte fehlende Datei anlegen oder Frontmatter reparieren. Danach
> einfach erneut aufrufen."

Stop. Do not propose `a1-new-feature` re-entry — the problem is below that level.

## Hard rules for this workflow

- Never edit any file from this workflow. The gate is read-only.
- Always pass `--format human` first for user display, then re-run with
  `--format json` only when you need to drive the fix-path suggestion.
- Never combine multiple gate invocations in one command line. One project +
  one feature per run.
- If the user provided a `--vault <path>` override (or the env var
  `A1_VAULT_ROOT` is set), forward it; otherwise the CLI defaults to
  `~/Documents/Obsidian Vault`.

## When this workflow ends

- After PASS confirmation, or
- After FAIL with the user's decision on whether to re-enter `a1-new-feature`, or
- After ERROR with the user acknowledging the setup issue.

The skill does not maintain state between invocations.
