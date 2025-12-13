# 📑 LEARNINGS.md Index

> **Auto-generated index for fast pattern lookup**
> **Purpose:** Reduce token cost from 50K (full file) to ~500 tokens (index only)
> **Usage:** Read index first → Find relevant sections → Load only those sections
> **Last Updated:** 2025-11-28

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

- **Total Entries:** 85 (Added L-075, L-079 to L-083, L-091 to L-096, L-099 to L-104)
- **Categories:** 13
- **Node Types Covered:** 15+
- **Error Types Cataloged:** 31+
- **File Size:** 7,935+ lines (~238,000 tokens)
- **Index Size:** ~1,200 tokens (99.5% reduction)
- **Last Updated:** 2025-12-11

---

## 🔍 Quick Lookup Tables

### By Node Type

| Node Type | Entries | Line Numbers | Topics |
|-----------|---------|--------------|--------|
| **Supabase** | 6 | 1020-1130, 3094-3124 | Schema checks, RLS, RPC, insert/update, getAll, **🔴 L-075: RPC Parameter Order (CRITICAL)** |
| **Set (v3.4)** | 2 | 285-400 | ={{ syntax, expression validation, manual mode |
| **HTTP Request** | 4 | 1441-1710, 172-240 | continueOnFail, credentials, status codes, error handling, **🔴 L-101: Credential expression not resolved (CRITICAL)** |
| **Webhook** | 3 | 730-1458, 4940-5076 | Creation, production setup, path uniqueness, **L-076: Telegram Webhook configuration checklist** |
| **Telegram** | 5 | 1130-1190, 400-490, 4940-5076, 6820+, 244-335 | Parameter format, AI Agent integration, **L-076: Webhook onError+path parameters**, **🔴 L-099: Reply Keyboard RAW array format**, **🔴 L-100: n8n node doesn't support Reply Keyboard (CRITICAL)** |
| **Notion** | 6 | 890-1050 | Filters, dates, properties, page objects, timezone |
| **Memory (AI Agent)** | 2 | 1639-1683 | Session ID, context passing, customKey |
| **Code Node** | 4 | 1570-1602, 3560-3718, 3492-3576 | **⭐ L-104: Post-processing pattern for reliable formatting**, IF routing, regex escaping, **🔴 L-060: Deprecated $node["..."] syntax causes 300s timeout (CRITICAL)** |
| **Switch Node** | 2 | 1415-1441, 2145-2279 | Data flow after routing, fan-out patterns |
| **IF Node** | 3 | 1570-1586, 2616-2675, 330-430 | Debugging, Code Node fallback, v2.2 validator false positive (L-053), **🔴 L-068: Binary data NOT passed through IF outputs (CRITICAL)** |
| **AI Agent** | 5 | 172-305, 1639-1683, 3492-3576 | **⭐ L-104: AI Formatting Rules Unreliable - Post-Processing 100% Success**, **🟡 L-103: Multi-layer data integration pattern (DB+Tool+Prompt)**, Parameters, clarification, tools, memory |
| **Generic (MCP)** | 10 | 172-890 | **🔴 L-067: Two-step execution mode for large workflows (CRITICAL)**, **🔴 L-059: Execution analysis (superseded by L-067 for >10 nodes)**, Workflow creation, modification, validation, debugging |

### By Error Type

| Error Type | Entries | Related Nodes | Line Numbers |
|------------|---------|---------------|--------------|
| **Missing Parameter** | 6 | Supabase, Set, HTTP Request | 285-400, 1020-1130, 1380-1394 |
| **Validation Error** | 6 | Set, n8n API, Partial Update, QA Complete Check | 285-339, 1602-1639, 5182-5372 (L-078) |
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
| **Execution Analysis Incomplete** | 2 | 🔴 **L-067: Two-step for large workflows (CRITICAL)**, L-059 (small workflows) | 172-351 |
| **Deprecated Syntax Timeout** | 1 | 🔴 **$node["..."] causes 300s timeout (L-060 CRITICAL)** | 3560-3718 |
| **MCP Server Issues** | 3 | stdio vs WebSocket, Migration, Zod v4 bug (L-055) | 1117-1163, 1729+, 2772-2886 |
| **False Positives** | 4 | Validation, continueOnFail+onError, IF combinator (L-053), QA override (L-054) | 2051-2143, 2616-2771 |
| **Fan-Out Routing** | 1 | Switch Node, Multi-Way | 2145-2279 |
| **Binary Data Loss** | 1 | 🔴 **IF Node strips binary data at output (L-068 CRITICAL)** | 330-430 |
| **Webhook Configuration** | 1 | Telegram Webhook onError+path parameters (L-076) | 4940-5076 |

### By Category (from Quick Index)

| Category | Lines | Entries | Focus Areas |
|----------|-------|---------|-------------|
| Claude Code | 295-400 | 1 | Task tool syntax, agent vs subagent_type, context isolation |
| Agent Standardization | 70-190 | 1 | Template v2.0, English-only, changelog |
| n8n Workflows | 170-890, 2145-2279 | 21 | **🔴 L-103: Multi-Layer Data Integration (AI+DB)**, **🔴 L-067: Two-step execution mode for large workflows (CRITICAL)**, L-059 (for small workflows), Creation, modification, validation, debugging, partial updates, fan-out, large workflows, triggers |
| Notion Integration | 890-1020 | 6 | Filters, dates, properties, timezone, page objects |
| Supabase Database | 172-305, 1020-1130 | 6 | **🟡 L-103: Multi-layer integration with AI Agent**, Schema, RLS, RPC, insert/update, get vs getAll |
| Telegram Bot | 1130-1190 | 2 | Webhooks, message handling, parameters |
| Git & GitHub | 1190-1250 | 3 | Monorepo, PRs, pull/rebase, secrets |
| Error Handling | 1250-1340, 2051-2143, 2616-2886 | 7 | continueOnFail, 404 handling, validation, false positives, IF validator bug (L-053), QA L3 override (L-054), MCP Zod bug (L-055) |
| AI Agents | 1340-1440 | 3 | Parameters, tools, prompts, memory, clarification |
| HTTP Requests | 1440-1530 | 2 | Error handling, credentials, status codes |
| MCP Server | 1500-1757 | 1 | stdio, WebSocket, migration |
| Methodology | 3810-4387 | 3 | ⭐ **L-064: Validation Protocol (30x ROI)**, ⭐ **L-065: Dual-Source Diagnosis (48x ROI)**, 🔥 **L-066: 5-Tier Search Hierarchy (100x ROI)** |

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
| 2025-12-11 | ⭐ L-104: AI Formatting Rules Unreliable - Use Post-Processing | 3492 | AI Agents / Post-Processing |
| 2025-12-10 | 🟡 L-103: Multi-Layer Data Integration Pattern (AI+DB) | 172 | n8n Workflows / AI Agent / Database |
| 2025-12-10 | 🔴 L-102: Multiple Changes Cascade - 6-Hour Debug Marathon | 309 | Debugging / Change Management |
| 2025-12-10 | 🔴 L-101: HTTP Request Credential Expression Not Resolved (CRITICAL) | 312 | HTTP Request / Credentials |
| 2025-12-10 | 🔴 L-100: n8n Telegram Node Doesn't Support Reply Keyboard (CRITICAL) | 244 | Telegram / Node Limitation |
| 2025-12-10 | 🔴 L-099: Telegram Reply Keyboard RAW Array Format (CRITICAL) | 6820 | Telegram / Node Configuration |
| 2025-12-04 | 🔥 L-096: Validation ≠ Execution Success (CRITICAL) | 6532 | Testing / QA |
| 2025-12-04 | L-095: Code Node Injection for AI Context | 6345 | n8n Workflows / AI Agent |
| 2025-12-04 | 🛡️ L-094: Progressive Escalation Enforcement | 6192 | Orchestration / Process |
| 2025-12-04 | 🔴 L-093: Execution Log Analysis MANDATORY (CRITICAL) | 6045 | Debugging / Process |
| 2025-12-04 | ⭐ L-092: Web Search for Unknown Patterns | 5920 | Research / Methodology |
| 2025-12-04 | 🔥 L-091: Deep Research Before Building (10x ROI) | 5798 | Process / Methodology |
| 2025-12-03 | L-078: QA Complete Parameter Validation | 5182 | Methodology / QA |
| 2025-12-03 | L-077: Template #2465 - Production Base for Telegram AI Bots | 5080 | n8n Workflows / Templates |
| 2025-12-03 | L-076: Telegram Webhook Configuration Checklist | 4940 | n8n Workflows / Telegram |
| 2025-11-30 | 🔴 L-067: Execution Mode Selection for Large Workflows (CRITICAL) | 172 | n8n Workflows / Performance |
| 2025-11-28 | 🔥 L-066: Solution Search Hierarchy - 5-Tier Systematic Research | 4187 | Methodology / Research |
| 2025-11-28 | ⭐ L-065: Execution vs Configuration Data - Dual-Source Diagnosis | 3948 | Methodology / Debugging |
| 2025-11-28 | ⭐ L-064: LEARNINGS Validation Protocol - Verify Before Apply | 3810 | Methodology / Debugging |
| 2025-11-28 | 🔴 L-060: Code Node Deprecated $node["..."] Syntax Timeout (CRITICAL) | 3560 | Code Node / Debugging |

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

### Pattern 9: "How to search for solutions / where to look"
→ **Check:** Methodology (line 3810-4387)
→ **Specific:** Line 4187 (L-066: 5-Tier Search Hierarchy)

### Pattern 12: "AI not following formatting rules / emoji missing / inconsistent output"
→ **Check:** AI Agents (line 3490-3650)
→ **Specific:** Line 3492 (L-104: Post-Processing Pattern - 100% Success)

### Pattern 10: "Validate learning before applying / confidence threshold"
→ **Check:** Methodology (line 3810-4387)
→ **Specific:** Line 3810 (L-064: Validation Protocol)

### Pattern 11: "Need both execution and configuration data"
→ **Check:** Methodology (line 3810-4387)
→ **Specific:** Line 3948 (L-065: Dual-Source Diagnosis)

---

## 🔑 Keyword Map (for grep)

### Node Keywords
- `supabase` → Lines: 1020-1130, 490-616, 1336-1415
- `set node` → Lines: 285-400
- `http request` → Lines: 1441-1530, 1528-1710
- `webhook` OR `chat trigger` → Lines: 172, 730-871, 1458-1474, 4940-5076 (L-076)
- `telegram` → Lines: 1130-1190, 400-490, 4940-5076 (L-076), 6820+ (L-099: reply_markup), 244-335 (L-100: node limitation)
- `notion` → Lines: 890-1020, 1229-1336
- `memory` OR `ai agent` → Lines: 1639-1683, 1661-1683, 3492-3576 (L-104: formatting reliability)
- `code node` → Lines: 1570-1602, 1586-1602, 3560-3718, 3492-3576 (L-104: post-processing)
- `switch` → Lines: 1415-1441, 2145-2279
- `if node` → Lines: 1570-1586, 330-430 (L-068: Binary data loss)
- `binary data` OR `vision analysis` OR `image processing` → Lines: 330-430 (L-068)

### Error Keywords
- `missing parameter` OR `required field` → Lines: 285-400, 1380-1394
- `validation` OR `zod` → Lines: 285-339, 1602-1639, 5182-5372 (L-078: Complete validation)
- `reply_markup` OR `keyboard` OR `telegram buttons` OR `raw array` → Lines: 6820+ (L-099: CRITICAL), 244-335 (L-100: node limitation CRITICAL)
- `http request credentials` OR `expression not resolved` OR `predefinedCredentialType` → Lines: 172-240 (L-101: CRITICAL)
- `webhook configuration` OR `onError` OR `webhook path` → Lines: 4940-5076 (L-076)
- `template` OR `#2465` OR `ai-chatbot` OR `telegram bot template` → Lines: 5080-5178 (L-077)
- `qa validation` OR `complete check` OR `sequential validation` → Lines: 5182-5372 (L-078)
- `authentication` OR `credentials` → Lines: 1441-1458, 616-661
- `parameter order` OR `rpc wrong value` OR `date out of range` → Lines: 3094-3124 (L-075: CRITICAL)
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
- `timeout` OR `builder timeout` OR `freeze` → Lines: 172, 3560-3718
- `deprecated` OR `$node["` OR `old syntax` → Lines: 3560-3718
- `large workflow` OR `>10 nodes` OR `chunked building` → Lines: 172
- `mode=full` OR `mode=summary` OR `mode=filtered` OR `two-step` → Lines: 172-290 (L-067)
- `ai formatting` OR `emoji missing` OR `post-processing` OR `regex injection` → Lines: 3492-3576 (L-104: 100% success pattern)
- `llm unreliable` OR `instruction following` OR `prompt ignored` → Lines: 3492-3576 (L-104: why AI ignores rules)

### Operation Keywords
- `create workflow` → Lines: 730-871, 661-686, 172
- `modify workflow` OR `update workflow` → Lines: 871-1094, 1602-1639
- `validate` → Lines: 172-285, 285-339
- `debug` → Lines: 490-616, 1570-1586
- `logical block building` OR `parameter alignment` → Lines: 172

### Methodology Keywords
- `validation protocol` OR `verify before apply` → Lines: 3810-3944 (L-064)
- `dual-source` OR `execution vs configuration` → Lines: 3948-4183 (L-065)
- `search hierarchy` OR `where to look` OR `tier 1-5` → Lines: 4187-4387 (L-066)
- `confidence threshold` OR `80% confidence` → Lines: 3810-3944, 4187-4387
- `researcher strategy` OR `systematic search` → Lines: 4187-4387
- `learning validation` OR `symptom match` → Lines: 3810-3944
- `roi` OR `token savings` OR `methodology` → Lines: 3810-4387

### Claude Code Keywords
- `task tool` OR `agent parameter` → Lines: 295-400
- `subagent_type` OR `custom agent` → Lines: 295-400
- `context isolation` OR `agent isolation` → Lines: 295-400
- `agent frontmatter` OR `model selection` → Lines: 295-400

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

**Last Updated:** 2025-12-11
**Version:** 1.8.2
**Maintainer:** Kilocode System
**Purpose:** 98% token cost reduction for researcher agent
**Latest Additions:** L-104 (AI Formatting Rules Unreliable - Use Post-Processing, 100% success rate), L-091 to L-096 (Validation Gates v3.6.0 - Process Methodology from POST_MORTEM_TASK24.md), L-099 (Telegram Reply Keyboard RAW Array Format - CRITICAL)

### L-069: Agent Frontmatter Must Explicitly List MCP Tools
- **Category:** Agent System
- **Tags:** `agent-system`, `mcp-tools`, `frontmatter`, `configuration`
- **Problem:** Agents couldn't call MCP tools - output pseudocode instead
- **Solution:** Explicitly list ALL MCP tools in frontmatter `tools` array
- **Impact:** High - core agent functionality

### New Learnings (2025-12-03 FoodTracker Recovery)

| ID | Title | Category | Agent | Severity | Line |
|----|-------|----------|-------|----------|------|
| **L-079** | Builder Post-Change Verification | Builder Process / QA | builder | CRITICAL | ~5370 |
| **L-080** | QA Execution Testing | QA Process / Testing | qa | HIGH | ~5450 |
| **L-081** | Canonical Snapshot Review | Researcher Process / Context | researcher | HIGH | ~5530 |
| **L-082** | Cross-Path Dependency Analysis | QA Process / Testing | qa | HIGH | ~5610 |
| **L-083** | Credential Type Verification | Researcher Process / Config | researcher | CRITICAL | ~5690 |

**Summary:** Five new protocols from FoodTracker v111 failure recovery (2025-12-03):
- L-079: Builder MUST re-fetch workflow after mutation to verify changes applied
- L-080: QA MUST test execution (not just config validation)
- L-081: Researcher MUST read canonical snapshot BEFORE modifications
- L-082: QA MUST test ALL execution paths after shared node changes
- L-083: Researcher MUST verify credential types match node requirements

**Keywords:** `builder-verification`, `execution-testing`, `canonical-snapshot`, `cross-path-testing`, `credential-verification`, `foodtracker`, `v111-failure`, `post-change-verification`, `runtime-validation`, `context-preservation`
