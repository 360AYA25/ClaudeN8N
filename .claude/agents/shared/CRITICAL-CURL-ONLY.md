# 🚨 CRITICAL: MCP Write Tools BROKEN - Use curl ONLY!

**Updated:** 2025-12-27
**Source:** LEARNINGS.md L-071/L-072 (Zod v4 bug)

---

## Problem

MCP write tools **DO NOT WORK** due to Zod v4 schema validation bug (GitHub #444, #447):

❌ **BROKEN MCP Tools:**
- `mcp__n8n-mcp__n8n_create_workflow` → workflows appear EMPTY in UI!
- `mcp__n8n-mcp__n8n_update_full_workflow` → fails silently
- `mcp__n8n-mcp__n8n_update_partial_workflow` → fails silently
- `mcp__n8n-mcp__n8n_autofix_workflow` (apply mode) → fails

✅ **Working MCP Tools (READ operations):**
- `mcp__n8n-mcp__n8n_get_workflow`
- `mcp__n8n-mcp__n8n_list_workflows`
- `mcp__n8n-mcp__n8n_validate_workflow`
- `mcp__n8n-mcp__n8n_delete_workflow`
- `mcp__n8n-mcp__n8n_executions`

---

## Solution: Use curl POST/PUT Instead

### 1. Load API Credentials

```bash
N8N_API_URL=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_URL')
N8N_API_KEY=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_KEY')
```

### 2. Create Workflow (POST)

```bash
curl -s -X POST "${N8N_API_URL}/api/v1/workflows" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Workflow Name",
    "nodes": [...],
    "connections": {...},
    "settings": {}
  }' | jq '.'
```

**Capture workflow ID:**
```bash
WORKFLOW_ID=$(curl ... | jq -r '.id')
```

### 3. Update Workflow (PUT)

**CRITICAL:** PUT requires **ALL** fields (name, nodes, connections, settings)!

```bash
curl -s -X PUT "${N8N_API_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "nodes": [...],
    "connections": {...},
    "settings": {}
  }' | jq '.'
```

### 4. Activate Workflow (PATCH - lightweight)

```bash
curl -s -X PATCH "${N8N_API_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"active": true}' | jq '.'
```

---

## Critical Details

### A. Connections Use node.name, NOT node.id

```json
{
  "connections": {
    "Webhook Trigger": {  // ✅ CORRECT (node name)
      "main": [[{"node": "Process Data", "type": "main", "index": 0}]]
    }
  }
}
```

❌ **WRONG:**
```json
{
  "connections": {
    "webhook-1": {...}  // node.id won't work!
  }
}
```

### B. PUT Requires ALL Fields

❌ **WRONG:** Missing settings
```json
{"name": "...", "nodes": [...], "connections": {...}}
```

✅ **CORRECT:** All fields present
```json
{"name": "...", "nodes": [...], "connections": {...}, "settings": {}}
```

### C. Start with 3 Nodes Maximum!

Per LEARNINGS.md L-072 (line 2693-2699):

❌ **DON'T:** Create 10+ nodes in one call
✅ **DO:** Start with 3 nodes, verify in UI, then add more incrementally

---

## Builder Implementation Checklist

**BEFORE creating/updating workflow:**

- [ ] Load `N8N_API_URL` and `N8N_API_KEY` from `.mcp.json`
- [ ] Use **curl POST** for new workflows (NOT MCP!)
- [ ] Use **curl PUT** for updates (include `settings: {}`!)
- [ ] Use **curl PATCH** for activation only
- [ ] Start with **3 nodes max** for initial creation
- [ ] Verify via MCP `n8n_get_workflow` (read works!)
- [ ] Capture workflow ID from curl response
- [ ] Log all curl calls in `mcp_calls` array

---

## Example: Create Minimal 3-Node Workflow

```bash
# Load credentials
N8N_API_URL=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_URL')
N8N_API_KEY=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_KEY')

# Create workflow via curl POST
RESULT=$(curl -s -X POST "${N8N_API_URL}/api/v1/workflows" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Workflow",
    "nodes": [
      {
        "id": "webhook-1",
        "name": "Webhook Trigger",
        "type": "n8n-nodes-base.webhook",
        "typeVersion": 2,
        "position": [250, 300],
        "parameters": {
          "path": "test-webhook",
          "httpMethod": "POST",
          "responseMode": "responseNode"
        }
      },
      {
        "id": "code-1",
        "name": "Process Data",
        "type": "n8n-nodes-base.code",
        "typeVersion": 2,
        "position": [450, 300],
        "parameters": {
          "mode": "runOnceForAllItems",
          "jsCode": "return $input.all().map(item => ({json: {...item.json, processed: true}}));"
        }
      },
      {
        "id": "respond-1",
        "name": "Send Response",
        "type": "n8n-nodes-base.respondToWebhook",
        "typeVersion": 1,
        "position": [650, 300],
        "parameters": {
          "respondWith": "json",
          "responseBody": "={{ $json }}"
        }
      }
    ],
    "connections": {
      "Webhook Trigger": {
        "main": [[{"node": "Process Data", "type": "main", "index": 0}]]
      },
      "Process Data": {
        "main": [[{"node": "Send Response", "type": "main", "index": 0}]]
      }
    },
    "settings": {}
  }')

# Capture workflow ID
WORKFLOW_ID=$(echo "$RESULT" | jq -r '.id')

echo "✅ Workflow created: $WORKFLOW_ID"
```

---

## Verification

**ALWAYS verify via MCP after curl operation:**

```bash
# Verification via MCP (read works!)
# Use mcp__n8n-mcp__n8n_get_workflow with mode="structure"
```

---

**Reference:** `/Users/sergey/Projects/ClaudeN8N/docs/learning/LEARNINGS.md` lines 4639-4738
