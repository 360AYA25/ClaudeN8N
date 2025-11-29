# Plan: Canonical Workflow Snapshot System

**Status:** IMPLEMENTED (2025-11-28)

## Problem Statement

**Current:** Detailed workflow analysis happens ONLY at L3 (after 7 QA failures)
**Result:** 89% token waste, 9 cycles missed $node["..."] deprecated syntax (L-060 incident)
**Root cause:** Agents work "blind" - no full workflow picture, each time re-analyze from scratch

## Solution: Canonical Workflow Snapshot

**Snapshot = Single Source of Truth** for each workflow (~10K tokens):

```
Workflow created → [Create Canonical Snapshot] → File ALWAYS exists
       ↓
  Any change → [Update Snapshot] → New canonical
       ↓
  Next task → [Read Snapshot] → Agents see EVERYTHING immediately
```

### Key Principles

1. **ALWAYS EXISTS** - for each workflow there's a snapshot file
2. **FULL DETAIL** (~10K tokens) - nodes, jsCode, connections, executions, history
3. **CANONICAL** - this is source of truth, not cache
4. **UPDATED AFTER CHANGES** - fix bug → snapshot updates
5. **VERSIONED** - change history preserved

## Directory Structure

```
memory/
├── workflow_snapshots/
│   ├── {workflow_id}/
│   │   ├── canonical.json       # Current snapshot (auto-updated)
│   │   └── history/
│   │       ├── v1_2025-11-25.json
│   │       └── v2_2025-11-26.json
│   └── README.md
```

## Commands

```bash
/orch snapshot view <workflow_id>      # View current snapshot
/orch snapshot rollback <id> [version] # Restore from history
/orch snapshot refresh <workflow_id>   # Force recreate from n8n
```

## Agent Integration

| Agent | Access | When |
|-------|--------|------|
| Orchestrator | Read/Write | Load at start, update after build |
| Researcher | READ | Use instead of n8n_get_workflow |
| Builder | READ | Check anti_patterns before build |
| QA | READ | Compare before/after |
| Analyst | READ | Richer context for analysis |

## Snapshot Format

```json
{
  "snapshot_metadata": { "workflow_id", "version", "node_count" },
  "workflow_config": { "nodes", "connections", "settings" },
  "extracted_code": { "node_name": { "jsCode", "anti_patterns" } },
  "node_inventory": { "total", "by_type", "credentials_used" },
  "connections_graph": { "entry_points", "branches", "max_depth" },
  "execution_history": { "last_10", "success_rate" },
  "anti_patterns_detected": [ { "pattern": "L-060", "severity": "critical" } ],
  "learnings_matched": [ { "id": "L-060", "confidence": 95 } ],
  "recommendations": [ { "priority": 1, "action", "nodes" } ],
  "change_history": [ { "version", "action", "nodes_changed" } ]
}
```

## Expected Results

| Metric | Before | After |
|--------|--------|-------|
| QA cycles to success | 7 | 1-2 |
| Token waste | 89% | 10% |
| Time to fix | 45 min | 10 min |
| L3 escalations | 100% | 5% |

## Files Modified

| File | Change |
|------|--------|
| `memory/workflow_snapshots/README.md` | Created format documentation |
| `.claude/commands/orch.md` | Added snapshot protocol + commands |
| `.claude/agents/builder.md` | Removed old placeholder, added reference |
| `.claude/agents/researcher.md` | Added STEP 0.0 snapshot read |
| `.claude/agents/qa.md` | Added snapshot comparison |
| `.claude/agents/analyst.md` | Added canonical read |

## User Decision

**Chosen:** Auto + basic manual commands (view, rollback, refresh)

Automatic behavior:
1. Orchestrator checks for canonical.json
2. If missing → creates
3. If exists → loads
4. After successful fix/feature → updates

User does nothing - system works automatically.
