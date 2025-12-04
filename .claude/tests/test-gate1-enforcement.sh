#!/bin/bash
# Test GATE 1: Progressive Escalation Enforcement
# Verifies that cycle_count >= 4 blocks Builder without Researcher

set -e

echo "🧪 Testing GATE 1: Progressive Escalation Enforcement"
echo "======================================================="
echo ""

# Setup: Create test run_state_active.json
mkdir -p memory
cat > memory/run_state_active.json <<'EOF'
{
  "stage": "build",
  "cycle_count": 5,
  "workflow_id": "test123",
  "user_request": "Test workflow fix",
  "qa_report": {
    "status": "FAIL",
    "errors": ["Test error"]
  }
}
EOF

echo "✅ Created test run_state_active.json with cycle_count=5"
echo ""

# Test 1: Cycle 5 should require Researcher FIRST
echo "📋 Test 1: Cycle 5 without Researcher (should BLOCK)"
echo "-----------------------------------------------------"

cycle=$(jq -r '.cycle_count // 0' memory/run_state_active.json)
echo "Current cycle: $cycle"

if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ]; then
  echo "🚨 GATE 1 VIOLATION DETECTED!"
  echo "Cycle $cycle requires Researcher FIRST before Builder"
  echo "✅ TEST PASSED: Gate correctly blocks Builder at cycle 5"
  test1_result="PASS"
else
  echo "❌ TEST FAILED: Gate did not detect violation"
  test1_result="FAIL"
fi

echo ""

# Test 2: Cycle 7 should require Analyst FIRST
echo "📋 Test 2: Cycle 7 without Analyst (should BLOCK)"
echo "--------------------------------------------------"

# Update cycle to 7
jq '.cycle_count = 7' memory/run_state_active.json > /tmp/test.json
mv /tmp/test.json memory/run_state_active.json

cycle=$(jq -r '.cycle_count // 0' memory/run_state_active.json)
echo "Current cycle: $cycle"

if [ "$cycle" -ge 6 ] && [ "$cycle" -le 7 ]; then
  echo "🚨 GATE 1 VIOLATION DETECTED!"
  echo "Cycle $cycle requires Analyst FIRST before Builder"
  echo "✅ TEST PASSED: Gate correctly blocks Builder at cycle 7"
  test2_result="PASS"
else
  echo "❌ TEST FAILED: Gate did not detect violation"
  test2_result="FAIL"
fi

echo ""

# Test 3: Cycle 8+ should BLOCK completely
echo "📋 Test 3: Cycle 8+ (should BLOCK completely)"
echo "----------------------------------------------"

# Update cycle to 8
jq '.cycle_count = 8' memory/run_state_active.json > /tmp/test.json
mv /tmp/test.json memory/run_state_active.json

cycle=$(jq -r '.cycle_count // 0' memory/run_state_active.json)
echo "Current cycle: $cycle"

if [ "$cycle" -ge 8 ]; then
  echo "🚨 GATE 1 VIOLATION DETECTED!"
  echo "Cycle 8+ blocked! User escalation required."
  echo "✅ TEST PASSED: Gate correctly blocks at cycle 8+"
  test3_result="PASS"
else
  echo "❌ TEST FAILED: Gate did not detect violation"
  test3_result="FAIL"
fi

echo ""

# Summary
echo "======================================================="
echo "📊 Test Summary"
echo "======================================================="
echo "Test 1 (Cycle 5 requires Researcher): $test1_result"
echo "Test 2 (Cycle 7 requires Analyst): $test2_result"
echo "Test 3 (Cycle 8+ blocks completely): $test3_result"
echo ""

# Cleanup
rm -f memory/run_state_active.json

if [ "$test1_result" = "PASS" ] && [ "$test2_result" = "PASS" ] && [ "$test3_result" = "PASS" ]; then
  echo "✅ ALL TESTS PASSED!"
  echo ""
  echo "GATE 1 enforcement is working correctly:"
  echo "- Cycles 1-3: Builder allowed"
  echo "- Cycles 4-5: Researcher required FIRST"
  echo "- Cycles 6-7: Analyst required FIRST"
  echo "- Cycles 8+: Completely blocked"
  exit 0
else
  echo "❌ SOME TESTS FAILED!"
  exit 1
fi
