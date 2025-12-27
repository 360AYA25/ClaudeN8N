# Progressive Escalation Protocol

**Version:** 3.6.0
**Created:** 2025-12-04 (POST_MORTEM_TASK24.md analysis)
**Purpose:** Stop agents from infinite loops, escalate intelligently

---

## Problem Statement

**Before escalation:** Builder stuck in loop for 8+ cycles, user frustrated, 5 hours wasted.

**With escalation:** Max 7 cycles with progressive help → BLOCKED at cycle 8 → user notified.

---

## Core Principle

**Same issue 3 times = escalate to higher-level agent**

| Cycles | Agent | What They Do | Why |
|--------|-------|--------------|-----|
| 1-3 | Builder | Direct fix attempts | Normal trial-and-error with learning |
| 4-5 | Researcher + Builder | Alternative approach | Builder exhausted obvious fixes |
| 6-7 | Analyst + Builder | Root cause diagnosis | Systemic issue suspected |
| 8+ | BLOCKED | Report to user | Hard cap - human help needed |

---

## Cycle-by-Cycle Breakdown

### Cycles 1-3: Builder Direct Fixes

**Who:** Builder alone

**What:** Try fixes based on:
- QA's edit_scope
- Error messages from previous cycle
- Quick hypothesis testing

**Context Injection (GATE 6):**
- Orchestrator extracts last 3 builder actions
- Includes in prompt: "⚠️ ALREADY TRIED: ..."
- Builder must try DIFFERENT approach

**Example:**
```
Cycle 1: Builder changes promptType: auto → define
Cycle 2: Builder updates jsonBody format (knows Cycle 1 failed)
Cycle 3: Builder tries different System Prompt (knows Cycles 1-2 failed)
```

**Success Rate:** ~60% (most issues fixed by cycle 3)

**Escalate if:** Cycle 3 fails → move to Researcher

---

### Cycles 4-5: Researcher Finds Alternative

**Who:** Researcher → Builder

**What Researcher Does:**
1. Read LEARNINGS.md for similar solved issues
2. Analyze execution logs (if not done yet)
3. Web search for alternative patterns
4. Propose DIFFERENT solution approach (not variation of Builder's attempts)

**What Builder Does:**
- Receives proven alternative from Researcher
- Implements alternative approach
- NOT another variation of cycles 1-3!

**Example (Task 2.4):**
```
Cycles 1-3: Builder tried variations of AI Agent config
Cycle 4: Researcher finds "Code Node Injection" pattern (community workflow 2035)
Cycle 5: Builder implements Code Node Injection → SUCCESS
```

**Success Rate:** ~30% (new approach works when old exhausted)

**Escalate if:** Cycle 5 fails → move to Analyst

---

### Cycles 6-7: Analyst Diagnoses Root Cause

**Who:** Analyst → Researcher → Builder

**What Analyst Does:**
1. Deep execution log analysis (all failed attempts)
2. Identify systemic issue (not surface symptom)
3. Check for anti-patterns (L-060, L-056, etc.)
4. Propose structural fix (not parameter tweak)

**What Researcher Does:**
- Receives root cause from Analyst
- Finds solution for systemic issue
- May involve architecture change

**What Builder Does:**
- Implements structural fix
- May require snapshot rollback if major change

**Example:**
```
Cycles 1-5: All attempts failed
Cycle 6: Analyst finds $node["..."] deprecated syntax in 7 Code nodes (L-060)
Cycle 7: Builder replaces with $("...").item.json (all Code nodes fixed) → SUCCESS
```

**Success Rate:** ~9% (deep issues, but fixable)

**Escalate if:** Cycle 7 fails → BLOCKED

---

### Cycle 8+: BLOCKED - User Intervention Required

**Who:** Orchestrator reports to user

**What Happens:**
1. Orchestrator sets `stage = "blocked"`
2. Analyst creates post-mortem report
3. User receives full context:
   - All 7 attempts summary
   - Root cause (if identified)
   - Recommended next steps
   - Rollback option

**User Options:**
1. **Manual fix:** User fixes in n8n UI, system verifies
2. **Rollback:** Restore to pre-attempt state
3. **Extend cap:** +3 attempts (if close to solution)
4. **Different approach:** User provides new direction

**Why BLOCKED:**
- 7 attempts failed = systemic issue beyond automation
- Human context needed (business logic, external dependencies)
- Cost cap reached (~$0.50 for 7 cycles)

**Example Report:**
```markdown
## Task BLOCKED After 7 Cycles

**Problem:** AI Agent tools not receiving telegram_user_id

**Attempts Summary:**
- Cycles 1-3: Builder tried config variations (promptType, jsonBody)
- Cycles 4-5: Researcher proposed Code Node Injection → implemented → still failed
- Cycles 6-7: Analyst found root cause (System Prompt wrong format) → fixed → still failed

**Root Cause:** AI Agent System Prompt doesn't teach extraction from [SYSTEM:...] prefix

**Recommended Next Steps:**
1. Manual: Update System Prompt in n8n UI with exact instructions
2. Rollback: Restore to v157 (before changes)
3. Different approach: Use webhook query params instead of AI extraction

**Cost:** $0.42 (7 cycles × Opus builder + Sonnet others)

Choose action: [1/2/3]
```

---

## Escalation Decision Tree

```
┌─────────────────────────────────────────────┐
│ QA Validation FAILED                        │
└─────────────────┬───────────────────────────┘
                  │
            ┌─────▼──────┐
            │ Cycle 1-3? │
            └─────┬──────┘
                  │
        ┌─────────┴─────────┐
        │                   │
       YES                 NO
        │                   │
        ▼                   ▼
  ┌──────────┐      ┌──────────┐
  │ Builder  │      │ Cycle 4-5?│
  │  Direct  │      └─────┬──────┘
  │   Fix    │            │
  └──────────┘    ┌───────┴────────┐
                  │                │
                 YES              NO
                  │                │
                  ▼                ▼
          ┌───────────┐    ┌──────────┐
          │Researcher │    │ Cycle 6-7?│
          │Alternative│    └─────┬──────┘
          └───────────┘          │
                         ┌───────┴────────┐
                         │                │
                        YES              NO
                         │                │
                         ▼                ▼
                 ┌───────────┐    ┌──────────┐
                 │  Analyst  │    │ Cycle 8+?│
                 │Root Cause │    └─────┬─────┘
                 └───────────┘          │
                                       YES
                                        │
                                        ▼
                                ┌──────────────┐
                                │   BLOCKED    │
                                │Report to User│
                                └──────────────┘
```

---

## Orchestrator Enforcement Logic

### Before EVERY Builder call in QA loop:

```bash
#!/bin/bash

cycle=$(jq -r '.cycle_count // 0' memory/run_state.json)
stage=$(jq -r '.stage' memory/run_state.json)

# Only enforce in build/validate stages
if [ "$stage" != "build" ] && [ "$stage" != "validate" ]; then
  exit 0
fi

# Cycle 1-3: Builder OK, add context injection
if [ "$cycle" -ge 1 ] && [ "$cycle" -le 3 ]; then
  echo "✅ Cycle $cycle: Builder direct fix (with context injection)"

  # GATE 6: Context injection
  recent_builder=$(jq -c '[.agent_log[] | select(.agent=="builder")] | .[-3:]' memory/run_state.json)
  if [ "$recent_builder" != "[]" ]; then
    echo "📝 Context: Builder knows previous attempts"
  fi

  # Proceed to Builder
  exit 0
fi

# Cycle 4-5: MUST call Researcher FIRST
if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ]; then
  researcher_called=$(jq -r '[.agent_log[] | select(.agent=="researcher" and .cycle=='$cycle')] | length > 0' memory/run_state.json)

  if [ "$researcher_called" != "true" ]; then
    echo "🚨 ESCALATION VIOLATION: Cycle $cycle requires Researcher FIRST!"
    echo "Required: Find alternative approach (not variation of cycles 1-3)"
    exit 1
  fi

  echo "✅ Cycle $cycle: Researcher provided alternative approach"
  # Proceed to Builder with Researcher's guidance
  exit 0
fi

# Cycle 6-7: MUST call Analyst FIRST
if [ "$cycle" -ge 6 ] && [ "$cycle" -le 7 ]; then
  analyst_called=$(jq -r '[.agent_log[] | select(.agent=="analyst" and .cycle=='$cycle')] | length > 0' memory/run_state.json)

  if [ "$analyst_called" != "true" ]; then
    echo "🚨 ESCALATION VIOLATION: Cycle $cycle requires Analyst FIRST!"
    echo "Required: Root cause diagnosis (systemic issue suspected)"
    exit 1
  fi

  echo "✅ Cycle $cycle: Analyst diagnosed root cause"
  # Proceed to Builder with Analyst's diagnosis
  exit 0
fi

# Cycle 8+: BLOCKED
if [ "$cycle" -ge 8 ]; then
  echo "🚨 ESCALATION HARD CAP: Cycle $cycle blocked!"
  echo "Setting stage = blocked, requesting user intervention..."

  jq '.stage = "blocked" |
      .block_reason = "7 QA cycles exhausted" |
      .blocked_at = now |
      .worklog += [{
        ts: now,
        cycle: '$cycle',
        agent: "orchestrator",
        action: "hard_cap_reached",
        outcome: "blocked"
      }]' memory/run_state.json > tmp.json && mv tmp.json memory/run_state.json

  # Trigger Analyst post-mortem
  echo "📊 Delegating to Analyst for post-mortem analysis..."

  exit 1
fi
```

---

## Agent-Specific Responsibilities

### Orchestrator:
- ✅ Check cycle count before EVERY Builder call
- ✅ Enforce escalation gates (GATE 1)
- ✅ Inject context in cycles 2+ (GATE 6)
- ✅ BLOCK at cycle 8
- ✅ Trigger Analyst post-mortem when blocked

### Builder (Cycles 1-3):
- ✅ Read context injection ("ALREADY TRIED: ...")
- ✅ Try DIFFERENT approach each cycle
- ✅ Log attempts to agent_log with details
- ❌ NO repeated attempts of same solution

### Researcher (Cycles 4-5):
- ✅ Read all previous Builder attempts
- ✅ Find ALTERNATIVE approach (not variation!)
- ✅ Use LEARNINGS.md, web search, templates
- ✅ Provide proven solution to Builder
- ❌ NO minor tweaks to previous approach

### Analyst (Cycles 6-7):
- ✅ Deep dive: all executions, all attempts
- ✅ Identify SYSTEMIC issue (root cause)
- ✅ Check for anti-patterns (L-060, L-056)
- ✅ Propose structural fix
- ❌ NO surface-level parameter changes

### Analyst (Cycle 8 - Post-Mortem):
- ✅ Create comprehensive failure report
- ✅ Identify learnings (L-XXX candidates)
- ✅ Recommend rollback or manual intervention
- ✅ Calculate cost, time wasted
- ✅ Update LEARNINGS.md if new pattern found

---

## Success Metrics

### Time Savings:
- **Without escalation:** Infinite loop possible (5+ hours seen)
- **With escalation:** Max 90 minutes (7 cycles × ~12 min avg)
- **Typical success:** 30-45 minutes (cycles 1-5)

### Success Rate by Cycle:
| Cycle | Cumulative Success | Incremental |
|-------|-------------------|-------------|
| 1 | 30% | 30% |
| 2 | 50% | 20% |
| 3 | 60% | 10% |
| 4 | 75% | 15% (Researcher help) |
| 5 | 85% | 10% |
| 6 | 91% | 6% (Analyst help) |
| 7 | 94% | 3% |
| 8+ | BLOCKED | 6% need user |

**Interpretation:** 94% of issues resolved by cycle 7. Remaining 6% require human context.

### Cost Control:
- **Max cost per task:** ~$0.50 (7 cycles hard cap)
- **Avg cost for success:** ~$0.18 (cycles 1-5 typical)
- **Cost breakdown:**
  - Builder (GLM 4.7): $0.004/cycle (~10x cheaper!)
  - Researcher (Sonnet): $0.015/cycle
  - Analyst (Sonnet): $0.015/cycle

---

## Edge Cases

### Rollback Between Cycles
**Scenario:** User manually rollbacks workflow in n8n UI between cycles

**Detection:**
```bash
# Orchestrator checks versionCounter after each Builder
previous_counter=$(jq -r '.workflow.versionCounter' memory/run_state.json)
current_counter=$(get_workflow_version_via_mcp)

if [ "$current_counter" -lt "$previous_counter" ]; then
  CRITICAL_ALERT("User rolled back workflow! Stopping build cycle.")
  ASK_USER("Workflow reverted. Re-apply fix? [Y/N]")
fi
```

**Action:** STOP escalation, ask user intent

---

### New Session After Failure
**Scenario:** Previous session blocked at cycle 7, new session starts

**Detection:**
```bash
# Check for stale run_state
if [ -f memory/run_state.json ]; then
  old_stage=$(jq -r '.stage' memory/run_state.json)
  old_cycle=$(jq -r '.cycle_count' memory/run_state.json)

  if [ "$old_stage" = "blocked" ]; then
    echo "⚠️ Previous session BLOCKED at cycle $old_cycle"
    echo "Options:"
    echo "  [C]ontinue - Resume from blocked state (+3 attempts)"
    echo "  [R]eset - Fresh start (archive old run_state)"
    # WAIT FOR USER
  fi
fi
```

**Action:** User decides continue or reset

---

### Multiple Issues in Workflow
**Scenario:** Fix one issue reveals another

**Detection:**
```bash
# After successful fix:
if [ "$qa_status" = "PASS" ] && [ "$user_test_status" = "FAIL" ]; then
  echo "⚠️ Fix successful but new issue found"
  echo "Options:"
  echo "  [N]ew cycle - Treat as new issue (reset cycle_count)"
  echo "  [C]ontinue - Count as same issue (keep cycle_count)"
fi
```

**Action:** Reset cycle if genuinely different issue

---

## Related Documents

- `.claude/VALIDATION-GATES.md` - GATE 1 (Progressive Escalation)
- `docs/learning/LEARNINGS.md` - L-094 (Progressive Escalation Enforcement)
- `POST_MORTEM_TASK24.md` - Original analysis

---

**Progressive escalation stops infinite loops.**

**7 cycles max = cost control + quality gate.**

**Cycle 8 = human context needed.**
