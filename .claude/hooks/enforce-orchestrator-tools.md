---
name: enforce-orchestrator-tools
trigger: PreToolUse
enabled: true
priority: 100
---

# Enforce Orchestrator Tool Restrictions

## Purpose
**Orchestrator = PURE ROUTER** - can ONLY use Task/Read/Write/Bash.

Block ALL other tools (especially MCP) to enforce delegation pattern.

---

## Rule

Orchestrator can use **ONLY 4 tools:**
- ✅ `Task` - delegate to agents
- ✅ `Read` - read run_state, project files
- ✅ `Write` - update run_state
- ✅ `Bash` - jq for run_state manipulation

**ALL OTHER TOOLS → BLOCKED!**

---

## Hook Logic

```javascript
// Check if context is Orchestrator (NOT an agent)
const isOrchestrator = !conversation.includes('## ROLE: Architect') &&
                       !conversation.includes('## ROLE: Researcher') &&
                       !conversation.includes('## ROLE: Builder') &&
                       !conversation.includes('## ROLE: QA') &&
                       !conversation.includes('## ROLE: Analyst');

// Check tool being called
const allowedTools = ['Task', 'Read', 'Write', 'Bash'];
const toolName = tool.name;

// Detect MCP tools
const isMcpTool = toolName.startsWith('mcp__');

// Decision
if (isOrchestrator) {
  // Orchestrator context

  if (allowedTools.includes(toolName)) {
    // Allowed tool
    return { block: false };
  }

  if (isMcpTool) {
    // MCP tool - BLOCK with specific message
    return {
      block: true,
      message: MCP_BLOCK_MESSAGE
    };
  }

  // Other tool (AskUserQuestion, Glob, etc.) - BLOCK
  return {
    block: true,
    message: GENERAL_BLOCK_MESSAGE
  };
}

// Agent context - allow all tools
return { block: false };
```

---

## Block Messages

### MCP Tool Block

```
🚨 BLOCKED: Orchestrator cannot use MCP tools!

You are the ORCHESTRATOR (pure router).

FORBIDDEN:
- ❌ mcp__n8n-mcp__n8n_get_workflow
- ❌ mcp__n8n-mcp__n8n_executions
- ❌ mcp__n8n-mcp__search_nodes
- ❌ ANY mcp__n8n-mcp__* tool

ALLOWED ONLY:
- ✅ Task (delegate to agents)
- ✅ Read (run_state.json, project files)
- ✅ Write (run_state.json updates)
- ✅ Bash (jq for run_state)

YOUR JOB: Route, NOT execute!

ACTION REQUIRED:
Delegate via Task tool:

Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Researcher Agent

  Read: .claude/agents/researcher.md

  ## TASK
  [What you wanted to do with MCP]`
})

READ: .claude/agents/shared/orchestrator-cognitive-guards.md
```

### General Tool Block

```
🚨 BLOCKED: Orchestrator can only use Task/Read/Write/Bash!

You attempted to use: ${toolName}

ORCHESTRATOR ALLOWED TOOLS:
- ✅ Task - delegate to agents
- ✅ Read - read files
- ✅ Write - update run_state
- ✅ Bash - jq operations

FORBIDDEN:
- ❌ ${toolName}
- ❌ AskUserQuestion (agents ask user, not orchestrator)
- ❌ Glob, Grep (use Task → agent instead)
- ❌ WebSearch (use Task → Architect)

YOUR ROLE: Router ONLY

If you need data → Delegate via Task!
If you need to ask user → Architect asks!
If you need to search → Researcher searches!

READ: .claude/ORCHESTRATOR-STRICT-MODE.md
```

---

## Context Detection

### Orchestrator Context (BLOCK non-allowed tools)

Conversation does NOT contain:
- `## ROLE: Architect`
- `## ROLE: Researcher`
- `## ROLE: Builder`
- `## ROLE: QA`
- `## ROLE: Analyst`

AND conversation MAY contain:
- `/orch` command
- `## Orchestrator`
- Or no role marker (main conversation)

### Agent Context (ALLOW all tools)

Conversation DOES contain one of:
- `## ROLE: Architect Agent`
- `## ROLE: Researcher Agent`
- `## ROLE: Builder Agent`
- `## ROLE: QA Agent`
- `## ROLE: Analyst Agent`

This means we're in a Task-spawned subagent → allow all tools.

---

## Examples

### ❌ BLOCKED: Orchestrator using MCP

```javascript
// Context: /orch session (no "## ROLE:" marker)

// Orchestrator thinks: "Let me get workflow data"
const workflow = await mcp__n8n-mcp__n8n_get_workflow({
  id: "abc123"
})

// Hook triggers: BLOCKED!
// Message: "Orchestrator cannot use MCP tools! Delegate via Task"
```

### ✅ ALLOWED: Agent using MCP

```javascript
// Context: Task spawned with "## ROLE: Researcher Agent"

const workflow = await mcp__n8n-mcp__n8n_get_workflow({
  id: "abc123"
})

// Hook checks: "## ROLE: Researcher" present
// Decision: ALLOW (agent context)
```

### ❌ BLOCKED: Orchestrator using AskUserQuestion

```javascript
// Context: /orch session

const answer = await AskUserQuestion({
  question: "Which workflow?"
})

// Hook triggers: BLOCKED!
// Message: "AskUserQuestion forbidden for orchestrator! Architect asks user."
```

### ✅ ALLOWED: Orchestrator using Task

```javascript
// Context: /orch session

Task({
  subagent_type: "general-purpose",
  prompt: "## ROLE: Researcher\n..."
})

// Hook checks: Task in allowed list
// Decision: ALLOW
```

---

## Implementation Notes

1. **Priority: 100** - Run BEFORE other hooks (highest priority)

2. **Context detection:**
   - Check recent messages for "## ROLE:" markers
   - No role marker = Orchestrator context
   - Has role marker = Agent context

3. **Tool whitelist:**
   - Orchestrator: `['Task', 'Read', 'Write', 'Bash']`
   - Agents: all tools allowed

4. **MCP detection:**
   - Any tool starting with `mcp__` = MCP tool
   - Show specific MCP block message

5. **False positives:**
   - If legitimate case blocked → user can temporarily disable hook
   - Or refactor code to use delegation

---

## Why This Hook Exists

**Problem:** Orchestrator bypasses delegation system

**Symptoms:**
- "Let me quickly check workflow..." → calls MCP directly
- "I'll validate this..." → bypasses QA agent
- "Faster if I do it..." → ignores agent boundaries

**Root cause:**
- Instructions in prompt are passive ("you should...")
- No technical enforcement
- LLM optimizes for speed, not protocol

**Solution:**
- PreToolUse hook = **physical block**
- Intercepts tool call BEFORE execution
- Forces correct pattern: Orchestrator → Task → Agent → MCP

**Result:**
- 100% enforcement of router role
- All data fetching goes through agents
- Proper validation gates (can't bypass by calling MCP directly)

---

## Related Hooks

- **enforce-orch.md** - Forces `/orch` usage for n8n tasks
- **block-full-update.md** - Forces surgical edits (Builder only)
- **enforce-context-update.md** - Triggers Analyst after Builder success

---

## Rollback

If this hook causes problems:

```yaml
# Edit .claude/hooks/enforce-orchestrator-tools.md
---
enabled: false  # Disable hook
---
```

Or delete the file.

---

**Remember:** This hook is CRITICAL for system integrity. Do not disable without understanding implications!
