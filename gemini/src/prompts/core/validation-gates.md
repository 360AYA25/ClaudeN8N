# 6 Validation Gates - Enforced Process Quality

**Version:** 3.6.0
**Purpose:** Prevent failure loops by enforcing process discipline

---

## Overview

**Gates are MANDATORY checkpoints** enforced by Orchestrator before delegating to agents.

**Rule:** If ANY gate fails → STOP, report violation, exit.

---

## GATE 0: Mandatory Research Phase (Priority 0 - CRITICAL!)

**Applied:** BEFORE first Builder call

### REQUIRED:
```
✅ User request → Researcher (10-20min research) → Builder (proven solution) → QA → success

Research MUST include:
1. Read LEARNINGS.md
2. Web search for official docs + working examples
3. Create build_guidance with:
   - Root cause analysis (if fixing)
   - Configuration examples (with sources!)
   - Gotchas and warnings
```

---

## GATE 1: Progressive Escalation (Priority 1)

**Applied:** QA loop cycles 1-7

### Progressive Matrix:

| Cycle | Agent | Action | Rationale |
|-------|-------|--------|-----------|
| 1-3 | Builder | Direct fix attempts | Normal trial with learning |
| 4-5 | Researcher → Builder | Alternative approach | Builder exhausted obvious fixes |
| 6-7 | Analyst → Builder | Root cause diagnosis | Systemic issue suspected |
| 8+ | BLOCKED | Report to user | Hard cap reached |

---

## GATE 2: Execution Analysis MANDATORY (Priority 2)

**Applied:** BEFORE any fix attempt (debugging existing workflows)

### REQUIRED:
```
✅ Orchestrator → Analyst: "Analyze last 5 executions"
✅ Analyst: "Execution #33645 shows: p_telegram_user_id = undefined"
✅ Orchestrator → Researcher: "Root cause: $fromAI('telegram_user_id') returns undefined"
✅ Orchestrator → Builder: "Apply fix based on root cause"
```

---

## GATE 3: Phase 5 Real Testing (Priority 3)

**Applied:** BEFORE accepting QA PASS

### Validation ≠ Execution Success

| Check Type | What It Proves | Example |
|------------|----------------|---------|
| Validation | Structure correct | Nodes connected, expressions valid |
| Execution | Functionality works | HTTP request contains user_id=682776858 |

### REQUIRED:
```
✅ QA: "Validation passed → request user testing"
✅ Orchestrator → User: "Please send test message to bot"
✅ QA: Checks execution logs → HTTP request body contains user_id ✅
```

---

## GATE 4: Knowledge Base First (Priority 4)

**Applied:** BEFORE web search (Researcher agent)

### REQUIRED:
```
✅ Researcher: "Check LEARNINGS-INDEX.md FIRST"
✅ Grep: "AI Agent", "telegram_user_id"
✅ Found: L-089, L-090
✅ Apply proven solution
✅ IF NOT FOUND → WebSearch
```

---

## GATE 5: n8n API = Source of Truth (Priority 5)

**Applied:** AFTER Builder completes (verify claims)

### Files Are Caches (May Be Stale/Fake)

| Data | ❌ NOT Source of Truth | ✅ Source of Truth |
|------|----------------------|-------------------|
| Workflow exists? | `canonical.json` file | `n8n_get_workflow` MCP call |
| Node count | `run_state.workflow.node_count` | API response `.nodes.length` |

### REQUIRED:
```
✅ Builder: Calls n8n_create_workflow MCP → logs mcp_calls array
✅ Orchestrator: Verifies mcp_calls exists and not empty
✅ Orchestrator: Double-checks via n8n_get_workflow
```
