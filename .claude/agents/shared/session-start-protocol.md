# Session Start Protocol

> **Purpose:** Initialize /orch session with validation and safety checks
> **Usage:** Execute steps 0-5 at start of every /orch invocation
> **Safety:** Detects stale sessions, outdated snapshots, user frustration

---

## STEP 0: Load Gate Enforcement

```bash
# Source validation gate functions
source .claude/agents/shared/gate-enforcement.sh

# Source frustration detection
source .claude/agents/shared/frustration-detector.sh

echo "🔒 Gate enforcement loaded"
echo "🧠 Frustration detection loaded"
```

**Purpose:** Enable validation gates BEFORE any agent delegation (prevents disasters)

---

## STEP 0.5: Check User Frustration

**CRITICAL:** Detect frustration EARLY to prevent 6-hour disasters!

```bash
# Initialize session_start if new
if [ ! -f ${project_path}/memory/run_state_active.json ] || \
   [ "$(jq -r '.session_start // null' ${project_path}/memory/run_state_active.json)" = "null" ]; then

  session_start=$(date +%s)
  jq --arg ts "$session_start" '.session_start = ($ts | tonumber)' \
     ${project_path}/memory/run_state_active.json > /tmp/run_state_tmp.json && \
     mv /tmp/run_state_tmp.json ${project_path}/memory/run_state_active.json
fi

# Check frustration level
frustration_action=$(check_frustration "$user_request" ${project_path}/memory/run_state_active.json)

# Handle based on level
case "$frustration_action" in
  STOP_AND_ROLLBACK)
    echo "🚨 CRITICAL FRUSTRATION DETECTED"
    # Show signals + auto-rollback
    execute_auto_rollback ${project_path}/memory/run_state_active.json
    exit 0  # STOP - do not continue!
    ;;

  OFFER_ROLLBACK)
    echo "⚠️ HIGH FRUSTRATION DETECTED"
    # Ask user: [R]ollback / [C]ontinue / [S]top
    # WAIT for user input
    ;;

  CHECK_IN)
    echo "💡 MODERATE FRUSTRATION DETECTED"
    # Notify user, continue processing
    ;;

  CONTINUE)
    # Normal processing
    ;;
esac
```

**Reference:** `.claude/agents/shared/frustration-detector.sh`

---

## STEP 0.75: Project Path Detection

```bash
# Detect project_path from run_state or default
if [ -f ${project_path}/memory/run_state_active.json ]; then
  project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' \
                        ${project_path}/memory/run_state_active.json)
  workflow_id=$(jq -r '.workflow_id // null' \
                       ${project_path}/memory/run_state_active.json)
else
  # Default
  project_path="/Users/sergey/Projects/ClaudeN8N"
  workflow_id=null
fi

# Extract workflow_id from user_request if provided
if [[ "$user_request" =~ workflow_id=([a-zA-Z0-9_-]+) ]]; then
  workflow_id="${BASH_REMATCH[1]}"
fi

echo "📁 Project: $project_path"
echo "📋 Workflow: ${workflow_id:-none}"

# Export for all steps
export PROJECT_PATH="$project_path"
export WORKFLOW_ID="$workflow_id"
```

**Context Freshness Check:**

```bash
if [ -n "$workflow_id" ] && [ -f "${project_path}/.context/SYSTEM-CONTEXT.md" ]; then
  # Get real version from n8n
  real_workflow=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="minimal")
  workflow_version=$(echo "$real_workflow" | jq -r '.versionId // .versionCounter')

  # Get context version
  context_version=$(grep -m1 "Workflow Version:" "${project_path}/.context/SYSTEM-CONTEXT.md" | awk '{print $3}')

  if [ -n "$context_version" ] && [ "$workflow_version" != "$context_version" ]; then
    echo "⚠️ CONTEXT OUTDATED!"
    echo "   Workflow: v$workflow_version | Context: v$context_version"
    echo "   Recommendation: /orch snapshot refresh $workflow_id"
  fi
fi
```

---

## STEP 1: Load and Validate run_state

```bash
# Read existing run_state
if [ -f ${project_path}/memory/run_state_active.json ]; then
  old_stage=$(jq -r '.stage' ${project_path}/memory/run_state_active.json)
  old_request=$(jq -r '.user_request' ${project_path}/memory/run_state_active.json)
  old_workflow=$(jq -r '.workflow_id' ${project_path}/memory/run_state_active.json)

  # Check if stale session
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
    # Handle in main orch.md logic
  fi
fi
```

---

## STEP 2: Validate Canonical Snapshot (if workflow exists)

```bash
if [ -n "$workflow_id" ]; then
  canonical_file="${project_path}/memory/workflow_snapshots/${workflow_id}/canonical.json"

  if [ -f "$canonical_file" ]; then
    # Get versions
    canonical_version=$(jq -r '.snapshot_metadata.n8n_version_counter' "$canonical_file")

    # L-067: Use structure mode for large workflows
    node_count=$(jq -r '.node_inventory.total // 0' "$canonical_file")
    mode=$( [ "$node_count" -gt 10 ] && echo "structure" || echo "full" )

    real_workflow=$(mcp__n8n-mcp__n8n_get_workflow id="$workflow_id" mode="$mode")
    real_version=$(echo "$real_workflow" | jq -r '.versionId // .versionCounter')

    # Compare
    if [ "$canonical_version" != "$real_version" ]; then
      echo "⚠️ CANONICAL SNAPSHOT OUTDATED!"
      echo "   Snapshot: v$canonical_version | n8n: v$real_version"
      echo ""
      echo "Options:"
      echo "  [R]efresh - Download fresh snapshot from n8n"
      echo "  [K]eep - Use old snapshot (RISKY!)"
      echo "  [A]bort - Cancel and review manually"

      # WAIT FOR USER INPUT!
    else
      echo "✅ Canonical snapshot fresh (v$canonical_version)"
    fi
  fi
fi
```

---

## STEP 3: Handle Stale Data

### Archive Stale Session

```bash
function archive_stale_session() {
  timestamp=$(date +%Y%m%d_%H%M%S)
  mkdir -p ${project_path}/memory/run_state_archives

  # Archive old run_state
  mv ${project_path}/memory/run_state_active.json \
     "${project_path}/memory/run_state_archives/run_state_${timestamp}.json"

  # Create fresh
  source .claude/agents/shared/run-state-lib.sh
  init_run_state "$user_request" "$workflow_id" "$project_id" "$project_path"

  echo "📦 Archived stale session"
}
```

### Refresh Canonical Snapshot

```bash
function refresh_canonical_snapshot() {
  workflow_id="$1"
  snapshot_dir="${project_path}/memory/workflow_snapshots/${workflow_id}"

  # Archive old to history
  if [ -f "${snapshot_dir}/canonical.json" ]; then
    old_version=$(jq -r '.snapshot_metadata.snapshot_version' "${snapshot_dir}/canonical.json")
    mkdir -p "${snapshot_dir}/history"
    mv "${snapshot_dir}/canonical.json" \
       "${snapshot_dir}/history/v${old_version}_$(date +%Y%m%d).json"
  fi

  # Delegate to Researcher to create new snapshot
  # (Orchestrator does NOT call MCP directly!)
  Task({
    subagent_type: "general-purpose",
    prompt: `## ROLE: Researcher Agent

Read: .claude/agents/researcher.md

## TASK: Create Fresh Canonical Snapshot

Workflow ID: $workflow_id
Output: ${snapshot_dir}/canonical.json

Use n8n_get_workflow + create detailed snapshot per canonical snapshot protocol.`
  })

  echo "🔄 Canonical snapshot refreshed"
}
```

---

## STEP 4: Initialize New Session

```bash
# Source run-state lib
source .claude/agents/shared/run-state-lib.sh

# Initialize with project context
init_run_state "$user_request" "$workflow_id" "$project_id" "$project_path"

# Or if continuing, just update request
jq --arg req "$user_request" \
   '.user_request = $req' \
   ${project_path}/memory/run_state_active.json > /tmp/run_state_tmp.json && \
   mv /tmp/run_state_tmp.json ${project_path}/memory/run_state_active.json
```

---

## STEP 5: Start Architect (with Gate Check!)

```bash
# CHECK VALIDATION GATES FIRST!
source .claude/agents/shared/gate-enforcement.sh
check_all_gates "architect" "${project_path}/memory/run_state_active.json"

if [ $? -ne 0 ]; then
  echo "❌ Gate violation - cannot proceed"
  exit 1
fi

# Gates passed - delegate
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Architect Agent

Read: .claude/agents/architect.md

## CONTEXT
Read: ${project_path}/memory/run_state_active.json

## TASK: Clarify Requirements

User request: "${user_request}"

Clarify with user, write requirements to run_state.`
})
```

---

## 📋 VALIDATION DECISION MATRIX

| run_state | canonical | User Request | Action |
|-----------|-----------|--------------|--------|
| Empty | - | Any | Create new |
| complete | Fresh | Any | Create new |
| incomplete | - | Same | Continue |
| incomplete | - | Different | **ASK USER** |
| - | Outdated | Any | **ASK USER** |
| - | Missing | workflow_id exists | Create snapshot |

---

## 🔗 RELATED PROTOCOLS

- **run_state library:** `.claude/agents/shared/run-state-lib.sh`
- **Gate enforcement:** `.claude/agents/shared/gate-enforcement.sh`
- **Frustration detection:** `.claude/agents/shared/frustration-detector.sh`
- **Agent delegation:** `.claude/agents/shared/delegation-templates.md`
- **Canonical snapshots:** `.claude/agents/shared/snapshot-protocol.md`

---

## ⚠️ CRITICAL NOTES

1. **ALWAYS check gates before agent delegation** (prevents disasters)
2. **ALWAYS check frustration early** (prevents 6-hour loops)
3. **ALWAYS validate canonical snapshot** (prevents stale data bugs)
4. **ASK USER for conflicts** (stale session, outdated snapshot)
5. **Orchestrator does NOT call MCP** (delegates to agents!)

---

**After Step 5 completes:** Orchestrator enters main delegation loop (see orch.md)
