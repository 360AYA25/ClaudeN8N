# /orch — 5-Agent n8n Workflow Orchestration

## 📋 Доступные режимы

| Команда | Описание |
|---------|----------|
| `/orch <задача>` | Создать/изменить workflow (5-phase flow) |
| `/orch workflow_id=X <задача>` | Модифицировать существующий workflow (MODIFY flow) |
| `/orch --fix workflow_id=X node="Y" error="Z"` | **L1 Quick Fix** (~500 tokens) |
| `/orch --debug workflow_id=X` | **L2 Targeted Debug** (~2K tokens) |
| `/orch --test` | Quick health check всех агентов |
| `/orch --test agent:builder` | Тест Builder агента |
| `/orch --test agent:qa` | Тест QA агента |
| `/orch --test agent:researcher` | Тест Researcher агента |
| `/orch --test agent:architect` | Тест Architect агента |
| `/orch --test agent:analyst` | Тест Analyst агента |
| `/orch --test e2e` | Full E2E тест — создает реальный workflow 20+ нод |

---

## Overview
Launch the multi-agent system to create, modify, or fix n8n workflows.

## Usage

### Basic
```
/orch Create a webhook that saves data to Supabase
```

### With Parameters
```
/orch goal="Telegram bot" services="telegram,supabase" workflow_id="abc"
```

### Test Mode
```
/orch --test              # Test all agents
/orch --test agent:builder  # Test specific agent
/orch --test e2e          # End-to-End production test (20+ nodes)
```

## Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `goal` | string | (from prompt) | Task description |
| `services` | comma-separated | (auto-detect) | Services to integrate |
| `workflow_id` | string | null | Existing workflow to modify |

---

## Execution Protocol

### Calling Agents

```javascript
// ✅ CORRECT:
Task({ agent: "architect", prompt: "Clarify requirements..." })

// ❌ WRONG (don't use subagent_type for custom agents!):
Task({ subagent_type: "architect", prompt: "..." })
```

### Agent Delegation

| Stage | Agent | Model |
|-------|-------|-------|
| clarification | architect | sonnet |
| research | researcher | sonnet |
| decision | architect | sonnet |
| credentials | researcher | sonnet |
| implementation | researcher | sonnet |
| build | builder | opus 4.5 |
| validate/test | qa | sonnet |
| analysis | analyst | sonnet |

### Context Passing

1. **In prompt**: Pass ONLY summary (not full JSON!)
2. **Agent reads**: `memory/run_state.json` for details
3. **Agent writes**: Results to run_state + `memory/agent_results/`
4. **Return**: Summary only (~500 tokens max)

### 🛑 MANDATORY Validation Gates

**See `.claude/agents/validation-gates.md` for full rules.**

**GATE 1: Execution Analysis Required (DEBUGGING ONLY)**
```javascript
// BEFORE any fix attempt:
if (user_reports_broken && !execution_data_analyzed) {
  BLOCK("❌ FORBIDDEN: Fix without execution analysis!");
  REQUIRE: researcher.analyze_execution_data();
  // Researcher MUST get execution logs, identify stopping point
}
```

**GATE 2: Hypothesis Validation Required**
```javascript
// BEFORE calling Builder:
if (!research_findings.hypothesis_validated) {
  BLOCK("❌ FORBIDDEN: Unvalidated hypothesis!");
  REQUIRE: researcher.validate_with_mcp_tools();
  // Researcher MUST use get_node to verify configuration
}

if (!research_findings || !build_guidance_file_exists) {
  BLOCK("❌ FORBIDDEN: Missing research or build_guidance!");
}

if (modifying_workflow && !user_approval) {
  BLOCK("❌ FORBIDDEN: User approval required for modifications!");
}
```

**GATE 3: Post-Build Verification Required**
```javascript
// AFTER Builder completes:
if (builder_result.version_id) {
  REQUIRE: orchestrator.verify_changes_applied();
  // 1. Read workflow via MCP
  // 2. Check version_id changed
  // 3. Verify expected parameters present
  // 4. Detect rollback (version_counter decreased)
}
```

**GATE 4: Circuit Breaker**
```javascript
// If 2 cycles with same hypothesis:
if (cycle_count >= 2 && current_hypothesis === previous_hypothesis) {
  ESCALATE_TO_L4();
  REQUIRE: analyst.audit_methodology();
  REASON: "Not learning from failures";
}

// If 3 QA failures in a row:
if (qa_fail_count >= 3) {
  ESCALATE_TO_L4();
  ANALYST_AUDIT_METHODOLOGY();
}
```

**Before workflow mutation:**
- ❌ FORBIDDEN if 3+ nodes AND NOT incremental mode
- ❌ FORBIDDEN if stage !== "build"

### Context Isolation

Each `Task({ agent: "..." })` = **NEW PROCESS**:
- Clean context (~30-75K tokens)
- Model from agent's frontmatter
- Tools from agent's frontmatter
- Contexts do NOT overlap — exchange via files!

### Algorithm

1. Read `memory/run_state.json` or initialize new
2. Check stage, delegate to agent:
   - `clarification` → architect
   - `research` → researcher
   - `decision` → architect
   - `implementation` → researcher
   - `build` → builder
   - `validate/test` → qa
3. Receive updated run_state
4. Advance stage based on output

### Hard Rules

- **NEVER** mutate workflows (only list/get)
- **ALWAYS** advance stage forward (never rollback)
- **ALWAYS** fill `worklog` and `agent_log`

### Output Formats

- **worklog**: `{ ts, cycle, agent, action, outcome }`
- **agent_log**: `{ ts, agent, action, details }`

---

## 5-PHASE FLOW (Unified)

**No complexity detection!** All requests follow the same flow:

```
PHASE 1: CLARIFICATION
├── User request → Architect
├── Architect ←→ User (диалог)
└── Output: requirements

PHASE 2: RESEARCH
├── Architect → Orchestrator → Researcher
├── Search: local → existing → templates → nodes
└── Output: research_findings (fit_score, popularity)

PHASE 3: DECISION + CREDENTIALS
├── Researcher → Orchestrator → Architect
├── Architect ←→ User (выбор варианта)
├── Orchestrator → Researcher (discover credentials)
├── Researcher → Orchestrator (credentials_discovered)
├── Orchestrator → Architect (present credentials)
├── Architect ←→ User (select credentials)
├── Modify existing > Build new
└── Output: decision + blueprint + credentials_selected

PHASE 4: IMPLEMENTATION
├── Architect → Orchestrator → Researcher (deep dive)
├── Study: learnings → patterns → node configs
└── Output: build_guidance (gotchas, configs, warnings)

PHASE 5: BUILD
├── Researcher → Orchestrator → Builder → QA
├── QA Loop: max 7 cycles (progressive), then blocked
└── Output: completed workflow
```

---

## Project Selection

Detect if working on external project:

```bash
# Parse --project flag from user_request
if [[ "$user_request" =~ --project=([a-z-]+) ]]; then
  project_id="${BASH_REMATCH[1]}"

  # Set project_path based on ID
  case "$project_id" in
    "food-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/food-tracker"
      ;;
    "health-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/health-tracker"
      ;;
    "clauden8n"|"")
      project_path="/Users/sergey/Projects/ClaudeN8N"
      project_id="clauden8n"
      ;;
  esac
else
  # Check if run_state has project context from previous session
  if [ -f memory/run_state.json ]; then
    project_id=$(jq -r '.project_id // "clauden8n"' memory/run_state.json)
    project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state.json)
  else
    # Default to ClaudeN8N
    project_id="clauden8n"
    project_path="/Users/sergey/Projects/ClaudeN8N"
  fi
fi
```

**Project context stored in run_state:**
```json
{
  "project_id": "$project_id",
  "project_path": "$project_path",
  ...
}
```

**Agents will read project_path from run_state** to access project-specific documentation (TODO.md, SESSION_CONTEXT.md, ARCHITECTURE.md).

---

## Session Start

When `/orch` is invoked:

1. **Initialize or load run_state**
   ```
   Read memory/run_state.json
   If empty or finalized → create new with UUID
   Add project_id and project_path from Project Selection above
   ```

2. **Parse user request**
   ```
   Extract: goal, services, constraints
   Set: stage="clarification", cycle_count=0
   Set: project_id, project_path (from Project Selection)
   ```

3. **Start Architect for clarification**
   ```
   Task(agent=architect, prompt="Clarify requirements with user")
   ```

## Context Passed to Agents

Each agent receives full `run_state`:
- `id`, `user_request`, `goal`
- `stage`, `cycle_count`
- `requirements` (from Architect Phase 1)
- `research_request` (from Architect Phase 2)
- `research_findings` (from Researcher)
- `decision` (from Architect Phase 3)
- `blueprint` (from Architect Phase 3)
- `credentials_discovered` (from Researcher Phase 3 - scanned from existing workflows)
- `credentials_selected` (from Architect Phase 3 - user-chosen credentials)
- `build_guidance` (from Researcher Phase 4 - gotchas, node configs, warnings)
- `workflow` (from Builder)
- `qa_report` (from QA)
- `edit_scope` (nodes to modify)
- `worklog`, `agent_log` (history)

## Stage Transitions

### CREATE Flow (new workflow)
```
clarification → research → decision → credentials → implementation → build → validate → test → complete
                                                                                           ↓
                                                                                        blocked (after 7 QA fails)
```

### MODIFY Flow (existing workflow)
```
clarification → IMPACT_ANALYSIS → research → decision → credentials → implementation →
    ↓
INCREMENTAL_BUILD (with checkpoints)
    ↓
  [modify node_1] → checkpoint_qa → USER_APPROVAL
    ↓
  [modify node_2] → checkpoint_qa → USER_APPROVAL
    ↓
  [verify affected] → checkpoint_qa → USER_APPROVAL
    ↓
final_validate → complete | blocked
```

**CRITICAL:** System WAITS for user "да"/"ok"/"next" after each checkpoint!

## QA Loop (max 7 cycles — progressive)

```
QA fail → Builder fix (edit_scope) → QA → repeat
├── Cycle 1-3: Builder fixes directly
├── Cycle 4-5: Researcher helps find alternative approach
├── Cycle 6-7: Analyst diagnoses root cause
└── After 7 fails → stage="blocked" → report to user with full history
```

---

## Post-Build Verification Protocol

**Orchestrator MUST verify AFTER every Builder execution:**

```bash
# 1. Read updated workflow
workflow=$(mcp__n8n-mcp__n8n_get_workflow id=$workflow_id mode="full")

# 2. Verify version changed
current_version=$(echo $workflow | jq -r '.versionId')
if [ "$current_version" == "$previous_version" ]; then
  FAIL("❌ CRITICAL: Workflow version didn't change! Update may have failed silently.");
  BLOCK_QA();
  REPORT_TO_USER();
fi

# 3. Verify specific changes (from build_guidance expected_changes)
for change in "${expected_changes[@]}"; do
  node=$(echo $workflow | jq ".nodes[] | select(.name == \"${change.node}\")")
  actual_value=$(echo $node | jq -r ".parameters.${change.parameter}")

  if [ "$actual_value" != "${change.value}" ]; then
    FAIL("❌ Change not applied: ${change.node}.${change.parameter} = $actual_value (expected: ${change.value})");
    BLOCK_QA();
  fi
done

# 4. Detect rollback
version_counter=$(echo $workflow | jq -r '.versionCounter')
if [ $version_counter -lt $previous_counter ]; then
  CRITICAL_ALERT("⚠️ Version rollback detected! User may have reverted changes in UI.");
  STOP_BUILD_CYCLE();
  NOTIFY_USER("Workflow was rolled back after our update. Previous: $previous_counter, Current: $version_counter");
fi

# 5. Check node count matches
if [ $(echo $workflow | jq '.nodes | length') != $expected_node_count ]; then
  WARN("Node count mismatch - possible data corruption");
fi
```

**If verification fails:**
1. BLOCK QA from running
2. Report failure details to user
3. Provide rollback option
4. Do NOT continue build cycle

**If rollback detected:**
1. STOP immediately
2. Alert user: "Workflow reverted in UI - conflicts with our changes"
3. Ask: Re-apply fix? OR Abort?

## Test Mode

### `--test` (Quick health check)
Tests each agent can be invoked:

| Agent | Test | MCP Tools |
|-------|------|-----------|
| Orchestrator | read run_state | list/get workflows |
| Architect | read files + skills | **NO MCP!** |
| Researcher | search nodes/templates | full search |
| Builder | validate node config | mutations |
| QA | list workflows + executions | testing |
| Analyst | read executions | read-only |

**IMPORTANT:** Architect has NO MCP tools - only Read + Skills!

### `--test e2e` (End-to-End Production Test)

**REAL workflow test** — NOT a mock! Works exactly like normal system.

Follows **standard 5-PHASE FLOW** (no shortcuts):
- Creates REAL 20+ node workflow
- Services: Telegram, Supabase, OpenAI, HTTP
- Auto-discovers and uses real credentials
- Activates, triggers via Chat webhook, verifies execution
- Analyst report at end

**Test workflow:**
- Chat Trigger (dual mode: UI + webhook)
- AI Agent + Supabase + HTTP + Telegram
- Complex logic (IF, Switch, error handling)

**Success:** All nodes executed, services responded, no QA errors, analyst report generated.

**Cleanup:** Deactivate workflow, tag "e2e-test", keep for reference.

### `--test agent:NAME`
Tests specific agent in isolation:
```
/orch --test agent:builder
/orch --test agent:qa
/orch --test agent:researcher
```

## Examples

### Create Simple Workflow
```
/orch Create a webhook that responds with "Hello World"
```

### Create Complex Integration
```
/orch mode=complex goal="Telegram bot that saves messages to Supabase and notifies Slack" services="telegram,supabase,slack"
```

### Fix Existing Workflow
```
/orch workflow_id=abc123 Fix the Supabase insert error
```

### Run Tests
```
/orch --test e2e           # Production-grade 20+ node test
```

## Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| L1 | Simple error | Builder direct fix |
| L2 | Unknown error | Researcher → Builder |
| L3 | 7+ failures | stage="blocked" |
| L4 | Blocked | Report to user + Analyst post-mortem |

---

## Debugger Mode (Fast Fix)

### Problem
Full 5-phase flow is overkill for simple bugs (~10K+ tokens).

### Solution: 3-Level Debug System

```
Level 1: QUICK_FIX (1 agent, ~500 tokens)
├── Trigger: /orch --fix workflow_id=X node="Y" error="Z"
├── Agent: Builder ONLY
├── Flow: Read workflow → Fix node → Validate → Done
└── Escalate if: fix fails 2 times → L2

Level 2: TARGETED_DEBUG (2 agents, ~2K tokens)
├── Trigger: /orch --debug workflow_id=X
├── Agents: Analyst → Builder
├── Analyst: Read executions, find root cause, check LEARNINGS.md
├── Builder: Apply fix
└── Escalate if: root cause unclear → L3

Level 3: FULL_INVESTIGATION (NEW 9-STEP ALGORITHM!)
├── Trigger: Complex issue, user reports "bot not working"
├── **PHASE 1: FULL DIAGNOSIS** (Researcher only!)
│   ├── Download COMPLETE workflow (mode="full")
│   ├── Decompose ALL nodes (types, params, code, credentials)
│   ├── Analyze 10 executions (patterns, break points)
│   ├── Find WHERE it breaks (exact node + reason)
│   ├── Identify ROOT CAUSE (not symptom!)
│   └── Output: diagnosis_complete.json with hypothesis
├── Orchestrator presents findings to User
│   └── "Found: X breaks at node Y because Z. Approve fix?"
├── **PHASE 2: FIX + TEST**
│   ├── Builder: Create snapshot → Apply fix → Verify
│   ├── Architect → User: "Send test message to bot"
│   ├── User sends message
│   ├── QA: Phase 5 Real Testing (did bot respond?)
│   └── If bot responded → SUCCESS, else → back to PHASE 1
└── Used for: bot debugging, multi-failure workflows
```

### Auto-Detection: Which Level?

| User Input | Detected Level | Why |
|------------|----------------|-----|
| "fix X in node Y" | L1 QUICK_FIX | Specific node + action |
| "debug workflow" | L2 TARGETED | Need diagnosis first |
| "why doesn't it work" | L2 TARGETED | Root cause unknown |
| "redesign the flow" | L3 FULL | Architectural change |
| L1 failed 2x | L2 TARGETED | Auto-escalate |
| L2 unclear | L3 FULL | Auto-escalate |

### 🚨 MANDATORY Escalation Rules

**MUST use L3 FULL if ANY:**
1. ✅ 2nd+ fix attempt (previous fix didn't solve)
2. ✅ 3+ nodes modified
3. ✅ 3+ execution failures in row
4. ✅ Root cause unclear after diagnosis
5. ✅ Architectural/pattern issue

**FORBIDDEN:** Skip to L1/L2 when triggers met!

### Quick Fix Protocol (L1)

```bash
/orch --fix workflow_id=abc node="Supabase Insert" error="missing field"

# System:
# 1. Builder: Read workflow (n8n_get_workflow)
# 2. Builder: Identify node, read config
# 3. Builder: Apply fix (curl PUT)
# 4. Builder: Validate (n8n_validate_workflow)
# 5. Show result to user
# 6. If fail → escalate to L2
```

### Targeted Debug Protocol (L2)

```bash
/orch --debug workflow_id=abc

# System:
# 1. Analyst: Read recent executions (n8n_executions)
# 2. Analyst: Identify failing node + error pattern
# 3. Analyst: Check LEARNINGS.md for known solution
# 4. Present diagnosis:
#    "🔍 Проблема: Supabase Insert
#     Ошибка: missing field 'user_id'
#     Причина: Set node не передаёт это поле
#     Решение: Добавить user_id в Set node"
# 5. User approves → Builder applies fix
# 6. If unclear → escalate to L3
```

---

## Hard Caps (Resource Limits)

### Per-Task Limits

| Resource | Limit | Action on Exceed |
|----------|-------|------------------|
| Tokens | 50,000 | Stop + report |
| Agent calls | 25 | Stop + report |
| Time | 10 minutes | Stop + report |
| Cost | $0.50 | Stop + report |
| QA cycles | 7 | stage="blocked" |

### Tracking in run_state.usage

```javascript
// Check before EACH agent call:
function checkCaps() {
  const { usage } = run_state;
  const caps = {
    max_tokens: 50000,
    max_agent_calls: 25,
    max_time_seconds: 600,
    max_cost_usd: 0.50,
    max_qa_cycles: 7
  };

  if (usage.qa_cycles >= caps.max_qa_cycles) {
    return escalateToUser("QA failed 7 times. Need human help.");
  }
  if (usage.tokens_used >= caps.max_tokens) {
    return escalateToUser("Token limit reached. Task too complex?");
  }
  if (usage.cost_usd >= caps.max_cost_usd) {
    return escalateToUser("Cost limit reached.");
  }
  // ... other checks
}
```

### Escalation Dialog

```
⚠️ Hard Cap Reached

QA Cycles: 7/7 (LIMIT)
Tokens: 45K/50K
Time: 8min/10min

Проблема не решена за 7 попыток.

Варианты:
1. Показать все 7 попыток и ошибки (для анализа)
2. Откатить все изменения (Blue-Green rollback)
3. Увеличить лимит (+3 попытки) и продолжить
4. Эскалировать (manual intervention)

Выбор? (1/2/3/4)
```

---

## Handoff Contracts (Agent → Agent)

### Purpose
Validate data integrity between agent transitions.

### Contracts

| Transition | Required Fields | Validator |
|------------|-----------------|-----------|
| architect→researcher | requirements, research_request | services array not empty |
| researcher→architect | research_findings | templates or existing_workflows found |
| architect→builder | blueprint, credentials_selected | nodes_needed array not empty |
| researcher→builder | build_guidance | node_configs array not empty |
| builder→qa | workflow.id, workflow.node_count | id exists, count > 0 |
| qa→builder | qa_report, edit_scope | edit_scope array if failed |

### Validation Example

```javascript
const handoff_contracts = {
  "architect→researcher": {
    required: ["requirements", "research_request"],
    validate: (data) => {
      if (!data.requirements?.services?.length) {
        throw new Error("requirements.services required");
      }
      return true;
    }
  },
  "builder→qa": {
    required: ["workflow.id", "workflow.node_count"],
    validate: (data) => {
      if (!data.workflow?.id) {
        throw new Error("workflow.id required for QA");
      }
      return true;
    }
  }
};

// Before handoff:
function handoff(from, to, data) {
  const contract = handoff_contracts[`${from}→${to}`];
  try {
    contract.validate(data);
    log(`✅ Handoff ${from}→${to} valid`);
  } catch (error) {
    log(`❌ Handoff ${from}→${to} FAILED: ${error.message}`);
    throw new HandoffError(from, to, error);
  }
}
```

### Handoff Failure Recovery

```
❌ Handoff Failed: researcher→builder

Missing: build_guidance.node_configs

Recovery options:
1. Re-run Researcher with explicit request
2. Fill missing data manually
3. Skip to Builder with partial data (risky)

Выбор?
```

---

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
