---
name: a1-check
description: >
  Cross-artifact consistency gate between a feature's spec and its wave-plan.
  Verifies three structural invariants (deterministic, no LLM): (1) the wave-plan
  frontmatter spec_path resolves to the expected spec, (2) every FR-### from the spec
  appears in exactly one Wave, (3) no FR-### in the plan is absent from the spec.
  Primary caller is a1-new-feature's Phase 4.5 gate between Plan and Implement, but
  this skill can also be invoked manually. Exit semantics: 0=PASS, 1=FAIL (content
  inconsistency), 2=ERROR (missing file / bad frontmatter). MUST trigger when the user
  says: "konsistenz-check für <feature>", "check consistency between spec and plan",
  "a1-check", "prüfe ob plan zur spec passt", "verify wave plan", or asks to validate
  that a wave-plan covers all spec FRs. Do not activate for: bug consistency
  (a1-fix has its own model), generic project audits (a1-analyze), or semantic spec
  review (delegate to Rene). This gate is structural, not semantic.
allowed-tools:
  - Bash
  - Read
---

# a1-check — Spec ↔ Wave-Plan Consistency Gate

Thin Markdown wrapper around the deterministic CLI gate. All logic lives in
`~/.claude/skills/_shared/a1-tools.cjs check`. The workflow file translates a FAIL
result into a concrete fix-path suggestion for the user.

## When to use

Activate when the user wants a structural check between an existing spec and its
wave-plan. Both files must already exist on disk under the Obsidian Vault paths.

- Manual invocation: user names the project slug and the feature id.
- Programmatic invocation by `a1-new-feature` Phase 4.5: that workflow shells out to
  the CLI directly with `--format json`; this skill is **not** routed through.

## Storage (vault layout)

| Artifact | Path |
|---|---|
| Spec | `projects/<project-slug>/spec/<###>-<feature-slug>.md` |
| Wave-Plan | `projects/<project-slug>/plans/<###>-<feature-slug>-wave-plan.md` |

`<###>` is a zero-padded sequence assigned by `a1-new-feature`. The plan's YAML
frontmatter must contain `spec_path:` pointing back at the spec.

## CLI contract

```bash
node ~/.claude/skills/_shared/a1-tools.cjs check <project-slug> \
  --feature <###-feature-slug> \
  [--format json|human] \
  [--vault <abs-path>]
```

Exit codes:

| Code | Meaning |
|---|---|
| 0 | PASS — spec and wave-plan are consistent |
| 1 | FAIL — content inconsistency (diff in output) |
| 2 | ERROR — setup problem (file missing, frontmatter unparseable) |

Vault root resolution: env var `A1_VAULT_ROOT`, falling back to
`~/Documents/Obsidian Vault`. Override per-call via `--vault`.

## Three check classes (all structural)

| Class | What it asserts | FAIL trigger |
|---|---|---|
| `frontmatter_link` | Plan's `spec_path` resolves to the expected spec | spec_path empty, wrong filename, or pointing elsewhere |
| `fr_coverage` | Every spec FR-### appears in exactly one Wave heading section | missing FR or FR present in two waves |
| `fr_phantoms` | Every plan FR-### exists in the spec | plan references an FR-### the spec does not define |

## Phases

| # | Phase | What happens |
|---|---|---|
| 1 | Run | Invoke the CLI with `--format human`, capture exit code and stdout |
| 1 | Report | If PASS: short confirmation. If FAIL/ERROR: show output + propose fix path |

Phases are CLI-internal (Load → Compare → Report) — the skill itself has a single
workflow file because the heavy lifting belongs in the CLI.

## Workflow

See `workflows/01-run-check.md`.

## Hard rules

- Never edit spec or wave-plan files from this skill. The gate is read-only.
- Never invoke an LLM sub-agent for the consistency check itself — the CLI is
  authoritative.
- User-facing output (PASS/FAIL summary, fix-path suggestion) is in **German**.
  The CLI's `--format human` already produces German; pass it through verbatim and
  add only the fix-path suggestion on top.
- Do not auto-trigger other skills after a FAIL. Always ask the user before
  invoking `a1-new-feature` to re-enter a phase.

## Hand-offs

- On FAIL with missing FRs in waves → suggest re-running `a1-new-feature` Phase 4 (Plan).
- On FAIL with phantom FRs → suggest re-running `a1-new-feature` Phase 3 (Spec/Clarify)
  to add the FRs, or editing the wave-plan to drop the phantoms.
- On FAIL with frontmatter-link mismatch → suggest a targeted edit of the plan's
  YAML frontmatter (`spec_path`).
- On ERROR (setup) → ask the user to create the missing file or repair the
  frontmatter, then re-run.
