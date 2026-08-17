# Cursor Automations (loop mẫu)

Ba automation tách **lập kế hoạch**, **triển khai** và **đúc kết (compound)**. Gắn Linear team/project và git repo của **repo đích** (điền khi tạo automation). Tools: Linear MCP (+ Slack MCP cho hai automation đầu). Memory bật; scope private.

Cursor Automations trên tài khoản Keios **đã được cấu hình** — tài liệu này mô tả hợp đồng hành vi trong repo; **không** tạo/sửa automation trong Cursor UI từ task docs.

**JSON tham chiếu** (export mẫu — chỉnh team/project/repo trước khi import vào workspace khác):

| Automation | File |
|------------|------|
| Generate plan | [`automations/generate-plan.json`](./automations/generate-plan.json) |
| Implement | [`automations/implement.json`](./automations/implement.json) |
| Compound | [`automations/compound.json`](./automations/compound.json) |

```text
Serial Plan (routine ngoài): một issue → Plan; chờ Done rồi mới Plan issue tiếp
    ↓
Linear status → Plan
    ↓  Automation: Generate plan  (model: cursor-grok-4.5-high)
ce-plan → plan dưới docs/plans/ + auto-merge PR plan + tự đổi status → In Progress
    ↓  Automation: Implement  (model: composer-2.5)
kiểm tra PR plan đã merge (chưa → stop & Todo [fallback]; rồi → ce-work)
→ PR/MR + auto-merge PR ce-work + tick DoD + tự đổi status → Compound
    ↓  Automation: Compound  (model: cursor-grok-4.5-high)
ce-compound → learning/DOX → PR/MR + auto-merge (nếu có) + tự đổi status → Done
```

**Happy path:** `Plan` → auto `In Progress` → auto `Compound` → auto `Done`. Không dừng ở **In Review**; không chờ owner bấm tay các status đó.

Slack channel gắn project: điền ID channel của project đích (dùng khi agent báo Slack).

**Quy tắc chung — gắn URL PR/MR (bắt buộc):** bất kỳ automation nào tạo pull/merge request đều phải gắn URL PR/MR đó vào issue Linear liên quan ngay khi tạo, kể cả khi automation đó không phải Implement.

---

## 1. Generate plan

| Trường | Giá trị |
|--------|---------|
| Trigger | Linear status → **Plan** |
| Team / Project | Theo repo đích |
| Model | `cursor-grok-4.5-high` |
| Repo | URL git + nhánh `main` của repo đích |

**Agent làm gì**

1. Báo Linear + Slack: đã bắt đầu tạo plan.
2. Kiểm tra plan đã tồn tại chưa (tránh tạo trùng).
3. Chạy `/ce-plan` (skill `ce-plan`) cho issue Linear.
4. Nếu đã có code changes + PR/MR: gán URL PR/MR vào issue Linear; `git` kiểm tra conflict với `main`; có thì resolve; **auto-merge** PR vào nhánh `main`.
5. Khi xong: **tự đổi** status Linear → **In Progress** (sau khi PR plan đã merge hoặc không có PR cần merge). Comment Linear (tiếng Việt): plan path, merge status, đã chuyển In Progress.

---

## 2. Implement

| Trường | Giá trị |
|--------|---------|
| Trigger | Linear status → **In Progress** |
| Team / Project | Theo repo đích |
| Model | `composer-2.5` |
| Repo | URL git + nhánh `main` của repo đích |

**Agent làm gì**

1. Báo Linear: đã bắt đầu triển khai.
2. Kiểm tra trên Git provider (GitHub/GitLab) và trên Linear xem plan của task / PR chứa file plan đã được merge vào nhánh chính chưa.
   - Nếu chưa merge: dừng lại (`stop`), chuyển status Linear về **Todo** (`save_issue` → `Todo`), và gửi comment giải thích lý do (**fallback** — thường khi ai đó nhảy status tay).
   - Nếu đã merge: tiếp tục bước 3.
3. Chạy `/ce-work` theo plan gắn issue Linear.
4. Gán URL pull/merge request vào issue Linear.
5. Nếu đã có code changes + PR/MR: `git` kiểm tra conflict với `main`; có thì resolve; **auto-merge** PR vào nhánh `main`.
6. Tick Definition of Done trên plan khi có bằng chứng.
7. Khi xong: **tự đổi** status Linear → **Compound** (không dùng **In Review**). Comment Linear (tiếng Việt): đã ship gì, link PR/MR, đã chuyển Compound.

---

## 3. Compound

| Trường | Giá trị |
|--------|---------|
| Trigger | Linear status → **Compound** |
| Team / Project | Theo repo đích |
| Model | `cursor-grok-4.5-high` |
| Repo | URL git + nhánh `main` của repo đích |

**Agent làm gì**

1. Chạy `/ce-compound` (skill `ce-compound`) để ghi lại learning vừa xong dưới dạng durable — xem `ce-compound/SKILL.md`.
2. Nếu có thay đổi (code changes / docs): bắt buộc tạo pull/merge request, gán URL PR/MR vào issue Linear, resolve conflict với `main` nếu cần, rồi **auto-merge** PR vào `main`.
3. Nếu nhánh tạo lúc `ce-work` đã merge: **clean branches**.
4. Khi xong: **tự đổi** status Linear → **Done**. Comment Linear (tiếng Việt): đã đúc kết gì, issue đã Done.

---

## Cách dùng (owner / Serial Plan)

1. **Serial Plan:** đưa **đúng một** issue → **Plan**. Không đưa nhiều issue vào Plan cùng lúc.
2. Generate plan chạy tự động → auto-merge PR plan → **tự** chuyển **In Progress** (owner không cần bấm In Progress trên happy path).
3. Implement chạy tự động → auto-merge PR work → **tự** chuyển **Compound**.
4. Compound chạy tự động → auto-merge PR compound (nếu có) → **tự** chuyển **Done**.
5. Chỉ khi issue hiện tại đã **Done** mới đưa issue tiếp theo → **Plan**.

**Fallback / legacy:** nếu ai đó nhảy tay thẳng sang **In Progress** khi PR plan chưa merge, Implement sẽ stop → **Todo** + comment. Status **In Review** không còn thuộc happy path.

---

## ID tham chiếu (Linear)

Điền ID team / project / status của workspace đích khi tạo automation trong Cursor. Các field trong JSON mẫu (`teamIds`, `projectIds`, `statusIds`) là placeholder — thay bằng ID thật trước khi save.

Tạo/chỉnh automation trong [Cursor Automations](https://cursor.com/docs/agent/automations). Chat chỉ prefill editor — save cuối cùng trong UI. Trên tài khoản Keios: automation đã sẵn — chỉ cập nhật hợp đồng trong repo (`LOOP.md` / prompts JSON mẫu), không giả định đã save lại UI.
