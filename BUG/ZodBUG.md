# MCP Bug Tracker

## CRITICAL: n8n-mcp Workflow Write Operations BROKEN

**Status:** BLOCKING
**Severity:** Critical
**Discovered:** 2025-11-27
**Affects:** n8n-mcp v2.26.4, v2.26.5

---

## The Bug

All MCP tools that CREATE or UPDATE workflows fail with Zod validation error:

```
Cannot read properties of undefined (reading '_zod')
```

### Broken Tools

| Tool | Status | Notes |
|------|--------|-------|
| `n8n_create_workflow` | BROKEN | Main Builder tool |
| `n8n_update_full_workflow` | BROKEN | |
| `n8n_update_partial_workflow` | BROKEN | |
| `n8n_autofix_workflow` (applyFixes=true) | BROKEN | Preview works! |
| `n8n_workflow_versions` (rollback) | BROKEN | |

### Working Tools

All read-only tools work fine:
- `search_nodes`, `get_node`, `validate_node`
- `search_templates`, `get_template`
- `n8n_list_workflows`, `n8n_get_workflow`
- `n8n_validate_workflow`, `n8n_health_check`
- `n8n_executions`
- `n8n_delete_workflow`
- `n8n_trigger_webhook_workflow`

---

## GitHub Issues to Monitor

### Primary Issue
**URL:** https://github.com/czlonkowski/n8n-mcp/issues/444
**Title:** Cannot read properties of undefined (reading '_zod')
**Root Cause:** Zod v4 API incompatibility in MCP server validation

### Related Issues
- https://github.com/czlonkowski/n8n-mcp/issues/447 (duplicate)

---

## How to Check if Fixed

### Quick Test
```javascript
// Try creating minimal workflow via MCP:
mcp__n8n-mcp__n8n_create_workflow({
  name: "Test Bug Fix",
  nodes: [{
    id: "start",
    name: "Start",
    type: "n8n-nodes-base.manualTrigger",
    typeVersion: 1,
    position: [0, 0],
    parameters: {}
  }],
  connections: {}
})
```

**If returns workflow ID** → Bug is FIXED
**If returns `_zod` error** → Still broken

### Manual Check
1. Go to https://github.com/czlonkowski/n8n-mcp/issues/444
2. Check if status is "Closed"
3. Check latest release notes for fix mention
4. Check npm for newer version: `npm view n8n-mcp versions`

---

## Workaround: Direct n8n API

Until MCP is fixed, use curl to create/update workflows:

### Create Workflow
```bash
curl -X POST "https://n8n.srv1068954.hstgr.cloud/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Workflow Name",
    "nodes": [...],
    "connections": {},
    "settings": {"executionOrder": "v1"}
  }'
```

### Update Workflow
```bash
curl -X PATCH "https://n8n.srv1068954.hstgr.cloud/api/v1/workflows/{WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "nodes": [...],
    "connections": {}
  }'
```

### Activate Workflow
```bash
curl -X PATCH "https://n8n.srv1068954.hstgr.cloud/api/v1/workflows/{WORKFLOW_ID}/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

---

## Environment

```
N8N_API_URL: https://n8n.srv1068954.hstgr.cloud
MCP_VERSION: 2.26.5 (in .mcp.json)
```

---

## Action Items for Next Session

1. **Check issue status** at GitHub link above
2. **If new version released:**
   - Update `.mcp.json`: change `n8n-mcp@2.26.5` to new version
   - Restart Claude Code
   - Run quick test above
3. **If still broken:**
   - Use curl workaround for Builder agent
   - Or wait for fix

---

## History

| Date | Version | Status |
|------|---------|--------|
| 2025-11-27 | 2.26.4 | Discovered bug |
| 2025-11-27 | 2.26.5 | Updated, still broken |
