# my-loop-config

Repo này chứa template **loop engineering** (`LOOP.md` / `LOOP.mdc` / `AGENTS.md`) và cấu hình Cursor Automations cho KT System.

Tham gia bởi:

- [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin)
- [Cursor Automation](https://cursor.com/docs/agent/automations)
- [Linear](https://linear.app)
- [Slack](https://slack.com/)

## Tài liệu

| File | Nội dung |
|------|----------|
| [`AUTOMATIONS.md`](./AUTOMATIONS.md) | Hai automation KT System: **Generate plan** (`Todo`) và **Implement** (`In Progress`) |
| [`LOOP.md`](./LOOP.md) | Đặc tả vòng giao tính năng (đồng bộ với `LOOP.mdc`) |
| [`AGENTS.md`](./AGENTS.md) | Quy tắc đồng bộ `LOOP.md` ↔ `LOOP.mdc` |

## Cài / cập nhật `LOOP.mdc` vào repo khác

Mỗi repo giữ giá trị Linear riêng trong `.cursor/loop.env`. Script copy template rồi thay `REPLACE_*`.

```bash
# Lần đầu: tạo .cursor/loop.env rồi điền
./scripts/sync-loop.sh --init /path/to/repo
# chỉnh /path/to/repo/.cursor/loop.env

# Cài hoặc cập nhật sau khi sửa template
./scripts/sync-loop.sh /path/to/repo
```

Trong repo đích:

```bash
/path/to/my-loop-config/scripts/sync-loop.sh --init
# điền .cursor/loop.env
/path/to/my-loop-config/scripts/sync-loop.sh
```

Kết quả: `.cursor/rules/LOOP.mdc` với giá trị Linear của repo (không còn placeholder).

## Prompt cho agent (sync từng repo)

Copy prompt dưới đây khi nhờ agent cài hoặc cập nhật `LOOP.mdc` sang một (hoặc nhiều) repo:

```text
Dùng script sync-loop.sh trong repo my-loop-config để cài/cập nhật LOOP.mdc
cho từng repo đích. Không copy tay LOOP.mdc.

Đường dẫn script (tuyệt đối nếu cần):
  <path-to-my-loop-config>/scripts/sync-loop.sh

Cho mỗi repo đích, lần lượt:

1. Nếu chưa có <repo>/.cursor/loop.env:
   - Chạy: sync-loop.sh --init <repo>
   - Điền đủ 5 biến Linear trong .cursor/loop.env (hỏi owner nếu thiếu):
     REPLACE_LINEAR_OWNER_DISPLAY_NAME
     REPLACE_LINEAR_WORKSPACE
     REPLACE_LINEAR_PROJECT_NAME
     REPLACE_LINEAR_PROJECT_URL
     REPLACE_LINEAR_PROJECT_ID
   - Không commit secret; loop.env chỉ chứa metadata Linear public.

2. Chạy: sync-loop.sh <repo>
   - Kết quả bắt buộc: <repo>/.cursor/rules/LOOP.mdc
   - File này phải không còn placeholder REPLACE_LINEAR_*
   - Giá trị trong file phải khớp .cursor/loop.env của repo đó

3. Xác minh nhanh (grep REPLACE_LINEAR_ → không có kết quả; spot-check owner/project).

Khi user liệt kê nhiều repo: lặp bước 1–3 cho từng repo, báo cáo ngắn từng repo
(ok / thiếu loop.env / lỗi). Không sửa LOOP.md hoặc LOOP.mdc trong my-loop-config
trừ khi user yêu cầu rõ.
```
