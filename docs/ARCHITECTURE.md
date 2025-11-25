# Architecture

## Overview

ClaudeN8N is a knowledge base and toolkit for n8n workflow automation with Claude Code.

## System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      ClaudeN8N Project                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                       │
│  │   Claude Code   │◄── .claude/CLAUDE.md (instructions)   │
│  └────────┬────────┘                                       │
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
├── LEARNINGS.md          # 1700+ lines, 39 entries
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

### Building Workflows

```
1. User request → Claude Code
2. Claude Code ← .claude/CLAUDE.md (auto-loaded instructions)
3. Claude Code → Read PATTERNS.md (find best approach)
4. Claude Code → n8n-mcp (create workflow)
5. n8n-mcp → n8n API
6. Workflow created → User verification
```

### Debugging Workflows

```
1. Error occurs → Claude Code
2. Claude Code → Grep LEARNINGS.md (find solution)
3. Solution found → Apply fix via n8n-mcp
4. OR: Search N8N-RESOURCES.md for external help
```

## File Purposes

| File | Purpose | Updated |
|------|---------|---------|
| .claude/CLAUDE.md | Claude Code instructions (auto-loaded) | On workflow changes |
| LEARNINGS.md | Document problems & solutions | On each issue |
| LEARNINGS-INDEX.md | Fast pattern lookup | With LEARNINGS.md |
| PATTERNS.md | Proven reusable solutions | When new pattern found |
| N8N-RESOURCES.md | External resource links | Rarely |

## Token Economy

Using LEARNINGS-INDEX.md for lookups:
- Full file read: ~50,000 tokens
- Index + targeted read: ~1,000 tokens
- **Savings: 98%**
