#!/bin/bash
# Snapshot Manager Functions
# Version: 1.0.0 (2025-12-13)
# Purpose: Manage workflow snapshots and rollback operations
# Usage: source .claude/agents/shared/snapshot-manager.sh

###############################################################################
# Snapshot List
###############################################################################

function list_snapshots() {
  local project_path="${1:-/Users/sergey/Projects/ClaudeN8N}"
  local snapshot_dir="${project_path}/.n8n/snapshots"

  echo "📋 Available snapshots in $snapshot_dir:"
  echo ""

  if [ -d "$snapshot_dir" ] && [ -n "$(ls -A $snapshot_dir 2>/dev/null)" ]; then
    ls -1t "$snapshot_dir"/*.json | while read file; do
      timestamp=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
      basename_file=$(basename "$file")
      size=$(du -h "$file" | cut -f1)
      echo "  $basename_file ($size, created: $timestamp)"
    done
  else
    echo "  No snapshots found"
  fi
}

###############################################################################
# Find Snapshot
###############################################################################

function find_snapshot() {
  local timestamp="$1"
  local project_path="${2:-/Users/sergey/Projects/ClaudeN8N}"
  local snapshot_dir="${project_path}/.n8n/snapshots"

  # If no timestamp, get latest
  if [ -z "$timestamp" ]; then
    local latest_snapshot=$(ls -t "$snapshot_dir"/*.json 2>/dev/null | head -1)

    if [ -z "$latest_snapshot" ]; then
      echo "ERROR: No snapshots found in $snapshot_dir" >&2
      return 1
    fi

    echo "$latest_snapshot"
    return 0
  fi

  # Find by timestamp
  local snapshot_file=$(find "$snapshot_dir" -name "${timestamp}*.json" 2>/dev/null | head -1)

  if [ ! -f "$snapshot_file" ]; then
    echo "ERROR: Snapshot not found: $timestamp" >&2
    echo "Available:" >&2
    ls -1 "$snapshot_dir"/*.json 2>/dev/null | xargs -n1 basename >&2 || echo "  None" >&2
    return 1
  fi

  echo "$snapshot_file"
  return 0
}

###############################################################################
# Rollback Workflow
###############################################################################

function prepare_rollback() {
  local snapshot_file="$1"
  local workflow_id="$2"
  local project_path="${3:-/Users/sergey/Projects/ClaudeN8N}"

  # Validate snapshot exists
  if [ ! -f "$snapshot_file" ]; then
    echo "❌ Snapshot file not found: $snapshot_file"
    return 1
  fi

  # Extract workflow_id from snapshot if not provided
  if [ -z "$workflow_id" ] || [ "$workflow_id" = "null" ]; then
    workflow_id=$(jq -r '.id // .workflow_id // null' "$snapshot_file")

    if [ "$workflow_id" = "null" ]; then
      echo "❌ Cannot determine workflow_id from snapshot"
      return 1
    fi
  fi

  # Show confirmation dialog
  echo "⚠️ This will restore workflow to snapshot:"
  echo "   Workflow ID: $workflow_id"
  echo "   Snapshot: $(basename $snapshot_file)"
  echo "   Created: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$snapshot_file")"
  echo "   Size: $(du -h "$snapshot_file" | cut -f1)"
  echo ""

  # Return info for caller
  echo "$workflow_id"
  return 0
}

###############################################################################
# Handle Rollback Command
###############################################################################

function handle_rollback_command() {
  local user_request="$1"
  local project_path="${2:-/Users/sergey/Projects/ClaudeN8N}"
  local workflow_id="$3"
  local snapshot_dir="${project_path}/.n8n/snapshots"

  # Handle "list" subcommand
  if [[ "$user_request" =~ rollback\ list ]]; then
    list_snapshots "$project_path"
    return 0
  fi

  # Get timestamp (latest if not specified)
  local timestamp=$(echo "$user_request" | awk '{print $3}')

  # Find snapshot
  local snapshot_file=$(find_snapshot "$timestamp" "$project_path")
  if [ $? -ne 0 ]; then
    return 1
  fi

  # Extract workflow_id if needed
  if [ -z "$workflow_id" ] || [ "$workflow_id" = "null" ]; then
    workflow_id=$(jq -r '.id // .workflow_id // null' "$snapshot_file")
  fi

  # Prepare and show confirmation
  prepare_rollback "$snapshot_file" "$workflow_id" "$project_path"
  if [ $? -ne 0 ]; then
    return 1
  fi

  # Return snapshot info for caller
  echo "SNAPSHOT_FILE=$snapshot_file"
  echo "WORKFLOW_ID=$workflow_id"
  echo "PROJECT_PATH=$project_path"
  return 2  # Signal: need user confirmation
}

# End of snapshot-manager.sh
