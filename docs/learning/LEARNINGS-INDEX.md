# 📑 LEARNINGS.md Index

> **Auto-generated index for fast pattern lookup**
> **Purpose:** Reduce token cost from 50K (full file) to ~500 tokens (index only)
> **Usage:** Read index first → Find relevant sections → Load only those sections
> **Last Updated:** 2025-11-17

---

## 🎯 How to Use This Index

### For Bots (Researcher agent):

**Pattern: Index → Grep → Targeted Read**

```javascript
// Step 1: Read index (500 tokens)
const index = await read('LEARNINGS-INDEX.md');

// Step 2: Find relevant sections by keywords
const keywords = extractKeywords(error); // e.g., ["supabase", "missing parameter"]
const sections = findInIndex(index, keywords); // Returns: ["Supabase Database", line 1020]

// Step 3: Grep for specific entry (fast)
const matches = await grep(keywords.join('|'), 'LEARNINGS.md', {output_mode: 'content', '-n': true});

// Step 4: Read only relevant section (200-500 tokens)
const entry = await read('LEARNINGS.md', {offset: lineNumber, limit: 50});

// Cost: 500 + 100 + 300 = 900 tokens (vs 50K = 98% savings!)
```

---

## 📊 Index Statistics

- **Total Entries:** 42
- **Categories:** 10
- **Node Types Covered:** 15+
- **Error Types Cataloged:** 22+
- **File Size:** 2,285 lines (~65,000 tokens)
- **Index Size:** ~600 tokens (99% reduction)

---

## 🔍 Quick Lookup Tables

### By Node Type

| Node Type | Entries | Line Numbers | Topics |
|-----------|---------|--------------|--------|
| **Supabase** | 5 | 1020-1130 | Schema checks, RLS, RPC, insert/update, getAll |
| **Set (v3.4)** | 2 | 285-400 | ={{ syntax, expression validation, manual mode |
| **HTTP Request** | 3 | 1441-1710 | continueOnFail, credentials, status codes, error handling |
| **Webhook** | 2 | 730-1458 | Creation, production setup, path uniqueness |
| **Telegram** | 2 | 1130-1190, 400-490 | Parameter format, AI Agent integration |
| **Notion** | 6 | 890-1050 | Filters, dates, properties, page objects, timezone |
| **Memory (AI Agent)** | 2 | 1639-1683 | Session ID, context passing, customKey |
| **Code Node** | 2 | 1570-1602 | IF routing, regex escaping |
| **Switch Node** | 2 | 1415-1441, 2145-2279 | Data flow after routing, fan-out patterns |
| **IF Node** | 1 | 1570-1586 | Debugging, Code Node fallback |
| **AI Agent** | 3 | 1639-1683 | Parameters, clarification, tools, memory |
| **Generic (MCP)** | 8 | 190-890 | Workflow creation, modification, validation, debugging |

### By Error Type

| Error Type | Entries | Related Nodes | Line Numbers |
|------------|---------|---------------|--------------|
| **Missing Parameter** | 6 | Supabase, Set, HTTP Request | 285-400, 1020-1130, 1380-1394 |
| **Validation Error** | 5 | Set, n8n API, Partial Update | 285-339, 1602-1639 |
| **Authentication** | 2 | HTTP Request, Credentials | 1441-1458, 616-661 |
| **Schema Mismatch** | 3 | Supabase, RPC Functions | 1336-1364, 1394-1415 |
| **Connection Issues** | 2 | Supabase, HTTP Request | 1364-1380, 1683-1709 |
| **Context Passing** | 3 | Memory, Switch, Data Flow | 1415-1441, 1661-1683, 172-285 |
| **Workflow References** | 2 | Node names, $node() expressions | 172-285, 871-1094 |
| **Function Overloading** | 1 | AI Agent, RPC Tools | 172-285 |
| **Timezone Issues** | 1 | Notion Date fields | 1268-1286 |
| **Credential Overwrites** | 1 | Workflow updates | 1441-1458 |
| **Null Values** | 1 | Notion Date properties | 1229-1248 |
| **Regex Escaping** | 1 | Code Node | 1586-1602 |
| **Status Code Handling** | 2 | HTTP Request, continueOnFail | 1528-1710 |
| **Partial Update Deletion** | 1 | n8n API Critical | 1602-1639 |
| **MCP Server Issues** | 2 | stdio vs WebSocket, Migration | 1117-1163, 1729+ |
| **False Positives** | 1 | Validation, continueOnFail+onError | 2051-2143 |
| **Fan-Out Routing** | 1 | Switch Node, Multi-Way | 2145-2279 |

### By Category (from Quick Index)

| Category | Lines | Entries | Focus Areas |
|----------|-------|---------|-------------|
| Agent Standardization | 70-190 | 1 | Template v2.0, English-only, changelog |
| n8n Workflows | 170-890, 2145-2279 | 17 | Creation, modification, validation, debugging, partial updates, fan-out, large workflows |
| Notion Integration | 890-1020 | 6 | Filters, dates, properties, timezone, page objects |
| Supabase Database | 1020-1130 | 5 | Schema, RLS, RPC, insert/update, get vs getAll |
| Telegram Bot | 1130-1190 | 2 | Webhooks, message handling, parameters |
| Git & GitHub | 1190-1250 | 3 | Monorepo, PRs, pull/rebase, secrets |
| Error Handling | 1250-1340, 2051-2143 | 4 | continueOnFail, 404 handling, validation, false positives |
| AI Agents | 1340-1440 | 3 | Parameters, tools, prompts, memory, clarification |
| HTTP Requests | 1440-1530 | 2 | Error handling, credentials, status codes |
| MCP Server | 1500-1757 | 1 | stdio, WebSocket, migration |

### By Complexity Level

#### Simple (1-3 nodes, basic operations)
- **Line 1509-1528:** Never commit secrets to git *(foundational)*
- **Line 1495-1509:** Git pull --rebase before push *(foundational)*
- **Line 1458-1474:** Webhook trigger for production *(setup)*
- **Line 661-686:** n8n_create_workflow parameter format *(API basics)*
- **Line 616-661:** Credential/node type issues *(setup)*

#### Medium (4-7 nodes, integrations)
- **Line 1229-1248:** Notion Date null-check *(integration)*
- **Line 1268-1286:** Notion timezone bug *(integration)*
- **Line 1286-1304:** Notion page object format *(integration)*
- **Line 1336-1364:** Supabase schema checks *(database)*
- **Line 1364-1380:** Supabase get vs getAll *(database)*
- **Line 1380-1394:** Supabase missing NOT NULL *(database)*
- **Line 1528-1570:** HTTP Request error handling *(API)*
- **Line 1683-1709:** continueOnFail configuration *(error handling)*

#### Complex (8+ nodes, multi-system workflows)
- **Line 490-616:** FoodTracker full debugging (3+ hours) *(comprehensive)*
- **Line 400-490:** AI Agent parameter mismatches *(multi-node)*
- **Line 172-285:** PM validators pre-flight checks *(validation pipeline)*
- **Line 730-871:** n8n workflow creation via MCP *(step-by-step guide)*
- **Line 871-1094:** Modifying nodes via MCP *(workflow modification)*
- **Line 1094-1117:** YouTube workflow migration *(migration)*
- **Line 1602-1639:** n8n Partial Update deletion *(critical API behavior)*
- **Line 1661-1683:** Memory node context passing *(AI Agent integration)*

### By Recency (Most Recent First)

| Date | Title | Line | Category |
|------|-------|------|----------|
| 2025-11-26 | L-050: Builder Timeout on Large Workflows | 172 | n8n Workflows |
| 2025-11-26 | FP-003: continueOnFail + onError Defense-in-Depth | 2051 | Error Handling |
| 2025-11-26 | NC-003: Switch Node Multi-Way Routing | 2145 | n8n Workflows |
| 2025-11-12 | Set v3.4 Expression Syntax ={{ | 285 | n8n Workflows |
| 2025-11-11 | PM Validators Pre-Flight Checks | 172 | n8n Workflows |
| 2025-11-09 | Memory node "No session ID found" | 1661 | AI Agents |
| 2025-11-08 | AI Agent Parameter Mismatches | 400 | n8n Workflows |
| 2025-11-08 | Partial Update Deletes Fields (CRITICAL!) | 1602 | n8n Workflows |
| 2025-11-08 | RPC function signatures verification | 1394 | Supabase |
| 2025-11-08 | AI Agent clarification behavior | 1639 | AI Agents |
| 2025-11-01 | Unified Template for Subagents | 64 | Agent Standardization |

---

## 🎯 Common Search Patterns

### Pattern 1: "Supabase missing parameter"
→ **Check:** Supabase Database (line 1020-1130)
→ **Specific:** Line 1380 (Missing NOT NULL), Line 1336 (Schema checks)

### Pattern 2: "Set node validation error"
→ **Check:** n8n Workflows (line 190-890)
→ **Specific:** Line 285 (Set v3.4 ={{ syntax)

### Pattern 3: "Memory node session ID"
→ **Check:** AI Agents (line 1340-1440)
→ **Specific:** Line 1661 (Context passing issue)

### Pattern 4: "HTTP Request authentication"
→ **Check:** HTTP Requests (line 1440-1530)
→ **Specific:** Line 1441 (Credentials overwritten)

### Pattern 5: "Workflow modification broken references"
→ **Check:** n8n Workflows (line 190-890)
→ **Specific:** Line 172 (PM Validators), Line 871 (Modifying nodes)

### Pattern 6: "continueOnFail not working"
→ **Check:** Error Handling (line 1250-1340) OR HTTP Requests (line 1440-1530)
→ **Specific:** Line 1528, Line 1683, Line 1709

### Pattern 7: "Notion date timezone"
→ **Check:** Notion Integration (line 890-1020)
→ **Specific:** Line 1268 (Timezone bug), Line 1229 (Null-check)

### Pattern 8: "AI Agent function overloading"
→ **Check:** n8n Workflows (line 190-890) OR AI Agents (line 1340-1440)
→ **Specific:** Line 172 (PM Validators - Validator 3)

---

## 🔑 Keyword Map (for grep)

### Node Keywords
- `supabase` → Lines: 1020-1130, 490-616, 1336-1415
- `set node` → Lines: 285-400
- `http request` → Lines: 1441-1530, 1528-1710
- `webhook` → Lines: 730-871, 1458-1474
- `telegram` → Lines: 1130-1190, 400-490
- `notion` → Lines: 890-1020, 1229-1336
- `memory` OR `ai agent` → Lines: 1639-1683, 1661-1683
- `code node` → Lines: 1570-1602, 1586-1602
- `switch` → Lines: 1415-1441, 2145-2279
- `if node` → Lines: 1570-1586

### Error Keywords
- `missing parameter` OR `required field` → Lines: 285-400, 1380-1394
- `validation` OR `zod` → Lines: 285-339, 1602-1639
- `authentication` OR `credentials` → Lines: 1441-1458, 616-661
- `schema` → Lines: 1336-1415
- `connection` → Lines: 1364-1380, 1683-1709
- `context passing` OR `session id` → Lines: 172-285, 1661-1683
- `broken reference` OR `$node` → Lines: 172-285, 871-1094
- `timezone` → Lines: 1268-1286
- `null` → Lines: 1229-1248
- `partial update` → Lines: 1602-1639, 871-1094
- `continueonerror` OR `continueonarefail` → Lines: 1528-1710, 2051-2143
- `false positive` OR `defense-in-depth` → Lines: 2051-2143
- `fan-out` OR `fan-in` OR `multi-way` → Lines: 2145-2279
- `timeout` OR `builder timeout` OR `freeze` → Lines: 172
- `large workflow` OR `>10 nodes` OR `chunked building` → Lines: 172

### Operation Keywords
- `create workflow` → Lines: 730-871, 661-686, 172
- `modify workflow` OR `update workflow` → Lines: 871-1094, 1602-1639
- `validate` → Lines: 172-285, 285-339
- `debug` → Lines: 490-616, 1570-1586
- `logical block building` OR `parameter alignment` → Lines: 172

---

## 📈 Usage Metrics (Expected)

**Before Index:**
- Average read: 50,000 tokens per research call
- Cost: $0.007 per call (read only)
- Time: ~2-3 seconds to load

**After Index (with targeted reads):**
- Index read: 500 tokens
- Targeted grep: 100 tokens
- Targeted read: 200-500 tokens
- **Total: 800-1,100 tokens per research call**
- **Cost: $0.0001 per call**
- **Savings: 98% token reduction**
- Time: ~0.5-1 second

**Scaling Impact:**
- At 100 entries: Index stays ~800 tokens, full file = 100K tokens (99.2% savings)
- At 200 entries: Index stays ~1,200 tokens, full file = 200K tokens (99.4% savings)
- **Index scales logarithmically, file scales linearly**

---

## 🔄 Maintenance

**When adding new entry to LEARNINGS.md:**
1. Add entry to appropriate category in LEARNINGS.md
2. Update this index:
   - Add to "By Node Type" if new node mentioned
   - Add to "By Error Type" if new error pattern
   - Add to "By Category" line numbers
   - Add to "By Recency" table (keep top 10 only)
   - Update "Index Statistics" (total entries count)
3. Update "Keyword Map" if new keywords introduced

**Auto-update script:** (TODO - Phase 3 enhancement)
```bash
# Future: Auto-generate index from LEARNINGS.md
node scripts/generate-learnings-index.js
```

---

**Last Updated:** 2025-11-26
**Version:** 1.1.0
**Maintainer:** Kilocode System
**Purpose:** 98% token cost reduction for researcher agent
