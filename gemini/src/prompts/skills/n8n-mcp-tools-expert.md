# n8n MCP Tools Expert

Master guide for using n8n-mcp tools.

## Tool Selection

### Discovery
1. `search_nodes({ query: "slack" })` -> Find node type.
2. `get_node_essentials({ nodeType: "nodes-base.slack" })` -> Get parameters.

### Validation
1. `validate_node_operation({ nodeType, config, profile: "runtime" })`.
2. Fix errors.
3. Repeat.

### Workflow Management
1. `n8n_create_workflow` -> Initial build.
2. `n8n_update_partial_workflow` -> Iterative edits.
3. `n8n_validate_workflow` -> Final check.

## Critical: nodeType Formats

- **Search/Validate:** `nodes-base.slack` (Short prefix)
- **Create/Update:** `n8n-nodes-base.slack` (Full prefix)

## Best Practices
1. Use `get_node_essentials` (91% success) over `get_node_info`.
2. Specify `validation profile` (use "runtime").
3. Use **Smart Parameters** for connections (`branch: "true"`, `case: 0`).
4. Trust **Auto-Sanitization** for operator structures.
