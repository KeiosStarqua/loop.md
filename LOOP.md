### Loop Engineering — vòng giao tính năng

Hình dạng vòng chuẩn:

```text
Quan sát → Chọn việc → Lập kế hoạch → Triển khai → Kiểm chứng
         → Review → Học → Đóng vòng → Lặp lại hoặc Dừng
```

Ánh xạ trên repo này:

```text
Linear (issue kỹ thuật nguyên tử — nguồn sự thật)
    ↓ Cursor Automation: status → Plan → Generate plan (ce-plan)
docs/plans/ + auto-merge PR của plan + comment Linear cho owner + status → In Progress
    ↓ Cursor Automation: Implement (kiểm tra PR plan đã merge trên Git/Linear chưa; nếu chưa → stop & status Todo; nếu rồi → ce-work) → PR/MR + auto-merge PR của ce-work + status In Review
Đóng vòng sau review (bắt buộc — thuộc “xong”)
    → đánh dấu Definition of Done trên plan
    → Linear → Compound + comment cho owner
    ↓ Cursor Automation: status → Compound → Compound (ce-compound) → PR/MR + auto-merge PR của ce-compound + gắn URL Linear (nếu có thay đổi) + status Done; nếu nhánh ce-work đã merge → clean branches
Lặp issue Linear tiếp theo
```

**Cursor Automations (ba bước):**

1. **Generate plan** — status → **`Plan`**: báo Linear đã bắt đầu; chạy **`ce-plan`**; kiểm tra plan đã tồn tại; nếu có PR/MR chứa plan thì kiểm tra/resolve conflict với `main`, auto-merge PR vào nhánh chính (`main`), và gắn URL PR/MR vào Linear; **sau khi** plan đã gắn Linear và PR của plan đã merge (nếu có) thì đổi status → **`In Progress`** (kích hoạt Implement).
2. **Implement** — status → **`In Progress`**: báo Linear đã bắt đầu; kiểm tra trên Git provider (GitHub/GitLab) và trên Linear xem plan của task / PR của plan đã được merge chưa — nếu chưa thì **stop**, chuyển status issue trên Linear về **`Todo`** và comment Linear nêu rõ lý do; nếu đã merge thì chạy **`ce-work`** theo plan gắn issue; nếu có PR/MR thì kiểm tra/resolve conflict với `main`, auto-merge PR vào nhánh chính (`main`), và gắn URL PR/MR vào Linear; đổi status → **`In Review`** khi xong.
3. **Compound** — status → **`Compound`**: chạy **`ce-compound`** để ghi lại learning/DOX của issue vừa đóng vòng; nếu có thay đổi thì bắt buộc tạo pull/merge request, kiểm tra/resolve conflict với `main`, auto-merge PR vào nhánh chính (`main`), và gắn URL PR/MR vào Linear; kiểm tra nhánh tạo lúc **`ce-work`** đã merge chưa — nếu đã merge thì **clean branches**; sau khi merge PR của ce-compound (hoặc ngay nếu không có thay đổi) đổi status → **`Done`**.

**Quy tắc chung — gắn URL PR/MR (bắt buộc):** bất kỳ bước nào tạo pull/merge request (dù là `ce-plan`, `ce-work`, automation, hay chạy tay) đều **phải** gắn URL PR/MR đó vào issue Linear liên quan ngay khi tạo — không chờ tới bước tổng kết mới gắn.

**Sau khi `ce-plan` xong** (manual hoặc automation), nếu có PR tạo bởi bước lập kế hoạch thì agent **phải auto-merge PR của plan vào `main`**, comment Linear theo **Thông báo hoàn thành của agent**, rồi **đổi status → `In Progress`** — xem **Quy trình vòng sau `ce-plan`**. Ưu tiên bám plan do automation tạo; không mở đường lập kế hoạch song song.

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

Khi skill **`ce-plan`** (hoặc Cursor Automation chạy `ce-plan` sau status → `Plan`) **đã tạo/cập nhật plan** dưới `docs/plans/`, agent **không** dừng ở Cursor chat. Báo cáo lập kế hoạch và auto-merge PR plan là một phần của “xong plan”:

1. **Plan ↔ Linear** — đảm bảo đường dẫn plan đã ghi vào mô tả issue Linear và frontmatter/section plan có `linear_issues:` (xem **Plan ↔ Linear** bên dưới).
2. **Auto-merge PR của plan** — nếu bước `ce-plan` tạo PR/MR chứa file plan (hoặc commit trên branch riêng), agent **bắt buộc tự động merge (auto-merge)** pull/merge request đó vào nhánh chính (`main`) sau khi kiểm tra không có conflict, và gắn URL PR/MR vào Linear.
3. **Thông báo** — chạy **Thông báo hoàn thành của agent** (comment Linear): plan nào vừa tạo/cập nhật (path), issue Linear liên quan, trạng thái merge PR của plan, tóm tắt hướng triển khai / bước tiếp (status → `In Progress` → Implement / `ce-work`).
4. **Status → In Progress** — sau khi đã gắn plan↔Linear, auto-merge PR của plan (nếu có), và comment Linear: `save_issue` → **`In Progress`**. Đổi status **sau** merge để Implement không bị stop về `Todo`. Status → `In Progress` kích hoạt automation **Implement** (`ce-work`).

Không chỉ nhắc trong Cursor chat. Áp dụng cả khi `ce-plan` chạy thủ công lẫn qua automation.

### Quy trình vòng `ce-work` (bắt buộc)

1. **Kiểm tra điều kiện tiên quyết (trước khi triển khai):**
   - Khi bắt đầu công đoạn `ce-work` (hoặc Cursor Automation **Implement** sau khi issue chuyển status → `In Progress`), agent **bắt buộc kiểm tra trên Git provider (GitHub/GitLab) và trên Linear** xem plan của task đã được merge chưa (PR/MR chứa plan đã merge vào nhánh chính chưa).
   - **Nếu plan / PR của plan chưa được merge:** agent **phải dừng lại (`stop`)**, chuyển status của issue trên Linear về **`Todo`** (`save_issue` → `Todo`), và gửi comment tiếng Việt trên Linear nêu rõ PR của plan chưa được merge, cần merge trước khi chuyển sang `In Progress`.
   - **Nếu plan / PR của plan đã merge:** tiếp tục các bước triển khai theo plan gắn issue.

2. **Khi đã kiểm chứng và hoàn tất phạm vi plan:**
   - **Plan (`docs/plans/…`)** — đánh dấu **Definition of Done** (và checkbox unit liên quan nếu có) thành `[x]` khi đã có bằng chứng (build/smoke/commit). Thêm ghi chú smoke/verify ngắn nếu plan còn chỗ trống. *Trong lúc* `ce-work`, vẫn không dùng plan làm task tracker giữa chừng; *sau khi* hoàn tất, **phải** tick DoD — đóng vòng repo này ghi đè hướng dẫn skill chung “đừng sửa thân plan”.
   - **Auto-merge PR của `ce-work`** — nếu bước `ce-work` tạo PR/MR (hoặc commit trên branch riêng), agent **bắt buộc tự động merge (auto-merge)** pull/merge request đó vào nhánh chính (`main`) sau khi kiểm tra không có conflict, và gắn URL PR/MR vào Linear.
   - **Linear (automation Implement)** — gắn URL PR/MR vào issue; `save_issue` → **`In Review`** (không nhảy thẳng Compound). `save_comment` tiếng Việt: đã ship gì, link PR/MR, trạng thái auto-merge, chờ review/đóng vòng.
   - **Đóng vòng sau review** — khi PR/MR đã merge / owner duyệt xong: `save_issue` → **`Compound`** + comment. **Không** chỉ nhờ owner tự đóng issue nếu agent đang ở session đóng vòng. Status → `Compound` sẽ tự kích hoạt automation **Compound** (chạy `ce-compound`) — agent không cần tự chạy `ce-compound` tay trong session này.
   - **Thông báo** — chạy **Thông báo hoàn thành của agent** (comment Linear) sau khi tạo PR/MR, auto-merge và chuyển `In Review` (và sau khi chuyển `Compound` nếu có).

Cũng áp dụng khi plan đã ship ở session trước nhưng DoD/Linear còn mở: nếu agent thấy lệch, hoàn tất đóng vòng — không để Backlog + checkbox trống.

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
- **Status → Plan → plan:** owner chuyển issue sang **`Plan`** → automation **Generate plan** chạy **`ce-plan`**; nếu có PR/MR chứa plan thì resolve conflict, auto-merge vào `main`, và gắn URL PR/MR vào Linear; comment Linear; đổi status → **`In Progress`**. Xem **Quy trình vòng sau `ce-plan`**.
- **Status → In Progress → implement:** khi issue vào **`In Progress`** (Generate plan vừa xong, hoặc owner chuyển tay) → automation **Implement** kiểm tra trên Git provider (GitHub/GitLab) và Linear xem plan / PR của plan đã merge chưa — nếu chưa thì **stop**, chuyển status về **`Todo`** và comment; nếu đã merge thì chạy **`ce-work`** theo plan gắn issue; nếu có PR/MR thì resolve conflict, auto-merge vào `main`, và gắn URL PR/MR vào Linear; status → **`In Review`**.
- **Status → Compound → compound:** khi issue chuyển **`Compound`** (agent hoặc owner đóng vòng), automation **Compound** tự chạy **`ce-compound`** để đúc kết learning/DOX; nếu có thay đổi thì tạo PR/MR, kiểm tra/resolve conflict, auto-merge vào `main`, và gắn URL vào Linear; kiểm tra nhánh tạo lúc **`ce-work`** đã merge chưa — nếu đã merge thì **clean branches**; sau khi merge PR của ce-compound (hoặc ngay nếu không có thay đổi) đổi status → **`Done`**; agent **không** cần tự chạy tay bước này nữa.
- **Plan ↔ Linear (bắt buộc):** khi plan gắn issue Linear, ghi đường dẫn plan tương đối vào mô tả issue (ví dụ `docs/plans/feature-x.md`). Nhiều plan: mỗi path một dòng. Đổi tên/di chuyển/xóa plan thì cập nhật mọi Linear issue liên quan. Frontmatter / section của plan phải liệt kê `linear_issues:` (URL/ID issue) chiều ngược lại.
- Sau khi review xong (issue **`In Review`** / PR merged): agent hoặc owner đóng vòng → **`Compound`** + comment — xem **Quy trình vòng `ce-work`**. Automation Implement chỉ đưa tới **In Review**, không tự Compound.

### Tùy chọn: gắn Cursor `/loop` sau

Khi vòng thủ công đã ổn:

```text
/loop <interval> Chọn Linear issue mở ưu tiên cao nhất trong project REPLACE_LINEAR_PROJECT_NAME
(ưu tiên In Progress, rồi ưu tiên cao). Nếu chưa có plan thì chạy ce-plan (hoặc chờ
Cursor Automation sau Plan) rồi comment Linear cho owner và chuyển In Progress; nếu có plan thì kiểm tra plan/PR đã merge chưa (nếu chưa thì chuyển Todo; nếu đã merge thì ce-work). Kiểm chứng. Chạy đóng vòng
(DoD + Linear Compound + comment Linear cho owner).
Dừng khi BLOCKED / NEEDS_HUMAN_DECISION.
```

Không auto-merge sớm. Ưu tiên một vòng giao tính năng ổn định trước multi-agent graph.

### Checklist REPLACE (điền trước khi dán sang repo khác)

| Placeholder | Ví dụ |
|-------------|--------|
| `REPLACE_LINEAR_OWNER_DISPLAY_NAME` | `your-display-name` |
| `REPLACE_LINEAR_WORKSPACE` | `your-workspace` |
| `REPLACE_LINEAR_PROJECT_NAME` | `Your Project` |
| `REPLACE_LINEAR_PROJECT_URL` | `https://linear.app/your-workspace/project/your-project-id/overview` |
| `REPLACE_LINEAR_PROJECT_ID` | `your-project-id` |
