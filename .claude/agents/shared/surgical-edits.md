# Surgical Edits Protocol

> **Применяется:** Builder agent
> **Цель:** Изменять ТОЛЬКО нужные ноды, не трогать остальное

## Правило #1: Partial Updates ONLY

```
✅ ИСПОЛЬЗУЙ: n8n_update_partial_workflow
❌ ЗАПРЕЩЕНО: n8n_update_full_workflow (заблокировано hook!)
```

## Workflow изменения

### 1. Определи scope

```javascript
// Что именно нужно изменить?
const edit_scope = ["Switch"];  // Только эти ноды
```

### 2. Читай только нужное

```javascript
// НЕ читай весь workflow!
// Читай structure + конкретные ноды

// Структура (легковесная)
const structure = await n8n_get_workflow({
  id: workflow_id,
  mode: "structure"  // ~2000 tokens
});

// Только целевые ноды
const details = await n8n_get_workflow({
  id: workflow_id,
  mode: "filtered",
  nodeNames: ["Switch"]  // Только Switch
});
```

### 3. Генерируй операции

```javascript
const operations = [
  {
    type: "updateNode",
    nodeName: "Switch",
    properties: {
      parameters: {
        rules: [...existing_rules, new_rule]
      }
    }
  }
];
```

### 4. Применяй partial update

```javascript
const result = await n8n_update_partial_workflow({
  id: workflow_id,
  operations: operations
});
```

### 5. Логируй edit_scope

```javascript
return {
  status: "success",
  edit_scope: ["Switch"],  // ЧТО изменил
  changes: ["Added /water case"],  // КАК изменил
  mcp_calls: [...]
};
```

## Типы операций

| Операция | Когда использовать |
|----------|-------------------|
| `addNode` | Добавить новую ноду |
| `updateNode` | Изменить параметры существующей |
| `removeNode` | Удалить ноду |
| `addConnection` | Соединить ноды |
| `removeConnection` | Разъединить ноды |

## Когда допустим full update (исключения)

1. Создание workflow с нуля
2. Рефакторинг >50% нод (с approval юзера)
3. partial_workflow вернул ошибку (fallback)

**В этих случаях:** Запроси approval у юзера!

## Чеклист

- [ ] Определил edit_scope?
- [ ] Прочитал только нужные ноды?
- [ ] Использовал partial update?
- [ ] Залогировал edit_scope в результат?
- [ ] Проверил что изменились только заявленные ноды?
