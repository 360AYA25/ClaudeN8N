# run_state.json Append Protocol

> Token-efficient append-only pattern for all agents

---

## Why Append-Only?

- Read+Write entire file = ~6K tokens per operation
- jq append = ~200 tokens
- **Savings: ~20K tokens per complex task**

---

## agent_log Entry (ALL agents)

```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   --arg agent "AGENT_NAME" \
   --arg action "ACTION" \
   --arg details "DETAILS" \
   '.agent_log += [{"ts": $ts, "agent": $agent, "action": $action, "details": $details}]' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

**Parameters:**
- `agent`: builder | qa | researcher | analyst | architect
- `action`: fix_applied | validation_complete | search_complete | audit_complete | diagnosis_complete
- `details`: Brief description (~50 chars max)

---

## Update Specific Fields

```bash
# Single field
jq '.workflow.node_count = 34' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json

# Multiple fields
jq '.workflow.node_count = 34 | .workflow.version_counter = 81' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json

# Nested object (merge)
jq '.build_result = {"success": true, "changes": 3}' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

---

## Agent-Specific Examples

### Builder
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.agent_log += [{"ts": $ts, "agent": "builder", "action": "fix_applied", "details": "Updated HTTP node URL parameter"}]' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

### QA
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.agent_log += [{"ts": $ts, "agent": "qa", "action": "validation_complete", "details": "0 errors, 55 warnings. Ready for test."}]' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

### Researcher
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.agent_log += [{"ts": $ts, "agent": "researcher", "action": "search_complete", "details": "Found 3 templates, 12 nodes matching query"}]' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

### Analyst
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.agent_log += [{"ts": $ts, "agent": "analyst", "action": "audit_complete", "details": "Root cause: binary data loss at IF node"}]' \
   memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json
```

---

## NEVER Do This!

```bash
# ❌ WRONG - overwrites entire file
Write tool to memory/run_state.json with full content

# ❌ WRONG - reads 12KB just to add one entry
Read memory/run_state.json → modify in memory → Write back
```

---

## Reference

See also: `schemas/run-state.schema.json` for full field definitions
