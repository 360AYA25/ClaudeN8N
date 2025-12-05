# Architect Workflow Patterns Index

**Purpose:** Quick pattern lookup for Architect agent during planning phase
**Size:** ~800 tokens | **Full file:** PATTERNS.md (~1,600 lines, ~25K tokens)
**Token savings:** 97% (800 vs 25,000 tokens)

---

## 🔴 CRITICAL Patterns (Check FIRST!)

### Pattern 0: Smart n8n Workflow Creation Strategy
**When:** Creating ANY workflow
**Key:** Incremental approach (not batch), single-node mutations
**Full docs:** PATTERNS.md lines 169-376
**Critical rules:**
- One node at a time (NOT batch create)
- Checkpoint QA after each node
- User approval between steps
- GATE 0: Research BEFORE build

### Pattern 0.5: Modifying Individual Nodes
**When:** Updating existing workflows
**Key:** Surgical edits (not full replacement)
**Full docs:** PATTERNS.md lines 377-597
**Tools:** `n8n_update_partial_workflow` with diff operations

### Pattern 15: Cascading Parameter Changes
**When:** Debugging nodes with dependencies
**Key:** One parameter change cascades to others
**Full docs:** PATTERNS.md lines 971-1678
**Examples:** resource→operation→fields chain

---

## 📊 Top 15 Patterns by Category

### AI & Chat Workflows

**Pattern 32: Multi-Provider AI (Fan-Out/Fan-In)**
- **Use:** Multiple AI models for same task
- **Template:** Not yet in templates
- **Full docs:** PATTERNS.md lines 1679+
- **Services:** OpenAI, Anthropic, Google Gemini

### Database Operations

**Pattern 1: Dynamic Database Selection**
- **Use:** Switch databases based on user input
- **Template:** Custom implementation
- **Full docs:** PATTERNS.md lines 598-612

**Pattern 3: Summing Instead of Replacing**
- **Use:** Append data (not overwrite)
- **Template:** Notion Daily Format pattern
- **Full docs:** PATTERNS.md lines 625-634

**Pattern 4: Notion Property Reading**
- **Use:** Safe property access
- **Full docs:** PATTERNS.md lines 635-645

**Pattern 14: Null-Safe Notion Property Reading**
- **Use:** Handle missing properties gracefully
- **Full docs:** PATTERNS.md lines 918-970

### API & HTTP

**Pattern 2: Safe API Calls**
- **Use:** Error handling, retries, timeouts
- **Full docs:** PATTERNS.md lines 613-624

**Pattern 5: IF Node After API**
- **Use:** Branch based on HTTP response
- **Full docs:** PATTERNS.md lines 646-654

### Data Flow

**Pattern 10: One Value = Many Places**
- **Use:** Propagate single value across nodes
- **Template:** Variable reuse pattern
- **Full docs:** PATTERNS.md lines 728-761

**Pattern 12: Workflow Optimization (Single Source of Truth)**
- **Use:** Deduplicate data sources
- **Full docs:** PATTERNS.md lines 811-863

**Pattern 13: RADICAL Solution - JavaScript Filtering**
- **Use:** Complex Notion filtering via Code node
- **Full docs:** PATTERNS.md lines 864-917

### Debugging

**Pattern 6: Debugging Dynamic Expressions**
- **Use:** Troubleshoot {{ }} syntax
- **Full docs:** PATTERNS.md lines 655-663

**Pattern 8: Finding Solutions**
- **Use:** Systematic problem-solving approach
- **Full docs:** PATTERNS.md lines 675-689

**Pattern 9: Algorithm for Breaking Out of Loop**
- **Use:** Exit infinite loops
- **Full docs:** PATTERNS.md lines 690-727

### Architecture

**Pattern 11: API Design Evolution**
- **Use:** Iterative improvement vs big-bang redesign
- **Full docs:** PATTERNS.md lines 762-810

---

## 🎯 Quick Decision Tree

**User wants chatbot/AI response?**
→ Pattern 32 (Multi-Provider AI) or Pattern 0 (Incremental build)

**User wants database automation?**
→ Pattern 1 (Dynamic Selection) + Pattern 4 (Safe reading)

**User wants webhook/API endpoint?**
→ Pattern 2 (Safe API) + Pattern 5 (IF after API)

**Debugging workflow?**
→ Pattern 15 (Cascading) + Pattern 6 (Expressions)

**Modifying existing workflow?**
→ Pattern 0.5 (Surgical edits)

---

## 📖 How to Use This Index

1. **During clarification:** Match user request to category
2. **During decision:** Reference relevant patterns
3. **In blueprint:** Link to pattern numbers
4. **For deep dive:** Tell Researcher which patterns to study

**Example blueprint:**
```json
{
  "approach": "incremental",
  "patterns_applied": [0, 2, 5],
  "nodes_sequence": [
    {"type": "webhook", "pattern": 2},
    {"type": "if", "pattern": 5}
  ]
}
```

---

## 🔗 Related Resources

- **LEARNINGS.md** - Solutions to specific problems
- **LEARNINGS-INDEX.md** - Learnings quick lookup (99% faster)
- **N8N-RESOURCES.md** - External n8n documentation
- **PATTERNS.md (full)** - Complete pattern catalog

**Next:** When Researcher needs details → read specific PATTERNS.md sections by line numbers
