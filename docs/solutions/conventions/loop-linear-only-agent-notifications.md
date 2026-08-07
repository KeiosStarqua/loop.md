---
title: "LOOP Agent Notifications Use Linear Comments Only (No Slack)"
date: 2026-08-07
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc notification sections"
  - "Configuring how agents report completion in loop-distributed repos"
  - "Removing Slack from an existing LOOP template that still mentions dual Linear+Slack reporting"
tags: [loop, linear, agent-notifications, slack-removal, cursor-rules]
---

# LOOP Agent Notifications Use Linear Comments Only (No Slack)

## Context

The LOOP template (`LOOP.md` / `LOOP.mdc`) previously told agents to notify on both Linear and Slack during automation steps (for example Generate plan: "báo Linear + Slack đã bắt đầu") and included a long **Thông báo hoàn thành của agent** section with explicit Slack prohibitions ("chỉ qua Linear — không gửi Slack", "Không dùng Slack / draft…").

That duplicated the owner channel, added setup noise for repos that do not use Slack MCP, and made the rule file longer without changing the actual contract: owner visibility lives on the Linear issue thread.

## Guidance

Agent completion and step-start signals in LOOP are **Linear-only**:

1. **Single channel** — meaningful work completion is reported with Linear `save_comment` on the related technical issue (and optionally `save_issue` with `assignee: "me"` when re-assigning to the owner). Do not add Slack send/draft steps to LOOP.
2. **Generate plan automation** — when status → `Todo`, notify **Linear** that planning started; run `ce-plan`; do not change status when done (`LOOP.md:27`).
3. **Comment content** — Vietnamese 100%; short summary of what finished, main result/link, next step if any. Owner display name via placeholder `REPLACE_LINEAR_OWNER_DISPLAY_NAME` is optional in the comment, not a separate Slack mention (`LOOP.md:49`).
4. **Not Cursor chat** — "Không chỉ nhắc trong Cursor chat" remains: the Linear comment is the durable handoff (`LOOP.md:51`).
5. **Sync both files** — any notification change must land in **both** `LOOP.md` and `LOOP.mdc` (body identical; keep `LOOP.mdc` frontmatter). `AGENTS.md` restricts edits to explicit user requests.

## Why This Matters

- **One source of truth** — Linear issue + comments already anchor plan links, PR URLs, and status transitions in the loop diagram. See also [Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue](./loop-attach-pr-url-to-linear-issue.md).
- **Smaller template** — removing Slack instructions and anti-Slack rules keeps distributed `LOOP.mdc` easier to read and less tied to optional integrations.
- **Fewer false failures** — agents following LOOP in repos without Slack configured were blocked or confused by Slack-specific steps.

## When to Apply

- User asks to simplify owner notification in LOOP.
- Auditing loop-distributed repos for stale "Linear + Slack" strings.
- Adding a new automation step that needs owner visibility — default to Linear comment, not a second chat product.

## Examples

**Before (Generate plan step):**

```text
báo Linear + Slack đã bắt đầu; chạy ce-plan …
```

**After:**

```text
báo Linear đã bắt đầu; chạy ce-plan …
```

**Before (completion section):**

```text
thông báo chỉ qua Linear — không gửi Slack
Không dùng Slack / draft / nhắc trong Cursor chat thay cho comment Linear.
```

**After:**

```text
thông báo qua Linear
Không chỉ nhắc trong Cursor chat.
```

## Related

- `LOOP.md` / `LOOP.mdc` — **Thông báo hoàn thành của agent**, Cursor Automations, post-`ce-plan` / post-`ce-work` flows
- `AGENTS.md` — LOOP.md / LOOP.mdc sync rule
- `.projectmem/summary.md` — decision logged 2026-08-07 (Linear-only notification)
