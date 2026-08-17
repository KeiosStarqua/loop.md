### Loop Engineering — vòng giao tính năng

Hình dạng vòng chuẩn:

```text
Quan sát → Chọn việc → Lập kế hoạch → Triển khai → Kiểm chứng
         → Học → Đóng vòng → Lặp lại hoặc Dừng
```

Ánh xạ trên repo này:

```text
Linear (issue kỹ thuật nguyên tử — nguồn sự thật)
    ↓ Serial Plan: đưa đúng một issue → Plan; chờ issue đó Done rồi mới Plan issue tiếp
    ↓ Cursor Automation: status → Plan → Generate plan (ce-plan)
docs/plans/ + auto-merge PR của plan + comment Linear + tự đổi status → In Progress
    ↓ Cursor Automation: Implement (kiểm tra PR plan đã merge trên Git/Linear chưa;
      nếu chưa → stop & status Todo [fallback]; nếu rồi → ce-work)
    → PR/MR + auto-merge PR của ce-work + tick DoD + tự đổi status → Compound
    ↓ Cursor Automation: status → Compound → Compound (ce-compound)
    → PR/MR + auto-merge (nếu có) + gắn URL Linear; clean branches nếu nhánh ce-work đã merge
    → tự đổi status → Done
Lặp issue Linear tiếp theo (qua Serial Plan)
```

**Happy path (bắt buộc):** `Plan` → (ce-plan, auto-merge PR plan, auto → `In Progress`) → `In Progress` → (ce-work, auto-merge PR work, auto → `Compound`) → `Compound` → (ce-compound, auto-merge PR nếu có, auto → `Done`). Không dừng ở **In Review**; không chờ owner bấm tay `In Progress` / `Compound` / `Done` trên happy path.

**Cursor Automations (ba bước):**

1. **Generate plan** — status → **`Plan`**: báo Linear đã bắt đầu; chạy **`ce-plan`**; kiểm tra plan đã tồn tại; nếu có PR/MR chứa plan thì kiểm tra/resolve conflict với `main`, auto-merge PR vào nhánh chính (`main`), và gắn URL PR/MR vào Linear; khi xong **tự đổi** status → **`In Progress`** (sau khi PR plan đã merge hoặc không có PR cần merge).
2. **Implement** — status → **`In Progress`**: báo Linear đã bắt đầu; kiểm tra trên Git provider (GitHub/GitLab) và trên Linear xem plan của task / PR của plan đã được merge chưa — nếu chưa thì **stop**, chuyển status issue trên Linear về **`Todo`** và comment Linear nêu rõ lý do (**fallback** khi ai đó nhảy status tay, bỏ qua Plan); nếu đã merge thì chạy **`ce-work`** theo plan gắn issue; nếu có PR/MR thì kiểm tra/resolve conflict với `main`, auto-merge PR vào nhánh chính (`main`), gắn URL PR/MR vào Linear, tick Definition of Done trên plan; khi xong **tự đổi** status → **`Compound`** (không dùng **In Review**).
3. **Compound** — status → **`Compound`**: chạy **`ce-compound`** để ghi lại learning/DOX của issue vừa đóng vòng; nếu có thay đổi thì bắt buộc tạo pull/merge request, gán URL PR/MR vào Linear, kiểm tra/resolve conflict với `main`, và **auto-merge** PR vào `main`; kiểm tra nhánh tạo lúc **`ce-work`** đã merge chưa — nếu đã merge thì **clean branches**; khi xong **tự đổi** status → **`Done`**.

**Serial Plan (bắt buộc):** phải có routine/agent bên ngoài (hoặc owner) đưa issue sang **`Plan` theo tuần tự một issue một lúc**: chọn một issue → chuyển **`Plan`** → chờ vòng đầy đủ của issue đó kết thúc ở **`Done`** → mới đưa issue tiếp theo sang **`Plan`**. Không đẩy nhiều issue vào **`Plan`** cùng lúc (tránh nhiều Generate plan / Implement chạy song song làm loạn merge và context).

**Quy tắc chung — gắn URL PR/MR (bắt buộc):** bất kỳ bước nào tạo pull/merge request (dù là `ce-plan`, `ce-work`, automation, hay chạy tay) đều **phải** gắn URL PR/MR đó vào issue Linear liên quan ngay khi tạo — không chờ tới bước tổng kết mới gắn.

**Sau khi `ce-plan` xong** (manual hoặc automation), nếu có PR tạo bởi bước lập kế hoạch thì agent **phải auto-merge PR của plan vào `main`**, **tự đổi status → `In Progress`**, và comment Linear theo **Thông báo hoàn thành của agent** — xem **Quy trình vòng sau `ce-plan`**. Ưu tiên bám plan do automation tạo; không mở đường lập kế hoạch song song.

Một đặc tả vòng nên có ít nhất: Trigger, Goal, Available context, Permitted actions, Verification, Failure handling, Memory update, Stopping conditions.

Trạng thái kết thúc (mỗi lần chạy kết thúc đúng một):

- `COMPLETE`
- `BLOCKED`
- `FAILED_VERIFICATION`
- `NEEDS_HUMAN_DECISION`
- `BUDGET_EXHAUSTED`

Chỉ `COMPLETE` khi: acceptance criteria có bằng chứng; các check bắt buộc pass; không còn thay đổi không giải thích được; docs đã cập nhật khi cần; đóng vòng tracking đã xong.

### Thông báo hoàn thành của agent (bắt buộc)

Khi agent xong việc có ý nghĩa (task/issue xong, owner cần xem kết quả, hoặc user yêu cầu báo cáo), thông báo qua Linear:

1. **Linear** — trên issue kỹ thuật liên quan: `save_comment` (có thể ghi `REPLACE_LINEAR_OWNER_DISPLAY_NAME`), và/hoặc `save_issue` với `assignee: "me"` khi gán lại cho owner. Ngôn ngữ comment: **tiếng Việt 100%**. Comment ngắn: việc gì xong, kết quả/link chính, bước tiếp theo nếu có.

Không chỉ nhắc trong Cursor chat. Nếu chưa có Linear issue phù hợp, tạo issue ngắn trong project **`REPLACE_LINEAR_PROJECT_NAME`**, rồi comment + (tùy chọn) assign.

### Quy trình vòng sau `ce-plan` (bắt buộc)

Khi skill **`ce-plan`** (hoặc Cursor Automation chạy `ce-plan` sau status → `Plan`) **đã tạo/cập nhật plan** dưới `docs/plans/`, agent **không** dừng ở Cursor chat. Báo cáo lập kế hoạch, auto-merge PR plan, và chuyển status là một phần của “xong plan”:

1. **Plan ↔ Linear** — đảm bảo đường dẫn plan đã ghi vào mô tả issue Linear và frontmatter/section plan có `linear_issues:` (xem **Plan ↔ Linear** bên dưới).
2. **Auto-merge PR của plan** — nếu bước `ce-plan` tạo PR/MR chứa file plan (hoặc commit trên branch riêng), agent **bắt buộc tự động merge (auto-merge)** pull/merge request đó vào nhánh chính (`main`) sau khi kiểm tra không có conflict, và gắn URL PR/MR vào Linear.
3. **Status** — sau khi PR plan đã merge (hoặc không có PR cần merge): `save_issue` → **`In Progress`** để kích hoạt automation **Implement**. Đây là happy path; **không** để issue kẹt ở `Plan` chờ owner bấm tay.
4. **Thông báo** — chạy **Thông báo hoàn thành của agent** (comment Linear): plan nào vừa tạo/cập nhật (path), issue Linear liên quan, trạng thái merge PR của plan, đã chuyển `In Progress` / bước tiếp (`ce-work`).

Không chỉ nhắc trong Cursor chat. Áp dụng cả khi `ce-plan` chạy thủ công lẫn qua automation.

### Quy trình vòng `ce-work` (bắt buộc)

1. **Kiểm tra điều kiện tiên quyết (trước khi triển khai):**
   - Khi bắt đầu công đoạn `ce-work` (hoặc Cursor Automation **Implement** sau khi issue chuyển status → `In Progress`), agent **bắt buộc kiểm tra trên Git provider (GitHub/GitLab) và trên Linear** xem plan của task đã được merge chưa (PR/MR chứa plan đã merge vào nhánh chính chưa).
   - **Nếu plan / PR của plan chưa được merge:** agent **phải dừng lại (`stop`)**, chuyển status của issue trên Linear về **`Todo`** (`save_issue` → `Todo`), và gửi comment tiếng Việt trên Linear nêu rõ PR của plan chưa được merge, cần merge / chạy lại Plan trước khi triển khai. Đây là **fallback** khi status bị nhảy tay (bỏ qua Generate plan / auto-merge).
   - **Nếu plan / PR của plan đã merge:** tiếp tục các bước triển khai theo plan gắn issue.

2. **Khi đã kiểm chứng và hoàn tất phạm vi plan:**
   - **Plan (`docs/plans/…`)** — đánh dấu **Definition of Done** (và checkbox unit liên quan nếu có) thành `[x]` khi đã có bằng chứng (build/smoke/commit). Thêm ghi chú smoke/verify ngắn nếu plan còn chỗ trống. *Trong lúc* `ce-work`, vẫn không dùng plan làm task tracker giữa chừng; *sau khi* hoàn tất, **phải** tick DoD — đóng vòng repo này ghi đè hướng dẫn skill chung “đừng sửa thân plan”.
   - **Auto-merge PR của `ce-work`** — nếu bước `ce-work` tạo PR/MR (hoặc commit trên branch riêng), agent **bắt buộc tự động merge (auto-merge)** pull/merge request đó vào nhánh chính (`main`) sau khi kiểm tra không có conflict, và gắn URL PR/MR vào Linear.
   - **Linear (automation Implement)** — gắn URL PR/MR vào issue; `save_issue` → **`Compound`** (không dừng ở **In Review**; không chờ owner review tay trên happy path). `save_comment` tiếng Việt: đã ship gì, link PR/MR, trạng thái auto-merge, đã chuyển `Compound`.
   - **Thông báo** — chạy **Thông báo hoàn thành của agent** (comment Linear) sau khi tạo PR/MR, auto-merge và chuyển `Compound`. Status → `Compound` tự kích hoạt automation **Compound** (`ce-compound`).

Cũng áp dụng khi plan đã ship ở session trước nhưng DoD/Linear còn mở: nếu agent thấy lệch, hoàn tất đóng vòng — không để Backlog + checkbox trống.

### Quy trình vòng `ce-compound` (bắt buộc)

Khi skill **`ce-compound`** (hoặc Cursor Automation **Compound** sau status → `Compound`) chạy xong:

1. Nếu có PR/MR từ bước compound: gắn URL vào Linear, resolve conflict với `main` nếu cần, **auto-merge** vào `main`.
2. Clean branches của `ce-work` nếu nhánh đó đã merge.
3. `save_issue` → **`Done`**. **Không** để issue kẹt ở `Compound` sau khi compound xong.
4. Comment Linear (tiếng Việt): đã đúc kết gì, link PR/MR nếu có, issue đã `Done`.

### Quản lý việc

**Linear** là nguồn sự thật cho issue triển khai đang chạy và backlog kỹ thuật của vòng này. **Không** nhân bản toàn bộ backlog vào git.

#### Linear (issue kỹ thuật nguyên tử)

| Trường | Giá trị |
|--------|---------|
| Workspace | **`REPLACE_LINEAR_WORKSPACE`** |
| Project | **`REPLACE_LINEAR_PROJECT_NAME`** |
| URL project | `REPLACE_LINEAR_PROJECT_URL` |
| ID project | `REPLACE_LINEAR_PROJECT_ID` |

**Ngôn ngữ (bắt buộc cho setup này)**
- Toàn bộ chữ trên Linear **tiếng Việt 100%**: title, description, comment, acceptance, ghi chú. Giữ nguyên identifier file/path/tech khi trích dẫn.

**Quy trình agent**
- Trước khi làm việc cụ thể trên repo, query project Linear trước — ưu tiên `In Progress`, rồi ưu tiên cao, rồi deadline gần nhất.
- Dùng Linear MCP: `list_issues` lọc theo project; `get_issue` lấy chi tiết acceptance.
- **Serial Plan:** chỉ một issue ở `Plan` (và vòng tiếp theo) tại một thời điểm; routine ngoài đưa issue tiếp theo sang `Plan` sau khi issue hiện tại đã `Done`.
- **Status → Plan → plan:** issue sang **`Plan`** → automation **Generate plan** chạy **`ce-plan`**; nếu có PR/MR chứa plan thì resolve conflict, auto-merge vào `main`, gắn URL PR/MR vào Linear; **tự đổi** status → **`In Progress`**. Sau `ce-plan`, **bắt buộc** comment Linear — xem **Quy trình vòng sau `ce-plan`**.
- **Status → In Progress → implement:** automation **Implement** kiểm tra trên Git provider (GitHub/GitLab) và Linear xem plan / PR của plan đã merge chưa — nếu chưa thì **stop**, chuyển status về **`Todo`** và comment (fallback); nếu đã merge thì chạy **`ce-work`** theo plan gắn issue; nếu có PR/MR thì resolve conflict, auto-merge vào `main`, gắn URL PR/MR vào Linear; **tự đổi** status → **`Compound`**.
- **Status → Compound → compound:** automation **Compound** chạy **`ce-compound`**; nếu có thay đổi thì tạo PR/MR + gắn URL + auto-merge; clean branches nếu nhánh `ce-work` đã merge; **tự đổi** status → **`Done`**.
- **Plan ↔ Linear (bắt buộc):** khi plan gắn issue Linear, ghi đường dẫn plan tương đối vào mô tả issue (ví dụ `docs/plans/feature-x.md`). Nhiều plan: mỗi path một dòng. Đổi tên/di chuyển/xóa plan thì cập nhật mọi Linear issue liên quan. Frontmatter / section của plan phải liệt kê `linear_issues:` (URL/ID issue) chiều ngược lại.

### Tùy chọn: gắn Cursor `/loop` sau

Khi vòng thủ công đã ổn:

```text
/loop <interval> Serial Plan: chọn đúng một Linear issue mở ưu tiên cao nhất trong project
REPLACE_LINEAR_PROJECT_NAME (chưa Done; không chọn issue khác nếu đang có issue ở Plan /
In Progress / Compound). Đưa issue đó → Plan (hoặc chờ automation đang chạy). Không đẩy
nhiều issue vào Plan cùng lúc. Kiểm chứng vòng: Plan → In Progress → Compound → Done.
Dừng khi BLOCKED / NEEDS_HUMAN_DECISION.
```

Ưu tiên một vòng giao tính năng ổn định (serial) trước multi-agent / multi-issue song song.

### Checklist REPLACE (điền trước khi dán sang repo khác)

| Placeholder | Ví dụ |
|-------------|--------|
| `REPLACE_LINEAR_OWNER_DISPLAY_NAME` | `your-display-name` |
| `REPLACE_LINEAR_WORKSPACE` | `your-workspace` |
| `REPLACE_LINEAR_PROJECT_NAME` | `Your Project` |
| `REPLACE_LINEAR_PROJECT_URL` | `https://linear.app/your-workspace/project/your-project-id/overview` |
| `REPLACE_LINEAR_PROJECT_ID` | `your-project-id` |
