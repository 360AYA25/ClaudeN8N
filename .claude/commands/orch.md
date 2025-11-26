# /orch — 6-Agent n8n Workflow Orchestration

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
/orch --test full         # Full system test
```

## Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `goal` | string | (from prompt) | Task description |
| `services` | comma-separated | (auto-detect) | Services to integrate |
| `workflow_id` | string | null | Existing workflow to modify |

---

## 4-PHASE FLOW (Unified)

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

PHASE 3: DECISION
├── Researcher → Orchestrator → Architect
├── Architect ←→ User (выбор варианта)
├── Modify existing > Build new
└── Output: decision + blueprint

PHASE 4: BUILD
├── Architect → Orchestrator → Builder → QA
├── QA Loop: max 3 cycles, then blocked
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
- `blueprint` (from Architect Phase 4)
- `workflow` (from Builder)
- `qa_report` (from QA)
- `edit_scope` (nodes to modify)
- `worklog`, `agent_log` (history)

## Stage Transitions

```
clarification → research → decision → build → validate → test → complete
                                                    ↓
                                                 blocked (after 3 QA fails)
```

## QA Loop (max 3 cycles)

```
QA fail → Builder fix (edit_scope) → QA → repeat
After 3 fails → stage="blocked" → report to user
```

## Test Mode

### `--test` (Quick health check)
Tests each agent can be invoked:
- Orchestrator: can read run_state
- Researcher: can search nodes
- Builder: can validate (no create)
- QA: can validate (no trigger)
- Architect: can search templates
- Analyst: can read logs

### `--test full` (Integration test)
Creates a test workflow end-to-end:
1. Creates simple Webhook → Set → Respond workflow
2. Validates with QA
3. Triggers test webhook
4. Cleans up (deactivates)

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
/orch --test full
```

## Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| L1 | Simple error | Builder direct fix |
| L2 | Unknown error | Researcher → Builder |
| L3 | 3+ failures | stage="blocked" |
| L4 | Blocked | Report to user + Analyst post-mortem |

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
