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
/orch --test e2e          # End-to-End production test (20+ nodes)
```

## Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `goal` | string | (from prompt) | Task description |
| `services` | comma-separated | (auto-detect) | Services to integrate |
| `workflow_id` | string | null | Existing workflow to modify |

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
- `blueprint` (from Architect Phase 3)
- `credentials_discovered` (from Researcher Phase 3 - scanned from existing workflows)
- `credentials_selected` (from Architect Phase 3 - user-chosen credentials)
- `build_guidance` (from Researcher Phase 4 - gotchas, node configs, warnings)
- `workflow` (from Builder)
- `qa_report` (from QA)
- `edit_scope` (nodes to modify)
- `worklog`, `agent_log` (history)

## Stage Transitions

```
clarification → research → decision → implementation → build → validate → test → complete
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

| Agent | Test | MCP Tools |
|-------|------|-----------|
| Orchestrator | read run_state | list/get workflows |
| Architect | read files + skills | **NO MCP!** |
| Researcher | search nodes/templates | full search |
| Builder | validate node config | mutations |
| QA | list workflows + executions | testing |
| Analyst | read executions | read-only |

**IMPORTANT:** Architect has NO MCP tools - only Read + Skills!

### `--test e2e` (End-to-End Production Test) 🆕
**Full system stress test with REAL 20+ node workflow**

Creates, activates, and tests complex production-grade workflow with:
- **20+ nodes** (triggers Logical Block Building)
- **Multiple services** (Telegram, Supabase, OpenAI, HTTP Request)
- **AI Agent node** with custom prompt
- **Complex logic** (IF, Switch, Merge nodes)
- **Real credentials** (auto-discovered from existing workflows)
- **Full execution** (activates + triggers + monitors)
- **Auto-fix loops** (if execution fails, Builder fixes)
- **Analyst review** (post-mortem analysis + learnings)

**Process:**
```
PHASE 1: DISCOVERY
├─ Orchestrator → Researcher: Discover available credentials
├─ Find: Telegram, Supabase, OpenAI, HTTP auth keys
└─ Output: credentials_map

PHASE 2: DESIGN & BUILD
├─ Architect: Design 20+ node workflow blueprint
│  ├─ Block 1: **Chat Trigger** (AI-optimized webhook + UI) (3 nodes)
│  ├─ Block 2: Data validation with IF/Switch (5 nodes)
│  ├─ Block 3: AI Agent processing (4 nodes)
│  ├─ Block 4: Supabase storage (4 nodes)
│  ├─ Block 5: HTTP Request to external API (2 nodes)
│  └─ Block 6: Telegram notification + Chat Response (3 nodes)
├─ Builder: Create workflow using Logical Block Building
├─ QA: Validate all nodes + connections
└─ Output: workflow_id + chat_url

PHASE 3: ACTIVATION & EXECUTION
├─ QA: Activate workflow
├─ QA: Trigger test execution (webhook or manual)
├─ Monitor: Check execution logs
└─ Output: execution_id, status

PHASE 4: VERIFICATION
├─ QA: Read execution details
├─ Check: All 20+ nodes executed successfully
├─ Check: AI Agent response valid
├─ Check: Supabase records created
├─ Check: Telegram message sent
└─ Output: verification_report

PHASE 5: FIX LOOP (if failures)
├─ IF execution failed:
│  ├─ Analyst: Identify root cause from logs
│  ├─ Researcher: Find solution in LEARNINGS.md
│  ├─ Builder: Fix nodes (max 3 cycles)
│  ├─ QA: Re-validate + re-execute
│  └─ Repeat until success or blocked
└─ Max 3 fix cycles

PHASE 6: ANALYSIS & LEARNINGS
├─ Analyst: Comprehensive post-mortem
│  ├─ Agent performance review
│  ├─ Token usage analysis
│  ├─ Time per phase
│  ├─ QA loop efficiency
│  ├─ Logical block building effectiveness
│  ├─ Identified issues
│  └─ Recommendations for improvement
├─ Analyst: Write to LEARNINGS.md (if new patterns)
└─ Output: analysis_report.md
```

**Test Workflow Specification:**

```json
{
  "name": "E2E Test: Multi-Service AI Workflow",
  "description": "20+ node production test covering all agent capabilities",
  "nodes_count": 21,
  "blocks": [
    {
      "name": "Trigger",
      "type": "foundation",
      "nodes": [
        "Chat Trigger (@n8n/n8n-nodes-langchain.chatTrigger)",
        "  mode: webhook (API access)",
        "  public: true (open chat UI)",
        "  responseMode: lastNode",
        "Set: Parse Chat Input",
        "IF: Validate Required Fields"
      ]
    },
    {
      "name": "AI Processing",
      "type": "intelligence",
      "nodes": [
        "AI Agent: Analyze Input",
        "  prompt: 'You are a data validator. Check if input contains valid user data. Return JSON with validation result.'",
        "  tools: [http_request]",
        "Code: Parse AI Response",
        "Switch: Route by AI Decision"
      ]
    },
    {
      "name": "Storage Operations",
      "type": "persistence",
      "nodes": [
        "Supabase: Insert User Record",
        "Supabase: Get User by ID",
        "Set: Format User Data",
        "IF: Check Insert Success"
      ]
    },
    {
      "name": "External API",
      "type": "integration",
      "nodes": [
        "HTTP Request: GET jsonplaceholder.typicode.com/users/1",
        "Set: Merge External Data"
      ]
    },
    {
      "name": "Notifications",
      "type": "output",
      "nodes": [
        "Telegram: Send Success Message",
        "Set: Format Response",
        "Respond to Webhook: Return Results"
      ]
    }
  ],
  "complexity_features": [
    "Multiple IF/Switch routing",
    "AI Agent with tools",
    "Database operations (insert + get)",
    "External API calls",
    "Error handling on all blocks",
    "Webhook response with data"
  ]
}
```

**Why Chat Trigger? 🎯**

| Feature | Webhook Trigger | **Chat Trigger** | Manual Trigger |
|---------|----------------|------------------|----------------|
| UI for testing | ❌ No | ✅ Built-in chat | ✅ Button |
| API access | ✅ Yes | ✅ Yes (webhook) | ❌ No |
| Session memory | ❌ No | ✅ Automatic | ❌ No |
| For AI agents | 🟡 Works | ✅ Optimized | 🟡 Works |
| Chat history | ❌ No | ✅ Visible in UI | ❌ No |
| Claude Code testing | ✅ API only | ✅ **Both ways!** | ❌ UI only |

**Chat Trigger = Best choice because:**
- ✅ You can open UI and test manually
- ✅ Claude Code can trigger via webhook API
- ✅ Session memory - conversation persists
- ✅ Perfect for AI workflows
- ✅ History visible - see all tests

**Testing methods:**
```javascript
// Method 1: Automated (Claude Code)
n8n_trigger_webhook_workflow({
  webhookUrl: "https://n8n.srv1068954.hstgr.cloud/webhook-test/{id}",
  httpMethod: "POST",
  data: {
    chatInput: "Test query from Claude Code",
    sessionId: "e2e-test-session"
  },
  waitForResponse: true
})

// Method 2: Manual (User)
// Open workflow → Click "Open Chat" on Chat Trigger node
// Type message → See response in real-time
```

**Success Criteria:**
✅ Workflow created with 20+ nodes
✅ All logical blocks built correctly
✅ All credentials applied
✅ Workflow activated
✅ Execution completed (all nodes green)
✅ AI Agent responded correctly
✅ Supabase records exist
✅ Telegram message delivered
✅ Chat Trigger returned 200 OK
✅ Chat UI accessible (manual testing)
✅ No QA errors
✅ Analyst report generated

**Cleanup:**
- Deactivate workflow after test
- Delete test Supabase records
- Keep workflow for reference (tag: "e2e-test")

**Usage:**
```bash
/orch --test e2e
```

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
| L3 | 3+ failures | stage="blocked" |
| L4 | Blocked | Report to user + Analyst post-mortem |

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
