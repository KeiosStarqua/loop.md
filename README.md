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

**URL remote runner (khuyến nghị — tự tải `sync-loop.sh` + `LOOP.mdc` + `loop.env.example`):**

```text
https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh
```

### Chạy bằng `curl` (không cần clone)

Trong thư mục repo đích:

```bash
# 1) Tạo .cursor/loop.env (chỉ lần đầu)
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --init

# 2) Điền 5 biến Linear trong .cursor/loop.env

# 3) Sync → ghi .cursor/rules/LOOP.mdc
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s --
```

Hoặc chỉ định đường dẫn repo (chạy từ bất kỳ đâu):

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --init /path/to/repo
# chỉnh /path/to/repo/.cursor/loop.env
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- /path/to/repo
```

`bash -s --` nhận args sau `--` rồi truyền vào script. Không pipe thẳng `sync-loop.sh` — script đó cần template cạnh nó; dùng `sync-loop-remote.sh` để tải đủ.

### Clone local

```bash
/path/to/my-loop-config/scripts/sync-loop-remote.sh --init /path/to/repo
# chỉnh /path/to/repo/.cursor/loop.env
/path/to/my-loop-config/scripts/sync-loop-remote.sh /path/to/repo

# Hoặc sync từ tree local (không fetch GitHub)
./scripts/sync-loop.sh --init /path/to/repo
./scripts/sync-loop.sh /path/to/repo
```

Kết quả: `.cursor/rules/LOOP.mdc` với giá trị Linear của repo (không còn placeholder).

## Prompt cho agent (sync từng repo)

Copy prompt dưới đây khi nhờ agent cài hoặc cập nhật `LOOP.mdc` sang một (hoặc nhiều) repo:

```text
Dùng sync-loop để cài/cập nhật LOOP.mdc cho từng repo đích. Không copy tay LOOP.mdc.

Luôn lấy runner mới nhất qua curl (khuyến nghị — không cần clone):

  curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- [--init] [<repo>]

  sync-loop-remote.sh tự tải sync-loop.sh + LOOP.mdc + loop.env.example cùng revision.
  Không pipe sync-loop.sh trực tiếp (thiếu template).

  Nếu đã clone my-loop-config: chạy scripts/sync-loop-remote.sh hoặc ./scripts/sync-loop.sh.

Cho mỗi repo đích, lần lượt:

1. Nếu chưa có <repo>/.cursor/loop.env:
   - Chạy:
       curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --init <repo>
   - Điền đủ 5 biến Linear trong .cursor/loop.env (hỏi owner nếu thiếu):
     REPLACE_LINEAR_OWNER_DISPLAY_NAME
     REPLACE_LINEAR_WORKSPACE
     REPLACE_LINEAR_PROJECT_NAME
     REPLACE_LINEAR_PROJECT_URL
     REPLACE_LINEAR_PROJECT_ID
   - Không commit secret; loop.env chỉ chứa metadata Linear public.

2. Chạy:
     curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- <repo>
   - Kết quả bắt buộc: <repo>/.cursor/rules/LOOP.mdc
   - File này phải không còn placeholder REPLACE_LINEAR_*
   - Giá trị trong file phải khớp .cursor/loop.env của repo đó

3. Xác minh nhanh (grep REPLACE_LINEAR_ → không có kết quả; spot-check owner/project).

Khi user liệt kê nhiều repo: lặp bước 1–3 cho từng repo, báo cáo ngắn từng repo
(ok / thiếu loop.env / lỗi). Không sửa LOOP.md hoặc LOOP.mdc trong my-loop-config
trừ khi user yêu cầu rõ.
```
