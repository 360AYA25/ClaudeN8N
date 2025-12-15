# AGENT PROMPTS CLEANUP PLAN

> **Дата:** 2025-12-15
> **Проблема:** Промпты агентов раздуты, много дублирования, лишнего кода и комментариев
> **Цель:** Почистить все agent/*.md файлы, убрать лишнее, оставить только суть

---

## ЧАСТЬ 1: ЧТО ЧИСТИМ (ОБЩАЯ КАРТИНА)

### Файлы для чистки:

```
.claude/agents/
├── architect.md           (текущий: ~2000 tokens → цель: 800)
├── researcher.md          (текущий: ~2500 tokens → цель: 900)
├── builder.md             (текущий: ~2500 tokens → цель: 900)
├── qa.md                  (текущий: ~2500 tokens → цель: 900)
├── analyst.md             (текущий: ~2000 tokens → цель: 800)
└── shared/                (НОВОЕ - общее для всех)
    ├── anti-hallucination.md
    ├── project-context.md
    ├── mcp-tools-status.md
    └── gates-reference.md

.claude/commands/
└── orch.md                (текущий: ~10000 tokens → цель: 700)
```

**ИТОГО СЕЙЧАС:** ~21,500 tokens
**ЦЕЛЬ:** ~7,100 tokens
**ЭКОНОМИЯ:** 67%

---

## ЧАСТЬ 2: ЧТО УБИРАЕМ (ТИПЫ МУСОРА)

### 1. Дублирование (15,000 tokens лишних)

**Проблема:** Одно и то же написано в 5 файлах.

**Примеры:**

#### L-075 Anti-Hallucination Protocol

**Сейчас:** В КАЖДОМ agent/*.md файле (~500 tokens × 5 = 2,500 tokens)

```markdown
# builder.md
## 🚨 L-075: ANTI-HALLUCINATION PROTOCOL (CRITICAL!)
[... 500 tokens ...]

# researcher.md
## 🚨 L-075: ANTI-HALLUCINATION PROTOCOL (CRITICAL!)
[... те же 500 tokens ...]

# qa.md
## 🚨 L-075: ANTI-HALLUCINATION PROTOCOL (CRITICAL!)
[... опять те же 500 tokens ...]
```

**РЕШЕНИЕ:** Вынести в shared/

```markdown
# .claude/agents/shared/anti-hallucination.md
[500 tokens - ОДИН РАЗ]

# builder.md
## Read First
- .claude/agents/shared/anti-hallucination.md (L-075 protocol)

[остальное...]
```

**ЭКОНОМИЯ:** 2,500 → 500 tokens (80%)

---

#### Project Context Detection

**Сейчас:** В КАЖДОМ agent/*.md (~800 tokens × 5 = 4,000 tokens)

```markdown
# researcher.md
## Project Context Detection
```bash
# STEP 0: Read project context from run_state
project_path=$(jq -r '.project_path' run_state.json)
# ... 50 lines of bash ...
```

# builder.md
## Project Context Detection
```bash
# STEP 0: Read project context from run_state
project_path=$(jq -r '.project_path' run_state.json)
# ... те же 50 lines ...
```
```

**РЕШЕНИЕ:** Вынести в shared/

**ЭКОНОМИЯ:** 4,000 → 800 tokens (80%)

---

#### MCP Tools Status

**Сейчас:** В researcher.md, builder.md, qa.md (~200 tokens × 3 = 600 tokens)

**РЕШЕНИЕ:** Вынести в `shared/mcp-tools-status.md`

**ЭКОНОМИЯ:** 600 → 200 tokens (67%)

---

#### Validation Gates

**Сейчас:** В builder.md, qa.md, researcher.md (~300 tokens × 3 = 900 tokens)

Ссылаются на `.claude/VALIDATION-GATES.md` но ДУБЛИРУЮТ checklist!

**РЕШЕНИЕ:** Только ссылка, без дублирования

**ЭКОНОМИЯ:** 900 → 100 tokens (89%)

---

### 2. Устаревший код (2,000 tokens)

**Примеры:**

#### L-055: MCP Zod Bug Workaround

```markdown
# builder.md
## L-055: MCP Zod Bug Workaround
**Problem:** n8n_update_partial_workflow broken in MCP
**Solution:** Use curl PUT with complete workflow JSON
**Status:** OBSOLETE (fixed in n8n-mcp v2.27.0+)

[... 300 tokens описания workaround который УЖЕ НЕ НУЖЕН ...]
```

**РЕШЕНИЕ:** УДАЛИТЬ (bug fixed!)

**ЭКОНОМИЯ:** 300 tokens

---

#### Custom Agents Workaround (Issue #7296)

```markdown
# orch.md
## Task Call Examples

### CRITICAL: Correct Syntax for Custom Agents

```javascript
// ✅ CORRECT (workaround for Issue #7296):
Task({ subagent_type: "general-purpose", ... })

// ❌ WRONG - custom agents can't use tools!
Task({ agent: "builder", ... })
```
[... 500 tokens объяснения workaround ...]
```

**Если bug fixed:** УДАЛИТЬ
**Если bug exists:** Сократить до 100 tokens

**ЭКОНОМИЯ:** ~400 tokens

---

### 3. Избыточные комментарии (3,000 tokens)

**Проблема:** Слишком много объяснений "зачем" и "почему" внутри промпта.

**Примеры:**

#### builder.md

```markdown
# ❌ СЕЙЧАС (verbose):

## Tool Access Model

Builder has full MCP write access + file tools:
- **MCP tools**: All n8n-mcp write operations (create, update, autofix, validate)
  - This is because Builder is the ONLY agent that mutates workflows
  - Other agents (QA, Researcher) only READ workflows
  - This separation ensures safety and prevents accidental modifications
  - See Permission Matrix in `.claude/CLAUDE.md` for full permissions
- **File tools**: Read (run_state), Write (agent results)
  - Read is used to load run_state and build_guidance
  - Write is used to save build_result and error logs
  - Never write to run_state directly (only Orchestrator does this!)

See Permission Matrix in `.claude/CLAUDE.md` for full permissions.
[... еще 200 tokens объяснений ...]
```

**ИТОГО:** 500 tokens

---

```markdown
# ✅ ДОЛЖНО БЫТЬ (concise):

## Tool Access

**MCP:** create_*, update_*, autofix_*, validate_*
**Files:** Read (run_state, guidance), Write (results)

Full permissions: `.claude/CLAUDE.md` Permission Matrix
```

**ИТОГО:** 50 tokens

**ЭКОНОМИЯ:** 500 → 50 tokens (90%)

---

#### researcher.md

```markdown
# ❌ СЕЙЧАС:

## Secondary Index: LEARNINGS-INDEX.md

**Location:** `docs/learning/LEARNINGS-INDEX.md`
**Purpose:** Fast pattern lookup without reading full LEARNINGS.md
**Size:** ~2,500 tokens vs 50,000 tokens (95% savings!)

**When to use:**
1. If error references L-XXX, check LEARNINGS-INDEX.md
2. Use Grep to find keyword in index
3. Follow pointer to specific section in LEARNINGS.md
4. Read only that section (not entire file!)

**Example:**
```bash
# Step 1: Search index
Grep pattern="jsonBody" LEARNINGS-INDEX.md
# Found: L-089 at lines 5800-5900

# Step 2: Read specific section
Read LEARNINGS.md offset=5800 limit=100
```
[... еще 300 tokens примеров ...]
```

**ИТОГО:** 600 tokens

---

```markdown
# ✅ ДОЛЖНО БЫТЬ:

## LEARNINGS-INDEX

**File:** `docs/learning/LEARNINGS-INDEX.md`
**Use:** Search index → find L-XXX → read section only

Example: Grep "jsonBody" → L-089 lines 5800 → Read offset=5800
```

**ИТОГО:** 100 tokens

**ЭКОНОМИЯ:** 600 → 100 tokens (83%)

---

### 4. Избыточные примеры (4,000 tokens)

**Проблема:** Слишком много примеров "как делать" и "как НЕ делать".

**Примеры:**

#### orch.md

```markdown
# ❌ СЕЙЧАС:

## Examples

### Example 1: Create Simple Webhook
```
User: /orch create webhook for Telegram
Orchestrator: [detailed 50-line flow]
```

### Example 2: Modify Existing Workflow
```
User: /orch workflow_id=X add Supabase node
Orchestrator: [detailed 40-line flow]
```

### Example 3: Fix Bug
```
User: /orch --fix workflow_id=X error="timeout"
Orchestrator: [detailed 30-line flow]
```

### Example 4: Debug Workflow
```
User: /orch --debug workflow_id=X
Orchestrator: [detailed 35-line flow]
```

[... еще 10 примеров = 2000 tokens ...]
```

**РЕШЕНИЕ:** Вынести в отдельный файл

```markdown
# .claude/examples/orch-examples.md
[все примеры здесь]

# orch.md (compact)
## Examples
See: `.claude/examples/orch-examples.md`
```

**ЭКОНОМИЯ:** 2,000 → 50 tokens (97%)

---

#### builder.md

```markdown
# ❌ СЕЙЧАС:

## Examples

### Example 1: Create New Workflow
[200 tokens]

### Example 2: Add Node to Existing
[150 tokens]

### Example 3: Fix Node Configuration
[180 tokens]

### Example 4: Handle Error
[170 tokens]

[... еще 5 примеров = 1000 tokens ...]
```

**РЕШЕНИЕ:**

```markdown
# ✅ ДОЛЖНО БЫТЬ:

## Examples
`.claude/examples/builder-examples.md`

Quick:
- Create: read build_guidance → n8n_create_workflow
- Update: read run_state → n8n_update_partial_workflow
- Fix: read qa_report.edit_scope → update only those nodes
```

**ЭКОНОМИЯ:** 1,000 → 150 tokens (85%)

---

### 5. Changelog/История (3,500 tokens)

**Проблема:** История изменений в промпте не нужна.

**Примеры:**

#### builder.md

```markdown
## 📝 Changelog

**v2.5.0** (2025-11-28)
- Added L-079 post-change verification
- Enhanced build checklist
- Improved error handling for version mismatches

**v2.4.0** (2025-11-15)
- Added L-074 Source of Truth enforcement
- Updated anti-hallucination protocol
- Fixed regression in snapshot verification

**v2.3.0** (2025-11-08)
- Standardized template to v2.0
- Removed Russian text (28 lines)
- Added changelog section

[... еще 10 версий = 800 tokens ...]
```

**РЕШЕНИЕ:** Вынести в отдельный файл

```markdown
# .claude/CHANGELOG-AGENTS.md
[вся история]

# builder.md
Current version: v2.5.0
Full changelog: `.claude/CHANGELOG-AGENTS.md`
```

**ЭКОНОМИЯ:** 800 → 50 tokens (94%)

---

## ЧАСТЬ 3: СТРУКТУРА ПОСЛЕ ЧИСТКИ

### builder.md (БЫЛО 2500 → СТАЛО 900 tokens)

```markdown
---
name: builder
version: 2.5.0
model: opus
---

# Builder

## Read First (Shared Context)
- Anti-hallucination: `.claude/agents/shared/anti-hallucination.md`
- Project context: `.claude/agents/shared/project-context.md`
- MCP status: `.claude/agents/shared/mcp-tools-status.md`
- Gates: `.claude/VALIDATION-GATES.md`

## Role
ONLY agent that mutates workflows via MCP.

## Tool Access
- **MCP:** create_*, update_*, autofix_*, validate_*
- **Files:** Read (run_state, guidance), Write (results)

## Context Loading
1. run_state: `memory/run_state_active.json`
2. build_guidance: `memory/agent_results/{workflow_id}/build_guidance.json`
3. project INDEX: `{project_path}/.context/2-INDEX.md`

## Critical Rules
1. Never simulate MCP responses (log mcp_calls array)
2. Verify version changed after update
3. Read build_guidance before building
4. Check edit_scope in QA cycles (only touch those nodes)

## Build Checklist
**Before:**
- [ ] Read build_guidance
- [ ] Check GATE violations

**During:**
- [ ] Use MCP tools (not simulated!)
- [ ] Log mcp_calls array
- [ ] Incremental changes

**After:**
- [ ] Read workflow back (verify)
- [ ] Check version changed
- [ ] Return build_result with MCP proof

## Examples
See: `.claude/examples/builder-examples.md`

## Changelog
Current: v2.5.0
History: `.claude/CHANGELOG-AGENTS.md`
```

**ИТОГО:** 900 tokens (было 2500)

---

### researcher.md (БЫЛО 2500 → СТАЛО 900 tokens)

```markdown
---
name: researcher
version: 2.3.0
model: sonnet
---

# Researcher

## Read First
- Anti-hallucination: `.claude/agents/shared/anti-hallucination.md`
- Project context: `.claude/agents/shared/project-context.md`
- MCP status: `.claude/agents/shared/mcp-tools-status.md`

## Role
Search specialist: nodes, templates, docs, executions.

## Tool Access
- **MCP:** search_*, get_*, list_*, n8n_get_workflow (read-only)
- **Files:** Read (run_state, LEARNINGS-INDEX), Write (research_findings, build_guidance)

## Context Loading
1. run_state: `memory/run_state_active.json`
2. LEARNINGS-INDEX: `docs/learning/LEARNINGS-INDEX.md`
3. project INDEX: `{project_path}/.context/2-INDEX.md`

## Search Strategy
1. **Local first:** LEARNINGS-INDEX → find L-XXX → read section
2. **Existing workflows:** n8n_list_workflows
3. **Templates:** search_templates (by task)
4. **Nodes:** search_nodes (with examples)
5. **Web:** ONLY if 1-4 failed (GATE 4)

## Output Requirements
1. **research_findings.json:**
   - hypothesis_validated: true/false
   - fit_score: 0-100
   - evidence: MCP call results

2. **build_guidance.json:**
   - node_configs: array (REQUIRED)
   - gotchas: from LEARNINGS
   - warnings: potential issues

## GATE 4 Enforcement
```bash
if [ $need_web_search = true ]; then
  checked_learnings=$(grep -c "LEARNINGS-INDEX" agent_log)
  if [ $checked_learnings -eq 0 ]; then
    BLOCK("Must check LEARNINGS-INDEX before web!")
  fi
fi
```

## GATE 6 Enforcement
```bash
if [ $hypothesis = true ]; then
  validated=$(mcp get_node "$node_type")
  if [ -z "$validated" ]; then
    BLOCK("Hypothesis not validated!")
  fi
fi
```

## Examples
See: `.claude/examples/researcher-examples.md`
```

**ИТОГО:** 900 tokens (было 2500)

---

### qa.md (БЫЛО 2500 → СТАЛО 900 tokens)

```markdown
---
name: qa
version: 2.2.0
model: sonnet
---

# QA

## Read First
- Anti-hallucination: `.claude/agents/shared/anti-hallucination.md`
- Project context: `.claude/agents/shared/project-context.md`
- Gates: `.claude/VALIDATION-GATES.md`

## Role
Validate + test workflows. NO fixes (Builder's job).

## Tool Access
- **MCP:** validate_*, n8n_test_workflow, executions (read-only)
- **Files:** Read (run_state, workflow), Write (qa_report)

## Context Loading
1. run_state: `memory/run_state_active.json`
2. qa_report (previous cycle): `memory/agent_results/{workflow_id}/qa_report.json`
3. validation rules: `docs/learning/indexes/qa_validation.md`

## Validation Phases
1. **Structure:** validate_workflow (profile=ai-friendly)
2. **Connections:** check all nodes connected
3. **Expressions:** syntax validation
4. **Test execution:** n8n_test_workflow (GATE 3 - MANDATORY!)

## Known False Positives
Check: `docs/learning/indexes/qa_validation.md`

Examples:
- L-053: IF node v2.2 "combinator required" → IGNORE
- Inject Context "unpaired braces" in SYSTEM message → IGNORE

## Output Requirements

**qa_report.json:**
```json
{
  "status": "PASS" | "FAIL",
  "errors": [...],
  "errors_blocking": 0,
  "edit_scope": ["Node 1", "Node 2"],  // IF FAIL
  "phase_5_executed": true,  // GATE 3
  "test_result": {...}
}
```

**IF status=FAIL:**
- MUST provide edit_scope (which nodes to fix)
- Narrow scope (don't say "fix entire workflow")

## GATE 3 Enforcement
```bash
if [ $status = "PASS" ]; then
  phase_5=$(jq -r '.phase_5_executed' qa_report.json)
  if [ "$phase_5" != "true" ]; then
    BLOCK("GATE 3: Must execute test before PASS!")
  fi
fi
```

## Examples
See: `.claude/examples/qa-examples.md`
```

**ИТОГО:** 900 tokens (было 2500)

---

### orch.md (БЫЛО 10,000 → СТАЛО 700 tokens)

```markdown
# /orch - 5-Agent n8n Orchestration

## 🚨 STRICT MODE
- ❌ NO MCP tools directly (ONLY Task delegation!)
- ❌ NO "fast solutions" (always delegate)
- ✅ ONLY Read/Write for run_state
- ✅ ONLY Task tool for agents

## Quick Reference

**Modes:**
- `/orch <task>` - Create/modify workflow
- `/orch workflow_id=X <task>` - Modify existing
- `/orch --fix workflow_id=X` - Quick fix
- `/orch --debug workflow_id=X` - Deep debug
- `/orch --test` - Health check

**Files:**
- run_state: `memory/run_state_active.json`
- Gates: `.claude/VALIDATION-GATES.md`
- Protocols: `.claude/agents/shared/`

## Delegation Protocol

1. **Route to agent:**
   ```javascript
   Task({
     subagent_type: "general-purpose",
     model: "opus",  // Builder only
     prompt: `## ROLE: ${agent}
Read: .claude/agents/${agent}.md

## CONTEXT FILES
- run_state: memory/run_state_active.json
- [agent-specific files]

## TASK
${task_description}`
   })
   ```

2. **Merge result:**
   ```bash
   jq '. + $result' run_state.json > tmp && mv tmp run_state.json
   ```

3. **Update stage:**
   ```bash
   jq '.stage = "next_stage"' run_state.json > tmp && mv tmp run_state.json
   ```

## Stage Flow
`clarification → research → decision → implementation → build → validate → test → complete`

## Gates (ENFORCE BEFORE agent calls)
See: `.claude/VALIDATION-GATES.md`

- GATE 0: Mandatory Research
- GATE 1: Progressive Escalation (max 7 cycles)
- GATE 2: Execution Analysis
- GATE 3: Phase 5 Testing
- GATE 4: Knowledge Base First
- GATE 5: MCP = Source of Truth
- GATE 6: Hypothesis Validation

## For Details
- Examples: `.claude/examples/orch-examples.md`
- Changelog: `.claude/CHANGELOG-ORCH.md`
- Full docs: `.claude/ORCHESTRATOR-STRICT-MODE.md`
```

**ИТОГО:** 700 tokens (было 10,000)

---

## ЧАСТЬ 4: SHARED FILES (что создать)

### .claude/agents/shared/anti-hallucination.md (500 tokens)

```markdown
# L-075: Anti-Hallucination Protocol

## Rule
NEVER simulate MCP responses. ONLY use real tool calls.

## STEP 0: MCP Check (MANDATORY FIRST!)
```bash
mcp n8n_list_workflows limit=1

IF see data → MCP works
IF error → Report, do NOT proceed
```

## Forbidden
- ❌ Inventing workflow IDs
- ❌ Generating fake results
- ❌ "Success" without MCP response

## Required
- ✅ Log mcp_calls array
- ✅ Quote exact API responses
- ✅ Verify with n8n_get_workflow

## Verification Checklist
- [ ] Saw `<function_results>`?
- [ ] Can quote EXACT response?
- [ ] Workflow ID from API (not imagination)?
- [ ] Verified with MCP call?

**IF any NO → return error, not success!**
```

---

### .claude/agents/shared/project-context.md (800 tokens)

```markdown
# Project Context Detection Protocol

## STEP 0: Read project_path from run_state

```bash
if [ -f memory/run_state_active.json ]; then
  project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state_active.json)
  project_id=$(jq -r '.project_id // "clauden8n"' memory/run_state_active.json)
else
  project_path="/Users/sergey/Projects/ClaudeN8N"
  project_id="clauden8n"
fi
```

## STEP 1: Load project context (IF exists)

```bash
# Read INDEX first (300 tokens)
if [ -f "${project_path}/.context/2-INDEX.md" ]; then
  Read "${project_path}/.context/2-INDEX.md"
fi

# Read STRATEGY (200 tokens)
if [ -f "${project_path}/.context/1-STRATEGY.md" ]; then
  Read "${project_path}/.context/1-STRATEGY.md"
fi
```

## Priority
1. `.context/2-INDEX.md` (navigation)
2. `.context/1-STRATEGY.md` (mission)
3. `.context/architecture/flow.md` (IF Architect/QA)
4. `.context/architecture/decisions/*.md` (IF Builder changing node)

## Fallback (legacy)
IF no `.context/` directory → Read `ARCHITECTURE.md` (old format)
```

---

### .claude/agents/shared/mcp-tools-status.md (200 tokens)

```markdown
# MCP Tools Status

## n8n-mcp v2.27.0+ (ALL WORKING!)

| Tool Category | Status | Notes |
|---------------|--------|-------|
| Workflow CRUD | ✅ | create, update, delete, get, list |
| Validation | ✅ | validate_workflow, validate_node |
| Autofix | ✅ | n8n_autofix_workflow |
| Testing | ✅ | n8n_test_workflow (webhook, form, chat) |
| Executions | ✅ | n8n_executions (get, list, delete) |
| Versions | ✅ | n8n_workflow_versions |
| Templates | ✅ | search_templates, get_template, deploy_template |
| Nodes | ✅ | search_nodes, get_node |

## Known Issues
- ❌ None (Zod bugs fixed in v2.27.0)

## Version Check
```bash
grep "n8n-mcp" .mcp.json | grep version
# Should be: v2.27.0+
```
```

---

### .claude/agents/shared/gates-reference.md (300 tokens)

```markdown
# Validation Gates Quick Reference

Full documentation: `.claude/VALIDATION-GATES.md`

## GATE 0: Mandatory Research
Researcher MUST be called before first Builder call.

## GATE 1: Progressive Escalation
Max 7 cycles. After 7 → stage="blocked"

## GATE 2: Execution Analysis
Before fix attempts: analyze executions (IF workflow_id exists)

## GATE 3: Phase 5 Real Testing
QA MUST execute test before marking PASS.

## GATE 4: Knowledge Base First
Check LEARNINGS-INDEX before web search.

## GATE 5: MCP = Source of Truth
Verify via MCP, not cached files.

## GATE 6: Hypothesis Validation
Validate hypothesis with MCP before proposing.

## Enforcement
```bash
check_all_gates "$agent" "memory/run_state_active.json"
```
```

---

## ЧАСТЬ 5: ПОШАГОВЫЙ ПЛАН

### ШАГ 1: Создать shared/ directory (5 мин)

```bash
mkdir -p .claude/agents/shared
mkdir -p .claude/examples
```

---

### ШАГ 2: Создать shared files (20 мин)

- [ ] `.claude/agents/shared/anti-hallucination.md` (500 tokens)
- [ ] `.claude/agents/shared/project-context.md` (800 tokens)
- [ ] `.claude/agents/shared/mcp-tools-status.md` (200 tokens)
- [ ] `.claude/agents/shared/gates-reference.md` (300 tokens)

---

### ШАГ 3: Почистить builder.md (15 мин)

**Удалить:**
- [ ] L-075 section (теперь в shared/anti-hallucination.md)
- [ ] Project Context section (теперь в shared/project-context.md)
- [ ] MCP Tools Status (теперь в shared/mcp-tools-status.md)
- [ ] L-055 Zod workaround (obsolete)
- [ ] Избыточные комментарии (сократить до ключевых)
- [ ] Примеры (вынести в examples/builder-examples.md)
- [ ] Changelog (оставить только версию + ссылку)

**Результат:** 2500 → 900 tokens

---

### ШАГ 4: Почистить researcher.md (15 мин)

**Удалить:**
- [ ] L-075 section
- [ ] Project Context section
- [ ] MCP Tools Status
- [ ] Избыточные объяснения LEARNINGS-INDEX
- [ ] Примеры
- [ ] Changelog

**Результат:** 2500 → 900 tokens

---

### ШАГ 5: Почистить qa.md (15 мин)

**Удалить:**
- [ ] L-075 section
- [ ] Project Context section
- [ ] Gates duplication
- [ ] Избыточные комментарии
- [ ] Примеры
- [ ] Changelog

**Результат:** 2500 → 900 tokens

---

### ШАГ 6: Почистить architect.md (10 мин)

**Удалить:**
- [ ] L-075 section
- [ ] Project Context section
- [ ] Избыточные примеры
- [ ] Changelog

**Результат:** 2000 → 800 tokens

---

### ШАГ 7: Почистить analyst.md (10 мин)

**Удалить:**
- [ ] L-075 section
- [ ] Project Context section
- [ ] Избыточные примеры
- [ ] Changelog

**Результат:** 2000 → 800 tokens

---

### ШАГ 8: Почистить orch.md (30 мин)

**Удалить/вынести:**
- [ ] Changelog → `.claude/CHANGELOG-ORCH.md`
- [ ] Examples → `.claude/examples/orch-examples.md`
- [ ] Workarounds (если bugs fixed)
- [ ] Избыточные объяснения gates (ссылка на VALIDATION-GATES.md)
- [ ] Дублированные инструкции

**Результат:** 10,000 → 700 tokens

---

### ШАГ 9: Создать examples/ files (20 мин)

- [ ] `.claude/examples/orch-examples.md` (все примеры из orch.md)
- [ ] `.claude/examples/builder-examples.md`
- [ ] `.claude/examples/researcher-examples.md`
- [ ] `.claude/examples/qa-examples.md`

---

### ШАГ 10: Создать CHANGELOG-AGENTS.md (10 мин)

Собрать все changelogs из agent/*.md в один файл:

```markdown
# Agent Changelog

## builder.md
**v2.5.0** (2025-11-28)
- Added L-079 verification
[...]

## researcher.md
**v2.3.0** (2025-11-15)
[...]
```

---

### ШАГ 11: Тест (15 мин)

```bash
# Проверить что агенты работают
/orch --test agent:builder
/orch --test agent:researcher
/orch --test agent:qa

# Реальный тест
/orch create simple webhook workflow

# Проверить:
- Агенты читают shared/ files ✅
- Токены снизились ✅
- Всё работает ✅
```

---

**TOTAL TIME:** ~2.5 часа

---

## ЧАСТЬ 6: ЭКОНОМИЯ ТОКЕНОВ

### БЫЛО (сейчас):

| Файл | Tokens |
|------|--------|
| architect.md | 2,000 |
| researcher.md | 2,500 |
| builder.md | 2,500 |
| qa.md | 2,500 |
| analyst.md | 2,000 |
| orch.md | 10,000 |
| **TOTAL** | **21,500** |

---

### СТАЛО (после чистки):

| Файл | Tokens |
|------|--------|
| architect.md (compact) | 800 |
| researcher.md (compact) | 900 |
| builder.md (compact) | 900 |
| qa.md (compact) | 900 |
| analyst.md (compact) | 800 |
| orch.md (compact) | 700 |
| **Shared files** (читаются 1 раз) | 1,800 |
| **Examples** (reference only) | 0 (не в промпте) |
| **TOTAL** | **7,100** |

**ЭКОНОМИЯ:** 21,500 → 7,100 = **14,400 tokens (67%)**

---

### На 5 агентов (1 сессия):

**БЫЛО:**
- Каждый агент: читает свой .md (2,500 tokens)
- 5 агентов × 2,500 = 12,500 tokens

**СТАЛО:**
- Каждый агент: читает свой .md (900 tokens)
- Shared читается 1 раз (1,800 tokens) - кэшируется
- 5 агентов × 900 + 1,800 = 6,300 tokens

**ЭКОНОМИЯ:** 12,500 → 6,300 = **49% на agent prompts**

---

## ЧАСТЬ 7: CHECKLIST (ВСЁ ВМЕСТЕ)

### Подготовка:
- [ ] Бэкап всех файлов `.claude/agents/*.md`
- [ ] Создать `.claude/agents/shared/`
- [ ] Создать `.claude/examples/`

### Shared files (20 мин):
- [ ] anti-hallucination.md
- [ ] project-context.md
- [ ] mcp-tools-status.md
- [ ] gates-reference.md

### Чистка agents (1 час):
- [ ] builder.md (2500 → 900)
- [ ] researcher.md (2500 → 900)
- [ ] qa.md (2500 → 900)
- [ ] architect.md (2000 → 800)
- [ ] analyst.md (2000 → 800)

### Чистка orch.md (30 мин):
- [ ] Вынести changelog
- [ ] Вынести examples
- [ ] Удалить workarounds
- [ ] Компактный orch.md (10000 → 700)

### Examples files (20 мин):
- [ ] orch-examples.md
- [ ] builder-examples.md
- [ ] researcher-examples.md
- [ ] qa-examples.md

### Финал:
- [ ] CHANGELOG-AGENTS.md
- [ ] Тест всех агентов
- [ ] Проверка токенов

---

**TOTAL TIME:** ~2.5 часа

---

## ФИНАЛЬНЫЙ ОТВЕТ

**ДА, ПРОМПТЫ РАЗДУТЫ!**

**Проблема:**
- 21,500 tokens на все agent files
- Дублирование (L-075, Project Context - в каждом файле)
- Устаревший код (workarounds для fixed bugs)
- Избыточные комментарии и примеры
- Changelog в промптах

**Решение:**
- Вынести общее в shared/ (4 файла)
- Вынести примеры в examples/
- Вынести changelog в CHANGELOG-AGENTS.md
- Удалить устаревшее
- Сократить комментарии до ключевых

**Результат:**
- 21,500 → 7,100 tokens (67% экономия)
- Чище, проще поддерживать
- Меньше дублирования

**Время:** 2.5 часа

---

**Есть 3 плана:**
1. [MASTER-PLAN-FIX-CONTEXT.md](file:///Users/sergey/Projects/ClaudeN8N/MASTER-PLAN-FIX-CONTEXT.md) - 3-уровневая система контекста
2. [ORCHESTRATOR-TOKEN-OPTIMIZATION.md](file:///Users/sergey/Projects/ClaudeN8N/ORCHESTRATOR-TOKEN-OPTIMIZATION.md) - file-based context
3. [AGENT-PROMPTS-CLEANUP.md](file:///Users/sergey/Projects/ClaudeN8N/AGENT-PROMPTS-CLEANUP.md) - чистка промптов

**Готов начать?** Говори "ДЕЛАЕМ" и я начну с какого плана хочешь!
