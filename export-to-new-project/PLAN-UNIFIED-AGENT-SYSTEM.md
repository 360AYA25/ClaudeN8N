> ⚠️ **DEPRECATED** — This file is outdated. See `.claude/CLAUDE.md` and `.claude/commands/orch.md` for current 5-Agent architecture.

# UNIFIED AGENT SYSTEM - Architecture Plan (LEGACY)

> **Objective:** 6-agent Pure Claude system for n8n workflow automation

**Version:** 2.4.0 (DEPRECATED)
**Date:** 2025-11-25
**Status:** ❌ DEPRECATED — See v2.9.0+ in main docs

---

## 1. EXECUTIVE SUMMARY

### What We're Building

A **6-agent Pure Claude system** for n8n workflows:

| Agent | Model | Cost | Role |
|-------|-------|------|------|
| orchestrator | Sonnet | $3/$15 | Route + coordinate |
| architect | Opus 4.5 | $5/$25 | Plan complex tasks |
| researcher | Sonnet | $3/$15 | Search nodes/templates |
| builder | Opus 4.5 | $5/$25 | Create + fix workflows |
| qa | Haiku | $1/$5 | Validate + test |
| **analyst** | **Opus 4.5** | $5/$25 | **Post-mortem, audit, learnings** |

### Architecture Diagram

```
                                   ┌───────────────────────────────────────────────────┐
                                   │              ORCHESTRATOR (Sonnet)                │
                                   │  tools: Task, Read                                │
                                   │  mcp: list_workflows, get_workflow                │
                                   │  role: Route tasks, coordinate loops              │
                                   │  tokens: ~800                                     │
                                   └─────────────────────┬─────────────────────────────┘
                                                         │
          ┌──────────────────────────────────────────────┼──────────────────────────────────────────────┐
          │                      │                       │                       │                      │
          ▼                      ▼                       ▼                       ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ARCHITECT (Opus)  │  │RESEARCHER (Son.) │  │ BUILDER (Opus)   │  │   QA (Haiku)     │  │ ANALYST (Opus)   │
│                  │  │                  │  │                  │  │                  │  │                  │
│mcp:              │  │mcp:              │  │mcp:              │  │mcp:              │  │mcp: READ-ONLY    │
│ search_templates │  │ search_nodes     │  │ create_workflow  │  │ validate_*       │  │ get_workflow     │
│ search_nodes     │  │ search_templates │  │ update_*         │  │ trigger_webhook  │  │ get_execution    │
│ get_template     │  │ get_node         │  │ autofix_*        │  │ get_execution    │  │ list_executions  │
│                  │  │ list_nodes       │  │ validate_*       │  │                  │  │ workflow_versions│
│                  │  │                  │  │                  │  │                  │  │                  │
│tools: Read, Web  │  │tools: Read       │  │tools: Read       │  │tools: Read       │  │tools: Read, Write│
│                  │  │                  │  │                  │  │                  │  │ (LEARNINGS.md)   │
│skills:           │  │skills:           │  │skills:           │  │skills:           │  │                  │
│ n8n/patterns     │  │ n8n/patterns     │  │ n8n/patterns     │  │ n8n/validation   │  │skills:           │
│ n8n/node-configs │  │                  │  │ n8n/node-configs │  │                  │  │ n8n/patterns     │
│                  │  │                  │  │                  │  │                  │  │ n8n/audit        │
│tokens: ~1500     │  │tokens: ~400      │  │tokens: ~1000     │  │tokens: ~300      │  │                  │
│                  │  │                  │  │                  │  │                  │  │tokens: ~1200     │
│WHEN: Complex     │  │WHEN: Search      │  │WHEN: Create/fix  │  │WHEN: After build │  │                  │
│      L3 escalate │  │      lookup      │  │      ONLY WRITER │  │      NO FIXES!   │  │WHEN: Post-mortem │
└──────────────────┘  └──────────────────┘  └──────────────────┘  └──────────────────┘  │      Audit logs  │
                                                                                        │      Learnings   │
                                                                                        │      NO DELEGATE │
                                                                                        └──────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                          FLOW PATTERNS                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Simple:    Researcher → Builder → QA → Done                                                                │
│ Complex:   Architect → Researcher → Builder → QA → Done                                                    │
│ Fix loop:  QA error → Builder fix → QA (max 3 cycles)                                                      │
│ Blocked:   After 3 fails → Architect (L3) or User (L4)                                                     │
│ Analysis:  User asks "why?" or failure_source=unknown → ANALYST (reads full logs, proposes learnings)      │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### MCP Tool Distribution (v2.26.1 Unified)

> **v2.26.1 uses unified tools with mode/action params - fewer tools, same power!**

#### ORCHESTRATOR (Sonnet) - MINIMAL! Only routing
```yaml
allowed_mcp_tools:
  - n8n_list_workflows                    # See what exists
  - n8n_get_workflow  # mode: 'minimal'   # Quick workflow check

# Main tools: Task (delegate), Read (context)
# Total MCP: 2 tools only!
```

#### ARCHITECT (Opus 4.5) - Planning & Strategy
```yaml
allowed_mcp_tools:
  # Templates - unified search
  - search_templates     # searchMode: 'keyword'|'by_nodes'|'by_metadata'|'by_task'
  - get_template
  # Node discovery - unified
  - search_nodes
  - get_node            # mode: 'info'|'docs'|'search_properties'
  # Workflow awareness
  - n8n_list_workflows
  - n8n_get_workflow    # mode: 'structure'

# Also: WebSearch, Read
# Total MCP: 6 tools (was 12)
```

#### RESEARCHER (Sonnet) - Search Expert
```yaml
allowed_mcp_tools:
  # Node search - unified
  - search_nodes
  - get_node            # mode: 'info'|'docs'|'search_properties', includeExamples: true
  # Templates - unified
  - search_templates    # searchMode: 'keyword'|'by_nodes'|'by_metadata'
  - get_template
  # Basic validation
  - validate_node       # mode: 'minimal'|'full'

# Total MCP: 5 tools (was 16!)
```

#### BUILDER (Opus 4.5) - **ONLY WRITER**
```yaml
allowed_mcp_tools:
  # ⚡ MUTATION - ONLY BUILDER!
  - n8n_create_workflow
  - n8n_update_partial_workflow
  - n8n_update_full_workflow
  - n8n_autofix_workflow
  # Validation - unified
  - validate_workflow
  - validate_node       # mode: 'minimal'|'full'
  # Node config - unified
  - get_node            # mode: 'info'|'search_properties', propertyQuery: 'auth'
  # Workflow read - unified
  - n8n_get_workflow    # mode: 'full'|'structure'

# Total MCP: 8 tools (was 14)
# 4 mutation + 4 read
```

#### QA (Haiku) - Validate & Test
```yaml
allowed_mcp_tools:
  # Validation - unified
  - validate_workflow
  - n8n_validate_workflow
  - validate_node       # mode: 'minimal'|'full'
  # Workflow read - unified
  - n8n_get_workflow    # mode: 'full'|'structure'
  # Test execution
  - n8n_trigger_webhook_workflow
  - n8n_update_partial_workflow  # ONLY activate/deactivate!
  # Execution results - unified
  - n8n_executions      # action: 'get'|'list'

# ❌ PROHIBITED: autofix, create, update_full
# Total MCP: 7 tools (was 12)
```

#### ANALYST (Opus 4.5) - READ-ONLY Audit
```yaml
allowed_mcp_tools:
  # Workflow - unified
  - n8n_get_workflow    # mode: 'full'|'details'|'structure'
  - n8n_list_workflows
  - n8n_workflow_versions
  # Executions - unified
  - n8n_executions      # action: 'get'|'list'
  # Validation
  - validate_workflow
  # System state
  - n8n_health_check

# ❌ PROHIBITED: Task, create, update, autofix, trigger
# Total MCP: 6 tools (was 12)
# Can WRITE only to: LEARNINGS.md
```

### MCP Summary Table (v2.26.1)

| Agent | MCP Tools | Mutate? | Test? | Primary Focus |
|-------|-----------|---------|-------|---------------|
| **orchestrator** | **2** | ❌ | ❌ | **Routing only!** |
| architect | 6 | ❌ | ❌ | Templates, planning |
| researcher | 5 | ❌ | ❌ | Node/template search |
| **builder** | **8** | **✅** | ❌ | **CREATE/UPDATE/AUTOFIX** |
| qa | 7 | ❌ | ✅ | Validate + test |
| analyst | 6 | ❌ | ❌ | Audit logs, versions |

**Total: 34 tools (was 68!)** - 50% reduction with unified tools.

**Key principle:** Each agent gets ONLY tools needed for their job. Orchestrator is minimal - just routes!

### Skills Distribution

| Skill | Agents | Tokens | Content |
|-------|--------|--------|---------|
| `n8n/patterns` | architect, researcher, builder, analyst | ~300 | Critical patterns from LEARNINGS.md |
| `n8n/node-configs` | architect, builder | ~400 | Node configuration examples |
| `n8n/validation` | qa | ~200 | Validation rules, error classification |
| `n8n/audit` | analyst | ~300 | Log analysis patterns, root cause templates |

**Total skills:** 4 files, ~1200 tokens loaded on-demand

### Permission Matrix (HARD RULES Summary)

| Action | Orch | Arch | Res | Build | QA | Analyst |
|--------|:----:|:----:|:---:|:-----:|:--:|:-------:|
| Create/Update workflow | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Delete workflow | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Autofix | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Validate (final) | ❌ | ❌ | ❌ | pre | ✅ | ❌ |
| Activate/Test | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Search nodes/templates | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| WebSearch | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Task (delegate) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Write LEARNINGS.md | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Read all logs | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

**Key:** Only Builder mutates workflows. Only Orchestrator delegates. Only Analyst writes learnings.

### Files to Copy (New Project Setup)

**Location:** `export-to-new-project/` folder in SubAgents

**READ ORDER for new bot:**
1. `docs/PLAN-UNIFIED-AGENT-SYSTEM.md` (THIS FILE) - main reference
2. `.claude/agents/*.md` - agent templates with tools and prompts
3. `memory/run_state.json` - state file schema

**Contents:**
```
export-to-new-project/
├── .claude/
│   ├── agents/           # 5 agent templates (orchestrator, architect, builder, qa, analyst)
│   └── commands/
│       └── orch.md       # /orch slash command
├── docs/
│   └── PLAN-UNIFIED-AGENT-SYSTEM.md
├── memory/
│   └── run_state.json    # State file template (empty)
└── README.md             # Quick start guide
```

**Create manually:** `.mcp.json` with n8n-mcp credentials (not included for security)

---

## 2. PROJECT STRUCTURE

### New Project Location

```
~/Projects/AgentSystem/
├── CLAUDE.md                     # Master orchestrator prompt + routing
├── .claude/
│   ├── agents/                   # Specialized agents (6 total, Pure Claude)
│   │   ├── orchestrator.md       # Sonnet - routing & coordination
│   │   ├── architect.md          # Opus 4.5 - planning & strategy
│   │   ├── researcher.md         # Sonnet - search nodes/templates
│   │   ├── builder.md            # Opus 4.5 - creates workflows (MAIN!)
│   │   ├── qa.md                 # Haiku - validate + test
│   │   └── analyst.md            # Opus 4.5 - post-mortem, audit, learnings
│   │
│   ├── skills/                   # Domain knowledge (progressive disclosure)
│   │   ├── n8n/
│   │   │   ├── patterns.md       # n8n patterns (from LEARNINGS.md)
│   │   │   ├── node-configs.md   # Node configuration examples
│   │   │   └── validation.md     # Validation rules
│   │   ├── database/
│   │   │   ├── sql-patterns.md   # SQL best practices
│   │   │   └── schema-rules.md   # Schema conventions
│   │   ├── comms/
│   │   │   ├── templates.md      # Message templates
│   │   │   └── channels.md       # Channel conventions
│   │   └── dev/
│   │       ├── coding-standards.md
│   │       └── git-workflow.md
│   │
│   └── commands/                 # Slash commands
│       ├── orch.md               # /orch - n8n workflows
│       ├── dev.md                # /dev - development
│       ├── data.md               # /data - database ops
│       └── comms.md              # /comms - communications
│
├── memory/                       # Persistent state
│   ├── decisions.md              # Routing decisions log
│   ├── learnings.md              # Captured patterns
│   └── context.md                # Current session state
│
├── schemas/                      # JSON schemas
│   ├── run-state.json            # Stateless protocol schema
│   └── agent-output.json         # Standard output format
│
├── docs/
│   ├── ARCHITECTURE.md           # System architecture
│   ├── AGENTS.md                 # Agent specifications
│   ├── SKILLS.md                 # Skills documentation
│   └── MIGRATION.md              # Migration from SubAgents
│
└── .mcp.json                     # MCP configuration (gitignored)
```

---

## 3. AGENT SPECIFICATIONS

### 3.1 Agent Overview (6 Agents, Pure Claude)

| Agent | Model | Tools | Tokens | Role |
|-------|-------|-------|--------|------|
| **orchestrator** | **Sonnet** | Task, Read, mcp__n8n (list/get) | ~800 | Routing, coordination, 4-level escalation |
| **architect** | **Opus 4.5** | Read, WebSearch, mcp__n8n (search/templates) | ~1500 | Deep planning, strategy, patterns |
| **researcher** | **Sonnet** | mcp__n8n (search/get/list), Read | ~400 | Search nodes, templates, documentation |
| **builder** | **Opus 4.5** | mcp__n8n (create/update/validate) | ~1000 | **CREATES workflows** - most complex! |
| **qa** | **Haiku** | mcp__n8n (validate/trigger), Read | ~300 | Validate + test, reports errors (NO fix!) |
| **analyst** | **Opus 4.5** | Read, Write (LEARNINGS), mcp (READ-ONLY) | ~1200 | **Post-mortem, full audit, learnings** |

**Model Distribution Rationale:**
- **Opus 4.5** ($5/$25): Builder + Architect + Analyst (CREATION + ANALYSIS - need intelligence)
- **Sonnet** ($3/$15): Orchestrator + Researcher (coordination + search)
- **Haiku** ($1/$5): QA (simple validation, boolean results)

**Cost per workflow:** ~$0.03-0.05 | **Monthly (100 workflows):** ~$3-5

### 3.2 Orchestrator (Coordinator)

```yaml
---
name: orchestrator
description: Main coordinator. Routes tasks, manages 4-level escalation, coordinates agent loops.
tools: Task, Read, mcp__n8n (list_workflows, get_workflow)
model: sonnet
---

You are the Orchestrator - central coordinator for n8n workflows.

## WORKFLOW
1. **Analyze** - Understand user request complexity
2. **Route** - Delegate to appropriate agent
3. **Coordinate** - Manage build→qa→fix loops (max 3 cycles)
4. **Report** - Present final result to user

## 4-LEVEL ESCALATION
| Level | Trigger | Action |
|-------|---------|--------|
| L1: Quick Fix | Simple error, known pattern | Builder direct fix |
| L2: Research | Unknown error, needs templates | Researcher → Builder |
| L3: Strategic | 3+ failed attempts | Architect re-plan |
| L4: User | Blocked, needs decision | Report to user |

## QA LOOP (max 3 cycles)
Builder creates → QA validates → if errors: Builder fixes → QA re-validates
After 3 failures: Escalate to L3 (Architect)

## ROUTING TABLE
| Task Type | Agent | When |
|-----------|-------|------|
| Complex planning | @architect | Multi-service, architecture decisions |
| Find nodes/templates | @researcher | Search, documentation lookup |
| Create/fix workflow | @builder | Any mutation operation |
| Validate/test | @qa | After build, before deploy |

## RULES
- NEVER create workflows yourself (Builder does this)
- ALWAYS pass full run_state to agents
- Track cycle_count in run_state
- Log routing decisions

## HARD RULES
- ❌ NEVER create/update/delete workflows (Builder does this)
- ❌ NEVER search deeply (Researcher does this)
- ❌ NEVER validate/test (QA does this)
- ❌ NEVER do deep planning (Architect does this)
- ✅ ONLY route tasks and coordinate loops
- ✅ CAN read workflow list (for routing)
```

### 3.3 Architect (Strategic Planning)

```yaml
---
name: architect
description: Deep planning and strategy. Analyzes complex requirements, designs workflow architecture.
tools: Read, WebSearch, mcp__n8n (search_templates, search_nodes, get_template)
model: opus
skills: ["n8n/patterns", "n8n/node-configs"]
---

You are the Architect - strategic planner for complex n8n workflows.

## WHEN CALLED
- Multi-service integrations (3+ services)
- Unclear requirements (need research)
- L3 escalation (3+ failed build attempts)
- User requests architecture review

## WORKFLOW
1. **Analyze** - Break down user request into components
2. **Research** - Find templates, patterns, best practices
3. **Design** - Create workflow blueprint with node structure
4. **Plan** - Define execution steps for Builder
5. **Return** - Update run_state with blueprint

## BLUEPRINT OUTPUT
Update run_state.blueprint:
{
  "services": ["service1", "service2"],
  "pattern": "webhook→process→store",
  "nodes_needed": [
    { "type": "webhook", "role": "trigger" },
    { "type": "httpRequest", "role": "api_call" },
    { "type": "supabase", "role": "storage" }
  ],
  "template_refs": ["template_123"],
  "risks": ["rate_limits", "auth_expiry"],
  "build_steps": [
    "1. Create trigger webhook",
    "2. Add API integration",
    "3. Connect to storage"
  ]
}

## RULES
- ALWAYS search templates before designing from scratch
- Include error handling in blueprint
- Pass ready-to-build plan to Orchestrator
- Do NOT create workflows (Builder does this)

## HARD RULES
- ❌ NEVER create/update workflows (Builder does this)
- ❌ NEVER delegate via Task (return to Orchestrator)
- ❌ NEVER validate/test (QA does this)
- ✅ ONLY plan and design blueprints
- ✅ CAN search templates for patterns
- ✅ CAN use WebSearch for research
```

### 3.4 Researcher (Search & Documentation)

```yaml
---
name: researcher
description: Search nodes, templates, documentation. Fast lookup specialist.
tools: mcp__n8n (search_nodes, search_templates, get_node, get_template, list_nodes), Read
model: sonnet
skills: ["n8n/patterns"]
---

You are the Researcher - fast search specialist for n8n.

## RESPONSIBILITIES
- Search nodes by keyword
- Find matching templates
- Get node documentation
- Lookup patterns from LEARNINGS.md

## SEARCH PRIORITY
1. **MCP Tools** - search_nodes, search_templates (primary)
2. **Local Knowledge** - LEARNINGS.md, PATTERNS.md (patterns)
3. **Node Docs** - get_node_documentation (details)

## OUTPUT
Update run_state.research_findings:
{
  "nodes_found": [{ "type": "...", "docs_summary": "..." }],
  "templates_found": [{ "id": "...", "name": "...", "relevance": "..." }],
  "patterns_applicable": ["pattern_name: description"],
  "recommendation": "Use template X or build with nodes Y, Z"
}

## RULES
- Return structured results, not raw dumps
- Summarize docs, don't copy everything
- Prioritize templates over custom builds
- Complete quickly - Builder is waiting

## FIX SEARCH PROTOCOL (при эскалации)
1. `Read memory/run_state.json` - получить workflow
2. Найти nodes с `_meta.status == "error"`
3. **ПРОЧИТАТЬ `_meta.fix_attempts`** - что уже пробовали
4. **ИСКЛЮЧИТЬ** уже попробованные решения из поиска
5. Искать АЛЬТЕРНАТИВНЫЕ подходы
6. Write `research_findings` с пометкой: `excluded: [...]`
7. Добавить запись в `agent_log`

## HARD RULES
- ❌ NEVER create/update/fix workflows (Builder does this)
- ❌ NEVER delegate via Task (return to Orchestrator)
- ❌ NEVER validate/test (QA does this)
- ❌ NEVER do deep planning (Architect does this)
- ✅ ONLY search and return findings
- ✅ CAN read LEARNINGS.md for patterns
- ✅ CAN search nodes, templates, documentation
```

### 3.5 Builder (Workflow Creator)

```yaml
---
name: builder
description: Creates and modifies n8n workflows. ONLY agent that mutates workflows.
tools: mcp__n8n (create_workflow, update_full_workflow, update_partial_workflow, autofix_workflow, validate_workflow)
model: opus
skills: ["n8n/patterns", "n8n/node-configs"]
---

You are the Builder - the ONLY agent that can create/modify workflows.

## RESPONSIBILITIES
- Create new workflows from blueprints
- Fix errors reported by QA
- Apply autofix when appropriate
- Update existing workflows

## WORKFLOW
1. **Receive** - Get blueprint from Architect or fix request from Orchestrator
2. **Build/Fix** - Create workflow or apply fixes
3. **Validate** - Run validate_workflow before returning
4. **Return** - Update run_state with workflow details

## SAFETY RULES
- ALWAYS use update_partial for fixes (not full replace)
- ALWAYS validate before returning
- If validation fails: attempt autofix (preview first)
- Wipe protection: if removing >50% nodes, STOP and report

## OUTPUT
Update run_state.workflow:
{
  "id": "workflow_id",
  "name": "...",
  "node_count": N,
  "created_or_updated": "created|updated",
  "validation_passed": true|false,
  "actions": [{ "tool": "...", "result": "..." }]
}

## FIX MODE (when called after QA errors)
- Read run_state.qa_report.issues
- Apply targeted fixes (edit_scope from QA)
- Do NOT rebuild entire workflow
- Return for QA re-validation

## STATE FILE PROTOCOL (CRITICAL!)
1. При старте: `Read memory/run_state.json`
2. Найти nodes с `_meta.status == "error"`
3. Проверить `_meta.fix_attempts` - что уже пробовали
4. **ПЕРЕД изменением**: сохранить snapshot в `_meta.snapshot_before_fix`
5. **ПОСЛЕ изменения**: Write обновлённый workflow в run_state.json
6. Добавить свой attempt в `_meta.fix_attempts`
7. Sync с n8n через MCP
8. Добавить запись в `agent_log`

## HARD RULES
- ❌ NEVER validate for final approval (QA does this)
- ❌ NEVER delegate via Task (return to Orchestrator)
- ❌ NEVER do deep research (Researcher does this)
- ❌ NEVER activate for production (QA does this)
- ✅ ONLY create/update/fix workflows
- ✅ CAN validate own work before returning (pre-check)
- ✅ CAN use autofix in preview mode
```

### 3.6 QA (Validation & Testing)

```yaml
---
name: qa
description: Validates workflows and runs tests. Reports errors but does NOT fix.
tools: mcp__n8n (validate_workflow, n8n_validate_workflow, trigger_webhook_workflow, get_execution), Read
model: haiku
---

You are QA - validate and test workflows, report results.

## RESPONSIBILITIES
- Validate workflow structure, connections, expressions
- Activate workflow for testing
- Trigger webhook tests (if applicable)
- Report all issues with node IDs and evidence

## WORKFLOW
1. **Validate** - Run validate_workflow
2. **Activate** - If validation passes, activate workflow
3. **Test** - If webhook: trigger with test payload, check execution
4. **Report** - Return full qa_report to Orchestrator

## WHAT YOU DO NOT DO
- ❌ NO fixing errors (Builder does this)
- ❌ NO autofix calls (Builder does this)
- ❌ NO workflow mutations (only activate for test)

## OUTPUT
Update run_state.qa_report:
{
  "validation_status": "passed|passed_with_warnings|failed",
  "issues": [
    { "node_id": "...", "severity": "error|warning", "message": "...", "evidence": "..." }
  ],
  "activation_result": "success|failed|skipped",
  "test_result": {
    "execution_id": "...",
    "status": "success|error",
    "error_message": "..."
  },
  "edit_scope": ["node_id_1", "node_id_2"],  // Nodes that need fixing
  "ready_for_deploy": true|false
}

## RULES
- If validation fails: report issues, set ready_for_deploy=false
- If test fails: include execution error details
- Orchestrator will route errors to Builder for fixing
- Max 3 QA cycles before escalation to Architect

## ANNOTATION PROTOCOL (CRITICAL!)
1. `Read memory/run_state.json` - получить workflow
2. Валидировать КАЖДЫЙ node
3. Аннотировать `_meta` на проблемных nodes:
   - `status: "error" | "warning" | "ok"`
   - `error: "описание проблемы"`
   - `suggested_fix: "что делать"`
   - `evidence: "где найдена ошибка"`
4. **Проверять РЕГРЕССИИ**: если node был "ok" и стал "error" → пометить `regression_caused_by`
5. Write обновлённый workflow в run_state.json
6. Добавить запись в `agent_log`

## HARD RULES
- ❌ NEVER fix errors (Builder does this)
- ❌ NEVER call autofix (Builder does this)
- ❌ NEVER delegate via Task (return to Orchestrator)
- ❌ NEVER create/update workflows (Builder does this)
- ✅ ONLY validate and test
- ✅ CAN activate workflow for testing
- ✅ CAN trigger webhook for smoke test
- ✅ CAN annotate _meta on nodes
```

### 3.7 Analyst (Post-Mortem & Learnings)

```yaml
---
name: analyst
description: Read-only forensics. Audits full execution logs, identifies root causes, proposes learnings.
tools: Read, Write (LEARNINGS.md only)
mcp: get_workflow, get_execution, list_executions, workflow_versions, get_workflow_details (READ-ONLY!)
model: opus
skills: ["n8n/patterns", "n8n/audit"]
prohibited_actions: ["Task", "create_workflow", "update_*", "autofix_*", "delete_*", "activate"]
---

You are the Analyst - READ-ONLY forensics expert with learning capture.

## RESPONSIBILITIES
1. **Full Audit** - Read complete execution history of all agents
2. **Timeline** - Reconstruct what happened, when, by whom
3. **Root Cause** - Identify why it failed
4. **Classify** - Set failure_source (implementation | analysis | unknown)
5. **Recommend** - Who should fix (researcher vs builder)
6. **Learnings** - Propose new patterns for LEARNINGS.md

## AUDIT MODE (Full Log Analysis)
When called, read and analyze:
- run_state history (all stages)
- Each agent's actions and decisions
- MCP tool calls and results
- Errors encountered and how they were handled
- QA reports and fix attempts

## OUTPUT FORMAT
{
  "timeline": [
    { "agent": "...", "action": "...", "result": "...", "timestamp": "..." }
  ],
  "root_cause": {
    "what": "Description of failure",
    "why": "Root cause analysis",
    "evidence": ["source1", "source2"]
  },
  "failure_source": "implementation|analysis|unknown",
  "recommendation": {
    "assignee": "researcher|builder|user",
    "action": "What they should do",
    "risk": "low|medium|high"
  },
  "proposed_learnings": [
    {
      "pattern_id": "next available",
      "title": "Pattern title",
      "description": "What we learned",
      "example": "Code/config example",
      "source": "This incident"
    }
  ]
}

## AUDIT PROTOCOL (CRITICAL!)
1. `Read memory/run_state.json` - получить ПОЛНЫЙ state
2. `Read memory/history.jsonl` - получить ВСЮ историю
3. Анализировать `agent_log` - кто что делал
4. Анализировать `_meta.fix_attempts` на КАЖДОМ node - что пробовали
5. Выявлять паттерны ошибок (одна и та же ошибка повторяется?)
6. Определить root cause
7. Предложить learning для `memory/learnings.md`
8. **НЕ ФИКСИТЬ** - только анализ и рекомендации

## HARD RULES
- ❌ NEVER mutate workflows (no create/update/autofix/delete)
- ❌ NEVER delegate (no Task tool, no new_task)
- ❌ NEVER activate/execute workflows
- ✅ ONLY respond to USER (no handoffs)
- ✅ CAN write to memory/learnings.md (approved learnings only)
- ✅ CAN read ALL: run_state.json, history.jsonl, executions, workflow versions

## WHEN CALLED
- User asks "why did this fail?" / "what happened?"
- failure_source = unknown after QA
- Post-mortem after blocked workflow
- Periodic audit of patterns
```

---

## 4. SKILLS SYSTEM

### 4.1 How Skills Work

```
Orchestrator routes task → Agent loads skill → Agent executes with domain knowledge
                                    ↓
                            Skill loads ONLY when needed
                            (~200-500 tokens on demand)
```

### 4.2 Skill Structure

```yaml
# .claude/skills/n8n/patterns.md
---
name: n8n-patterns
description: n8n workflow patterns and critical rules. Load when working with n8n.
---

# N8N Patterns

## Critical Patterns (ALWAYS apply!)

### Pattern 47: Never Trust Defaults
ALL node parameters must be explicit. Never rely on n8n defaults.
- Set node v3.4+: Include `mode: "manual"`
- Webhook: Explicit `path`, `httpMethod`, `responseMode`
- Supabase: MUST have `fieldsUi` with explicit columns

### Pattern 23: Supabase fieldsUi
```javascript
// WRONG - will fail silently
{ columns: ["name", "email"], values: ["John", "john@example.com"] }

// CORRECT - explicit structure
{ fieldsUi: { fieldValues: [
  { fieldName: "name", fieldValue: "John" },
  { fieldName: "email", fieldValue: "john@example.com" }
]}}
```

### Pattern 0: Incremental Creation
Build core workflow first (3 nodes), test, then add nodes one by one.

## Common Errors

### Error: 401 Unauthorized on Supabase
Check: credentials configured? fieldsUi structure correct?

### Error: Webhook path exists
Generate unique path: `/webhook-{uuid}` or `/webhook-{timestamp}`

## Sources
- LEARNINGS.md: Full pattern database
- PATTERNS.md: Proven solutions
```

### 4.3 Skills Inventory (5 Agents)

| Skill | Agent | Tokens | Content |
|-------|-------|--------|---------|
| `n8n/patterns` | architect, builder | ~300 | Critical patterns, common errors |
| `n8n/node-configs` | architect, builder | ~400 | Node configuration examples |
| `n8n/validation` | qa | ~200 | Validation rules, error classification |

**Note:** Focused skill set for n8n-specific agents. No database/comms/dev skills in core system.

---

## 5. STATELESS PROTOCOL (run_state)

### 5.1 Why Stateless?

| Context Files (SubAgents) | run_state JSON (KiloCode) |
|--------------------------|---------------------------|
| File on disk | In-memory payload |
| Can be lost on crash | Passed explicitly |
| Agents must read/write | Agents receive and return |
| Path management overhead | No filesystem state |
| ~2-5K token overhead | Minimal overhead |

### 5.2 run_state Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "run_state",
  "type": "object",
  "required": ["id", "user_request", "stage"],
  "properties": {
    "id": { "type": "string", "description": "UUID for this execution" },
    "user_request": { "type": "string" },
    "goal": { "type": "string" },
    "operation": { "enum": ["new", "patch"], "default": "new" },

    "stage": {
      "enum": ["planning", "research", "build", "validate", "test", "complete", "blocked"]
    },

    "blueprint": {
      "type": "object",
      "properties": {
        "nodes": { "type": "array" },
        "connections": { "type": "object" },
        "services": { "type": "array" },
        "credentials_required": { "type": "array" }
      }
    },

    "research_findings": {
      "type": "object",
      "properties": {
        "research_stages": { "type": "array" },
        "patterns_found": { "type": "array" },
        "templates_found": { "type": "array" },
        "remediation": { "type": "array" },
        "ready_for_builder": { "type": "boolean" }
      }
    },

    "workflow": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" },
        "nodes": { "type": "array" },
        "connections": { "type": "object" },
        "graph_hash": { "type": "string" },
        "actions": { "type": "array", "description": "MCP tool calls log" }
      }
    },

    "qa_report": {
      "type": "object",
      "properties": {
        "validation_status": { "enum": ["passed", "passed_with_warnings", "failed"] },
        "issues": { "type": "array" },
        "failure_source": { "enum": ["implementation", "analysis", "unknown"] },
        "activation_result": { "type": "string" },
        "test_result": { "type": "object" }
      }
    },

    "memory": {
      "type": "object",
      "description": "Persistent history across cycles (for Analyst)",
      "properties": {
        "issues_history": { "type": "array", "description": "ALL issues from ALL QA cycles" },
        "fixes_applied": { "type": "array", "description": "ALL fixes ever applied" },
        "regressions": { "type": "array", "description": "Issues caused by fixes" }
      }
    },

    "edit_scope": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Node IDs that builder is allowed to modify"
    },

    "errors": { "type": "array" },
    "fixes_tried": { "type": "array" },
    "worklog": { "type": "array", "description": "High-level cycle summaries" },
    "last_attempt_notes": { "type": "string", "description": "What failed in last cycle" },

    "finalized": {
      "type": "object",
      "properties": {
        "status": { "type": "boolean" },
        "at": { "type": "string", "format": "date-time" }
      }
    }
  }
}
```

### 5.3 Context Passing Mechanism

**How agents receive and return context:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     CONTEXT PASSING FLOW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  USER REQUEST                                                           │
│       │                                                                 │
│       ▼                                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ ORCHESTRATOR creates initial run_state:                         │    │
│  │ {                                                               │    │
│  │   id: uuid(),                                                   │    │
│  │   user_request: "...",                                          │    │
│  │   stage: "routing",                                             │    │
│  │   cycle_count: 0                                                │    │
│  │ }                                                               │    │
│  └────────────────────────┬────────────────────────────────────────┘    │
│                           │                                             │
│                           ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Task(subagent_type="researcher", prompt=..., payload=run_state) │    │
│  │                                                                 │    │
│  │ RESEARCHER receives FULL run_state, adds:                       │    │
│  │ - research_findings: { nodes_found, templates_found, ... }      │    │
│  │ - stage: "research"                                             │    │
│  │                                                                 │    │
│  │ Returns: FULL updated run_state                                 │    │
│  └────────────────────────┬────────────────────────────────────────┘    │
│                           │                                             │
│                           ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ ORCHESTRATOR merges result:                                     │    │
│  │ - Objects: shallow merge (agent result overrides)               │    │
│  │ - Arrays: errors, fixes_tried → APPEND-ONLY                     │    │
│  │ - Stage: only advance forward                                   │    │
│  │                                                                 │    │
│  │ Then delegates to next agent with merged run_state              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.4 Merge Rules (Orchestrator)

| Field Type | Merge Strategy | Example |
|------------|---------------|---------|
| **Objects** | Shallow merge, agent overrides | `blueprint`, `workflow`, `qa_report` |
| **Append-only arrays** | Always append, never replace | `errors`, `fixes_tried`, `memory.issues_history` |
| **Replace arrays** | Agent result replaces | `edit_scope`, `workflow.nodes` |
| **Stage** | Only advance forward | `planning→research→build→qa→complete` |
| **Primitives** | Agent result overrides | `goal`, `operation` |

**Critical rule:** When merging `qa_report.issues` → also append to `memory.issues_history`

### 5.5 Worklog Format (Cycle Summaries)

```json
"worklog": [
  {
    "ts": "2025-01-15T10:30:00Z",
    "cycle": 1,
    "agent": "builder",
    "action": "create_workflow",
    "outcome": "success",
    "nodes_changed": ["webhook_1", "supabase_1"],
    "qa_status": "passed"
  },
  {
    "ts": "2025-01-15T10:31:00Z",
    "cycle": 2,
    "agent": "builder",
    "action": "fix_nodes",
    "outcome": "partial",
    "nodes_changed": ["supabase_1"],
    "qa_status": "failed",
    "error_summary": "fieldsUi missing"
  }
]
```

**Trimming:** Keep last ~20 entries in `worklog`, move older to logs file

### 5.6 Actions Format (MCP Tool Calls)

```json
"workflow.actions": [
  {
    "action": "create_node",
    "mcp_tool": "n8n_update_partial_workflow",
    "node_id": "webhook_1",
    "result": "success",
    "timestamp": "2025-01-15T10:30:05Z"
  },
  {
    "action": "validate",
    "mcp_tool": "validate_workflow",
    "result": "2 warnings",
    "timestamp": "2025-01-15T10:30:10Z"
  },
  {
    "action": "code_hash",
    "node": "code_1",
    "hash": "sha256:abc123...",
    "timestamp": "2025-01-15T10:30:15Z"
  }
]
```

**Purpose:** Full audit trail for Analyst

### 5.7 State Persistence Layer

```
memory/
├── run_state.json           # ГЛАВНЫЙ STATE FILE (все агенты читают/пишут)
│   ├── id                   # UUID текущего run
│   ├── user_request         # Исходный запрос
│   ├── stage                # Текущая стадия
│   ├── workflow: {          # ПОЛНЫЙ JSON + _meta на каждом node
│   │   id, name, nodes[], connections{}
│   │   nodes[]._meta: { status, error, fix_attempts[], snapshot... }
│   │ }
│   ├── blueprint            # От Architect
│   ├── research_findings    # От Researcher
│   ├── qa_report            # От QA
│   ├── fixes_tried: [...]   # Global fix history (append-only)
│   ├── memory: {            # Persistent across cycles
│   │   issues_history,
│   │   fixes_applied,
│   │   regressions
│   │ }
│   └── agent_log: [...]     # Кто что делал (full audit trail)
│
├── history.jsonl            # Append-only log (для Analyst post-mortem)
└── learnings.md             # Captured patterns (Analyst пишет)

logs/                        # Gitignored, debugging only
└── session-*.json           # Full state dumps per session
```

**Rules:**
- `memory/run_state.json` = ГЛАВНЫЙ source of truth для всех агентов
- `memory/` = persistent, git-tracked (кроме run_state.json если большой)
- `logs/` = ephemeral, gitignored, debugging only
- Agents NEVER read/write `.context/` files (deprecated)

**Agent Log Format:**
```json
{
  "ts": "2025-01-15T10:30:00Z",
  "agent": "builder",
  "action": "fix_node",
  "target": "supabase_1",
  "details": "Attempted fix: added fieldsUi",
  "result": "success",
  "mcp_calls": ["n8n_update_partial_workflow"]
}
```

### 5.8 State Flow Example (6 Agents)

```
USER: "Create webhook→Supabase workflow"
         │
         ▼
    ┌─────────────────────────────────────────────────────────┐
    │ ORCHESTRATOR receives request, creates run_state:        │
    │ {                                                        │
    │   id: "abc123",                                          │
    │   user_request: "Create webhook→Supabase workflow",      │
    │   stage: "routing",                                      │
    │   cycle_count: 0                                         │
    │ }                                                        │
    │ Routes to: RESEARCHER (simple) or ARCHITECT (complex)    │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ RESEARCHER (Sonnet) searches nodes/templates             │
    │ Updates: stage: "research",                              │
    │          research_findings: {                            │
    │            nodes_found: [...],                           │
    │            templates_found: [...]                        │
    │          }                                               │
    │ Returns to ORCHESTRATOR                                  │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ ORCHESTRATOR routes to BUILDER                           │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ BUILDER (Opus 4.5) creates workflow                      │
    │ Updates: stage: "build",                                 │
    │          workflow: { id: "xyz789", node_count: 3 }       │
    │ Returns to ORCHESTRATOR                                  │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ ORCHESTRATOR routes to QA                                │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ QA (Haiku) validates + tests                             │
    │ Updates: stage: "qa",                                    │
    │          qa_report: {                                    │
    │            validation_status: "passed",                  │
    │            activation_result: "success",                 │
    │            ready_for_deploy: true                        │
    │          }                                               │
    │ Returns to ORCHESTRATOR                                  │
    └────────────────────────┬────────────────────────────────┘
                             │
                             ▼
    ┌─────────────────────────────────────────────────────────┐
    │ ORCHESTRATOR checks qa_report.ready_for_deploy           │
    │ If true: stage: "complete", report to USER               │
    │ If false: cycle_count++, route to BUILDER for fix        │
    │ If cycle_count >= 3: escalate to ARCHITECT               │
    └─────────────────────────────────────────────────────────┘
```

### 5.9 Annotated Workflow Pattern (State Persistence)

#### Главная идея
Workflow JSON хранится в `memory/run_state.json` с `_meta` аннотациями на каждом node.
Все агенты читают/пишут этот файл. Builder НЕ вызывает `n8n_get_workflow` - всё уже в контексте.

#### _meta структура на каждом node:

```json
{
  "id": "supabase_1",
  "type": "n8n-nodes-base.supabase",
  "parameters": { "operation": "insert" },
  "_meta": {
    "status": "ok | warning | error",
    "last_modified": "2025-01-15T10:30:00Z",
    "modified_by": "builder",
    "error": "fieldsUi missing - Pattern #23",
    "evidence": "validation error at line 45",
    "suggested_fix": "Add fieldsUi.fieldValues array",
    "fix_attempts": [
      {
        "attempt": 1,
        "change": "added columns array",
        "result": "failed - wrong structure",
        "by": "builder",
        "ts": "2025-01-15T10:31:00Z"
      }
    ],
    "snapshot_before_fix": { "...previous_params..." },
    "previous_status": "ok"
  }
}
```

#### Agent Read/Write Rules:

| Agent | Reads | Writes |
|-------|-------|--------|
| **Orchestrator** | run_state.json | merge results, history.jsonl |
| **Architect** | run_state.json | blueprint, agent_log |
| **Researcher** | workflow._meta, fixes_tried | research_findings, agent_log |
| **Builder** | workflow (FULL) | workflow + _meta, agent_log |
| **QA** | workflow | _meta annotations, qa_report |
| **Analyst** | EVERYTHING (read-only) | learnings.md only |

#### Loop Prevention:

```javascript
// Builder ПЕРЕД фиксом проверяет:
const node = workflow.nodes.find(n => n._meta?.status === "error");

// 1. Уже пробовали этот фикс?
if (node._meta.fix_attempts?.some(a => a.change === proposedFix)) {
  // → Ищем ДРУГОЙ подход или эскалируем
}

// 2. Слишком много попыток на этом node?
if (node._meta.fix_attempts?.length >= 3) {
  // → Эскалация к Researcher/Architect
}

// 3. Это регрессия? (было ok, стало error)
if (node._meta.previous_status === "ok" && node._meta.status === "error") {
  // → Откатываем последнее изменение
}
```

#### Regression Detection:

1. **ПЕРЕД** изменением Builder сохраняет snapshot: `_meta.snapshot_before_fix`
2. **ПОСЛЕ** изменения QA проверяет ВСЕ nodes (не только изменённые)
3. Если node был "ok" и стал "error" → **РЕГРЕССИЯ**
4. При регрессии:
   - Builder откатывает изменение (использует snapshot)
   - Помечает fix как `caused_regression` в fix_attempts
   - Эскалирует к Architect

#### N8N Sync Strategy:

```
1. При старте: remote = n8n_get_workflow(id)
2. Сравнивает graph_hash с local
3. Если drift → merge remote, preserve _meta
4. После изменения: sync n8n + state + hash

ВАЖНО: _meta хранится ТОЛЬКО в state, не в n8n!
```

---

## 6. CLAUDE.md ORCHESTRATOR PROMPT

### 6.1 Full Template (5 Agents, Pure Claude)

```markdown
# Agent System - n8n Workflow Orchestration

## System Overview (5 Agents)

| Agent | Model | Role |
|-------|-------|------|
| **orchestrator** | Sonnet | Routes tasks, coordinates loops |
| **architect** | Opus 4.5 | Deep planning, strategy |
| **researcher** | Sonnet | Search nodes, templates |
| **builder** | Opus 4.5 | Creates/fixes workflows |
| **qa** | Haiku | Validate + test |

## Routing Rules

### Task Analysis
| Task Type | Agent | When |
|-----------|-------|------|
| Complex planning | @architect | Multi-service, architecture |
| Find nodes/templates | @researcher | Search, lookup |
| Create/modify workflow | @builder | Any mutation |
| Validate/test | @qa | After build |

### Flow Pattern
```
User Request → Orchestrator
                   ↓
          [Simple or Complex?]
                   ↓
Simple: Researcher → Builder → QA → Done
Complex: Architect → Researcher → Builder → QA → Done
                   ↓
          [QA Failed? Max 3 cycles]
                   ↓
Cycle 1-2: Builder fix → QA revalidate
Cycle 3+: Escalate to Architect (L3)
```

## Agent Descriptions

### @orchestrator (Sonnet)
Central coordinator. Routes tasks, manages build→qa→fix loops.
**Tools:** Task, Read, mcp__n8n (list/get workflows)

### @architect (Opus 4.5)
Strategic planner. Creates blueprints for complex workflows.
**Tools:** Read, WebSearch, mcp__n8n (search/templates)

### @researcher (Sonnet)
Fast search. Finds nodes, templates, patterns.
**Tools:** mcp__n8n (search/get/list nodes), Read

### @builder (Opus 4.5)
ONLY agent that creates/modifies workflows.
**Tools:** mcp__n8n (create/update/autofix)

### @qa (Haiku)
Validates and tests. Reports errors, does NOT fix.
**Tools:** mcp__n8n (validate/trigger), Read

### @analyst (Opus 4.5)
READ-ONLY forensics. Full audit, post-mortem, proposes learnings.
**Tools:** Read, Write (LEARNINGS.md), mcp__n8n (get_* only)
**NEVER:** mutate, delegate, activate

## Critical Rules

1. **Builder = ONLY writer** - other agents read-only
2. **QA = NO fixes** - reports to Orchestrator, Builder fixes
3. **Max 3 cycles** - then escalate to Architect
4. **Analyst = READ-ONLY** - audits, proposes learnings, no mutations
5. **Pass run_state** - always include full context
```

---

## 7. MIGRATION PLAN (6 Agents, Pure Claude)

### 7.1 Agent Consolidation

| Old (7 agents) | New (6 agents) | Model | Notes |
|----------------|----------------|-------|-------|
| orchestrator | **orchestrator** | Sonnet | Simplified routing + loop coordination |
| architect + planner | **architect** | Opus 4.5 | Merged planning functions |
| researcher | **researcher** | Sonnet | Keep as-is |
| workflow-builder | **builder** | Opus 4.5 | + autofix responsibility |
| validator + tester | **qa** | Haiku | Merged into single QA |
| analyst | **analyst** | Opus 4.5 | **KEPT** - post-mortem + learnings |

### 7.2 Key Changes from SubAgents

| Feature | Old Behavior | New Behavior |
|---------|--------------|--------------|
| Model strategy | GPT-5, Gemini, mixed | **Pure Claude** (Opus/Sonnet/Haiku) |
| QA flow | Validator → Tester | **Single QA** (validates + tests) |
| Fixes | QA could autofix | **Builder fixes** (QA reports only) |
| Analyst | Separate | **KEPT on Opus** (post-mortem + learnings) |
| Escalation | Manual | **4-level automatic** (L1-L4) |
| Agent count | 7 agents | **6 agents** |

### 7.3 What to Keep from KiloCode

| Feature | Implementation |
|---------|----------------|
| Stateless run_state | JSON payload between agents |
| edit_scope | QA reports node IDs, Builder fixes only those |
| Max 3 cycles | Orchestrator tracks, escalates to Architect |
| QA no-fix | QA reports errors, never calls autofix |
| **Analyst read-only** | Full audit, proposes learnings, NO mutations |
| **Analyst no-delegate** | Responds ONLY to user, never hands off |

### 7.4 Migration Steps

```
PHASE 1: Setup
├── Update project structure (6 agents)
├── Update CLAUDE.md routing rules
└── Configure model distribution

PHASE 2: Agents (Consolidate)
├── Update orchestrator.md (Sonnet, +loop coordination)
├── Create architect.md (Opus, merged from planner+architect)
├── Update researcher.md (Sonnet, keep current)
├── Update builder.md (Opus, +fix responsibility)
├── Create qa.md (Haiku, merged validator+tester)
└── Create analyst.md (Opus, post-mortem + learnings)

PHASE 3: Remove Old Agents
├── Remove planner.md (merged → architect)
├── Remove validator.md (merged → qa)
└── Remove tester.md (merged → qa)

PHASE 4: Skills (Simplified)
├── n8n/patterns.md (for architect, builder)
├── n8n/node-configs.md (for architect, builder)
└── n8n/validation.md (for qa)

PHASE 5: Testing
├── Test simple flow: researcher → builder → qa
├── Test complex flow: architect → researcher → builder → qa
├── Test fix loop: qa error → builder fix → qa revalidate
└── Verify model costs match estimates
```

---

## 8. TOKEN ECONOMY (Pure Claude, 6 Agents)

### 8.1 Model Pricing (2025)

| Model | Input | Output | Use Case |
|-------|-------|--------|----------|
| **Opus 4.5** | $5/M | $25/M | Builder, Architect, Analyst (creation + analysis) |
| **Sonnet** | $3/M | $15/M | Orchestrator, Researcher (coordination) |
| **Haiku** | $1/M | $5/M | QA (validation) |

**Key insight:** Opus 4.5 only 67% more than Sonnet (not 5x like old Opus!)

### 8.2 Cost Per Workflow

| Flow Type | Agents Used | Estimated Cost |
|-----------|-------------|----------------|
| Simple | Researcher(S) → Builder(O) → QA(H) | ~$0.02 |
| Complex | Architect(O) → Researcher(S) → Builder(O) → QA(H) | ~$0.04 |
| With 2 fix cycles | + 2x (Builder + QA) | ~$0.06 |
| With Analyst | + Analyst(O) post-mortem | ~$0.08 |

**Monthly estimate (100 workflows):** ~$3-5 (without analyst) / ~$5-8 (with analyst)

### 8.3 Token Breakdown by Agent

```
AGENT TOKEN USAGE:

orchestrator (Sonnet):   ~800 tokens
  └── Routing logic:     ~300 tokens
  └── Loop coordination: ~500 tokens

architect (Opus 4.5):    ~1500 tokens
  └── Planning logic:    ~800 tokens
  └── Blueprint output:  ~700 tokens

researcher (Sonnet):     ~400 tokens
  └── Search results:    ~400 tokens

builder (Opus 4.5):      ~1000 tokens
  └── Workflow JSON:     ~600 tokens
  └── Fix operations:    ~400 tokens

qa (Haiku):              ~300 tokens
  └── Validation report: ~300 tokens

analyst (Opus 4.5):      ~1200 tokens
  └── Log analysis:      ~600 tokens
  └── Timeline + report: ~400 tokens
  └── Proposed learnings: ~200 tokens
```

### 8.4 Comparison with Old System

| Metric | Old (7 agents, GPT+Gemini) | New (6 agents, Pure Claude) |
|--------|---------------------------|------------------------------|
| Agents | 7 | 6 |
| Models | GPT-5, Gemini, Haiku | Opus, Sonnet, Haiku |
| Cost/workflow | ~$0.05-0.10 | ~$0.02-0.05 |
| Monthly (100) | ~$5-10 | ~$3-8 |
| Complexity | High (3 providers) | Low (1 provider) |

---

## 9. SAFETY FEATURES (6 Agents)

### 9.1 Core Safety Rules

| Feature | Implementation |
|---------|----------------|
| **Builder = ONLY writer** | Only builder can create/update/autofix |
| **QA = NO fixes** | QA reports errors, never calls autofix |
| **Analyst = READ-ONLY** | Full audit access, NO mutations, NO delegation |
| **edit_scope** | QA reports node IDs, Builder fixes only those |
| **diff_gate** | Block if payload < 50% of remote (wipe protection) |
| **Max 3 cycles** | After 3 QA failures → escalate to Architect |

### 9.2 QA Safety (NO MUTATIONS!)

```yaml
# QA validates and tests but NEVER fixes
allowed_tools:
  - mcp__n8n__validate_workflow
  - mcp__n8n__n8n_validate_workflow
  - mcp__n8n__trigger_webhook_workflow  # For testing only
  - mcp__n8n__get_execution
  - mcp__n8n__get_workflow
  - Read

prohibited_tools:
  - mcp__n8n__n8n_autofix_workflow  # NO AUTOFIX!
  - mcp__n8n__n8n_update_*          # NO UPDATES!
  - mcp__n8n__n8n_create_*          # NO CREATE!
  - mcp__n8n__n8n_delete_*          # NO DELETE!
```

### 9.3 Builder Safety

```yaml
# Builder can mutate but with constraints
allowed_tools:
  - mcp__n8n__n8n_create_workflow
  - mcp__n8n__n8n_update_partial_workflow
  - mcp__n8n__n8n_update_full_workflow
  - mcp__n8n__n8n_autofix_workflow
  - mcp__n8n__validate_workflow

safety_rules:
  - If edit_scope exists: ONLY modify listed nodes
  - If removing >50% nodes: STOP, report to Orchestrator
  - Always validate before returning
  - Preview autofix before applying
```

### 9.4 Analyst Safety (STRICTEST!)

```yaml
# Analyst is the SAFEST agent - full audit, ZERO mutations
allowed_tools:
  - Read (ALL files, logs, configs)
  - Write (ONLY LEARNINGS.md - approved learnings)
  - mcp__n8n__get_workflow
  - mcp__n8n__get_execution
  - mcp__n8n__list_executions
  - mcp__n8n__workflow_versions
  - mcp__n8n__get_workflow_details

prohibited_tools:
  - Task                              # NO delegation!
  - mcp__n8n__n8n_create_*            # NO CREATE!
  - mcp__n8n__n8n_update_*            # NO UPDATE!
  - mcp__n8n__n8n_autofix_*           # NO AUTOFIX!
  - mcp__n8n__n8n_delete_*            # NO DELETE!
  - mcp__n8n__trigger_webhook_*       # NO EXECUTE!
  - mcp__n8n__activate_*              # NO ACTIVATE!

safety_rules:
  - NEVER delegate (no Task, no new_task, no switch_mode)
  - ONLY respond to USER (no handoffs)
  - CAN propose learnings (user approves before commit)
  - Full read access to ALL logs, executions, versions
```

---

## 10. NEXT STEPS

### Immediate Actions

1. **Update SubAgents** with 6-agent architecture
2. **Create agent files:**
   - orchestrator.md (Sonnet)
   - architect.md (Opus 4.5)
   - researcher.md (Sonnet)
   - builder.md (Opus 4.5)
   - qa.md (Haiku)
   - analyst.md (Opus 4.5)
3. **Update /orch command** for new flow
4. **Test simple workflow** creation end-to-end
5. **Measure actual costs** vs estimates

### Questions Resolved

| Question | Decision |
|----------|----------|
| Models? | **Pure Claude** (Opus/Sonnet/Haiku) |
| Agent count? | **6** (kept analyst from KiloCode) |
| QA flow? | **Single QA** (merged validator+tester) |
| Fixes? | **Builder fixes** (QA reports only) |
| Analyst? | **KEPT on Opus** (post-mortem + learnings) |

---

## 11. SUMMARY

### What We're Building

A **6-agent Pure Claude system** for n8n workflows:

| Agent | Model | Role |
|-------|-------|------|
| orchestrator | Sonnet | Route + coordinate loops |
| architect | Opus 4.5 | Plan complex workflows |
| researcher | Sonnet | Search nodes/templates |
| builder | Opus 4.5 | Create + fix workflows |
| qa | Haiku | Validate + test (no fix!) |
| **analyst** | **Opus 4.5** | **Post-mortem, audit, learnings** |

### Key Design Decisions

1. ✅ **Pure Claude** - no GPT-5/Gemini dependency
2. ✅ **6 agents** - kept analyst from KiloCode
3. ✅ **Opus for creation + analysis** - Builder + Architect + Analyst
4. ✅ **Sonnet for coordination** - Orchestrator + Researcher
5. ✅ **Haiku for validation** - QA (simple boolean results)
6. ✅ **QA never fixes** - reports to Builder
7. ✅ **Analyst never mutates** - full audit, proposes learnings
8. ✅ **Max 3 cycles** - then escalate to Architect

### Expected Results

- **Cost:** ~$0.02-0.05 per workflow
- **Monthly (100 workflows):** ~$3-8
- **Simplicity:** 1 provider (Anthropic)
- **Reliability:** Opus 4.5 for critical tasks
- **Learning:** Analyst captures patterns to LEARNINGS.md

---

**Document Version:** 2.4.0 (6 Agents + HARD RULES + Permission Matrix)
**Updated:** 2025-11-25
**Author:** Claude + Sergey
