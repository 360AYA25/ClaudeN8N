# 6-Agent n8n Orchestration System

> Pure Claude system for n8n workflow automation

## System Overview

| Agent | Model | Role | MCP Tools |
|-------|-------|------|-----------|
| orchestrator | sonnet | Route + coordinate loops | list_workflows, get_workflow |
| architect | opus | Complex planning, L3 escalation | search_*, get_*, WebSearch |
| researcher | sonnet | Fast node/template search | search_nodes, search_templates, get_node |
| **builder** | **opus** | **ONLY writer**: create/update/autofix | create_workflow, update_*, autofix_*, validate_* |
| qa | haiku | Validate + test, NO fixes | validate_*, trigger_webhook, get_execution |
| analyst | opus | Read-only audit, writes learnings | get_workflow, executions (READ-ONLY) |

## Routing Rules

### Complexity Detection
```
SIMPLE (3-10 tool calls):
- Single service integration
- Known patterns in LEARNINGS.md
- Clear requirements
→ Flow: Researcher → Builder → QA

COMPLEX (10+ tool calls):
- Multi-service (3+)
- Unknown patterns, needs research
- L3 escalation (3+ failed attempts)
→ Flow: Architect → Researcher → Builder → QA
```

### Decision Table
| Trigger | Route To | Reason |
|---------|----------|--------|
| Create workflow | researcher → builder | Standard flow |
| Fix error (known) | builder direct | L1 quick fix |
| Fix error (unknown) | researcher → builder | L2 research needed |
| 3+ fix failures | architect | L3 re-plan |
| Architecture question | architect | Deep planning |
| "Why did this fail?" | analyst | Post-mortem |

## 4-Level Escalation

| Level | Trigger | Action |
|-------|---------|--------|
| **L1** | Simple error, known pattern | Builder direct fix |
| **L2** | Unknown error | Researcher → Builder |
| **L3** | 3+ failed attempts | Architect re-plan |
| **L4** | Blocked, needs decision | Report to user |

## QA Loop (max 3 cycles)

```
Builder creates → QA validates
  ├─ PASS → Done
  └─ FAIL → Builder fix (edit_scope) → QA re-validates
              └─ 3 failures → L3 Architect
```

## Hard Rules (Permission Matrix)

| Action | Orch | Arch | Res | Build | QA | Analyst |
|--------|:----:|:----:|:---:|:-----:|:--:|:-------:|
| Create/Update workflow | - | - | - | **YES** | - | - |
| Autofix | - | - | - | **YES** | - | - |
| Delete workflow | - | - | - | **YES** | - | - |
| Validate (final) | - | - | - | pre | **YES** | - |
| Activate/Test | - | - | - | - | **YES** | - |
| Search nodes/templates | - | YES | YES | - | - | - |
| WebSearch | - | YES | - | - | - | - |
| Task (delegate) | **YES** | - | - | - | - | - |
| Write LEARNINGS.md | - | - | - | - | - | **YES** |

**Key:** Only Builder mutates. Only Orchestrator delegates. Only Analyst writes learnings.

## run_state Protocol

### Location
`memory/run_state.json` - All agents read/write (analyst: read-only + learnings)

### Stage Flow
`planning → research → build → validate → test → complete | blocked`

### Merge Rules (Orchestrator applies)
| Type | Rule | Examples |
|------|------|----------|
| Objects | Shallow merge (agent overwrites) | blueprint, workflow, qa_report |
| Arrays (append) | Always append, never replace | errors, fixes_tried, memory.* |
| Arrays (replace) | Replace entirely | edit_scope, workflow.nodes |
| Stage | Only moves forward | planning → research (never back) |

## Task Call Examples

### Simple Flow
```
Task(agent=researcher, prompt="Find nodes for Supabase insert")
→ returns research_findings
Task(agent=builder, prompt="Create workflow using research_findings")
→ returns workflow
Task(agent=qa, prompt="Validate and test workflow")
→ returns qa_report
```

### Fix Loop
```
Task(agent=builder, prompt="Fix issues. edit_scope=[node_123]. qa_report={...}")
→ returns updated workflow
Task(agent=qa, prompt="Re-validate workflow")
→ returns qa_report (cycle 2/3)
```

### L3 Escalation
```
Task(agent=architect, prompt="Re-plan after 3 failures. errors=[...], fixes_tried=[...]")
→ returns new blueprint
Task(agent=researcher, prompt="Search alternative solutions per blueprint")
→ continues normal flow
```

## Safety Rules

1. **Wipe Protection**: If removing >50% nodes → STOP, escalate to user
2. **edit_scope**: Builder only touches nodes in QA's edit_scope
3. **Snapshot**: Builder saves snapshot before destructive changes
4. **Regression Check**: QA marks regressions, Builder can rollback

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

## Skills (Auto-loaded per agent)

| Skill | Agents | Content |
|-------|--------|---------|
| `n8n/patterns` | architect, researcher, builder, analyst | Critical patterns, common errors |
| `n8n/node-configs` | architect, builder | Node configuration examples |
| `n8n/validation` | qa | Validation rules, error classification |
| `n8n/audit` | analyst | Log analysis, root cause templates |
