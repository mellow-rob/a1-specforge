# Phase 04 — Write

Goal: deterministic, atomic deployment of the reviewed constitution. No LLM
in this phase — pure CLI sequence + final user-facing summary.

## Preconditions

- Vault file exists with `status: reviewed`.
- `CONST_PATH` is set.
- `REPO_ROOT` is set (from Phase 1 payload, or re-ask Robert if missing).

If status ≠ `reviewed`: route to the matching phase.

## Step 1 — Archive current repo file (if any)

Check if `<repo-root>/constitution.md` already exists. If yes, the version in
the vault is already considered the next version (because Phase 1 Step 3
ran `archive-current` on the previous vault file before re-init). So no
additional archiving needed here.

But if this is a **re-write of an existing vault constitution** (rare: user
went `written` → fresh Phase 4 without re-init), we still need to ensure the
history is consistent. We rely on Phase 1's archiving logic — Phase 4 itself
does NOT archive. It only writes.

(Reasoning: archiving on init is correct because we want to snapshot the
"last known good" before discovery starts. Archiving in Phase 4 would
snapshot the current draft, which is not what audit-history is for.)

## Step 2 — Write the repo mirror

```bash
node ~/.claude/skills/_shared/a1-tools.cjs constitution write-mirror \
  <project-slug> \
  --repo-root "<REPO_ROOT>"
```

Parse JSON. Capture `mirror_path` and `bytes`.

## Step 3 — Ensure CLAUDE.md cross-link

```bash
node ~/.claude/skills/_shared/a1-tools.cjs constitution link-claudemd \
  <project-slug> \
  --repo-root "<REPO_ROOT>"
```

Parse JSON. Capture `action` (`appended` or `updated`).

If the CLI fails with "CLAUDE.md not found": surface auf Deutsch and stop
WITHOUT setting status to `written`. The vault constitution remains at
`reviewed` so Robert can fix CLAUDE.md and re-run Phase 4.

## Step 4 — Transition status to `written`

```bash
node ~/.claude/skills/_shared/a1-tools.cjs constitution update-status \
  "<CONST_PATH>" written
```

This appends `phase=write completed=<iso>` to `phase_history` and sets
`last_written_at` to the current ISO timestamp.

## Step 5 — Final report (German, structured)

Tell Robert auf Deutsch:

```
Constitution geschrieben.

  Projekt:           <slug>
  Version:           v<N> (aus Vault-Frontmatter)
  Vault-Datei:       projects/<slug>/constitution/constitution.md
  Repo-Spiegel:      <REPO_ROOT>/constitution.md (<bytes> bytes)
  CLAUDE.md-Link:    <action> (appended | updated)

  Phase-Historie:
    - discover: <iso>
    - draft:    <iso>
    - review:   <iso>
    - write:    <iso>

  Single Source of Truth: das Vault-File. Wenn die Repo-Datei mal verändert
  wurde oder verloren geht: einfach `a1-constitution` mit der Bitte um
  Re-Mirror starten — der Vault rebuilt ihn.
```

## Step 6 — Soft hand-off recommendations (no auto-spawn)

Append to the report:

```
Was du jetzt tun kannst (manuell, optional):

  - Commit machen: CLAUDE.md + constitution.md gehören in einen Commit
    ("docs(constitution): add behavioral rules v<N>").
  - Reinhard manuell bitten, einen Compliance-Review auf den jüngsten PR
    zu machen — er ist noch NICHT constitution-aware (M3-Roadmap), aber
    du kannst ihm den Link zur Constitution explizit mitgeben.
  - Wenn andere Projekte (niimo, n3ural-platform) noch keine Constitution
    haben: a1-constitution für diese starten — pro Projekt eine Constitution.
```

## Hard rules

- This phase has zero LLM calls. Pure CLI.
- The order is strict: write-mirror → link-claudemd → update-status. Why:
  if link-claudemd fails (no CLAUDE.md), the mirror is already written but
  status stays at `reviewed` — that is correct, because we have not yet
  declared a successful write. update-status is the commit point.
- If write-mirror fails (e.g. repo-root permission), do NOT call link-claudemd.
  Status stays at `reviewed`.
- Frontmatter changes only via CLI. Body changes are forbidden in Phase 4.
- No automatic git operations. Robert commits manually when he wants.
