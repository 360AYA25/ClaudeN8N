# Agent System Export

Files for configuring 6-agent Pure Claude Code system for n8n workflows.

## Structure

```
export-to-new-project/
├── .claude/
│   ├── agents/           # 5 agent templates
│   │   ├── architect.md
│   │   ├── orchestrator.md
│   │   ├── workflow-builder.md
│   │   ├── workflow-tester.md
│   │   └── workflow-validator.md
│   └── commands/
│       └── orch.md       # /orch command
├── docs/
│   └── PLAN-UNIFIED-AGENT-SYSTEM.md  # MAIN REFERENCE (read first!)
├── memory/
│   └── run_state.json    # State file template
└── README.md
```

## How to Use

1. Copy entire folder to new project
2. Read `docs/PLAN-UNIFIED-AGENT-SYSTEM.md` - contains:
   - 6 agents with HARD RULES
   - Permission Matrix
   - MCP tools per agent
   - State file schema
   - Context passing flow

3. Configure `.mcp.json` with n8n-mcp server (not included - contains credentials)

## Key Concepts

- **State File:** `memory/run_state.json` - all agents read/write
- **HARD RULES:** Each agent has explicit permissions (what they CAN and CANNOT do)
- **Permission Matrix:** Only Builder mutates workflows, only Orchestrator delegates
- **Annotated Workflow:** Nodes have `_meta` for tracking status/errors/fixes

## Missing (create manually)

- `.mcp.json` - MCP server config with n8n-mcp credentials
- `CLAUDE.md` - Project-specific instructions
