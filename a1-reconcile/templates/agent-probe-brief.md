# Sub-Agent Probe Brief (Phase 3 — Probe)

Used by `workflows/03-probe.md` to construct a focused brief per (repo ×
agent) dispatch. All four sections below MUST appear verbatim.

```
Du bist <AGENT_NAME>. Aufgabe: Spec-vs-Code Drift-Probe.

## Project Context

- Projekt-Slug: <PROJECT_SLUG>
- Lokaler Repo-Pfad: <REPO_PATH>

Drift-Report (NICHT editieren, nur Referenz):
<DRIFT_REPORT_PATH>

## Probe Task

Für jeden der folgenden Spec-Anker prüfe deterministisch im Code:
- existiert das Artefakt am referenzierten Ort?
- existiert es woanders im Repo (DIVERGED-Hinweis)?
- existiert es gar nicht (MISSING)?
- gibt es zugehörigen Code, der NICHT im Spec-Anker auftaucht (EXTRA — nur
  melden, wenn klar dieser Feature zugehörig)?

Anker-Liste:
<SPEC_SUMMARY_BLOCK>

Vorgehen:
1. Für jeden Anker: gezielte Suche (Grep / Glob) im REPO_PATH.
2. Wenn `kind=file`: prüfe Existenz der Datei. Wenn nicht da: MISSING.
3. Wenn `kind=function`: Grep nach Funktions-/Klassennamen.
4. Wenn `kind=endpoint`: Grep nach Route-Definition (z.B. `app.post('/api/login'`).
5. Wenn `kind=other`: heuristische Keyword-Suche aus dem FR-Text.
6. Nach den gezielten Suchen: ein schneller breiter Scan auf EXTRA-Kandidaten
   (Funktionen/Endpoints im Feature-Bereich, die in keinem Anker vorkommen).

## Output Contract (HARD)

Liefere AUSSCHLIESSLICH eine JSON-Liste. Pro Eintrag:

```json
{
  "class": "MISSING" | "EXTRA" | "DIVERGED" | "STALE" | "IN_SYNC",
  "artifact": "short label",
  "spec_ref": "FR-### or empty",
  "code_ref": "path:line or empty",
  "description": "factual, 1-3 sentences",
  "recommendation": "actionable next step or empty"
}
```

Klassen-Definitionen:
- MISSING: Spec fordert es, im Code nicht auffindbar.
- EXTRA: Code-Artefakt existiert (feature-relevant), Spec referenziert es nicht.
- DIVERGED: Existiert in beidem, aber Pfad/Signatur/Struktur weicht ab.
- STALE: nutze NUR, wenn du explizit Hinweise auf veralteten Code-Stand
  findest (z.B. TODO-Marker, "deprecated", auskommentierte Implementation,
  die der Spec entsprechen würde). Sonst nicht setzen — Phase 3 macht
  STALE-Reklassifikation aus Pre-Filter.
- IN_SYNC: bestätigte Übereinstimmung. EIN Eintrag pro geprüftem Anker reicht.

Free-Prosa wird abgelehnt. Wenn du nichts findest: `[]`.

## Out of Scope

- KEINE Code-Änderungen. Du bist read-only.
- KEIN Test-Run, KEIN Build, KEIN Deploy.
- KEINE Files in REPO_PATH modifizieren.
- KEINE Drift-Report-Files anlegen oder editieren.
- KEINE Spec-Edits.
- KEINE Aussagen über semantische Korrektheit — nur strukturelle Präsenz/Form.
- KEINE Diskussion alternativer Architekturen.
```

## Dispatch checklist (workflow uses this)

- [ ] All four brief sections present
- [ ] Project Context filled from frontmatter
- [ ] Spec Summary Block contains every `parsed_targets[]` entry for this repo
- [ ] Output Contract verbatim, no shortening
- [ ] Out of Scope verbatim, no shortening
- [ ] Agent name set
- [ ] Drift report path passed (read-only reference)
