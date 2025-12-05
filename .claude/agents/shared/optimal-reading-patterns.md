# Optimal Reading Patterns (Option C v3.6.0)

**Purpose:** Shared documentation for token-efficient reading patterns across all agents

---

## 📊 Agent-Scoped Indexes Overview

| Agent | Primary Index | Size | Full File | Savings |
|-------|---------------|------|-----------|---------|
| **Architect** | architect_patterns.md | 800 | PATTERNS.md (25K) | 97% |
| **Researcher** | researcher_nodes.md | 1,200 | - | - |
| **Researcher** | LEARNINGS-INDEX.md | 2,500 | LEARNINGS.md (50K) | 95% |
| **Builder** | builder_gotchas.md | 1,000 | - | - |
| **QA** | qa_validation.md | 700 | - | - |
| **Analyst** | analyst_learnings.md | 900 | - | - |

**Total index size:** ~7,100 tokens
**Full files:** ~75,000 tokens
**Overall savings:** 91%

---

## 🎯 Index-First Reading Protocol

### Core Principle
**"Index First, Full File Only If Not Found"**

### 4-Step Process

```
1. READ INDEX
   ├── Agent reads their primary index (~700-1,200 tokens)
   └── Quick scan for relevant keyword/pattern

2. FIND POINTER
   ├── Index contains: line numbers, L-XXX IDs, template IDs
   └── Pointer directs to specific section in full file

3. READ SECTION
   ├── Read ONLY the referenced section (not entire file)
   └── Example: Read LEARNINGS.md lines 3521-3705 (L-060 only)

4. FALLBACK
   ├── If not in index → Read full file
   └── Then propose: Add to index for next time
```

---

## 📚 Index Locations

**All indexes located in:** `docs/learning/indexes/`

```
docs/learning/indexes/
├── architect_patterns.md      # Top 15 workflow patterns
├── researcher_nodes.md         # Top 20 n8n nodes + search strategy
├── builder_gotchas.md          # Critical build-time gotchas
├── qa_validation.md            # Validation checklist + false positives
└── analyst_learnings.md        # Post-mortem framework + learnings

docs/learning/
└── LEARNINGS-INDEX.md          # Master index for all L-XXX learnings
```

---

## 🔍 Example Flows by Agent

### Architect: Design Workflow
```
Task: "Design AI chatbot for Telegram"

Flow:
1. Read architect_patterns.md (800 tokens)
2. Find: Pattern 32 (Multi-Provider AI), lines 1420-1580
3. Find: Template #2465 (Telegram AI Bot)
4. Read PATTERNS.md lines 1420-1580 ONLY
5. Check gotchas: L-089 (AI Agent Input Scope)
6. Read LEARNINGS-INDEX.md → L-089 at lines 5800-5900
7. Read LEARNINGS.md lines 5800-5900 ONLY

Token usage: 800 + 160 + 100 + 100 = 1,160 tokens
Saved: 73,840 tokens (98.5% savings!)
```

### Researcher: Find Node
```
Task: "Find node for Telegram bot"

Flow:
1. Read researcher_nodes.md (1,200 tokens)
2. Find: "Telegram (n8n-nodes-base.telegram)"
3. Get: nodeType, common configs, gotchas L-076
4. MCP: get_node("n8n-nodes-base.telegram", detail="standard")
5. Validate hypothesis (GATE 6)

Token usage: 1,200 + ~500 (MCP) = 1,700 tokens
Saved: 48,300 tokens (97% savings!)
```

### Builder: Create Node
```
Task: "Add Code node for transformation"

Flow:
1. Read builder_gotchas.md (1,000 tokens)
2. Find: L-060 (CRITICAL: Code syntax causing 300s timeout)
3. Check: ✅ Use $("Node").item.json, ❌ NOT $node["..."]
4. Build node with correct syntax
5. Log mcp_calls array

Token usage: 1,000 tokens
Saved: 49,000 tokens (98% savings!)
Avoided: 4-cycle debugging loop (160K tokens wasted)
```

### QA: Validate Workflow
```
Task: "Validate workflow with IF node v2.2"

Flow:
1. Read qa_validation.md (700 tokens)
2. Find: L-053 (IF node false positive - "combinator required")
3. Run validation → Error about combinator
4. Check known_false_positives → L-053 listed → IGNORE
5. Phase 5: Execute workflow test (GATE 3)
6. Report: PASS + phase_5_executed: true

Token usage: 700 tokens
Saved: 49,300 tokens (99% savings!)
Avoided: Blocking Builder on false positive
```

### Analyst: Post-Mortem
```
Task: "Analyze blocked session (7 cycles)"

Flow:
1. Read analyst_learnings.md (900 tokens)
2. Framework: Evidence → Timeline → Pattern → Root Cause
3. Pattern: Same error 3+ times = Knowledge gap
4. Root cause: Builder unaware of L-060
5. Calculate token waste: 160K (73%)
6. Circuit breaker: Knowledge gap detected
7. Propose: Add L-060 to builder_gotchas.md

Token usage: 900 tokens
Saved: 49,100 tokens (98% savings!)
Prevention: Future sessions won't repeat this error
```

---

## 🚫 Anti-Patterns (What NOT to Do)

### ❌ Reading Full Files Directly
```bash
# WRONG:
Read: docs/learning/LEARNINGS.md (50,000 tokens)
# Just to find one L-XXX learning

# RIGHT:
Read: docs/learning/LEARNINGS-INDEX.md (2,500 tokens)
Find: L-060 at lines 3521-3705
Read: LEARNINGS.md lines 3521-3705 (185 tokens)
```

### ❌ Skipping Index Check
```bash
# WRONG:
Researcher: "I'll just search MCP for nodes"
# Wastes time and tokens

# RIGHT:
Researcher: Read researcher_nodes.md first
# 80% of common nodes already documented
```

### ❌ Not Following Pointers
```bash
# WRONG:
Read index → See "L-060" → Ignore → Re-search problem

# RIGHT:
Read index → See "L-060 lines 3521-3705" → Read section → Solved!
```

---

## 📈 Token Savings Breakdown

### Per-Workflow Savings

**Before Option C (average workflow):**
```
Architect:  25,000 (PATTERNS.md)
Researcher: 50,000 (LEARNINGS.md)
Builder:    50,000 (LEARNINGS.md)
QA:         50,000 (LEARNINGS.md)
Analyst:    50,000 (LEARNINGS.md)
-------------------------
Total:     225,000 tokens per workflow
```

**After Option C (average workflow):**
```
Architect:     800 (architect_patterns.md)
Researcher:  3,700 (researcher_nodes.md + LEARNINGS-INDEX.md)
Builder:     1,000 (builder_gotchas.md)
QA:            700 (qa_validation.md)
Analyst:       900 (analyst_learnings.md)
-------------------------
Total:       7,100 tokens per workflow
```

**Savings: 217,900 tokens (97%)**

### Cumulative Savings (10 Workflows)

- **Before:** 2,250,000 tokens
- **After:** 71,000 tokens
- **Saved:** 2,179,000 tokens (97%)
- **Cost reduction:** ~$22 → ~$0.70 (at $0.01/1K tokens)

---

## 🔄 Index Maintenance Protocol

### When to Update Index

**Add to index if:**
- Same pattern/node/learning accessed 3+ times
- New critical gotcha discovered (blocking issue)
- Common question answered repeatedly
- Token savings >10K per occurrence

### Update Process

1. **Identify gap:**
   ```
   Agent reads full file 3+ times for same info
   → Index missing this pattern
   ```

2. **Propose update:**
   ```
   Analyst or user proposes: "Add L-XXX to [agent]_index.md"
   ```

3. **Verify uniqueness:**
   ```
   Check index doesn't already have it
   Check it's truly common (not one-off)
   ```

4. **Add entry:**
   ```markdown
   ### L-XXX: [Title]
   **Problem:** [brief]
   **Solution:** [brief]
   **Full docs:** LEARNINGS.md lines X-Y
   ```

5. **Test:**
   ```
   Next workflow: Agent uses new index entry
   Verify: Token savings achieved
   ```

---

## 🎯 Enforcement Rules

### GATE 4: Knowledge Base First (Researcher)

```javascript
// MANDATORY before web search
if (!checked_learnings_index) {
  BLOCK("Read LEARNINGS-INDEX.md first!");
}
```

**Flow:**
1. LEARNINGS-INDEX.md (local knowledge)
2. MCP search_nodes/templates (n8n knowledge)
3. Web search (global knowledge)

### GATE 6: Hypothesis Validation (Researcher)

```javascript
// MANDATORY before proposing solution
if (!hypothesis_validated) {
  BLOCK("Validate hypothesis with MCP first!");
}
```

**Example:**
```
Hypothesis: "Use HTTP Request node for API"
Validation: get_node("n8n-nodes-base.httpRequest") → Verified
Result: {hypothesis_validated: true, evidence: "..."}
```

---

## 📖 Quick Reference Table

| If you need... | Read this first | Then (if needed) | Token cost |
|----------------|-----------------|------------------|------------|
| Workflow pattern | architect_patterns.md | PATTERNS.md section | 800 + ~200 |
| Node information | researcher_nodes.md | MCP get_node | 1,200 + ~500 |
| Learning by keyword | LEARNINGS-INDEX.md | LEARNINGS.md section | 2,500 + ~200 |
| Build gotcha | builder_gotchas.md | LEARNINGS.md section | 1,000 + ~200 |
| Validation checklist | qa_validation.md | - | 700 |
| Post-mortem template | analyst_learnings.md | LEARNINGS.md section | 900 + ~200 |

---

## 🎓 Summary

**Golden Rule:**
> "Index First, Full File Only If Not Found, Always Follow Pointers"

**Benefits:**
- ✅ 97% token savings per workflow
- ✅ Faster agent execution (less reading)
- ✅ Consistent patterns across agents
- ✅ Easy maintenance (update index, not all agents)
- ✅ Knowledge accumulation (indexes grow over time)

**Success Criteria:**
- Agents read indexes first (100% compliance)
- Full file reads decrease by 90%+
- Token usage per workflow <10K (vs 225K before)
- No repeated searches for same information

**This is the new standard for all ClaudeN8N agents!**
