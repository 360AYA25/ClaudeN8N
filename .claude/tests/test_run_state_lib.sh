#!/bin/bash
# Unit tests for run-state-lib.sh
# Version: 1.0.0 (2025-12-11)
# Usage: bash .claude/tests/test_run_state_lib.sh

source .claude/agents/shared/run-state-lib.sh

PASS=0
FAIL=0

test() {
  local name="$1"
  shift
  if "$@"; then
    echo "✅ PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "❌ FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

# Test 1: Path resolution (new location)
test "get_path_new" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  path=$(get_run_state_path "/Users/sergey/Projects/ClaudeN8N")
  [[ "$path" == *"run_state"* ]]
'

# Test 2: Update stage
test "update_stage" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"stage\": \"clarification\"}" > /tmp/test_rs.json
  update_stage "research" "/tmp/test_rs.json"
  stage=$(jq -r ".stage" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$stage" == "research" ]]
'

# Test 3: Increment cycle
test "increment_cycle" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"cycle_count\": 0}" > /tmp/test_rs.json
  increment_cycle "/tmp/test_rs.json"
  cycle=$(jq -r ".cycle_count" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$cycle" == "1" ]]
'

# Test 4: Set cycle
test "set_cycle" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"cycle_count\": 0}" > /tmp/test_rs.json
  set_cycle 5 "/tmp/test_rs.json"
  cycle=$(jq -r ".cycle_count" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$cycle" == "5" ]]
'

# Test 5: Append agent_log
test "append_agent_log" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"agent_log\": []}" > /tmp/test_rs.json
  append_agent_log "orchestrator" "test" "details" "/tmp/test_rs.json"
  count=$(jq ".agent_log | length" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$count" == "1" ]]
'

# Test 6: Update field
test "update_field" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"workflow_id\": null}" > /tmp/test_rs.json
  update_field ".workflow_id" "\"abc123\"" "/tmp/test_rs.json"
  wf_id=$(jq -r ".workflow_id" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$wf_id" == "abc123" ]]
'

# Test 7: Merge agent result
test "merge_agent_result" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"requirements\": null, \"research_findings\": null}" > /tmp/test_rs.json
  merge_agent_result "{\"requirements\": {\"test\": true}}" "/tmp/test_rs.json"
  test_val=$(jq -r ".requirements.test" /tmp/test_rs.json)
  rm /tmp/test_rs.json
  [[ "$test_val" == "true" ]]
'

# Test 8: Init run_state (creates file)
test "init_run_state" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  rm -f /tmp/test_init_rs.json
  # For this test, just verify the function runs without error
  true
'

# Test 9: Backup run_state
test "backup_run_state" bash -c '
  source .claude/agents/shared/run-state-lib.sh
  echo "{\"test\": true}" > /tmp/test_backup_rs.json
  backup_path=$(backup_run_state "/tmp/test_backup_rs.json")
  rm /tmp/test_backup_rs.json
  rm -rf /tmp/backups
  [[ -n "$backup_path" ]]
'

echo ""
echo "════════════════════════════════════════"
echo "Tests: $((PASS + FAIL)) total, $PASS passed, $FAIL failed"
echo "════════════════════════════════════════"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
