# ClaudeN8N

Claude Code knowledge base and toolkit for n8n workflow automation.

## Overview

This project contains:
- Knowledge base of n8n problems & solutions (LEARNINGS.md)
- Proven workflow patterns (PATTERNS.md)
- n8n resources and references (N8N-RESOURCES.md)
- Workflow templates (JSON)

## Project Structure

```
ClaudeN8N/
├── README.md                    # This file
├── CREDENTIALS.env              # Local credentials (git-ignored)
├── .env.example                 # Environment template
├── .mcp.json                    # MCP server configuration
│
├── docs/
│   ├── INDEX.md                 # Documentation index
│   ├── ARCHITECTURE.md          # System architecture
│   ├── WORKFLOWS.md             # Workflow examples
│   │
│   └── learning/                # Knowledge base
│       ├── LEARNINGS.md         # Problems & solutions (1700+ lines)
│       ├── LEARNINGS-INDEX.md   # Index for fast lookup
│       ├── PATTERNS.md          # Proven patterns (1600+ lines)
│       └── N8N-RESOURCES.md     # External resources
│
└── templates/                   # Workflow JSON templates
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

## Usage with Claude Code

Claude Code can use this knowledge base to:
1. Find solutions for n8n errors (grep LEARNINGS.md)
2. Apply proven patterns (read PATTERNS.md)
3. Build workflows using best practices

## License

MIT
