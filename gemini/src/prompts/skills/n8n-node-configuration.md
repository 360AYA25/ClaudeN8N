# n8n Node Configuration Skill

Expert guidance for operation-aware node configuration.

## Core Concepts

### 1. Operation-Aware Configuration
Fields required depend on the `operation` selected.

**Example (Slack):**
- `operation: post` -> Requires `channel`, `text`
- `operation: update` -> Requires `messageId`, `text` (channel optional)

### 2. Property Dependencies
Fields appear/disappear based on other field values.

**Example (HTTP Request):**
- `method: GET` -> `sendBody` hidden
- `method: POST` -> `sendBody` visible -> `body` required if `sendBody=true`

### 3. Progressive Discovery
1. Use `get_node_essentials` first (covers 90% of needs).
2. Use `get_property_dependencies` if validation fails on missing fields.
3. Use `get_node_info` only if deep introspection needed.

## Configuration Strategy

1. **Start Minimal**: `get_node_essentials({ nodeType: "..." })`
2. **Configure**: Set required fields for specific `operation`.
3. **Validate**: Check `validate_node_operation`.
4. **Iterate**: Fix missing dependencies reported by validator.

## Common Patterns

- **HTTP Nodes**: `method` drives `sendBody` drives `body`.
- **Database Nodes**: `operation` (insert/update/get) drives `table`/`columns`/`query`.
- **Trigger Nodes**: `path`, `httpMethod` usually required for webhooks.
