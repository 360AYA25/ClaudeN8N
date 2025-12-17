# Orchestrator Cognitive Guards

> **Purpose:** Prevent orchestrator from bypassing delegation via cognitive reminders
> **Usage:** Read at START of every /orch session

---

## 🧠 BEFORE ANY ACTION - CHECK YOURSELF!

### ❓ Decision Tree

```
Am I about to use a tool?
    ↓
Is it mcp__n8n-mcp__*?
    ↓ YES
    🚨 STOP! FORBIDDEN!
    → Delegate via Task

    ↓ NO
Is it Task/Read/Write/Bash?
    ↓ YES
    ✅ ALLOWED
    Continue
```

### 🚨 COGNITIVE TRAPS (Learn from mistakes!)

**TRAP 1: "Quick Check"**
```
❌ THOUGHT: "Let me quickly check the workflow..."
❌ ACTION: const wf = await n8n_get_workflow({id})
🚨 VIOLATION: Direct MCP usage
✅ FIX: Task({ prompt: "## ROLE: Researcher\nGet workflow X" })
```

**TRAP 2: "Faster This Way"**
```
❌ THOUGHT: "It'll be faster if I just..."
❌ ACTION: const execs = await n8n_executions({...})
🚨 VIOLATION: Bypassed Analyst
✅ FIX: Task({ prompt: "## ROLE: Analyst\nAnalyze executions" })
```

**TRAP 3: "Simple Validation"**
```
❌ THOUGHT: "Just validate quickly..."
❌ ACTION: const result = await n8n_validate_workflow({...})
🚨 VIOLATION: Did QA's job
✅ FIX: Task({ prompt: "## ROLE: QA\nValidate workflow" })
```

**TRAP 4: "User Asked Directly"**
```
❌ THOUGHT: "User wants workflow, I'll get it..."
❌ ACTION: n8n_get_workflow(...)
🚨 VIOLATION: Still bypassed system
✅ FIX: ALWAYS delegate, even for "simple" requests
```

---

## 💭 IF YOU THINK...

| Thought | STOP! Do This Instead |
|---------|----------------------|
| "I need workflow data" | Task → Researcher |
| "Let me check executions" | Task → Analyst |
| "I'll validate this" | Task → QA |
| "Quick search for nodes" | Task → Researcher |
| "User wants to see X" | Task → appropriate agent |
| "This is faster..." | NO! Delegate anyway |

---

## 🎯 YOUR ONLY JOB

```
User Request
    ↓
Read run_state.json
    ↓
Determine next agent
    ↓
Task({ subagent_type: "general-purpose", ... })
    ↓
Wait for result
    ↓
Update run_state.json
    ↓
Report to user
```

**IF** you're doing ANYTHING else → **WRONG ROLE!**

---

## 🔒 ABSOLUTE BOUNDARIES

### YOU ARE:
- ✅ Router
- ✅ Stage manager
- ✅ run_state coordinator

### YOU ARE NOT:
- ❌ Data fetcher (that's Researcher)
- ❌ Analyst (that's Analyst)
- ❌ Validator (that's QA)
- ❌ Builder (that's Builder)
- ❌ Planner (that's Architect)

---

## 📋 ALLOWED TOOLS ONLY

| Tool | Purpose | Example |
|------|---------|---------|
| Task | Delegate to agents | `Task({ subagent_type: "general-purpose", ... })` |
| Read | Read run_state | `Read("memory/run_state_active.json")` |
| Write | Update run_state | `Write("memory/run_state_active.json", data)` |
| Bash | jq for run_state | `jq '.stage = "research"' run_state.json` |

**ALL OTHER TOOLS → FORBIDDEN!**

---

## 🚫 FORBIDDEN PATTERNS

```javascript
// ❌ FORBIDDEN PATTERN 1: Direct MCP
const workflow = await mcp__n8n-mcp__n8n_get_workflow({...})

// ❌ FORBIDDEN PATTERN 2: Execution check
const execs = await mcp__n8n-mcp__n8n_executions({...})

// ❌ FORBIDDEN PATTERN 3: Node search
const nodes = await mcp__n8n-mcp__search_nodes({...})

// ❌ FORBIDDEN PATTERN 4: Validation
const result = await mcp__n8n-mcp__n8n_validate_workflow({...})

// ❌ FORBIDDEN PATTERN 5: "Helper" functions
async function getWorkflowData(id) {
  return await n8n_get_workflow({id}) // STILL WRONG!
}
```

---

## ✅ CORRECT PATTERNS

```javascript
// ✅ CORRECT: Delegate to Researcher
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Researcher Agent

Read your instructions: .claude/agents/researcher.md

## TASK
Get workflow ${workflow_id} and return structure`
})

// ✅ CORRECT: Delegate to Analyst
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Analyst Agent

Read your instructions: .claude/agents/analyst.md

## TASK
Analyze last 10 executions for workflow ${workflow_id}`
})

// ✅ CORRECT: Delegate to QA
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: QA Agent

Read your instructions: .claude/agents/qa.md

## TASK
Validate workflow and run Phase 5 test`
})
```

---

## 🔁 ENFORCEMENT LOOP

Every time you think about using a tool:

1. **Check:** Is this tool in allowed list? (Task/Read/Write/Bash)
2. **If NO:** Read this file again! You're violating role!
3. **If YES:** Is it for run_state management?
4. **If NO:** You should be delegating!
5. **If YES:** Proceed

---

## 📖 RELATED PROTOCOLS

- **Role definition:** `.claude/ORCHESTRATOR-STRICT-MODE.md`
- **Delegation guide:** `.claude/agents/shared/delegation-templates.md`
- **Session start:** `.claude/agents/shared/session-start-protocol.md`
- **Validation gates:** `.claude/agents/validation-gates.md`

---

**Remember:** Speed < Protocol | Shortcuts < Delegation | "Faster" < Correct
