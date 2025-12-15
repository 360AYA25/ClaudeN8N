# 5-Agent n8n Orchestration System

> Pure Claude system for n8n workflow automation
>
> **Option C v3.6.0** ✅ Active (deployed 2025-12-05)
> - 97% token savings via agent-scoped indexes
> - Workflow isolation for clean organization
> - validation-gates enforcement for quality

---

## 🚨 TOKEN ECONOMY RULES (CRITICAL!)

**DO:**
- Short answers, minimal code
- English only (code/docs)
- Tools over text (Read/Write/Edit)
- Reference files, don't duplicate

**DON'T:**
- Long explanations
- Verbose configs
- Russian in code/docs
- Repeat content

**Limits:**
- Agent prompts: Max 400 lines
- Code blocks: Max 15 lines → else reference file
- Examples: Max 3 lines

**Priority:** Safety > User control > Knowledge > Token economy

---

## 🚨 DEFAULT MODE: /orch (ALWAYS!)

**ВСЕ задачи в этом проекте выполняются через Orchestrator!**

```
User request → /orch → 5-Agent System → Result
```

### 🔒 ENFORCEMENT: PreToolUse Hook Active

**Hook:** `.claude/hooks/enforce-orch.md`

**What it does:**
- **BLOCKS** all direct `mcp__n8n-mcp__*` tool calls
- **ALLOWS** only when context shows "## ROLE: [Agent]" (subagent from /orch)
- **Forces** you to use `/orch` - you physically CANNOT bypass it!

**Block message:**
```
🚨 BLOCKED: Direct n8n MCP access not allowed!
Rule: ALL n8n workflow tasks MUST use /orch
Correct: /orch <your task>
```

### При получении ЛЮБОГО запроса:
1. **Автоматически запускай** `/orch` (SlashCommand) - enforcement via hook!
2. Orchestrator сам определит какого агента вызвать
3. Hook БЛОКИРУЕТ прямые MCP вызовы к n8n - обход невозможен

### Исключения (когда НЕ использовать /orch):
- Вопросы о системе ("как работает система?", "покажи агентов")
- Редактирование документации проекта (CLAUDE.md, agents/*.md, hooks/*.md)
- Git операции (commit, push)
- Работа с файлами проекта (Read, Write, Edit - не n8n MCP!)

### Примеры:
| User говорит | Действие |
|--------------|----------|
| "создай workflow" | → `/orch создай workflow` |
| "исправь FoodTracker" | → `/orch исправь FoodTracker` |
| "найди node для Telegram" | → `/orch найди node для Telegram` |
| "что сломалось?" | → `/orch что сломалось?` |
| "как работает builder?" | Ответь напрямую (документация) |
| *Попытка вызвать n8n_get_workflow* | **🚨 BLOCKED by hook!** |

---

## System Overview

| Agent | Model | Role | MCP Tools | Skills |
|-------|-------|------|-----------|--------|
| architect | sonnet | 5-phase dialog + planning | **WebSearch** (NO MCP!) | workflow-patterns, mcp-tools-expert |
| researcher | sonnet | Search with scoring | search_*, get_*, list_workflows | mcp-tools-expert, node-configuration |
| **builder** | **opus 4.5** | **ONLY writer** | create_*, update_*, autofix_*, validate_* | node-config, expression, code-js, code-py |
| qa | sonnet | Validate + test, NO fixes | validate_*, trigger_*, executions | validation-expert, mcp-tools-expert |
| analyst | sonnet | Read-only audit + token tracking | get_workflow, executions, versions | workflow-patterns, validation-expert |

**Orchestrator:** Main context (orch.md) — routes between agents, NOT a separate agent file.

---

## 5-PHASE UNIFIED FLOW (No Complexity Detection!)

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
├── Key principle: Modify existing > Build new
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

### Stage Transitions
```
clarification → research → decision → credentials → implementation → build → validate → test → complete
                                                                                  ↓
                                                                               blocked (after 7 QA cycles with progressive escalation)
```

## Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| **L1** | Simple error | Builder direct fix |
| **L2** | Unknown error | Researcher → Builder |
| **L3** | 7+ failures | stage="blocked" |
| **L4** | Blocked | Report to user + Analyst post-mortem |

## QA Loop (max 7 cycles — progressive)

```
QA fail → Builder fix (edit_scope) → QA → repeat
├── Cycle 1-3: Builder fixes directly
├── Cycle 4-5: Researcher helps find alternative approach
├── Cycle 6-7: Analyst diagnoses root cause
└── After 7 fails → stage="blocked" → report to user with full history
```

## Hard Rules (Permission Matrix)

| Action | Orch | Arch | Res | Build | QA | Analyst | Method |
|--------|:----:|:----:|:---:|:-----:|:--:|:-------:|--------|
| Create/Update workflow | **NO** | - | - | **YES** | - | - | **MCP** ✅ (Zod bug fixed v2.27.0+) |
| Autofix | **NO** | - | - | **YES** | - | - | **MCP** ✅ |
| Delete workflow | **NO** | - | - | **YES** | - | - | MCP ✅ |
| Validate (final) | **NO** | - | - | pre | **YES** | - | MCP ✅ |
| Activate/Test | **NO** | - | - | - | **YES** | - | **MCP** ✅ |
| Search nodes/templates | **NO** | - | **YES** | - | - | - | MCP ✅ |
| Discover credentials | **NO** | - | **YES** | - | - | - | MCP ✅ |
| Present credentials to user | **NO** | **YES** | - | - | - | - | - |
| List/Get workflows | **NO** | - | **YES** | YES | YES | YES | MCP ✅ |
| Write LEARNINGS.md | **NO** | - | - | - | - | **YES** | File |
| Delegate via Task | **YES** | - | - | - | - | - | Task tool |

**Key:**
- **Orchestrator = PURE ROUTER**: NO MCP tools, ONLY Task delegation!
- Only Builder mutates workflows via MCP
- Architect has NO MCP tools (uses Researcher for data)
- IF Orchestrator thinks "I need to check X" → DELEGATE!

## L-074: Source of Truth (CRITICAL!)

**n8n API = Source of Truth. Files = Caches only!**

| Data | Source of Truth | NOT Source of Truth |
|------|-----------------|---------------------|
| Workflow exists? | `n8n_get_workflow` MCP call | `agent_results/*.json` files |
| Node count | n8n API response `.nodes.length` | `run_state.workflow.node_count` |
| Version | n8n API `versionCounter` | `canonical.json` (cache!) |
| Success? | MCP call returned valid response | File with `success: true` |
| Workflow active? | n8n API `.active` field | `run_state.workflow.active` |

**Anti-Fake Rules:**
- L-071: Builder MUST log `mcp_calls` array
- L-072: QA MUST verify via MCP before validating
- L-073: Orchestrator MUST check `mcp_calls` exists

**Files are CACHES that can be stale/fake. Only MCP calls prove reality!**

## run_state Protocol (Option C v3.6.0)

### Location
- **Active:** `memory/run_state_active.json` - Compacted state (last 10 agent_log entries)
- **History:** `memory/run_state_history/{workflow_id}/` - Full trace by stage
- **Archives:** `memory/run_state_archives/` - Completed workflows

### Stage Flow
`clarification → research → decision → credentials → implementation → build → validate → test → complete | blocked`

### Merge Rules (Orchestrator applies)
| Type | Rule | Examples |
|------|------|----------|
| Objects | Shallow merge (agent overwrites) | requirements, research_request, decision, blueprint, workflow, qa_report |
| Arrays (append) | Always append, never replace | errors, fixes_tried, memory.* |
| Arrays (replace) | Replace entirely | edit_scope, workflow.nodes |
| Stage | Only moves forward | clarification → research (never back) |

---

## Option C Architecture (v3.6.0)

**Deployed:** 2025-12-05
**Status:** ✅ Active
**Token Savings:** 97% per workflow

### Directory Structure

```
memory/
├── run_state_active.json           # Current workflow (compacted, ~800 tokens)
├── run_state_history/{id}/         # Per-workflow history
│   ├── 001_clarification.json
│   ├── 002_research.json
│   ├── 003_decision.json
│   └── complete.json
├── run_state_archives/             # Completed workflows
│   └── {workflow_id}_complete.json
├── agent_results/{workflow_id}/    # Workflow-isolated agent outputs
│   ├── research_findings.json
│   ├── build_guidance.json
│   ├── build_result.json
│   ├── qa_report.json
│   └── qa_history/
│       ├── cycle_1.json
│       └── cycle_2.json
└── workflow_snapshots/{id}/        # Version backups
    ├── canonical.json
    └── v{N}.json

docs/learning/indexes/              # Agent-scoped indexes (NEW!)
├── architect_patterns.md           # Top 15 patterns (~800 tokens)
├── researcher_nodes.md             # Top 20 nodes (~1,200 tokens)
├── builder_gotchas.md              # Critical gotchas (~1,000 tokens)
├── qa_validation.md                # Validation checklist (~700 tokens)
└── analyst_learnings.md            # Post-mortem framework (~900 tokens)

.claude/agents/shared/
└── optimal-reading-patterns.md     # Index-First protocol documentation
```

### Key Features

**1. Workflow Isolation**
- Each workflow gets own directory: `agent_results/{workflow_id}/`
- No cross-contamination between workflows
- Easy cleanup after completion

**2. Compacted Active State**
- `run_state_active.json`: Last 10 agent_log entries only
- Full history preserved in `run_state_history/{id}/`
- Automatic archiving on completion

**3. Agent-Scoped Indexes**
- 5 specialized indexes for 5 agents
- 95-97% token savings per index
- Index-First Reading Protocol enforced

**4. Token Optimization**
| Component | Before | After | Savings |
|-----------|--------|-------|---------|
| run_state | 2,845 | 800 | 72% |
| Agent reads | 225K | 7.1K | 97% |
| **Total per workflow** | **269K** | **116K** | **57%** |

**5. Cumulative Savings (10 Workflows)**
- Before: 2,690,000 tokens (~$27 at $0.01/1K)
- After: 1,160,000 tokens (~$12)
- **Savings: $15 per 10 workflows**

### Index-First Reading Protocol

**All agents MUST:**
1. Read their agent-scoped index FIRST
2. Use LEARNINGS-INDEX.md instead of full LEARNINGS.md
3. Follow pointers to specific sections
4. Only read full files if not found in index

**Example:**
```
Researcher task: "Find Telegram node"
1. Read researcher_nodes.md (1,200 tokens) ← Index
2. Find: "Telegram (n8n-nodes-base.telegram)"
3. MCP: get_node() for details
DONE (saved 48,800 tokens!)
```

**Documentation:** `.claude/agents/shared/optimal-reading-patterns.md`

## Task Call Examples

### CRITICAL: Correct Syntax for Custom Agents

```javascript
// ✅ CORRECT (workaround for Issue #7296 - custom agents can't use tools):
Task({
  subagent_type: "general-purpose",
  model: "opus",  // for builder only
  prompt: `## ROLE: Builder Agent
Read: .claude/agents/builder.md

## TASK
Clarify requirements with user`
})

// ❌ WRONG - custom agents can't use tools!
Task({
  agent: "builder",  // This agent won't have MCP/Bash access!
  prompt: "..."
})
```

### 5-Phase Flow (using workaround)
```javascript
// Phase 1: Clarification
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Architect\nRead: .claude/agents/architect.md\n\n## TASK: Clarify requirements" })
→ returns requirements

// Phase 2: Research
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Researcher\nRead: .claude/agents/researcher.md\n\n## TASK: Search for solutions" })
→ returns research_findings

// Phase 3: Decision
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Architect\n...\n\n## TASK: Present options" })
→ returns decision + blueprint

// Phase 4: Implementation
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Researcher\n...\n\n## TASK: Deep dive" })
→ returns build_guidance

// Phase 5: Build
Task({ subagent_type: "general-purpose", model: "opus", prompt: "## ROLE: Builder\n...\n\n## TASK: Build workflow" })
→ returns workflow
Task({ subagent_type: "general-purpose", prompt: "## ROLE: QA\n...\n\n## TASK: Validate" })
→ returns qa_report
```

### QA Fix Loop
```javascript
Task({ subagent_type: "general-purpose", model: "opus", prompt: "## ROLE: Builder\n...\n\n## TASK: Fix issues per edit_scope" })
→ returns updated workflow
Task({ subagent_type: "general-purpose", prompt: "## ROLE: QA\n...\n\n## TASK: Re-validate" })
→ returns qa_report (cycle 2/3)
```

### L4 Post-mortem
```javascript
// After stage="blocked"
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Analyst\nRead: .claude/agents/analyst.md\n\n## TASK: Analyze failure" })
→ returns root_cause, proposed_learnings, token_usage
```

### Context Isolation
Each agent runs in **isolated context** with its own model:
- Orchestrator calls `Task({ subagent_type: "general-purpose", model: "opus" })` → NEW process
- Agent reads its role from .claude/agents/*.md file
- Agent gets clean context (~50-75K tokens) + TOOLS WORK!
- Agent reads `memory/run_state_active.json` for details (compacted!)
- Agent writes results to `memory/agent_results/{workflow_id}/`
- Agent returns ONLY summary to Orchestrator

## Safety Rules

1. **Wipe Protection**: If removing >50% nodes → STOP, escalate to user
2. **edit_scope**: Builder only touches nodes in QA's edit_scope
3. **Snapshot**: Builder saves snapshot before destructive changes
4. **Regression Check**: QA marks regressions, Builder can rollback

## Context Optimization (Option C v3.6.0)

### 1. Workflow Isolation (saves ~45K tokens)
| Agent | Full Result | run_state Summary |
|-------|-------------|-------------------|
| Builder | `memory/agent_results/{workflow_id}/build_result.json` | id, name, node_count, graph_hash |
| QA | `memory/agent_results/{workflow_id}/qa_report.json` | status, error_count, edit_scope |
| Researcher | `memory/agent_results/{workflow_id}/research_findings.json` | hypothesis_validated, fit_score |

**Benefit:** Each workflow isolated → no cross-contamination, easy cleanup

### 2. Compacted Active State (saves ~2K tokens)
- `run_state_active.json`: Last 10 agent_log entries (~800 tokens)
- Full history: `run_state_history/{id}/` (72% reduction vs full state)

### 3. Agent-Scoped Indexes (saves ~218K tokens per workflow)
| Agent | Index File | Size | Full File | Savings |
|-------|------------|------|-----------|---------|
| Architect | architect_patterns.md | 800 | PATTERNS.md (25K) | 97% |
| Researcher | researcher_nodes.md | 1,200 | - | - |
| Researcher | LEARNINGS-INDEX.md | 2,500 | LEARNINGS.md (50K) | 95% |
| Builder | builder_gotchas.md | 1,000 | - | - |
| QA | qa_validation.md | 700 | - | - |
| Analyst | analyst_learnings.md | 900 | - | - |

**Total:** 7,100 tokens (indexes) vs 225,000 tokens (full files) = **97% savings**

### 4. Index-First Protocol (MANDATORY)
**All agents MUST:**
1. Read their agent-scoped index FIRST
2. Use LEARNINGS-INDEX.md instead of full LEARNINGS.md
3. Follow pointers to specific sections
4. **NEVER** read full files directly

**Enforcement:** See `.claude/agents/shared/optimal-reading-patterns.md`

### Total Savings Per Workflow
- Before Option C: **269,000 tokens**
- After Option C: **116,000 tokens**
- **Savings: 153,000 tokens (57%)**

## MCP Configuration

### Files
| File | Purpose |
|------|---------|
| `.mcp.json` | Active config (n8n-mcp only) |
| `.mcp.json.full` | Full config with all MCPs (for quick enable) |

### Available MCPs (in .mcp.json.full)
| MCP | Purpose | When to Enable |
|-----|---------|----------------|
| `n8n-mcp` | n8n workflow operations | **Always ON** |
| `notion` | Notion API | When working with Notion |
| `gemini-cli` | Gemini AI | When need alternative AI |
| `supabase` | Direct Supabase access | When need DB operations |

### Quick Switch
```bash
# Enable all MCPs
cp .mcp.json.full .mcp.json

# Restore minimal (n8n only)
# Edit .mcp.json, keep only n8n-mcp
```

**Note:** `.mcp.json*` files contain API keys - NEVER commit to git!

## Knowledge Base

Before n8n work, check:
1. `docs/learning/LEARNINGS-INDEX.md` - Quick pattern lookup
2. `docs/learning/LEARNINGS.md` - Detailed solutions
3. `docs/learning/PATTERNS.md` - Proven workflows

## Skills (Auto-loaded from czlonkowski/n8n-skills)

| Skill | Purpose |
|-------|---------|
| `n8n-mcp-tools-expert` | MCP tool selection, nodeType formats, validation profiles |
| `n8n-workflow-patterns` | 5 architectural patterns from 2,653+ templates |
| `n8n-validation-expert` | Error interpretation, false positive handling |
| `n8n-node-configuration` | Operation-aware setup, property dependencies |
| `n8n-expression-syntax` | {{}} syntax, $json/$node/$now variables |
| `n8n-code-javascript` | Data access patterns, 10 production patterns |
| `n8n-code-python` | Standard library, external lib workarounds |

### Skill Distribution by Agent

| Agent | Skills | When to Invoke |
|-------|--------|---------------|
| **Architect** | workflow-patterns, mcp-tools-expert | Discussing patterns, formulating research_request |
| **Researcher** | mcp-tools-expert, node-configuration | Before MCP calls, analyzing node configs |
| **Builder** | node-configuration, expression-syntax, code-javascript, code-python | Creating/modifying nodes, writing expressions/code |
| **QA** | validation-expert, mcp-tools-expert | Interpreting errors, choosing validation tools |
| **Analyst** | workflow-patterns, validation-expert | Analyzing patterns, classifying errors |
