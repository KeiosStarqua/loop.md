# my-loop-config

Repo này chứa template **loop engineering** (`LOOP.md` / `LOOP.mdc` / `AGENTS.md`) và cấu hình Cursor Automations mẫu (Generate plan / Implement).

Tham gia bởi:

- [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin)
- [Cursor Automation](https://cursor.com/docs/agent/automations)
- [Linear](https://linear.app)
- [Slack](https://slack.com/)

## Tài liệu

| File | Nội dung |
|------|----------|
| [`AUTOMATIONS.md`](./AUTOMATIONS.md) | Hai automation mẫu: **Generate plan** (`Todo`) và **Implement** (`In Progress`) |
| [`LOOP.md`](./LOOP.md) | Đặc tả vòng giao tính năng (đồng bộ với `LOOP.mdc`) |
| [`AGENTS.md`](./AGENTS.md) | Quy tắc đồng bộ `LOOP.md` ↔ `LOOP.mdc` |

## Cài / cập nhật `LOOP.mdc` vào repo khác

Mỗi repo giữ giá trị Linear riêng trong `.cursor/loop.env`. Script copy template rồi thay `REPLACE_*`.

**URL remote runner (khuyến nghị — tự tải `sync-loop.sh` + `LOOP.mdc` + `loop.env.example`):**

```text
https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh
```

### Cách đơn giản nhất — 1 lệnh, không cần flag

Trong thư mục repo đích (hoặc chỉ định đường dẫn):

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash
# hoặc: ... | bash -s -- /path/to/repo
```

- Chưa có `.cursor/loop.env` → **tự tạo** từ `loop.env.example` (giá trị mặc định `your-*`) rồi sync luôn, **không lỗi**.
- Đã có `.cursor/loop.env` → dùng luôn giá trị đó để sync (chạy lại bao nhiêu lần cũng an toàn).
- Nếu giá trị mặc định (`your-display-name`, `your-workspace`...) không đúng cho repo này: mở `.cursor/loop.env` sửa 5 biến Linear cho đúng, rồi chạy lại đúng lệnh trên — không cần bước riêng nào khác.

`bash -s --` dùng khi cần truyền thêm đường dẫn repo. Không pipe thẳng `sync-loop.sh` — script đó cần template cạnh nó; dùng `sync-loop-remote.sh` để tải đủ.

### Clone local

```bash
./scripts/sync-loop.sh /path/to/repo
```

Kết quả: `.cursor/rules/LOOP.mdc` với giá trị Linear của repo (không còn placeholder REPLACE_*, có thể là giá trị mặc định nếu chưa sửa `loop.env`).

### Tuỳ chọn nâng cao

| Flag | Khi nào dùng |
|------|--------------|
| `--init` | Chỉ tạo `.cursor/loop.env` từ mẫu, **không** sync ngay — dùng khi muốn sửa giá trị trước |
| `--setup --owner ... --workspace ... --project-name ... --project-url ... --project-id ...` | Tạo `loop.env` với giá trị Linear thật ngay từ đầu (bỏ qua bước sửa tay), rồi sync. Idempotent nếu `loop.env` đã có; thêm `--force` để ghi đè |

## Prompt cho agent (sync từng repo)

Copy prompt dưới đây khi nhờ agent cài hoặc cập nhật `LOOP.mdc` sang một (hoặc nhiều) repo:

```text
Dùng sync-loop để cài/cập nhật LOOP.mdc cho từng repo đích. Không copy tay LOOP.mdc.

Luôn lấy runner mới nhất qua curl (khuyến nghị — không cần clone):

  curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- [--init|--setup ...] [<repo>]

  sync-loop-remote.sh tự tải sync-loop.sh + LOOP.mdc + loop.env.example cùng revision.
  Không pipe sync-loop.sh trực tiếp (thiếu template).

  Nếu đã clone my-loop-config: chạy scripts/sync-loop-remote.sh hoặc ./scripts/sync-loop.sh.

Cho mỗi repo đích, lần lượt:

1. Nếu chưa có <repo>/.cursor/loop.env: tự tra Linear (list_projects / search theo
   tên repo) để xác định project phù hợp, hỏi owner nếu không kết luận được rõ ràng.
   Cần đủ 5 giá trị: owner display name, workspace slug, project name, project url,
   project id.

2. Chạy đúng 1 lệnh --setup cho repo đó (tự tạo loop.env nếu chưa có, rồi sync ngay;
   nếu loop.env đã có thì bỏ qua flag và chỉ sync — an toàn để chạy lại):

     curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --setup \
       --owner "<owner>" --workspace "<workspace>" --project-name "<project name>" \
       --project-url "<project url>" --project-id "<project id>" <repo>

   - Kết quả bắt buộc: <repo>/.cursor/rules/LOOP.mdc, không còn placeholder REPLACE_LINEAR_*
   - Giá trị trong file phải khớp .cursor/loop.env của repo đó
   - Không commit secret; loop.env chỉ chứa metadata Linear public.

3. Xác minh nhanh (grep REPLACE_LINEAR_ → không có kết quả; spot-check owner/project).

Khi user liệt kê nhiều repo: lặp bước 1–3 cho từng repo (mỗi repo 1 lệnh --setup),
báo cáo ngắn từng repo (ok / thiếu thông tin Linear / lỗi). Không sửa LOOP.md hoặc
LOOP.mdc trong my-loop-config trừ khi user yêu cầu rõ.
```
