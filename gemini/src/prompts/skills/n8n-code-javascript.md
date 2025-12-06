# JavaScript Code Node Skill

Expert guidance for writing JavaScript code in n8n Code nodes.

## Quick Start

```javascript
// Basic template for Code nodes
const items = $input.all();

// Process data
const processed = items.map(item => ({
  json: {
    ...item.json,
    processed: true,
    timestamp: new Date().toISOString()
  }
}));

return processed;
```

### Essential Rules

1. **Choose "Run Once for All Items" mode** (recommended for most use cases)
2. **Access data**: `$input.all()`, `$input.first()`, or `$input.item`
3. **CRITICAL**: Must return `[{json: {...}}]` format
4. **CRITICAL**: Webhook data is under `$json.body` (not `$json` directly)
5. **Built-ins available**: $helpers.httpRequest(), DateTime (Luxon), $jmespath()

## Data Access Patterns

### Pattern 1: $input.all() - Most Common
Use when processing arrays, batch operations, aggregations.

```javascript
const allItems = $input.all();
const valid = allItems.filter(item => item.json.status === 'active');
return valid;
```

### Pattern 2: $input.first() - Very Common
Use when working with single objects or first-in-first-out.

```javascript
const firstItem = $input.first();
return [{ json: { result: process(firstItem.json) } }];
```

### Pattern 3: $node - Reference Other Nodes
Use when needing data from specific upstream nodes.

```javascript
const webhookData = $node["Webhook"].json;
const httpData = $node["HTTP Request"].json;
return [{ json: { combined: { webhookData, httpData } } }];
```

## Common Mistakes to AVOID

1. **Missing Return**: Code node MUST return data.
2. **Wrong Format**: Must return array of objects with `json` property. `[{json: {key: val}}]`
3. **Deprecated Syntax**: Avoid `$node["Name"]` in favor of `$("Name")` or `$node` selector.
4. **Webhook Nesting**: Remember `$json.body` for webhook payloads.
