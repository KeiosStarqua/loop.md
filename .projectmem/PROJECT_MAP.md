# Project Map - my-loop-config

## Project purpose

Portable Loop Engineering template and Cursor Automations samples for Linear-driven feature delivery: `LOOP.md` / `LOOP.mdc` sync into target repos; this config repo also holds `AUTOMATIONS.md` and `automations/*.json`.

## Structure

- `LOOP.md` — portable loop specification (body synced with `LOOP.mdc`)
- `LOOP.mdc` — same body + `alwaysApply: true` Cursor rule frontmatter
- `AGENTS.md` — DOX rail + LOOP sync / auto-merge / Serial Plan preferences
- `AUTOMATIONS.md` — operator docs for Generate plan / Implement / Compound
- `CONCEPTS.md` — domain vocabulary (LOOP, Serial Plan, automations)
- `README.md` — install / sync-loop usage
- `automations/`
  - `automations/generate-plan.json` — Plan trigger prompt sample
  - `automations/implement.json` — In Progress trigger prompt sample
  - `automations/compound.json` — Compound trigger prompt sample
- `docs/solutions/` — durable learnings (conventions, tooling, DX)
- `scripts/`
  - `scripts/sync-loop.sh` — copy rendered LOOP.mdc into a target repo
  - `scripts/sync-loop-remote.sh` — remote wrapper fetching script + template
- `loop.env.example` — REPLACE_LINEAR_* template for target repos
- `.projectmem/` — project memory (summary derived; map authored here)

## Relationships

- `LOOP.md` body must match `LOOP.mdc` (except frontmatter); `scripts/sync-loop.sh` reads `LOOP.mdc`
- `AUTOMATIONS.md` and `automations/*.json` describe the same three Linear status automations as LOOP
- `docs/solutions/conventions/*` capture LOOP contract learnings applied when editing LOOP/AUTOMATIONS
- Target repos get `.cursor/rules/LOOP.mdc` via sync; they do not receive `AUTOMATIONS.md`
