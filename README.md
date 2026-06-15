# MCP Jira Sotatek

Kết nối Claude với Jira nội bộ để đọc, tạo, sửa, xóa ticket ngay trong Claude.

## Yêu cầu

- [Node.js >= 18](https://nodejs.org)
- Claude Desktop

## Cài đặt

### Cách 1 — Chạy 1 lệnh (không cần clone repo)

Mở PowerShell, chạy:

```powershell
irm https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/main/setup.ps1 | iex
```

### Cách 2 — Chạy local (đã clone/copy folder về máy)

**Right-click** vào file `setup.ps1` → **"Run with PowerShell"**

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

## Ví dụ

> "Đọc ticket MPHBC-447"

> "Tìm tất cả bug đang open assign cho tôi"

> "Tạo task mới trong project MPHBC: Fix login page"
