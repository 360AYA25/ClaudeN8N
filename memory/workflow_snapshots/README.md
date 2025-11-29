# Canonical Workflow Snapshots

**Purpose:** Single Source of Truth for each workflow - detailed analysis that persists between sessions.

## Directory Structure

```
workflow_snapshots/
├── {workflow_id}/
│   ├── canonical.json       # Current canonical snapshot (auto-updated)
│   └── history/
│       ├── v1_2025-11-25.json
│       └── v2_2025-11-26.json
└── README.md
```

## Canonical Snapshot Format (~10K tokens)

```json
{
  "snapshot_metadata": {
    "workflow_id": "sw3Qs3Fe3JahEbbW",
    "workflow_name": "FoodTracker v2.0",
    "created_at": "2025-11-28T20:00:00Z",
    "updated_at": "2025-11-28T23:30:00Z",
    "version_counter": 37,
    "snapshot_version": 5,
    "node_count": 29,
    "is_canonical": true
  },

  "workflow_config": {
    "nodes": [...],           // FULL nodes array
    "connections": {...},     // FULL connections
    "settings": {...}
  },

  "extracted_code": {
    "Process Text": {
      "node_id": "abc-123",
      "node_type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "jsCode": "...",
      "language": "javascript",
      "lines_of_code": 45,
      "anti_patterns": [
        { "pattern": "deprecated_$node_syntax", "severity": "critical", "learning": "L-060" }
      ]
    }
  },

  "node_inventory": {
    "total": 29,
    "by_type": { "code": 7, "switch": 1 },
    "by_category": { "trigger": 1, "processing": 12 },
    "critical_nodes": [{ "name": "...", "issues": [...] }],
    "credentials_used": ["telegramApi", "openAiApi"]
  },

  "connections_graph": {
    "entry_points": ["Telegram Trigger"],
    "routing_nodes": ["Switch"],
    "branches": { "text": [...], "voice": [...] },
    "max_depth": 12
  },

  "execution_history": {
    "last_10_executions": [...],
    "success_rate": 0.3,
    "common_failure_point": "Process Text"
  },

  "anti_patterns_detected": [
    { "id": "AP-001", "pattern": "L-060", "severity": "critical", "auto_fixable": true }
  ],

  "learnings_matched": [
    { "id": "L-060", "confidence": 95, "applicable": true }
  ],

  "recommendations": [
    { "priority": 1, "action": "fix_deprecated_syntax", "nodes": [...], "learning": "L-060" }
  ],

  "change_history": [
    { "version": 4, "timestamp": "...", "action": "fix", "nodes_changed": [...] }
  ]
}
```

## Lifecycle

```
[NEW WORKFLOW] → Create initial canonical.json
       ↓
[FIX/FEATURE] → Load canonical → Apply changes → Update canonical
       ↓
[NEXT TASK] → Load canonical → Already know everything!
```

## Commands

```bash
/orch snapshot view <workflow_id>      # View current snapshot
/orch snapshot rollback <id> [version] # Restore from history
/orch snapshot refresh <workflow_id>   # Force recreate from n8n
```

## Anti-Pattern Detection

| Pattern | Learning | Severity | Auto-fixable |
|---------|----------|----------|--------------|
| `$node["..."]` deprecated | L-060 | CRITICAL | Yes |
| Switch without mode | L-056 | HIGH | Yes |
| Missing webhook path | L-042 | MEDIUM | Yes |

## Agent Usage

| Agent | Access | Purpose |
|-------|--------|---------|
| Orchestrator | Read/Write | Load at start, update after build |
| Researcher | Read | Use instead of n8n_get_workflow |
| Builder | Read | Check anti_patterns before build |
| QA | Read | Compare before/after |
| Analyst | Read | Richer context for analysis |
