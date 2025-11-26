# 6-Agent n8n Orchestration System

> Pure Claude system for n8n workflow automation

## System Overview

| Agent | Model | Role | MCP Tools | Skills |
|-------|-------|------|-----------|--------|
| orchestrator | sonnet | Route + coordinate loops | list_workflows, get_workflow | — |
| architect | opus | 4-phase dialog + planning | **NONE** (Read only) | workflow-patterns, mcp-tools-expert |
| researcher | sonnet | Search with scoring | search_*, get_*, list_workflows | mcp-tools-expert, node-configuration |
| **builder** | **opus** | **ONLY writer** | create_*, update_*, autofix_*, validate_* | node-config, expression, code-js, code-py |
| qa | haiku | Validate + test, NO fixes | validate_*, trigger_*, executions | validation-expert, mcp-tools-expert |
| analyst | opus | Read-only audit | get_workflow, executions, versions | workflow-patterns, validation-expert |

---

## 4-PHASE UNIFIED FLOW (No Complexity Detection!)

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
├── Key principle: Modify existing > Build new
└── Output: decision + blueprint

PHASE 4: BUILD
├── Architect → Orchestrator → Builder → QA
├── QA Loop: max 3 cycles, then blocked
└── Output: completed workflow
```

### Stage Transitions
```
clarification → research → decision → build → validate → test → complete
                                                    ↓
                                                 blocked (after 3 QA fails)
```

## Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| **L1** | Simple error | Builder direct fix |
| **L2** | Unknown error | Researcher → Builder |
| **L3** | 3+ failures | stage="blocked" |
| **L4** | Blocked | Report to user + Analyst post-mortem |

## QA Loop (max 3 cycles)

```
QA fail → Builder fix (edit_scope) → QA → repeat
After 3 fails → stage="blocked" → report to user
```

## Hard Rules (Permission Matrix)

| Action | Orch | Arch | Res | Build | QA | Analyst |
|--------|:----:|:----:|:---:|:-----:|:--:|:-------:|
| Create/Update workflow | - | - | - | **YES** | - | - |
| Autofix | - | - | - | **YES** | - | - |
| Delete workflow | - | - | - | **YES** | - | - |
| Validate (final) | - | - | - | pre | **YES** | - |
| Activate/Test | - | - | - | - | **YES** | - |
| Search nodes/templates | - | - | **YES** | - | - | - |
| List/Get workflows | YES | - | **YES** | YES | YES | YES |
| Task (delegate) | **YES** | - | - | - | - | - |
| Write LEARNINGS.md | - | - | - | - | - | **YES** |

**Key:** Only Builder mutates. Only Orchestrator delegates. Architect has NO MCP tools.

## run_state Protocol

### Location
`memory/run_state.json` - All agents read/write (analyst: read-only + learnings)

### Stage Flow
`clarification → research → decision → build → validate → test → complete | blocked`

### Merge Rules (Orchestrator applies)
| Type | Rule | Examples |
|------|------|----------|
| Objects | Shallow merge (agent overwrites) | requirements, research_request, decision, blueprint, workflow, qa_report |
| Arrays (append) | Always append, never replace | errors, fixes_tried, memory.* |
| Arrays (replace) | Replace entirely | edit_scope, workflow.nodes |
| Stage | Only moves forward | clarification → research (never back) |

## Task Call Examples

### 4-Phase Flow
```
# Phase 1: Clarification
Task(agent=architect, prompt="Clarify requirements with user")
→ returns requirements

# Phase 2: Research
Task(agent=researcher, prompt="Search for solutions per research_request")
→ returns research_findings (fit_score, popularity, existing_workflows)

# Phase 3: Decision
Task(agent=architect, prompt="Present options to user, get decision")
→ returns decision + blueprint

# Phase 4: Build
Task(agent=builder, prompt="Build workflow per blueprint")
→ returns workflow
Task(agent=qa, prompt="Validate and test workflow")
→ returns qa_report
```

### QA Fix Loop
```
Task(agent=builder, prompt="Fix issues. edit_scope=[node_123]. qa_report={...}")
→ returns updated workflow
Task(agent=qa, prompt="Re-validate workflow")
→ returns qa_report (cycle 2/3)
```

### L4 Post-mortem
```
# After stage="blocked"
Task(agent=analyst, prompt="Analyze why this failed")
→ returns root_cause, proposed_learnings
```

## Safety Rules

1. **Wipe Protection**: If removing >50% nodes → STOP, escalate to user
2. **edit_scope**: Builder only touches nodes in QA's edit_scope
3. **Snapshot**: Builder saves snapshot before destructive changes
4. **Regression Check**: QA marks regressions, Builder can rollback

## Context Optimization

### File-Based Results (saves ~45K tokens)
| Agent | Full Result | run_state Summary |
|-------|-------------|-------------------|
| Builder | `memory/agent_results/workflow_{id}.json` | id, name, node_count, graph_hash |
| QA | `memory/agent_results/qa_report_{id}.json` | status, error_count, edit_scope |

### Index-First Reading (saves ~20K tokens)
Researcher MUST:
1. Read `LEARNINGS-INDEX.md` first (~500 tokens)
2. Find relevant IDs (L-042, P-015)
3. Read ONLY those sections from full files
4. **NEVER** read full LEARNINGS.md directly

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
