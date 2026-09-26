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
| [`AUTOMATIONS.md`](./AUTOMATIONS.md) | Ba automation mẫu: **Generate plan** (`Plan`), **Implement** (`In Progress`) và **Compound** (`Compound`) |
| [`LOOP.md`](./LOOP.md) | Nguồn đặc tả vòng giao tính năng. `LOOP.mdc` sinh bằng `scripts/gen-loop-mdc.sh` |
| [`AGENTS.md`](./AGENTS.md) | Quy tắc: sửa `LOOP.md`, chạy script để ghi `LOOP.mdc` |

Sinh `LOOP.mdc` sau khi sửa nguồn (nội dung giữ nguyên, thêm frontmatter `alwaysApply: true`):

```bash
./scripts/gen-loop-mdc.sh          # ghi LOOP.mdc
./scripts/gen-loop-mdc.sh --check  # lỗi nếu lệch
```

## Cài / cập nhật `LOOP.mdc` vào repo khác

Mỗi repo giữ giá trị Linear riêng trong `.cursor/loop.jsonc` (nhiều project trong mảng `projects`). Script copy template rồi thay `REPLACE_*`. Repo còn `.cursor/loop.env` (một project) vẫn được đọc khi chưa có `loop.jsonc`.

**URL remote runner (khuyến nghị — tự tải `sync-loop.sh` + `loop-jsonc.py` + `LOOP.mdc` + `loop.jsonc.example`):**

```text
https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh
```

### Cách đơn giản nhất — 1 lệnh, không cần flag

Trong thư mục repo đích (hoặc chỉ định đường dẫn):

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash
# hoặc: ... | bash -s -- /path/to/repo
```

**PowerShell (Windows / `pwsh`):**

```powershell
irm https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1 | iex
# hoặc chỉ định repo (dùng -TargetRepo — tránh path kiểu /tmp/... vì PowerShell coi là switch):
$u = 'https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1'
& ([ScriptBlock]::Create((irm $u))) @('-TargetRepo', 'C:\path\to\repo')
```

- Chưa có `.cursor/loop.jsonc` và chưa có `.cursor/loop.env` → **tự tạo** `loop.jsonc` từ `loop.jsonc.example` (giá trị mặc định `your-*`, một project) rồi sync luôn, **không lỗi**.
- Đã có `.cursor/loop.jsonc` → dùng mảng `projects` trong file đó (chạy lại bao nhiêu lần cũng an toàn).
- Chỉ có `.cursor/loop.env` → đọc như một project. Muốn thêm project thì tạo `loop.jsonc` (file này được ưu tiên hơn `loop.env`).
- Nếu giá trị mặc định (`your-display-name`, `your-workspace`...) không đúng cho repo này: mở `.cursor/loop.jsonc`, sửa `ownerDisplayName`, `workspace`, `forceMergePr`, và mảng `projects`, rồi chạy lại đúng lệnh trên.

`bash -s --` dùng khi cần truyền thêm đường dẫn repo. Không pipe thẳng `sync-loop.sh` — script đó cần template cạnh nó; dùng `sync-loop-remote.sh` để tải đủ. Trên PowerShell: dùng `sync-loop-remote.ps1` (không pipe thẳng `sync-loop.ps1` — cùng lý do).

### Clone local

```bash
./scripts/sync-loop.sh /path/to/repo
```

```powershell
./scripts/sync-loop.ps1 -TargetRepo C:\path\to\repo
```

Kết quả: `.cursor/rules/LOOP.mdc` với giá trị Linear của repo (không còn placeholder REPLACE_*, có thể là giá trị mặc định nếu chưa sửa `loop.jsonc`).

### Tuỳ chọn nâng cao

| Flag | Khi nào dùng |
|------|--------------|
| `--init` / `-Init` | Chỉ tạo `.cursor/loop.jsonc` từ mẫu, **không** sync ngay — dùng khi muốn sửa giá trị trước. Không tạo mẫu nếu repo đang dùng `loop.env` (tránh file mới che cấu hình cũ) |
| `--setup --owner ...` / `-Setup -Owner ...` | Tạo `loop.jsonc` với giá trị Linear thật ngay từ đầu, rồi sync. Lặp `--project-name` / `--project-url` / `--project-id` cho mỗi project; project đầu tiên là mặc định. Idempotent nếu `loop.jsonc` hoặc `loop.env` đã có; thêm `--force` / `-Force` để ghi `loop.jsonc` |

## Prompt cho agent (sync từng repo)

Copy prompt dưới đây khi nhờ agent cài hoặc cập nhật `LOOP.mdc` sang một (hoặc nhiều) repo:

```text
Dùng sync-loop để cài/cập nhật LOOP.mdc cho từng repo đích. Không copy tay LOOP.mdc.

Luôn lấy runner mới nhất qua curl hoặc irm (khuyến nghị — không cần clone):

  curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- [--init|--setup ...] [<repo>]

  # PowerShell:
  irm https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1 | iex
  # hoặc có tham số:
  $u = 'https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1'
  & ([ScriptBlock]::Create((irm $u))) @('-Setup', '-Owner', '<owner>', '-Workspace', '<workspace>', '-ProjectName', '<project name>', '-ProjectUrl', '<project url>', '-ProjectId', '<project id>', '-TargetRepo', '<repo>')

  sync-loop-remote.sh tự tải sync-loop.sh + loop-jsonc.py + LOOP.mdc + loop.jsonc.example cùng revision.
  sync-loop-remote.ps1 tự tải sync-loop.ps1 + LOOP.mdc + loop.jsonc.example cùng revision.
  Không pipe sync-loop.{sh,ps1} trực tiếp (thiếu template).

  Nếu đã clone my-loop-config: chạy scripts/sync-loop-remote.{sh,ps1} hoặc ./scripts/sync-loop.{sh,ps1}.

Cho mỗi repo đích, lần lượt:

1. Nếu chưa có <repo>/.cursor/loop.jsonc (và chưa có loop.env): tự tra Linear
   (list_projects / search theo tên repo) để xác định mọi project quản lý issue
   của repo, hỏi owner nếu không kết luận được rõ ràng.
   Cần: owner display name, workspace slug, và ít nhất một project (name, url, id).
   Project tạo issue mới khi chưa rõ project là phần tử "default": true
   (hoặc project đầu tiên nếu không đánh dấu).

2. Chạy đúng 1 lệnh --setup cho repo đó (tự tạo loop.jsonc nếu chưa có, rồi sync ngay;
   nếu loop.jsonc hoặc loop.env đã có thì bỏ qua flag và chỉ sync — an toàn để chạy lại).
   Nhiều project: lặp bộ --project-name / --project-url / --project-id. Project đầu tiên là mặc định.

     curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --setup \
       --owner "<owner>" --workspace "<workspace>" \
       --project-name "<project name>" --project-url "<project url>" --project-id "<project id>" \
       --project-name "<project name 2>" --project-url "<project url 2>" --project-id "<project id 2>" \
       <repo>

   PowerShell tương đương (nhiều project: truyền các mảng cùng thứ tự):

     $u = 'https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1'
     & ([ScriptBlock]::Create((irm $u))) @('-Setup', '-Owner', '<owner>', '-Workspace', '<workspace>', '-ProjectName', '<project name>','<project name 2>', '-ProjectUrl', '<project url>','<project url 2>', '-ProjectId', '<project id>','<project id 2>', '-TargetRepo', '<repo>')

   - Kết quả bắt buộc: <repo>/.cursor/rules/LOOP.mdc, không còn placeholder REPLACE_LINEAR_*
   - Bảng project trong file phải khớp .cursor/loop.jsonc của repo đó (hoặc loop.env nếu chưa chuyển)
   - Không commit secret; loop.jsonc chỉ chứa metadata Linear public.

3. Xác minh nhanh (grep REPLACE_LINEAR_ → không có kết quả; spot-check owner/project).

Khi user liệt kê nhiều repo: lặp bước 1–3 cho từng repo (mỗi repo 1 lệnh --setup),
báo cáo ngắn từng repo (ok / thiếu thông tin Linear / lỗi). Không sửa LOOP.md hoặc
LOOP.mdc trong my-loop-config trừ khi user yêu cầu rõ.
```
