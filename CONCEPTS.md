# Concepts

> Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound and ce-compound-refresh process learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## LOOP distribution

### LOOP
The portable Loop Engineering specification (`LOOP.md` / `LOOP.mdc`) that defines the feature-delivery loop, agent notification contract, and Cursor Automation hooks. Synced into each target repository as a Cursor rule; body content must stay identical across both source files.

### loop.env
Per-target-repository configuration holding the five Linear metadata values (owner, workspace, project name, URL, id) that replace `REPLACE_LINEAR_*` placeholders during sync. Created from the example template on first sync; never overwritten without an explicit force path.

### sync-loop
The install toolchain that copies a rendered `LOOP.mdc` into a target repo's `.cursor/rules/` using values from that repo's `loop.env`. Remote installs use a wrapper that stages the script beside its template siblings before execution.

## Automation

### Cursor Automations
The three Linear status-triggered automation steps defined in LOOP: **Generate plan** (`Plan` → `ce-plan` → auto-merge plan PR → auto **In Progress**), **Implement** (`In Progress` → `ce-work` → auto-merge work PR → auto **Compound**), and **Compound** (`Compound` → `ce-compound` → auto-merge if any → auto **Done**). Happy path does not stop at **In Review** and does not wait for the owner to click status by hand. Owner visibility during these steps is Linear-only. Any step that creates a pull or merge request must attach that URL to the related Linear issue immediately.

### Serial Plan
An outside routine or agent that moves Linear issues to **Plan** one at a time: start one issue → Plan, wait until that issue reaches **Done**, then move the next issue to Plan. Do not send many issues to Plan at once.
