#!/bin/bash
# run-state Library - jq functions for Orchestrator
# Version: 1.0.0 (2025-12-16)
# Purpose: Centralized run_state.json manipulation (extracted from orch.md)
# Usage: source .claude/agents/shared/run-state-lib.sh

###############################################################################
# INITIALIZATION
###############################################################################

function init_run_state() {
  local user_request="$1"
  local workflow_id="$2"
  local project_id="$3"
  local project_path="$4"
  local run_state_file="${project_path}/memory/run_state_active.json"

  jq -n \
    --arg id "run_$(date +%Y%m%d_%H%M%S)" \
    --arg req "$user_request" \
    --arg wf "$workflow_id" \
    --arg proj "$project_id" \
    --arg path "$project_path" \
    '{
      id: $id,
      user_request: $req,
      workflow_id: $wf,
      project_id: $proj,
      project_path: $path,
      stage: "clarification",
      cycle_count: 0,
      agent_log: [],
      worklog: [],
      session_start: now,
      usage: {
        tokens_used: 0,
        agent_calls: 0,
        qa_cycles: 0,
        cost_usd: 0
      }
    }' > "$run_state_file"

  echo "✅ run_state initialized: $run_state_file"
}

###############################################################################
# STAGE TRANSITIONS
###############################################################################

function advance_stage() {
  local new_stage="$1"
  local run_state_file="$2"

  jq --arg stage "$new_stage" \
    '.stage = $stage' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  echo "✅ Stage: $new_stage"
}

function increment_cycle() {
  local run_state_file="$1"

  jq '.cycle_count += 1' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  local cycle=$(jq -r '.cycle_count' "$run_state_file")
  echo "✅ Cycle: $cycle"
}

function set_blocked() {
  local reason="$1"
  local run_state_file="$2"

  jq --arg reason "$reason" \
    '.stage = "blocked" | .block_reason = $reason' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  echo "🚨 BLOCKED: $reason"
}

function set_complete() {
  local run_state_file="$1"

  jq '.stage = "complete"' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  echo "✅ COMPLETE"
}

###############################################################################
# AGENT RESULT MERGING
###############################################################################

function merge_agent_result() {
  local agent="$1"
  local result_file="$2"
  local run_state_file="$3"

  # Read agent result
  local result=$(cat "$result_file")

  # Merge based on agent type
  case "$agent" in
    architect)
      jq --argjson result "$result" \
        '.requirements = ($result.requirements // .requirements) |
         .research_request = ($result.research_request // .research_request) |
         .decision = ($result.decision // .decision) |
         .blueprint = ($result.blueprint // .blueprint)' \
        "$run_state_file" > /tmp/run_state_tmp.json
      ;;

    researcher)
      jq --argjson result "$result" \
        '.research_findings = ($result.research_findings // .research_findings) |
         .build_guidance = ($result.build_guidance // .build_guidance) |
         .credentials_discovered = ($result.credentials_discovered // .credentials_discovered)' \
        "$run_state_file" > /tmp/run_state_tmp.json
      ;;

    builder)
      jq --argjson result "$result" \
        '.workflow = ($result.workflow // .workflow) |
         .build_result = ($result.build_result // .build_result)' \
        "$run_state_file" > /tmp/run_state_tmp.json
      ;;

    qa)
      jq --argjson result "$result" \
        '.qa_report = ($result.qa_report // .qa_report) |
         .edit_scope = ($result.edit_scope // .edit_scope)' \
        "$run_state_file" > /tmp/run_state_tmp.json
      ;;

    analyst)
      jq --argjson result "$result" \
        '.analysis = ($result.analysis // .analysis) |
         .execution_analysis = ($result.execution_analysis // .execution_analysis)' \
        "$run_state_file" > /tmp/run_state_tmp.json
      ;;
  esac

  mv /tmp/run_state_tmp.json "$run_state_file"
  echo "✅ Merged $agent result"
}

###############################################################################
# LOGGING
###############################################################################

function append_agent_log() {
  local agent="$1"
  local action="$2"
  local details="$3"
  local run_state_file="$4"

  jq --arg agent "$agent" \
     --arg action "$action" \
     --arg details "$details" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.agent_log += [{
      ts: $ts,
      agent: $agent,
      action: $action,
      details: $details
    }]' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"
}

function append_worklog() {
  local cycle="$1"
  local agent="$2"
  local action="$3"
  local outcome="$4"
  local run_state_file="$5"

  jq --arg cycle "$cycle" \
     --arg agent "$agent" \
     --arg action "$action" \
     --arg outcome "$outcome" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.worklog += [{
      ts: $ts,
      cycle: ($cycle | tonumber),
      agent: $agent,
      action: $action,
      outcome: $outcome
    }]' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"
}

###############################################################################
# COMPACTION (for active run state)
###############################################################################

function compact_run_state() {
  local run_state_file="$1"
  local max_log_entries="${2:-10}"

  jq --arg max "$max_log_entries" \
    '.agent_log = (.agent_log | if length > ($max | tonumber) then .[-($max | tonumber):] else . end)' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  echo "✅ Compacted run_state (last $max_log_entries entries)"
}

###############################################################################
# ARCHIVING
###############################################################################

function archive_run_state() {
  local run_state_file="$1"
  local project_path="$2"
  local workflow_id=$(jq -r '.workflow_id' "$run_state_file")

  local archive_dir="${project_path}/memory/run_state_archives"
  mkdir -p "$archive_dir"

  local archive_file="${archive_dir}/${workflow_id}_complete_$(date +%Y%m%d_%H%M%S).json"
  cp "$run_state_file" "$archive_file"

  echo "✅ Archived: $archive_file"
}

###############################################################################
# SNAPSHOT TO HISTORY
###############################################################################

function snapshot_to_history() {
  local run_state_file="$1"
  local project_path="$2"
  local stage=$(jq -r '.stage' "$run_state_file")
  local workflow_id=$(jq -r '.workflow_id' "$run_state_file")

  local history_dir="${project_path}/memory/run_state_history/${workflow_id}"
  mkdir -p "$history_dir"

  local counter=$(ls -1 "$history_dir" 2>/dev/null | wc -l)
  counter=$((counter + 1))

  local snapshot_file=$(printf "%s/%03d_%s.json" "$history_dir" "$counter" "$stage")
  cp "$run_state_file" "$snapshot_file"

  echo "✅ History snapshot: $snapshot_file"
}

###############################################################################
# PROJECT CONTEXT
###############################################################################

function update_project_context() {
  local project_id="$1"
  local project_path="$2"
  local workflow_id="$3"
  local run_state_file="$4"

  jq --arg proj "$project_id" \
     --arg path "$project_path" \
     --arg wf "$workflow_id" \
    '.project_id = $proj |
     .project_path = $path |
     .workflow_id = $wf' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"

  echo "✅ Project context updated: $project_id"
}

###############################################################################
# VALIDATION HELPERS
###############################################################################

function check_mcp_calls() {
  local agent="$1"
  local result_file="$2"

  local mcp_calls=$(jq -r '.mcp_calls // []' "$result_file")

  if [ "$mcp_calls" = "[]" ] || [ "$mcp_calls" = "null" ]; then
    echo "❌ L-073 FRAUD: No MCP calls in $agent result!"
    return 1
  fi

  echo "✅ MCP calls verified for $agent"
  return 0
}

function get_cycle_count() {
  local run_state_file="$1"
  jq -r '.cycle_count // 0' "$run_state_file"
}

function get_stage() {
  local run_state_file="$1"
  jq -r '.stage' "$run_state_file"
}

function get_workflow_id() {
  local run_state_file="$1"
  jq -r '.workflow_id' "$run_state_file"
}

function get_project_path() {
  local run_state_file="$1"
  jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state_file"
}

###############################################################################
# USAGE TRACKING
###############################################################################

function increment_agent_calls() {
  local run_state_file="$1"

  jq '.usage.agent_calls += 1' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"
}

function increment_qa_cycles() {
  local run_state_file="$1"

  jq '.usage.qa_cycles += 1' \
    "$run_state_file" > /tmp/run_state_tmp.json && \
    mv /tmp/run_state_tmp.json "$run_state_file"
}

###############################################################################
# EXPORT
###############################################################################

echo "✅ run-state-lib.sh loaded (v1.0.0)"
echo "Functions available:"
echo "  - init_run_state"
echo "  - advance_stage"
echo "  - increment_cycle"
echo "  - set_blocked / set_complete"
echo "  - merge_agent_result"
echo "  - append_agent_log / append_worklog"
echo "  - compact_run_state"
echo "  - archive_run_state"
echo "  - snapshot_to_history"
echo "  - check_mcp_calls"
echo "  - get_* (cycle_count, stage, workflow_id, project_path)"
