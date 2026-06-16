---
name: fix-open-issues
description: Fetches the user's open Jira issues, categorizes them by effort (quick wins / FE-only / needs BE / needs clarification), shows a visual summary with action options, then implements the chosen fixes directly in the codebase. Use this skill whenever the user wants to tackle their Jira backlog, asks "fix my open issues", "what should I work on?", "làm ticket", "fix ticket", or wants to work through pending issues. ALWAYS trigger this skill when the user mentions fixing open Jira issues, even if phrased casually.
---

# Fix Open Issues

Workflow: fetch → categorize → present options → implement.

## Step 1: Fetch open issues

Use `mcp__jira__search_issues` with JQL:
```
assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC
```
`maxResults`: 30. If the tool is unavailable, tell the user to install the Jira MCP first.

## Step 2: Read issue details

Use `mcp__jira__read_issue` for each issue to get the full description. Limit to the 25 most recently updated issues to avoid overloading context.

## Step 3: Categorize

Assign each issue to one of four groups:

### Group A — Quick wins (low effort, parallelizable)
- Text/label/typo fixes
- Config, constant, or color value changes
- Simple CSS/styling tweaks
- Obvious null checks
- Criteria: fix is < ~15 lines, minimal context needed

### Group B — FE-only (medium effort, frontend changes only)
- Logic bugs in React components
- Form validation, error handling
- State management, routing issues
- Wrong display due to FE mishandling API data (no API change needed)
- Criteria: requires reading code, but no backend changes needed

### Group C — Needs BE (large effort, backend must be updated)
- Missing or incorrect API endpoints
- Data model or server-side business logic changes
- Permission/auth issues on the backend
- Criteria: FE cannot fix this alone

### Group D — Needs clarification
- The issue description is vague, missing reproduction steps, or lacks enough context to determine the fix
- The title alone doesn't clearly map to a known component or screen
- It's unclear whether the root cause is FE or BE
- Criteria: you genuinely cannot make a confident categorization or plan a fix without asking the user first

**Tie-breaking rules:**
- Unsure between A and B → if fix is likely < 15 lines, pick A
- Unsure between B and C → if FE can work around it without BE changes, pick B
- Unsure about anything else → pick D

## Step 4: Display summary and options

First call `mcp__visualize__read_me` (if not already called), then use `mcp__visualize__show_widget` to show:

1. **Summary table** grouped by A / B / C / D, each row: key, title, group.
   - Group D issues should include a short note on what's unclear.
2. **Action options**:
   - Button "Fix A + B" — fix all quick wins and FE-only issues
   - Button "Fix A only" — fix only quick wins
   - Text input + "Custom" button — user types custom instructions

Use `sendPrompt(text)` to send the user's choice back to chat.

Example widget structure:
```html
<!-- Summary table -->
<table>...</table>

<!-- Options -->
<button onclick="sendPrompt('Fix A + B')">Fix A + B</button>
<button onclick="sendPrompt('Fix A only')">Fix A only</button>
<input id="custom" type="text" placeholder="Describe what you want Claude to do...">
<button onclick="sendPrompt('Custom: ' + document.getElementById('custom').value)">Custom</button>
```

## Step 5: Implement fixes

Based on the user's choice:

**"Fix A + B"**: implement all Group A and B issues  
**"Fix A only"**: implement Group A only  
**"Custom: ..."**: follow the user's instructions  

For each issue to fix:
1. Re-read full details with `mcp__jira__read_issue` if description wasn't loaded
2. Use `mcp__jira__transition_issue` to transition the issue status to **IN PROGRESS** before touching any code
3. Find relevant files using `Grep` / `Glob` based on component name, screen name, or keywords from the title
4. Read enough code context to understand the problem
5. Implement the fix with `Edit`

For step 2, use `mcp__jira__transition_issue` with `transitionName: "in progress"` (case-insensitive). Do NOT use `mcp__jira__update_issue` for status changes — it silently reports success without actually transitioning the issue. After calling `transition_issue`, verify with `mcp__jira__read_issue` that `status` actually changed before moving on.

Workflow transitions are sequential (e.g. To Do → In Progress → In review) — you generally cannot jump straight from To Do to a later status. Use `mcp__jira__get_transitions` first if unsure which transitions are available from the current status, and step through them in order.

Do NOT add any comments to Jira tickets. Do NOT modify the issue title, description, or any other fields besides the status transition.

**Group A**: fix in parallel when files are independent.  
**Group B**: fix sequentially, read code carefully before editing.

## Step 6: Summary

After completing, list:
- Fixed issues with the files modified
- Group C issues (needs BE) — explain why FE cannot fix them
- Group D issues (needs clarification) — list the specific questions you need answered before proceeding
- Suggested next steps if any
