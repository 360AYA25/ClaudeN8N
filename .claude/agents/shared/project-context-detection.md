# Project Context Detection

> Shared protocol for detecting which project an agent is working on

---

## At Session Start

```bash
# Read project context from run_state
project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state.json)
project_id=$(jq -r '.project_id // "clauden8n"' memory/run_state.json)

# Load project-specific context (if external project)
if [ "$project_id" != "clauden8n" ]; then
  [ -f "$project_path/ARCHITECTURE.md" ] && Read "$project_path/ARCHITECTURE.md"
  [ -f "$project_path/SESSION_CONTEXT.md" ] && Read "$project_path/SESSION_CONTEXT.md"
  [ -f "$project_path/TODO.md" ] && Read "$project_path/TODO.md"
fi

# LEARNINGS always from ClaudeN8N (shared knowledge base)
Read /Users/sergey/Projects/ClaudeN8N/docs/learning/LEARNINGS-INDEX.md
```

---

## Priority Order

1. **Project-specific** `ARCHITECTURE.md` (detailed node flow, structure)
2. **Project-specific** `SESSION_CONTEXT.md` (current state, progress)
3. **build_guidance** from Researcher (gotchas, node configs)
4. **ClaudeN8N** `LEARNINGS.md` (shared knowledge base)

---

## Known Projects

| project_id | project_path | Description |
|------------|--------------|-------------|
| `clauden8n` | `/Users/sergey/Projects/ClaudeN8N` | Default - agent system |
| `food-tracker` | `/Users/sergey/Projects/MultiBOT/bots/food-tracker` | Telegram food tracking bot |
| `health-tracker` | `/Users/sergey/Projects/MultiBOT/bots/health-tracker` | Health tracking bot |

---

## Workflow Backups (Builder only)

```bash
# If external project has workflows/ directory
if [ "$project_id" != "clauden8n" ] && [ -d "$project_path/workflows" ]; then
  backup_path="$project_path/workflows/backup_$(date +%s).json"
  # Save snapshot before destructive changes
fi
```
