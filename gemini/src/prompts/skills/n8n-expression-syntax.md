# n8n Expression Syntax

Expert guide for writing correct n8n expressions.

## Format
Always wrap in double curly braces: `{{ expression }}`.

## Core Variables

### $json (Current Node)
Access output of the immediate previous node.
```javascript
{{$json.body.name}}
{{$json["field with spaces"]}}
```

### $node (Any Previous Node)
Access output of specific node.
**Case-sensitive!** Quotes required.
```javascript
{{$node["HTTP Request"].json.data}}
```

### $now (Time)
Luxon DateTime object.
```javascript
{{$now.toFormat('yyyy-MM-dd')}}
```

### $env (Environment)
```javascript
{{$env.API_KEY}}
```

## Webhook Data Structure
**CRITICAL:** Webhook data is wrapped in `body`.
- ❌ Wrong: `{{$json.email}}`
- ✅ Right: `{{$json.body.email}}`

## Common Mistakes
1. **Missing Braces:** `$json.id` -> `{{$json.id}}`
2. **Code Node:** Do NOT use `{{}}` in Code node JS! Use direct JS access (`$input.item.json`).
3. **Wrong Node Name:** `$node["http"].json` -> `$node["HTTP Request"].json`
