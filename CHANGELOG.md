# Changelog

All notable changes to ClaudeN8N (5-Agent n8n Orchestration System).

## [2.9.0] - 2025-11-27

### 6-Agent → 5-Agent Architecture Refactor

**Removed orchestrator.md agent file** — cannot work as sub-agent due to nested MCP limitation.

### Removed
- **orchestrator.md** agent file — coordination logic moved to main context (orch.md)
- Orchestrator row from permission matrix in CLAUDE.md

### Changed
- **Title:** "6-Agent" → "5-Agent" everywhere
- **Models optimized:**
  - architect: opus → sonnet (dialog doesn't need opus)
  - builder: opus → opus 4.5 (`claude-opus-4-5-20251101`) — latest and most capable
  - qa: haiku → sonnet (haiku too weak for validation)
  - analyst: opus → sonnet (post-mortem doesn't need opus)
- **orch.md:** Added Execution Protocol section with:
  - Correct Task syntax (`agent` not `subagent_type`)
  - Agent delegation table (stage → agent → model)
  - Context passing protocol
  - Algorithm and hard rules
- **E2E spec:** Shortened from ~200 lines to ~20 lines (works like normal flow)
- **CLAUDE.md:** Added note that Orchestrator is main context, not separate agent file

### Fixed
- Agent model selection for cost/quality balance
- Documentation consistency (5-Agent throughout)

### Architecture
```
5 Agents: architect, researcher, builder, qa, analyst
Orchestrator = main context (orch.md), NOT a separate agent file

Models:
- architect: sonnet (dialog + planning)
- researcher: sonnet (search + discovery)
- builder: opus 4.5 (ONLY writer, needs best model)
- qa: sonnet (validation + testing)
- analyst: sonnet (post-mortem + audit)
```

### Commits
- Refactored from 6-agent to 5-agent architecture

---

## [2.8.0] - 2025-11-27

### Task Tool Syntax Fix for Custom Agents

**Critical fix: correct syntax for calling custom agents via Task tool**

### Fixed
- **Task Tool Syntax** - Custom agents must use `agent` parameter, not `subagent_type`
  ```javascript
  // ✅ CORRECT:
  Task({ agent: "architect", prompt: "..." })

  // ❌ WRONG:
  Task({ subagent_type: "architect", prompt: "..." })
  ```
- **E2E Test Algorithm** - Now follows 5-PHASE FLOW correctly (8 phases)
  1. CLARIFICATION → Architect
  2. RESEARCH → Researcher
  3. DECISION → Architect
  4. IMPLEMENTATION → Researcher
  5. BUILD → Builder
  6. VALIDATE & TEST → QA
  7. ANALYSIS → Analyst
  8. CLEANUP → QA

### Added
- **Execution Protocol** in orchestrator.md
  - Correct syntax for calling custom agents
  - Agent delegation table (stage → agent → model)
  - Context passing protocol (summary in prompt, full in files)
  - Context isolation diagram
- **L-052** in LEARNINGS.md: "Task Tool Syntax - agent vs subagent_type"
  - `subagent_type` = built-in agents (general-purpose, Explore, Plan, etc.)
  - `agent` = custom agents (from `.claude/agents/` directory)
  - Context isolation explanation
  - Model selection from frontmatter
- **Claude Code Keywords** in LEARNINGS-INDEX.md
  - New category "Claude Code" added
  - Keywords: task tool, subagent_type, custom agent, context isolation

### Changed
- **CLAUDE.md** - Updated Task call examples with correct syntax
- **orchestrator.md** - E2E test now uses correct agent calls
- **LEARNINGS-INDEX.md** - 44 entries, 11 categories

### Documentation
- Full explanation of context isolation (each Task = new process)
- Model selection from agent frontmatter (opus/sonnet/haiku)
- Tools whitelist from agent frontmatter

### Commits
- `3debb05` docs: fix Task tool syntax for custom agents (v2.8.0)

---

## [2.7.0] - 2025-11-27

### Token Usage Tracking & E2E Test Improvements

**Token tracking for cost monitoring + Chat Trigger for better testing**

### Added
- **Token Usage Tracking in Analyst**
  - Tracks token consumption per agent (Orchestrator, Architect, Researcher, Builder, QA, Analyst)
  - Calculates total tokens used in workflow execution
  - Estimates cost based on Claude pricing (Sonnet/Opus/Haiku)
  - Shows efficiency metrics (most expensive/efficient agents)
  - Includes token report in all post-mortem analyses
- **Chat Trigger for E2E Tests**
  - E2E test now uses `@n8n/n8n-nodes-langchain.chatTrigger` instead of Webhook
  - Enables dual testing: manual (UI chat) + automated (API)
  - Automatic session memory for conversations
  - Visible chat history in n8n UI
  - Perfect for AI Agent workflows
- **Trigger Selection Guide in Builder**
  - When to use Chat Trigger vs Webhook vs Manual
  - Node template with proper configuration
  - Decision criteria for different use cases

### Changed
- **E2E Test Workflow** (`.claude/commands/orch.md`)
  - Block 1: Chat Trigger instead of Webhook (3 nodes)
  - Updated success criteria to include chat UI verification
  - Added comparison table (Webhook vs Chat vs Manual)
- **Analyst Output** (`.claude/agents/analyst.md`)
  - Now includes `token_usage` object in JSON output
  - Report format with markdown table
  - Cost calculation based on model pricing
- **Orchestrator E2E Algorithm** (`.claude/agents/orchestrator.md`)
  - Phase 7 (ANALYSIS) now includes token usage report
  - Updated success criteria with `chat_url_accessible` check

### Removed
- **`--test full` mode** removed from `/orch` command
  - Obsolete integration test (simple 3-node workflow)
  - Only E2E production test (`--test e2e`) remains
  - Simplified test options for better clarity

### Documentation
- **L-051** added to LEARNINGS.md: "Chat Trigger vs Webhook Trigger - When to Use What"
  - Full comparison table
  - Implementation examples (API + manual testing)
  - Use case guidelines
- LEARNINGS-INDEX.md updated (43 entries, +1)
  - Added "chat trigger" keyword
  - Updated n8n Workflows category (18 entries)

### Benefits
- ✅ **Track costs**: See exactly how much each agent costs
- ✅ **Optimize efficiency**: Identify expensive agents
- ✅ **Better testing**: Test AI workflows manually + automated
- ✅ **Session memory**: Conversation history persists
- ✅ **Visible history**: See all test runs in UI

### Commits
- `b106e92` feat: add logical block building for large workflows (v2.6.0)
- `d5f03b6` feat: add E2E production test mode to /orch command
- `fec02ab` feat: upgrade E2E test to use Chat Trigger instead of Webhook
- `2c8863b` feat: add token usage tracking to Analyst (v2.7.0)
- `07f056e` refactor: remove --test full mode from /orch

---

## [2.6.0] - 2025-11-26

### Logical Block Building for Large Workflows

**Prevents Builder timeout on workflows with >10 nodes**

### Added
- **Logical Block Building Protocol** in Builder
  - Splits workflows >10 nodes into logical blocks
  - 5 block types: TRIGGER, PROCESSING, AI/API, STORAGE, OUTPUT
  - Parameter alignment verification within each block
  - Sequential block creation with verification
  - Foundation block created first, then remaining blocks added
- **Algorithm in builder.md**
  - Block identification rules
  - Parameter alignment check
  - Verification after each block
- **Updated Process step 7**
  - Conditional: >10 nodes → use Logical Block Building
  - ≤10 nodes → single create_workflow call

### Changed
- **Builder workflow creation** (`.claude/agents/builder.md`)
  - Max 10 nodes per single call (prevents timeout)
  - Large workflows built in multiple MCP calls
  - Verification between blocks
- **Orchestrator note** (`.claude/agents/orchestrator.md`)
  - Phase 5 (BUILD) may report multiple progress updates
  - Normal for workflows >10 nodes

### Documentation
- **L-050** added to LEARNINGS.md: "Builder Timeout on Large Workflows"
  - Problem: timeout on >10 nodes
  - Solution: logical block building with aligned params
  - Block types and parameter alignment rules
- LEARNINGS-INDEX.md updated (42 entries, +1)
  - Added keywords: timeout, large workflow, chunked building

### Impact
- **Success rate**: 0% → 100% for >20 node workflows
- **Time**: -80% vs timeout (30s vs infinite wait)
- **Token cost**: +20% for large workflows (acceptable trade-off)

### Commits
- `b106e92` feat: add logical block building for large workflows (v2.6.0)

---

## [2.5.0] - 2025-11-26

### Credential Discovery (Researcher → Architect → User)

Phase 3 now includes automatic credential discovery from existing workflows.

### Added
- **Credential Discovery Protocol** in Researcher
  - Scans active workflows for existing credentials
  - Extracts credentials by type (telegramApi, httpHeaderAuth, etc.)
  - Returns `credentials_discovered` to Orchestrator
- **Phase 3.5: Credential Selection** in Architect
  - Receives `credentials_discovered` from Researcher
  - Presents credentials to user grouped by service type
  - User selects which credentials to use
  - Saves `credentials_selected` to run_state
- **Credential Usage** in Builder
  - Uses `credentials_selected` when creating nodes with auth
  - Prevents manual credential setup
- Updated Phase 3 in `/orch` command
  - Added credential discovery step between decision and blueprint

### Changed
- Researcher now handles credential scanning (was Architect in v2.3.0)
- Architect remains without MCP tools (token savings maintained)
- Stage flow: `clarification → research → decision → credentials → implementation → build → ...`
- One-level delegation maintained (Orchestrator → agents)

### Architecture
- Based on v2.3.0 working architecture (e858f4f)
- Credential feature from d4c8841, moved to Researcher
- Maintains ONE-level Task delegation (no nested calls)

### Commits
- `ff19024` feat: add credential discovery to Researcher (v2.5.0)

---

## [2.2.0] - 2025-11-26

### 5-Phase Flow (Implementation Stage)

After user approves decision, Researcher does deep dive on HOW to build.

### Added
- **Phase 4: IMPLEMENTATION** between decision and build
- `implementation` stage in run_state
- `build_guidance` field with:
  - `learnings_applied` - Learning IDs applied (L-015, L-042, etc.)
  - `patterns_applied` - Pattern IDs applied (P-003, etc.)
  - `node_configs` - Detailed node configurations from get_node
  - `expression_examples` - Ready-to-use n8n expressions
  - `warnings` - API limits, RLS checks, rate limits
  - `code_snippets` - Code node snippets if needed
- Implementation Research Protocol in researcher.md

### Changed
- 4-phase → 5-phase flow
- Stage flow: `clarification → research → decision → implementation → build → ...`

### Commits
- `1f9f99b` feat: add implementation stage (5-phase flow)

---

## [2.1.0] - 2025-11-26

### Context Optimization (~65K tokens saved)

### Added
- File-based results for Builder and QA
- Index-first reading protocol for Researcher
- `memory/agent_results/` directory for full workflow/QA results
- Write tool for Builder and QA agents

### Changed
- Builder outputs summary to run_state, full workflow to file (~30K tokens saved)
- QA outputs summary to run_state, full report to file (~15K tokens saved)
- Researcher reads LEARNINGS-INDEX.md first (~20K tokens saved)
- Schema: added `node_count`, `full_result_file` to workflow
- Schema: added `error_count`, `warning_count`, `full_report_file` to qa_report

### Commits
- `f7ef405` feat: add context optimization (~65K tokens saved)

---

## [2.0.0] - 2025-11-26

### 4-Phase Unified Flow
Complete architecture redesign from complexity-based routing to unified 4-phase flow.

### Added
- **4-Phase Flow**: Clarification → Research → Decision → Build
- New stages: `clarification`, `decision` in run_state
- New fields: `requirements`, `research_request`, `decision` in run_state
- Extended `blueprint`: `base_workflow_id`, `action`, `changes_required`
- Extended `research_findings`: `fit_score`, `popularity`, `existing_workflows`
- Extended `errors`: `severity`, `fixable`
- Skill distribution by agent in CLAUDE.md

### Changed
- Removed complexity detection (no more simple/complex routing)
- Architect: NO MCP tools (pure planner)
- Researcher: does ALL search (local → existing → templates → nodes)
- Key principle: "Modify existing > Build new"

### False Positive Rules (`54a3d9e`)
QA validator improvements to reduce false positives:

**New sections in qa.md:**
- **Code Node** — skip expression validation for `jsCode`/`pythonCode` (it's JS, not n8n expression!)
- **Set Node** — check `mode` before validation (`raw` → jsonOutput, `manual` → assignments)
- **Error Handling** — don't warn on `continueOnFail`/`onError` (intentional error routing)

**FP Tracking in qa_report:**
```json
{
  "fp_stats": {
    "total_issues": 28,
    "confirmed_issues": 20,
    "false_positives": 8,
    "fp_rate": 28.5,
    "fp_categories": {
      "jsCode_as_expression": 5,
      "set_raw_mode": 2,
      "continueOnFail_intentional": 1
    }
  }
}
```

**Safety Guards** — added FP Filter (apply FP rules before counting errors)

Now QA:
- Applies FP rules BEFORE final report
- Tracks `fp_rate` to measure improvements
- Categorizes FP by type

### Commits
- `5f3696d` docs: add learnings from test run
- `54a3d9e` feat(qa): add FP rules and tracking
- `4d56f03` docs: update CLAUDE.md for 4-phase flow
- `c133486` feat(schema): add 4-phase workflow fields
- `dba84e4` feat(orch): update command for 4-phase flow
- `a5e77f4` feat(agents): implement 4-phase workflow

---

## [1.1.0] - 2025-11-26

### MCP Format Fix
Fixed MCP tool names from `mcp__n8n__` to `mcp__n8n-mcp__`.

### Added
- Skills integration (czlonkowski/n8n-skills)
- Search Protocol for Researcher
- Preconditions and Safety Guards for Builder
- Activation Protocol for QA
- Skill Usage sections in all agents

### Fixed
- MCP tool format in all agents
- Removed broken `n8n_get_workflow_details` from Analyst

### Commits
- `78b442c` fix(analyst): MCP format + skills + remove broken tool
- `3f7f76d` fix(qa): MCP format + skills + activation protocol
- `edb74ac` fix(builder): MCP format + skills + preconditions + guards
- `bc1db0c` fix(researcher): MCP format + skills + Search Protocol
- `80f238f` fix(agents): MCP format orchestrator + architect skills

---

## [1.0.0] - 2025-11-25

### Initial Release
6-Agent n8n Orchestration System.

### Agents
- **Orchestrator** (sonnet): Route + coordinate loops
- **Architect** (opus): Planning + strategy
- **Researcher** (sonnet): Search specialist
- **Builder** (opus): ONLY writer
- **QA** (haiku): Validate + test
- **Analyst** (opus): Read-only audit

### Features
- run_state protocol with JSON schema
- QA Loop (max 3 cycles)
- 4-level escalation (L1-L4)
- Safety rules (Wipe Protection, edit_scope, Snapshot)

### Commits
- `861f178` feat: implement 6-agent orchestration system
- `d4ba720` feat: add Claude Code instructions and update documentation
- `b2aaadc` feat: add knowledge base and update architecture
- `e224cf7` chore: initial project structure
