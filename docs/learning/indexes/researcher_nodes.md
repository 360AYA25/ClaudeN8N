# Researcher Nodes & Templates Index

**Purpose:** Quick node lookup for Researcher during research phase
**Size:** ~1,200 tokens | **Full knowledge:** LEARNINGS.md + Skills
**Token savings:** 95% (1,200 vs 50,000+ tokens)

---

## 🎯 Most Common Nodes (Top 20)

### Core Nodes

**1. Webhook** (`@n8n/n8n-nodes-langchain.webhook`)
- **Use:** Trigger workflows via HTTP
- **Critical:** Path must be unique, method selection
- **Template IDs:** #2465, #1234, #5678
- **Common issues:** L-060 (missing path), L-056 (method mismatch)

**2. HTTP Request** (`n8n-nodes-base.httpRequest`)
- **Use:** Call external APIs
- **Critical:** Authentication, timeout, error handling
- **Skills:** See `n8n-node-configuration/OPERATION_PATTERNS.md`
- **Common configs:** GET/POST, JSON body, headers

**3. Code (JavaScript)** (`n8n-nodes-base.code`)
- **Use:** Custom data transformation
- **Critical:** `$input.all()` vs `$input.first()`, async/await
- **Skills:** See `n8n-code-javascript/SKILL.md`
- **Anti-pattern:** L-060 (deprecated `$node["..."]` syntax)

**4. Code (Python)** (`n8n-nodes-base.code`)
- **Use:** Python transformations
- **Skills:** See `n8n-code-python/SKILL.md`
- **Limitations:** Standard library only, no pip packages

**5. IF** (`n8n-nodes-base.if`)
- **Use:** Conditional branching
- **Critical:** Expression syntax, true/false outputs
- **Pattern:** Pattern 5 (IF after API calls)

**6. Switch** (`n8n-nodes-base.switch`)
- **Use:** Multi-way routing
- **Critical:** typeVersion 3.3+, output numbering
- **Common issue:** NC-003 (Switch routing corruption)

**7. Set** (`n8n-nodes-base.set`)
- **Use:** Transform data fields
- **Critical:** v3.4+ requires `mode: "manual"`, `={{ }}` prefix
- **Anti-pattern:** Missing `={{` → silent failures
- **Pattern:** Pattern 0 (Set Node v3.4+ CRITICAL)

### AI & LangChain Nodes

**8. AI Agent** (`@n8n/n8n-nodes-langchain.agent`)
- **Use:** Conversational AI with tools
- **Critical:** System prompt, tool connections, memory
- **Template:** #2465 (FoodTracker pattern)
- **Common issues:** L-089, L-090, L-095 (context passing)
- **🔴 NEW:** L-097 (Functional completeness: promptType + text + ai_tool REQUIRED)
- **Research requirements:** GATE 4.5 - LangChain Deep-Dive Protocol

**9. Chat Model (OpenAI/Anthropic/Gemini)** (`@n8n/n8n-nodes-langchain.lmChatOpenAi`)
- **Use:** LLM integration
- **Critical:** Model name typos, API key credentials
- **Common gotcha:** "gpt-4.1-mini" doesn't exist (should be "gpt-4o-mini")

**10. Supabase Vector Store** (`@n8n/n8n-nodes-langchain.vectorStoreSupabase`)
- **Use:** Embeddings + similarity search
- **Critical:** Table must have vector column, dimension match
- **Skills:** See Pattern 32 (Multi-Provider AI)

### Database Nodes

**11. Supabase** (`n8n-nodes-base.supabase`)
- **Use:** PostgreSQL operations via Supabase
- **Operations:** Insert, Update, Delete, Get, RPC
- **Critical:** RLS policies, API key credentials
- **Pattern:** Pattern 1 (Dynamic Database Selection)

**12. Notion** (`n8n-nodes-base.notion`)
- **Use:** Notion API operations
- **Critical:** Database ID, property types, filters
- **Patterns:** Pattern 3, 4, 13, 14 (Notion-specific)

### Communication Nodes

**13. Telegram** (`n8n-nodes-base.telegram`)
- **Use:** Telegram Bot API
- **Operations:** Send message, receive updates
- **Critical:** Bot token credentials, chat_id

**14. Slack** (`n8n-nodes-base.slack`)
- **Use:** Slack integration
- **Common:** Post message, reactions

**15. Gmail** (`n8n-nodes-base.gmail`)
- **Use:** Email automation
- **Critical:** OAuth2 credentials

### Utility Nodes

**16. Merge** (`n8n-nodes-base.merge`)
- **Use:** Combine data from multiple nodes
- **Modes:** Append, merge by key, multiplex

**17. Split In Batches** (`n8n-nodes-base.splitInBatches`)
- **Use:** Process large datasets in chunks
- **Critical:** Batch size, loop detection

**18. Error Trigger** (`n8n-nodes-base.errorTrigger`)
- **Use:** Catch workflow errors
- **Pattern:** Error handling workflows

**19. Schedule Trigger** (`n8n-nodes-base.scheduleTrigger`)
- **Use:** Cron-based execution
- **Common:** Daily, hourly schedules

**20. Wait** (`n8n-nodes-base.wait`)
- **Use:** Pause execution
- **Modes:** Time, webhook resume

---

## 🔍 Search Strategy for Researcher

### Step 1: Check Local Knowledge First (GATE 4)
```javascript
// MANDATORY: Check LEARNINGS-INDEX.md BEFORE web search
Grep: {
  pattern: "keyword",
  path: "docs/learning/LEARNINGS-INDEX.md",
  output_mode: "content"
}

// If match found → Read specific learning
Read: {
  file_path: "docs/learning/LEARNINGS.md",
  offset: <line_from_index>,
  limit: 100
}
```

### Step 2: Search n8n MCP Tools
```javascript
// Search nodes by keyword
mcp__n8n-mcp__search_nodes({
  query: "keyword",
  mode: "OR",  // OR | AND | FUZZY
  limit: 20
})

// Get node details
mcp__n8n-mcp__get_node({
  nodeType: "n8n-nodes-base.httpRequest",
  detail: "standard",  // minimal | standard | full
  includeExamples: true  // Real-world configs from templates
})
```

### Step 3: Search Templates
```javascript
// Find templates by task
mcp__n8n-mcp__search_templates({
  searchMode: "by_task",
  task: "webhook_processing"  // or "ai_automation", etc.
})

// Get template details
mcp__n8n-mcp__get_template({
  templateId: 2465,
  mode: "structure"  // nodes_only | structure | full
})
```

### Step 4: Validate Hypothesis (GATE 6)
```javascript
// MANDATORY before proposing solution
// Test hypothesis with real data
const validation = await mcp__n8n-mcp__get_node({
  nodeType: "proposed-node",
  mode: "info"
})

// Document in research_findings:
{
  "hypothesis": "Use HTTP Request with JSON body",
  "hypothesis_validated": true,  // ← GATE 6 requirement
  "validation_method": "get_node MCP call",
  "evidence": "Node supports JSON body parameter"
}
```

---

## 🚨 L-101: Evidence-First Diagnosis (CRITICAL!)

**Rule:** NO diagnosis without execution data!

**BEFORE proposing solution (especially in fix cycles):**

```javascript
// Step 1: Get execution history
mcp__n8n-mcp__n8n_executions({
  action: "list",
  workflowId: workflow_id,
  limit: 10
})

// Step 2: Get detailed execution with data
mcp__n8n-mcp__n8n_executions({
  action: "get",
  id: execution_id,
  includeData: true  // ← MANDATORY for diagnosis!
})

// Step 3: Find EXACT error in logs
// - Which node failed?
// - What was the input?
// - What was the error message?
```

**IF execution data unavailable (API timeout/error):**

1. Log blocker: "Execution data unavailable - need manual verification"
2. Set status: "BLOCKED"
3. Report to Orchestrator → escalate to user for manual UI check
4. **DO NOT** proceed with hypothesis-based fix!

**Label hypotheses clearly:**

```json
{
  "research_findings": {
    "hypothesis": "Code node using deprecated .first() syntax",
    "confidence": "MEDIUM (no execution logs)",
    "type": "HYPOTHESIS",  // ← NOT "fact"!
    "requires_user_approval": true  // ← Before Builder applies
  }
}
```

**NO hypothesis-based fixes without user approval!**

**Full docs:** LEARNINGS.md L-101

---

## 📚 Node Configuration Resources

**For each node, Researcher should check:**

1. **Skill files:** `.claude/skills/n8n-node-configuration/`
   - OPERATION_PATTERNS.md - Common configs by operation
   - DEPENDENCIES.md - Field dependencies

2. **LEARNINGS.md sections:**
   - L-060: Code Node Inspection
   - L-056: Webhook configurations
   - L-089, L-090, L-095: AI Agent patterns

3. **MCP get_node tool:**
   - `detail: "standard"` for essential fields
   - `includeExamples: true` for real configs
   - `mode: "search_properties"` to find specific field

---

## 🎯 Common Research Patterns

### Pattern: Find Node for Task
```
User wants: "Save data to database"
→ Search: "database" → Supabase, PostgreSQL, MySQL
→ Check existing workflows: any use Supabase?
→ Get node examples: includeExamples=true
→ Propose: Supabase Insert operation
```

### Pattern: Debug Existing Node
```
User reports: "Webhook not working"
→ Check LEARNINGS-INDEX: "webhook"
→ Found: L-056 (path required)
→ Read full learning: lines 456-520
→ Verify workflow: path missing?
→ Propose fix: add path parameter
```

### Pattern: Find Alternative Approach
```
Cycle 4-5: Previous fix failed
→ GATE 1: Alternative approach required
→ Search templates: similar workflows
→ Find: Different node type used
→ Validate: Check node capabilities
→ Propose: Alternative implementation
```

---

## 🔗 Related Resources

- **n8n-node-configuration** skill - Property dependencies
- **n8n-mcp-tools-expert** skill - MCP tool usage guide
- **LEARNINGS-INDEX.md** - Problem-solution lookup
- **PATTERNS.md** - Workflow architecture patterns

**Usage:** Load this index → Search by keyword → Get node details → Validate hypothesis → Propose solution
