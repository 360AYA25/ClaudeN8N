# n8n API via curl (Bug #7296 Workaround)

**Problem:** MCP tools not available in `general-purpose` agents
**Solution:** Use Bash + curl for all n8n API operations

## Setup

```bash
N8N_URL="https://n8n.srv1068954.hstgr.cloud"
API_KEY="eyJhbGc...Q.L0Gh...q5cA"
```

## Common Operations

### List Workflows
```bash
curl -s "$N8N_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $API_KEY"
```

### Get Workflow
```bash
curl -s "$N8N_URL/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: $API_KEY"
```

### Update Workflow
```bash
curl -s -X PUT "$N8N_URL/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflow.json
```

### Get Executions
```bash
curl -s "$N8N_URL/api/v1/executions?workflowId={id}&limit=10" \
  -H "X-N8N-API-KEY: $API_KEY"
```

### Activate Workflow
```bash
curl -s -X PATCH "$N8N_URL/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"active": true}'
```

## Read from .mcp.json

```bash
N8N_URL=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_URL' .mcp.json)
API_KEY=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_KEY' .mcp.json)
```
