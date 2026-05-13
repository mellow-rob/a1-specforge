# Feature Skills — Entry Conditions

**Eine Quelle, kein Ratespiel.** Wenn du ein Feature starten willst, nutze diese Tabelle.

## Entscheidungsbaum

```
Hast du eine Idee für das n3ural-a1-office Produkt (OF-P-NNN)?
├── JA → feature-idea  (Frank: Katalog-Eintrag anlegen)
│         └── Danach → feature-spec  (Rene: User Stories + AC)
│                       └── Danach → a1-new-feature Phase 3+  (ab "clarify")
└── NEIN → a1-new-feature  (Vollpipeline: Idee → Code → Verify)
```

## Skill-Übersicht

| Skill | Scope | Output | Wann nutzen |
|---|---|---|---|
| `feature-idea` | n3ural-a1-office Backlog | OF-P-NNN Katalog-Eintrag (Vault) | Neue Idee ins Backlog aufnehmen |
| `feature-spec` | n3ural-a1-office oder standalone | Spec mit User Stories + AC | Katalog-Eintrag zu testbarer Spec ausbauen |
| `a1-new-feature` | Jedes Projekt | Vollständige Pipe (Spec → Plan → Code → Verify) | Feature komplett von Idee bis Produktion durchziehen |

## Abgrenzungen

- **`feature-idea` ≠ `a1-new-feature`:** `feature-idea` erstellt nur den Backlog-Eintrag. `a1-new-feature` orchestriert den gesamten Build-Prozess.
- **`feature-spec` ≠ Phase 2 von `a1-new-feature`:** `feature-spec` schreibt eine standalone Spec (Vault). `a1-new-feature` Phase 2 ist Teil eines orchestrierten Flows mit Frontmatter-State.
- **Kein Overlap:** n3ural-a1-office-Features gehen durch `feature-idea → feature-spec`, dann bei Bedarf in `a1-new-feature` ab Phase 3 (clarify). Alle anderen Projekte: direkt `a1-new-feature`.

## Trigger-Phrasen (eindeutig)

| Phrase | Skill |
|---|---|
| "neue Feature-Idee", "ins Backlog", "OF-P anlegen" | `feature-idea` |
| "Rene, schreib die Spec", "AC für OF-P-NNN" | `feature-spec` |
| "neues Feature für \<projekt\>", "Feature von Idee bis Verify" | `a1-new-feature` |
| "Bug in \<projekt\>", "X funktioniert nicht" | `a1-fix` |
