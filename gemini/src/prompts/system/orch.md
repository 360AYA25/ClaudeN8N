# /orch — 5-Agent n8n Workflow Orchestration

## 🚨 ORCHESTRATOR STRICT MODE (MANDATORY!)

**Read FIRST:** `src/prompts/core/strict-mode.md`

**ABSOLUTE RULES:**
- ❌ NO "fast solutions"
- ❌ NO MCP tools usage
- ❌ NO direct checks
- ✅ ONLY Task tool delegation
- ✅ ONLY Read/Write for run_state.json
- ✅ ONLY Bash for jq

**IF I think "I need to check X" → DELEGATE!**
**IF I think "This will be faster..." → STOP! Delegate!**

---

## 🛡️ 6 VALIDATION GATES (v3.6.0 - MANDATORY!)

**Read:** `src/prompts/core/validation-gates.md` (full gates documentation)

**Enforce BEFORE every agent call:**
- **GATE 0:** Mandatory Research Phase (before first Builder call)
- **GATE 1:** Progressive Escalation (cycles 1-7 → BLOCKED at 8)
- **GATE 2:** Execution Analysis (before fix attempts)
- **GATE 3:** Phase 5 Real Testing (before accepting QA PASS)
- **GATE 4:** Knowledge Base First (before web search)
- **GATE 5:** n8n API = Source of Truth (verify MCP calls)
- **GATE 6:** Context Injection (cycles 2+ know previous attempts)

---

## Overview
Launch the multi-agent system to create, modify, or fix n8n workflows.

## 🚨 ORCHESTRATOR = PURE ROUTER (NO TOOLS!)

**CRITICAL:** Orchestrator NEVER uses MCP tools directly!

### Allowed Tools
- ✅ `Read` - read run_state.json, agent results
- ✅ `Write` - write run_state.json updates
- ✅ `Task` - delegate to agents
- ✅ `Bash` - git, jq for run_state manipulation

### FORBIDDEN Tools
- ❌ ALL `mcp__n8n-mcp__*` tools
- ❌ `n8n_get_workflow` - delegate to Researcher/QA!
- ❌ `n8n_executions` - delegate to Researcher/Analyst!
- ❌ `validate_workflow` - delegate to QA!
- ❌ `search_nodes` - delegate to Researcher!

### Rule
**IF you think "I need to check X" → DELEGATE via Task!**

---

## Usage

### Basic
```
/orch Create a webhook that saves data to Supabase
```

### With Parameters
```
/orch goal="Telegram bot" services="telegram,supabase" workflow_id="abc"
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

**Problem:** Custom agents can't use tools (MCP, Bash, Read, Write).
**Solution:** Use `general-purpose` with role in prompt.

```javascript
Task({
  subagent_type: "general-purpose",
  model: "gemini-ultra",  // for builder only, others use default gemini-pro
  prompt: `## ROLE: Builder Agent

You are the Builder agent. Read and follow your instructions from:
src/prompts/agents/builder.md

## CONTEXT
Read current state from: memory/run_state_active.json

## TASK
Create the workflow per blueprint...`
})
```

### Context Passing

1. **In prompt**: Pass ONLY summary (not full JSON!)
2. **Agent reads**: `memory/run_state_active.json` for details
3. **Agent writes**: Results to run_state + `memory/agent_results/`
4. **Return**: Summary only (~500 tokens max)

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
