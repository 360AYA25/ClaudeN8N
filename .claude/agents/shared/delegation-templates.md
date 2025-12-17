# Agent Delegation Templates

> **Purpose:** Standard patterns for delegating to agents via Task tool
> **Usage:** Copy template, fill parameters, execute
> **Context:** All agents run via workaround for Issue #7296 (use general-purpose + role in prompt)

---

## 🎯 DELEGATION PROTOCOL

### Standard Pattern

```javascript
Task({
  subagent_type: "general-purpose",
  model: "opus",  // ONLY for Builder! Others use default (sonnet)
  prompt: `## ROLE: [Agent Name] Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/[agent].md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

## TASK
[Specific task description]`
})
```

---

## 🏗️ ARCHITECT (Planning & Dialog)

### Phase 1: Clarification

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Architect Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/architect.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

## TASK: Clarify Requirements

User request: "${user_request}"

Your job:
1. Ask clarifying questions (use AskUserQuestion tool)
2. Understand goal, constraints, services needed
3. Write requirements to run_state

Output:
- requirements: {goal, services, constraints, success_criteria}
- research_request: {hypothesis, search_criteria}

Return summary to orchestrator.`
})
```

### Phase 3: Present Options & Get Decision

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Architect Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/architect.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Research findings available in run_state.research_findings

## TASK: Present Options to User

Based on research findings, present:
1. Option A: Modify existing (if fit_score > 80%)
2. Option B: Build from template (if relevant template found)
3. Option C: Build from scratch

For MODIFY: Include IMPACT ANALYSIS (L-053 protocol)

Use AskUserQuestion to get decision.

After user chooses:
- Write decision to run_state
- Create blueprint (high-level design)
- Present credential options (from credentials_discovered)

Return summary to orchestrator.`
})
```

---

## 🔍 RESEARCHER (Search & Discovery)

### Phase 2: Research

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Researcher Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/researcher.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Research request available in run_state.research_request

## TASK: Search for Solutions

Search priority:
1. Local existing workflows (list_workflows + similarity check)
2. n8n templates (search_templates)
3. Individual nodes (search_nodes)

For each candidate:
- Calculate fit_score (0-100%)
- Check popularity (template downloads, node usage)
- Note gotchas from LEARNINGS.md

Output to: ${project_path}/memory/agent_results/research_findings.json
- hypothesis_validated: bool
- candidates: [{type, name, fit_score, popularity, url}]
- recommendation: "modify_existing" | "use_template" | "build_new"

Return summary to orchestrator.`
})
```

### Phase 3.5: Discover Credentials

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Researcher Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/researcher.md

## TASK: Discover Available Credentials

Services needed: ${services}

Use: mcp__n8n-mcp__n8n_discover_credentials
- Scan existing workflows for credential usage
- Group by service type
- Return credential names (NOT values!)

Output to run_state:
- credentials_discovered: {service: [credential_names]}

Orchestrator will pass to Architect to present to user.

Return summary to orchestrator.`
})
```

### Phase 4: Deep Dive (Implementation Research)

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Researcher Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/researcher.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

User decision and blueprint available in run_state

## TASK: Implementation Research

Study:
1. LEARNINGS.md - relevant gotchas for chosen services/nodes
2. PATTERNS.md - architectural patterns to follow
3. get_node() - detailed configs for key nodes

Output to: ${project_path}/memory/agent_results/build_guidance.json
- gotchas: [{issue, solution, learning_id}]
- node_configs: [{node_type, critical_params, example}]
- warnings: [string]
- expected_changes: [{node, parameter, value}] (for post-build verification)

Return summary to orchestrator.`
})
```

---

## 🏗️ BUILDER (ONLY Agent That Mutates Workflows)

### Phase 5: Build Workflow

```javascript
Task({
  subagent_type: "general-purpose",
  model: "opus",  // ⚠️ Builder uses Opus 4.5!
  prompt: `## ROLE: Builder Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/builder.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Blueprint and build_guidance available in run_state

## TASK: Create Workflow

Based on blueprint, create workflow using:
- n8n_create_workflow (if new)
- n8n_update_partial_workflow (if modify)

CRITICAL:
1. Read build_guidance gotchas FIRST
2. Follow L-075 anti-hallucination protocol
3. Use surgical edits only (L-053)
4. Log ALL mcp_calls in result

Output to: ${project_path}/memory/agent_results/build_result.json
- workflow: {id, name, nodes, connections}
- mcp_calls: [{tool, params, result}]
- verified: bool (called n8n_get_workflow to verify)

Return summary to orchestrator.`
})
```

### QA Loop: Fix Issues

```javascript
Task({
  subagent_type: "general-purpose",
  model: "opus",  // Builder uses Opus
  prompt: `## ROLE: Builder Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/builder.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

QA report available in run_state.qa_report
edit_scope available in run_state.edit_scope

Cycle: ${cycle_count}

## TASK: Fix Issues Per edit_scope

QA found issues. Fix ONLY nodes in edit_scope.

Use: n8n_update_partial_workflow
- operations: [updateNode/addNode/deleteNode per edit_scope]

${cycle_count >= 2 ? `
⚠️ PREVIOUS ATTEMPTS (don't repeat!):
${recent_builder_actions}

Try a DIFFERENT approach!
` : ''}

CRITICAL:
- Log mcp_calls
- Verify with n8n_get_workflow

Return summary to orchestrator.`
})
```

---

## ✅ QA (Validation & Testing)

### Phase 5: Validate & Test

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: QA Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/qa.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Workflow available in run_state.workflow

## TASK: Validate Workflow

Phases:
1. Schema validation (n8n_validate_workflow)
2. Config checks (node connections, credentials)
3. Anti-pattern detection (L-060, L-056, etc.)
4. LEARNINGS.md gotcha checks
5. **Phase 5: REAL EXECUTION TEST** (mandatory!)

Use: n8n_test_workflow or n8n_trigger_workflow
- Verify actual execution works
- Check execution logs

Output to: ${project_path}/memory/agent_results/qa_report.json
- status: "PASS" | "FAIL"
- errors: [{node, issue, severity}]
- edit_scope: [node_names] (if FAIL)
- phase_5_executed: true (REQUIRED for PASS)

Return summary to orchestrator.`
})
```

---

## 📊 ANALYST (Read-Only Forensics)

### Execution Analysis (GATE 2)

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Analyst Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/analyst.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Workflow ID: ${workflow_id}

## TASK: Analyze Execution History

Use: n8n_executions
- Get last 10 executions
- Identify failure patterns
- Find stopping point (which node fails)
- Extract error messages

CRITICAL (L-060):
If Code node never executes:
- Read Code node configuration
- Check for deprecated $node["..."] syntax
- Check for 300s timeout signature

Output to run_state:
- execution_analysis: {
    completed: true,
    last_10_status: [bool],
    failure_rate: percent,
    stopping_node: string,
    root_cause_hypothesis: string,
    errors: [{execution_id, node, error}]
  }

Return summary to orchestrator.`
})
```

### Post-Mortem (After Build Success)

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Analyst Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/analyst.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

Workflow successfully built and tested.

## TASK: Update Project Context

Per context-update.md protocol:

1. Update ${project_path}/.context/2-INDEX.md
   - Add entry to "Recent Changes" table
   - Update workflow version

2. Update ${project_path}/.context/SYSTEM-CONTEXT.md (if exists)
   - Update workflow version
   - Update node count
   - Update execution health

3. Update ADRs if architectural decision made

4. Update state.json with current workflow state

Return summary to orchestrator.`
})
```

### L4 Escalation (After 7 QA Failures)

```javascript
Task({
  subagent_type: "general-purpose",
  prompt: `## ROLE: Analyst Agent

Read your instructions from:
/Users/sergey/Projects/ClaudeN8N/.claude/agents/analyst.md

## CONTEXT
Read current state from: ${project_path}/memory/run_state_active.json

7 QA cycles failed. System is BLOCKED.

## TASK: Methodology Audit

Analyze entire run_state history:
- What approaches were tried?
- Why did each fail?
- Was execution analysis done? (GATE 2 check)
- Was hypothesis validated? (GATE 6 check)
- Pattern: repeating same fix?

Output:
- root_cause: string
- methodology_violations: [string]
- proposed_learnings: [{problem, solution, files}]
- recommendation: string

Present to user for decision.

Return detailed report.`
})
```

---

## 📝 COMMON PARAMETERS

### Project Path Detection

```bash
# Read from run_state
project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state_active.json)

# Or detect from workflow ID (if known)
# ... lookup logic ...
```

### Context Passing

**Agents read context from:**
- `${project_path}/memory/run_state_active.json` - current state
- `${project_path}/.context/` - project-specific docs

**Orchestrator only passes:**
- Task description
- Current cycle count (if QA loop)
- Recent actions (if cycle 2+)

**Agents write results to:**
- `${project_path}/memory/agent_results/[agent]_result.json`
- Orchestrator merges back to run_state

---

## ⚠️ CRITICAL NOTES

1. **Model Selection:**
   - Builder: `model: "opus"` (REQUIRED!)
   - All others: default (sonnet)

2. **Workaround #7296:**
   - Custom agents can't use tools
   - Solution: `subagent_type: "general-purpose"` + role in prompt

3. **Context Isolation:**
   - Each Task call = NEW process
   - Agents DON'T see previous agent's context
   - Exchange via run_state files ONLY

4. **MCP Logging:**
   - ALL agents MUST log mcp_calls in result
   - Orchestrator checks via L-073 protocol

5. **Return Format:**
   - Agents return SUMMARY (~500 tokens max)
   - Full data in agent_results/ files
   - Orchestrator merges to run_state

---

## 📖 RELATED PROTOCOLS

- **Anti-hallucination:** `.claude/agents/shared/L-075-anti-hallucination.md`
- **Surgical edits:** `.claude/agents/shared/surgical-edits.md`
- **Context update:** `.claude/agents/shared/context-update.md`
- **Validation gates:** `.claude/agents/validation-gates.md`
- **run_state management:** `.claude/agents/shared/run-state-lib.sh`
