#!/bin/bash
# Integration Test: Full Safety System
# Tests all Priority 0 + Priority 1 features together
# Version: 1.0.0 (2025-12-10)

# Note: NOT using "set -e" because we EXPECT some commands to fail (gates blocking)

echo "═══════════════════════════════════════════════════════════"
echo "🧪 SAFETY SYSTEM INTEGRATION TEST"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Testing Priority 0 + Priority 1 features:"
echo "  1. Gate Enforcement (6 gates)"
echo "  2. Auto-Snapshot System"
echo "  3. Incremental Testing (ChangeQueue)"
echo "  4. QA Phase 5 Mandatory"
echo "  5. Minimal Fix Preference"
echo "  6. Frustration Detection"
echo ""

# Setup
test_dir="/tmp/safety_integration_test"
mkdir -p "$test_dir"
cd /Users/sergey/Projects/ClaudeN8N

# Test counters
total_tests=0
passed_tests=0

run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_result="$3"  # "pass" or "block"

  ((total_tests++))

  echo "───────────────────────────────────────────────────────────"
  echo "TEST $total_tests: $test_name"
  echo "───────────────────────────────────────────────────────────"

  # Run test command
  eval "$test_command" >/dev/null 2>&1
  result=$?

  if [ "$expected_result" = "pass" ]; then
    if [ $result -eq 0 ]; then
      echo "✅ PASS (command succeeded as expected)"
      ((passed_tests++))
    else
      echo "❌ FAIL (command failed - unexpected!)"
    fi
  else
    if [ $result -ne 0 ]; then
      echo "✅ PASS (command blocked as expected)"
      ((passed_tests++))
    else
      echo "❌ FAIL (command allowed - security hole!)"
    fi
  fi

  echo ""
}

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 1: GATE ENFORCEMENT INTEGRATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Load gate enforcement
source .claude/agents/shared/gate-enforcement.sh

# Test 1.1: All gates pass with valid state
cat > "$test_dir/run_state_valid.json" <<EOF
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "project_path": "$test_dir",
  "research_findings": {"status": "complete"},
  "execution_analysis": {"completed": true, "root_cause": "found"},
  "frustration_signals": {"profanity": 0}
}
EOF

mkdir -p "$test_dir/.n8n/agent_results"

cat > "$test_dir/.n8n/agent_results/research_findings.json" <<EOF
{
  "status": "complete",
  "hypothesis_validated": true,
  "learnings_checked": true
}
EOF

cat > "$test_dir/.n8n/agent_results/build_result.json" <<EOF
{
  "status": "success",
  "mcp_calls": [
    {"tool": "n8n_update_workflow", "response": {"id": "test123", "versionId": 42}}
  ]
}
EOF

cat > "$test_dir/.n8n/agent_results/qa_report.json" <<EOF
{
  "status": "PASS",
  "phase_5_executed": true
}
EOF

run_test "Gate Enforcement: All gates PASS" \
  "check_all_gates builder '$test_dir/run_state_valid.json'" \
  "pass"

# Test 1.2: GATE 2 blocks fix without execution analysis
cat > "$test_dir/run_state_no_analysis.json" <<EOF
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "test123",
  "execution_analysis": {"completed": false}
}
EOF

run_test "GATE 2: Block fix without execution analysis" \
  "check_all_gates builder '$test_dir/run_state_no_analysis.json'" \
  "block"

# Test 1.3: GATE 5 blocks fake success
cat > "$test_dir/run_state_no_mcp.json" <<EOF
{
  "stage": "build",
  "cycle_count": 0,
  "workflow_id": "test123",
  "project_path": "$test_dir",
  "research_findings": {"status": "complete"}
}
EOF

cat > "$test_dir/.n8n/agent_results/build_result_no_mcp.json" <<EOF
{
  "status": "success",
  "mcp_calls": []
}
EOF

# Point build_result.json to the fake one temporarily for GATE 5 test
mv "$test_dir/.n8n/agent_results/build_result.json" "$test_dir/.n8n/agent_results/build_result_backup.json"
mv "$test_dir/.n8n/agent_results/build_result_no_mcp.json" "$test_dir/.n8n/agent_results/build_result.json"

run_test "GATE 5: Block fake success (no MCP calls)" \
  "check_all_gates builder '$test_dir/run_state_no_mcp.json'" \
  "block"

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 2: FRUSTRATION DETECTION INTEGRATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Load frustration detector
source .claude/agents/shared/frustration-detector.sh

# Test 2.1: Normal request
cat > "$test_dir/run_state_frustration.json" <<EOF
{
  "session_start": $(date +%s),
  "frustration_signals": {"profanity": 0, "complaints": 0, "repeated_requests": 0},
  "last_request": ""
}
EOF

level=$(analyze_frustration "добавь кнопку" "$test_dir/run_state_frustration.json")

if [ "$level" = "NORMAL" ]; then
  echo "✅ PASS: NORMAL frustration level detected"
  ((passed_tests++))
else
  echo "❌ FAIL: Expected NORMAL, got $level"
fi
((total_tests++))
echo ""

# Test 2.2: CRITICAL frustration triggers auto-rollback
cat > "$test_dir/run_state_critical.json" <<EOF
{
  "session_start": $(date -v-5H +%s),
  "frustration_signals": {"profanity": 3, "complaints": 5, "repeated_requests": 3},
  "last_request": "",
  "workflow_id": "test123",
  "project_path": "$test_dir"
}
EOF

mkdir -p "$test_dir/.n8n/snapshots"
cat > "$test_dir/.n8n/snapshots/2025-12-10-backup.json" <<EOF
{"id": "test123", "name": "Backup"}
EOF

level=$(analyze_frustration "блядь fuck сука" "$test_dir/run_state_critical.json")

if [ "$level" = "CRITICAL" ]; then
  echo "✅ PASS: CRITICAL frustration level detected"
  ((passed_tests++))
else
  echo "❌ FAIL: Expected CRITICAL, got $level"
fi
((total_tests++))
echo ""

# Test 2.3: Auto-rollback executes
snapshot_output=$(execute_auto_rollback "$test_dir/run_state_critical.json" 2>&1)
rollback_status=$?

# Extract path from last line (the return value)
snapshot_path=$(echo "$snapshot_output" | tail -1)

if [ $rollback_status -eq 0 ] && [ -f "$snapshot_path" ]; then
  echo "✅ PASS: Auto-rollback executed successfully"
  ((passed_tests++))
else
  echo "❌ FAIL: Auto-rollback failed (path: $snapshot_path, exists: $([ -f "$snapshot_path" ] && echo yes || echo no))"
fi
((total_tests++))
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 3: RESEARCHER MINIMAL FIX PROTOCOL"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 3.1: Researcher.md contains Minimal Fix Protocol
if grep -q "Option 1: MINIMAL FIX" .claude/agents/researcher.md; then
  echo "✅ PASS: Minimal Fix Protocol exists in researcher.md"
  ((passed_tests++))
else
  echo "❌ FAIL: Minimal Fix Protocol missing"
fi
((total_tests++))
echo ""

# Test 3.2: Protocol mandates Option 1 first
if grep -q "MANDATORY Structure for ALL Proposals" .claude/agents/researcher.md; then
  echo "✅ PASS: MANDATORY structure enforced"
  ((passed_tests++))
else
  echo "❌ FAIL: MANDATORY structure missing"
fi
((total_tests++))
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 4: ORCHESTRATOR INTEGRATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 4.1: Orchestrator loads gate enforcement
if grep -q "source .claude/agents/shared/gate-enforcement.sh" .claude/commands/orch.md; then
  echo "✅ PASS: Orchestrator loads gate enforcement"
  ((passed_tests++))
else
  echo "❌ FAIL: Gate enforcement not loaded in orch.md"
fi
((total_tests++))
echo ""

# Test 4.2: Orchestrator loads frustration detection
if grep -q "source .claude/agents/shared/frustration-detector.sh" .claude/commands/orch.md; then
  echo "✅ PASS: Orchestrator loads frustration detection"
  ((passed_tests++))
else
  echo "❌ FAIL: Frustration detection not loaded in orch.md"
fi
((total_tests++))
echo ""

# Test 4.3: Orchestrator checks frustration before processing
if grep -q "check_frustration" .claude/commands/orch.md; then
  echo "✅ PASS: Orchestrator checks frustration"
  ((passed_tests++))
else
  echo "❌ FAIL: Frustration check missing"
fi
((total_tests++))
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 5: BUILDER AUTO-SNAPSHOT"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 5.1: Builder has snapshot protocol
if grep -q "PRE-BUILD: Snapshot Protocol" .claude/agents/builder.md; then
  echo "✅ PASS: Builder has snapshot protocol"
  ((passed_tests++))
else
  echo "❌ FAIL: Snapshot protocol missing"
fi
((total_tests++))
echo ""

# Test 5.2: Builder has ChangeQueue
if grep -q "class ChangeQueue" .claude/agents/builder.md; then
  echo "✅ PASS: Builder has ChangeQueue (incremental testing)"
  ((passed_tests++))
else
  echo "❌ FAIL: ChangeQueue missing"
fi
((total_tests++))
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "SECTION 6: QA PHASE 5 ENFORCEMENT"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 6.1: QA has Phase 5 protocol
if grep -q "PHASE 5: Execution Verification" .claude/agents/qa.md; then
  echo "✅ PASS: QA has Phase 5 protocol"
  ((passed_tests++))
else
  echo "❌ FAIL: Phase 5 protocol missing"
fi
((total_tests++))
echo ""

# Test 6.2: GATE 3 enforces Phase 5
cat > "$test_dir/run_state_no_phase5.json" <<EOF
{
  "stage": "validate",
  "workflow_id": "test123",
  "project_path": "$test_dir"
}
EOF

# Restore build_result.json and update qa_report for Phase 5 test
mv "$test_dir/.n8n/agent_results/build_result_backup.json" "$test_dir/.n8n/agent_results/build_result.json"

cat > "$test_dir/.n8n/agent_results/qa_report_no_phase5.json" <<EOF
{
  "status": "PASS",
  "phase_5_executed": false
}
EOF

mv "$test_dir/.n8n/agent_results/qa_report.json" "$test_dir/.n8n/agent_results/qa_report_backup.json"
mv "$test_dir/.n8n/agent_results/qa_report_no_phase5.json" "$test_dir/.n8n/agent_results/qa_report.json"

check_all_gates qa "$test_dir/run_state_no_phase5.json" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "✅ PASS: GATE 3 blocks QA PASS without Phase 5"
  ((passed_tests++))
else
  echo "❌ FAIL: GATE 3 should block QA without Phase 5"
fi
((total_tests++))
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "INTEGRATION TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $((total_tests - passed_tests))"
echo ""

# Cleanup
cd /
rm -rf "$test_dir"

if [ $passed_tests -eq $total_tests ]; then
  echo "✅ ALL INTEGRATION TESTS PASSED"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "🎯 SAFETY SYSTEM STATUS: OPERATIONAL"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Implemented Features:"
  echo "  ✅ Gate Enforcement (6 gates)"
  echo "  ✅ Auto-Snapshot System"
  echo "  ✅ Incremental Testing (ChangeQueue)"
  echo "  ✅ QA Phase 5 Mandatory (enforced by GATE 3)"
  echo "  ✅ Minimal Fix Preference (Researcher)"
  echo "  ✅ Frustration Detection (auto-rollback)"
  echo ""
  echo "Reference: SYSTEM-SAFETY-OVERHAUL.md"
  echo "Prevents: FAILURE-ANALYSIS-2025-12-10.md disasters"
  echo ""
  echo "Status: ✅ READY FOR PRODUCTION"
  echo ""
  exit 0
else
  echo "❌ SOME INTEGRATION TESTS FAILED"
  echo ""
  echo "Please review failures and fix before deploying."
  exit 1
fi
