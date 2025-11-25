# Context Passing Between Agents

> **Quick reference for passing context between SubAgents**

---

## 🎯 The Problem

Each subagent runs in **isolated context** (separate conversation). They DON'T see:
- What project-manager is doing
- What other subagents did
- Project structure
- Previous tasks

**Solution:** Pass minimal necessary context in Task prompt.

---

## 📋 Context Passing Templates

### Template 1: Project Manager → Orchestrator

**When to use:** PM delegates a task to orchestrator

```markdown
## Task Context (from Project Manager)

**Project:** [project name]
**Phase:** [phase name] ([progress]% complete)
**Current Task:** [task title]
**GitHub Issue:** #[issue number]

**Project Structure:**
- Repo: [absolute path]
- Agents: .claude/agents/*.md ([N] existing)
- Docs: docs/*.md
- Key files: [critical files to read]

**Critical patterns (must follow):**
- [Pattern 1 - e.g., Never Trust Defaults]
- [Pattern 2 - e.g., Templates-first approach]
- [Pattern 3 - e.g., Multi-level validation]

**Your task:**
[Clear, specific task description]

**Expected result:**
- [File/output 1]
- [File/output 2]
- [Quality criteria]

**Return to PM when done for approval.**
```

**Example:**

```markdown
## Task Context (from Project Manager)

**Project:** SubAgents Multi-Agent System
**Phase:** Phase 2 - Interactive Mode (80% complete)
**Current Task:** Create credentials-manager subagent
**GitHub Issue:** #125

**Project Structure:**
- Repo: /Users/sergey/Projects/SubAgents
- Agents: .claude/agents/*.md (18 existing)
- Docs: docs/*.md
- Key files: ARCHITECTURE.md, SUBAGENTS-GUIDE.md

**Critical patterns (must follow):**
- Never Trust Defaults (all params explicit)
- Templates-first approach
- Multi-level validation
- A2A logging for all delegations

**Your task:**
Create credentials-manager subagent that automatically copies credentials from existing n8n workflows.

**Expected result:**
- File: .claude/agents/credentials-manager.md
- Follow format from SUBAGENTS-GUIDE.md
- Update orchestrator routing rules
- Test with /orch command

**Return to PM when done for approval.**
```

---

### Template 2: Orchestrator → Specialist

**When to use:** Orchestrator delegates to specialist subagent

```markdown
## Task Context (from Orchestrator)

**User request:** [original user request]
**Template found:** [template ID and name, if applicable]

**Workflow plan:**
[Brief plan - numbered list of nodes/steps]

**Your specific task:**
[Clear, specific task for this specialist]

[Details specific to the task]

**Critical:**
- [Critical constraint 1]
- [Critical constraint 2]
- [Critical constraint 3]

**Return to orchestrator when done.**
```

**Example:**

```markdown
## Task Context (from Orchestrator)

**User request:** Create webhook that sends to Slack
**Template found:** #2414 (Webhook to Slack - 98% match)

**Workflow plan:**
1. Webhook node (POST, path: /slack-webhook)
2. IF node (check message.text exists)
3. Slack node (send to #general)

**Your specific task:**
Configure these 3 nodes with EXPLICIT parameters:

1. Webhook node:
   - httpMethod: POST
   - path: /slack-webhook
   - responseMode: onReceived

2. IF node:
   - conditions: {{ $json.message?.text !== undefined }}

3. Slack node:
   - resource: message
   - operation: post
   - channel: #general
   - text: {{ $json.message.text }}

**Critical:**
- ALL parameters explicit (Never Trust Defaults!)
- Use credentials-manager for Slack auth
- Return node configs as JSON

**Return to orchestrator when done.**
```

---

### Template 3: Specialist → Specialist (via Orchestrator)

**When to use:** Specialist needs help from another specialist

**Step 1:** Specialist → Orchestrator (request)

```markdown
## Request from [agent name]

I need [what you need].

**Context:**
- [Key context item 1]
- [Key context item 2]
- [Key context item 3]

**Task for [target specialist]:**
[Clear task description]

**Return [what data/format] to me ([agent name]).**
```

**Step 2:** Orchestrator → Target Specialist (delegation)

```markdown
## Task from Orchestrator (delegated by [requesting agent])

**Workflow:** [workflow name/description]
**Node type:** [if applicable]
**Required:** [what's needed]

**Your task:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Return to orchestrator → [requesting agent].**
```

**Example:**

```markdown
## Request from node-engineer

I need credentials for Slack node.

**Context:**
- Workflow: Webhook to Slack
- Node: Slack (resource: message, operation: post)
- Required credential type: slackOAuth2Api

**Task for credentials-manager:**
Find available Slack credentials in n8n and ask user which to use.

**Return credential ID to me (node-engineer).**
```

Then orchestrator passes to credentials-manager:

```markdown
## Task from Orchestrator (delegated by node-engineer)

**Workflow:** Webhook to Slack
**Node type:** n8n-nodes-base.slack
**Required credential:** slackOAuth2Api

**Your task:**
1. List available Slack credentials in n8n
2. Ask user which credential to use
3. Return credential ID

**Return to orchestrator → node-engineer.**
```

---

### Template 4: Request-Response Pattern (Specialist → Orchestrator)

**When to use:** Specialist needs user input or function calls (AskUserQuestion, WebSearch, etc.)

**⚠️ CRITICAL:** Agents in Task subprocess **CANNOT** execute function calls directly. Use this pattern instead.

**Step 1:** Specialist returns structured request

```json
{
  "status": "needs_user_input",
  "questions": [
    {
      "id": "param_id",
      "question": "Clear question text?",
      "type": "text|select|multiselect",
      "required": true,
      "options": ["Option 1", "Option 2"],
      "default": "Option 1"
    }
  ],
  "partial_result": {
    "completed_steps": ["step 1", "step 2"],
    "pending_params": ["param_id"]
  }
}
```

**Step 2:** Orchestrator executes AskUserQuestion

```javascript
const answers = await AskUserQuestion({
  questions: specialistResponse.questions.map(q => ({
    question: q.question,
    header: "Configuration",
    multiSelect: q.type === "multiselect",
    options: q.options?.map(opt => ({label: opt, value: opt}))
  }))
});
```

**Step 3:** Orchestrator re-delegates with answers

```markdown
## Task Context (from Orchestrator - continued)

**Previous state:**
${JSON.stringify(specialistResponse.partial_result)}

**User answers:**
${JSON.stringify(answers)}

**Your task:**
Continue from where you left off with the user's input.

**Return final result to orchestrator.**
```

**Example: node-engineer needs Slack channel**

```json
{
  "status": "needs_user_input",
  "questions": [
    {
      "id": "slack_channel",
      "question": "Which Slack channel should receive notifications?",
      "type": "select",
      "required": true,
      "options": ["#general", "#alerts", "#logs"],
      "default": "#general"
    },
    {
      "id": "message_format",
      "question": "Message format?",
      "type": "select",
      "options": ["Simple text", "Rich blocks", "Markdown"],
      "default": "Simple text"
    }
  ],
  "partial_result": {
    "nodes_configured": ["webhook-1"],
    "pending_nodes": ["slack-1"],
    "pending_params": ["slack.channel", "slack.text"]
  }
}
```

Then orchestrator asks user and re-delegates:

```markdown
## Task Context (from Orchestrator - continued)

**User request:** Create webhook that sends to Slack
**Previous state:**
- Configured nodes: webhook-1
- Pending nodes: slack-1
- Pending params: slack.channel, slack.text

**User answers:**
- Slack channel: #general
- Message format: Simple text

**Your task:**
Complete Slack node configuration:
- channel: #general
- text: {{ $json.message }} (simple text format)

**Critical:**
- ALL parameters explicit (Never Trust Defaults!)
- Return final node configs as JSON

**Return final result to orchestrator.**
```

---

## ✅ What to Include

**Always include:**
1. ✅ **From/To** - Who's asking, who should respond
2. ✅ **Original user request** - Why this task exists
3. ✅ **Specific task** - What exactly to do
4. ✅ **Critical constraints** - Never Trust Defaults, etc.
5. ✅ **Expected output** - Format, where to return

**Include if relevant:**
6. ✅ **Project context** - Phase, progress (from PM)
7. ✅ **Structure** - Repo paths, key files (from PM)
8. ✅ **Template** - If found by architect
9. ✅ **Workflow plan** - Overall picture (from orchestrator)
10. ✅ **Return path** - Who needs the result

---

## ❌ What NOT to Include

**Never include:**
1. ❌ **Entire PLAN.md** - Too much, PM has it cached
2. ❌ **Entire TODO.md** - Not needed by specialists
3. ❌ **Code of other agents** - Each agent has own instructions
4. ❌ **General instructions** - Already in agent.md files
5. ❌ **Full architecture** - Too verbose, not needed

**Keep it:**
- ✅ **Minimal** - Only what's needed
- ✅ **Sufficient** - Enough to complete task
- ✅ **Clear** - No ambiguity
- ✅ **Actionable** - Specific steps/requirements

---

## 🔄 Full Chain Example

**User:** `/pm continue` → "Create credentials-manager"

### 1. PM → Orchestrator

```markdown
## Task Context (from Project Manager)

**Project:** SubAgents Multi-Agent System
**Phase:** Phase 2 (80% complete)
**Current Task:** Create credentials-manager subagent
**GitHub Issue:** #125

**Project Structure:**
- Repo: /Users/sergey/Projects/SubAgents
- Agents: .claude/agents/*.md (18 existing)
- Key files: docs/SUBAGENTS-GUIDE.md, .claude/agents/orchestrator.md

**Critical patterns:**
- Follow SUBAGENTS-GUIDE.md format
- Update orchestrator routing rules
- A2A logging

**Your task:**
Create credentials-manager subagent.

**Return to PM for approval.**
```

### 2. Orchestrator asks user (if task unclear)

**Note:** orchestrator now handles user questions directly (v3.0.0+)

```javascript
// orchestrator uses AskUserQuestion directly
const answers = await AskUserQuestion({
  questions: [{
    question: "Which credential types should credentials-manager support?",
    header: "Clarify Requirements",
    multiSelect: true,
    options: [
      {label: "OAuth2", value: "oauth2"},
      {label: "API Keys", value: "apiKey"},
      {label: "Basic Auth", value: "basicAuth"},
      {label: "All types", value: "all"}
    ]
  }, {
    question: "Auto-select credentials or always ask user?",
    header: "Behavior",
    multiSelect: false,
    options: [
      {label: "Auto-select if only one available", value: "auto"},
      {label: "Always ask user", value: "ask"}
    ]
  }]
});

// Then proceeds with user's answers
```

### 3. Orchestrator → Architect

```markdown
## Task Context (from Orchestrator)

**User request:** Create credentials-manager subagent
**Project:** SubAgents

**Your task:**
Find similar subagent examples in docs/SUBAGENTS-GUIDE.md and existing .claude/agents/*.md files.

**Return best practices for:**
- YAML frontmatter format
- Tools selection
- Model choice (haiku vs sonnet)

**Return to orchestrator.**
```

### 4. Orchestrator → PM (completion)

```markdown
## Result from Orchestrator

**Task:** Create credentials-manager
**Status:** Completed

**Files created:**
- .claude/agents/credentials-manager.md (350 lines)

**Changes made:**
- Created agent with YAML frontmatter
- Added routing rule to orchestrator.md
- Follows SUBAGENTS-GUIDE.md format

**Quality checks:**
✅ YAML valid
✅ Tools correct (n8n-mcp tools)
✅ Model: haiku (fast, low cost)
✅ Follows project patterns

**Ready for user review.**
```

### 5. PM → User

```
Task completed!

Result:
- File: .claude/agents/credentials-manager.md
- 350 lines
- Features: Auto credential setup

Accept? [Y/N]
```

---

## 🎯 Key Principles

### 1. Minimal but Sufficient

```markdown
✅ GOOD (minimal):
Project: SubAgents
Task: Create credentials-manager
Structure: .claude/agents/*.md
Pattern: Never Trust Defaults

❌ BAD (too much):
[Copies entire PLAN.md, TODO.md, ARCHITECTURE.md]
```

### 2. Clear Task Definition

```markdown
✅ GOOD (clear):
Your task: Configure Slack node with explicit parameters
- resource: message
- operation: post
- channel: #general

❌ BAD (vague):
Your task: Configure Slack node properly
```

### 3. Critical Info Only

```markdown
✅ GOOD:
Critical:
- Never Trust Defaults
- Use credentials-manager for auth

❌ BAD:
Critical:
- Be nice to user
- Write good code
- [10 more generic rules]
```

### 4. Return Path

```markdown
✅ GOOD:
Return credential ID to orchestrator → node-engineer

❌ BAD:
Return the result
```

---

## 📊 Context Size Guidelines

**Project Manager → Orchestrator:** 150-300 words
- Project name
- Phase & progress
- Repo structure
- Critical patterns
- Specific task

**Orchestrator → Specialist:** 100-200 words
- Original user request
- Template (if found)
- Workflow plan
- Specific task
- Critical constraints

**Specialist → Specialist:** 50-100 words
- What you need
- Minimal context
- Return format

**Rule:** If context > 300 words, you're probably including too much!

---

## 🚨 Common Mistakes

### Mistake 1: No Original Request

```markdown
❌ BAD:
Your task: Configure Slack node

✅ GOOD:
User request: Create webhook that sends to Slack
Your task: Configure Slack node (part of webhook→slack workflow)
```

### Mistake 2: Losing Critical Patterns

```markdown
❌ BAD:
Your task: Configure nodes

✅ GOOD:
Your task: Configure nodes
Critical: Never Trust Defaults - ALL parameters explicit
```

### Mistake 3: No Return Path

```markdown
❌ BAD:
Your task: Find credentials

✅ GOOD:
Your task: Find credentials
Return: credential ID to orchestrator → node-engineer
```

### Mistake 4: Too Much Context

```markdown
❌ BAD:
[Copies entire PLAN.md with all 50 tasks]
Your task: Create one agent

✅ GOOD:
Project: SubAgents, Phase 2 (80%)
Your task: Create credentials-manager agent
```

---

## 🎓 Best Practices

1. **Start with template** - Use one of the 3 templates above
2. **Original request first** - Always include why task exists
3. **Be specific** - Clear, actionable task description
4. **Critical patterns** - Never Trust Defaults, etc.
5. **Return path** - Who needs the result
6. **Test the context** - Can specialist complete task with just this info?

---

## 📚 See Also

- **CLAUDE.md** - Section "🔄 Context Passing Between Agents"
- **A2A-PROTOCOL.md** - Logging agent interactions
- **SUBAGENTS-GUIDE.md** - How to create subagents
- **docs/TOKEN-ECONOMY.md** - Why minimal context matters (token optimization!)

---

**Context passing = успех задачи! 🚀**
