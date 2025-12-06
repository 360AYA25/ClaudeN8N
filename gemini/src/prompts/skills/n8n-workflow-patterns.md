# n8n Workflow Patterns

Proven architectural patterns for building n8n workflows.

## The 5 Core Patterns

### 1. Webhook Processing (Most Common)
**Pattern:** `Webhook -> Validate -> Transform -> Respond`
**Use when:** Receiving data (Stripe, Slack commands).
**Key:** Always respond quickly (within 3s) or use "Respond to Webhook" node early.

### 2. HTTP API Integration
**Pattern:** `Trigger -> HTTP Request -> Transform -> Action -> Error Handler`
**Use when:** Fetching data from REST APIs.
**Key:** Handle pagination and rate limits.

### 3. Database Operations
**Pattern:** `Schedule -> Query -> Transform -> Write -> Verify`
**Use when:** Syncing data (ETL).
**Key:** Use batching for large datasets.

### 4. AI Agent Workflow
**Pattern:** `Trigger -> AI Agent (Model + Tools + Memory) -> Output`
**Use when:** Chatbots, reasoning tasks.
**Key:** Use `Window Buffer Memory` to manage context window.

### 5. Scheduled Tasks
**Pattern:** `Schedule -> Fetch -> Process -> Deliver -> Log`
**Use when:** Reporting, cleanup.
**Key:** Add "Error Trigger" node to notify on failure.

## Common Gotchas

1. **Webhook Data**: It's under `$json.body`, not `$json` root.
2. **Multiple Items**: Nodes process ALL input items. Use `Execute Once` if needed.
3. **Execution Order**: Always check connections. v1 engine is connection-based.
