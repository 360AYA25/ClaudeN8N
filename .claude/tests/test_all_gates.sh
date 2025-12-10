#!/bin/bash

# Test ALL 6 Validation Gates
echo "🧪 Testing ALL 6 Validation Gates"
echo "===================================="
echo ""

# Load gate enforcement
source .claude/agents/shared/gate-enforcement.sh

# Test counters
passed=0
failed=0

# Helper function
run_test() {
  local test_name="$1"
  local expected_result="$2"  # "pass" or "block"
  local agent="$3"
  local run_state_file="$4"

  echo "Test: $test_name"
  echo "-----------------------------------------------------------"

  check_all_gates "$agent" "$run_state_file" >/dev/null 2>&1
  result=$?

  if [ "$expected_result" = "pass" ]; then
    if [ $result -eq 0 ]; then
      echo "✅ PASS (gates allowed as expected)"
      ((passed++))
    else
      echo "❌ FAIL (gates blocked - unexpected!)"
      ((failed++))
    fi
  else
    if [ $result -ne 0 ]; then
      echo "✅ PASS (gates blocked as expected)"
      ((passed++))
    else
      echo "❌ FAIL (gates allowed - BUG!)"
      ((failed++))
    fi
  fi

  echo ""
}

# ===========================================================================
# GATE 0: Research Phase Required
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 0: Research Phase Required"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Clean test directory
rm -rf memory/agent_results/test123

# Test 1: First Builder call WITH research (should PASS)
# Need build_result.json with mcp_calls to pass GATE 5
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/build_result.json <<'EOF'
{
  "status": "success",
  "mcp_calls": [{"tool": "test"}]
}
EOF

cat > /tmp/gate0_pass.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 0,
  "workflow_id": "test123",
  "research_findings": {
    "status": "complete",
    "hypothesis_validated": true
  }
}
EOF

run_test "GATE 0.1: First Builder call WITH research_findings" "pass" "builder" "/tmp/gate0_pass.json"

# Test 2: First Builder call WITHOUT research (should BLOCK)
cat > /tmp/gate0_fail.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 0,
  "workflow_id": "test123"
}
EOF

run_test "GATE 0.2: First Builder call WITHOUT research_findings" "block" "builder" "/tmp/gate0_fail.json"

# Test 3: Second Builder call (cycle_count > 0) - GATE 0 doesn't apply
# BUT GATE 2 does apply! Need execution_analysis for cycle > 0
cat > /tmp/gate0_skip.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "execution_analysis": {
    "completed": true,
    "root_cause": "test"
  },
  "project_path": "/tmp"
}
EOF

# Need build_result with mcp_calls to pass GATE 5
# Gates look in: ${project_path}/.n8n/agent_results/ or memory/agent_results/${workflow_id}/
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/build_result.json <<'EOF'
{
  "status": "success",
  "mcp_calls": [{"tool": "test"}]
}
EOF

run_test "GATE 0.3: Second Builder call (cycle_count=1, GATE 0 skip, GATE 2 satisfied)" "pass" "builder" "/tmp/gate0_skip.json"

# ===========================================================================
# GATE 2: Execution Analysis Required
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 2: Execution Analysis Required"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 4: Builder fix WITH execution_analysis (should PASS)
cat > /tmp/gate2_pass.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "execution_analysis": {
    "completed": true,
    "root_cause": "Node timeout",
    "diagnosis_file": "test.json"
  }
}
EOF

run_test "GATE 2.1: Builder fix WITH execution_analysis.completed=true" "pass" "builder" "/tmp/gate2_pass.json"

# Test 5: Builder fix WITHOUT execution_analysis (should BLOCK)
cat > /tmp/gate2_fail.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "execution_analysis": {
    "completed": false
  }
}
EOF

run_test "GATE 2.2: Builder fix WITHOUT execution_analysis.completed" "block" "builder" "/tmp/gate2_fail.json"

# ===========================================================================
# GATE 3: Phase 5 Real Testing
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 3: Phase 5 Real Testing"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 6: QA PASS WITH Phase 5 (should PASS)
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/qa_report.json <<'EOF'
{
  "status": "PASS",
  "phase_5_executed": true,
  "execution_result": "success"
}
EOF

cat > /tmp/gate3_pass.json <<'EOF'
{
  "stage": "validate",
  "workflow_id": "test123",
  "project_path": "/tmp"
}
EOF

run_test "GATE 3.1: QA reports PASS WITH phase_5_executed=true" "pass" "qa" "/tmp/gate3_pass.json"

# Test 7: QA PASS WITHOUT Phase 5 (should BLOCK)
cat > memory/agent_results/test123/qa_report.json <<'EOF'
{
  "status": "PASS",
  "phase_5_executed": false
}
EOF

run_test "GATE 3.2: QA reports PASS WITHOUT phase_5_executed" "block" "qa" "/tmp/gate3_pass.json"

# Test 8: QA FAIL (Phase 5 not required for failures)
cat > memory/agent_results/test123/qa_report.json <<'EOF'
{
  "status": "FAIL",
  "phase_5_executed": false,
  "errors": ["Node X missing"]
}
EOF

run_test "GATE 3.3: QA reports FAIL (phase_5 not required)" "pass" "qa" "/tmp/gate3_pass.json"

# ===========================================================================
# GATE 4: Knowledge Base Check
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 4: Knowledge Base Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 9: Researcher WITH learnings_checked (should PASS)
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/research_findings.json <<'EOF'
{
  "learnings_checked": true,
  "web_search_planned": true,
  "status": "in_progress"
}
EOF

cat > /tmp/gate4_pass.json <<'EOF'
{
  "stage": "research",
  "workflow_id": "test123",
  "project_path": "/tmp"
}
EOF

run_test "GATE 4.1: Researcher web search WITH learnings_checked" "pass" "researcher" "/tmp/gate4_pass.json"

# Test 10: Researcher WITHOUT learnings_checked (should BLOCK)
cat > memory/agent_results/test123/research_findings.json <<'EOF'
{
  "learnings_checked": false,
  "web_search_planned": true,
  "status": "in_progress"
}
EOF

run_test "GATE 4.2: Researcher web search WITHOUT learnings_checked" "block" "researcher" "/tmp/gate4_pass.json"

# ===========================================================================
# GATE 5: MCP Verification
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 5: MCP Verification"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 11: Builder success WITH mcp_calls (should PASS)
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/build_result.json <<'EOF'
{
  "status": "success",
  "workflow_id": "123",
  "mcp_calls": [
    {"tool": "n8n_create_workflow", "result": "123"},
    {"tool": "n8n_get_workflow", "result": "verified"}
  ]
}
EOF

cat > /tmp/gate5_pass.json <<'EOF'
{
  "stage": "build",
  "workflow_id": "test123",
  "project_path": "/tmp",
  "cycle_count": 0,
  "research_findings": {
    "status": "complete"
  }
}
EOF

run_test "GATE 5.1: Builder success WITH mcp_calls array" "pass" "builder" "/tmp/gate5_pass.json"

# Test 12: Builder success WITHOUT mcp_calls (should BLOCK)
cat > memory/agent_results/test123/build_result.json <<'EOF'
{
  "status": "success",
  "workflow_id": "123",
  "mcp_calls": []
}
EOF

cat > /tmp/gate5_fail.json <<'EOF'
{
  "stage": "build",
  "workflow_id": "test123",
  "project_path": "/tmp",
  "cycle_count": 0,
  "research_findings": {
    "status": "complete"
  }
}
EOF

run_test "GATE 5.2: Builder success WITHOUT mcp_calls (anti-hallucination)" "block" "builder" "/tmp/gate5_fail.json"

# ===========================================================================
# GATE 6: Hypothesis Validation
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "GATE 6: Hypothesis Validation"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 13: Researcher complete WITH hypothesis_validated (should PASS)
mkdir -p memory/agent_results/test123
cat > memory/agent_results/test123/research_findings.json <<'EOF'
{
  "status": "complete",
  "hypothesis_validated": true,
  "fit_score": 95
}
EOF

cat > /tmp/gate6_pass.json <<'EOF'
{
  "stage": "research",
  "workflow_id": "test123",
  "project_path": "/tmp"
}
EOF

run_test "GATE 6.1: Researcher complete WITH hypothesis_validated=true" "pass" "researcher" "/tmp/gate6_pass.json"

# Test 14: Researcher complete WITHOUT hypothesis_validated (should BLOCK)
cat > memory/agent_results/test123/research_findings.json <<'EOF'
{
  "status": "complete",
  "hypothesis_validated": false,
  "fit_score": 95
}
EOF

run_test "GATE 6.2: Researcher complete WITHOUT hypothesis_validated" "block" "researcher" "/tmp/gate6_pass.json"

# ===========================================================================
# SUMMARY
# ===========================================================================
echo "═══════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Total tests: $((passed + failed))"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [ $failed -eq 0 ]; then
  echo "🎉 ALL GATES WORKING CORRECTLY!"
  exit 0
else
  echo "❌ SOME GATES FAILED - FIX REQUIRED!"
  exit 1
fi
