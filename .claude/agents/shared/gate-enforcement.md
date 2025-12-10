# Validation Gate Enforcement

**Purpose:** Code-based enforcement of validation gates (not advisory)
**Usage:** Source this file in orchestrator before agent delegation
**Version:** 1.0.0 (2025-12-10)

---

## Usage

```bash
# In orchestrator:
source .claude/agents/shared/gate-enforcement.md

# Check gates before delegation
check_all_gates "$target_agent" "$context_file"

if [ $? -ne 0 ]; then
  # Gate violation - agent call BLOCKED
  exit 1
fi

# Gates passed - proceed with delegation
Task({ ... })
```

---

## Gate Functions

### GATE 0: Research Phase Required

**Rule:** Before first Builder call in session, Research must complete

```bash
function check_gate_0() {
  local target_agent="$1"
  local run_state="$2"

  local cycle_count=$(jq -r '.cycle_count // 0' "$run_state")

  # Only check on first Builder call
  if [ "$target_agent" = "builder" ] && [ "$cycle_count" -eq 0 ]; then
    local research_findings=$(jq -r '.research_findings // null' "$run_state")

    if [ "$research_findings" = "null" ]; then
      echo "🚨 GATE 0 VIOLATION: Research required before first Builder call"
      echo ""
      echo "Before calling Builder, delegate to Researcher:"
      echo ""
      echo "Task({"
      echo "  subagent_type: \"general-purpose\","
      echo "  prompt: \"## ROLE: Researcher Agent"
      echo ""
      echo "  Read: .claude/agents/researcher.md"
      echo ""
      echo "  ## TASK: Research solutions"
      echo "  User request: [describe task]"
      echo "  Find existing workflows, nodes, patterns.\""
      echo "})"
      return 1
    fi
  fi

  return 0
}
```

### GATE 2: Execution Analysis Required

**Rule:** Cannot fix workflow without analyzing execution logs

```bash
function check_gate_2() {
  local target_agent="$1"
  local run_state="$2"

  local stage=$(jq -r '.stage // "unknown"' "$run_state")
  local cycle_count=$(jq -r '.cycle_count // 0' "$run_state")

  # Check if this is a fix/debug task
  local is_fix_task=false

  if [ "$stage" = "build" ] && [ "$cycle_count" -gt 0 ]; then
    is_fix_task=true
  fi

  # If fixing broken workflow, execution analysis REQUIRED
  if [ "$is_fix_task" = true ] && [ "$target_agent" = "builder" ]; then
    local analysis_completed=$(jq -r '.execution_analysis.completed // false' "$run_state")

    if [ "$analysis_completed" != "true" ]; then
      echo "🚨 GATE 2 VIOLATION: Cannot fix without execution analysis"
      echo ""
      echo "CRITICAL: You MUST analyze execution logs before attempting fix!"
      echo ""
      echo "Delegate to Analyst FIRST:"
      echo ""
      echo "Task({"
      echo "  subagent_type: \"general-purpose\","
      echo "  prompt: \"## ROLE: Analyst Agent"
      echo ""
      echo "  Read: .claude/agents/analyst.md"
      echo ""
      echo "  ## TASK: Analyze last execution"
      echo "  Workflow ID: \$(jq -r '.workflow_id' $run_state)"
      echo "  Find root cause of failure."
      echo ""
      echo "  Write execution_analysis to run_state:\\"
      echo "  {\\\"completed\\\": true, \\\"root_cause\\\": \\\"...\\\", \\\"diagnosis_file\\\": \\\"...\\\"}\""
      echo "})"
      echo ""
      echo "Reference: FAILURE-ANALYSIS-2025-12-10.md (GATE 2 violation caused 6-hour disaster)"
      return 1
    fi
  fi

  return 0
}
```

### GATE 3: Phase 5 Real Testing

**Rule:** QA cannot report PASS without execution test

```bash
function check_gate_3() {
  local target_agent="$1"
  local run_state="$2"

  # Only check when QA returns result
  if [ "$target_agent" = "qa" ]; then
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local qa_report_file="${project_path}/.n8n/agent_results/qa_report.json"

    if [ -f "$qa_report_file" ]; then
      local qa_status=$(jq -r '.status // "unknown"' "$qa_report_file")
      local phase_5=$(jq -r '.phase_5_executed // false' "$qa_report_file")

      if [ "$qa_status" = "PASS" ] && [ "$phase_5" != "true" ]; then
        echo "🚨 GATE 3 VIOLATION: Cannot report PASS without Phase 5 execution test"
        echo ""
        echo "QA MUST test real execution, not just config validation!"
        echo ""
        echo "Phase 5 requirement:"
        echo "1. Trigger workflow via MCP"
        echo "2. Wait for execution completion"
        echo "3. Verify execution status = success"
        echo "4. Check expected behavior (bot responds, etc.)"
        echo "5. Set phase_5_executed: true in qa_report"
        echo ""
        echo "Reference: FAILURE-ANALYSIS-2025-12-10.md (QA missed 'Log Message' error)"
        return 1
      fi
    fi
  fi

  return 0
}
```

### GATE 4: Knowledge Base Check

**Rule:** Researcher must check LEARNINGS before web search

```bash
function check_gate_4() {
  local target_agent="$1"
  local run_state="$2"

  # Check if Researcher is about to do web search
  if [ "$target_agent" = "researcher" ]; then
    local research_findings_file="${project_path}/.n8n/agent_results/research_findings.json"

    if [ -f "$research_findings_file" ]; then
      local learnings_checked=$(jq -r '.learnings_checked // false' "$research_findings_file")
      local web_search_planned=$(jq -r '.web_search_planned // false' "$research_findings_file")

      if [ "$web_search_planned" = "true" ] && [ "$learnings_checked" != "true" ]; then
        echo "🚨 GATE 4 VIOLATION: Check LEARNINGS-INDEX.md before web search"
        echo ""
        echo "Protocol:"
        echo "1. Read docs/learning/LEARNINGS-INDEX.md first"
        echo "2. Search for relevant L-XXX patterns"
        echo "3. If found → use local knowledge"
        echo "4. If not found → then web search allowed"
        echo ""
        echo "Local knowledge > Web search (faster + proven solutions)"
        return 1
      fi
    fi
  fi

  return 0
}
```

### GATE 5: MCP Verification

**Rule:** Builder must log actual MCP responses (anti-hallucination)

```bash
function check_gate_5() {
  local target_agent="$1"
  local run_state="$2"

  # Check when Builder returns result
  if [ "$target_agent" = "builder" ]; then
    local workflow_id=$(jq -r '.workflow_id' "$run_state")
    local build_result_file="${project_path}/.n8n/agent_results/build_result.json"

    if [ -f "$build_result_file" ]; then
      local build_status=$(jq -r '.status // "unknown"' "$build_result_file")
      local mcp_calls=$(jq -r '.mcp_calls // []' "$build_result_file")
      local mcp_count=$(jq -r '.mcp_calls | length' "$build_result_file")

      if [ "$build_status" = "success" ] && [ "$mcp_count" -eq 0 ]; then
        echo "🚨 GATE 5 VIOLATION: Builder must log mcp_calls array"
        echo ""
        echo "Anti-hallucination measure:"
        echo "Builder MUST log actual MCP tool responses in build_result.json:"
        echo ""
        echo "{"
        echo "  \"status\": \"success\","
        echo "  \"mcp_calls\": ["
        echo "    {"
        echo "      \"tool\": \"n8n_update_full_workflow\","
        echo "      \"workflow_id\": \"abc123\","
        echo "      \"response\": { \"id\": \"abc123\", \"versionId\": 42 }"
        echo "    }"
        echo "  ]"
        echo "}"
        echo ""
        echo "Reference: L-075 (Anti-hallucination protocol)"
        return 1
      fi
    fi
  fi

  return 0
}
```

### GATE 6: Hypothesis Validation

**Rule:** Researcher must validate hypothesis via MCP

```bash
function check_gate_6() {
  local target_agent="$1"
  local run_state="$2"

  # Check when Researcher returns findings
  if [ "$target_agent" = "researcher" ]; then
    local research_findings_file="${project_path}/.n8n/agent_results/research_findings.json"

    if [ -f "$research_findings_file" ]; then
      local findings_status=$(jq -r '.status // "unknown"' "$research_findings_file")
      local hypothesis_validated=$(jq -r '.hypothesis_validated // false' "$research_findings_file")

      if [ "$findings_status" = "complete" ] && [ "$hypothesis_validated" != "true" ]; then
        echo "🚨 GATE 6 VIOLATION: Hypothesis not validated"
        echo ""
        echo "Researcher MUST validate solution via MCP before proposing:"
        echo ""
        echo "Example:"
        echo "  Hypothesis: \"Use HTTP Request node for API\""
        echo "  Validation: mcp__n8n_mcp__get_node(nodeType=\"n8n-nodes-base.httpRequest\")"
        echo "  Result: {hypothesis_validated: true, evidence: \"Node exists, supports auth\"}""
        echo ""
        echo "Never propose untested solutions!"
        return 1
      fi
    fi
  fi

  return 0
}
```

---

## Main Enforcement Function

```bash
function check_all_gates() {
  local target_agent="$1"
  local run_state="$2"

  # Get project_path
  project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")

  echo "🔒 Checking validation gates for: $target_agent"

  # Check all gates in order
  check_gate_0 "$target_agent" "$run_state" || return 1
  check_gate_2 "$target_agent" "$run_state" || return 1
  check_gate_3 "$target_agent" "$run_state" || return 1
  check_gate_4 "$target_agent" "$run_state" || return 1
  check_gate_5 "$target_agent" "$run_state" || return 1
  check_gate_6 "$target_agent" "$run_state" || return 1

  echo "✅ All validation gates passed"
  return 0
}
```

---

## Testing

### Test GATE 2 Violation

```bash
# Create test run_state with missing execution_analysis
cat > /tmp/test_run_state.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "execution_analysis": {
    "completed": false
  }
}
EOF

# Test enforcement
source .claude/agents/shared/gate-enforcement.md
check_all_gates "builder" "/tmp/test_run_state.json"

# Expected output:
# 🚨 GATE 2 VIOLATION: Cannot fix without execution analysis
# (exit code 1)
```

### Test All Gates Pass

```bash
# Create complete run_state
cat > /tmp/test_run_state.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 0,
  "workflow_id": "test123",
  "research_findings": {"status": "complete"},
  "execution_analysis": {"completed": true}
}
EOF

# Test enforcement
check_all_gates "builder" "/tmp/test_run_state.json"

# Expected output:
# 🔒 Checking validation gates for: builder
# ✅ All validation gates passed
# (exit code 0)
```

---

## Error Messages Guide

All gate violation messages include:
1. **What went wrong** - Clear violation description
2. **Why it matters** - Reference to FAILURE-ANALYSIS or learning
3. **How to fix** - Exact code/commands to resolve
4. **Example** - Working example of correct usage

**Philosophy:** Block early, guide clearly, prevent disasters.

---

**Version:** 1.0.0
**Created:** 2025-12-10
**Status:** ✅ Ready for integration into orchestrator
