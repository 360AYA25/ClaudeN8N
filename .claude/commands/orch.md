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

| Команда | Описание |
|---------|----------|
| `/orch <задача>` | Создать/изменить workflow (5-phase flow) |
| `/orch workflow_id=X <задача>` | Модифицировать существующий workflow (MODIFY flow) |
| `/orch --fix workflow_id=X node="Y" error="Z"` | **L1 Quick Fix** (~500 tokens) |
| `/orch --debug workflow_id=X` | **L2 Targeted Debug** (~2K tokens) |
| `/orch --test` | Quick health check всех агентов |
| `/orch --test agent:builder` | Тест Builder агента |
| `/orch --test agent:qa` | Тест QA агента |
| `/orch --test agent:researcher` | Тест Researcher агента |
| `/orch --test agent:architect` | Тест Architect агента |
| `/orch --test agent:analyst` | Тест Analyst агента |
| `/orch --test e2e` | Full E2E тест — создает реальный workflow 20+ нод |
| `/orch snapshot view <workflow_id>` | Посмотреть canonical snapshot |
| `/orch snapshot rollback <id> [version]` | Откатить snapshot к версии |
| `/orch snapshot refresh <workflow_id>` | Принудительно обновить snapshot |

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

### Agent Role Templates

| Agent | Model | Role Prompt |
|-------|-------|-------------|
| architect | sonnet (default) | `## ROLE: Architect Agent\nRead: .claude/agents/architect.md` |
| researcher | sonnet (default) | `## ROLE: Researcher Agent\nRead: .claude/agents/researcher.md` |
| builder | `model: "opus"` | `## ROLE: Builder Agent\nRead: .claude/agents/builder.md` |
| qa | sonnet (default) | `## ROLE: QA Agent\nRead: .claude/agents/qa.md` |
| analyst | sonnet (default) | `## ROLE: Analyst Agent\nRead: .claude/agents/analyst.md` |

### Agent Delegation

| Stage | Agent | Model |
|-------|-------|-------|
| clarification | architect | sonnet |
| research | researcher | sonnet |
| decision | architect | sonnet |
| credentials | researcher | sonnet |
| implementation | researcher | sonnet |
| build | builder | opus 4.5 |
| validate/test | qa | sonnet |
| analysis | analyst | sonnet |

### Context Passing

1. **In prompt**: Pass ONLY summary (not full JSON!)
2. **Agent reads**: `${project_path}/.n8n/run_state.json` for details
3. **Agent writes**: Results to run_state + `${project_path}/.n8n/agent_results/`
4. **Return**: Summary only (~500 tokens max)

### 🛑 MANDATORY Validation Gates

**See `.claude/agents/validation-gates.md` for full rules.**

**GATE 1: Execution Analysis Required (DEBUGGING ONLY)**
```javascript
// BEFORE any fix attempt:
if (user_reports_broken && !execution_data_analyzed) {
  BLOCK("❌ FORBIDDEN: Fix without execution analysis!");
  REQUIRE: researcher.analyze_execution_data();
  // Researcher MUST get execution logs, identify stopping point
}

// 🔴 CRITICAL (L-060): Code Node Inspection!
if (code_node_never_executes && !code_inspected) {
  BLOCK("❌ FORBIDDEN: Fix Code node without inspecting JavaScript!");
  REQUIRE: researcher.STEP_0_3_1_inspect_code_nodes();
  // Execution data ≠ Configuration data!
  // MUST check for deprecated $node["..."] syntax → causes 300s timeout
}
```

**GATE 2: Hypothesis Validation Required**
```javascript
// BEFORE calling Builder:
if (!research_findings.hypothesis_validated) {
  BLOCK("❌ FORBIDDEN: Unvalidated hypothesis!");
  REQUIRE: researcher.validate_with_mcp_tools();
  // Researcher MUST use get_node to verify configuration
}

if (!research_findings || !build_guidance_file_exists) {
  BLOCK("❌ FORBIDDEN: Missing research or build_guidance!");
}

if (modifying_workflow && !user_approval) {
  BLOCK("❌ FORBIDDEN: User approval required for modifications!");
}
```

**GATE 3: Post-Build Verification Required**
```javascript
// AFTER Builder completes:
if (builder_result.version_id) {
  REQUIRE: orchestrator.verify_changes_applied();
  // 1. Read workflow via MCP
  // 2. Check version_id changed
  // 3. Verify expected parameters present
  // 4. Detect rollback (version_counter decreased)
}
```

**GATE 4: Circuit Breaker**
```javascript
// If 2 cycles with same hypothesis:
if (cycle_count >= 2 && current_hypothesis === previous_hypothesis) {
  ESCALATE_TO_L4();
  REQUIRE: analyst.audit_methodology();
  REASON: "Not learning from failures";
}

// If 7 QA cycles with progressive escalation:
if (qa_fail_count >= 7) {
  ESCALATE_TO_L4();
  ANALYST_AUDIT_METHODOLOGY();
  // Progressive: cycles 1-3 Builder, 4-5 +Researcher, 6-7 +Analyst
}
```

**Before workflow mutation:**
- ❌ FORBIDDEN if 3+ nodes AND NOT incremental mode
- ❌ FORBIDDEN if stage !== "build"

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

```bash
# 1. Merge agent result into run_state
jq --argjson result "$AGENT_RESULT" \
   '.requirements = $result.requirements // .requirements |
    .research_findings = $result.research_findings // .research_findings |
    .decision = $result.decision // .decision |
    .blueprint = $result.blueprint // .blueprint |
    .build_guidance = $result.build_guidance // .build_guidance |
    .workflow = $result.workflow // .workflow |
    .qa_report = $result.qa_report // .qa_report |
    .edit_scope = $result.edit_scope // .edit_scope' \
   ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json
```

### Stage transitions (Orchestrator decides):

```bash
# After Architect (clarification → research)
jq '.stage = "research"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After Researcher (research → decision)
jq '.stage = "decision"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After Architect decision (decision → implementation)
jq '.stage = "implementation"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After Researcher implementation (implementation → build)
jq '.stage = "build"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After Builder (build → validate)
jq '.stage = "validate"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After QA success (validate → test → complete)
jq '.stage = "complete"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After QA fail (stay in validate, increment cycle)
jq '.cycle_count += 1 | .stage = "build"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json

# After 7 QA fails (→ blocked)
jq '.stage = "blocked"' ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json
```

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

## ❌ L-073: ANTI-FAKE - Verify MCP Calls in Agent Output!

> **Note:** Verification is delegated to QA agent, NOT done by Orchestrator directly.
> The code below shows what QA agent executes when validating Builder output.

**Orchestrator MUST verify agents actually used MCP tools!**

### After Builder returns (BEFORE calling QA):

```bash
# Check agent_log for MCP calls
latest_builder=$(jq '[.agent_log[] | select(.agent=="builder")] | last' ${project_path}/.n8n/run_state.json)
mcp_calls=$(echo "$latest_builder" | jq -r '.mcp_calls // []')

# BLOCK if no MCP calls!
if [ "$mcp_calls" == "[]" ] || [ "$mcp_calls" == "null" ]; then
  echo "❌ L-073 FRAUD DETECTED: Builder reported success without MCP calls!"
  jq '.stage = "blocked" | .block_reason = "L-073: No MCP calls in agent_log"' \
     ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json
  # DO NOT proceed to QA!
  exit 1
fi

# Double-check: verify workflow exists via MCP
workflow_id=$(jq -r '.workflow_id' ${project_path}/.n8n/run_state.json)
real_check=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="minimal")

if [ -z "$real_check" ] || echo "$real_check" | jq -e '.error' > /dev/null; then
  echo "❌ L-073: Workflow $workflow_id does NOT exist in n8n!"
  jq '.stage = "blocked" | .block_reason = "L-073: Workflow not found in n8n"' \
     ${project_path}/.n8n/run_state.json > tmp.json && mv tmp.json ${project_path}/.n8n/run_state.json
  exit 1
fi

echo "✅ L-073: MCP calls verified, workflow exists"
```

### What gets BLOCKED:

| Check | Blocked If |
|-------|-----------|
| `mcp_calls` array | Missing or empty |
| `verified` field | false or missing |
| `n8n_get_workflow` | Returns error/null |
| Node count | Doesn't match claim |

**Trust NO agent! Verify EVERYTHING via MCP!**

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
# Parse rollback command
if [[ "$user_request" =~ ^/orch\ rollback ]]; then

  # Get project context
  if [ -f ${project_path}/.n8n/run_state.json ]; then
    project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' ${project_path}/.n8n/run_state.json)
    workflow_id=$(jq -r '.workflow_id // null' ${project_path}/.n8n/run_state.json)
  else
    project_path="/Users/sergey/Projects/ClaudeN8N"
    workflow_id=null
  fi

  snapshot_dir="${project_path}/.n8n/snapshots"

  # Handle "list" subcommand
  if [[ "$user_request" =~ rollback\ list ]]; then
    echo "📋 Available snapshots in $snapshot_dir:"
    echo ""
    if [ -d "$snapshot_dir" ] && [ -n "$(ls -A $snapshot_dir 2>/dev/null)" ]; then
      ls -1t "$snapshot_dir"/*.json | while read file; do
        timestamp=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
        basename_file=$(basename "$file")
        size=$(du -h "$file" | cut -f1)
        echo "  $basename_file ($size, created: $timestamp)"
      done
    else
      echo "  No snapshots found"
    fi
    exit 0
  fi

  # Get timestamp (latest if not specified)
  timestamp=$(echo "$user_request" | awk '{print $3}')

  if [ -z "$timestamp" ]; then
    # Get latest snapshot
    latest_snapshot=$(ls -t "$snapshot_dir"/*.json 2>/dev/null | head -1)

    if [ -z "$latest_snapshot" ]; then
      echo "❌ No snapshots found in $snapshot_dir"
      echo "Snapshots are created automatically before destructive changes"
      exit 1
    fi

    timestamp=$(basename "$latest_snapshot" | cut -d'-' -f1-6)
  fi

  # Find snapshot file
  snapshot_file=$(find "$snapshot_dir" -name "${timestamp}*.json" 2>/dev/null | head -1)

  if [ ! -f "$snapshot_file" ]; then
    echo "❌ Snapshot not found: $timestamp"
    echo "Available snapshots:"
    ls -1 "$snapshot_dir"/*.json 2>/dev/null | xargs -n1 basename || echo "  No snapshots"
    exit 1
  fi

  # Extract workflow_id from snapshot
  if [ "$workflow_id" = "null" ]; then
    workflow_id=$(jq -r '.id // .workflow_id // null' "$snapshot_file")

    if [ "$workflow_id" = "null" ]; then
      echo "❌ Cannot determine workflow_id from snapshot"
      exit 1
    fi
  fi

  # Confirm with user
  echo "⚠️ This will restore workflow to snapshot:"
  echo "   Workflow ID: $workflow_id"
  echo "   Snapshot: $(basename $snapshot_file)"
  echo "   Created: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$snapshot_file")"
  echo "   Size: $(du -h "$snapshot_file" | cut -f1)"
  echo ""
  read -p "Confirm rollback? (yes/no): " confirm

  if [ "$confirm" != "yes" ]; then
    echo "❌ Rollback cancelled"
    exit 0
  fi

  # Delegate to Builder for restore
  Task({
    subagent_type: "general-purpose",
    model: "opus",
    prompt: `## ROLE: Builder Agent

Read: .claude/agents/builder.md

## TASK: Restore workflow from snapshot

Snapshot file: $snapshot_file
Workflow ID: $workflow_id
Project path: $project_path

Steps:
1. Read snapshot file
2. Use mcp__n8n-mcp__n8n_update_full_workflow to restore
3. Verify restore successful (n8n_get_workflow)
4. Report to user with workflow stats (node count, connections)

CRITICAL:
- Use EXACT workflow JSON from snapshot
- Verify with MCP call after restore
- Report success with workflow details
`
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

### Step 0: Load Gate Enforcement (🔒 NEW - CRITICAL!)

```bash
# 0.1 Source gate enforcement functions
source .claude/agents/shared/gate-enforcement.sh

# 0.2 Source frustration detection functions
source .claude/agents/shared/frustration-detector.sh

# 0.3 This enables validation gates BEFORE every agent delegation
# Reference: SYSTEM-SAFETY-OVERHAUL.md (prevents FAILURE-ANALYSIS disasters)

echo "🔒 Gate enforcement loaded (v1.0.0)"
echo "🧠 Frustration detection loaded (v1.0.0)"
```

### Step 0.5: Check User Frustration (🚨 NEW - PREVENTS 6-HOUR DISASTERS!)

```bash
# 0.5.1 Initialize session_start if new session
if [ ! -f ${project_path}/.n8n/run_state.json ] || [ "$(jq -r '.session_start // null' ${project_path}/.n8n/run_state.json)" = "null" ]; then
  # Create/update run_state with session_start
  session_start=$(date +%s)

  if [ -f ${project_path}/.n8n/run_state.json ]; then
    jq --arg ts "$session_start" '.session_start = ($ts | tonumber)' \
       ${project_path}/.n8n/run_state.json > /tmp/run_state_tmp.json && \
       mv /tmp/run_state_tmp.json ${project_path}/.n8n/run_state.json
  else
    # Create minimal run_state for frustration detection
    echo '{"session_start": '"$session_start"', "frustration_signals": {"profanity": 0, "complaints": 0, "repeated_requests": 0, "session_duration": 0}}' > ${project_path}/.n8n/run_state.json
  fi
fi

# 0.5.2 Update last_request for repeated request detection
if [ -f ${project_path}/.n8n/run_state.json ]; then
  jq --arg req "$user_request" '.last_request = $req' \
     ${project_path}/.n8n/run_state.json > /tmp/run_state_tmp.json && \
     mv /tmp/run_state_tmp.json ${project_path}/.n8n/run_state.json
fi

# 0.5.3 Check frustration level
frustration_action=$(check_frustration "$user_request" ${project_path}/.n8n/run_state.json)

# 0.5.4 Handle frustration levels
case "$frustration_action" in
  STOP_AND_ROLLBACK)
    echo ""
    echo "🚨 CRITICAL FRUSTRATION DETECTED"
    echo ""
    get_frustration_message "CRITICAL"
    echo ""

    # Show frustration signals
    signals=$(jq -r '.frustration_signals' ${project_path}/.n8n/run_state.json)
    echo "Signals detected:"
    echo "$signals" | jq '.'
    echo ""

    # Execute auto-rollback
    snapshot_path=$(execute_auto_rollback ${project_path}/.n8n/run_state.json)

    if [ $? -eq 0 ]; then
      echo "✅ Auto-rollback completed: $snapshot_path"
      echo ""
      echo "💤 Рекомендация: Продолжим завтра, когда ты отдохнёшь? 😊"
      echo ""
      echo "Для восстановления используй:"
      echo "  /orch rollback $(basename $snapshot_path .json)"
    fi

    # STOP processing - do not continue with task
    exit 0
    ;;

  OFFER_ROLLBACK)
    echo ""
    echo "⚠️ HIGH FRUSTRATION DETECTED"
    echo ""
    get_frustration_message "HIGH"
    echo ""

    # Show frustration signals
    signals=$(jq -r '.frustration_signals' ${project_path}/.n8n/run_state.json)
    echo "Signals detected:"
    echo "$signals" | jq '.'
    echo ""

    echo "Варианты:"
    echo "  [R]ollback - Откатить все изменения"
    echo "  [C]ontinue - Попробовать другой подход"
    echo "  [S]top - Остановить и отдохнуть"
    echo ""
    echo "❓ Что выбираешь? (R/C/S)"

    # WAIT FOR USER INPUT before continuing
    # Note: In actual implementation, orchestrator should pause here
    # For now, this is a reminder to handle user choice
    ;;

  CHECK_IN)
    echo ""
    echo "💡 MODERATE FRUSTRATION DETECTED"
    echo ""
    get_frustration_message "MODERATE"
    echo ""

    # Continue processing but notify user
    ;;

  CONTINUE)
    # Normal processing - no frustration detected
    ;;
esac
```

### Step 0.75: Project Path Detection (🗂️ NEW - DISTRIBUTED ARCHITECTURE!)

```bash
# 0.75.1 Detect project_path from run_state or user input
if [ -f ${project_path}/.n8n/run_state.json ]; then
  project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' ${project_path}/.n8n/run_state.json)
  workflow_id=$(jq -r '.workflow_id // null' ${project_path}/.n8n/run_state.json)
else
  # Default to ClaudeN8N project
  project_path="/Users/sergey/Projects/ClaudeN8N"
  workflow_id=null
fi

# 0.75.2 If workflow_id provided in user_request, extract it
if [[ "$user_request" =~ workflow_id=([a-zA-Z0-9_-]+) ]]; then
  workflow_id="${BASH_REMATCH[1]}"
fi

# 0.75.3 If workflow_id known, detect project_path from workflow location
# (For future: can lookup workflow → project mapping)

echo "📁 Project: $project_path"
echo "📋 Workflow: ${workflow_id:-none}"
echo ""

# 0.75.4 Context Freshness Check (if SYSTEM-CONTEXT.md exists)
if [ -n "$workflow_id" ] && [ -f "${project_path}/.context/SYSTEM-CONTEXT.md" ]; then
  # Get workflow version from n8n API
  real_workflow=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="minimal")
  workflow_version=$(echo "$real_workflow" | jq -r '.versionId // .versionCounter')

  # Get context version from SYSTEM-CONTEXT.md
  context_version=$(grep -m1 "Workflow Version:" "${project_path}/.context/SYSTEM-CONTEXT.md" | awk '{print $3}')

  if [ -n "$context_version" ] && [ "$workflow_version" != "$context_version" ]; then
    echo "⚠️ CONTEXT OUTDATED!"
    echo "   Workflow version: $workflow_version"
    echo "   Context version: $context_version"
    echo ""
    echo "Recommendation: Refresh context before continuing"
    echo "Command: /orch snapshot refresh $workflow_id"
    echo ""
  fi
fi

# 0.75.5 Export project_path for use in all subsequent steps
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
    usage: { tokens_used: 0, agent_calls: 0, qa_cycles: 0, cost_usd: 0 }
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

### Purpose
Single Source of Truth для каждого workflow. Детальный анализ сохраняется между сессиями.

### Directory Structure
```
${project_path}/.n8n/snapshots/
├── {workflow_id}/
│   ├── canonical.json       # Current snapshot (~10K tokens)
│   └── history/
│       └── v{N}_{date}.json # Previous versions
└── README.md
```

### Load Snapshot (at session start)

```javascript
if (workflow_id) {
  const snapshot_dir = `${project_path}/.n8n/snapshots/${workflow_id}`;
  const canonical_file = `${snapshot_dir}/canonical.json`;

  if (file_exists(canonical_file)) {
    // Load existing
    run_state.canonical_snapshot = read_json(canonical_file);
    console.log(`📖 Loaded snapshot: ${run_state.canonical_snapshot.node_inventory.total} nodes`);
  } else {
    // Create initial
    console.log("📸 Creating initial canonical snapshot...");
    run_state.canonical_snapshot = await createCanonicalSnapshot(workflow_id);
  }

  run_state.snapshot = {
    dir: snapshot_dir,
    file: canonical_file,
    version: run_state.canonical_snapshot.snapshot_metadata.snapshot_version,
    anti_patterns_count: run_state.canonical_snapshot.anti_patterns_detected.length
  };
}
```

### Update Snapshot (after successful build)

```javascript
if (build_result.success && workflow_id) {
  // 1. Archive current to history
  const current_version = run_state.canonical_snapshot.snapshot_metadata.snapshot_version;
  const history_file = `${snapshot_dir}/history/v${current_version}_${timestamp}.json`;
  write_file(history_file, run_state.canonical_snapshot);

  // 2. Create new canonical
  const new_snapshot = await createCanonicalSnapshot(workflow_id);
  new_snapshot.change_history.push({
    version: current_version + 1,
    timestamp: new Date().toISOString(),
    action: run_state.stage === "build" ? "feature" : "fix",
    description: run_state.goal,
    nodes_changed: build_result.nodes_changed
  });

  // 3. Save
  write_file(`${snapshot_dir}/canonical.json`, new_snapshot);
  console.log(`✅ Snapshot updated: v${current_version} → v${current_version + 1}`);
}
```

### Snapshot Commands

**View snapshot:**
```
/orch snapshot view sw3Qs3Fe3JahEbbW

📸 Canonical Snapshot: FoodTracker v2.0
├── Nodes: 29
├── Anti-patterns: 1 (L-060)
├── Last updated: 2025-11-28 23:30
├── History: 5 versions
└── Recommendations:
    1. [CRITICAL] Fix deprecated $node["..."] in 7 Code nodes
```

**Rollback:**
```
/orch snapshot rollback sw3Qs3Fe3JahEbbW v4
→ Restores canonical.json from history/v4_*.json
```

**Force refresh:**
```
/orch snapshot refresh sw3Qs3Fe3JahEbbW
→ Downloads fresh from n8n, recreates snapshot
```

### What Snapshot Contains

| Section | Purpose | Size |
|---------|---------|------|
| workflow_config | Full nodes + connections | ~5K |
| extracted_code | All jsCode from Code nodes | ~2K |
| anti_patterns_detected | L-060, L-056, etc. | ~200 |
| learnings_matched | Already checked LEARNINGS | ~200 |
| recommendations | Prioritized fixes | ~300 |
| execution_history | Last 10 runs summary | ~500 |
| change_history | Who changed what | ~300 |

### Agent Usage

| Agent | Access | When |
|-------|--------|------|
| Researcher | READ | Before debug — use instead of n8n_get_workflow |
| Builder | READ | Before build — check anti_patterns |
| QA | READ | Compare before/after |
| Analyst | READ | Richer context for post-mortem |

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

> **Source:** validation-gates.md (Priority 0 Critical Gates)
> **Orchestrator MUST check gates BEFORE every Task call in QA loop!**

### BEFORE Calling ANY Agent in QA Loop

**Step 1: Check GATE 1 - Progressive Escalation**

```bash
# Read current cycle
cycle=$(jq -r '.cycle_count // 0' ${project_path}/.n8n/run_state.json)
stage=$(jq -r '.stage' ${project_path}/.n8n/run_state.json)

# GATE 1 CHECK: Progressive Escalation
if [ "$stage" = "validate" ] || [ "$stage" = "build" ]; then
  # Cycle 1-3: Builder OK
  if [ "$cycle" -ge 1 ] && [ "$cycle" -le 3 ]; then
    echo "✅ GATE 1 PASS: Cycle $cycle allows Builder direct fix"
  fi

  # Cycle 4-5: MUST call Researcher FIRST!
  if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ]; then
    # Check if Researcher was already called this cycle
    researcher_called=$(jq -r '[.agent_log[] | select(.agent=="researcher" and .cycle_context=='$cycle')] | length > 0' ${project_path}/.n8n/run_state.json 2>/dev/null || echo "false")

    if [ "$researcher_called" != "true" ]; then
      echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Researcher FIRST (alternative approach)!"
      echo "Required: Call Researcher to find different solution before Builder."
      echo "See validation-gates.md GATE 1 for details."
      exit 1
    fi
  fi

  # Cycle 6-7: MUST call Analyst FIRST!
  if [ "$cycle" -ge 6 ] && [ "$cycle" -le 7 ]; then
    analyst_called=$(jq -r '[.agent_log[] | select(.agent=="analyst" and .cycle_context=='$cycle')] | length > 0' ${project_path}/.n8n/run_state.json 2>/dev/null || echo "false")

    if [ "$analyst_called" != "true" ]; then
      echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Analyst FIRST (root cause diagnosis)!"
      echo "Required: Call Analyst to analyze execution logs and identify root cause."
      echo "See validation-gates.md GATE 1 for details."
      exit 1
    fi
  fi

  # Cycle 8+: BLOCKED!
  if [ "$cycle" -ge 8 ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle 8+ blocked! No more attempts allowed."
    echo "Required: Set stage='blocked' and escalate to user."
    echo "See validation-gates.md GATE 1 for details."
    exit 1
  fi
fi
```

**Step 2: Check GATE 2 - Execution Analysis (if fixing workflow)**

```bash
# GATE 2 CHECK: Execution Analysis Required
workflow_id=$(jq -r '.workflow_id // ""' ${project_path}/.n8n/run_state.json)

# Check if fixing existing workflow (not creating new)
if [ "$stage" = "build" ] && [ -n "$workflow_id" ] && [ -f "${project_path}/.n8n/snapshots/$workflow_id/canonical.json" ]; then
  # This is a FIX to existing workflow
  execution_analysis=$(jq -r '.execution_analysis.completed // false' ${project_path}/.n8n/run_state.json)

  if [ "$execution_analysis" != "true" ]; then
    echo "🚨 GATE 2 VIOLATION: Cannot fix without execution analysis!"
    echo "Required: Call Analyst to analyze last 5 executions FIRST."
    echo "Must identify: WHERE it breaks, root cause, failed executions count."
    echo "See validation-gates.md GATE 2 for details."
    exit 1
  fi

  echo "✅ GATE 2 PASS: Execution analysis completed"
fi
```

**Step 3: Check GATE 4 - Context Injection (cycle 2+)**

```bash
# GATE 4 CHECK: Fix Attempts History
if [ "$cycle" -ge 2 ]; then
  fix_attempts=$(jq -r '.fix_attempts // []' ${project_path}/.n8n/run_state.json)

  if [ "$fix_attempts" = "[]" ]; then
    echo "🚨 GATE 4 VIOLATION: Cycle $cycle requires fix_attempts history!"
    echo "Required: Extract previous failed approaches and add to run_state.fix_attempts[]"
    echo "See validation-gates.md GATE 4 for details."
    exit 1
  fi

  echo "✅ GATE 4 PASS: Fix attempts history present (cycle $cycle)"
fi
```

**Step 4: Check GATE 5 - MCP Call Verification (after Builder)**

```bash
# GATE 5 CHECK: MCP Call Verification (after Builder completes)
# This check runs AFTER Builder Task returns

build_result_file="${project_path}/.n8n/agent_results/${workflow_id}/build_result.json"

if [ -f "$build_result_file" ]; then
  builder_status=$(jq -r '.build_result.status // ""' "$build_result_file")

  if [ "$builder_status" = "success" ]; then
    mcp_calls=$(jq -r '.build_result.mcp_calls // []' "$build_result_file")

    if [ "$mcp_calls" = "[]" ]; then
      echo "🚨 GATE 5 VIOLATION: Builder reported success without MCP call proof!"
      echo "Possible L-073 fake success pattern detected."
      echo "See validation-gates.md GATE 5 for details."
      exit 1
    fi

    # Verify at least one create/update call
    has_mutation=$(echo "$mcp_calls" | jq '[.[] | select(.tool | test("create|update|autofix"))] | length > 0')

    if [ "$has_mutation" != "true" ]; then
      echo "🚨 GATE 5 VIOLATION: No create/update MCP calls found!"
      echo "See validation-gates.md GATE 5 for details."
      exit 1
    fi

    echo "✅ GATE 5 PASS: MCP calls verified ($mcp_calls)"
  fi
fi
```

**Step 5: Check GATE 6 - Researcher Hypothesis Validation (after Researcher)**

```bash
# GATE 6 CHECK: Hypothesis Validation (after Researcher completes)
research_file="${project_path}/.n8n/agent_results/${workflow_id}/research_findings.json"

if [ -f "$research_file" ]; then
  researcher_status=$(jq -r '.research_findings.status // ""' "$research_file")

  if [ "$researcher_status" = "complete" ]; then
    hypothesis_validated=$(jq -r '.research_findings.hypothesis_validated // false' "$research_file")

    if [ "$hypothesis_validated" != "true" ]; then
      echo "🚨 GATE 6 VIOLATION: Researcher proposed solution without testing hypothesis!"
      echo "Required: Validate hypothesis with execution data before proposing to Builder."
      echo "See validation-gates.md GATE 6 for details."
      exit 1
    fi

    echo "✅ GATE 6 PASS: Hypothesis validated"
  fi
fi
```

**Step 6: Check GATE 3 - Phase 5 Real Testing (before accepting QA PASS)**

```bash
# GATE 3 CHECK: Phase 5 Real Testing (before accepting QA PASS)
qa_report_file="${project_path}/.n8n/agent_results/${workflow_id}/qa_report.json"

if [ -f "$qa_report_file" ]; then
  qa_status=$(jq -r '.qa_report.status // ""' ${project_path}/.n8n/run_state.json)

  if [ "$qa_status" = "PASS" ]; then
    phase_5_executed=$(jq -r '.qa_report.phase_5_executed // false' "$qa_report_file")

    if [ "$phase_5_executed" != "true" ]; then
      echo "🚨 GATE 3 VIOLATION: QA reported PASS without Phase 5 real testing!"
      echo "Required: QA must trigger workflow and verify execution."
      echo "See validation-gates.md GATE 3 for details."
      exit 1
    fi

    echo "✅ GATE 3 PASS: Phase 5 real testing completed"
  fi
fi
```

### Enforcement Summary

**Before EVERY Task call in QA loop:**
1. ✅ Check GATE 1 (progressive escalation - cycle based agent selection)
2. ✅ Check GATE 2 (execution analysis required for fixes)
3. ✅ Check GATE 4 (fix attempts history for cycle 2+)

**After agent returns:**
4. ✅ Check GATE 5 (MCP call verification after Builder)
5. ✅ Check GATE 6 (hypothesis validation after Researcher)
6. ✅ Check GATE 3 (Phase 5 testing before QA PASS)

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

**Token cost:** ~150 tokens (3 entries × 50 tokens)

---

## Post-Fix Checklist (MANDATORY! - L-067)

**After successful fix + test, Orchestrator MUST:**

```markdown
## Post-Fix Checklist
- [ ] Fix applied (Builder confirmed)
- [ ] Tests passed (QA Phase 5 real test)
- [ ] User verified in n8n UI
- [ ] **ASK USER:** "Workflow fixed and tested. Update canonical snapshot? [Y/N]"
- [ ] If Y → Update snapshot
- [ ] If N → Note reason, keep old snapshot
```

**⚠️ CRITICAL RULES:**
- ❌ NEVER update snapshot without user approval!
- ❌ NEVER update snapshot if tests failed!
- ✅ ALWAYS ask user after successful test

**Integration with Snapshot System:**
```
┌────────────────────────────────────────────────────────────────┐
│  ⚠️ AFTER SUCCESSFUL FIX + TEST:                               │
│                                                                │
│  1. QA confirms workflow works                                 │
│  2. ASK USER: "Workflow fixed and tested. Update snapshot?"    │
│  3. IF user approves:                                          │
│     └── Update canonical.json with new working state           │
│  4. IF user declines:                                          │
│     └── Keep old snapshot (user may want more testing)         │
│                                                                │
│  ❌ NEVER update snapshot without user approval!               │
│  ❌ NEVER update snapshot if tests failed!                     │
└────────────────────────────────────────────────────────────────┘
```

---

## Post-Build Verification Protocol

**Orchestrator MUST verify AFTER every Builder execution:**

```bash
# 1. Read updated workflow (L-067: smart mode selection)
node_count=$(jq -r '.workflow.node_count // 999' ${project_path}/.n8n/run_state.json)
mode=$( [ "$node_count" -gt 10 ] && echo "structure" || echo "full" )
workflow=$(mcp__n8n-mcp__n8n_get_workflow id=$workflow_id mode="$mode")

# 2. Verify version changed
current_version=$(echo $workflow | jq -r '.versionId')
if [ "$current_version" == "$previous_version" ]; then
  FAIL("❌ CRITICAL: Workflow version didn't change! Update may have failed silently.");
  BLOCK_QA();
  REPORT_TO_USER();
fi

# 3. Verify specific changes (from build_guidance expected_changes)
for change in "${expected_changes[@]}"; do
  node=$(echo $workflow | jq ".nodes[] | select(.name == \"${change.node}\")")
  actual_value=$(echo $node | jq -r ".parameters.${change.parameter}")

  if [ "$actual_value" != "${change.value}" ]; then
    FAIL("❌ Change not applied: ${change.node}.${change.parameter} = $actual_value (expected: ${change.value})");
    BLOCK_QA();
  fi
done

# 4. Detect rollback
version_counter=$(echo $workflow | jq -r '.versionCounter')
if [ $version_counter -lt $previous_counter ]; then
  CRITICAL_ALERT("⚠️ Version rollback detected! User may have reverted changes in UI.");
  STOP_BUILD_CYCLE();
  NOTIFY_USER("Workflow was rolled back after our update. Previous: $previous_counter, Current: $version_counter");
fi

# 5. Check node count matches
if [ $(echo $workflow | jq '.nodes | length') != $expected_node_count ]; then
  WARN("Node count mismatch - possible data corruption");
fi
```

**If verification fails:**
1. BLOCK QA from running
2. Report failure details to user
3. Provide rollback option
4. Do NOT continue build cycle

**If rollback detected:**
1. STOP immediately
2. Alert user: "Workflow reverted in UI - conflicts with our changes"
3. Ask: Re-apply fix? OR Abort?

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

### Problem
Full 5-phase flow is overkill for simple bugs (~10K+ tokens).

### Solution: 3-Level Debug System

```
Level 1: QUICK_FIX (1 agent, ~500 tokens)
├── Trigger: /orch --fix workflow_id=X node="Y" error="Z"
├── Agent: Builder ONLY
├── Flow: Read workflow → Fix node → Validate → Done
└── Escalate if: fix fails 2 times → L2

Level 2: TARGETED_DEBUG (2 agents, ~2K tokens)
├── Trigger: /orch --debug workflow_id=X
├── Agents: Analyst → Builder
├── Analyst: Read executions, find root cause, check LEARNINGS.md
├── Builder: Apply fix
└── Escalate if: root cause unclear → L3

Level 3: FULL_INVESTIGATION (NEW 9-STEP ALGORITHM!)
├── Trigger: Complex issue, user reports "bot not working"
├── **PHASE 1: FULL DIAGNOSIS** (Researcher only!)
│   ├── Download workflow with smart mode selection (L-067: see .claude/agents/shared/L-067-smart-mode-selection.md):
│   │   ├── If node_count > 10 → mode="structure" (safe, ~2-5K tokens)
│   │   └── If node_count ≤ 10 → mode="full" (safe for small workflows)
│   ├── Decompose ALL nodes (types, params, code, credentials)
│   ├── Analyze executions with two-step approach (L-067):
│   │   ├── STEP 1: mode="summary" (all nodes, find WHERE)
│   │   └── STEP 2: mode="filtered" (problem nodes only, find WHY)
│   ├── Find WHERE it breaks (exact node + reason)
│   ├── Identify ROOT CAUSE (not symptom!)
│   └── Output: diagnosis_complete.json with hypothesis
├── Orchestrator presents findings to User
│   └── "Found: X breaks at node Y because Z. Approve fix?"
├── **PHASE 2: FIX + TEST**
│   ├── Builder: Create snapshot → Apply fix → Verify
│   ├── Architect → User: "Send test message to bot"
│   ├── User sends message
│   ├── QA: Phase 5 Real Testing (did bot respond?)
│   └── If bot responded → SUCCESS, else → back to PHASE 1
└── Used for: bot debugging, multi-failure workflows
```

### Auto-Detection: Which Level?

| User Input | Detected Level | Why |
|------------|----------------|-----|
| "fix X in node Y" | L1 QUICK_FIX | Specific node + action |
| "debug workflow" | L2 TARGETED | Need diagnosis first |
| "why doesn't it work" | L2 TARGETED | Root cause unknown |
| "redesign the flow" | L3 FULL | Architectural change |
| L1 failed 2x | L2 TARGETED | Auto-escalate |
| L2 unclear | L3 FULL | Auto-escalate |

### 🚨 MANDATORY Escalation Rules

**MUST use L3 FULL if ANY:**
1. ✅ 2nd+ fix attempt (previous fix didn't solve)
2. ✅ 3+ nodes modified
3. ✅ 3+ execution failures in row
4. ✅ Root cause unclear after diagnosis
5. ✅ Architectural/pattern issue

**FORBIDDEN:** Skip to L1/L2 when triggers met!

### Quick Fix Protocol (L1)

```bash
/orch --fix workflow_id=abc node="Supabase Insert" error="missing field"

# System:
# 1. Builder: Read workflow (n8n_get_workflow)
# 2. Builder: Identify node, read config
# 3. Builder: Apply fix (curl PUT)
# 4. Builder: Validate (n8n_validate_workflow)
# 5. Show result to user
# 6. If fail → escalate to L2
```

### Targeted Debug Protocol (L2)

```bash
/orch --debug workflow_id=abc

# System:
# 1. Analyst: Read recent executions (n8n_executions)
# 2. Analyst: Identify failing node + error pattern
# 3. Analyst: Check LEARNINGS.md for known solution
# 4. Present diagnosis:
#    "🔍 Проблема: Supabase Insert
#     Ошибка: missing field 'user_id'
#     Причина: Set node не передаёт это поле
#     Решение: Добавить user_id в Set node"
# 5. User approves → Builder applies fix
# 6. If unclear → escalate to L3
```

---

## Hard Caps (Resource Limits)

### Per-Task Limits

| Resource | Limit | Action on Exceed |
|----------|-------|------------------|
| Tokens | 50,000 | Stop + report |
| Agent calls | 25 | Stop + report |
| Time | 10 minutes | Stop + report |
| Cost | $0.50 | Stop + report |
| QA cycles | 7 | stage="blocked" |

### Tracking in run_state.usage

```javascript
// Check before EACH agent call:
function checkCaps() {
  const { usage } = run_state;
  const caps = {
    max_tokens: 50000,
    max_agent_calls: 25,
    max_time_seconds: 600,
    max_cost_usd: 0.50,
    max_qa_cycles: 7
  };

  if (usage.qa_cycles >= caps.max_qa_cycles) {
    return escalateToUser("QA failed 7 times. Need human help.");
  }
  if (usage.tokens_used >= caps.max_tokens) {
    return escalateToUser("Token limit reached. Task too complex?");
  }
  if (usage.cost_usd >= caps.max_cost_usd) {
    return escalateToUser("Cost limit reached.");
  }
  // ... other checks
}
```

### Escalation Dialog

```
⚠️ Hard Cap Reached

QA Cycles: 7/7 (LIMIT)
Tokens: 45K/50K
Time: 8min/10min

Проблема не решена за 7 попыток.

Варианты:
1. Показать все 7 попыток и ошибки (для анализа)
2. Откатить все изменения (Blue-Green rollback)
3. Увеличить лимит (+3 попытки) и продолжить
4. Эскалировать (manual intervention)

Выбор? (1/2/3/4)
```

---

## Handoff Contracts (Agent → Agent)

### Purpose
Validate data integrity between agent transitions.

### Contracts

| Transition | Required Fields | Validator |
|------------|-----------------|-----------|
| architect→researcher | requirements, research_request | services array not empty |
| researcher→architect | research_findings | templates or existing_workflows found |
| architect→builder | blueprint, credentials_selected | nodes_needed array not empty |
| researcher→builder | build_guidance | node_configs array not empty |
| builder→qa | workflow.id, workflow.node_count | id exists, count > 0 |
| qa→builder | qa_report, edit_scope | edit_scope array if failed |

### Validation Example

```javascript
const handoff_contracts = {
  "architect→researcher": {
    required: ["requirements", "research_request"],
    validate: (data) => {
      if (!data.requirements?.services?.length) {
        throw new Error("requirements.services required");
      }
      return true;
    }
  },
  "builder→qa": {
    required: ["workflow.id", "workflow.node_count"],
    validate: (data) => {
      if (!data.workflow?.id) {
        throw new Error("workflow.id required for QA");
      }
      return true;
    }
  }
};

// Before handoff:
function handoff(from, to, data) {
  const contract = handoff_contracts[`${from}→${to}`];
  try {
    contract.validate(data);
    log(`✅ Handoff ${from}→${to} valid`);
  } catch (error) {
    log(`❌ Handoff ${from}→${to} FAILED: ${error.message}`);
    throw new HandoffError(from, to, error);
  }
}
```

### Handoff Failure Recovery

```
❌ Handoff Failed: researcher→builder

Missing: build_guidance.node_configs

Recovery options:
1. Re-run Researcher with explicit request
2. Fill missing data manually
3. Skip to Builder with partial data (risky)

Выбор?
```

---

## Output

On completion, run_state contains:
- `workflow.id` - Created/updated workflow ID
- `qa_report.ready_for_deploy` - Whether ready for production
- `worklog` - Full execution history
- `finalized.status` - True when complete
