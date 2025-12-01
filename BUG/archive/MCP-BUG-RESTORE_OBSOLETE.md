# ⚠️ OBSOLETE - Bug Fixed in v2.27.0

**This workaround is NO LONGER NEEDED.**

n8n-mcp Zod bug was fixed on 2025-11-28 in version 2.27.0.
All MCP write operations are now working normally.

**See:** [BUG/ZodBUG.md](../ZodBUG.md) for current status.

---

# MCP Bug Restore Guide

> When n8n-mcp Zod v4 bug (#444, #447) is fixed, follow this guide to restore normal MCP operations.

## Bug Status Check

```bash
# Check n8n-mcp version (bug should be fixed in version > 2.26.5)
npx n8n-mcp --version

# Test if create_workflow works
# If it returns workflow (not Zod error) → bug is fixed!
```

## Files Modified (need restore)

| File | Status | What Changed |
|------|--------|--------------|
| `.claude/agents/builder.md` | MODIFIED | Added curl workaround |
| `.claude/agents/qa.md` | MODIFIED | Added curl for activation |
| `.claude/agents/researcher.md` | MINOR | Added status table |
| `.claude/agents/analyst.md` | MINOR | Added status table |
| `.claude/CLAUDE.md` | MODIFIED | Added bug notice |

---

## Restore Instructions

### 1. builder.md — Remove curl Workaround

**REMOVE this section:**
```markdown
## ⚠️ CRITICAL: MCP Bug Workaround (Zod v4 #444, #447)
... entire section about curl ...
```

**RESTORE MCP calls:**
```javascript
// Instead of curl, use:
mcp__n8n-mcp__n8n_create_workflow({
  name: "...",
  nodes: [...],
  connections: {...}
})

mcp__n8n-mcp__n8n_update_full_workflow({
  id: "...",
  nodes: [...],
  connections: {...}
})

mcp__n8n-mcp__n8n_update_partial_workflow({
  id: "...",
  operations: [...]
})

mcp__n8n-mcp__n8n_autofix_workflow({
  id: "...",
  applyFixes: true  // Can use true again!
})
```

### 2. qa.md — Restore MCP Activation

**REMOVE curl activation:**
```bash
# Remove this:
curl -s -X PATCH "${N8N_API_URL}/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -d '{"active": true}'
```

**RESTORE MCP activation:**
```javascript
mcp__n8n-mcp__n8n_update_partial_workflow({
  id: workflow_id,
  operations: [{
    type: "activateWorkflow"
  }]
})
```

### 3. Remove MCP Status Tables

**FROM all agent files, remove:**
```markdown
## MCP Tools Status (Bug #444, #447)
| Tool | Status |
...
```

### 4. CLAUDE.md — Remove Bug Notice

**REMOVE:**
```markdown
## ⚠️ MCP Bug Notice
...
```

---

## Original Tool Usage (Normal Mode)

### Builder (ONLY agent that mutates)
```javascript
// Create new workflow
n8n_create_workflow({ name, nodes, connections })

// Update entire workflow
n8n_update_full_workflow({ id, nodes, connections })

// Incremental updates
n8n_update_partial_workflow({ id, operations: [
  { type: "addNode", node: {...} },
  { type: "updateNode", nodeId: "...", changes: {...} },
  { type: "addConnection", connection: {...} }
]})

// Auto-fix with apply
n8n_autofix_workflow({ id, applyFixes: true })

// Rollback
n8n_workflow_versions({ mode: "rollback", workflowId: "..." })
```

### QA
```javascript
// Activate (via MCP)
n8n_update_partial_workflow({
  id: "...",
  operations: [{ type: "activateWorkflow" }]
})

// Deactivate
n8n_update_partial_workflow({
  id: "...",
  operations: [{ type: "deactivateWorkflow" }]
})
```

---

## Quick Test After Fix

```javascript
// 1. Create test workflow
const result = await mcp__n8n-mcp__n8n_create_workflow({
  name: "Test Bug Fix",
  nodes: [{
    id: "trigger",
    name: "Manual Trigger",
    type: "n8n-nodes-base.manualTrigger",
    typeVersion: 1,
    position: [250, 300],
    parameters: {}
  }],
  connections: {}
});

// 2. If result.id exists → BUG IS FIXED!
console.log(result.id ? "✅ Bug fixed!" : "❌ Still broken");

// 3. Cleanup
await mcp__n8n-mcp__n8n_delete_workflow({ id: result.id });
```

---

## Version History

| Date | n8n-mcp Version | Status |
|------|-----------------|--------|
| 2024-XX-XX | 2.26.5 | Bug present |
| TBD | ?.?.? | Bug fixed |

---

## 🔄 IMPORTANT: Add Fallback System After Restore!

После восстановления MCP — **ДОБАВЬ fallback систему** чтобы в будущем подобные баги не ломали всю систему.

### Зачем Fallback?

Текущий подход (hard switch на curl) требует ручного восстановления.
Fallback автоматически переключится на curl если MCP сломается снова.

### Что добавить в Builder

**В секцию "Verification Protocol" добавить:**

```javascript
// === MCP with Fallback to curl ===

async function createWorkflowWithFallback(workflowJson) {
  // Step 1: Try MCP first
  try {
    const result = await mcp__n8n-mcp__n8n_create_workflow(workflowJson);
    if (result && result.id) {
      console.log("✅ MCP create_workflow succeeded");
      return result;
    }
  } catch (error) {
    console.log("⚠️ MCP failed:", error.message);
  }

  // Step 2: Fallback to curl
  console.log("🔄 Falling back to curl...");

  const N8N_API_URL = getEnvFromMcpJson("N8N_API_URL");
  const N8N_API_KEY = getEnvFromMcpJson("N8N_API_KEY");

  const response = await fetch(`${N8N_API_URL}/api/v1/workflows`, {
    method: "POST",
    headers: {
      "X-N8N-API-KEY": N8N_API_KEY,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(workflowJson)
  });

  const result = await response.json();

  if (!result.id) {
    throw new Error("Both MCP and curl failed!");
  }

  console.log("✅ curl fallback succeeded");
  return result;
}

async function updateWorkflowWithFallback(id, workflowJson) {
  // Step 1: Try MCP first
  try {
    const result = await mcp__n8n-mcp__n8n_update_full_workflow({ id, ...workflowJson });
    if (result && result.id) {
      console.log("✅ MCP update_workflow succeeded");
      return result;
    }
  } catch (error) {
    console.log("⚠️ MCP failed:", error.message);
  }

  // Step 2: Fallback to curl
  console.log("🔄 Falling back to curl...");

  const N8N_API_URL = getEnvFromMcpJson("N8N_API_URL");
  const N8N_API_KEY = getEnvFromMcpJson("N8N_API_KEY");

  const response = await fetch(`${N8N_API_URL}/api/v1/workflows/${id}`, {
    method: "PATCH",
    headers: {
      "X-N8N-API-KEY": N8N_API_KEY,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(workflowJson)
  });

  return await response.json();
}

// Helper to read from .mcp.json
function getEnvFromMcpJson(key) {
  const mcpConfig = JSON.parse(fs.readFileSync(".mcp.json", "utf8"));
  return mcpConfig.mcpServers["n8n-mcp"].env[key];
}
```

### Что добавить в QA

**В секцию "Activation" добавить:**

```javascript
async function activateWorkflowWithFallback(workflowId) {
  // Step 1: Try MCP first
  try {
    const result = await mcp__n8n-mcp__n8n_update_partial_workflow({
      id: workflowId,
      operations: [{ type: "activateWorkflow" }]
    });
    if (result) {
      console.log("✅ MCP activation succeeded");
      return result;
    }
  } catch (error) {
    console.log("⚠️ MCP failed:", error.message);
  }

  // Step 2: Fallback to curl
  console.log("🔄 Falling back to curl...");

  const N8N_API_URL = getEnvFromMcpJson("N8N_API_URL");
  const N8N_API_KEY = getEnvFromMcpJson("N8N_API_KEY");

  const response = await fetch(`${N8N_API_URL}/api/v1/workflows/${workflowId}`, {
    method: "PATCH",
    headers: {
      "X-N8N-API-KEY": N8N_API_KEY,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ active: true })
  });

  return await response.json();
}
```

### Принцип Fallback

```
┌─────────────────────────────────────────────────┐
│  1. Попробовать MCP tool                        │
│     ↓                                           │
│  2. Если успех → вернуть результат              │
│     ↓                                           │
│  3. Если ошибка → логировать + fallback to curl │
│     ↓                                           │
│  4. curl запрос напрямую к n8n API              │
│     ↓                                           │
│  5. Вернуть результат или throw error           │
└─────────────────────────────────────────────────┘
```

### Преимущества Fallback

| Аспект | Без Fallback | С Fallback |
|--------|--------------|------------|
| При новом баге | Ручной фикс всех агентов | Автоматически работает |
| При исправлении | Ручной restore | Автоматически MCP |
| Токены | Экономнее | +500 токенов при ошибке |
| Латентность | Быстрее | +2 сек при ошибке |

### Итого: Задачи для бота при восстановлении

1. ✅ Убрать curl-only workaround из агентов
2. ✅ Восстановить MCP calls
3. ⭐ **ДОБАВИТЬ fallback функции** (см. код выше)
4. ✅ Обновить документацию

---

## Links

- Bug Issue: https://github.com/n8n-io/n8n/issues/444
- Bug Issue: https://github.com/n8n-io/n8n/issues/447
- n8n-mcp: https://www.npmjs.com/package/n8n-mcp
