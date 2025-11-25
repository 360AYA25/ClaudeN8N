# Architecture

## Overview

ClaudeN8N integrates Claude Code with n8n workflow automation.

## Components

```
┌─────────────────┐     ┌─────────────────┐
│   Claude Code   │────▶│    n8n-mcp      │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   n8n Instance  │
                        └─────────────────┘
```

## MCP Integration

The project uses n8n-mcp server for:
- Workflow CRUD operations
- Node configuration
- Execution management
- Credential handling

## Data Flow

1. User request → Claude Code
2. Claude Code → n8n-mcp (via MCP protocol)
3. n8n-mcp → n8n API
4. Response back through chain
