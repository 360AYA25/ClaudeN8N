# Architecture

## Overview

ClaudeN8N is a **5-Agent orchestration system** for n8n workflow automation with Claude Code.

## 5-Agent System

| Agent | Model | Role | MCP Tools |
|-------|-------|------|-----------|
| **architect** | sonnet | Planning + Dialog | WebSearch (NO MCP!) |
| **researcher** | sonnet | Search + Discovery | search_*, get_*, list |
| **builder** | opus 4.5 | ONLY writer | create/update/autofix |
| **qa** | sonnet | Validate + Test | validate, trigger, exec |
| **analyst** | sonnet | Read-only audit | get, list, versions |

**Orchestrator** = main context ([orch.md](../.claude/commands/orch.md)), NOT a separate agent file.

### 5-Phase Flow

```
PHASE 1: CLARIFICATION    → Architect ←→ User
PHASE 2: RESEARCH         → Researcher (search)
PHASE 3: DECISION + CREDS → Architect ←→ User + Researcher (discover)
PHASE 4: IMPLEMENTATION   → Researcher (deep dive)
PHASE 5: BUILD            → Builder → QA (max 7 cycles, progressive)
```

### Stage Flow

```
clarification → research → decision → credentials →
implementation → build → validate → test → complete | blocked
```

### Permission Matrix

| Action | Arch | Res | Build | QA | Analyst |
|--------|:----:|:---:|:-----:|:--:|:-------:|
| Create/Update workflow | - | - | **YES** | - | - |
| Search nodes/templates | - | **YES** | - | - | - |
| Activate/Test | - | - | - | **YES** | - |
| Write LEARNINGS.md | - | - | - | - | **YES** |

**Key:** Only Builder mutates. Orchestrator (main context) delegates via Task.

---

## System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    ClaudeN8N Project                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                       │
│  │   Claude Code   │◄── .claude/CLAUDE.md (instructions)   │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────────────────┐                           │
│  │    5-Agent System           │                           │
│  │  ┌──────────────────────┐   │                           │
│  │  │ architect (sonnet)   │   │                           │
│  │  │ researcher (sonnet)  │   │                           │
│  │  │ builder (opus 4.5)   │   │                           │
│  │  │ qa (sonnet)          │   │                           │
│  │  │ analyst (sonnet)     │   │                           │
│  │  └──────────────────────┘   │                           │
│  └─────────────────────────────┘                           │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────────────────┐                           │
│  │   Knowledge Base (docs/)    │                           │
│  │  - LEARNINGS.md (solutions) │                           │
│  │  - PATTERNS.md (patterns)   │                           │
│  │  - N8N-RESOURCES.md (links) │                           │
│  └─────────────────────────────┘                           │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │    n8n-mcp      │ ◄── MCP Server                        │
│  └────────┬────────┘                                       │
│           │                                                 │
└───────────│─────────────────────────────────────────────────┘
            │
            ▼
   ┌─────────────────┐
   │  n8n Instance   │ ◄── External (localhost:5678)
   └─────────────────┘
```

## Knowledge Base Structure

```
docs/learning/
├── LEARNINGS.md          # 1700+ lines, 39+ entries
│   ├── Agent Standardization
│   ├── n8n Workflows
│   ├── Notion Integration
│   ├── Supabase Database
│   ├── Telegram Bot
│   ├── Git & GitHub
│   ├── Error Handling
│   ├── AI Agents
│   ├── HTTP Requests
│   └── MCP Server
│
├── LEARNINGS-INDEX.md    # Fast lookup (98% token savings)
│   ├── By Node Type
│   ├── By Error Type
│   ├── By Category
│   └── Keyword Map
│
├── PATTERNS.md           # 1600+ lines, 15+ patterns
│   ├── Pattern 0: Smart Workflow Creation
│   ├── Pattern 0.5: Node Modification
│   ├── Pattern 1-14: Various n8n patterns
│   ├── Pattern 15: Cascading Changes
│   └── Anti-Patterns
│
└── N8N-RESOURCES.md      # External resources
    ├── Official (docs, templates, blog)
    ├── Community (forum, Discord, GitHub)
    └── Search cheat sheets
```

## MCP Integration

The project uses n8n-mcp server for:
- Workflow CRUD operations (create, read, update, delete)
- Node configuration and validation
- Workflow execution management
- Credential handling (secure)

### Configuration

`.mcp.json`:
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["-y", "@anthropic/n8n-mcp"],
      "env": {
        "N8N_API_URL": "${N8N_API_URL}",
        "N8N_API_KEY": "${N8N_API_KEY}"
      }
    }
  }
}
```

## Data Flow

### Building Workflows (via /orch)

```
1. User: /orch Create webhook → Claude Code
2. Orchestrator → Architect (clarify requirements)
3. Orchestrator → Researcher (search solutions)
4. Orchestrator → Architect (present options to user)
5. Orchestrator → Researcher (discover credentials)
6. Orchestrator → Architect (user selects credentials)
7. Orchestrator → Researcher (deep dive: learnings + patterns)
8. Orchestrator → Builder (create workflow via n8n-mcp)
9. Orchestrator → QA (validate + test)
10. Success → User | Fail (3x) → Analyst post-mortem
```

### Debugging Workflows

```
1. Error occurs → Claude Code
2. Researcher → Read LEARNINGS-INDEX.md
3. Researcher → Read relevant sections from LEARNINGS.md
4. Solution found → Builder applies fix via n8n-mcp
5. QA validates fix
6. OR: Search N8N-RESOURCES.md for external help
```

## File Purposes

| File | Purpose | Updated |
|------|---------|---------|
| .claude/CLAUDE.md | System overview & agent specs | On architecture changes |
| .claude/commands/orch.md | Orchestrator command | On flow changes |
| .claude/agents/*.md | Agent specifications | On agent logic changes |
| schemas/run-state.schema.json | State contract | On state structure changes |
| LEARNINGS.md | Document problems & solutions | On each issue |
| LEARNINGS-INDEX.md | Fast pattern lookup | With LEARNINGS.md |
| PATTERNS.md | Proven reusable solutions | When new pattern found |
| N8N-RESOURCES.md | External resource links | Rarely |

## Context Optimization

### File-Based Results (~45K tokens saved)

| Agent | Full Result | run_state Summary |
|-------|-------------|-------------------|
| Builder | `memory/agent_results/workflow_{id}.json` | id, name, node_count, graph_hash |
| QA | `memory/agent_results/qa_report_{id}.json` | status, error_count, edit_scope |

### Index-First Reading (~20K tokens saved)

Researcher protocol:
1. Read `LEARNINGS-INDEX.md` first (~500 tokens)
2. Find relevant IDs (L-042, P-015)
3. Read ONLY those sections from full files
4. **NEVER** read full LEARNINGS.md directly

**Total savings: ~65K tokens per workflow**

## Safety Guards

### Core Guards
1. **Wipe Protection**: If removing >50% nodes → STOP, escalate to user
2. **edit_scope**: Builder only touches nodes in QA's edit_scope
3. **Snapshot**: Builder saves snapshot before destructive changes
4. **Regression Check**: QA marks regressions, Builder can rollback
5. **QA Loop Limit**: Max 7 cycles → blocked (progressive: 1-3 Builder, 4-5 +Researcher, 6-7 +Analyst)

### Extended Guards (NEW)
6. **Blue-Green Workflows**: Clone-test-swap pattern for safe modifications
7. **Canary Testing**: Graduated testing (synthetic → 1 item → 10% → full)
8. **Circuit Breaker**: Per-agent failure tracking (3 failures → OPEN state)
9. **Checkpoint QA**: Validation after each modification step
10. **User Approval Gates**: System waits for explicit "да" after each checkpoint
11. **Hard Caps**: Token/cost/time limits per task (50K tokens, $0.50, 10min)

## Token Economy

### Using LEARNINGS-INDEX.md for lookups:
- Full file read: ~50,000 tokens
- Index + targeted read: ~1,000 tokens
- **Savings: 98%**

### Model Selection (Cost Optimization)
- **Builder on Opus 4.5**: Critical generation ($3/1M input, $15/1M output)
- **All others on Sonnet**: Dialog/search/validation ($3/1M input, $15/1M output)
- **Cost reduced 66%** vs all-Opus system
