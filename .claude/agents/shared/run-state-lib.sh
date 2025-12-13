#!/bin/bash
# Run State Helper Functions
# Version: 1.0.0 (2025-12-11)
# Purpose: Token-efficient jq operations for run_state.json
# Usage: source .claude/agents/shared/run-state-lib.sh

###############################################################################
# Core Functions
###############################################################################

# Get run_state path (handles legacy + new locations)
get_run_state_path() {
  local project_path="${1:-/Users/sergey/Projects/ClaudeN8N}"
  local workflow_id="${2:-}"

  # Primary: new location
  if [ -f "${project_path}/.n8n/run_state.json" ]; then
    echo "${project_path}/.n8n/run_state.json"
  # Fallback: legacy location
  elif [ -f "memory/run_state_active.json" ]; then
    echo "memory/run_state_active.json"
  # Workflow-specific
  elif [ -n "$workflow_id" ] && [ -f "memory/agent_results/${workflow_id}/run_state.json" ]; then
    echo "memory/agent_results/${workflow_id}/run_state.json"
  else
    # Default to new location (create if doesn't exist)
    echo "${project_path}/.n8n/run_state.json"
  fi
}

# Update stage
update_stage() {
  local stage="$1"
  local rs_path="${2:-$(get_run_state_path)}"
  jq --arg s "$stage" '.stage = $s' "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

# Increment cycle count
increment_cycle() {
  local rs_path="${1:-$(get_run_state_path)}"
  jq '.cycle_count += 1' "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

# Set cycle to specific value
set_cycle() {
  local cycle="$1"
  local rs_path="${2:-$(get_run_state_path)}"
  jq --argjson c "$cycle" '.cycle_count = $c' "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

# Append to agent_log (token-efficient)
append_agent_log() {
  local agent="$1"
  local action="$2"
  local details="$3"
  local rs_path="${4:-$(get_run_state_path)}"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq --arg ts "$ts" --arg agent "$agent" --arg action "$action" --arg details "$details" \
    '.agent_log += [{"ts": $ts, "agent": $agent, "action": $action, "details": $details}]' \
    "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

# Update field (generic)
update_field() {
  local field_path="$1"
  local value="$2"
  local rs_path="${3:-$(get_run_state_path)}"

  jq --argjson val "$value" "$field_path = \$val" "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

# Merge agent result (shallow merge objects, append arrays)
merge_agent_result() {
  local result_json="$1"
  local rs_path="${2:-$(get_run_state_path)}"

  jq --argjson result "$result_json" '
    .requirements = $result.requirements // .requirements |
    .research_findings = $result.research_findings // .research_findings |
    .decision = $result.decision // .decision |
    .blueprint = $result.blueprint // .blueprint |
    .build_guidance = $result.build_guidance // .build_guidance |
    .workflow = $result.workflow // .workflow |
    .qa_report = $result.qa_report // .qa_report |
    .edit_scope = $result.edit_scope // .edit_scope
  ' "$rs_path" > /tmp/rs_$$.json && mv /tmp/rs_$$.json "$rs_path"
}

###############################################################################
# Safety Helpers
###############################################################################

# Initialize run_state (if doesn't exist)
init_run_state() {
  local project_path="${1:-/Users/sergey/Projects/ClaudeN8N}"
  local workflow_id="${2:-}"
  local rs_path="$(get_run_state_path "$project_path" "$workflow_id")"

  if [ ! -f "$rs_path" ]; then
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local session_start=$(date +%s)

    jq -n --arg ts "$ts" --argjson ss "$session_start" '{
      id: ("run_" + $ts),
      stage: "clarification",
      cycle_count: 0,
      session_start: $ss,
      agent_log: [],
      worklog: [],
      usage: {tokens_used: 0, agent_calls: 0, qa_cycles: 0, cost_usd: 0},
      frustration_signals: {profanity: 0, complaints: 0, repeated_requests: 0, session_duration: 0}
    }' > "$rs_path"
  fi
}

# Backup run_state before destructive operation
backup_run_state() {
  local rs_path="${1:-$(get_run_state_path)}"
  local backup_dir="$(dirname "$rs_path")/backups"
  local ts=$(date +%Y%m%d_%H%M%S)

  mkdir -p "$backup_dir"
  cp "$rs_path" "$backup_dir/run_state_${ts}.json"
  echo "$backup_dir/run_state_${ts}.json"
}
