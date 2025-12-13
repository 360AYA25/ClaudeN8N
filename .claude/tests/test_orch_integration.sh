#!/bin/bash
# Integration test: Check orch.md can source all libraries
# Version: 1.0.0 (2025-12-11)
# Usage: bash .claude/tests/test_orch_integration.sh

echo "════════════════════════════════════════"
echo "Integration Tests: Library Loading"
echo "════════════════════════════════════════"
echo ""

PASS=0
FAIL=0

test() {
  local name="$1"
  if eval "$2" &>/dev/null; then
    echo "✅ PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "❌ FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

# Test 1: Can source gate-enforcement.sh?
test "Source gate-enforcement.sh" '
  source .claude/agents/shared/gate-enforcement.sh
  type check_all_gates
'

# Test 2: Can source frustration-detector.sh?
test "Source frustration-detector.sh" '
  source .claude/agents/shared/frustration-detector.sh
  type check_frustration
'

# Test 3: Can source run-state-lib.sh?
test "Source run-state-lib.sh" '
  source .claude/agents/shared/run-state-lib.sh
  type update_stage
'

# Test 4: All libraries load together without conflicts?
test "All libraries together (no conflicts)" '
  source .claude/agents/shared/gate-enforcement.sh
  source .claude/agents/shared/frustration-detector.sh
  source .claude/agents/shared/run-state-lib.sh
  type check_all_gates && \
  type check_frustration && \
  type update_stage && \
  type get_run_state_path && \
  type increment_cycle && \
  type append_agent_log
'

# Test 5: gate-enforcement.sh has all expected functions
test "gate-enforcement.sh functions" '
  source .claude/agents/shared/gate-enforcement.sh
  type check_gate_0 && \
  type check_gate_2 && \
  type check_gate_3 && \
  type check_gate_4 && \
  type check_gate_5 && \
  type check_gate_6 && \
  type check_all_gates
'

# Test 6: frustration-detector.sh has all expected functions
test "frustration-detector.sh functions" '
  source .claude/agents/shared/frustration-detector.sh
  type detect_profanity && \
  type detect_complaints && \
  type calculate_session_duration && \
  type detect_repeated_request && \
  type analyze_frustration && \
  type check_frustration
'

# Test 7: run-state-lib.sh has all expected functions
test "run-state-lib.sh functions" '
  source .claude/agents/shared/run-state-lib.sh
  type get_run_state_path && \
  type update_stage && \
  type increment_cycle && \
  type set_cycle && \
  type append_agent_log && \
  type update_field && \
  type merge_agent_result && \
  type init_run_state && \
  type backup_run_state
'

echo ""
echo "════════════════════════════════════════"
echo "Tests: $((PASS + FAIL)) total, $PASS passed, $FAIL failed"
echo "════════════════════════════════════════"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
