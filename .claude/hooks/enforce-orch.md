---
name: enforce-orch-mode
events:
  - PreToolUse
enabled: true
---

# Enforce /orch Mode - Block Direct n8n MCP Access

## Purpose
Force Claude to ALWAYS use `/orch` for n8n tasks. Block all direct MCP calls to n8n-mcp tools.

## Rule
**ALL n8n MCP tools MUST go through `/orch` orchestrator!**

## Hook Logic

When tool use is about to execute:

1. **Check if tool is n8n MCP:**
   - Tool name starts with `mcp__n8n-mcp__` → n8n tool

2. **Check if context is /orch:**
   - Recent messages contain "## ROLE: Orchestrator" or "## ROLE: [Agent Name]"
   - OR conversation includes SlashCommand execution with "/orch"
   - OR I am a subagent spawned by orchestrator

3. **Decision:**
   - If n8n tool AND NOT from /orch → **BLOCK** ❌
   - Otherwise → **ALLOW** ✅

## Block Message

```
🚨 BLOCKED: Direct n8n MCP access not allowed!

Rule: ALL n8n workflow tasks MUST use /orch

Correct approach:
/orch <your task description>

Example:
/orch Fix FoodTracker workflow - commands /report and /stats not working

The orchestrator will delegate to proper agents:
- Analyst → diagnose
- Researcher → find solution
- Builder → fix via MCP
- QA → validate

DO NOT work with n8n directly!
```

## Exceptions (Allow)

- Tool is NOT n8n-mcp (e.g., Bash, Read, Grep) → allow
- Context shows "## ROLE: Builder" (subagent from orch) → allow
- Context shows "## ROLE: Researcher" (subagent from orch) → allow
- User explicitly disabled hook temporarily

## Implementation

Check tool name:
```javascript
if (tool.name.startsWith('mcp__n8n-mcp__')) {
  // Check context for /orch indicators
  const hasOrchContext =
    recentMessages.includes('## ROLE:') ||
    recentMessages.includes('/orch') ||
    isSubagentContext;

  if (!hasOrchContext) {
    // BLOCK with message
    return { block: true, message: BLOCK_MESSAGE };
  }
}

return { block: false }; // Allow
```

## Why This Hook Exists

**Problem:** Claude ignores "use /orch" instruction and works directly with n8n MCP.

**Root cause:**
- Instruction in CLAUDE.md is passive ("you should use...")
- No enforcement mechanism
- Claude forgets and works directly

**Solution:**
- Active enforcement via PreToolUse hook
- BLOCKS tool execution before it happens
- Forces correct workflow: User → /orch → Agents → MCP

**Result:**
- 100% compliance with /orch requirement
- All n8n tasks go through 5-agent system
- Proper diagnosis, planning, execution, validation
