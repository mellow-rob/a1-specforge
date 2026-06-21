# a1-plan — Learning Log

Entries appended automatically by Phase 4 (Audit) after every run.
Used by a1-evolve for pattern clustering (threshold: 3+ same tag = proposal).

Tags: missing_acceptance_criteria | vague_tasks | no_success_criteria | wave_too_large | missing_dependency | unverifiable_goal | spec_omission

Canonical source: `~/N3URAL-Vault/pattern/a1-learnings/a1-plan.md`. This file is a fast-access cache.

---

---
date: 2026-05-10
task: Plan Spec 001 (Expense Document Preview) mit 6 Waves
project: n3ural-platform
result: partial
audit_findings: [missing_acceptance_criteria, vague_tasks, spec_omission]
what_worked: Full FR/US coverage bis Phase 4 — Wave Plan war strukturell solid
one_line_learning: Edit-Modus (BUG-08) wurde nicht im Initial-Spec geplant; explizite "is this CRUD complete?" Frage in Clarify hätte es gefangen
---

---
date: 2026-05-11
task: Plan Spec 003 (Reports Period Navigation) mit Header-Stepper + 5 KPI-Datenquellen
project: n3ural-platform
result: partial
audit_findings: [missing_acceptance_criteria, spec_omission]
what_worked: URL-State-Persistence im Plan explizit verankert; Periode-Filter-Architektur korrekt
one_line_learning: Multi-Query HTTP-Self-Calls nicht als Architektur-Risiko erkannt — Wave-Brief muss Query-Isolation-Pattern für Promise.all verpflichtend fordern
---

---
date: 2026-05-17
task: Plan Niimo Spec 001 (consolidate-ai-extraction-pipeline) mit 6 Waves
project: niimo
result: pass
audit_findings: []
what_worked: 7 FRs bijektiv auf 6 Waves mapped; Consistency Gate Phase 4.5 PASS; Compliance-Tests als explizite Wave eingeplant
one_line_learning: Refactoring-Voraussetzungen (Quality-Audit-Findings) hätten vor Planning stattfinden sollen — Plan baute auf unsauberem Ist-Stand auf
---
---
date: 2026-05-29
phase: ofp046-markdown-brain-railway
project: a1-office
spec: /Users/rob/.claude/plans/rolle-du-bist-senior-giggly-backus.md
result: pass
revisions: 0
audit_findings: 0
finding_classes: [vague_tasks, missing_dependency]
phase_that_produced_issues: [plan]
one_line_learning: Planner-Live-Check der installierten Tool-Config (basic-memory Default-Embedding = bge-small-en-v1.5, englisch-only) deckte einen ziel-kritischen Task auf, den alle Eingabe-Docs uebersahen — Tool-Defaults immer gegen das Ziel verifizieren, nie annehmen.
---
date: 2026-06-04
phase: crm-read-path-consolidation
project: n3ural-platform
spec: none
result: pass-after-revision
revisions: 1
audit_findings: 3
finding_classes: [missing_dependency, unverifiable_goal]
phase_that_produced_issues: [plan]
one_line_learning: Bei Tenant-kritischen Migrationen muss der Äquivalenz-Beweis (Wave 0) verschachtelte Embed-Child-Isolation + Pool-Rollen-Kontamination explizit als testbare STOP-Gates enthalten, nicht nur Top-Level-Row-Isolation.
