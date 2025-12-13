# /orch — 5-Agent n8n Workflow Orchestration

## 🚨 ORCHESTRATOR STRICT MODE (MANDATORY!)

**Read FIRST:** `.claude/ORCHESTRATOR-STRICT-MODE.md`

**ABSOLUTE RULES:**
- ❌ NO "fast solutions"
- ❌ NO MCP tools usage
- ❌ NO direct checks
- ✅ ONLY Task tool delegation
- ✅ ONLY Read/Write for run_state.json
- ✅ ONLY Bash for jq

**IF I think "I need to check X" → DELEGATE!**
**IF I think "This will be faster..." → STOP! Delegate!**

---

## 🛡️ 6 VALIDATION GATES (v3.6.0 - MANDATORY!)

**Read:** `.claude/VALIDATION-GATES.md` (full gates documentation)
**Read:** `.claude/PROGRESSIVE-ESCALATION.md` (escalation matrix)

**Enforce BEFORE every agent call:**
- **GATE 0:** Mandatory Research Phase (before first Builder call)
- **GATE 1:** Progressive Escalation (cycles 1-7 → BLOCKED at 8)
- **GATE 2:** Execution Analysis (before fix attempts)
- **GATE 3:** Phase 5 Real Testing (before accepting QA PASS)
- **GATE 4:** Knowledge Base First (before web search)
- **GATE 5:** n8n API = Source of Truth (verify MCP calls)
- **GATE 6:** Context Injection (cycles 2+ know previous attempts)

**Evidence:** 5 hours (no gates) vs 30 minutes (with gates) — Task 2.4 post-mortem

---

## 📋 Доступные режимы

**Available Modes:**
- `/orch <task>` — 5-phase flow (create/modify)
- `/orch workflow_id=X <task>` — MODIFY existing workflow
- `/orch --fix workflow_id=X` — L1 Quick Fix (~500 tokens)
- `/orch --debug workflow_id=X` — L2 Targeted Debug (~2K tokens)
- `/orch --test [agent:name]` — Health check (quick|specific agent|e2e)
- `/orch snapshot <view|rollback|refresh> <id>` — Snapshot management

---

## Overview
Launch the multi-agent system to create, modify, or fix n8n workflows.

## 🚨 ORCHESTRATOR = PURE ROUTER (NO TOOLS!)

**CRITICAL:** Orchestrator NEVER uses MCP tools directly!

### Allowed Tools
- ✅ `Read` - read run_state.json, agent results
- ✅ `Write` - write run_state.json updates
- ✅ `Task` - delegate to agents
- ✅ `Bash` - git, jq for run_state manipulation

### FORBIDDEN Tools
- ❌ ALL `mcp__n8n-mcp__*` tools
- ❌ `n8n_get_workflow` - delegate to Researcher/QA!
- ❌ `n8n_executions` - delegate to Researcher/Analyst!
- ❌ `validate_workflow` - delegate to QA!
- ❌ `search_nodes` - delegate to Researcher!

### Rule
**IF you think "I need to check X" → DELEGATE via Task!**

Examples:
- ❌ WRONG: `const workflow = await n8n_get_workflow({id})`
- ✅ RIGHT: `Task({ subagent_type: "general-purpose", prompt: "## ROLE: Researcher\nRead: .claude/agents/researcher.md\n\n## TASK: Get workflow X" })`

- ❌ WRONG: `const result = await validate_workflow({workflow})`
- ✅ RIGHT: `Task({ subagent_type: "general-purpose", prompt: "## ROLE: QA\nRead: .claude/agents/qa.md\n\n## TASK: Validate workflow" })`

**Cognitive trap:** "I'll just quickly check..." → NO! Always delegate!

---

## Usage

### Basic
```
/orch Create a webhook that saves data to Supabase
```

### With Parameters
```
/orch goal="Telegram bot" services="telegram,supabase" workflow_id="abc"
```

### Test Mode
```
/orch --test              # Test all agents
/orch --test agent:builder  # Test specific agent
/orch --test e2e          # End-to-End production test (20+ nodes)
```

## Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `goal` | string | (from prompt) | Task description |
| `services` | comma-separated | (auto-detect) | Services to integrate |
| `workflow_id` | string | null | Existing workflow to modify |

---

## Execution Protocol

### Calling Agents (Workaround for Issue #7296)

**Problem:** Custom agents can't use tools (MCP, Bash, Read, Write).
**Solution:** Use `general-purpose` with role in prompt.

```javascript
// ✅ CORRECT (workaround for Issue #7296):
Task({
  subagent_type: "general-purpose",
  model: "opus",  // for builder only, others use default sonnet
  prompt: `## ROLE: Builder Agent

You are the Builder agent. Read and follow your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/builder.md

## CONTEXT
Read current state from: ${project_path}/.n8n/run_state.json

## TASK
Create the workflow per blueprint...`
})

// ❌ WRONG (custom agents can't use tools!):
Task({ agent: "builder", prompt: "..." })
```

### Agent Templates

**Agents:**
- architect, researcher, qa, analyst → sonnet | Read `.claude/agents/{agent}.md`
- builder → opus | Read `.claude/agents/builder.md`

**Delegation:**
- clarification/decision → architect (sonnet)
- research/credentials/implementation → researcher (sonnet)
- build → builder (opus 4.5)
- validate/test → qa (sonnet)
- analysis → analyst (sonnet)

### Context Passing

1. **In prompt**: Pass ONLY summary (not full JSON!)
2. **Agent reads**: `${project_path}/.n8n/run_state.json` for details
3. **Agent writes**: Results to run_state + `${project_path}/.n8n/agent_results/`
4. **Return**: Summary only (~500 tokens max)

### 🛑 6 VALIDATION GATES (v3.6.0 - MANDATORY!)

**Enforce BEFORE every agent call:**
- **GATE 0:** Mandatory Research (before first Builder call)
- **GATE 1:** Progressive Escalation (cycles 1-7 → BLOCKED at 8)
- **GATE 2:** Execution Analysis (before fix attempts)
- **GATE 3:** Phase 5 Real Testing (before QA PASS)
- **GATE 4:** Knowledge Base First (before web search)
- **GATE 5:** n8n API = Source of Truth (verify MCP calls)
- **GATE 6:** Context Injection (cycles 2+ know previous attempts)

**Enforcement:**
```bash
source .claude/agents/shared/gate-enforcement.sh
check_all_gates "$agent" "$run_state_path"
[[ $? -ne 0 ]] && exit 1
```

**Details:** `.claude/agents/validation-gates.md`
**Code:** `.claude/agents/shared/gate-enforcement.sh`
**Evidence:** 5 hours (no gates) vs 30 minutes (with gates) - Task 2.4

### Context Isolation

Each `Task({ subagent_type: "general-purpose", ... })` = **NEW PROCESS**:
- Clean context (~30-75K tokens)
- Model via `model: "opus"` param (or default sonnet)
- Tools inherited from built-in agent (works!)
- Agent reads role instructions from .md file
- Contexts do NOT overlap — exchange via files!

### Algorithm

1. Read `${project_path}/.n8n/run_state.json` or initialize new
2. Check stage, delegate to agent:
   - `clarification` → architect
   - `research` → researcher
   - `decision` → architect
   - `implementation` → researcher
   - `build` → builder
   - `validate/test` → qa
3. Receive updated run_state
4. Advance stage based on output

### Hard Rules

- **NEVER** mutate workflows (only list/get)
- **ALWAYS** advance stage forward (never rollback)
- **ALWAYS** fill `worklog` and `agent_log`

### Output Formats

- **worklog**: `{ ts, cycle, agent, action, outcome }`
- **agent_log**: `{ ts, agent, action, details }`

---

## run_state Update Protocol (Orchestrator ONLY!)

**Orchestrator is the ONLY one who updates stage and merges agent results.**

### After EACH agent completes:

**Source library:**
```bash
source .claude/agents/shared/run-state-lib.sh
```

**Merge result:**
```bash
merge_agent_result "$AGENT_RESULT"
```

**Update stage:**
```bash
update_stage "research"        # After Architect clarification
update_stage "decision"        # After Researcher search
update_stage "credentials"     # After Architect decision
update_stage "implementation"  # After Researcher credentials
update_stage "build"           # After Researcher implementation
update_stage "validate"        # After Builder
update_stage "complete"        # After QA success
update_stage "blocked"         # After 7 QA fails
```

**Update cycle:**
```bash
increment_cycle    # After QA fail, before retry
```

**Functions:** `.claude/agents/shared/run-state-lib.sh`

### Merge Rules (applied by Orchestrator):

| Type | Rule | Fields |
|------|------|--------|
| Objects | Agent overwrites | requirements, research_findings, decision, blueprint, workflow, qa_report |
| Arrays (append) | Never replace | errors, fixes_tried, agent_log, worklog |
| Arrays (replace) | Full replace | edit_scope, workflow.nodes |
| Stage | Only forward | clarification → research → ... → complete |

### CRITICAL: Orchestrator responsibilities

1. ✅ Read run_state at start
2. ✅ Delegate to agent via Task
3. ✅ Merge agent result (jq)
4. ✅ Advance stage (jq)
5. ✅ Increment cycle_count on QA fail
6. ❌ NEVER mutate workflows directly!

---

## ❌ L-073: ANTI-FAKE - Verify MCP Calls!

**Rule:** Builder MUST log `mcp_calls[]` array. Verified by GATE 5 in `check_all_gates()`.

**Blocks if:** mcp_calls missing/empty | workflow not found in n8n | node count mismatch

**Impl:** `.claude/agents/shared/gate-enforcement.sh` → `check_gate_5()`

---

## 5-PHASE FLOW (Unified)

**No complexity detection!** All requests follow the same flow:

```
PHASE 1: CLARIFICATION
├── User request → Architect
├── Architect ←→ User (диалог)
└── Output: requirements

PHASE 2: RESEARCH
├── Architect → Orchestrator → Researcher
├── Search: local → existing → templates → nodes
└── Output: research_findings (fit_score, popularity)

PHASE 3: DECISION + CREDENTIALS
├── Researcher → Orchestrator → Architect
├── Architect ←→ User (выбор варианта)
├── Orchestrator → Researcher (discover credentials)
├── Researcher → Orchestrator (credentials_discovered)
├── Orchestrator → Architect (present credentials)
├── Architect ←→ User (select credentials)
├── Modify existing > Build new
└── Output: decision + blueprint + credentials_selected

PHASE 4: IMPLEMENTATION
├── Architect → Orchestrator → Researcher (deep dive)
├── Study: learnings → patterns → node configs
└── Output: build_guidance (gotchas, configs, warnings)

PHASE 5: BUILD
├── Researcher → Orchestrator → Builder → QA
├── QA Loop: max 7 cycles (progressive), then blocked
└── Output: completed workflow
```

**Note:** MODIFY flows include IMPACT_ANALYSIS as sub-phase within clarification:
- Stage: `"clarification"` (unchanged in run_state)
- Sub-phase: impact analysis (if workflow_id provided)
- Then: stage transitions to `"research"`

---

## Project Selection

Detect if working on external project:

```bash
# Parse --project flag from user_request
if [[ "$user_request" =~ --project=([a-z-]+) ]]; then
  project_id="${BASH_REMATCH[1]}"

  # Set project_path based on ID
  case "$project_id" in
    "food-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/food-tracker"
      ;;
    "health-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/health-tracker"
      ;;
    "clauden8n"|"")
      project_path="/Users/sergey/Projects/ClaudeN8N"
      project_id="clauden8n"
      ;;
  esac
else
  # Check if run_state has project context from previous session
  if [ -f ${project_path}/.n8n/run_state.json ]; then
    project_id=$(jq -r '.project_id // "clauden8n"' ${project_path}/.n8n/run_state.json)
    project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' ${project_path}/.n8n/run_state.json)
  else
    # Default to ClaudeN8N
    project_id="clauden8n"
    project_path="/Users/sergey/Projects/ClaudeN8N"
  fi
fi
```

**Project context stored in run_state:**
```json
{
  "project_id": "$project_id",
  "project_path": "$project_path",
  ...
}
```

**Agents will read project_path from run_state** to access project-specific documentation (TODO.md, SESSION_CONTEXT.md, ARCHITECTURE.md).

---

## Special Commands: Rollback System

### COMMAND: /orch rollback

**Purpose:** Restore workflow from auto-snapshot (created by Builder before destructive changes)

**Syntax:**
```bash
/orch rollback                    # Rollback to last snapshot
/orch rollback <timestamp>        # Rollback to specific snapshot
/orch rollback list               # Show available snapshots
```

**Implementation:**

```bash
source .claude/agents/shared/snapshot-manager.sh

# Parse rollback command
if [[ "$user_request" =~ ^/orch\ rollback ]]; then

  # Handle rollback (list, find snapshot, prepare)
  handle_rollback_command "$user_request" "$project_path" "$workflow_id"
  result=$?

  if [ $result -eq 0 ]; then
    exit 0  # list command completed
  elif [ $result -eq 1 ]; then
    exit 1  # error
  fi

  # result=2: need user confirmation
  read -p "Confirm rollback? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "❌ Rollback cancelled"
    exit 0
  fi

  # Delegate to Builder for restore
  Task({
    subagent_type: "general-purpose",
    model: "opus",
    prompt: "## ROLE: Builder Agent\nRead: .claude/agents/builder.md\n\n## TASK: Restore workflow from snapshot\nSnapshot: $SNAPSHOT_FILE\nWorkflow: $WORKFLOW_ID\n\nSteps: Read snapshot → n8n_update_full_workflow → Verify → Report"
  })

  exit 0
fi
```

**Example:**
```bash
# Rollback to latest snapshot
/orch rollback

# Rollback to specific snapshot
/orch rollback 2025-12-10T14-30-00

# List all snapshots
/orch rollback list
```

---

## Session Start (with Validation!)

When `/orch` is invoked:

### Step 0: Load Gate Enforcement

**Implementation:**
```bash
source .claude/agents/shared/gate-enforcement.sh
source .claude/agents/shared/frustration-detector.sh
source .claude/agents/shared/run-state-lib.sh
```

**Functions:** Gate validation, frustration detection, run_state helpers
**Evidence:** Prevents FAILURE-ANALYSIS disasters (Priority 0)

### Step 0.5: Frustration Detection

**Flow:** init_session → update_last_request → check_frustration → handle_action

**Implementation:**
```bash
# Init if needed
init_run_state

# Update last request
update_field '.last_request' "$user_request"

# Check frustration level
frustration_action=$(check_frustration "$user_request" "$run_state_path")

# Handle action (STOP_AND_ROLLBACK|OFFER_ROLLBACK|CHECK_IN|CONTINUE)
handle_frustration_action "$frustration_action" "$run_state_path"
result=$?

# Exit if user frustrated (return code 1 = stop, 2 = wait for input)
if [ $result -eq 1 ]; then
  exit 0  # Stop processing
elif [ $result -eq 2 ]; then
  # Wait for user choice [R/C/S] before continuing
  :
fi
```

**Details:** `.claude/agents/shared/frustration-detector.sh`
**Evidence:** Prevented 6-hour disasters in Task 2.4

### Step 0.75: Project Path Detection

```bash
# 0.75.1 Detect project_path from run_state or user input
if [ -f ${project_path}/.n8n/run_state.json ]; then
  project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' ${project_path}/.n8n/run_state.json)
  workflow_id=$(jq -r '.workflow_id // null' ${project_path}/.n8n/run_state.json)
else
  project_path="/Users/sergey/Projects/ClaudeN8N"
  workflow_id=null
fi

# 0.75.2 If workflow_id provided in user_request, extract it
if [[ "$user_request" =~ workflow_id=([a-zA-Z0-9_-]+) ]]; then
  workflow_id="${BASH_REMATCH[1]}"
fi

# 0.75.3 Context Freshness Check (if SYSTEM-CONTEXT.md exists)
if [ -n "$workflow_id" ] && [ -f "${project_path}/.context/SYSTEM-CONTEXT.md" ]; then
  real_workflow=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="minimal")
  workflow_version=$(echo "$real_workflow" | jq -r '.versionId // .versionCounter')
  context_version=$(grep -m1 "Workflow Version:" "${project_path}/.context/SYSTEM-CONTEXT.md" | awk '{print $3}')

  if [ -n "$context_version" ] && [ "$workflow_version" != "$context_version" ]; then
    echo "⚠️ CONTEXT OUTDATED (workflow v$workflow_version, context v$context_version)"
    echo "Recommendation: /orch snapshot refresh $workflow_id"
  fi
fi

# 0.75.4 Export for subsequent steps
export PROJECT_PATH="$project_path"
export WORKFLOW_ID="$workflow_id"
```

### Step 1: Load and Validate run_state

```bash
# 1.1 Read existing run_state
if [ -f ${project_path}/.n8n/run_state.json ]; then
  old_stage=$(jq -r '.stage' ${project_path}/.n8n/run_state.json)
  old_request=$(jq -r '.user_request' ${project_path}/.n8n/run_state.json)
  old_workflow=$(jq -r '.workflow_id' ${project_path}/.n8n/run_state.json)

  # 1.2 Check if stale session (not completed, different request)
  if [ "$old_stage" != "complete" ] && [ "$old_stage" != "blocked" ]; then
    echo "⚠️ STALE SESSION DETECTED!"
    echo "   Previous: $old_request"
    echo "   Stage: $old_stage"
    echo ""
    echo "Options:"
    echo "  [C]ontinue - Resume previous task"
    echo "  [N]ew - Start fresh (archive old run_state)"
    echo "  [A]bort - Cancel and review manually"
    # WAIT FOR USER INPUT!
  fi
fi
```

### Step 2: Validate Canonical Snapshot (CRITICAL!)

```bash
# 2.1 If workflow_id exists, compare with n8n
if [ -n "$workflow_id" ]; then
  canonical_file="${project_path}/.n8n/canonical.json"

  if [ -f "$canonical_file" ]; then
    # Get version from canonical
    canonical_version=$(jq -r '.snapshot_metadata.n8n_version_counter' "$canonical_file")

    # Get REAL version from n8n API (L-067: use structure mode for large workflows)
    real_workflow=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="minimal")
    real_version=$(echo "$real_workflow" | jq -r '.versionId // .versionCounter')

    # 2.2 Compare versions
    if [ "$canonical_version" != "$real_version" ]; then
      echo "⚠️ CANONICAL SNAPSHOT OUTDATED!"
      echo "   Snapshot version: $canonical_version"
      echo "   n8n version: $real_version"
      echo ""
      echo "Options:"
      echo "  [R]efresh - Download fresh snapshot from n8n"
      echo "  [K]eep - Use old snapshot (RISKY!)"
      echo "  [A]bort - Cancel and review manually"
      # WAIT FOR USER INPUT!
    else
      echo "✅ Canonical snapshot is fresh (v$canonical_version)"
    fi
  fi
fi
```

### Step 3: Handle Stale Data

```bash
# 3.1 If user chose [N]ew - archive and create fresh
archive_stale_session() {
  timestamp=$(date +%Y%m%d_%H%M%S)
  mkdir -p ${project_path}/.n8n/archives

  # Archive run_state
  mv ${project_path}/.n8n/run_state.json "${project_path}/.n8n/archives/run_state_${timestamp}.json"

  # Create fresh run_state
  jq -n '{
    id: "run_'$(date +%Y%m%d_%H%M%S)'",
    stage: "clarification",
    cycle_count: 0,
    agent_log: [],
    worklog: [],
    usage: { tokens_used: 0, agent_calls: 0, qa_cycles: 0 }
  }' > ${project_path}/.n8n/run_state.json

  echo "📦 Archived stale session to ${project_path}/.n8n/archives/"
}

# 3.2 If user chose [R]efresh - update canonical
refresh_canonical_snapshot() {
  workflow_id="$1"
  snapshot_dir="${project_path}/.n8n/snapshots/${workflow_id}"

  # Archive old canonical to history
  if [ -f "${snapshot_dir}/canonical.json" ]; then
    old_version=$(jq -r '.snapshot_metadata.snapshot_version' "${snapshot_dir}/canonical.json")
    mkdir -p "${snapshot_dir}/history"
    mv "${snapshot_dir}/canonical.json" "${snapshot_dir}/history/v${old_version}_$(date +%Y%m%d).json"
  fi

  # Researcher creates new snapshot
  Task({ subagent_type: "general-purpose", prompt: "## ROLE: Researcher\nRead: .claude/agents/researcher.md\n\n## TASK: Create fresh canonical snapshot for workflow $workflow_id" })

  echo "🔄 Canonical snapshot refreshed"
}
```

### Step 4: Initialize New Session

```bash
# Only after validation passes!
jq --arg req "$USER_REQUEST" \
   --arg wf "$workflow_id" \
   --arg proj "$project_id" \
   --arg path "$project_path" \
   '.user_request = $req |
    .workflow_id = $wf |
    .project_id = $proj |
    .project_path = $path |
    .stage = "clarification" |
    .cycle_count = 0' \
   ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json
```

### Step 5: Start Architect

```bash
# 5.1 Check validation gates BEFORE delegation
check_all_gates "architect" "${project_path}/.n8n/run_state.json"

if [ $? -ne 0 ]; then
  echo "❌ Gate violation detected - cannot proceed"
  echo "See error message above for required action"
  exit 1
fi

# 5.2 Gates passed - proceed with delegation
Task({ subagent_type: "general-purpose", prompt: "## ROLE: Architect\nRead: .claude/agents/architect.md\n\n## TASK: Clarify requirements with user" })
```

### Validation Decision Matrix

| run_state | canonical | User Request | Action |
|-----------|-----------|--------------|--------|
| Empty | - | Any | Create new |
| stage=complete | Fresh | Any | Create new |
| stage=incomplete | - | Same request | Continue |
| stage=incomplete | - | Different request | ASK USER! |
| - | Outdated | Any | ASK USER! |
| - | Missing | workflow_id exists | Create snapshot |

---

## 🔒 Agent Delegation Protocol (MANDATORY!)

**BEFORE EVERY Task() call, Orchestrator MUST check gates:**

```bash
# Standard delegation pattern (use for ALL agent calls):

# 1. Determine target agent
target_agent="builder"  # or researcher, qa, architect, analyst

# 2. Check validation gates
check_all_gates "$target_agent" "${project_path}/.n8n/run_state.json"

if [ $? -ne 0 ]; then
  # Gate violation - STOP!
  echo "❌ Cannot delegate to $target_agent - gate violation"
  echo "See error message above for required action"
  exit 1
fi

# 3. Gates passed - proceed with delegation
Task({
  subagent_type: "general-purpose",
  model: "opus",  # only for builder
  prompt: `## ROLE: ${agent} Agent

  Read: .claude/agents/${agent}.md

  ## TASK
  ...`
})
```

**Applies to:**
- ✅ Architect (clarification)
- ✅ Researcher (search, analysis)
- ✅ Builder (create, modify workflows)
- ✅ QA (validate, test)
- ✅ Analyst (post-mortem, execution analysis)

**NO EXCEPTIONS!** Gates prevent disasters like FAILURE-ANALYSIS-2025-12-10.md

---

## Canonical Snapshot Protocol

**Purpose:** Single Source of Truth for each workflow. Analysis preserved between sessions.

**Location:** `${project_path}/.n8n/snapshots/{workflow_id}/canonical.json` + `history/`

**Lifecycle:**
- **Load (session start):** If exists → load from file. Else → create via Researcher
- **Update (after build):** Archive current to history → Create new → Save

**Commands:**
- `/orch snapshot view <id>` — Show nodes, anti-patterns, recommendations
- `/orch snapshot rollback <id> <version>` — Restore from history
- `/orch snapshot refresh <id>` — Force re-download from n8n

**Contents:** workflow_config (~5K) | extracted_code (~2K) | anti_patterns | learnings_matched | recommendations | execution_history | change_history

**Agent Access:** All agents READ snapshots (Researcher before debug, Builder before build, QA for compare, Analyst for context)

## Context Passed to Agents

Each agent receives full `run_state`:
- `id`, `user_request`, `goal`
- `stage`, `cycle_count`
- `requirements` (from Architect Phase 1)
- `research_request` (from Architect Phase 2)
- `research_findings` (from Researcher)
- `decision` (from Architect Phase 3)
- `blueprint` (from Architect Phase 3)
- `credentials_discovered` (from Researcher Phase 3 - scanned from existing workflows)
- `credentials_selected` (from Architect Phase 3 - user-chosen credentials)
- `build_guidance` (from Researcher Phase 4 - gotchas, node configs, warnings)
- `workflow` (from Builder)
- `qa_report` (from QA)
- `edit_scope` (nodes to modify)
- `worklog`, `agent_log` (history)

## Stage Transitions

### CREATE Flow (new workflow)
```
clarification → research → decision → credentials → implementation → build → validate → test → complete
                                                                                           ↓
                                                                                        blocked (after 7 QA fails)
```

### MODIFY Flow (existing workflow_id)
```
clarification (includes IMPACT_ANALYSIS sub-phase) → research → decision → credentials → implementation →
    ↓
INCREMENTAL_BUILD (with checkpoints)
    ↓
  [modify node_1] → checkpoint_qa → USER_APPROVAL
    ↓
  [modify node_2] → checkpoint_qa → USER_APPROVAL
    ↓
  [verify affected] → checkpoint_qa → USER_APPROVAL
    ↓
final_validate → complete | blocked
```

**CRITICAL:** System WAITS for user "да"/"ok"/"next" after each checkpoint!

## 🚨 ENFORCEMENT PROTOCOL (MANDATORY!)

> **Source:** `.claude/agents/shared/gate-enforcement.sh` (all gates implemented)
> **Docs:** `.claude/agents/validation-gates.md`

### BEFORE Calling ANY Agent

```bash
source .claude/agents/shared/gate-enforcement.sh

# Check ALL gates before delegation
check_all_gates "$target_agent" "${project_path}/.n8n/run_state.json"
[[ $? -ne 0 ]] && exit 1

# Proceed with Task() call only if gates passed
```

### Gates Checked (by `check_all_gates()`)

| Gate | Rule | When |
|------|------|------|
| **GATE 0** | Research before first Builder | Before build |
| **GATE 1** | Progressive escalation (1-3→Builder, 4-5→Researcher, 6-7→Analyst, 8+→BLOCKED) | QA loop |
| **GATE 2** | Execution analysis required for fixes | Before fix |
| **GATE 3** | Phase 5 real testing before QA PASS | After QA |
| **GATE 4** | Knowledge base before web search | Before search |
| **GATE 5** | MCP call verification (anti-fake) | After Builder |
| **GATE 6** | Hypothesis validation | After Researcher |

**If ANY gate fails → STOP, report violation, exit 1**

---

## QA Loop (max 7 cycles — progressive)

```
QA fail → Builder fix (edit_scope) → QA → repeat
├── Cycle 1-3: Builder fixes directly
├── Cycle 4-5: Researcher helps find alternative approach
├── Cycle 6-7: Analyst diagnoses root cause
└── After 7 fails → stage="blocked" → report to user with full history
```

---

## Recent Context Injection (Cycles 1-3)

**Problem:** Builder in cycles 1-3 doesn't know what was already tried (workflow rollback, new session).

**Solution:** Orchestrator extracts recent builder actions and adds to prompt.

### BEFORE calling Builder (cycles 1-3):

```bash
# Extract last 3 builder actions from agent_log
recent_builder=$(jq -c '[.agent_log[] | select(.agent=="builder")] | .[-3:]' ${project_path}/.n8n/run_state.json)

# Format for prompt
if [ "$recent_builder" != "[]" ]; then
  already_tried=$(echo "$recent_builder" | jq -r '.[] | "- \(.action): \(.details)"')
fi
```

### Include in Task prompt:

```javascript
Task({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: `## ROLE: Builder Agent
Read: .claude/agents/builder.md

## CONTEXT
Read state from: ${project_path}/.n8n/run_state.json

## TASK
Fix workflow per edit_scope.

${already_tried ? `⚠️ ALREADY TRIED (don't repeat!):
${already_tried}

Try a DIFFERENT approach.` : ''}

edit_scope: ${edit_scope}
qa_report: ${qa_report_summary}`
})
```

### When to use:

| Cycle | Include recent context? | Why |
|-------|------------------------|-----|
| 1-3 | ✅ YES | Builder needs to know what failed |
| 4-5 | ❌ NO | Researcher reads `_meta.fix_attempts` |
| 6-7 | ❌ NO | Analyst reads full history |

---

## Post-Fix Checklist (L-067)

**After successful fix + test:**
1. ✅ Fix applied (Builder confirmed)
2. ✅ Tests passed (QA Phase 5)
3. ✅ User verified in n8n UI
4. **ASK:** "Update canonical snapshot? [Y/N]"
   - Y → Update snapshot
   - N → Keep old (user wants more testing)

**Rules:** ❌ NEVER update without user approval! ❌ NEVER update if tests failed!

---

## Post-Build Verification Protocol

**After Builder execution, delegate to QA for verification:**

| Check | Pass | Fail |
|-------|------|------|
| Version changed | Continue | ❌ BLOCK: Update failed silently |
| Changes applied | Continue | ❌ BLOCK: Change not applied |
| Rollback detected | Continue | ⚠️ STOP: Ask user re-apply/abort |
| Node count match | Continue | ⚠️ WARN: Data corruption |

**L-067:** Use `mode="structure"` for workflows >10 nodes, `mode="full"` for smaller.

**On failure:** BLOCK QA → Report to user → Offer rollback → Do NOT continue

## Test Mode

### `--test` (Quick health check)
Tests each agent can be invoked:

| Agent | Test | MCP Tools |
|-------|------|-----------|
| Orchestrator | read run_state | list/get workflows |
| Architect | read files + skills | **NO MCP!** |
| Researcher | search nodes/templates | full search |
| Builder | validate node config | mutations |
| QA | list workflows + executions | testing |
| Analyst | read executions | read-only |

**IMPORTANT:** Architect has NO MCP tools - only Read + Skills!

### `--test e2e` (End-to-End Production Test)

**REAL workflow test** — NOT a mock! Works exactly like normal system.

Follows **standard 5-PHASE FLOW** (no shortcuts):
- Creates REAL 20+ node workflow
- Services: Telegram, Supabase, OpenAI, HTTP
- Auto-discovers and uses real credentials
- Activates, triggers via Chat webhook, verifies execution
- Analyst report at end

**Test workflow:**
- Chat Trigger (dual mode: UI + webhook)
- AI Agent + Supabase + HTTP + Telegram
- Complex logic (IF, Switch, error handling)

**Success:** All nodes executed, services responded, no QA errors, analyst report generated.

**Cleanup:** Deactivate workflow, tag "e2e-test", keep for reference.

### `--test agent:NAME`
Tests specific agent in isolation:
```
/orch --test agent:builder
/orch --test agent:qa
/orch --test agent:researcher
```

## Examples

### Create Simple Workflow
```
/orch Create a webhook that responds with "Hello World"
```

### Create Complex Integration
```
/orch mode=complex goal="Telegram bot that saves messages to Supabase and notifies Slack" services="telegram,supabase,slack"
```

### Fix Existing Workflow
```
/orch workflow_id=abc123 Fix the Supabase insert error
```

### Run Tests
```
/orch --test e2e           # Production-grade 20+ node test
```

## Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| L1 | Simple error | Builder direct fix |
| L2 | Unknown error | Researcher → Builder |
| L3 | 7+ failures | stage="blocked" |
| L4 | Blocked | Report to user + Analyst post-mortem |

---

## Debugger Mode (Fast Fix)

**Problem:** Full 5-phase flow is overkill for simple bugs.

### 3-Level Debug System

| Level | Trigger | Agents | Flow | Escalate |
|-------|---------|--------|------|----------|
| **L1** QUICK_FIX | `/orch --fix workflow_id=X node="Y"` | Builder | Read → Fix → Validate | 2 fails → L2 |
| **L2** TARGETED | `/orch --debug workflow_id=X` | Analyst → Builder | Analyze executions → Find root cause → Fix | Unclear → L3 |
| **L3** FULL | Complex/"bot not working" | Researcher → Builder → QA | Full diagnosis (L-067) → User approval → Fix → Test | - |

**L3 Details:** Researcher downloads workflow (mode=structure for >10 nodes), analyzes executions (summary→filtered), finds WHERE + ROOT CAUSE, presents to user → Builder fixes → QA tests.

### Auto-Detection

| User says | Level | Why |
|-----------|-------|-----|
| "fix X in node Y" | L1 | Specific node |
| "debug workflow"/"why doesn't work" | L2 | Need diagnosis |
| "redesign the flow" | L3 | Architectural |
| L1 failed 2x | L2 | Auto-escalate |
| L2 unclear | L3 | Auto-escalate |

**🚨 MUST use L3 if:** 2nd+ fix attempt | 3+ nodes modified | 3+ execution failures | Root cause unclear | Architectural issue

---

## Hard Caps (Resource Limits)

| Resource | Limit | Action |
|----------|-------|--------|
| Tokens | 50K | Stop + report |
| Agent calls | 25 | Stop + report |
| Time | 10 min | Stop + report |
| QA cycles | 7 | stage="blocked" |

**On limit reached:** Show all attempts → Offer rollback/extend/escalate

---

## Handoff Contracts (Agent → Agent)

| Transition | Required | Validator |
|------------|----------|-----------|
| architect→researcher | requirements, research_request | services[] not empty |
| researcher→architect | research_findings | templates or workflows found |
| architect→builder | blueprint, credentials_selected | nodes_needed[] not empty |
| researcher→builder | build_guidance | node_configs[] not empty |
| builder→qa | workflow.id, node_count | id exists, count > 0 |
| qa→builder | qa_report, edit_scope | edit_scope[] if failed |

**On handoff fail:** Re-run agent with explicit request → Fill manually → Skip (risky)

---

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
