# ClaudeN8N

**5-Agent Orchestration System** for n8n workflow automation with Claude Code.

## Overview

ClaudeN8N is a complete multi-agent system that automates n8n workflow creation, debugging, and maintenance through a team of specialized AI agents working together.

**Current Version:** v3.7.0 (2025-12-15)

### What This System Does

- **Automates workflow building** through 5-phase collaborative process
- **Prevents critical incidents** via protected nodes, surgical edits, and validation gates
- **Preserves knowledge** in structured ADRs, service playbooks, and learning database
- **Optimizes token usage** through agent-scoped indexes and file-based context
- **Enforces safety** via hooks that prevent hallucinated operations and accidental deletions

### 5-Agent Team

| Agent | Model | Role | Responsibility |
|-------|-------|------|----------------|
| **Architect** | Sonnet 4.5 | Planning & Dialog | Clarifies requirements, presents options, coordinates phases |
| **Researcher** | Sonnet 4.5 | Search & Discovery | Finds nodes, templates, credentials, and documentation |
| **Builder** | Opus 4.5 | Implementation | Creates/modifies workflows via surgical edits only |
| **QA** | Sonnet 4.5 | Validation & Testing | Validates changes, runs tests, enforces edit scope |
| **Analyst** | Sonnet 4.5 | Analysis & Documentation | Post-mortems, updates .context/ files, tracks tokens |

**Orchestrator** = Main context that routes between agents (not a separate agent file)

## Project Structure

```
ClaudeN8N/
├── README.md                    # Project overview
├── CHANGELOG.md                 # Version history (v3.7.0)
├── CREDENTIALS.env              # Local credentials (git-ignored)
├── .mcp.json                    # MCP server configuration
│
├── .claude/                     # Claude Code configuration
│   ├── CLAUDE.md                # System instructions (auto-loaded)
│   │
│   ├── commands/                # Slash commands
│   │   └── orch.md              # Orchestrator (main entry point, ~5,765 tokens)
│   │
│   ├── agents/                  # Agent specifications (~23,610 tokens total)
│   │   ├── architect.md         # Planning agent (~1,700 tokens)
│   │   ├── researcher.md        # Search agent (~3,800 tokens)
│   │   ├── builder.md           # Implementation agent (~4,950 tokens)
│   │   ├── qa.md                # Validation agent (~4,225 tokens)
│   │   ├── analyst.md           # Analysis agent (~3,170 tokens)
│   │   └── shared/              # Shared protocols
│   │       ├── anti-hallucination.md      # MCP checks (486 tokens)
│   │       ├── project-context.md         # Reading order (463 tokens)
│   │       ├── surgical-edits.md          # Partial updates (672 tokens)
│   │       └── context-update.md          # Documentation sync (574 tokens)
│   │
│   └── hooks/                   # Enforcement hooks
│       ├── block-full-update.md           # PreToolUse: Force surgical edits
│       └── enforce-context-update.md      # PostToolUse: Trigger Analyst
│
├── docs/
│   ├── INDEX.md                 # Documentation index
│   ├── ARCHITECTURE.md          # System architecture (updated v3.7.0)
│   ├── WORKFLOWS.md             # Workflow examples
│   │
│   └── learning/                # Knowledge base
│       ├── LEARNINGS.md         # Problems & solutions (50+ entries)
│       ├── LEARNINGS-INDEX.md   # Fast lookup index (98% token savings)
│       ├── PATTERNS.md          # Proven patterns (15+ patterns)
│       └── N8N-RESOURCES.md     # External resources
│
├── memory/                      # Run state and agent results
│   ├── run_state_active.json    # Current workflow (compacted, ~800 tokens)
│   ├── run_state_history/       # Per-workflow history
│   ├── run_state_archives/      # Completed workflows
│   ├── agent_results/           # Agent outputs (workflow-isolated)
│   └── workflow_snapshots/      # Version backups
│
└── {project_path}/.context/     # Project-specific documentation (NEW v3.7.0)
    ├── 1-STRATEGY.md            # Mission, goals, boundaries
    ├── 2-INDEX.md               # Navigation hub, protected nodes
    ├── architecture/
    │   ├── flow.md              # Data flow diagrams
    │   ├── decisions/           # Architecture Decision Records (ADRs)
    │   ├── services/            # Service playbooks (Telegram, Supabase)
    │   └── nodes/               # Critical node intent cards
    └── technical/
        └── state.json           # Current workflow state
```

## Setup

1. Copy environment template:
   ```bash
   cp .env.example CREDENTIALS.env
   ```

2. Edit `CREDENTIALS.env` with your n8n API credentials

3. MCP server is pre-configured in `.mcp.json`

## Documentation

| Document | Description |
|----------|-------------|
| [docs/INDEX.md](docs/INDEX.md) | Full documentation index |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture |
| [docs/WORKFLOWS.md](docs/WORKFLOWS.md) | Workflow patterns |

### Learning Resources

| Document | Description |
|----------|-------------|
| [LEARNINGS.md](docs/learning/LEARNINGS.md) | Problems & solutions database |
| [LEARNINGS-INDEX.md](docs/learning/LEARNINGS-INDEX.md) | Fast lookup index |
| [PATTERNS.md](docs/learning/PATTERNS.md) | Proven solution patterns |
| [N8N-RESOURCES.md](docs/learning/N8N-RESOURCES.md) | External n8n resources |

## Quick Start

### Using the System

**All workflow tasks must use the `/orch` command** (enforced via hooks):

```bash
/orch Create a Telegram bot that tracks food intake
/orch Fix the webhook authentication issue
/orch Add rate limiting to the API workflow
```

The orchestrator automatically:
1. Clarifies requirements via Architect ←→ User dialog
2. Researches solutions via Researcher (nodes, templates, patterns)
3. Presents options via Architect ←→ User decision
4. Implements via Builder (surgical edits only)
5. Validates via QA (max 7 cycles with progressive escalation)
6. Documents via Analyst (.context/ updates, git commits)

### 5-Phase Workflow

```
User Request
    ↓
PHASE 1: CLARIFICATION     → Architect ←→ User
    ↓
PHASE 2: RESEARCH          → Researcher (search nodes, templates, credentials)
    ↓
PHASE 3: DECISION + CREDS  → Architect ←→ User + Researcher (discover credentials)
    ↓
PHASE 4: IMPLEMENTATION    → Researcher (deep dive: learnings, patterns, gotchas)
    ↓
PHASE 5: BUILD             → Builder → QA → (fix loop) → complete | blocked
```

### Key Features (v3.7.0)

**File-Based Context Protocol:**
- Each project has `.context/` directory with structured documentation
- Agents read context directly instead of embedded JSON in Task calls
- ~10,000 tokens saved per workflow build

**Protected Nodes & Surgical Edits:**
- Projects document DO NOT TOUCH rules in `2-INDEX.md`
- Builder uses `n8n_update_partial_workflow` only (full updates blocked via hooks)
- QA validates Builder only modified declared `edit_scope`

**Architecture Decision Records (ADRs):**
- Critical decisions documented with incident history
- Service playbooks for Telegram, Supabase, etc.
- Node intent cards explain critical component purposes

**Enforcement Hooks:**
- PreToolUse: Block `n8n_update_full_workflow` → force surgical edits
- PostToolUse: Trigger Analyst to update .context/ after Builder success

**Token Optimization:**
| Component | Tokens |
|-----------|--------|
| Full system (5 agents + orchestrator) | ~23,610 |
| Active run state (compacted) | ~800 |
| Project .context/ (example: FoodTracker) | ~5,653 |
| Savings per workflow (vs embedded context) | ~10,000 |
| **ROI after 10 workflows** | **141×** |

## License

MIT
