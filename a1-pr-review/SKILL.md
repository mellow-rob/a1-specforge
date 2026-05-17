---
name: a1-pr-review
description: >
  End-of-lifecycle skill that turns a finished feature branch into a
  reviewed Pull Request. Picks up worktrees in `status: handoff` from the
  a1-worktree registry (`~/.a1-worktrees-registry.json`), spawns the
  `a1-reinhard-reviewer` sub-agent for a structured code review, prepares a PR-Draft
  (title + body following conventional commits + a1-reinhard-reviewer findings) and,
  after user confirmation, opens the PR via `gh pr create`. Four phases:
  Detect (scan registry) → Review (a1-reinhard-reviewer, findings as JSON) → Draft
  (build PR title + body) → Submit (gh + registry update). BLOCKER
  findings halt the flow before submit; MAJOR findings are surfaced in
  the PR body under "Known Issues"; MINOR findings stay internal as
  inline review comment suggestions. MUST trigger when the user says:
  "pr review für <slug>", "a1-pr-review", "review meinen worktree", "pr
  draften", "a1-reinhard-reviewer auf <slug> ansetzen", "feature ist fertig, PR
  aufmachen", "worktree zur review", "code review + PR", or any request
  to wrap up a handoff-state worktree into a Pull Request. Distinct from
  `a1-worktree` (manages the working copy lifecycle) and `a1-check` /
  `a1-checklist` (pre-implementation gates). This skill runs strictly
  AFTER implementation, on a branch that already contains commits. Do
  not activate for: raw `gh pr create` requests without review, generic
  code-review-only tasks (call `a1-reinhard-reviewer` directly), worktrees still in
  `active` status (must exit to `handoff` first via a1-worktree).
allowed-tools:
  - Read
  - Bash
  - Task
---

# a1-pr-review — Handoff to Pull Request

This skill is a thin orchestrator. The lifecycle logic lives in
`workflows/`. The shared CLI helper
(`~/.claude/skills/_shared/a1-tools.cjs pr`) handles registry scans,
findings serialization, and status updates. The `gh` CLI is invoked
directly from the workflows — there is no wrapper.

## When to use

Activate when a worktree exits in mode `handoff` (registry status
`handoff`). Typical chain:

```
a1-new-feature → a1-worktree (enter/exit handoff) → a1-pr-review
```

## When NOT to use

- Worktrees still `active` — must exit to `handoff` via a1-worktree first.
- Generic code-review without PR intent — call `a1-reinhard-reviewer` directly.
- Hot-fix branches that already have an open PR.
- Re-runs after `pr-open` — registry status is terminal for this skill.

## Phases

| # | Phase | Workflow | Status after |
|---|---|---|---|
| 1 | Detect | `workflows/01-detect.md` | in-review |
| 2 | Review | `workflows/02-review.md` | reviewed |
| 3 | Draft | `workflows/03-draft.md` | draft-ready |
| 4 | Submit | `workflows/04-submit.md` | pr-open |

## Routing — pick the right phase

1. If the user names a slug and no `.a1-review/findings.json` exists in
   the worktree → Phase 1 (Detect).
2. If `findings.json` exists but no `pr-draft.md` → Phase 3 (Draft) — or
   re-run Phase 2 if the user explicitly asks for re-review.
3. If `pr-draft.md` exists and registry is still `reviewed` →
   Phase 4 (Submit).
4. If the user asks "was steht zur Review?" → call
   `a1-tools pr list-handoff` directly, no phase needed.

## State mechanics

State is split across two locations:

| What | Where |
|---|---|
| Worktree status (`handoff` → `in-review` → `reviewed` → `pr-open`) | `~/.a1-worktrees-registry.json` |
| Review findings (BLOCKER / MAJOR / MINOR arrays) | `<worktree>/.a1-review/findings.json` |
| PR draft (title + body markdown) | `<worktree>/.a1-review/pr-draft.md` |

Update via CLI only — never write the registry directly:

```bash
node ~/.claude/skills/_shared/a1-tools.cjs pr list-handoff
node ~/.claude/skills/_shared/a1-tools.cjs pr findings-summary <slug>
node ~/.claude/skills/_shared/a1-tools.cjs pr mark-pr-open <slug> <pr-url>
```

## Agent integration

Phase 2 spawns the global `a1-reinhard-reviewer` agent via the `Task` tool. The
brief is structured (worktree path, branch, diff range, scope hint from
the last `phase_history` entry). Reinhard returns findings as inline
JSON which the workflow then writes to `findings.json` via the CLI.

## Hard rules

- BLOCKER findings halt the flow before Phase 4. The user must confirm
  explicitly to proceed despite blockers.
- MAJOR findings are listed in the PR body under "Known Issues".
- MINOR findings are not in the PR body — they go into a separate
  `inline-comments.md` for optional manual posting.
- Never invoke `git push` or `gh pr create` without explicit user
  confirmation in Phase 4.
- Never write `~/.a1-worktrees-registry.json` directly. CLI only.
- User-facing prompts are in **German**. CLI output (JSON, log lines)
  and file contents (PR body, findings) stay in **English**.

## Hand-offs

- After `pr-open`: terminal. Registry stays at `pr-open` until the user
  merges or closes the PR manually (no further skill in this chain).
- BLOCKER halt → user fixes in worktree, then re-runs Phase 2 (review).
