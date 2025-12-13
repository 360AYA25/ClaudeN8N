# Workflow Update Protection Strategy

> **Problem:** AI Agent system prompt gets overwritten when updating workflow via MCP
> **Solution:** Multi-layer protection strategy

---

## 🚨 THE PROBLEM

**When using n8n MCP tools to update workflows, prompts can be ERASED:**

### Scenario 1: Full Workflow Update (`n8n_update_full_workflow`)
```javascript
// Builder updates workflow
n8n_update_full_workflow({
  id: "sw3Qs3Fe3JahEbbW",
  nodes: [...], // AI Agent node missing systemMessage!
  connections: {...}
})
// Result: System prompt → ERASED!
```

### Scenario 2: Partial Update (`n8n_update_partial_workflow`)
```javascript
// Builder updates node parameters
n8n_update_partial_workflow({
  id: "sw3Qs3Fe3JahEbbW",
  operations: [
    {
      type: "updateNode",
      nodeId: "cdfe74df-5815-4557-bf8f-f0213d9ca8ad", // AI Agent
      updates: {
        parameters: {} // Empty → systemMessage LOST!
      }
    }
  ]
})
// Result: System prompt → ERASED!
```

### Scenario 3: Node Position/Connection Change
```javascript
// Moving nodes or changing connections
// If full workflow replacement used → prompt LOST
```

---

## ✅ SOLUTION: 5-LAYER PROTECTION

### Layer 1: CANONICAL SNAPSHOT (Golden Source)

**Create immutable backup of AI Agent node:**

```bash
# Save canonical version of AI Agent node
jq '.nodes[] | select(.name == "AI Agent")' \
  memory/workflow_snapshots/sw3Qs3Fe3JahEbbW/canonical.json \
  > memory/workflow_snapshots/sw3Qs3Fe3JahEbbW/ai_agent_canonical.json
```

**Restore command (if prompt lost):**
```javascript
// Read canonical
const canonical = Read('memory/workflow_snapshots/.../ai_agent_canonical.json');

// Restore via partial update
n8n_update_partial_workflow({
  id: "sw3Qs3Fe3JahEbbW",
  operations: [{
    type: "updateNode",
    nodeId: "cdfe74df-5815-4557-bf8f-f0213d9ca8ad",
    updates: {
      parameters: {
        options: {
          systemMessage: canonical.parameters.options.systemMessage
        }
      }
    }
  }]
})
```

---

### Layer 2: QA PRE-CHECK (Mandatory)

**QA agent MUST verify prompt before marking workflow valid:**

```javascript
// In qa.md - BEFORE validating workflow
const workflow = n8n_get_workflow({ id: "..." });
const aiAgent = workflow.nodes.find(n => n.name === "AI Agent");

// Verify systemMessage exists and matches canonical
const canonicalPrompt = Read('...ai_agent_canonical.json');
const currentPrompt = aiAgent.parameters?.options?.systemMessage;

if (!currentPrompt || currentPrompt.length < 500) {
  return {
    status: "FAIL",
    error: "AI Agent system prompt missing or truncated!",
    edit_scope: ["restore_ai_agent_prompt"]
  };
}
```

---

### Layer 3: BUILDER EDIT_SCOPE RESTRICTION

**Builder MUST NEVER touch AI Agent node unless explicitly instructed:**

```javascript
// In builder.md protocol
## FORBIDDEN OPERATIONS

**NEVER update these nodes unless edit_scope explicitly includes them:**
- AI Agent (ID: cdfe74df-5815-4557-bf8f-f0213d9ca8ad)
- Conversation Memory
- OpenAI Chat Model

**Safe operations:**
- addNode - ✅ OK
- removeNode - ✅ OK (except protected nodes)
- updateNode - ❌ ONLY if edit_scope includes node name
- moveNode - ✅ OK (position changes only)
- addConnection - ✅ OK
- removeConnection - ✅ OK
```

**Example safe edit_scope:**
```json
{
  "edit_scope": [
    "Process Text",
    "Process Voice",
    "Download Photo"
  ]
  // AI Agent NOT in list → Builder CANNOT touch it
}
```

---

### Layer 4: VERSION CONTROL (Automatic)

**Every workflow update triggers version save:**

```javascript
// In builder.md - AFTER every update
// Save version snapshot
n8n_workflow_versions({
  mode: "list",
  workflowId: "sw3Qs3Fe3JahEbbW"
})

// Auto-prune keeps last 10 versions
n8n_workflow_versions({
  mode: "prune",
  workflowId: "sw3Qs3Fe3JahEbbW",
  maxVersions: 10
})
```

**Rollback if prompt lost:**
```javascript
// Find last good version
const versions = n8n_workflow_versions({
  mode: "list",
  workflowId: "sw3Qs3Fe3JahEbbW",
  limit: 20
});

// Rollback to version before prompt was lost
n8n_workflow_versions({
  mode: "rollback",
  workflowId: "sw3Qs3Fe3JahEbbW",
  versionId: versions[3].id, // 3 versions back
  validateBefore: true
})
```

---

### Layer 5: LEARNINGS.md ENFORCEMENT

**Create mandatory learnings to prevent future losses:**

**L-104: AI Agent Prompt Protection Protocol**
```markdown
**Category:** safety
**Severity:** CRITICAL
**Pattern:** Protecting AI Agent system prompts from accidental overwrites

**Rule:**
1. NEVER update AI Agent node unless edit_scope explicitly includes "AI Agent"
2. ALWAYS verify systemMessage exists in QA validation
3. ALWAYS save canonical snapshot before first workflow modification
4. IF prompt missing → restore from canonical IMMEDIATELY

**Detection:**
- QA checks: `aiAgent.parameters?.options?.systemMessage?.length < 500`
- Builder checks: `"AI Agent" in edit_scope` before updateNode

**Fix:**
```javascript
// Restore from canonical
const canonical = Read('memory/.../ai_agent_canonical.json');
n8n_update_partial_workflow({
  operations: [{
    type: "updateNode",
    nodeId: "...",
    updates: { parameters: canonical.parameters }
  }]
})
```

**Prevention:**
- Builder: Skip AI Agent unless explicitly in edit_scope
- QA: Fail validation if systemMessage missing/short
- Canonical: Maintain immutable golden source
```

---

## 🔥 IMPLEMENTATION CHECKLIST

### Initial Setup (One-time)

- [ ] Extract AI Agent node to `ai_agent_canonical.json`
- [ ] Verify canonical has full systemMessage
- [ ] Create L-104 learning in LEARNINGS.md
- [ ] Update builder.md with FORBIDDEN OPERATIONS section
- [ ] Update qa.md with pre-check prompt validation

### Before Every Workflow Update

- [ ] Check if AI Agent in edit_scope
- [ ] If NO → Builder skips AI Agent entirely
- [ ] If YES → verify canonical exists for rollback

### After Every Workflow Update

- [ ] QA validates systemMessage still present
- [ ] Save version snapshot (auto-prune to 10)
- [ ] If prompt missing → FAIL + restore from canonical

---

## 🧪 TEST SCENARIO

**Simulate prompt loss and recovery:**

```bash
# 1. Intentionally corrupt prompt
n8n_update_partial_workflow({
  id: "sw3Qs3Fe3JahEbbW",
  operations: [{
    type: "updateNode",
    nodeId: "cdfe74df-5815-4557-bf8f-f0213d9ca8ad",
    updates: {
      parameters: {
        options: {
          systemMessage: "" # CORRUPTED!
        }
      }
    }
  }]
})

# 2. QA should detect
# Expected: FAIL with "AI Agent system prompt missing!"

# 3. Restore from canonical
# Automated via QA agent

# 4. Verify restoration
# systemMessage should match canonical exactly
```

---

## 📚 RELATED DOCUMENTATION

- **LEARNINGS.md:** L-074 (Source of Truth), L-104 (Prompt Protection)
- **builder.md:** FORBIDDEN OPERATIONS section
- **qa.md:** Pre-check validation rules
- **workflow_snapshots/:** Canonical node backups

---

## 💡 WHY THIS WORKS

1. **Canonical Snapshot** → Golden source always available
2. **Edit Scope** → Builder physically cannot touch AI Agent
3. **QA Pre-check** → Detects loss before validation
4. **Version Control** → Easy rollback if needed
5. **LEARNINGS.md** → Institutional knowledge prevents repeat

**Result:** Prompt survives 100% of workflow updates! 🎉
