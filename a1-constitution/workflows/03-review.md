# Phase 03 — Review

Goal: present Finn's draft to Robert, capture any change requests, apply them
deterministically, and transition status to `reviewed`. No sub-agent in this
phase — direct dialogue + targeted edits only.

## Preconditions

- Vault file exists with `status: drafted`.
- `CONST_PATH` is set (or recompute from project slug:
  `<vault-root>/projects/<slug>/constitution/constitution.md`).

If status ≠ `drafted`, route to the matching phase based on the routing table
in `SKILL.md`.

## Step 1 — Present the draft

Read the constitution body (skip frontmatter):
```bash
# Use Read tool on CONST_PATH, then display body to Robert.
```

Show Robert auf Deutsch a structured preview:
> "Hier ist der Draft. Bitte einmal komplett lesen:
>
>  ---
>  <full body>
>  ---
>
>  Drei mögliche Reaktionen:
>  1) Passt so → ich gehe weiter zu Phase 4 (Write).
>  2) Kleine Änderungen → sag mir konkret was wo geändert werden soll.
>  3) Größere Umarbeitung → ich schicke Finn zurück mit deinen Anmerkungen
>     als neuen Brief (Re-Draft)."

## Step 2 — Capture decision

Wait for Robert. Branch:

### 2a — "Passt"

Proceed to Step 4.

### 2b — Small edits

Robert nennt konkrete Änderungen (z.B. "Regel 3 muss strenger formuliert sein"
oder "Override-Precedence-Tabelle: füge Beispiel für jede Layer hinzu").

For each change:
- Read the current body.
- Apply the change with the `Edit` tool **on the vault file directly**.
  Note: this is the ONE phase where direct body edits are allowed because
  they are minor, user-driven, and traceable (we'll show the diff before
  transitioning). Frontmatter is never touched by Edit — only via CLI.

After all edits applied: re-show the changed sections to Robert auf Deutsch
für eine kurze Bestätigung ("So jetzt?"). If he says yes, proceed to Step 4.
If he wants more changes, loop within Step 2b.

### 2c — Re-draft

If Robert wants a significant rework, write a new tmp file with his feedback:

```json
{
  "previous_body_path": "<CONST_PATH>",
  "robert_feedback": "<verbatim>",
  "specific_concerns": ["..."]
}
```

Construct a follow-up brief and re-dispatch Finn with subagent_type
`finn-cc-architect`, including the previous body and Robert's feedback.
Finn returns a revised body. Write it back via `constitution set-body`,
status STAYS at `drafted`, and we loop back to Step 1 (Robert reviews
the new draft).

Max 2 re-draft cycles before escalating to Robert auf Deutsch:
> "Wir sind beim 3. Draft. Möchtest du selbst übernehmen und die Constitution
>  direkt im Vault-File editieren? Ich kann den Pfad öffnen."

## Step 3 — User cancellation

Anytime Robert says "abbrechen":
```bash
node ~/.claude/skills/_shared/a1-tools.cjs constitution update-status \
  "<CONST_PATH>" cancelled
```
Tell Robert auf Deutsch was passiert ist und stop.

## Step 4 — Transition status to `reviewed`

```bash
node ~/.claude/skills/_shared/a1-tools.cjs constitution update-status \
  "<CONST_PATH>" reviewed
```

This appends `phase=review completed=<iso>` to `phase_history`.

## Step 5 — Route to Phase 4

Tell Robert **in German**:
> "Review abgeschlossen. Status: `reviewed`. Soll ich Phase 4 (Write) starten?
>  Das macht: (a) History-Snapshot wenn nötig, (b) Repo-Spiegel nach
>  `<repo-root>/constitution.md`, (c) Cross-Link in CLAUDE.md ergänzen,
>  (d) Status auf `written` setzen."

If yes: proceed to `04-write.md`.

## Hard rules

- Edit-tool may modify the **body** but never the YAML frontmatter.
- After every Edit-tool change, re-read the file before the next Edit to keep
  the in-memory view consistent.
- Re-draft loop max 2 iterations. Beyond that, hand control to Robert.
