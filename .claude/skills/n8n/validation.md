---
name: n8n-validation
description: Validation rules, error classification, and QA protocols.
---

# N8N Validation

## Severity Levels

### Error (Blocking)
Must fix before deployment:
- Missing credentials
- Broken connections (orphan nodes)
- Invalid webhook path
- Empty authentication
- Missing required parameters
- Invalid expression syntax

### Warning (Non-blocking)
Should fix, but workflow may work:
- Missing timeout
- No retryOnFail
- Implicit defaults used
- Deprecated node version
- Unused nodes

## Validation Checklist

### Structure
- [ ] All nodes connected (no orphans)
- [ ] Connections flow correctly (output → input)
- [ ] No circular dependencies
- [ ] Trigger node exists

### Parameters (Pattern 47)
- [ ] All required params explicitly set
- [ ] Webhook: path, httpMethod, responseMode
- [ ] Set node: mode="manual"
- [ ] HTTP: method, url, timeout
- [ ] Database: table, operation, fields

### Credentials
- [ ] All credential fields populated
- [ ] Credential names match n8n config
- [ ] No hardcoded secrets

### Expressions
- [ ] Using `={{ }}` syntax (not `{{ }}`)
- [ ] Valid JavaScript in expressions
- [ ] Referenced fields exist in input

### Connections
- [ ] IF/Switch outputs connected
- [ ] Error paths defined (if needed)
- [ ] No dangling outputs

## QA Annotation Protocol

### Node Annotation (_meta)
```json
{
  "nodes": [{
    "name": "Set",
    "_meta": {
      "status": "error|warning|ok",
      "error": "Brief error description",
      "suggested_fix": "Specific action to take",
      "evidence": "Where the error was found",
      "checked_at": "2025-01-01T00:00:00Z"
    }
  }]
}
```

### Regression Detection
If node was "ok" in previous cycle and now "error":
```json
{
  "_meta": {
    "status": "error",
    "regression_caused_by": {
      "agent": "builder",
      "change": "Modified expression in field X",
      "previous_status": "ok"
    }
  }
}
```

## QA Report Format

```json
{
  "validation_status": "passed|passed_with_warnings|failed",
  "issues": [
    {
      "node_id": "abc123",
      "node_name": "Set",
      "severity": "error",
      "message": "Missing required parameter: mode",
      "evidence": "parameters.mode is undefined",
      "suggested_fix": "Add mode: 'manual'"
    }
  ],
  "activation_result": "success|failed|skipped",
  "test_result": {
    "execution_id": "exec_123",
    "status": "success|error",
    "error_message": null
  },
  "edit_scope": ["node_id_1", "node_id_2"],
  "ready_for_deploy": false
}
```

## Common Validation Errors

### "Missing parameter"
**Check:** Required field not set
**Fix:** Add explicit value

### "Invalid expression"
**Check:** Expression syntax error
**Fix:** Use `={{ }}` format, valid JS

### "Credential not found"
**Check:** Credential reference invalid
**Fix:** Check credential ID exists

### "Connection missing"
**Check:** Node output not connected
**Fix:** Add connection to next node

### "Duplicate webhook path"
**Check:** Path already used
**Fix:** Generate unique path (Pattern 52)

## QA Hard Rules

1. **NEVER** fix errors (report only)
2. **NEVER** call autofix
3. **ONLY** activate for testing
4. **ALWAYS** annotate _meta on issues
5. **ALWAYS** provide edit_scope for Builder
