# MCP Jira Sotatek

Kết nối Claude với Jira nội bộ để đọc, tạo, sửa, xóa ticket ngay trong Claude.

## Yêu cầu

- [Node.js >= 18](https://nodejs.org)
- Claude Desktop

## Cài đặt

### Cách 1 — Chạy 1 lệnh (không cần clone repo)

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master/setup.ps1 | iex
```

**macOS / Linux (bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master/setup.sh | bash
```

### Cách 2 — Chạy local (đã clone/copy folder về máy)

- Windows: **Right-click** vào file `setup.ps1` → **"Run with PowerShell"**
- macOS/Linux: `chmod +x setup.sh && ./setup.sh`

---

Cả hai cách đều hỏi Jira Personal Access Token, tự cập nhật config Claude và cài dependencies.

Lấy token tại: `https://projects.plan-task.dev` → Avatar → **Profile** → **Personal Access Tokens** → **Create token**

Sau khi setup xong: **Restart Claude Desktop** là dùng được.

---

## Các tool có sẵn

| Tool | Mô tả |
|---|---|
| `read_issue` | Đọc chi tiết ticket (kèm danh sách ảnh đính kèm) |
| `get_attachment` | Xem ảnh đính kèm trong ticket |
| `create_issue` | Tạo ticket mới |
| `update_issue` | Cập nhật title/description |
| `delete_issue` | Xóa ticket |
| `add_comment` | Thêm comment |
| `search_issues` | Tìm kiếm bằng JQL |
| `get_transitions` | Lấy danh sách transitions (chuyển status) khả dụng của 1 ticket |
| `transition_issue` | Chuyển status ticket (VD: Open → In Progress) theo id hoặc tên transition |

## Skills

| Skill | Mô tả |
|---|---|
| `fix-open-issues` | Fetch ticket Jira đang mở của bạn, phân loại theo độ khó, hiển thị tóm tắt và tự fix code theo lựa chọn. Tự cài vào `.claude/skills/` của project khi chạy script trong project đó. |

## Ví dụ

> "Đọc ticket MPHBC-447"

> "Tìm tất cả bug đang open assign cho tôi"

> "Tạo task mới trong project MPHBC: Fix login page"
