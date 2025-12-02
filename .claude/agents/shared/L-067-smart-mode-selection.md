# L-067: Smart Mode Selection Protocol

**Purpose:** Prevent "Prompt is too long" crashes on large workflows

## Decision Logic

```javascript
// Get node count from best available source
const node_count = run_state.workflow?.node_count
                || run_state.canonical_snapshot?.node_inventory?.total
                || blueprint?.nodes_needed?.length
                || 999; // Default to safe mode

// Select mode
const mode = node_count > 10 ? "structure" : "full";
```

## Why?

- ≤10 nodes: "full" is safe (~2-5K tokens)
- >10 nodes: "structure" prevents binary data crash (~2-5K tokens, no binary)

## Apply Before

- All `n8n_get_workflow()` calls
- All `n8n_executions()` calls (use two-step: summary → filtered)

## Version History

- v3.3.0: Initial implementation (executions only)
- v3.3.1: Extended to get_workflow
- v3.3.2: Fixed orch.md L3 FULL_INVESTIGATION
- v3.4.0: Consolidated to single source of truth
