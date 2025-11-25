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
/orch mode=complex goal="Multi-service integration" services="webhook,supabase,slack"
```

### Test Mode
```
/orch --test              # Test all agents
/orch --test agent:builder  # Test specific agent
/orch --test full         # Full system test with sample workflow
```

## Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `mode` | auto, simple, complex | auto | Force routing mode |
| `goal` | string | (from prompt) | Task description |
| `services` | comma-separated | (auto-detect) | Services to integrate |
| `workflow_id` | string | null | Existing workflow to modify |

## Routing Logic

### Auto Mode (default)
```
SIMPLE (3-10 tool calls):
- Single service
- Known patterns
- Clear requirements
→ Researcher → Builder → QA

COMPLEX (10+ tool calls):
- Multi-service (3+)
- Unknown patterns
- Architecture decisions
→ Architect → Researcher → Builder → QA
```

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
   Set: stage="planning", cycle_count=0
   ```

3. **Determine complexity**
   ```
   If services.length >= 3 → complex
   If unknown_patterns → complex
   Else → simple
   ```

4. **Start agent flow**
   ```
   Complex: Task(agent=architect, ...)
   Simple: Task(agent=researcher, ...)
   ```

## Context Passed to Agents

Each agent receives full `run_state`:
- `id`, `user_request`, `goal`
- `stage`, `cycle_count`
- `blueprint` (from Architect)
- `research_findings` (from Researcher)
- `workflow` (from Builder)
- `qa_report` (from QA)
- `edit_scope` (nodes to modify)
- `worklog`, `agent_log` (history)
- `memory.issues_history`, `memory.fixes_applied`

## QA Loop

```
cycle_count < 3:
  Builder creates/fixes → QA validates
  If passed → complete
  If failed → increment cycle_count, Builder fixes with edit_scope

cycle_count >= 3:
  Escalate to Architect (L3)
  If still blocked → report to user (L4)
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
| L3 | 3+ failures | Architect re-plan |
| L4 | Blocked | Report to user |

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
