#!/bin/bash
# Validation Gate Enforcement Functions
# Version: 1.2.1 (2025-12-30) - Added GATE 6 (builder_gotchas.md mandatory read)
# Purpose: Code-based enforcement of validation gates (prevents FAILURE-ANALYSIS disasters)
# Usage: source .claude/agents/shared/gate-enforcement.sh

###############################################################################
# GATE 0: Research Phase Required
# Rule: Before first Builder call in session, Research must complete
###############################################################################
function check_gate_0() {
  local target_agent="$1"
  local run_state="$2"

  local cycle_count=$(jq -r '.cycle_count // 0' "$run_state")

  # Only check on first Builder call
  if [ "$target_agent" = "builder" ] && [ "$cycle_count" -eq 0 ]; then
    local research_findings=$(jq -r '.research_findings // null' "$run_state")

    if [ "$research_findings" = "null" ]; then
      echo "🚨 GATE 0 VIOLATION: Research required before first Builder call" >&2
      echo "" >&2
      echo "Before calling Builder, delegate to Researcher first" >&2
      return 1
    fi
  fi

  return 0
}

###############################################################################
# GATE 1: Progressive Escalation
# Rule: Cycles 4-5 require Researcher, Cycles 6-7 require Analyst
###############################################################################
function check_gate_1() {
  local target_agent="$1"
  local run_state="$2"

  local cycle_count=$(jq -r '.cycle_count // 0' "$run_state")
  local stage=$(jq -r '.stage // "unknown"' "$run_state")

  # Only check in build/validate stages
  if [ "$stage" != "build" ] && [ "$stage" != "validate" ]; then
    return 0
  fi

  # Cycle 4-5: MUST call Researcher FIRST
  if [ "$cycle_count" -ge 4 ] && [ "$cycle_count" -le 5 ]; then
    if [ "$target_agent" = "builder" ]; then
      local researcher_called=$(jq -r "[.agent_log[] | select(.agent==\"researcher\" and .cycle==$cycle_count)] | length" "$run_state")

      if [ "$researcher_called" = "0" ]; then
        echo "🚨 GATE 1 VIOLATION: Cycle $cycle_count requires Researcher FIRST!" >&2
        echo "" >&2
        echo "Builder cannot be called directly in cycles 4-5." >&2
        echo "Required: Delegate to Researcher for alternative approach." >&2
        echo "" >&2
        echo "Reference: PROGRESSIVE-ESCALATION.md (cycles 4-5)" >&2
        return 1
      fi
    fi
  fi

  # Cycle 6-7: MUST call Analyst FIRST
  if [ "$cycle_count" -ge 6 ] && [ "$cycle_count" -le 7 ]; then
    if [ "$target_agent" = "builder" ] || [ "$target_agent" = "researcher" ]; then
      local analyst_called=$(jq -r "[.agent_log[] | select(.agent==\"analyst\" and .cycle==$cycle_count)] | length" "$run_state")

      if [ "$analyst_called" = "0" ]; then
        echo "🚨 GATE 1 VIOLATION: Cycle $cycle_count requires Analyst FIRST!" >&2
        echo "" >&2
        echo "$target_agent cannot be called directly in cycles 6-7." >&2
        echo "Required: Delegate to Analyst for root cause diagnosis (L4 escalation)." >&2
        echo "" >&2
        echo "Reference: PROGRESSIVE-ESCALATION.md (cycles 6-7)" >&2
        return 1
      fi
    fi
  fi

  # Cycle 8+: BLOCKED
  if [ "$cycle_count" -ge 8 ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle $cycle_count blocked!" >&2
    echo "" >&2
    echo "Hard cap reached: 7 cycles maximum." >&2
    echo "Setting stage = blocked, requesting user intervention..." >&2
    echo "" >&2
    jq '.stage = "blocked" | .block_reason = "7 QA cycles exhausted"' "$run_state" > "$run_state.tmp" && mv "$run_state.tmp" "$run_state"
    return 1
  fi

  return 0
}

###############################################################################
# GATE 2: Execution Analysis Required (v2.0 - 2025-12-28)
# Rule: Cannot fix EXECUTION errors without analyzing execution logs
# UPDATE: Now distinguishes validation vs execution errors (fixes false positive)
###############################################################################
function check_gate_2() {
  local target_agent="$1"
  local run_state="$2"

  local stage=$(jq -r '.stage // "unknown"' "$run_state")
  local cycle_count=$(jq -r '.cycle_count // 0' "$run_state")
  local workflow_id=$(jq -r '.workflow_id // ""' "$run_state")
  local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")

  # Check if this is a fix/debug task
  local is_fix_task=false
  if [ "$stage" = "build" ] && [ "$cycle_count" -gt 0 ]; then
    is_fix_task=true
  fi

  # If fixing broken workflow, check error category FIRST
  if [ "$is_fix_task" = true ] && [ "$target_agent" = "builder" ]; then
    # Try to get error category from QA report
    local qa_report_file="${project_path}/memory/agent_results/${workflow_id}/qa_report.json"

    if [ -f "$qa_report_file" ]; then
      # Check first error's category
      local error_category=$(jq -r '.errors[0].category // "unknown"' "$qa_report_file")

      # VALIDATION errors don't need execution analysis (L1 direct fix OK)
      if [[ "$error_category" =~ ^(parameter_validation|expression_syntax|ai_agent_functionality|node_configuration)$ ]]; then
        # GATE 2 bypass: Validation errors can be fixed directly by Builder
        return 0
      fi

      # EXECUTION errors require analysis (L2+ escalation)
      if [[ "$error_category" =~ ^(execution_runtime|execution_timeout|execution_error|data_flow)$ ]]; then
        local analysis_completed=$(jq -r '.execution_analysis.completed // false' "$run_state")

        if [ "$analysis_completed" != "true" ]; then
          echo "🚨 GATE 2 VIOLATION: Execution errors require execution analysis" >&2
          echo "" >&2
          echo "Error category: $error_category" >&2
          echo "CRITICAL: You MUST analyze execution logs before attempting fix!" >&2
          echo "" >&2
          echo "Delegate to Researcher/Analyst FIRST to analyze executions" >&2
          echo "" >&2
          echo "Reference: FAILURE-ANALYSIS-2025-12-10.md (GATE 2 violation caused 6-hour disaster)" >&2
          return 1
        fi
      fi
    fi

    # Fallback: If no QA report found, require analysis (safer default)
    local analysis_completed=$(jq -r '.execution_analysis.completed // false' "$run_state")

    if [ "$analysis_completed" != "true" ]; then
      echo "🚨 GATE 2 VIOLATION: Cannot fix without execution analysis" >&2
      echo "" >&2
      echo "No QA report found - defaulting to require analysis" >&2
      echo "CRITICAL: You MUST analyze execution logs before attempting fix!" >&2
      echo "" >&2
      echo "Delegate to Analyst FIRST to analyze executions" >&2
      echo "" >&2
      echo "Reference: FAILURE-ANALYSIS-2025-12-10.md (GATE 2 violation caused 6-hour disaster)" >&2
      return 1
    fi
  fi

  return 0
}

###############################################################################
# GATE 3: Phase 5 Real Testing
# Rule: QA cannot report PASS without execution test
###############################################################################
function check_gate_3() {
  local target_agent="$1"
  local run_state="$2"

  # Only check when QA returns result
  if [ "$target_agent" = "qa" ]; then
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")
    local qa_report_file="${project_path}/.n8n/agent_results/qa_report.json"

    # Check legacy location too
    if [ ! -f "$qa_report_file" ]; then
      qa_report_file="memory/agent_results/${workflow_id}/qa_report.json"
    fi

    if [ -f "$qa_report_file" ]; then
      local qa_status=$(jq -r '.status // "unknown"' "$qa_report_file")
      local phase_5=$(jq -r '.phase_5_executed // false' "$qa_report_file")

      if [ "$qa_status" = "PASS" ] && [ "$phase_5" != "true" ]; then
        echo "🚨 GATE 3 VIOLATION: Cannot report PASS without Phase 5 execution test" >&2
        echo "" >&2
        echo "QA MUST test real execution, not just config validation!" >&2
        echo "" >&2
        echo "Reference: FAILURE-ANALYSIS-2025-12-10.md (QA missed 'Log Message' error)" >&2
        return 1
      fi
    fi
  fi

  return 0
}

###############################################################################
# GATE 4: Knowledge Base Check
# Rule: Researcher must check LEARNINGS before web search
###############################################################################
function check_gate_4() {
  local target_agent="$1"
  local run_state="$2"

  # Check if Researcher is about to do web search
  if [ "$target_agent" = "researcher" ]; then
    local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local research_findings_file="${project_path}/.n8n/agent_results/research_findings.json"

    # Check legacy location too
    if [ ! -f "$research_findings_file" ]; then
      research_findings_file="memory/agent_results/${workflow_id}/research_findings.json"
    fi

    if [ -f "$research_findings_file" ]; then
      local learnings_checked=$(jq -r '.learnings_checked // false' "$research_findings_file")
      local web_search_planned=$(jq -r '.web_search_planned // false' "$research_findings_file")

      if [ "$web_search_planned" = "true" ] && [ "$learnings_checked" != "true" ]; then
        echo "🚨 GATE 4 VIOLATION: Check LEARNINGS-INDEX.md before web search" >&2
        echo "" >&2
        echo "Local knowledge > Web search (faster + proven solutions)" >&2
        return 1
      fi
    fi
  fi

  return 0
}

###############################################################################
# GATE 5: MCP Verification
# Rule: Builder must log actual MCP responses (anti-hallucination)
###############################################################################
function check_gate_5() {
  local target_agent="$1"
  local run_state="$2"

  # Check when Builder returns result
  if [ "$target_agent" = "builder" ]; then
    local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local build_result_file="${project_path}/.n8n/agent_results/build_result.json"

    # Check legacy location too
    if [ ! -f "$build_result_file" ]; then
      build_result_file="memory/agent_results/${workflow_id}/build_result.json"
    fi

    if [ -f "$build_result_file" ]; then
      local build_status=$(jq -r '.status // "unknown"' "$build_result_file")
      local mcp_calls=$(jq -r '.mcp_calls // []' "$build_result_file")
      local mcp_count=$(jq -r '.mcp_calls | length' "$build_result_file")

      if [ "$build_status" = "success" ] && [ "$mcp_count" -eq 0 ]; then
        echo "🚨 GATE 5 VIOLATION: Builder must log mcp_calls array" >&2
        echo "" >&2
        echo "Anti-hallucination measure: Builder MUST log actual MCP tool responses" >&2
        echo "" >&2
        echo "Reference: L-075 (Anti-hallucination protocol)" >&2
        return 1
      fi
    fi
  fi

  return 0
}

###############################################################################
# GATE 6: Hypothesis Validation
# Rule: Researcher must validate hypothesis via MCP
###############################################################################
function check_gate_6() {
  local target_agent="$1"
  local run_state="$2"

  # Check when Researcher returns findings
  if [ "$target_agent" = "researcher" ]; then
    local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local research_findings_file="${project_path}/.n8n/agent_results/research_findings.json"

    # Check legacy location too
    if [ ! -f "$research_findings_file" ]; then
      research_findings_file="memory/agent_results/${workflow_id}/research_findings.json"
    fi

    if [ -f "$research_findings_file" ]; then
      local findings_status=$(jq -r '.status // "unknown"' "$research_findings_file")
      local hypothesis_validated=$(jq -r '.hypothesis_validated // false' "$research_findings_file")

      if [ "$findings_status" = "complete" ] && [ "$hypothesis_validated" != "true" ]; then
        echo "🚨 GATE 6 VIOLATION: Hypothesis not validated" >&2
        echo "" >&2
        echo "Researcher MUST validate solution via MCP before proposing" >&2
        echo "" >&2
        echo "Never propose untested solutions!" >&2
        return 1
      fi
    fi
  fi

  return 0
}

###############################################################################
# GATE 6: builder_gotchas.md Mandatory Read (L-106)
# Rule: Builder must read builder_gotchas.md before Code node work
###############################################################################
function check_gate_6() {
  local target_agent="$1"
  local run_state="$2"

  # Only check when Builder is being called
  if [ "$target_agent" != "builder" ]; then
    return 0
  fi

  # Check if workflow has Code nodes in edit_scope
  local has_code_nodes=$(jq -r '.edit_scope[]? | select(.issue | contains("Code node") or .node_name | contains("Code")) | .node_id' "$run_state" 2>/dev/null)

  if [ -n "$has_code_nodes" ]; then
    # Verify Builder read builder_gotchas.md
    local gotchas_read=$(jq -r '[.agent_log[] | select(.agent=="builder" and (.details | contains("builder_gotchas") or .details | contains("FULL CODE NODE INSPECTION")))] | length' "$run_state" 2>/dev/null)

    if [ "$gotchas_read" = "0" ] || [ -z "$gotchas_read" ]; then
      echo "🚨 GATE 6 VIOLATION: Builder must read builder_gotchas.md before Code node edits!" >&2
      echo "" >&2
      echo "Required:" >&2
      echo "  1. Read: docs/learning/indexes/builder_gotchas.md" >&2
      echo "  2. Check L-060 section (deprecated syntax warning)" >&2
      echo "  3. Follow FULL CODE NODE INSPECTION protocol" >&2
      echo "" >&2
      echo "Reference: L-106 (builder_gotchas.md prevents 3-hour debug sessions)" >&2
      return 1
    fi
  fi

  return 0
}

###############################################################################
# GATE 6.5: LangChain Functional Completeness (L-097, L-098, L-100)
# Rule: QA must check functional completeness of LangChain nodes before syntax
###############################################################################
function check_gate_6_5() {
  local target_agent="$1"
  local run_state="$2"

  # Only check for QA in validate stage
  local stage=$(jq -r '.stage // "unknown"' "$run_state")
  if [ "$stage" != "validate" ] || [ "$target_agent" != "qa" ]; then
    return 0
  fi

  # Check if workflow has LangChain nodes
  local workflow_json=$(jq -r '.workflow // {}' "$run_state" 2>/dev/null)

  # Check for AI Agent nodes
  local has_ai_agent=$(echo "$workflow_json" | jq -r '[.nodes[]? | select(.type | contains("langchain.agent"))] | length')

  if [ "$has_ai_agent" -gt 0 ]; then
    # Check build_guidance has langchain_requirements
    local langchain_reqs=$(jq -r '.build_guidance.langchain_requirements // null' "$run_state")

    if [ "$langchain_reqs" = "null" ]; then
      echo "🚨 GATE 6.5 VIOLATION: LangChain nodes present but no requirements documented" >&2
      echo "" >&2
      echo "Researcher must document LangChain node requirements:" >&2
      echo "- AI Agent: promptType, text, systemMessage, ai_tool connections" >&2
      echo "" >&2
      echo "Reference: L-097 (AI Agent requires promptType + text + ai_tool)" >&2
      return 1
    fi
  fi

  return 0
}

###############################################################################
# Main Enforcement Function
# Checks all gates in order
###############################################################################
function check_all_gates() {
  local target_agent="$1"
  local run_state="$2"

  echo "🔒 Checking validation gates for: $target_agent" >&2

  # Check all gates in order
  check_gate_0 "$target_agent" "$run_state" || return 1
  check_gate_1 "$target_agent" "$run_state" || return 1
  check_gate_2 "$target_agent" "$run_state" || return 1
  check_gate_3 "$target_agent" "$run_state" || return 1
  check_gate_4 "$target_agent" "$run_state" || return 1
  check_gate_5 "$target_agent" "$run_state" || return 1
  check_gate_6 "$target_agent" "$run_state" || return 1
  check_gate_6_5 "$target_agent" "$run_state" || return 1

  echo "✅ All validation gates passed" >&2
  return 0
}

# End of gate-enforcement.sh
