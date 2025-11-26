# Changelog

All notable changes to ClaudeN8N (6-Agent n8n Orchestration System).

## [Unreleased]

### Added
- Context optimization: file-based results for Builder and QA
- Context optimization: index-first reading protocol for Researcher
- `memory/agent_results/` directory for full workflow/QA results
- Write tool for Builder and QA agents

### Changed
- Builder outputs summary to run_state, full workflow to file (~30K tokens saved)
- QA outputs summary to run_state, full report to file (~15K tokens saved)
- Researcher reads LEARNINGS-INDEX.md first (~20K tokens saved)
- Schema: added `node_count`, `full_result_file` to workflow
- Schema: added `error_count`, `warning_count`, `full_report_file` to qa_report

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
- False Positive rules for QA validator
- FP tracking (`fp_stats`) in qa_report
- Skill distribution by agent in CLAUDE.md

### Changed
- Removed complexity detection (no more simple/complex routing)
- Architect: NO MCP tools (pure planner)
- Researcher: does ALL search (local → existing → templates → nodes)
- Key principle: "Modify existing > Build new"

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
