# Documentation Index

## 5-Agent System

| Document | Description |
|----------|-------------|
| [.claude/CLAUDE.md](../.claude/CLAUDE.md) | System overview & architecture |
| [.claude/commands/orch.md](../.claude/commands/orch.md) | Orchestrator command (~1,037 lines, optimized v3.7.0) |
| [Agent: architect](../.claude/agents/architect.md) | Planning & user dialog (sonnet) |
| [Agent: researcher](../.claude/agents/researcher.md) | Search & discovery (sonnet) |
| [Agent: builder](../.claude/agents/builder.md) | Workflow creation (opus 4.5) |
| [Agent: qa](../.claude/agents/qa.md) | Validation & testing (sonnet) |
| [Agent: analyst](../.claude/agents/analyst.md) | Post-mortem & audit (sonnet) |

## Shared Libraries

| Library | Description |
|---------|-------------|
| [gate-enforcement.sh](../.claude/agents/shared/gate-enforcement.sh) | 7 validation gates (GATE 0-6) |
| [frustration-detector.sh](../.claude/agents/shared/frustration-detector.sh) | User frustration detection & auto-rollback |
| [snapshot-manager.sh](../.claude/agents/shared/snapshot-manager.sh) | Workflow snapshot & rollback management |
| [run-state-lib.sh](../.claude/agents/shared/run-state-lib.sh) | Token-efficient jq operations for run_state |

## Architecture & Workflows

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, data flow, safety guards |
| [WORKFLOWS.md](WORKFLOWS.md) | Common patterns & /orch usage examples |
| [EXECUTION-DEBUGGING-GUIDE.md](EXECUTION-DEBUGGING-GUIDE.md) | 🔍 Полный гайд по анализу n8n executions (4 режима, примеры, troubleshooting) |
| [schemas/run-state.schema.json](../schemas/run-state.schema.json) | State contract between agents |

## Learning Resources

| Document | Description |
|----------|-------------|
| [LEARNINGS.md](learning/LEARNINGS.md) | Knowledge base - problems & solutions (3720+ lines, 60 learnings) |
| [LEARNINGS-INDEX.md](learning/LEARNINGS-INDEX.md) | Index for fast pattern lookup (99% token savings) |
| [PATTERNS.md](learning/PATTERNS.md) | Proven solution patterns (15+ patterns) |
| [N8N-RESOURCES.md](learning/N8N-RESOURCES.md) | n8n resources & external links |
| [POST-MORTEM-CYCLE5-BLIND-SPOT.md](learning/POST-MORTEM-CYCLE5-BLIND-SPOT.md) | 🔴 Why agents missed deprecated syntax (9 cycles analysis) |

## Optimization & Best Practices

| Document | Description |
|----------|-------------|
| [PROMPT-OPTIMIZATION-GUIDE.md](PROMPT-OPTIMIZATION-GUIDE.md) | 🤖 AI Prompt optimization best practices (symlink to ~/.claude/shared/) |
| [AI-PROMPT-BEST-PRACTICES-2025.md](AI-PROMPT-BEST-PRACTICES-2025.md) | General AI prompt engineering best practices 2025 |

**Use `/dev --optimize-prompts`** to analyze and optimize AI prompts in any project!

## Backup & Rollback

| Location | Description |
|----------|-------------|
| [.backup/](../.backup/) | Backup folder for major changes |
| [2025-12-13_orch-optimization/](../.backup/2025-12-13_orch-optimization/) | orch.md original + rollback instructions |

## Quick Start

1. **Create workflow**: `/orch Create a webhook that...`
2. **Test system**: `/orch --test` or `/orch --test e2e`
3. **Fix workflow**: `/orch workflow_id=abc Fix the error...`
4. **Optimize prompts**: `/dev --optimize-prompts`

## Quick Links

- [README](../README.md) - Project overview
- [CHANGELOG](../CHANGELOG.md) - Version history
