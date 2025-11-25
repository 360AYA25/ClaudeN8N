---
name: n8n-patterns
description: Critical patterns and anti-patterns for n8n workflow development.
---

# N8N Patterns

## Critical Patterns (ALWAYS apply!)

### Pattern 0: Incremental Creation
Build core workflow first (3 nodes), test, then add nodes one by one.

**Process:**
1. Create minimal viable workflow (trigger + 1 action + output)
2. Test with validate_workflow
3. Add one node at a time
4. Test after EACH addition
5. If error → fix before adding more

**Why:** Prevents cascading errors, easier debugging, faster iteration.

### Pattern 23: Supabase fieldsUi
ALWAYS use `fieldsUi.fieldValues` structure for Supabase operations.

```json
// WRONG - fails silently or 401
{
  "columns": ["name", "email"],
  "values": ["John", "john@example.com"]
}

// CORRECT - explicit structure
{
  "fieldsUi": {
    "fieldValues": [
      { "fieldName": "name", "fieldValue": "{{ $json.name }}" },
      { "fieldName": "email", "fieldValue": "{{ $json.email }}" }
    ]
  }
}
```

### Pattern 47: Never Trust Defaults
ALL node parameters must be explicitly set. Never rely on n8n defaults.

**Always specify:**
- Webhook: `httpMethod`, `path`, `responseMode`, `responseCode`
- Set node (v3.4+): `mode: "manual"`, explicit `includeOtherFields`
- HTTP Request: `method`, `timeout`, `authentication`
- All nodes: `retryOnFail`, `continueOnFail` (if needed)

### Pattern 52: Unique Webhook Path
Generate unique webhook paths to avoid collisions.

```javascript
// Format options:
path: `/webhook-${uuid()}`           // UUID-based
path: `/webhook-${Date.now()}`       // Timestamp-based
path: `/webhook-${workflowName}`     // Name-based (ensure unique)
```

**On conflict:** Deactivate old workflow, create new path.

### Pattern 60: Diff Gate (Wipe Protection)
If a change removes >50% of nodes or connections, STOP and escalate.

**Builder rule:**
```javascript
if (removedNodes / totalNodes > 0.5) {
  // STOP - do not apply
  // Escalate to user for confirmation
  return { error: "WIPE_PROTECTION", removedPercentage: 50+ }
}
```

## Anti-Patterns (NEVER do!)

### Anti-Pattern: Full Replace for Small Fixes
**WRONG:** Using `update_full_workflow` to fix one node
**CORRECT:** Using `update_partial_workflow` with specific node changes

### Anti-Pattern: Ignoring Validation
**WRONG:** Creating workflow → returning without validate
**CORRECT:** Creating workflow → validate_workflow → fix issues → return

### Anti-Pattern: Hardcoded Webhook Paths
**WRONG:** `path: "/webhook"`
**CORRECT:** `path: "/webhook-unique-identifier"`

## Common Errors & Solutions

### Error: 401 Unauthorized on Supabase
**Check:**
1. Credentials configured correctly?
2. Using `fieldsUi.fieldValues` structure?
3. Table name spelled correctly?
4. RLS policies allow the operation?

### Error: Webhook path already exists
**Solution:**
1. Generate unique path: `/webhook-{uuid}`
2. Deactivate conflicting workflow first
3. Use workflow name in path for uniqueness

### Error: Set node validation failed
**Check:**
1. Using `={{ }}` syntax (not `{{ }}`)
2. Mode set to "manual"
3. Expression syntax is valid JavaScript

### Error: Missing connections
**Check:**
1. All nodes connected in sequence
2. No orphan nodes
3. Output/input types match

## Testing Tips

1. **Always validate** after each builder change, before QA
2. **QA activates** workflow only after validation passes
3. **Trigger webhook** only on activated workflow
4. **Check execution** logs for runtime errors
5. **Snapshot before** destructive changes

## Knowledge Base References

For detailed solutions:
- `docs/learning/LEARNINGS-INDEX.md` - Quick lookup (read first)
- `docs/learning/LEARNINGS.md` - Full solutions
- `docs/learning/PATTERNS.md` - Proven workflows
