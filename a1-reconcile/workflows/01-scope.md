# Phase 01 — Scope

Goal: clarify trigger mode + targets, then create the drift-report file with
`status: scoped`.

## Step 1 — Determine trigger mode

If Robert didn't say it explicitly, ask in German (one question per turn):

> "Welcher Drift-Check?
>  - `single` — eine bestimmte Spec eines Projekts
>  - `project` — alle Specs eines Projekts (Pre-Release-Audit)
>  - `vault-sync` — alle Projekte (wöchentliches Hygiene-Sweep)"

## Step 2 — Resolve targets

| Mode | Required inputs | How to resolve |
|---|---|---|
| `single` | project slug + spec id (`<###>-<slug>`) | Ask if missing; verify spec file exists |
| `project` | project slug | List `projects/<slug>/spec/*.md`, filter `status: clarified` or `status: shipped` |
| `vault-sync` | — | Scan `~/Documents/Obsidian Vault/projects/*/spec/` |

For `single`/`project`, confirm the absolute repo path of the project (where
the code lives). For `vault-sync`, the skill maps each project slug to its
repo via the spec frontmatter `repo_path` if present; otherwise it asks
once per session and caches the answer in `scope_targets[].repo_path`.

If the user can't supply a repo path, skip that target and record it in
`skipped_projects[]` with reason `"no repo_path"`.

## Step 3 — Reserve slot + create the report file

```bash
node ~/.claude/skills/_shared/a1-tools.cjs reconcile next-slot \
  <project-slug-or-_vault-sync> [--date YYYY-MM-DD]
```

Returns the relative path (e.g. `projects/<slug>/drift-2026-05-13.md` or
`projects/<slug>/drift-2026-05-13-2.md`).

Then init the report:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs reconcile init \
  <project-slug-or-_vault-sync> \
  --scope <single|project|vault-sync> \
  [--spec <###-feature-slug>] \
  [--project-path /abs/path/to/repo] \
  [--date YYYY-MM-DD] \
  [--title "Drift Check — <human label>"]
```

The CLI writes the frontmatter (status=`scoped`, scope_mode, scope_targets[],
phase_history with Phase 1 timestamp) and an empty body skeleton.

## Step 4 — Summarize for Robert, in German

> "Drift-Report angelegt: `<path>`
>  Mode: <mode>. <n> Target(s):
>    - <project>/<spec-id>
>    - ...
>  Soll ich Phase 2 (Parse — Acceptance Criteria extrahieren) starten?"

If yes: proceed to `02-parse.md`.
If no: stop. Status `scoped` persists.

## Edge cases

- **Spec not found:** ask Robert to create the spec first (`a1-new-feature`)
  or correct the id. Do not create a drift report yet.
- **Spec status is `draft`:** confirm the user wants to reconcile against an
  unfinished spec. Default: refuse, status must be `clarified` or later.
- **vault-sync finds zero projects with specs:** abort with a message — no
  work to do.
- **Slot collision under high concurrency:** the CLI retries up to 3 times
  with increasing suffix; if still colliding, exit 1 with a clear error.
