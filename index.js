#!/usr/bin/env node
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');

const BASE_URL = process.env.JIRA_BASE_URL;
const TOKEN = process.env.JIRA_TOKEN;

if (!BASE_URL || !TOKEN) {
  console.error('Missing JIRA_BASE_URL or JIRA_TOKEN');
  process.exit(1);
}

const jira = axios.create({
  baseURL: `${BASE_URL}/rest/api/2`,
  headers: {
    Authorization: `Bearer ${TOKEN}`,
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

const server = new Server(
  { name: 'jira-server', version: '1.0.0' },
  { capabilities: { tools: {} } },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'read_issue',
      description: 'Đọc thông tin chi tiết một Jira issue',
      inputSchema: {
        type: 'object',
        properties: {
          issueKey: { type: 'string', description: 'VD: MPHBC-447' },
        },
        required: ['issueKey'],
      },
    },
    {
      name: 'create_issue',
      description: 'Tạo mới một Jira issue',
      inputSchema: {
        type: 'object',
        properties: {
          projectKey: { type: 'string', description: 'VD: MPHBC' },
          summary: { type: 'string', description: 'Tiêu đề issue' },
          description: { type: 'string', description: 'Mô tả issue' },
          issueType: { type: 'string', description: 'Bug, Task, Story...', default: 'Task' },
        },
        required: ['projectKey', 'summary'],
      },
    },
    {
      name: 'update_issue',
      description: 'Cập nhật thông tin một Jira issue',
      inputSchema: {
        type: 'object',
        properties: {
          issueKey: { type: 'string', description: 'VD: MPHBC-447' },
          summary: { type: 'string', description: 'Tiêu đề mới' },
          description: { type: 'string', description: 'Mô tả mới' },
        },
        required: ['issueKey'],
      },
    },
    {
      name: 'delete_issue',
      description: 'Xóa một Jira issue',
      inputSchema: {
        type: 'object',
        properties: {
          issueKey: { type: 'string', description: 'VD: MPHBC-447' },
        },
        required: ['issueKey'],
      },
    },
    {
      name: 'add_comment',
      description: 'Thêm comment vào một Jira issue',
      inputSchema: {
        type: 'object',
        properties: {
          issueKey: { type: 'string', description: 'VD: MPHBC-447' },
          comment: { type: 'string', description: 'Nội dung comment' },
        },
        required: ['issueKey', 'comment'],
      },
    },
    {
      name: 'search_issues',
      description: 'Tìm kiếm issues bằng JQL',
      inputSchema: {
        type: 'object',
        properties: {
          jql: { type: 'string', description: 'VD: project=MPHBC AND status=Open' },
          maxResults: { type: 'number', default: 10 },
        },
        required: ['jql'],
      },
    },
    {
      name: 'get_attachment',
      description: 'Download ảnh/file đính kèm trong Jira issue để xem nội dung',
      inputSchema: {
        type: 'object',
        properties: {
          attachmentId: { type: 'string', description: 'ID của attachment (lấy từ read_issue)' },
        },
        required: ['attachmentId'],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === 'read_issue') {
      const { data } = await jira.get(`/issue/${args.issueKey}`);
      const f = data.fields;
      const attachments = (f.attachment || []).map((a) => ({
        id: a.id,
        filename: a.filename,
        mimeType: a.mimeType,
        size: a.size,
        created: a.created,
        author: a.author?.displayName,
      }));
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            key: data.key,
            summary: f.summary,
            status: f.status?.name,
            assignee: f.assignee?.displayName,
            reporter: f.reporter?.displayName,
            priority: f.priority?.name,
            issueType: f.issuetype?.name,
            description: f.description,
            created: f.created,
            updated: f.updated,
            url: `${BASE_URL}/browse/${data.key}`,
            attachments,
          }, null, 2),
        }],
      };
    }

    if (name === 'create_issue') {
      const { data } = await jira.post('/issue', {
        fields: {
          project: { key: args.projectKey },
          summary: args.summary,
          description: args.description || '',
          issuetype: { name: args.issueType || 'Task' },
        },
      });
      return {
        content: [{
          type: 'text',
          text: `Tạo thành công: ${data.key}\nURL: ${BASE_URL}/browse/${data.key}`,
        }],
      };
    }

    if (name === 'update_issue') {
      const fields = {};
      if (args.summary) fields.summary = args.summary;
      if (args.description) fields.description = args.description;
      await jira.put(`/issue/${args.issueKey}`, { fields });
      return {
        content: [{ type: 'text', text: `Cập nhật ${args.issueKey} thành công.` }],
      };
    }

    if (name === 'delete_issue') {
      await jira.delete(`/issue/${args.issueKey}`);
      return {
        content: [{ type: 'text', text: `Đã xóa ${args.issueKey}.` }],
      };
    }

    if (name === 'add_comment') {
      await jira.post(`/issue/${args.issueKey}/comment`, { body: args.comment });
      return {
        content: [{ type: 'text', text: `Đã thêm comment vào ${args.issueKey}.` }],
      };
    }

    if (name === 'search_issues') {
      const { data } = await jira.get('/search', {
        params: { jql: args.jql, maxResults: args.maxResults || 10 },
      });
      const issues = data.issues.map((i) => ({
        key: i.key,
        summary: i.fields.summary,
        status: i.fields.status?.name,
        assignee: i.fields.assignee?.displayName,
        url: `${BASE_URL}/browse/${i.key}`,
      }));
      return {
        content: [{ type: 'text', text: JSON.stringify(issues, null, 2) }],
      };
    }

    if (name === 'get_attachment') {
      const { data: meta } = await jira.get(`/attachment/${args.attachmentId}`);
      const response = await axios.get(meta.content, {
        headers: { Authorization: `Bearer ${TOKEN}` },
        responseType: 'arraybuffer',
      });
      const base64 = Buffer.from(response.data).toString('base64');
      const mimeType = meta.mimeType || 'application/octet-stream';
      const isImage = mimeType.startsWith('image/');
      if (isImage) {
        return {
          content: [
            { type: 'text', text: `Attachment: ${meta.filename} (${mimeType})` },
            { type: 'image', data: base64, mimeType },
          ],
        };
      }
      return {
        content: [{
          type: 'text',
          text: `Attachment: ${meta.filename} (${mimeType}, ${meta.size} bytes) — không phải ảnh, không thể xem trực tiếp.`,
        }],
      };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (err) {
    const msg = err.response?.data?.errorMessages?.join(', ') || err.response?.data?.message || err.message;
    return {
      content: [{ type: 'text', text: `Lỗi: ${msg}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main();
