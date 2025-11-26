# Changelog

All notable changes to ClaudeN8N (6-Agent n8n Orchestration System).

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
