# Analyst Post-Mortem & Learnings Index

**Purpose:** Root cause analysis and learning extraction for Analyst agent
**Size:** ~900 tokens | **Full knowledge:** LEARNINGS.md + validation-expert skill
**Token savings:** 96% (900 vs 50,000+ tokens)

---

## 🎯 Analyst Role

**Trigger:** After stage="blocked" or L4 escalation (7+ QA cycles)
**Mission:** Find root cause + extract learnings + track token waste
**Output:** Post-mortem report with proposed learnings

**Core activities:**
1. Read execution history (get_workflow, executions, versions)
2. Analyze failure patterns
3. Identify root cause (NOT symptoms)
4. Propose new learnings for LEARNINGS.md
5. Calculate token waste from loops

---

## 🔍 Post-Mortem Analysis Framework

### Step 1: Gather Evidence
```javascript
// Read workflow state
mcp__n8n-mcp__n8n_get_workflow({ id, mode: "full" })

// Get execution history
mcp__n8n-mcp__n8n_executions({
  action: "list",
  workflowId: id,
  limit: 20
})

// Check version history
mcp__n8n-mcp__n8n_workflow_versions({
  mode: "list",
  workflowId: id,
  limit: 10
})
```

### Step 2: Timeline Reconstruction
```
Cycle 1: Builder created node X → QA error Y
Cycle 2: Builder fixed Y → QA error Z
Cycle 3: Builder fixed Z → QA error Y again (LOOP!)
Cycle 4: Researcher suggested approach A → Builder tried → failed
Cycle 5: Researcher suggested approach B → Builder tried → failed
Cycle 6: QA flagged false positive (L-053)
Cycle 7: Builder attempted rollback → blocked
```

### Step 3: Pattern Recognition
**Common failure patterns:**
- **Loop (same error):** Missing knowledge (propose new learning)
- **Ping-pong (A→B→A):** Conflicting requirements (escalate to user)
- **Progressive degradation:** Each fix breaks something else (architecture issue)
- **False positive loop:** Validator bug (override + document)
- **Knowledge gap:** Agent unaware of gotcha (add to index)

### Step 4: Root Cause Categories
| Category | Example | Learning Type |
|----------|---------|---------------|
| **Missing knowledge** | Agent unaware of L-060 Code syntax | Add to index |
| **Tool limitation** | MCP can't do X | Document workaround |
| **Validator bug** | L-053 IF node false positive | Add to known_false_positives |
| **Architecture limit** | Pattern doesn't scale to 50+ nodes | New pattern needed |
| **User requirement conflict** | "Fast" vs "Accurate" tradeoff | Escalate decision |
| **Token waste** | Reading 50K tokens for 1 fact | Create index |

---

## 📝 Learning Extraction Template

**When to create new learning:**
- Same error occurred 2+ times across sessions
- Fix required non-obvious solution
- Solution contradicts common assumptions
- Saves >30 minutes of debugging time
- Prevents token waste >10K tokens

**Learning structure:**
```markdown
### L-XXX: [Title - Problem in 5 words]

**Problem:** [What went wrong]
**Symptoms:** [How it manifested]
**Root Cause:** [Why it happened]
**Solution:** [How to fix]
**Prevention:** [How to avoid]
**Related:** [Other learnings, patterns, gates]

**Example:**
[Code or config snippet]

**Evidence:**
- Session: [date/time]
- Workflow: [ID]
- Cycles wasted: [number]
- Tokens wasted: [number]
```

---

## 🚨 Circuit Breaker Triggers

**Analyst escalates when:**

### Trigger 1: Knowledge Gap Detected
```
IF same_error_count >= 2 AND error NOT in LEARNINGS.md:
  → Create new learning
  → Add to appropriate index
  → Report gap to user
```

### Trigger 2: Architectural Limit Hit
```
IF fix_attempts >= 5 AND pattern_mismatch:
  → Propose alternative architecture
  → Escalate to Architect for redesign
  → Report to user with options
```

### Trigger 3: Tool/Validator Bug
```
IF false_positive_count >= 3:
  → Document in qa_validation.md
  → Override validator
  → Report bug to n8n-mcp maintainer
```

### Trigger 4: Token Waste Detected
```
IF tokens_per_cycle > 30K AND index_missing:
  → Create missing index
  → Update agent prompts to use index
  → Recalculate token savings
```

### Trigger 5: User Decision Needed
```
IF conflicting_requirements OR architecture_choice:
  → Present options with tradeoffs
  → Wait for user selection
  → Document decision rationale
```

---

## 📊 Token Tracking Patterns

### Calculate Token Waste
```javascript
total_tokens = sum(agent_log[].tokens_used)
useful_tokens = initial_research + final_build
wasted_tokens = total_tokens - useful_tokens

// Example:
// Cycle 1-3: 120K tokens (QA loop)
// Cycle 4-7: 180K tokens (failed fixes)
// Total: 300K tokens
// Useful: 80K tokens (initial + final)
// Wasted: 220K tokens (73% waste!)
```

### Identify Waste Sources
| Source | Pattern | Fix |
|--------|---------|-----|
| Full file reads | Reading 50K LEARNINGS.md for 1 fact | Create index |
| Repeated searches | Same MCP call 5+ times | Cache in run_state |
| False positive loops | QA → Builder → QA (same error) | Add to known_false_positives |
| Context bloat | Agent receives 100K tokens, uses 10K | Isolate context |
| Redundant validation | Validating same node 3+ times | Single validation pass |

---

## 🎓 Critical Learnings for Debugging

### L-072: QA MUST Verify Real n8n (Anti-Fake)
**Problem:** Trusting Builder's file outputs without MCP verification
**Solution:** ALWAYS call n8n_get_workflow to verify
**Full docs:** LEARNINGS.md lines 4780-4809

### L-074: n8n API = Source of Truth
**Problem:** Files can be stale/fake caches
**Solution:** Only MCP calls prove reality
**Full docs:** LEARNINGS.md lines 4893-4985

### L-080: Phase 5 Real Testing Required
**Problem:** Validation passes but workflow fails at runtime
**Solution:** GATE 3 enforcement - test execution mandatory
**Full docs:** LEARNINGS.md lines 5448-5530

### L-060: Code Node Deprecated Syntax
**Problem:** Using `$node["..."].json` syntax causes 300s timeout
**Solution:** Use `$("Node Name").item.json`
**Full docs:** LEARNINGS.md lines 3521-3705

### L-053: IF Node v2.2 Validator False Positive
**Problem:** Validator claims "combinator required" but field is optional
**Solution:** IGNORE this error, document in known_false_positives
**Full docs:** LEARNINGS.md lines 3093-3151

---

## 🔍 Root Cause Analysis Checklist

**For each blocked session:**

- [ ] Timeline reconstructed (all cycles documented)
- [ ] Failure pattern identified (loop/ping-pong/degradation)
- [ ] Root cause category determined
- [ ] Knowledge gap vs tool limitation vs validator bug
- [ ] Token waste calculated and sources identified
- [ ] New learning needed? (yes/no + draft)
- [ ] Index update needed? (which index)
- [ ] Circuit breaker triggered? (which trigger)
- [ ] User escalation required? (decision/approval)
- [ ] Prevention strategy documented

---

## 📋 Post-Mortem Report Template

```json
{
  "session_id": "run_xxx",
  "workflow_id": "abc123",
  "status": "blocked",
  "cycles_executed": 7,
  "root_cause": {
    "category": "knowledge_gap",
    "description": "Builder unaware of L-060 Code syntax gotcha",
    "evidence": "Same 300s timeout error in cycles 2, 4, 6"
  },
  "timeline": [
    {"cycle": 1, "agent": "builder", "action": "created Code node", "result": "timeout"},
    {"cycle": 2, "agent": "builder", "action": "added error handling", "result": "timeout again"},
    {"cycle": 3, "agent": "researcher", "action": "suggested increase timeout", "result": "failed"},
    {"cycle": 4, "agent": "builder", "action": "set timeout=600000", "result": "timeout persists"}
  ],
  "token_usage": {
    "total": 220000,
    "useful": 60000,
    "wasted": 160000,
    "waste_percentage": 73,
    "waste_sources": [
      {"source": "QA loop", "tokens": 80000},
      {"source": "Full LEARNINGS.md reads", "tokens": 50000},
      {"source": "Repeated MCP calls", "tokens": 30000}
    ]
  },
  "proposed_learnings": [
    {
      "id": "L-060-EXTENSION",
      "title": "Add Code syntax to builder_gotchas.md",
      "rationale": "Builder index missing critical L-060 reference",
      "impact": "Would save 80K tokens and 4 cycles"
    }
  ],
  "prevention": {
    "index_updates": ["builder_gotchas.md - add L-060 to top 5"],
    "agent_prompts": ["Builder: check builder_gotchas BEFORE creating Code node"],
    "validation_rules": ["QA: flag deprecated syntax in pre-validation"]
  },
  "user_escalation": {
    "required": true,
    "reason": "Knowledge gap - need to update indexes",
    "decision_needed": "Approve L-060 addition to builder_gotchas.md?"
  }
}
```

---

## 🔗 Related Resources

### Skills:
- `n8n-validation-expert` - Error patterns, debugging strategies
- `n8n-workflow-patterns` - Architecture analysis

### Learnings:
- L-072, L-074, L-080: Verification requirements
- L-060: Code syntax gotcha (common root cause)
- L-053, L-054: False positive handling

### Gates:
- GATE 1: Alternative approach (cycle 4-5)
- GATE 2: Analyst diagnosis (before Builder fixes)
- GATE 3: Phase 5 testing (execution required)

**Usage:** Blocked → Gather evidence → Reconstruct timeline → Identify pattern → Root cause → Propose learning → Report

---

## 💡 Quick Decision Matrix

| Observation | Root Cause | Action |
|-------------|------------|--------|
| Same error 3+ times | Knowledge gap | Create learning |
| Ping-pong between 2 errors | Conflicting requirements | Escalate to user |
| Progressive degradation | Architecture limit | Propose redesign |
| False positive loop | Validator bug | Override + document |
| Token spike (>50K/cycle) | Missing index | Create index |
| 7 cycles, no progress | Circuit breaker | Full post-mortem |

**Token Optimization:**
- This index: ~900 tokens
- Full LEARNINGS.md: ~50,000 tokens
- Savings: 96%

**When to use full LEARNINGS.md:**
- Creating new learning (need to check L-XXX numbering)
- Deep analysis (need all 60+ learnings)
- Pattern research (cross-referencing multiple learnings)
