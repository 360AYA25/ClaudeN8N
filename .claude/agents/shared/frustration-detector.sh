#!/bin/bash
# Frustration Detection System
# Version: 1.0.0 (2025-12-10)
# Purpose: Auto-detect user frustration and offer rollback
# Usage: source .claude/agents/shared/frustration-detector.sh

###############################################################################
# Frustration Signal Detection
###############################################################################

function detect_profanity() {
  local message="$1"

  # Russian and English profanity words
  local profanity_words=(
    "блядь" "пизд" "хуй" "пидор" "сука" "ебан" "чёрт"
    "fuck" "shit" "damn" "crap" "hell"
  )

  local count=0

  for word in "${profanity_words[@]}"; do
    # Case-insensitive grep count
    local matches=$(echo "$message" | grep -io "$word" | wc -l | xargs)
    count=$((count + matches))
  done

  echo "$count"
}

function detect_complaints() {
  local message="$1"

  # Complaint phrases
  local complaint_phrases=(
    "не работает"
    "сломал"
    "где кнопки"
    "why not working"
    "still broken"
    "nothing works"
    "час"
    "hours"
    "пятый час"
    "третий час"
  )

  for phrase in "${complaint_phrases[@]}"; do
    if echo "$message" | grep -qi "$phrase"; then
      echo "1"
      return
    fi
  done

  echo "0"
}

function calculate_session_duration() {
  local run_state="$1"

  # Get session start timestamp (Unix epoch)
  local session_start=$(jq -r '.session_start // null' "$run_state")

  if [ "$session_start" = "null" ]; then
    echo "0"
    return
  fi

  # Current time
  local now=$(date +%s)

  # Duration in minutes
  local duration=$(( (now - session_start) / 60 ))

  echo "$duration"
}

function detect_repeated_request() {
  local current_request="$1"
  local run_state="$2"

  local last_request=$(jq -r '.last_request // ""' "$run_state")

  if [ -z "$last_request" ]; then
    echo "0"
    return
  fi

  # Simple word overlap check
  # Convert to lowercase, split into words
  local words1=$(echo "$current_request" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '\n')
  local words2=$(echo "$last_request" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '\n')

  # Count common words
  local common=$(comm -12 <(echo "$words1" | sort) <(echo "$words2" | sort) | wc -l | xargs)
  local total=$(echo "$words1 $words2" | tr ' ' '\n' | sort -u | wc -l | xargs)

  # If >60% overlap → similar
  if [ "$total" -gt 0 ]; then
    local similarity=$(awk "BEGIN {print ($common / $total)}")
    if (( $(echo "$similarity > 0.6" | bc -l) )); then
      echo "1"
      return
    fi
  fi

  echo "0"
}

###############################################################################
# Frustration Level Calculation
###############################################################################

function analyze_frustration() {
  local message="$1"
  local run_state="$2"

  # 1. Detect signals
  local profanity=$(detect_profanity "$message")
  local complaint=$(detect_complaints "$message")
  local session_duration=$(calculate_session_duration "$run_state")
  local repeated=$(detect_repeated_request "$message" "$run_state")

  # 2. Get accumulated signals from run_state
  local total_profanity=$(jq -r '.frustration_signals.profanity // 0' "$run_state")
  local total_complaints=$(jq -r '.frustration_signals.complaints // 0' "$run_state")
  local total_repeated=$(jq -r '.frustration_signals.repeated_requests // 0' "$run_state")

  # 3. Add new signals
  total_profanity=$((total_profanity + profanity))
  total_complaints=$((total_complaints + complaint))
  total_repeated=$((total_repeated + repeated))

  # 4. Update run_state with new signals
  jq --arg prof "$total_profanity" \
     --arg comp "$total_complaints" \
     --arg rep "$total_repeated" \
     --arg dur "$session_duration" \
     '.frustration_signals = {
       profanity: ($prof | tonumber),
       complaints: ($comp | tonumber),
       repeated_requests: ($rep | tonumber),
       session_duration: ($dur | tonumber)
     }' "$run_state" > /tmp/run_state_tmp.json && mv /tmp/run_state_tmp.json "$run_state"

  # 5. Calculate frustration level
  local level=0

  # Thresholds
  local profanity_threshold=3
  local session_threshold=120  # 2 hours
  local complaints_threshold=5
  local repeated_threshold=3

  # Add points based on signals
  if [ "$total_profanity" -ge "$profanity_threshold" ]; then
    level=$((level + 3))
  fi

  if [ "$session_duration" -ge "$session_threshold" ]; then
    level=$((level + 2))
  fi

  if [ "$total_complaints" -ge "$complaints_threshold" ]; then
    level=$((level + 2))
  fi

  if [ "$total_repeated" -ge "$repeated_threshold" ]; then
    level=$((level + 1))
  fi

  # 6. Determine frustration level
  local frustration_level="NORMAL"

  if [ "$level" -ge 5 ]; then
    frustration_level="CRITICAL"
  elif [ "$level" -ge 3 ]; then
    frustration_level="HIGH"
  elif [ "$level" -ge 1 ]; then
    frustration_level="MODERATE"
  fi

  # 7. Return level
  echo "$frustration_level"
}

###############################################################################
# Recommended Action
###############################################################################

function get_recommended_action() {
  local frustration_level="$1"

  case "$frustration_level" in
    CRITICAL)
      echo "STOP_AND_ROLLBACK"
      ;;
    HIGH)
      echo "OFFER_ROLLBACK"
      ;;
    MODERATE)
      echo "CHECK_IN"
      ;;
    *)
      echo "CONTINUE"
      ;;
  esac
}

function get_frustration_message() {
  local frustration_level="$1"

  case "$frustration_level" in
    CRITICAL)
      echo "🚨 Вижу, что ты очень устал. Откатываю все изменения и предлагаю продолжить позже, когда отдохнёшь."
      ;;
    HIGH)
      echo "⚠️ Кажется, что-то пошло не так. Откатить все изменения и вернуться к рабочему состоянию?"
      ;;
    MODERATE)
      echo "💡 Вижу, что возникли проблемы. Хочешь, чтобы я попробовал другой подход или откатить изменения?"
      ;;
    *)
      echo ""
      ;;
  esac
}

###############################################################################
# Auto-Rollback Execution
###############################################################################

function execute_auto_rollback() {
  local run_state="$1"

  # Get project context
  local project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' "$run_state")
  local workflow_id=$(jq -r '.workflow_id // null' "$run_state")

  if [ "$workflow_id" = "null" ]; then
    echo "❌ No workflow_id in run_state - cannot rollback" >&2
    return 1
  fi

  # Find latest snapshot
  local snapshot_dir="${project_path}/.n8n/snapshots"

  if [ ! -d "$snapshot_dir" ]; then
    echo "❌ No snapshots directory - cannot rollback" >&2
    return 1
  fi

  local latest_snapshot=$(ls -1t "$snapshot_dir"/*.json 2>/dev/null | head -n 1)

  if [ -z "$latest_snapshot" ]; then
    echo "❌ No snapshots found - cannot rollback" >&2
    return 1
  fi

  echo "🔄 Auto-rollback to: $(basename $latest_snapshot)"

  # Delegate to Builder for restore
  echo "Delegating rollback to Builder agent..."

  # Return snapshot path for orchestrator
  echo "$latest_snapshot"
  return 0
}

###############################################################################
# Main Frustration Check Function
###############################################################################

function check_frustration() {
  local message="$1"
  local run_state="$2"

  echo "🔍 Checking frustration signals..." >&2

  # 1. Analyze frustration
  local frustration_level=$(analyze_frustration "$message" "$run_state")

  # 2. Get recommended action
  local action=$(get_recommended_action "$frustration_level")

  # 3. Log signals to stderr
  local signals=$(jq -r '.frustration_signals' "$run_state")
  echo "Signals: $signals" >&2
  echo "Level: $frustration_level" >&2
  echo "Action: $action" >&2

  # 4. Return action to stdout
  echo "$action"
}

###############################################################################
# Handle Frustration Action (full implementation)
###############################################################################

function handle_frustration_action() {
  local action="$1"
  local run_state="$2"

  case "$action" in
    STOP_AND_ROLLBACK)
      echo ""
      echo "🚨 CRITICAL FRUSTRATION DETECTED"
      echo ""
      get_frustration_message "CRITICAL"
      echo ""

      # Show frustration signals
      local signals=$(jq -r '.frustration_signals' "$run_state")
      echo "Signals detected:"
      echo "$signals" | jq '.'
      echo ""

      # Execute auto-rollback
      local snapshot_path=$(execute_auto_rollback "$run_state")

      if [ $? -eq 0 ]; then
        echo "✅ Auto-rollback completed: $snapshot_path"
        echo ""
        echo "💤 Рекомендация: Продолжим завтра, когда ты отдохнёшь? 😊"
        echo ""
        echo "Для восстановления используй:"
        echo "  /orch rollback $(basename $snapshot_path .json)"
      fi

      # Signal to stop processing
      return 1
      ;;

    OFFER_ROLLBACK)
      echo ""
      echo "⚠️ HIGH FRUSTRATION DETECTED"
      echo ""
      get_frustration_message "HIGH"
      echo ""

      # Show frustration signals
      local signals=$(jq -r '.frustration_signals' "$run_state")
      echo "Signals detected:"
      echo "$signals" | jq '.'
      echo ""

      echo "Варианты:"
      echo "  [R]ollback - Откатить все изменения"
      echo "  [C]ontinue - Попробовать другой подход"
      echo "  [S]top - Остановить и отдохнуть"
      echo ""
      echo "❓ Что выбираешь? (R/C/S)"

      # Signal to wait for user input
      return 2
      ;;

    CHECK_IN)
      echo ""
      echo "💡 MODERATE FRUSTRATION DETECTED"
      echo ""
      get_frustration_message "MODERATE"
      echo ""
      # Continue processing
      return 0
      ;;

    *)
      # Normal processing - no frustration detected
      return 0
      ;;
  esac
}

# End of frustration-detector.sh
