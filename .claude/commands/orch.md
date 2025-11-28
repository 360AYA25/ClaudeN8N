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

## Session Start

When `/orch` is invoked:

1. **Initialize or load run_state**
   ```
   Read memory/run_state.json
   If empty or finalized → create new with UUID
   ```

2. **Parse user request**
   ```
   Extract: goal, services, constraints
   Set: stage="clarification", cycle_count=0
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

Level 3: FULL_INVESTIGATION (all agents, ~10K+ tokens)
├── Trigger: Complex issue, escalated from L1/L2
├── Full system: Architect → Researcher → Builder → QA → Analyst
└── Used for: architectural issues, multiple failures
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
