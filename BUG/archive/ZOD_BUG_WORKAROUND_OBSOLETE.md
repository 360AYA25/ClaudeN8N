# ⚠️ OBSOLETE - Bug Fixed in v2.27.0

**This workaround is NO LONGER NEEDED.**

n8n-mcp Zod bug was fixed on 2025-11-28 in version 2.27.0.
All MCP write operations are now working normally.

**See:** [BUG/ZodBUG.md](../ZodBUG.md) for current status.

---

# n8n-mcp Zod v4 Bug Workaround Guide

> Инструкция для AI: как обходить баг Zod v4 в n8n-mcp

## Проблема

**Bug:** n8n-mcp использует Zod v4 для валидации, но есть баг который ломает все write операции.

**Issues:** #444, #447

**Версия с багом:** n8n-mcp 2.26.5 и ниже

**Симптомы:**
- MCP tools возвращают ошибки типа "Workflow validation failed with structural issues"
- Все операции записи (create, update, autofix apply) не работают
- Операции чтения работают нормально

---

## Диагностика

### Как понять что баг активен:

```javascript
// Попробуй создать простой workflow
const result = await mcp__n8n-mcp__n8n_create_workflow({
  name: "Test",
  nodes: [{
    id: "test",
    name: "Manual Trigger",
    type: "n8n-nodes-base.manualTrigger",
    typeVersion: 1,
    position: [250, 300],
    parameters: {}
  }],
  connections: {}
});

// Если ошибка Zod/validation → баг активен
// Если вернулся workflow с id → баг исправлен
```

---

## Классификация инструментов

### ❌ СЛОМАННЫЕ (не использовать!)

| Tool | Описание | Workaround |
|------|----------|------------|
| `n8n_create_workflow` | Создание workflow | curl POST |
| `n8n_update_full_workflow` | Полное обновление | curl **PUT** (settings!) |
| `n8n_update_partial_workflow` | Частичное обновление | curl **PUT** |
| `n8n_autofix_workflow` (applyFixes: true) | Применение фиксов | Preview + curl PUT |
| `n8n_workflow_versions` (rollback) | Откат версии | curl PUT |

### ⚠️ ВАЖНО: Update использует PUT, не PATCH!
- **POST** — создание нового workflow
- **PUT** — обновление существующего (полная замена, settings ОБЯЗАТЕЛЕН!)
- **PATCH** — только для активации (`{"active": true}`)

### ✅ РАБОТАЮЩИЕ (можно использовать)

| Tool | Описание |
|------|----------|
| `search_nodes` | Поиск нод |
| `get_node` | Документация ноды |
| `search_templates` | Поиск шаблонов |
| `get_template` | Детали шаблона |
| `n8n_list_workflows` | Список workflows |
| `n8n_get_workflow` | Получить workflow |
| `n8n_validate_workflow` | Валидация (статическая) |
| `validate_node` | Валидация ноды |
| `n8n_autofix_workflow` (applyFixes: false) | Превью фиксов |
| `n8n_trigger_webhook_workflow` | Триггер webhook |
| `n8n_executions` | Логи выполнения |
| `n8n_delete_workflow` | Удаление |
| `n8n_health_check` | Проверка API |

---

## Workaround: Direct n8n REST API

### Принцип

**Вместо MCP tools используй прямые curl запросы к n8n API.**

MCP tools используют тот же API, но с багнутой Zod валидацией.
curl обходит эту валидацию и работает напрямую с n8n.

### Шаг 1: Получить credentials

```bash
# Читаем из .mcp.json (там хранятся API ключи)
N8N_API_URL=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_URL')
N8N_API_KEY=$(cat .mcp.json | jq -r '.mcpServers["n8n-mcp"].env.N8N_API_KEY')

# Проверяем что получили
echo "URL: $N8N_API_URL"
echo "KEY: ${N8N_API_KEY:0:20}..."
```

### Шаг 2: Создание workflow

```bash
curl -s -X POST "${N8N_API_URL}/api/v1/workflows" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Workflow",
    "nodes": [
      {
        "id": "trigger-1",
        "name": "Manual Trigger",
        "type": "n8n-nodes-base.manualTrigger",
        "typeVersion": 1,
        "position": [250, 300],
        "parameters": {}
      }
    ],
    "connections": {},
    "settings": {}
  }'
```

### Шаг 3: Обновление workflow (PUT — settings обязателен!)

```bash
curl -s -X PUT "${N8N_API_URL}/api/v1/workflows/{workflow_id}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "nodes": [...],
    "connections": {...},
    "settings": {}
  }'
```

**⚠️ Без settings:{} запрос вернёт ошибку!**

### Шаг 4: Активация workflow

```bash
# Активировать
curl -s -X PATCH "${N8N_API_URL}/api/v1/workflows/{workflow_id}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"active": true}'

# Деактивировать
curl -s -X PATCH "${N8N_API_URL}/api/v1/workflows/{workflow_id}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"active": false}'
```

---

## Workflow JSON Format

### Структура

```json
{
  "name": "Workflow Name",
  "nodes": [
    {
      "id": "unique-string-id",
      "name": "Display Name For UI",
      "type": "n8n-nodes-base.nodeType",
      "typeVersion": 1,
      "position": [x, y],
      "parameters": {
        // node-specific parameters
      },
      "credentials": {
        "credentialType": {
          "id": "credential-id",
          "name": "Credential Name"
        }
      }
    }
  ],
  "connections": {
    "Source Node Name": {
      "main": [
        [
          {
            "node": "Target Node Name",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}
```

### Критические правила

| Поле | Правило |
|------|---------|
| `id` | Уникальный string (uuid или slug) |
| `name` | Display name — **ИСПОЛЬЗУЕТСЯ В CONNECTIONS!** |
| `type` | Полный формат: `n8n-nodes-base.XXX` или `@n8n/n8n-nodes-langchain.XXX` |
| `typeVersion` | Число (1, 2, 3.4) — не строка! |
| `position` | Array `[x, y]` — координаты на canvas |
| `connections` | Ключ = **name** ноды (не id!) |
| `settings` | **ОБЯЗАТЕЛЕН для PUT!** (может быть `{}`) |

### ⚠️ Connections: name, НЕ id!

```javascript
// ❌ НЕПРАВИЛЬНО - используем node.id:
"connections": {
  "trigger-1": { "main": [[{"node": "set-2", ...}]] }
}

// ✅ ПРАВИЛЬНО - используем node.name:
"connections": {
  "Manual Trigger": { "main": [[{"node": "Set Data", ...}]] }
}
```

### Пример с credentials

```json
{
  "id": "telegram-1",
  "name": "Send Message",
  "type": "n8n-nodes-base.telegram",
  "typeVersion": 1.2,
  "position": [450, 300],
  "parameters": {
    "resource": "message",
    "operation": "sendMessage",
    "chatId": "={{ $json.chat_id }}",
    "text": "Hello!"
  },
  "credentials": {
    "telegramApi": {
      "id": "ofhXzaw3ObXDT5JY",
      "name": "Multi_Bot0101_bot"
    }
  }
}
```

---

## Паттерн: Create + Verify

**НИКОГДА не доверяй curl blindly!** Всегда верифицируй через MCP.

```bash
# 1. Создаём через curl
response=$(curl -s -X POST "${N8N_API_URL}/api/v1/workflows" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${WORKFLOW_JSON}")

# 2. Извлекаем ID
workflow_id=$(echo "$response" | jq -r '.id')

# 3. Проверяем что ID валидный
if [ -z "$workflow_id" ] || [ "$workflow_id" == "null" ]; then
  echo "ERROR: Failed to create workflow"
  echo "Response: $response"
  exit 1
fi

echo "Created workflow: $workflow_id"
```

```javascript
// 4. Верифицируем через MCP (работает!)
const workflow = await mcp__n8n-mcp__n8n_get_workflow({
  id: workflow_id,
  mode: "full"
});

if (!workflow || !workflow.id) {
  throw new Error(`Workflow ${workflow_id} not found in n8n!`);
}

// 5. Валидируем через MCP (работает!)
const validation = await mcp__n8n-mcp__n8n_validate_workflow({
  id: workflow_id
});

console.log("Validation:", validation);
```

---

## Паттерн: Autofix Preview + Manual Apply

Autofix preview работает, apply сломан. Workaround:

```javascript
// 1. Получаем preview фиксов (MCP работает!)
const preview = await mcp__n8n-mcp__n8n_autofix_workflow({
  id: workflow_id,
  applyFixes: false  // ТОЛЬКО preview!
});

// 2. Смотрим какие фиксы предлагаются
console.log("Suggested fixes:", preview.fixes);

// 3. Получаем текущий workflow
const current = await mcp__n8n-mcp__n8n_get_workflow({
  id: workflow_id,
  mode: "full"
});

// 4. Применяем фиксы вручную к JSON
const fixed = applyFixesManually(current, preview.fixes);
```

```bash
# 5. Обновляем через curl
curl -s -X PATCH "${N8N_API_URL}/api/v1/workflows/${workflow_id}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${FIXED_WORKFLOW_JSON}"
```

```javascript
// 6. Верифицируем
const result = await mcp__n8n-mcp__n8n_get_workflow({
  id: workflow_id,
  mode: "full"
});
```

---

## Доступные credentials (этот проект)

| Service | ID | Name |
|---------|----|----|
| OpenAI | `NPHTuT9Bime92Mku` | OpenAi account |
| Telegram | `ofhXzaw3ObXDT5JY` | Multi_Bot0101_bot |
| Supabase | `DYpIGQK8a652aosj` | Supabase account |

---

## Как адаптировать агентов

### Принцип

1. **Read-only агенты** (Researcher, Analyst) → без изменений
2. **Write агенты** (Builder, QA) → заменить MCP write на curl

### Что менять в Builder

```markdown
## БЫЛО (MCP):
n8n_create_workflow({ name, nodes, connections })
n8n_update_full_workflow({ id, nodes, connections })
n8n_update_partial_workflow({ id, operations })

## СТАЛО (curl):
curl POST ${N8N_API_URL}/api/v1/workflows + verify via n8n_get_workflow
curl PATCH ${N8N_API_URL}/api/v1/workflows/{id} + verify via n8n_get_workflow
```

### Что менять в QA

```markdown
## БЫЛО (MCP):
n8n_update_partial_workflow({ id, operations: [{ type: "activateWorkflow" }] })

## СТАЛО (curl):
curl PATCH ${N8N_API_URL}/api/v1/workflows/{id} -d '{"active": true}'
```

---

## Проверка что баг исправлен

```javascript
// Тест-запрос
const test = await mcp__n8n-mcp__n8n_create_workflow({
  name: "Bug Fix Test",
  nodes: [{
    id: "test-trigger",
    name: "Manual Trigger",
    type: "n8n-nodes-base.manualTrigger",
    typeVersion: 1,
    position: [250, 300],
    parameters: {}
  }],
  connections: {}
});

if (test && test.id) {
  console.log("✅ BUG FIXED! MCP create_workflow works!");
  // Cleanup
  await mcp__n8n-mcp__n8n_delete_workflow({ id: test.id });
} else {
  console.log("❌ Bug still present, use curl workaround");
}
```

---

## Файлы проекта

| Файл | Описание |
|------|----------|
| `.claude/agents/builder.md` | Builder с curl workaround |
| `.claude/agents/qa.md` | QA с curl activation |
| `.claude/CLAUDE.md` | Общая документация с bug notice |
| `docs/MCP-BUG-RESTORE.md` | Как вернуть к MCP когда баг исправят |
| `memory/ZOD_BUG_WORKAROUND.md` | Этот файл |

---

## Ссылки

- n8n-mcp npm: https://www.npmjs.com/package/n8n-mcp
- n8n REST API: https://docs.n8n.io/api/
- Bug issues: #444, #447
