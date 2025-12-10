# Project Initialization Guide

> **Simple guide for starting new n8n workflow projects**
>
> **Architecture:** Distributed (Option C v3.6.3)
> **Time:** 2-5 minutes

---

## 🚀 Quick Start (Automatic)

**Easiest way - let /orch do everything:**

```bash
/orch create Telegram bot that sends daily reports
```

System automatically:
1. Creates project structure (`.n8n/` and `.context/`)
2. Generates workflow
3. Creates SYSTEM-CONTEXT.md
4. Ready to use!

---

## 📁 Manual Initialization (3 Steps)

**If you need custom project folder:**

### Step 1: Create Project Structure

```bash
# Example: Telegram notification bot
mkdir -p ~/Projects/telegram-notifier
cd ~/Projects/telegram-notifier

# Create folders
mkdir -p .n8n/agent_results
mkdir -p .context
```

### Step 2: Create Initial run_state.json

```bash
cat > .n8n/run_state.json <<EOF
{
  "id": "run_telegram_notifier_$(date +%Y%m%d)",
  "stage": "clarification",
  "cycle_count": 0,
  "user_request": "Create Telegram bot for daily notifications",
  "workflow_id": null,
  "project_id": "telegram-notifier",
  "project_path": "$(pwd)",
  "agent_log": [],
  "worklog": [],
  "usage": {
    "tokens_used": 0,
    "agent_calls": 0,
    "qa_cycles": 0,
    "cost_usd": 0
  },
  "validation_gates_version": "3.6.0"
}
EOF
```

**Key fields:**
- `user_request` - What you want to build
- `project_path` - Full path to project folder
- `project_id` - Short name (alphanumeric + dashes)

### Step 3: Run Orchestrator

```bash
/orch create daily notification bot for Telegram
```

Orchestrator will:
- Read run_state.json from current folder
- Detect project_path automatically
- Create workflow in n8n
- Save results to `.n8n/agent_results/`
- Generate `.context/SYSTEM-CONTEXT.md`

---

## 📋 Project Structure (After Initialization)

```
telegram-notifier/
├── .n8n/                           # Workflow state (isolated)
│   ├── run_state.json              # Current session
│   ├── canonical.json              # Workflow snapshot
│   ├── agent_results/              # Per-agent outputs
│   │   ├── research_findings.json
│   │   ├── build_result.json
│   │   └── qa_report.json
│   ├── snapshots/                  # Version backups
│   └── history/                    # Session history
│
├── .context/                       # Auto-generated context
│   ├── SYSTEM-CONTEXT.md           # Main context (~1.8K tokens)
│   ├── sources.json                # Config
│   └── context-version.json        # Versioning
│
├── README.md                       # Project documentation
└── .gitignore                      # Git ignore rules
```

---

## 🔧 Configuration Options

### Custom Sources (Optional)

Create `.context/sources.json` to customize what goes into SYSTEM-CONTEXT.md:

```json
{
  "project_name": "Telegram Notifier",
  "project_type": "n8n-workflow",
  "context_sources": {
    "workflow": {
      "enabled": true,
      "path": "${project_path}/.n8n/canonical.json"
    },
    "architecture": {
      "enabled": true,
      "path": "${project_path}/ARCHITECTURE.md"
    },
    "tasks": {
      "enabled": true,
      "path": "${project_path}/TODO.md"
    },
    "learnings": {
      "enabled": true,
      "limit": 10
    }
  }
}
```

**Defaults work for 95% of cases - only customize if needed!**

---

## ✅ Verification Checklist

After initialization, verify:

```bash
# Check structure
ls -la .n8n/
ls -la .context/

# Verify run_state
cat .n8n/run_state.json | jq '.project_path, .workflow_id'

# Check context (should exist after first /orch run)
wc -l .context/SYSTEM-CONTEXT.md
# Should be ~100-150 lines (~1,800 tokens)

# Verify workflow in n8n
/orch status
```

---

## 🎯 Example Projects

**See working examples:**
- [Simple Webhook](../examples/simple-webhook-workflow/) - Basic webhook → Supabase
- [FoodTracker](~/Projects/MultiBOT/bots/food-tracker/) - Complex Telegram bot with AI

---

## 🔄 Workflow Updates

**System auto-updates context when workflow changes:**

```bash
# After modifying workflow
/orch refresh context

# Or automatic (on session complete)
# Analyst ROLE 2 triggers auto-refresh
```

**Context freshness check:**
```bash
# Orchestrator checks on each /orch run:
workflow_version=$(n8n API)
context_version=$(SYSTEM-CONTEXT.md)

if context_version < workflow_version:
  → Shows warning
  → Recommends: /orch refresh context
```

---

## 📚 Related Docs

- **Architecture:** [Distributed Architecture](../examples/simple-webhook-workflow/README.md)
- **Migration:** [MIGRATION-PLAN.md](../migrations/MIGRATION-PLAN.md)
- **Templates:** [.claude/templates/project-structure/.context/](../.claude/templates/project-structure/.context/)
- **Analyst ROLE 2:** [.claude/agents/analyst.md](../.claude/agents/analyst.md) (lines 83-250)

---

## 🚨 Common Issues

### "project_path not found"
**Solution:** Check run_state.json has correct path:
```bash
jq -r '.project_path' .n8n/run_state.json
```

### "Context outdated"
**Solution:** Refresh context:
```bash
/orch refresh context
```

### "No .n8n/ folder"
**Solution:** Create structure (see Step 1) or use automatic initialization

---

**Questions?** Ask in project documentation or check examples!
