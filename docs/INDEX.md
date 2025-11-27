# Documentation Index

## 5-Agent System

| Document | Description |
|----------|-------------|
| [.claude/CLAUDE.md](../.claude/CLAUDE.md) | System overview & architecture |
| [.claude/commands/orch.md](../.claude/commands/orch.md) | Orchestrator command & test modes |
| [Agent: architect](../.claude/agents/architect.md) | Planning & user dialog (sonnet) |
| [Agent: researcher](../.claude/agents/researcher.md) | Search & discovery (sonnet) |
| [Agent: builder](../.claude/agents/builder.md) | Workflow creation (opus 4.5) |
| [Agent: qa](../.claude/agents/qa.md) | Validation & testing (sonnet) |
| [Agent: analyst](../.claude/agents/analyst.md) | Post-mortem & audit (sonnet) |

## Architecture & Workflows

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, data flow, safety guards |
| [WORKFLOWS.md](WORKFLOWS.md) | Common patterns & /orch usage examples |
| [schemas/run-state.schema.json](../schemas/run-state.schema.json) | State contract between agents |

## Learning Resources

| Document | Description |
|----------|-------------|
| [LEARNINGS.md](learning/LEARNINGS.md) | Knowledge base - problems & solutions (1700+ lines) |
| [LEARNINGS-INDEX.md](learning/LEARNINGS-INDEX.md) | Index for fast pattern lookup (98% token savings) |
| [PATTERNS.md](learning/PATTERNS.md) | Proven solution patterns (15+ patterns) |
| [N8N-RESOURCES.md](learning/N8N-RESOURCES.md) | n8n resources & external links |

## Quick Start

1. **Create workflow**: `/orch Create a webhook that...`
2. **Test system**: `/orch --test` or `/orch --test e2e`
3. **Fix workflow**: `/orch workflow_id=abc Fix the error...`

## Quick Links

- [README](../README.md) - Project overview
- [CHANGELOG](../CHANGELOG.md) - Version history
