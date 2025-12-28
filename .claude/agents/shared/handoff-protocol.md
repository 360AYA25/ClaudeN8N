# Agent Handoff Verification Protocol

> **Purpose:** Ensure next agent receives previous agent's output
> **Rule:** NO handoff = NO progress
> **Enforcement:** Orchestrator mandatory check

---

## Handoff Flow

```
Agent A completes task
    ↓
Orchestrator merges output to run_state (MANDATORY!)
    ↓
Orchestrator includes previous output in next agent prompt
    ↓
Agent B starts WITH context from Agent A
```

---

## Mandatory Handoff Matrix

| From Agent | To Agent | Handoff Data | Verification |
|------------|----------|--------------|--------------|
| **Researcher** | Builder | `build_guidance.json` → `run_state.build_guidance` | Builder prompt includes guidance |
| **Analyst** | Researcher | `root_cause.json` → `run_state.analyst_diagnosis` | Researcher prompt includes diagnosis |
| **Researcher** | Builder | `solution.json` → `run_state.researcher_solution` | Builder prompt includes solution |
| **QA** | Orchestrator | `qa_report.json` → `run_state.qa_report` | Escalation triggers checked |
| **Builder** | QA | `build_result.json` → `run_state.build_result` | QA knows what changed |

---

## Orchestrator Enforcement

### After EVERY Task delegation:

```bash
#!/bin/bash
# CRITICAL: Merge agent output to run_state (MANDATORY!)
agent_result_file="memory/agent_results/${workflow_id}/${agent}_result.json"
run_state_file="memory/run_state_active.json"

# Source merge library
source .claude/agents/shared/run-state-lib.sh

# Merge agent output to run_state
merge_agent_result "$agent" "$agent_result_file" "$run_state_file"

# Verify merge succeeded
if ! jq -e '.agent_log[] | select(.agent=="'$agent'")' "$run_state_file" >/dev/null 2>&1; then
  echo "🚨 HANDOFF FAILURE: $agent output not merged to run_state!"
  echo "Required: merge_agent_result must be called after every Task"
  exit 1
fi

echo "✅ Handoff verified: $agent output merged to run_state"
```

### Include previous output in next agent prompt:

```bash
# CRITICAL: Include merged data in next agent prompt
previous_agent_output=$(jq -r '.'"$previous_agent"_result" // empty' "$run_state_file")

if [ -n "$previous_agent_output" ]; then
  next_agent_prompt="## CONTEXT FROM PREVIOUS AGENT ($previous_agent):

$(jq -r '.'"$previous_agent"_result'' "$run_state_file")

## YOUR TASK:
..."
else
  echo "🚨 HANDOFF FAILURE: No output from $previous_agent found in run_state!"
  echo "Required: Previous agent output must be merged before calling next agent"
  exit 1
fi
```

---

## Handoff Verification Checklist

Before delegating to next agent, Orchestrator MUST:

- [ ] Called `merge_agent_result()` after previous agent completed
- [ ] Verified agent_log contains previous agent entry
- [ ] Read merged data from run_state
- [ ] Included merged data in next agent prompt
- [ ] Next agent can see previous agent's output

**If ANY check fails:** BLOCK and report handoff failure

---

## Agent-Specific Responsibilities

### Builder:
- **Before building:** Read `run_state.build_guidance` (cycle 4-5) or `run_state.analyst_diagnosis` (cycle 6-7)
- **If missing:** Report handoff failure, don't build blind
- **Example:**
  ```bash
  guidance=$(jq -r '.build_guidance.alternative_approach // empty' memory/run_state_active.json)
  if [ -z "$guidance" ]; then
    echo "🚨 HANDOFF FAILURE: No Researcher guidance in cycle $cycle!"
    exit 1
  fi
  ```

### Researcher:
- **Before researching:** Read `run_state.qa_report.issues` (what QA found)
- **Before proposing solution:** Read `run_state.analyst_diagnosis` (cycle 6-7)
- **If missing:** Report handoff failure

### QA:
- **Before validating:** Read `run_state.build_result` (what Builder changed)
- **After validation:** Write escalation trigger to run_state if cycle > 1
- **Example:**
  ```bash
  if [ "$cycle" -ge 2 ] && [ "$has_same_error" = "true" ]; then
    # Write escalation trigger (MANDATORY!)
    jq '.escalation_trigger = {level: "L2", agent: "researcher", ...}' run_state.json
  fi
  ```

### Analyst:
- **Before diagnosing:** Read full agent_log (all failed attempts)
- **After diagnosis:** Write `run_state.analyst_diagnosis` for Researcher

---

## Failure Modes

### Mode 1: run_state Not Merged

**Symptom:** Next agent asks "What did previous agent find?"

**Root Cause:** Orchestrator skipped `merge_agent_result()`

**Detection:**
```bash
# Check if previous agent in agent_log
if ! jq -e '.agent_log[] | select(.agent=="'$previous_agent'")' "$run_state_file" >/dev/null; then
  echo "🚨 HANDOFF FAILURE: $previous_agent not in agent_log!"
  echo "Orchestrator must call merge_agent_result() after Task"
  exit 1
fi
```

**Fix:** MANDATORY merge after every Task delegation

---

### Mode 2: Previous Output Not In Prompt

**Symptom:** Next agent works blind, repeats mistakes

**Root Cause:** Orchestrator didn't include run_state data in prompt

**Detection:**
```bash
# Check if prompt includes previous output
if ! echo "$next_agent_prompt" | grep -q "CONTEXT FROM PREVIOUS AGENT"; then
  echo "🚨 HANDOFF FAILURE: Prompt missing previous agent context!"
  echo "Required: Include run_state data in every prompt"
  exit 1
fi
```

**Fix:** MANDATORY context injection in every prompt

---

### Mode 3: Agent Ignores Context

**Symptom:** Agent receives guidance but ignores it

**Root Cause:** Agent file doesn't mandate reading run_state

**Detection:**
```bash
# Builder should check for guidance before building
guidance=$(jq -r '.build_guidance // empty' "$run_state_file")
if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ] && [ -z "$guidance" ]; then
  echo "🚨 HANDOFF FAILURE: No Researcher guidance in cycle $cycle!"
  echo "Builder must read run_state.build_guidance in cycles 4-5"
  exit 1
fi
```

**Fix:** Add "Read run_state first!" to agent file (see builder.md STEP 2)

---

## Related Files

- `.claude/agents/shared/run-state-lib.sh` - merge functions
- `.claude/commands/orch.md` - Orchestrator handoff logic
- `.claude/agents/validation-gates.md` - GATE 6 (context injection)
- `.claude/agents/builder.md` - Progressive escalation awareness

---

## Quick Reference

**Orchestrator:**
```bash
# After EVERY Task:
merge_agent_result "$agent" "$result_file" "$run_state_file" || exit 1

# Before NEXT Task:
previous_output=$(jq -r '.'"$agent"_result'' "$run_state_file")
next_prompt="## CONTEXT FROM $previous_output\n## YOUR TASK:..."
```

**Builder (cycles 4-5):**
```bash
guidance=$(jq -r '.build_guidance.alternative_approach' run_state.json)
[ -n "$guidance" ] || { echo "🚨 HANDOFF FAILURE!"; exit 1; }
```

**QA (escalation):**
```bash
if [ "$cycle" -ge 2 ] && [ "$same_error" = "true" ]; then
  jq '.escalation_trigger = {level: "L2"}' run_state.json
fi
```

---

**Every handoff MUST be verified.**
**No handoff = NO progress.**
**Handoff failure = STOP and report.**
