# Cursor Automations (loop mẫu)

Ba automation tách **lập kế hoạch**, **triển khai** và **đúc kết (compound)**. Gắn Linear team/project và git repo của **repo đích** (điền khi tạo automation). Tools: Linear MCP (+ Slack MCP cho hai automation đầu). Memory bật; scope private.

**JSON tham chiếu** (export từ Cursor Automations — chỉnh team/project/repo trước khi import):

| Automation | File |
|------------|------|
| Generate plan | [`automations/generate-plan.json`](./automations/generate-plan.json) |
| Implement | [`automations/implement.json`](./automations/implement.json) |
| Compound | [`automations/compound.json`](./automations/compound.json) |

```text
Linear status → Plan
    ↓  Automation: Generate plan  (model: cursor-grok-4.5-high)
ce-plan → plan dưới docs/plans/ + auto-merge PR của plan (không đổi status Linear)
    ↓  owner chuyển status → In Progress
    ↓  Automation: Implement  (model: composer-2.5)
kiểm tra PR plan đã merge trên Git provider & Linear (chưa → stop & Todo; rồi → ce-work) → PR/MR + auto-merge PR của ce-work + gắn URL Linear → status In Review
    ↓  review xong → agent/owner chuyển status → Compound
    ↓  Automation: Compound  (model: cursor-grok-4.5-high)
ce-compound → ghi learning/DOX → PR/MR + auto-merge PR của ce-compound + gắn URL Linear (nếu có thay đổi) → status Done
```

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
4. **Không** đổi status Linear khi xong.
5. Nếu đã có code changes + PR/MR: gán URL PR/MR vào issue Linear; `git` kiểm tra conflict với `main`; có thì resolve; tự động merge (auto-merge) PR vào nhánh `main`.

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
   - Nếu chưa merge: dừng lại (`stop`), chuyển status Linear về **Todo** (`save_issue` → `Todo`), và gửi comment giải thích lý do.
   - Nếu đã merge: tiếp tục bước 3.
3. Chạy `/ce-work` theo plan gắn issue Linear.
4. Gán URL pull/merge request vào issue Linear.
5. Nếu đã có code changes + PR/MR: `git` kiểm tra conflict với `main`; có thì resolve; tự động merge (auto-merge) PR vào nhánh `main`.
6. Đổi status Linear → **In Review** khi xong.

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
2. Nếu có thay đổi (code changes / docs), bắt buộc tạo pull request / merge request, gán URL PR/MR vào issue Linear, dùng git kiểm tra conflict với `main` (nếu có thì resolve), và tự động merge (auto-merge) PR vào nhánh `main`.
3. Sau khi merge PR của ce-compound (hoặc ngay nếu không có thay đổi) đổi status Linear → **Done**.

---

## Cách dùng (owner)

1. Issue vào **Plan** → chờ Generate plan xong (status giữ Plan).
2. Duyệt plan trên Linear / `docs/plans/`.
3. Chuyển **In Progress** → Implement chạy; khi xong issue vào **In Review**.
4. Review PR/MR → merge / Compound theo quy trình đóng vòng trong `LOOP.md`.
5. Issue vào **Compound** → Compound tự chạy `ce-compound` để đúc kết learning; khi xong (PR đã merge hoặc không có thay đổi) issue vào **Done**.

Không nhảy thẳng Plan → In Progress nếu chưa có plan (Implement cần plan gắn issue).

---

## ID tham chiếu (Linear)

Điền ID team / project / status của workspace đích khi tạo automation trong Cursor. Các field trong JSON mẫu (`teamIds`, `projectIds`, `statusIds`) là placeholder — thay bằng ID thật trước khi save.

Tạo/chỉnh automation trong [Cursor Automations](https://cursor.com/docs/agent/automations). Chat chỉ prefill editor — save cuối cùng trong UI.
