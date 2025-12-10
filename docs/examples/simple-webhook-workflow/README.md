# Example: Simple Webhook Workflow

**Demonstration of Distributed Architecture (Option C v3.6.0)**

This example shows how a project using the new distributed architecture is organized.

---

## 📁 Project Structure

```
simple-webhook-workflow/
├── .n8n/                           # Workflow state (isolated)
│   ├── run_state.json              # Current session state
│   ├── canonical.json              # Workflow snapshot
│   ├── agent_results/              # Per-agent outputs
│   │   ├── research_findings.json
│   │   ├── build_guidance.json
│   │   ├── build_result.json
│   │   └── qa_report.json
│   ├── snapshots/                  # Version backups
│   └── history/                    # Session history
│
├── .context/                       # Auto-generated context
│   ├── SYSTEM-CONTEXT.md           # Main context file (~1.8K tokens)
│   ├── sources.json                # Data source config
│   ├── context-version.json        # Version tracking
│   └── changes-log.json            # Update history
│
├── ARCHITECTURE.md                 # Project architecture
├── README.md                       # This file
└── .gitignore                      # Git ignore rules

```

---

## 🚀 How It Works

### 1. Project Initialization

When you start working on this project:

```bash
# Orchestrator detects project_path from:
1. run_state.json → .project_path field
2. User input → "workflow_id=abc123"
3. Default → /Users/sergey/Projects/ClaudeN8N
```

### 2. Agent Reading Order

All agents read files in this priority:

```
1. SYSTEM-CONTEXT.md       # 1,800 tokens (auto-generated)
2. SESSION_CONTEXT.md      # If PM-managed project
3. ARCHITECTURE.md         # Legacy fallback
4. LEARNINGS-INDEX.md      # Global knowledge base
```

**Token savings: 90%** (1.8K vs 10K)

### 3. Context Auto-Update

When workflow changes, Analyst ROLE 2 automatically:

```bash
# Triggered by:
- Session complete (stage: "complete")
- Manual: /orch refresh context
- Staleness: context_version < workflow_version

# Process:
1. Read .context/sources.json
2. Extract data from ARCHITECTURE.md, canonical.json, TODO.md
3. Generate new SYSTEM-CONTEXT.md from template
4. Increment context version
5. Log changes to changes-log.json
6. Commit to git (if repo)
```

---

## 📊 Benefits vs Legacy Architecture

| Aspect | Legacy (memory/) | Distributed (.n8n/) | Improvement |
|--------|------------------|---------------------|-------------|
| **Portability** | 2 folders required | Single folder | ✅ Self-contained |
| **Token usage** | 10K per agent | 1.8K per agent | ✅ 82% savings |
| **Context freshness** | Manual updates | Auto-refresh | ✅ Always current |
| **Project isolation** | Mixed in memory/ | Isolated | ✅ No contamination |
| **Git tracking** | State separate | State with code | ✅ Better history |
| **Backup** | Copy 2 folders | Copy 1 folder | ✅ Simpler |

---

## 🔄 Example Session Flow

### Starting a New Session

```bash
# 1. Orchestrator reads run_state
project_path=$(jq -r '.project_path' .n8n/run_state.json)
workflow_id=$(jq -r '.workflow_id' .n8n/run_state.json)

# 2. Check context freshness
workflow_version=$(jq -r '.versionId' .n8n/canonical.json)
context_version=$(grep "Context Version:" .context/SYSTEM-CONTEXT.md | awk '{print $3}')

if [ "$context_version" -lt "$workflow_version" ]; then
  echo "⚠️ Context outdated - refreshing..."
  /orch refresh context
fi

# 3. Export for agents
export PROJECT_PATH="$project_path"
export WORKFLOW_ID="$workflow_id"

# 4. Agents read SYSTEM-CONTEXT.md first
# (90% token savings!)
```

### During Development

```bash
# Builder creates/modifies workflow
→ Writes to .n8n/agent_results/build_result.json

# QA validates
→ Writes to .n8n/agent_results/qa_report.json

# Orchestrator updates run_state
→ Updates .n8n/run_state.json (stage, cycle_count, etc.)
```

### Session Complete

```bash
# Orchestrator detects stage: "complete"
→ Triggers Analyst ROLE 2

# Analyst refreshes context
1. Read sources.json
2. Extract latest data
3. Generate new SYSTEM-CONTEXT.md
4. Increment version
5. Git commit

# Next session gets fresh context automatically!
```

---

## 📝 File Examples

See files in this directory:
- `.n8n/run_state.json` - Session state example
- `.context/SYSTEM-CONTEXT.md` - Generated context example
- `.context/sources.json` - Config example

---

## 🎯 Usage with /orch

```bash
# Start working on this project
/orch fix broken webhook in simple-webhook-workflow

# System automatically:
1. Detects project_path from run_state
2. Loads SYSTEM-CONTEXT.md (1.8K tokens instead of 10K)
3. Agents work with isolated .n8n/ folder
4. Results saved to .n8n/agent_results/
5. On complete → auto-refresh context

# Manual context refresh (if needed)
/orch refresh context
```

---

## 🔗 Related Documentation

- **Migration Plan:** `/MIGRATION-PLAN.md`
- **Templates:** `/.claude/templates/project-structure/.context/`
- **Analyst ROLE 2:** `/.claude/agents/analyst.md` (lines 83-250)
- **Orchestrator Step 0.75:** `/.claude/commands/orch.md`

---

**This is the new standard for all n8n workflow projects!**
