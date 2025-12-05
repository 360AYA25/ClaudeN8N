# 6 Validation Gates - Enforced Process Quality

**Version:** 3.6.0
**Created:** 2025-12-04 (POST_MORTEM_TASK24.md analysis)
**Purpose:** Prevent 5-hour failures by enforcing process discipline

---

## Overview

**Gates are MANDATORY checkpoints** enforced by Orchestrator before delegating to agents.

**Why gates exist:** Task 2.4 took 5 hours (8 failed attempts) without gates, 30 minutes with gates.

**Rule:** If ANY gate fails → STOP, report violation, exit.

---

## GATE 0: Mandatory Research Phase (Priority 0 - CRITICAL!)

**Applied:** BEFORE first Builder call (new tasks OR debugging)

**Problem:** Jumping to build/fix wastes hours on wrong approaches.

**Evidence:** 5 hours (no research) vs 30 minutes (15min research).

### FORBIDDEN:
```
❌ User request → Builder (guess) → QA → fail → repeat
❌ "I'll try changing X and see if it works"
❌ Assumptions about node behavior
```

### REQUIRED:
```
✅ User request → Researcher (10-20min research) → Builder (proven solution) → QA → success

Research MUST include:
1. Read LEARNINGS.md (Grep search for keywords)
2. Web search for official docs + working examples
3. Study similar solved issues
4. Create build_guidance with:
   - Root cause analysis (if fixing)
   - Configuration examples (with sources!)
   - Gotchas and warnings
   - Estimated complexity
5. User approval of approach
```

### Enforcement (Orchestrator):

```bash
# Before FIRST Builder call:
if [ "$stage" = "build" ] && [ "$cycle_count" = "0" ]; then
  research_file="memory/agent_results/build_guidance_*.json"

  if [ ! -f $research_file ]; then
    echo "🚨 GATE 0 VIOLATION: Build without research!"
    echo "Required: Delegate to Researcher for 10-20min deep research."
    echo "Must create: build_guidance with sources, gotchas, examples."
    exit 1
  fi

  # Verify research quality
  has_sources=$(jq -r '.build_guidance.sources // [] | length > 0' "$research_file")
  has_examples=$(jq -r '.build_guidance.configuration_examples // [] | length > 0' "$research_file")

  if [ "$has_sources" != "true" ] || [ "$has_examples" != "true" ]; then
    echo "🚨 GATE 0 VIOLATION: Low-quality research!"
    echo "Required: Research must include sources AND configuration examples."
    exit 1
  fi

  echo "✅ GATE 0 PASS: Research phase completed with sources + examples"
fi
```

### Exceptions:
- ❌ NONE! All tasks require research.
- Even "simple" tasks → 10min quick research saves hours.

### Related Learnings:
- **L-091:** Deep Research Before Building
- **L-092:** Web Search for Unknown Patterns

---

## GATE 1: Progressive Escalation (Priority 1)

**Applied:** QA loop cycles 1-7

**Problem:** Agents stuck in loop, user frustrated, time wasted.

**Evidence:** Previous session: 8 attempts by Builder alone. Should have escalated at attempt #3.

### Progressive Matrix:

| Cycle | Agent | Action | Rationale |
|-------|-------|--------|-----------|
| 1-3 | Builder | Direct fix attempts | Normal trial with learning |
| 4-5 | Researcher → Builder | Alternative approach | Builder exhausted obvious fixes |
| 6-7 | Analyst → Builder | Root cause diagnosis | Systemic issue suspected |
| 8+ | BLOCKED | Report to user | Hard cap reached |

### Enforcement (Orchestrator):

```bash
cycle=$(jq -r '.cycle_count // 0' memory/run_state.json)

# Cycle 4-5: MUST call Researcher FIRST
if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ]; then
  researcher_called=$(jq -r '[.agent_log[] | select(.agent=="researcher" and .cycle=='$cycle')] | length > 0' memory/run_state.json)

  if [ "$researcher_called" != "true" ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Researcher FIRST!"
    echo "Required: Find alternative approach before Builder retry."
    exit 1
  fi
fi

# Cycle 6-7: MUST call Analyst FIRST
if [ "$cycle" -ge 6 ] && [ "$cycle" -le 7 ]; then
  analyst_called=$(jq -r '[.agent_log[] | select(.agent=="analyst" and .cycle=='$cycle')] | length > 0' memory/run_state.json)

  if [ "$analyst_called" != "true" ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Analyst FIRST!"
    echo "Required: Root cause diagnosis before continuing."
    exit 1
  fi
fi

# Cycle 8+: BLOCKED
if [ "$cycle" -ge 8 ]; then
  echo "🚨 GATE 1 VIOLATION: Cycle 8+ blocked!"
  jq '.stage = "blocked" | .block_reason = "7 QA cycles exhausted"' memory/run_state.json > tmp && mv tmp memory/run_state.json
  exit 1
fi
```

### Related Learnings:
- **L-094:** Progressive Escalation Enforcement

---

## GATE 2: Execution Analysis MANDATORY (Priority 2)

**Applied:** BEFORE any fix attempt (debugging existing workflows)

**Problem:** Guessing without data = 8+ wasted attempts.

**Evidence:** Previous session guessed for 5 hours; emergency audit found issue in 5 minutes by checking execution #33645.

### FORBIDDEN:
```
❌ User: "Bot not responding"
❌ Builder: "I'll try changing promptType..."  (GUESS!)
```

### REQUIRED:
```
✅ User: "Bot not responding"
✅ Orchestrator → Analyst: "Analyze last 5 executions"
✅ Analyst: "Execution #33645 shows: p_telegram_user_id = undefined in HTTP request body"
✅ Orchestrator → Researcher: "Root cause: $fromAI('telegram_user_id') returns undefined"
✅ Researcher: "Solution: Code Node Injection pattern (see workflow 2035)"
✅ Orchestrator → Builder: "Apply Code Node Injection fix"
```

### Enforcement (Orchestrator):

```bash
# Check if fixing existing workflow
workflow_id=$(jq -r '.workflow_id // ""' memory/run_state.json)

if [ "$stage" = "build" ] && [ -n "$workflow_id" ] && [ -f "memory/workflow_snapshots/$workflow_id/canonical.json" ]; then
  # This is a FIX to existing workflow
  execution_analysis=$(jq -r '.execution_analysis.completed // false' memory/run_state.json)

  if [ "$execution_analysis" != "true" ]; then
    echo "🚨 GATE 2 VIOLATION: Cannot fix without execution analysis!"
    echo "Required: Call Analyst to analyze last 5 executions FIRST."
    echo "Must identify: WHERE it breaks, WHY, root cause."
    exit 1
  fi

  # Verify quality of analysis
  root_cause=$(jq -r '.execution_analysis.root_cause // ""' memory/run_state.json)
  if [ -z "$root_cause" ]; then
    echo "🚨 GATE 2 VIOLATION: Execution analysis incomplete!"
    echo "Required: root_cause must be identified."
    exit 1
  fi

  echo "✅ GATE 2 PASS: Execution analysis completed (root cause: $root_cause)"
fi
```

### Related Learnings:
- **L-093:** Execution Log Analysis MANDATORY

---

## GATE 3: Phase 5 Real Testing (Priority 3)

**Applied:** BEFORE accepting QA PASS

**Problem:** Validation checks structure, not functionality (undefined values pass validation!).

**Evidence:** v145 validated successfully but Test 5 failed - only execution logs showed `p_telegram_user_id: undefined`.

### Validation ≠ Execution Success

| Check Type | What It Proves | Example |
|------------|----------------|---------|
| Validation | Structure correct | Nodes connected, expressions valid syntax |
| Execution | Functionality works | HTTP request contains user_id=682776858 |

### FORBIDDEN:
```
❌ QA: "Validation passed → mark complete"
❌ Orchestrator: "Great! Task done."
```

### REQUIRED:
```
✅ QA: "Validation passed → request user testing"
✅ Orchestrator → User: "Please send test message to bot"
✅ User: Sends real message
✅ QA: Checks execution logs → HTTP request body contains user_id ✅
✅ Orchestrator: "Execution proves success → mark complete"
```

### Enforcement (Orchestrator):

```bash
qa_status=$(jq -r '.qa_report.status // ""' memory/run_state.json)

if [ "$qa_status" = "PASS" ]; then
  phase_5_executed=$(jq -r '.qa_report.phase_5_executed // false' memory/run_state.json)

  if [ "$phase_5_executed" != "true" ]; then
    echo "🚨 GATE 3 VIOLATION: QA reported PASS without Phase 5 real testing!"
    echo "Required: QA must trigger workflow and verify execution."
    echo "Validation = structure check. Execution = functionality proof!"
    exit 1
  fi

  # Verify execution logs checked
  execution_verified=$(jq -r '.qa_report.execution_logs_verified // false' memory/run_state.json)
  if [ "$execution_verified" != "true" ]; then
    echo "🚨 GATE 3 VIOLATION: Phase 5 executed but logs not verified!"
    echo "Required: Check actual HTTP request bodies, node outputs."
    exit 1
  fi

  echo "✅ GATE 3 PASS: Phase 5 real testing + execution logs verified"
fi
```

### Related Learnings:
- **L-096:** Validation ≠ Execution Success

---

## GATE 4: Knowledge Base First (Priority 4)

**Applied:** BEFORE web search (Researcher agent)

**Problem:** Similar issues solved before, but agents repeat mistakes.

**Evidence:** L-089, L-090 existed but weren't checked → wasted 5 hours reinventing solution.

### FORBIDDEN:
```
❌ Researcher: "Unknown issue → WebSearch immediately"
```

### REQUIRED:
```
✅ Researcher: "Check LEARNINGS-INDEX.md FIRST"
✅ Grep: "AI Agent", "telegram_user_id", "$fromAI"
✅ Found: L-089, L-090 (AI input scope issues)
✅ Apply proven solution
✅ IF NOT FOUND → WebSearch → Create new learning
```

### Enforcement (Researcher agent):

```bash
# Before WebSearch or external research:
if [ ! -f "memory/agent_results/learnings_check.json" ]; then
  echo "🚨 GATE 4 VIOLATION: WebSearch before LEARNINGS.md check!"
  echo "Required: Grep LEARNINGS-INDEX.md first."
  exit 1
fi

# Verify Grep was performed
grep_keywords=$(jq -r '.learnings_check.keywords_searched // []' memory/agent_results/learnings_check.json)
if [ "$grep_keywords" = "[]" ]; then
  echo "🚨 GATE 4 VIOLATION: Empty keywords search!"
  echo "Required: Extract keywords from issue, Grep LEARNINGS-INDEX.md."
  exit 1
fi

echo "✅ GATE 4 PASS: LEARNINGS.md checked first (keywords: $grep_keywords)"
```

### Algorithm (Researcher):

```
1. Extract keywords from issue (e.g., "AI Agent", "telegram_user_id")
2. Grep LEARNINGS-INDEX.md for keywords
3. IF found matching L-XXX:
   → Read those sections from LEARNINGS.md
   → Apply proven solution
   → DONE (time saved: 90%)
4. IF NOT found:
   → WebSearch official docs + community
   → Create new learning after success
```

### Related Learnings:
- **L-091:** Deep Research Before Building (includes LEARNINGS.md check)

---

## GATE 5: n8n API = Source of Truth (Priority 5 - L-074)

**Applied:** AFTER Builder completes (verify claims)

**Problem:** Agents fake success by writing files without MCP calls.

**Evidence:** L-073 fake success pattern - Builder claimed workflow exists, but n8n API showed nothing.

### Files Are Caches (May Be Stale/Fake)

| Data | ❌ NOT Source of Truth | ✅ Source of Truth |
|------|----------------------|-------------------|
| Workflow exists? | `canonical.json` file | `n8n_get_workflow` MCP call |
| Node count | `run_state.workflow.node_count` | API response `.nodes.length` |
| Version | File timestamp | API `versionCounter` |
| Tool works? | Validation PASS | Execution logs with real data |

### FORBIDDEN:
```
❌ Builder: "Workflow created! (writes file with fake data)"
❌ Orchestrator: "Great! (trusts file)"
```

### REQUIRED:
```
✅ Builder: Calls n8n_create_workflow MCP → logs mcp_calls array
✅ Orchestrator: Verifies mcp_calls exists and not empty
✅ Orchestrator: Double-checks via n8n_get_workflow
✅ IF workflow exists → PASS
✅ IF workflow missing → BLOCKED (L-073 fraud)
```

### Enforcement (Orchestrator):

```bash
# After Builder returns:
build_result_file="memory/agent_results/build_result_*.json"

if [ -f "$build_result_file" ]; then
  builder_status=$(jq -r '.build_result.status // ""' "$build_result_file")

  if [ "$builder_status" = "success" ]; then
    mcp_calls=$(jq -r '.build_result.mcp_calls // []' "$build_result_file")

    # Check MCP calls exist
    if [ "$mcp_calls" = "[]" ]; then
      echo "🚨 GATE 5 VIOLATION: Builder success without MCP call proof!"
      echo "Possible L-073 fake success detected."
      jq '.stage = "blocked" | .block_reason = "L-073: No MCP calls"' memory/run_state.json > tmp && mv tmp memory/run_state.json
      exit 1
    fi

    # Verify workflow exists via MCP
    workflow_id=$(jq -r '.workflow_id' memory/run_state.json)

    # Delegate verification to Researcher (Orchestrator can't use MCP!)
    Task({
      subagent_type: "general-purpose",
      prompt: "## ROLE: Researcher\nVerify workflow $workflow_id exists via n8n_get_workflow. Return {exists: true/false}"
    })

    # Check result
    exists=$(jq -r '.verification.exists' memory/agent_results/verification.json)
    if [ "$exists" != "true" ]; then
      echo "🚨 GATE 5 VIOLATION: Workflow $workflow_id NOT found in n8n!"
      jq '.stage = "blocked" | .block_reason = "L-073: Workflow not in n8n"' memory/run_state.json > tmp && mv tmp memory/run_state.json
      exit 1
    fi

    echo "✅ GATE 5 PASS: MCP calls verified + workflow exists in n8n"
  fi
fi
```

### Anti-Fake Rules:
- **L-071:** Builder MUST log `mcp_calls` array in agent_log
- **L-072:** QA MUST verify via MCP before validating
- **L-073:** Orchestrator MUST check `mcp_calls` exists
- **L-074:** Files = caches. Only MCP calls = reality.

---

## GATE 6: Context Injection for Cycle 2+ (Prevent Repeated Mistakes)

**Applied:** BEFORE Builder call in cycles 2+

**Problem:** Builder doesn't know what was already tried (especially after rollback).

**Evidence:** Cycles 2-3 repeated same fix attempts from cycle 1.

### FORBIDDEN:
```
❌ Cycle 2: Builder tries same approach as Cycle 1 (doesn't know it failed)
```

### REQUIRED:
```
✅ Orchestrator extracts last 3 builder actions from agent_log
✅ Includes in Task prompt: "⚠️ ALREADY TRIED (don't repeat!): ..."
✅ Builder tries DIFFERENT approach
```

### Enforcement (Orchestrator):

```bash
# Before Builder call in cycles 2+:
cycle=$(jq -r '.cycle_count // 0' memory/run_state.json)

if [ "$cycle" -ge 2 ]; then
  # Extract recent builder actions
  recent_builder=$(jq -c '[.agent_log[] | select(.agent=="builder")] | .[-3:]' memory/run_state.json)

  if [ "$recent_builder" = "[]" ]; then
    echo "⚠️ GATE 6 WARNING: No builder history found for cycle $cycle"
    # Not blocking, but log warning
  else
    # Format for prompt
    already_tried=$(echo "$recent_builder" | jq -r '.[] | "- \(.action): \(.details)"')

    # Add to Task prompt
    prompt_addition="
⚠️ ALREADY TRIED (don't repeat!):
$already_tried

Try a DIFFERENT approach this time.
"

    echo "✅ GATE 6 PASS: Context injection prepared (cycle $cycle)"
  fi
fi
```

### Implementation:

Included in Task call:
```javascript
Task({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: `## ROLE: Builder Agent
Read: .claude/agents/builder.md

## CONTEXT
Read state from: memory/run_state.json

## TASK
Fix workflow per edit_scope.

${already_tried ? prompt_addition : ''}

edit_scope: ${edit_scope}
qa_report: ${qa_report_summary}`
})
```

---

## Gate Enforcement Checklist (Orchestrator)

### Before EVERY agent Task call:

```bash
# 1. Check applicable gates
check_gate_0_research_phase()        # BEFORE first Builder
check_gate_1_progressive_escalation() # cycles 1-7
check_gate_2_execution_analysis()     # BEFORE fix attempts
check_gate_6_context_injection()      # cycles 2+

# 2. Call agent via Task
Task({ ... })

# 3. After agent returns:
check_gate_5_mcp_verification()       # AFTER Builder
check_gate_4_knowledge_base()         # AFTER Researcher
check_gate_3_phase_5_testing()        # BEFORE accepting QA PASS
```

### If ANY gate fails:
```bash
echo "🚨 GATE VIOLATION: $gate_name"
echo "Required: $requirement"
exit 1
```

---

## Success Metrics

### Before Gates (Baseline):
- Time: 5 hours (300 minutes)
- Failed attempts: 8+
- User frustration: High
- Research time: 0

### After Gates (Target):
- Time: 30 minutes (10x improvement)
- Failed attempts: 0-1
- User frustration: None
- Research time: 15 minutes (saves 285 minutes!)

### Gate Hit Rates (Expected):
- GATE 0: 100% (all tasks)
- GATE 1: ~30% (progressive escalation needed)
- GATE 2: ~50% (half are fixes)
- GATE 3: 100% (all QA PASS)
- GATE 4: 100% (all research)
- GATE 5: 100% (all Builder calls)

---

## Related Documents

- `.claude/PROGRESSIVE-ESCALATION.md` - Detailed escalation matrix
- `docs/learning/LEARNINGS.md` - L-091 to L-096
- `POST_MORTEM_TASK24.md` - Original analysis

---

**Gates enforce process discipline. Process discipline prevents 5-hour failures.**

**15 minutes of research saves 285 minutes of wasted work.**
