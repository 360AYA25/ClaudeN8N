# ClaudeN8N Project Instructions

## Project Overview

Knowledge base and toolkit for n8n workflow automation with Claude Code.

## Before Working with n8n

**ALWAYS check knowledge base first:**

1. **Quick lookup** (98% token savings):
   ```
   Read: docs/learning/LEARNINGS-INDEX.md
   ```

2. **Find solution by keyword**:
   ```
   Grep: "keyword" in docs/learning/LEARNINGS.md
   ```

3. **Find pattern**:
   ```
   Grep: "Pattern" in docs/learning/PATTERNS.md
   ```

## Knowledge Base Files

| File | Use For |
|------|---------|
| `docs/learning/LEARNINGS-INDEX.md` | Fast lookup (read FIRST) |
| `docs/learning/LEARNINGS.md` | Detailed solutions (1700+ lines) |
| `docs/learning/PATTERNS.md` | Proven workflow patterns (1600+ lines) |
| `docs/learning/N8N-RESOURCES.md` | External links & search tips |

## MCP Tools

When n8n-mcp server is connected, use these tools:
- `mcp__n8n-mcp__*` - workflow CRUD, node config, execution

## Workflow Creation Checklist

Before creating/modifying n8n workflows:

1. Check PATTERNS.md for "Pattern 0: Smart Workflow Creation"
2. Search LEARNINGS.md for similar problems
3. Use n8n-mcp tools (not manual JSON editing)
4. Validate with n8n-mcp validation tools

## Token Economy

- Use LEARNINGS-INDEX.md for lookups (not full file)
- Index + targeted read = ~1,000 tokens
- Full file read = ~50,000 tokens
- **Savings: 98%**

## Adding New Knowledge

When solving new n8n problems:

1. Add entry to `docs/learning/LEARNINGS.md`
2. Update `docs/learning/LEARNINGS-INDEX.md` with keywords
3. If reusable pattern found → add to `docs/learning/PATTERNS.md`
