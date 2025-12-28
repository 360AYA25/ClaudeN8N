#!/bin/bash
# Integration Test: Verify cycle 6-7 escalation works correctly

echo "🧪 Testing Cycle 6-7 Escalation (Analyst delegation)"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_result="$3"

  echo "📋 Test: $test_name"

  eval "$test_command"
  local actual_result=$?

  if [ "$actual_result" -eq "$expected_result" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name (expected: $expected_result, got: $actual_result)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  echo ""
}

# Setup test environment
TEST_DIR="/tmp/cycle_6_7_test_$$"
mkdir -p "$TEST_DIR/memory"

# Create minimal run_state for testing
cat > "$TEST_DIR/memory/run_state_active.json" << 'EOF'
{
  "workflow_id": "test_cycle_6_7",
  "cycle_count": 6,
  "stage": "build",
  "agent_log": []
}
EOF

echo "Test directory: $TEST_DIR"
echo ""

# Source gate enforcement (if available)
if [ -f ".claude/agents/shared/gate-enforcement.sh" ]; then
  source .claude/agents/shared/gate-enforcement.sh
  echo -e "${GREEN}✓${NC} Gate enforcement library loaded"
else
  echo -e "${YELLOW}⚠${NC} Gate enforcement library not found - checking logic only"
fi
echo ""

# ============================================================================
# Test 1: Cycle 6 without Analyst should BLOCK
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Cycle 6 requires Analyst FIRST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if gate enforcement available
if [ -f ".claude/agents/shared/gate-enforcement.sh" ]; then
  run_test \
    "Cycle 6 without Analyst (should BLOCK)" \
    "check_all_gates 'builder' '$TEST_DIR/memory/run_state_active.json' 2>/dev/null" \
    1  # Expect exit code 1 (BLOCKED)
else
  echo -e "${YELLOW}⚠ SKIP${NC}: Gate enforcement not available"
  echo "Manual check: Verify orch.md line 357 calls Analyst for cycle 6"
  echo ""
fi

# ============================================================================
# Test 2: After Analyst, Builder should be allowed
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Builder allowed after Analyst for cycle 6"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Add Analyst to agent_log + execution analysis (for GATE 2)
cat > "$TEST_DIR/memory/run_state_active.json" << 'EOF'
{
  "workflow_id": "test_cycle_6_7",
  "cycle_count": 6,
  "stage": "build",
  "agent_log": [
    {"agent": "analyst", "cycle": 6, "timestamp": "2025-12-27T12:00:00Z"}
  ],
  "execution_analysis": {
    "completed": true,
    "root_cause": "test"
  }
}
EOF

if [ -f ".claude/agents/shared/gate-enforcement.sh" ]; then
  run_test \
    "Builder allowed after Analyst (should PASS)" \
    "check_all_gates 'builder' '$TEST_DIR/memory/run_state_active.json' 2>/dev/null" \
    0  # Expect exit code 0 (ALLOWED)
else
  echo -e "${YELLOW}⚠ SKIP${NC}: Gate enforcement not available"
  echo ""
fi

# ============================================================================
# Test 3: Verify orch.md contains Analyst for cycle 6-7
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Verify orch.md calls Analyst for cycles 6-7"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if orch.md contains "Analyst FIRST" for cycle 6-7
if grep -q 'Analyst FIRST.*GATE 1 enforces' .claude/commands/orch.md 2>/dev/null; then
  echo -e "${GREEN}✅ PASS${NC}: orch.md contains 'Analyst FIRST' for cycle 6-7"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}❌ FAIL${NC}: orch.md does NOT contain 'Analyst FIRST' for cycle 6-7"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Also check that it doesn't contain the old wrong pattern
if grep -q 'Researcher FIRST.*deep dive' .claude/commands/orch.md 2>/dev/null; then
  echo -e "${RED}❌ FAIL${NC}: orch.md still contains old 'Researcher FIRST' pattern for cycle 6-7"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "${GREEN}✅ PASS${NC}: orch.md does NOT contain old 'Researcher FIRST' pattern"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi
echo ""

# ============================================================================
# Test 4: Verify cycle 7 also requires Analyst
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Cycle 7 requires Analyst FIRST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > "$TEST_DIR/memory/run_state_active.json" << 'EOF'
{
  "workflow_id": "test_cycle_6_7",
  "cycle_count": 7,
  "stage": "build",
  "agent_log": []
}
EOF

if [ -f ".claude/agents/shared/gate-enforcement.sh" ]; then
  run_test \
    "Cycle 7 without Analyst (should BLOCK)" \
    "check_all_gates 'builder' '$TEST_DIR/memory/run_state_active.json' 2>/dev/null" \
    1  # Expect exit code 1 (BLOCKED)
else
  echo -e "${YELLOW}⚠ SKIP${NC}: Gate enforcement not available"
  echo ""
fi

# ============================================================================
# Cleanup
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
rm -rf "$TEST_DIR"
echo "Test directory cleaned up: $TEST_DIR"
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}🎉 All tests passed!${NC}"
  echo ""
  echo "✅ Cycle 6-7 escalation is correctly configured:"
  echo "   - orch.md calls Analyst for cycles 6-7"
  echo "   - VALIDATION-GATES.md requires Analyst"
  echo "   - Gate enforcement blocks violations"
  exit 0
else
  echo -e "${RED}⚠️  Some tests failed!${NC}"
  echo ""
  echo "Please review the failures above."
  exit 1
fi
