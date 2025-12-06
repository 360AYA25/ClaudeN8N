# n8n Validation Expert

Expert guide for interpreting and fixing n8n validation errors.

## Error Severity Levels

### 1. Errors (Must Fix)
Blocks workflow execution.
- `missing_required` - Required field missing
- `invalid_value` - Value not in allowed list
- `type_mismatch` - String vs Number
- `invalid_expression` - Syntax error in {{}}

### 2. Warnings (Should Fix)
Doesn't block execution but risky.
- `best_practice` - e.g., missing error handling
- `performance` - e.g., unbound queries

## Common Error Types & Fixes

### missing_required
**Fix:** Use `get_node_essentials` to see what's missing.
```javascript
// Error: "Channel name is required"
config.channel = "#general";
```

### invalid_expression
**Fix:** Check {{}} syntax.
```javascript
// Wrong: $json.name
// Right: {{$json.name}}
```

### invalid_reference
**Fix:** Check node name spelling. Case-sensitive!
```javascript
// Wrong: {{$node["http request"].json}}
// Right: {{$node["HTTP Request"].json}}
```

## Validation Profiles

- `minimal`: Required fields only. Fast.
- `runtime`: Values + Types. Recommended for Pre-deployment.
- `strict`: Everything + Best Practices. Production.

## Auto-Sanitization
The system automatically fixes:
- **Binary Operators:** Removes `singleValue` property.
- **Unary Operators:** Adds `singleValue: true`.

## False Positives (Ignore These)
1. "Missing error handling" on simple nodes.
2. "No retry logic" on internal APIs.
3. "Expression syntax error" inside Code Node `jsCode` (it's JS, not expression!).
