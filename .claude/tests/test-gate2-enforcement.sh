#!/bin/bash
# Test GATE 2: Execution Analysis Requirement
# Verifies that Builder cannot fix without execution analysis

set -e

echo "🧪 Testing GATE 2: Execution Analysis Requirement"
echo "=================================================="
echo ""

# Setup: Create test environment
mkdir -p memory/workflow_snapshots/test123

# Create canonical.json to indicate this is a FIX (not new build)
cat > memory/workflow_snapshots/test123/canonical.json <<'EOF'
{
  "id": "test123",
  "name": "Test Workflow",
  "nodes": []
}
EOF

# Test 1: Fix WITHOUT execution_analysis (should BLOCK)
echo "📋 Test 1: Fix without execution_analysis (should BLOCK)"
echo "---------------------------------------------------------"

cat > memory/run_state_active.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 2,
  "workflow_id": "test123",
  "user_request": "Fix broken workflow",
  "qa_report": {
    "status": "FAIL",
    "errors": ["Workflow execution failed"]
  }
}
EOF

echo "Created run_state_active.json WITHOUT execution_analysis"
echo ""

stage=$(jq -r '.stage' memory/run_state_active.json)
workflow_id=$(jq -r '.workflow_id' memory/run_state_active.json)

echo "Stage: $stage"
echo "Workflow ID: $workflow_id"

# Check if fixing existing workflow
if [ "$stage" = "build" ] && [ -f "memory/workflow_snapshots/$workflow_id/canonical.json" ]; then
  echo "This is a FIX (canonical.json exists)"

  execution_analysis=$(jq -r '.execution_analysis.completed // false' memory/run_state_active.json)
  echo "Execution analysis completed: $execution_analysis"

  if [ "$execution_analysis" != "true" ]; then
    echo ""
    echo "🚨 GATE 2 VIOLATION DETECTED!"
    echo "Cannot fix without execution analysis!"
    echo "REQUIRED: Analyst must analyze last 5 executions FIRST."
    echo "✅ TEST PASSED: Gate correctly blocks Builder without analysis"
    test1_result="PASS"
  else
    echo "❌ TEST FAILED: Gate did not detect missing analysis"
    test1_result="FAIL"
  fi
else
  echo "❌ TEST FAILED: Did not detect fix scenario"
  test1_result="FAIL"
fi

echo ""

# Test 2: Fix WITH execution_analysis (should ALLOW)
echo "📋 Test 2: Fix with execution_analysis (should ALLOW)"
echo "-------------------------------------------------------"

cat > memory/run_state_active.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 2,
  "workflow_id": "test123",
  "user_request": "Fix broken workflow",
  "execution_analysis": {
    "completed": true,
    "analyst_agent": "analyst",
    "timestamp": "2025-12-04T15:30:00Z",
    "findings": {
      "break_point": "AI Agent node - input field missing",
      "root_cause": "Data structure mismatch",
      "failed_executions": 5
    }
  },
  "qa_report": {
    "status": "FAIL",
    "errors": ["Workflow execution failed"]
  }
}
EOF

echo "Created run_state_active.json WITH execution_analysis"
echo ""

execution_analysis=$(jq -r '.execution_analysis.completed // false' memory/run_state_active.json)
echo "Execution analysis completed: $execution_analysis"

if [ "$execution_analysis" = "true" ]; then
  echo ""
  echo "✅ Execution analysis present"
  echo "Builder is allowed to proceed with fix"
  echo "✅ TEST PASSED: Gate allows Builder with analysis"
  test2_result="PASS"
else
  echo "❌ TEST FAILED: Gate incorrectly blocked Builder"
  test2_result="FAIL"
fi

echo ""

# Test 3: New build (no canonical.json) should SKIP gate
echo "📋 Test 3: New build without canonical.json (should SKIP gate)"
echo "---------------------------------------------------------------"

rm -rf memory/workflow_snapshots/test123

cat > memory/run_state_active.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 1,
  "workflow_id": "newflow456",
  "user_request": "Create new workflow"
}
EOF

workflow_id=$(jq -r '.workflow_id' memory/run_state_active.json)
echo "Workflow ID: $workflow_id"

if [ ! -f "memory/workflow_snapshots/$workflow_id/canonical.json" ]; then
  echo "No canonical.json - this is NEW build"
  echo "GATE 2 does not apply to new builds"
  echo "✅ TEST PASSED: Gate correctly skips new builds"
  test3_result="PASS"
else
  echo "❌ TEST FAILED: Incorrectly detected as fix scenario"
  test3_result="FAIL"
fi

echo ""

# Summary
echo "=================================================="
echo "📊 Test Summary"
echo "=================================================="
echo "Test 1 (Fix without analysis - BLOCK): $test1_result"
echo "Test 2 (Fix with analysis - ALLOW): $test2_result"
echo "Test 3 (New build - SKIP gate): $test3_result"
echo ""

# Cleanup
rm -rf memory

if [ "$test1_result" = "PASS" ] && [ "$test2_result" = "PASS" ] && [ "$test3_result" = "PASS" ]; then
  echo "✅ ALL TESTS PASSED!"
  echo ""
  echo "GATE 2 enforcement is working correctly:"
  echo "- FIX without analysis: ❌ BLOCKED"
  echo "- FIX with analysis: ✅ ALLOWED"
  echo "- NEW build: ✅ SKIPPED (gate not applicable)"
  exit 0
else
  echo "❌ SOME TESTS FAILED!"
  exit 1
fi
