# Phase 4 — Submit

Goal: open the actual Pull Request via `gh pr create`. Update registry
to `pr-open`. This phase is terminal.

## Pre-flight

User must have confirmed in Phase 3. If unclear, ask again:
> "Sicher, dass ich den PR jetzt erstelle? (ja / nein)"

### 4.1 Check `gh` auth

```bash
gh auth status
```

If not authenticated: tell user in German to run `gh auth login`, abort.

### 4.2 Push branch (if needed)

```bash
git -C "<worktree_path>" push -u origin "<branch>"
```

If push fails (e.g. branch already pushed, non-fast-forward): show the
git error, ask the user before retrying with `--force-with-lease`.
Never force-push to `main`.

### 4.3 Read draft

Read `<worktree>/.a1-review/pr-draft.md`. Split into TITLE and body.

### 4.4 Create PR

```bash
cd "<worktree_path>" && gh pr create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body>
EOF
)"
```

Capture the returned PR URL.

### 4.5 Update registry

```bash
node ~/.claude/skills/_shared/a1-tools.cjs pr mark-pr-open <id> "<pr-url>"
```

This sets `status: pr-open` and appends to `phase_history`.

### 4.6 Report (German)

```
PR ist offen: <pr-url>

Inline-Kommentare aus MINOR-Findings (optional manuell posten):
<worktree>/.a1-review/inline-comments.md  (X Einträge)

a1-pr-review ist fertig. Registry steht auf `pr-open`.
```

## Failure modes

- `gh pr create` fails (e.g. existing PR for branch): show error, do
  NOT mark registry. Suggest `gh pr view` to inspect.
- Push rejected: do not auto-force. Ask user.
- User aborts at confirm: registry stays `reviewed`. Draft remains on
  disk for later submission.
