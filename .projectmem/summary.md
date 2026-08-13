# projectmem - my-loop-config

_Last updated: 2026-08-12_

## Project purpose
Replace this placeholder with a concise description of what this project does, who it serves, and the main technologies or runtime assumptions.

## Recent issues
- No issues logged yet.

## Decisions
- Không đề cập AUTOMATIONS.md trong LOOP.md / LOOP.mdc — các file này được copy vào từng repo và LOOP.mdc thành Cursor rule; chi tiết automation chỉ giữ ở AUTOMATIONS.md trong repo config.
- Thông báo hoàn thành agent chỉ qua Linear comment (save_comment) — bỏ gửi message Slack khỏi LOOP.md/LOOP.mdc [LOOP.md]
- Linear automation triggers: Todo → Plan, Done → Compound. In Progress / In Review unchanged. Đóng vòng sau review chuyển sang Compound (không còn Done) để kích hoạt ce-compound. [LOOP.md]

## Notes
- feat: add remote sync-loop runner from GitHub raw URL
- docs: add curl one-liners for sync-loop-remote.sh
- docs: explain why sync-loop must use sync-loop-remote wrapper
- docs: generalize loop templates and remove KT System references
- feat: add --setup one-shot mode to sync-loop.sh
- High churn detected: docs/solutions/developer-experience/sync-loop-auto-init-missing-env.md (4 edits in 10 min) [docs/solutions/developer-experience/sync-loop-auto-init-missing-env.md]
- Merge: Merge pull request #1 from KeiosStarqua/cursor/add-compound-automation-fe8d
- LOOP.md và LOOP.mdc phải đồng bộ nội dung; không cross-ref file chỉ tồn tại trong my-loop-config (như AUTOMATIONS.md).
- LOOP Generate plan: báo bắt đầu chỉ trên Linear (không còn Linear + Slack) [LOOP.md]
- New feature: feat(automations): attach PR URL in generate-plan automation prompt [automations/generate-plan.json]

## Key files
- `README.md`
- `AGENTS.md`
- `LOOP.md`
- `LOOP.mdc`
- `AUTOMATIONS.md`
- `automations/kt-system-generate-plan.json`
- `automations/kt-system-implement.json`
- `loop.env.example`
- `scripts/sync-loop.sh`
- `scripts/sync-loop-remote.sh`
- `sync-loop-remote.sh`
- `docs/solutions/tooling-decisions/sync-loop-remote-wrapper-required.md`
- `automations/generate-plan.json`
- `automations/implement.json`
- `sync-loop.sh`
- `loop.env`
- `docs/solutions/developer-experience/sync-loop-auto-init-missing-env.md`
- `LOOP.md/LOOP.mdc`

## Open questions
- None logged yet.
