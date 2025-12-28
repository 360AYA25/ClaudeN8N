# Builder Critical Gotchas Index

**Purpose:** Critical learnings for Builder agent to avoid common mistakes
**Size:** ~1,000 tokens | **Full knowledge:** LEARNINGS.md (~60 learnings)
**Token savings:** 96% (1,000 vs 50,000+ tokens)

---

## 🔴 CRITICAL GOTCHAS (Must Check EVERY Time!)

### L-104: Code Node `.first()` Deprecated Syntax (Returns undefined!)
**Problem:** `$('Node Name').first().json.field` returns `undefined` (deprecated!)
**Solution:** Use `$node['Node Name'].json.field` instead
**Detection:** Search for `.first()` in Code node BEFORE building
**Example:**
```javascript
// ❌ WRONG (returns undefined!):
const userId = $('Check User').first().json?.telegram_user_id;

// ✅ CORRECT:
const userId = $node['Check User'].json.telegram_user_id;
// OR
const userId = $node['Telegram Trigger'].json.message.from.id;
```
**Impact:** Silent failures, data undefined, 300s timeouts
**Full docs:** LEARNINGS.md L-104

### L-060: Code Node Deprecated Syntax (300s Timeout!)
**Problem:** `$node["Node Name"].json.field` causes 300s timeout
**Solution:** Use `$('Node Name').item.json.field` instead
**Detection:** ALWAYS inspect Code node JavaScript BEFORE building
**Full docs:** LEARNINGS.md lines 3853-4102
**Impact:** 5 hours debugging vs 30 minutes with this check

### L-071: Builder MUST Use MCP Tools (Anti-Fake)
**Problem:** Claiming success without actual MCP calls
**Solution:** ALWAYS log mcp_calls[] array in result
**Enforcement:** GATE 5 checks for MCP proof
**Full docs:** LEARNINGS.md lines 4747-4779
**Example:**
```json
{
  "build_result": {
    "status": "success",
    "mcp_calls": [  // ← MANDATORY!
      {"tool": "n8n_create_workflow", "id": "abc123"},
      {"tool": "n8n_get_workflow", "id": "abc123"}
    ]
  }
}
```

### L-074: Source of Truth = n8n API (Not Files!)
**Problem:** Trusting cached data instead of live API
**Solution:** ALWAYS verify via MCP after changes
**Full docs:** LEARNINGS.md lines 4841-4870
**Rule:** If workflow_id exists → call `n8n_get_workflow` to verify

### L-075: Anti-Hallucination Protocol
**Problem:** Simulating MCP responses instead of real calls
**Solution:** NEVER fake tool outputs, use real MCP tools
**Full docs:** LEARNINGS.md lines 4871-4939
**Enforcement:** Orchestrator validates MCP calls exist

### L-055: MCP Zod Bug Workaround
**Problem:** n8n_update_partial_workflow broken in MCP
**Solution:** Use curl PUT with complete workflow JSON
**Full docs:** LEARNINGS.md lines 3239-3363
**Status:** OBSOLETE (fixed in n8n-mcp v2.27.0+)
**When:** Only if MCP version < 2.27.0

---

## ⚠️ HIGH-PRIORITY Gotchas

### L-067: Smart Mode Selection for Large Workflows
**Problem:** mode="full" times out on >10 nodes
**Solution:** Use mode="structure" for >10 nodes
**Full docs:** LEARNINGS.md lines 172-360
**Decision tree:**
- ≤10 nodes → mode="full" (safe)
- >10 nodes → mode="structure" (2-5K tokens, safe)
- Debugging specific node → mode="filtered" with nodeNames

### L-068: IF Nodes Don't Pass Binary Data
**Problem:** Binary data lost after IF node
**Solution:** Explicitly restore from previous node
**Full docs:** LEARNINGS.md lines 361-461
**Pattern:**
```javascript
// After IF node, restore binary
$binary = $('Previous Node').binary
```

### L-056: Switch Node Mode Parameter
**Problem:** typeVersion 3.3+ requires mode parameter
**Solution:** Add `"mode": "rules"` to Switch nodes
**Full docs:** LEARNINGS.md lines 3364-3513

### L-057: Post-Build Verification
**Problem:** Silent failures (version didn't change)
**Solution:** Verify version_id changed after update
**Full docs:** LEARNINGS.md lines 3514-3676
**Check:**
```javascript
before_version = workflow.versionId
// ... update ...
after_version = updated_workflow.versionId
if (before_version === after_version) {
  FAIL("Update didn't apply!")
}
```

### L-079: Builder Post-Change Verification
**Problem:** Changes applied but not visible
**Solution:** Read workflow again, verify specific parameters
**Full docs:** LEARNINGS.md lines 5375-5447
**Steps:**
1. Get expected changes from build_guidance
2. Update workflow
3. Read back via MCP
4. Verify each change present

---

## 📋 Build Checklist (Use Every Time!)

### Before Building:
- [ ] Read LEARNINGS-INDEX.md for relevant gotchas
- [ ] Check build_guidance for warnings
- [ ] If fixing: Check execution_analysis (GATE 2)
- [ ] If cycle 2+: Review fix_attempts[] history (GATE 4)

### During Building:
- [ ] Use MCP tools (NOT simulated responses!)
- [ ] Log mcp_calls[] array in result
- [ ] One change at a time (incremental)
- [ ] Verify version_id changed after update

### After Building:
- [ ] Read workflow back via MCP (L-074)
- [ ] Verify specific parameters (L-079)
- [ ] Check node count matches expected
- [ ] Return build_result with MCP proof

### Special Cases:
- [ ] Code nodes: Inspect for deprecated syntax (L-060)
- [ ] Large workflows (>10 nodes): Use mode="structure" (L-067)
- [ ] IF nodes with binary: Restore binary data (L-068)
- [ ] Switch nodes: Add mode="rules" (L-056)
- [ ] **AI Agent nodes: Check functional completeness (L-097)** 🔴 NEW

---

## 🔴 NEW: AI Agent Functional Completeness (L-097)

**Problem:** AI Agent nodes created without promptType, text, or ai_tool connections → empty UI

**CRITICAL Check BEFORE creating ANY LangChain node:**

```javascript
// AI Agent (@n8n/n8n-nodes-langchain.agent)
if (nodeType === "@n8n/n8n-nodes-langchain.agent") {
  // MANDATORY checks:
  assert(node.parameters.promptType, "promptType required (define|combine)");
  assert(node.parameters.text || node.parameters.systemMessage, "text OR systemMessage required");
  assert(workflow.connections[node.name].ai_tool?.length > 0, "ai_tool connection required");
  assert(workflow.connections[node.name].ai_languageModel?.length > 0, "ai_languageModel connection required");
}
```

**Before building AI Agent:**
1. Read build_guidance.langchain_requirements (from Researcher)
2. Verify ALL 4 requirements present
3. Only create node when complete

**If requirements missing:**
- STOP building
- Request Researcher to provide build_guidance with langchain_requirements
- Do NOT create incomplete node

**Full docs:** SYSTEM-IMPROVEMENTS-2025-12-27.md (Section 1.2)

---

## 🎯 Common Mistakes to Avoid

### ❌ DON'T:
- Batch create multiple nodes (use incremental Pattern 0)
- Trust cached data (always verify via MCP - L-074)
- Skip MCP call logging (GATE 5 will block - L-071)
- Use deprecated `$node["..."]` syntax (L-060)
- Assume update worked without verification (L-057)
- Build without reading LEARNINGS-INDEX first

### ✅ DO:
- Create one node at a time with checkpoints
- Verify every change via n8n_get_workflow
- Log all MCP calls in mcp_calls[] array
- Use modern `$('Node Name')` syntax
- Read workflow after update to confirm
- Check LEARNINGS-INDEX before every build

---

## 🔍 Debugging Failed Builds

### Symptom: Timeout (300s)
**Likely cause:** L-060 (deprecated Code node syntax)
**Fix:** Inspect Code nodes, replace `$node["..."]`

### Symptom: "Success" but workflow unchanged
**Likely cause:** L-057 (silent failure)
**Fix:** Check version_id before/after

### Symptom: GATE 5 violation
**Likely cause:** L-071 (missing MCP calls proof)
**Fix:** Add mcp_calls[] to build_result

### Symptom: Binary data lost
**Likely cause:** L-068 (IF node)
**Fix:** Restore $binary from previous node

### Symptom: MCP tool "not working"
**Likely cause:** L-055 (Zod bug - obsolete)
**Fix:** Update n8n-mcp to v2.27.0+ OR use curl workaround

---

## 🔗 Related Resources

### Skills:
- `n8n-node-configuration` - Node property configs
- `n8n-expression-syntax` - {{ }} syntax rules
- `n8n-code-javascript` - Code node patterns
- `n8n-code-python` - Python Code node patterns

### Learnings:
- L-060: Code node deprecated syntax (CRITICAL!)
- L-067: Smart mode selection (>10 nodes)
- L-071, L-074, L-075: Anti-fake protocols
- L-057, L-079: Post-build verification

### Patterns:
- Pattern 0: Incremental workflow creation
- Pattern 0.5: Surgical node edits
- Pattern 15: Cascading parameter changes

**Usage:** Check this index BEFORE building → Apply relevant gotchas → Verify changes → Log MCP calls
