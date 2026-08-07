# KT System — Cursor Automations

Hai automation tách **lập kế hoạch** và **triển khai**. Cả hai gắn Linear team **Keios**, project **[KT System](https://linear.app/keios/project/kt-system-ea15401361ab)**, checkout GitLab `TaQuangKhoi/kt-system` nhánh `main`. Tools: Linear MCP + Slack MCP. Memory bật; scope private.

```text
Linear status → Todo
    ↓  Automation: KT-System - Generate plan  (model: cursor-grok-4.5-high)
ce-plan → plan dưới docs/plans/  (không đổi status Linear)
    ↓  owner chuyển status → In Progress
    ↓  Automation: KT-System - Implement  (model: composer-2.5)
ce-work → PR/MR + gắn URL Linear → status In Review
```

Slack channel gắn project: `C0BN6GATNSH` (dùng khi agent báo Slack).

---

## 1. KT-System - Generate plan

| Trường | Giá trị |
|--------|---------|
| Trigger | Linear status → **Todo** (`786e2ae5-c7f3-4888-8fb4-9a6d4f0ad601`) |
| Team / Project | Keios / KT System |
| Model | `cursor-grok-4.5-high` |
| Repo | `https://gitlab.com/TaQuangKhoi/kt-system` @ `main` |

**Agent làm gì**

1. Báo Linear + Slack: đã bắt đầu tạo plan.
2. Kiểm tra plan đã tồn tại chưa (tránh tạo trùng).
3. Chạy `/ce-plan` (skill `ce-plan`) cho issue Linear.
4. **Không** đổi status Linear khi xong.
5. Nếu đã có code changes + PR/MR: `git` kiểm tra conflict với `main`; có thì resolve.

---

## 2. KT-System - Implement

| Trường | Giá trị |
|--------|---------|
| Trigger | Linear status → **In Progress** (`1e014385-ae7f-4991-9487-e5aa3db09044`) |
| Team / Project | Keios / KT System |
| Model | `composer-2.5` |
| Repo | `https://gitlab.com/TaQuangKhoi/kt-system` @ `main` |

**Agent làm gì**

1. Báo Linear: đã bắt đầu triển khai.
2. Chạy `/ce-work` theo plan gắn issue Linear.
3. Gán URL pull/merge request vào issue Linear.
4. Đổi status Linear → **In Review** khi xong.
5. Nếu đã có code changes + PR/MR: `git` kiểm tra conflict với `main`; có thì resolve.

---

## Cách dùng (owner)

1. Issue vào **Todo** → chờ Generate plan xong (status giữ Todo).
2. Duyệt plan trên Linear / `docs/plans/`.
3. Chuyển **In Progress** → Implement chạy; khi xong issue vào **In Review**.
4. Review PR/MR → merge / Done theo quy trình đóng vòng trong `LOOP.md`.

Không nhảy thẳng Todo → In Progress nếu chưa có plan (Implement cần plan gắn issue).

---

## ID tham chiếu (Linear)

| Thực thể | ID |
|----------|-----|
| Team Keios | `51744d2d-408f-4a76-922e-262add85cb6f` |
| Project KT System | `5b44e380-e2f4-4bdd-81f9-a0cd29aa2c90` |
| Status Todo | `786e2ae5-c7f3-4888-8fb4-9a6d4f0ad601` |
| Status In Progress | `1e014385-ae7f-4991-9487-e5aa3db09044` |
| Status In Review | `a1aa09b7-ecc3-4697-bb37-076aa3fd5301` |

Tạo/chỉnh automation trong [Cursor Automations](https://cursor.com/docs/agent/automations). Chat chỉ prefill editor — save cuối cùng trong UI.
