# ГЛУБОКИЙ АНАЛИЗ СИСТЕМЫ + ИНТЕГРИРОВАННЫЙ ПЛАН

> **Дата:** 2025-12-15
> **Цель:** Объединить 3 плана + предложение от другого бота + surgical edits
> **Статус:** Комплексный анализ перед внедрением

---

## EXECUTIVE SUMMARY

### Проблема (корневая причина):
Агенты теряют контекст и ломают работающие части workflow потому что:
1. **Видят только тактику** (JSON ноды), не видят **стратегию** (зачем) и **архитектуру** (почему так)
2. **Нет среднего слоя** - Service Playbooks и Node Intent Cards
3. **Нет Change Protocol** - агенты меняют напрямую, без валидации и diff
4. **Тратят 61,500 tokens** на передачу контекста (JSON встроен в промпты)
5. **Agent промпты раздуты** - 21,500 tokens с дублированием

### Решение (интегрированное):
**4-фазный план на 5 часов:**
1. **Agent Cleanup** (2ч) - file-based context + shared files → экономия 67% tokens
2. **Context Architecture** (1.5ч) - 3 уровня + Service Playbooks + Node Intent Cards
3. **Builder Change Protocol** (1ч) - surgical edits + diff + validation
4. **Protected Nodes** (30мин) - валидаторы + DO NOT TOUCH

**Результат:**
- ✅ Агенты понимают ЗАЧЕМ (стратегия)
- ✅ Агенты понимают ПОЧЕМУ (ADRs + Node Intent Cards)
- ✅ Builder не может сломать (Change Protocol + validators)
- ✅ Экономия 65% tokens (61,500 → 21,400)
- ✅ Файлов 11 вместо 250

---

## ЧАСТЬ 1: ВЗАИМООТНОШЕНИЯ АГЕНТОВ (КАК РАБОТАЕТ СЕЙЧАС)

### Текущая архитектура (v3.6.0):

```
┌─────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR                           │
│  ❌ NO MCP tools (pure router)                             │
│  ✅ ONLY: Read, Write, Task, Bash                          │
│  Role: Делегирует через Task tool                          │
└─────────────────────────────────────────────────────────────┘
                         ↓
         ┌───────────────┴───────────────┐
         ↓                               ↓
┌─────────────────┐              ┌─────────────────┐
│   ARCHITECT     │              │   RESEARCHER    │
│  Model: sonnet  │              │  Model: sonnet  │
│  NO MCP tools   │              │  MCP: search_*  │
│  Диалог с User  │              │  get_*, list_*  │
└─────────────────┘              └─────────────────┘
         ↓                               ↓
         └───────────────┬───────────────┘
                         ↓
         ┌───────────────┴───────────────┐
         ↓               ↓               ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   BUILDER    │  │     QA       │  │   ANALYST    │
│  Model: OPUS │  │ Model: sonnet│  │ Model: sonnet│
│  MCP: create │  │ MCP: validate│  │ MCP: get_*   │
│  update, fix │  │ test, trigger│  │ executions   │
│  ONLY writer │  │ NO mutations │  │ Read-only    │
└──────────────┘  └──────────────┘  └──────────────┘
```

### 5-Phase Flow:

```
PHASE 1: CLARIFICATION
User → Architect (диалог) → requirements

PHASE 2: RESEARCH
Architect → Orchestrator → Researcher
Researcher: search local → existing → templates → nodes
Output: research_findings (fit_score, sources)

PHASE 3: DECISION + CREDENTIALS
Researcher → Orchestrator → Architect
Architect ←→ User (выбор варианта)
Orchestrator → Researcher (discover credentials)
Architect ←→ User (select credentials)
Output: decision + blueprint + credentials_selected

PHASE 4: IMPLEMENTATION
Architect → Orchestrator → Researcher (deep dive)
Researcher: LEARNINGS → patterns → node configs
Output: build_guidance (gotchas, configs, warnings)

PHASE 5: BUILD + QA LOOP
Researcher → Orchestrator → Builder
Builder: create/update workflow
Orchestrator → QA
QA: validate + test

IF QA FAIL:
  ├── Cycle 1-3: Builder fixes directly
  ├── Cycle 4-5: Researcher helps (alternative approach)
  ├── Cycle 6-7: Analyst diagnoses (root cause)
  └── Cycle 8+: BLOCKED → report to user

IF QA PASS:
  → stage=complete
```

### Validation Gates (6 обязательных):

| Gate | Когда | Что проверяет | Блокирует если |
|------|-------|---------------|----------------|
| **GATE 0** | Before first Builder | Mandatory Research | build_guidance не существует |
| **GATE 1** | Cycles 1-7 | Progressive Escalation | Cycle 8+ (hard cap) |
| **GATE 2** | Before fix attempts | Execution Analysis | execution_analysis.completed = false |
| **GATE 3** | Before accepting PASS | Phase 5 Real Testing | phase_5_executed = false |
| **GATE 4** | Before web search | Knowledge Base First | LEARNINGS не проверены |
| **GATE 5** | After Builder | MCP = Source of Truth | mcp_calls array пустой |

---

## ЧАСТЬ 2: ПРОБЛЕМЫ (ЧТО НЕ ТАК)

### Проблема 1: Контекст теряется

**Симптомы:**
- Builder в v516 повторяет ошибку v432 (добавляет jsonBody снова)
- Builder удаляет Memory node → пользователи теряют историю
- Builder меняет команды в Switch → забывает обновить BotFather

**Корневая причина:**
Агенты видят ТОЛЬКО тактический уровень (JSON ноды), но НЕ видят:
- **ЗАЧЕМ** проект существует (стратегия)
- **ПОЧЕМУ** нода подключена именно так (архитектурные решения)
- **ЧТО** нельзя трогать (критичные инварианты)

**Пример:**
```
Builder видит:
{
  "nodes": [
    {"id": "AI Agent", "type": "ai-agent"},
    {"id": "Memory", "type": "memory"}
  ]
}

Builder НЕ видит:
- ЗАЧЕМ Memory: пользователи говорят "обнови последнее" → AI должен помнить
- ПОЧЕМУ прямое подключение: Memory ДОЛЖЕН быть ПЕРЕД AI Agent
- ЧТО нельзя: customKey='telegram_user_id' НЕЛЬЗЯ менять (v442 сломали)
```

### Проблема 2: Builder ломает то, что работает

**Симптомы:**
- Меняет 1 ноду → ломаются 3 других
- Загружает весь workflow (58 нод) → меняет случайные параметры
- Нет diff → непонятно что именно изменилось

**Корневая причина:**
- Нет Change Protocol (прямые правки master workflow)
- Нет валидаторов (graph integrity, breaking changes)
- Нет surgical edits (Builder использует update_full вместо update_partial)

**Пример:**
```
User: "Добавь команду /water в Switch"

Builder делает:
1. Читает весь workflow (58 нод, 58,000 tokens!)
2. Меняет Switch node (добавляет /water)
3. СЛУЧАЙНО меняет параметр в другой ноде (опечатка в JSON)
4. Отправляет весь workflow обратно (update_full)
5. Результат: /water работает, но сломалась фото-обработка

Должен делать:
1. Читает только Switch node (100 tokens)
2. Генерирует diff: добавил 1 case в Switch
3. Валидатор проверяет: других нод не трогал
4. update_partial - меняет ТОЛЬКО Switch node
5. Результат: /water работает, остальное не тронуто
```

### Проблема 3: Orchestrator тратит 61,500 tokens

**Breakdown:**

| Компонент | Tokens | Количество | Итого |
|-----------|--------|------------|-------|
| orch.md | 10,000 | 1 | 10,000 |
| Agent role files | 2,500 | 5 агентов | 12,500 |
| run_state (in prompt) | 800 | 5 агентов | 4,000 |
| research_findings (in prompt) | 3,000 | 3 агента | 9,000 |
| build_guidance (in prompt) | 5,000 | 2 агента | 10,000 |
| canonical_snapshot (in prompt) | 8,000 | 2 агента | 16,000 |
| **TOTAL** | | | **61,500** |

**Корневая причина:**
- JSON встроен в промпты (`${JSON.stringify(run_state)}`)
- Дублирование: один и тот же JSON передается 5 раз
- Agent files дублируют общие правила (L-075 в каждом файле)

### Проблема 4: 250+ файлов мусора

**Где:**
- `memory/agent_results/{workflow_id}/` - cycle файлы никогда не удаляются
- `FoodTracker/.n8n/agent_results/` - дубликаты из ClaudeN8N

**Файлы:**
```
build_result.json          ← нужен
build_result_cycle1.json   ← МУСОР (никто не читает)
build_result_cycle2.json   ← МУСОР
build_result_cycle3.json   ← МУСОР
qa_report.json             ← нужен
qa_report_cycle1.json      ← МУСОР
qa_report_cycle2.json      ← МУСОР
```

---

## ЧАСТЬ 3: РЕШЕНИЕ (ИНТЕГРИРОВАННЫЙ ПЛАН)

### Объединяем 4 источника:

1. **MASTER-PLAN-FIX-CONTEXT.md** → 3-level context + ADRs
2. **ORCHESTRATOR-TOKEN-OPTIMIZATION.md** → file-based context
3. **AGENT-PROMPTS-CLEANUP.md** → shared files
4. **Предложение от другого бота** → Service Playbooks + Node Intent Cards + Change Protocol

### Новая архитектура (после внедрения):

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTEXT LAYERS                           │
├─────────────────────────────────────────────────────────────┤
│  STRATEGIC (200 tokens)                                     │
│  - 1-STRATEGY.md: зачем проект, цели, границы, инварианты  │
├─────────────────────────────────────────────────────────────┤
│  ARCHITECTURAL (1500 tokens)                                │
│  - 2-INDEX.md: навигация (кому что читать)                 │
│  - flow.md: как данные идут                                 │
│  - decisions/*.md: ADRs (почему так сделано)                │
│  - services/*.md: Service Playbooks (🆕 NEW!)              │
│  - nodes/*.md: Node Intent Cards (🆕 NEW!)                 │
├─────────────────────────────────────────────────────────────┤
│  TACTICAL (500 tokens + lazy load)                          │
│  - state.json: workflow_id, version, node_count             │
│  - Full workflow: load via MCP on demand                    │
└─────────────────────────────────────────────────────────────┘
```

### Service Playbook (новый слой):

**Зачем:** Чтобы агенты понимали как работать с внешними сервисами.

**Пример: `architecture/services/telegram.md`**
```markdown
# Telegram Bot API

## Назначение
Основной интерфейс для FoodTracker бота.

## Эндпойнты
- Webhook: `/webhook/telegram` (POST)
- sendMessage: используется для ответов
- Rate limit: 30 msg/sec

## Зависимые ноды
- Telegram Trigger (webhook)
- Telegram Send Message (8 мест)
- Switch (для роутинга команд)

## Критичные правила
- ❌ НЕ меняй webhook path без обновления BotFather
- ❌ НЕ удаляй Telegram Trigger (точка входа)
- ✅ Команды в Switch ДОЛЖНЫ совпадать с BotFather

## История ошибок
- v506: Добавили /welcome в Switch, забыли в BotFather → юзеры confused
```

**Создать для:** Telegram, Supabase, OpenAI, Whisper (4 файла)

### Node Intent Card (новый слой):

**Зачем:** Чтобы Builder понимал назначение КАЖДОЙ критичной ноды.

**Пример: `architecture/nodes/ai-agent.md`**
```markdown
# AI Agent Node

## ID
`nodes-base.agent` (единственный в workflow)

## Назначение
Главный обработчик - понимает текст юзера, вызывает tools, генерирует ответы.

## Контракт интерфейса
**Вход:**
- message: текст от юзера
- context: дата, timezone, user_id (из Inject Context)

**Выход:**
- response: текст ответа
- signature: "-- FoodTracker Bot" (убирается Strip Signature)

## Зависимости
- ⚠️ КРИТИЧНО: Memory node ДОЛЖЕН быть подключен (memory_input)
- Inject Context ДОЛЖЕН быть ПЕРЕД AI Agent
- 16 tools настроены (Add Meal, Search Meals, etc)

## Инварианты (DO NOT TOUCH!)
1. Memory connection ОБЯЗАТЕЛЬНА (customKey='telegram_user_id')
2. НЕ добавляй jsonBody к tools (v432 инцидент - бот замолчал)
3. Prompt включает инструкции на русском (юзеры русскоязычные)

## Последствия удаления
🔴 КАТАСТРОФА: Бот перестанет понимать запросы, все AI функции сломаются.

## История изменений
- v432: Добавили jsonBody → бот замолчал → откат v434
- v442: customKey изменили → сессии сломались → откат v444
```

**Создать для:** AI Agent, Memory, Switch, Inject Context, Telegram Trigger (5-7 нод)

### Change Protocol для Builder (🆕 NEW!):

**Текущий процесс (плохой):**
```
Builder:
1. Read workflow (full JSON, 58,000 tokens)
2. Modify nodes directly in memory
3. Write workflow (update_full)
❌ Результат: случайные изменения, нет diff, нельзя откатить
```

**Новый процесс (правильный):**
```
Builder:
1. Read workflow (mode=structure, 2,000 tokens)
2. Identify target nodes (из edit_scope)
3. Read ONLY target nodes (mode=filtered, nodeNames=[...])
4. Generate ChangeSet:
   - what: "Add /water case to Switch"
   - why: "User requested"
   - nodes_affected: ["Switch"]
   - risk: "low"
5. Create diff:
   - added: 1 case in Switch.parameters.rules
   - changed: 0
   - deleted: 0
6. Validate:
   - Graph integrity: ✅
   - Protected nodes: ✅ (Switch not protected)
   - Breaking changes: ✅ (no deletions)
7. Apply changes (n8n_update_partial_workflow)
8. Log edit_scope: ["Switch"]
✅ Результат: только Switch изменен, diff виден, можно откатить
```

### Validators (минимальный набор):

| Validator | Проверяет | Блокирует если |
|-----------|-----------|----------------|
| **Graph Integrity** | Нет висячих связей | nodeId referenced но не exists |
| **Required Nodes** | Обязательные ноды на месте | Telegram Trigger удален |
| **Protected Nodes** | DO NOT TOUCH не тронуты | Memory customKey изменен |
| **Breaking Changes** | Нет удалений без обоснования | Удалена нода из INDEX |
| **Contract Check** | Вход/выход соответствуют | AI Agent output изменен |

---

## ЧАСТЬ 4: ПОШАГОВАЯ РЕАЛИЗАЦИЯ (5 ЧАСОВ)

### ФАЗА 1: Agent Cleanup + File-based Context (2 часа)

#### Шаг 1.1: Создать shared/ directory (5 мин)
```bash
mkdir -p .claude/agents/shared
mkdir -p .claude/examples
```

#### Шаг 1.2: Создать shared files (20 мин)

**Файл 1: `.claude/agents/shared/anti-hallucination.md`** (500 tokens)
```markdown
# L-075: Anti-Hallucination Protocol

## STEP 0: MCP Check (MANDATORY!)
Call: mcp__n8n-mcp__n8n_list_workflows limit=1
IF see data → MCP works
IF error → Report, do NOT proceed

## Forbidden
- ❌ Inventing workflow IDs
- ❌ Fake success without MCP response

## Required
- ✅ Log mcp_calls array
- ✅ Quote exact API responses
```

**Файл 2: `.claude/agents/shared/project-context.md`** (800 tokens)
```markdown
# Project Context Detection

## STEP 0: Read project_path from run_state
project_path=$(jq -r '.project_path' memory/run_state_active.json)

## STEP 1: Load context
1. Read INDEX: {project_path}/.context/2-INDEX.md
2. Read STRATEGY: {project_path}/.context/1-STRATEGY.md

## Priority
1. INDEX (navigation)
2. STRATEGY (mission)
3. flow.md (IF Architect/QA)
4. ADRs (IF Builder changing node)
```

**Файл 3: `.claude/agents/shared/mcp-tools-status.md`** (200 tokens)
**Файл 4: `.claude/agents/shared/gates-reference.md`** (300 tokens)

#### Шаг 1.3: Компактный orch.md (30 мин)

**Вынести:**
- Changelog → `.claude/CHANGELOG-ORCH.md`
- Examples → `.claude/examples/orch-examples.md`
- Workarounds (если bugs fixed)

**Новый orch.md:** 10,000 → 700 tokens

#### Шаг 1.4: File-based context (40 мин)

**Изменить все Task calls в orch.md:**

❌ **БЫЛО:**
```javascript
Task({
  prompt: `## CONTEXT
${JSON.stringify(run_state, null, 2)}  // 800 tokens!
${JSON.stringify(build_guidance, null, 2)}  // 5,000 tokens!
`
})
```

✅ **СТАЛО:**
```javascript
Task({
  prompt: `## CONTEXT FILES
Read these files yourself (in order):
1. run_state: memory/run_state_active.json
2. guidance: memory/agent_results/{workflow_id}/build_guidance.json

Do NOT wait for me to give you content - read files yourself!`
})
```

**Экономия:** 18,800 → 200 tokens per agent call

#### Шаг 1.5: Почистить agent files (60 мин)

**Для каждого agent/*.md:**
1. Удалить L-075 section → ссылка на shared/
2. Удалить Project Context → ссылка на shared/
3. Удалить MCP status → ссылка на shared/
4. Удалить избыточные примеры → ссылка на examples/
5. Компактный формат

**Результат:**
- builder.md: 2,500 → 900 tokens
- researcher.md: 2,500 → 900 tokens
- qa.md: 2,500 → 900 tokens
- architect.md: 2,000 → 800 tokens
- analyst.md: 2,000 → 800 tokens

**ИТОГО ФАЗА 1:**
- Экономия: 61,500 → 21,400 tokens (65%)
- Время: 2 часа

---

### ФАЗА 2: Context Architecture (1.5 часа)

#### Шаг 2.1: Создать 1-STRATEGY.md для FoodTracker (10 мин)

**Файл: `{project}/.context/1-STRATEGY.md`**
```markdown
# FoodTracker - Стратегия

## Зачем проект
Telegram бот для трекинга еды через разговор с AI.

## Главные цели
1. Быстрый ввод (голос, фото, текст)
2. Умный анализ (AI понимает естественную речь)
3. Полезные отчеты (день, неделя, месяц)

## Что НЕ делаем
❌ НЕ фитнес-трекер
❌ НЕ книга рецептов
❌ НЕ для нескольких пользователей

## Критичные требования
- Бот ДОЛЖЕН отвечать <3 сек
- AI ДОЛЖЕН помнить историю (Memory node)
- Отчеты ДОЛЖНЫ показывать тренды
```

#### Шаг 2.2: Создать 2-INDEX.md (15 мин)

**Файл: `{project}/.context/2-INDEX.md`**
```markdown
# Навигация по контексту

## Для ВСЕХ агентов
- Прочитай: 1-STRATEGY.md

## Для Builder
⚠️ ПЕРЕД ИЗМЕНЕНИЕМ НОДЫ - прочитай её Intent Card!

| Нода | Intent Card | DO NOT TOUCH |
|------|-------------|--------------|
| AI Agent | nodes/ai-agent.md | Memory connection, jsonBody |
| Memory | nodes/memory.md | customKey='telegram_user_id' |
| Switch | nodes/switch.md | Обнови BotFather тоже! |

## Protected Nodes (НЕ удалять без approval!)
- Telegram Trigger (точка входа)
- AI Agent (главный обработчик)
- Memory (история разговоров)
```

#### Шаг 2.3: Создать flow.md (10 мин)
#### Шаг 2.4: Создать ADRs (30 мин)

**3-5 файлов:**
- 001-ai-agent-memory.md
- 002-inject-context.md
- 003-telegram-sync.md

#### Шаг 2.5: Создать Service Playbooks (15 мин)

**2-3 файла:**
- services/telegram.md
- services/supabase.md
- services/openai.md

#### Шаг 2.6: Создать Node Intent Cards (20 мин)

**5-7 файлов:**
- nodes/ai-agent.md
- nodes/memory.md
- nodes/switch.md
- nodes/inject-context.md
- nodes/telegram-trigger.md

**ИТОГО ФАЗА 2:**
- Создано: 15 файлов контекста
- Время: 1.5 часа

---

### ФАЗА 3: Builder Change Protocol (1 час)

#### Шаг 3.1: Обновить builder.md - Surgical Edits Protocol (30 мин)

**Добавить секцию:**

```markdown
# 🔧 SURGICAL EDITS PROTOCOL (CRITICAL!)

## Rule: Change ONLY what's needed

### ❌ FORBIDDEN (causes breakage):
```javascript
// BAD: Load full workflow
const workflow = await n8n_get_workflow({id, mode: "full"});
// → 58,000 tokens, risky to modify

// Modify multiple nodes
workflow.nodes[5].parameters.x = "new value";
workflow.nodes[12].parameters.y = "other value";

// Write everything back
await n8n_update_full_workflow({id, workflow});
// → High risk: accidental changes to unrelated nodes
```

### ✅ REQUIRED (safe surgical edit):
```javascript
// STEP 1: Read structure only (lightweight)
const structure = await n8n_get_workflow({
  id: workflow_id,
  mode: "structure"  // ~2,000 tokens
});

// STEP 2: Identify target nodes from edit_scope
const targetNodes = qa_report.edit_scope;  // ["Switch", "AI Agent"]

// STEP 3: Read ONLY target nodes
const details = await n8n_get_workflow({
  id: workflow_id,
  mode: "filtered",
  nodeNames: targetNodes
});

// STEP 4: Generate ChangeSet
const changeset = {
  what: "Add /water case to Switch",
  why: "User requested",
  nodes_affected: ["Switch"],
  risk: "low",
  rollback_plan: "Remove case from rules array"
};

// STEP 5: Create diff
const diff = {
  added: ["Switch.parameters.rules[7]"],
  changed: [],
  deleted: []
};

// STEP 6: Validate
if (!validate(diff)) {
  return {error: "Validation failed"};
}

// STEP 7: Apply ONLY to target nodes (partial update)
const result = await n8n_update_partial_workflow({
  id: workflow_id,
  operations: [
    {
      type: "updateNode",
      nodeName: "Switch",
      properties: {
        parameters: updated_parameters
      }
    }
  ]
});

// STEP 8: Log edit_scope
return {
  status: "success",
  edit_scope: ["Switch"],
  diff: diff,
  mcp_calls: [...]
};
```

## When to use partial vs full update

| Scenario | Use | Why |
|----------|-----|-----|
| Modify 1-3 nodes | `n8n_update_partial_workflow` | Safe, surgical |
| Add new node | `n8n_update_partial_workflow` | Isolated change |
| Delete node | `n8n_update_partial_workflow` | Controlled |
| Restructure >50% | `n8n_update_full_workflow` | Major refactor |
| Create from scratch | `n8n_create_workflow` | New workflow |

## Mandatory checks before update

- [ ] Read target node Intent Card
- [ ] Check Protected Nodes list
- [ ] Generate ChangeSet (what, why, risk)
- [ ] Create diff (added, changed, deleted)
- [ ] Validate: graph integrity, contracts
- [ ] Log edit_scope array
- [ ] Use partial update (unless major refactor)
```

#### Шаг 3.2: Обновить QA - Validate Edit Scope (15 мин)

**Добавить в qa.md:**

```markdown
# Edit Scope Validation

## After Builder update, QA MUST verify:

1. **Read Builder's edit_scope:**
   ```javascript
   const edit_scope = build_result.edit_scope;  // ["Switch", "AI Agent"]
   ```

2. **Get workflow and compare:**
   ```javascript
   const before = previous_version;
   const after = current_version;
   const actual_changes = diff(before, after);
   ```

3. **Verify ONLY edit_scope nodes changed:**
   ```javascript
   const unexpected_changes = actual_changes.filter(
     change => !edit_scope.includes(change.node)
   );

   if (unexpected_changes.length > 0) {
     return {
       status: "FAIL",
       error: "Unexpected changes detected!",
       details: unexpected_changes,
       action: "Rollback and fix Builder"
     };
   }
   ```

4. **Check Protected Nodes:**
   ```javascript
   const protected = ["Telegram Trigger", "AI Agent", "Memory"];
   const touched_protected = actual_changes.filter(
     change => protected.includes(change.node)
   );

   if (touched_protected.length > 0 && !user_approved) {
     return {
       status: "BLOCKED",
       error: "Protected node modified without approval!",
       node: touched_protected[0].node
     };
   }
   ```
```

#### Шаг 3.3: Enforcement в Orchestrator (15 мин)

**Добавить проверку после Builder:**

```bash
# After Builder returns
build_result_file="memory/agent_results/${workflow_id}/build_result.json"

# Check edit_scope exists
edit_scope=$(jq -r '.build_result.edit_scope // []' "$build_result_file")
if [ "$edit_scope" = "[]" ]; then
  echo "⚠️ WARNING: Builder didn't log edit_scope!"
  echo "Required for surgical edits verification"
fi

# Pass edit_scope to QA
Task({
  prompt: `## ROLE: QA

## TASK: Validate workflow

IMPORTANT: Builder claimed to change only these nodes:
${edit_scope}

Verify ONLY these nodes were actually modified!`
})
```

**ИТОГО ФАЗА 3:**
- Builder: surgical edits protocol
- QA: edit_scope validation
- Orchestrator: enforcement
- Время: 1 час

---

### ФАЗА 4: Protected Nodes + Validators (30 мин)

#### Шаг 4.1: Добавить Protected Nodes в INDEX (10 мин)

**В 2-INDEX.md:**

```markdown
## Protected Nodes (CRITICAL!)

| Node | Why Protected | DO NOT TOUCH | Break if modified |
|------|---------------|--------------|-------------------|
| Telegram Trigger | Entry point | Webhook path | Bot stops receiving messages |
| AI Agent | Core logic | Memory connection, jsonBody | Bot can't process requests |
| Memory | Session state | customKey | Users lose conversation history |
| Switch | Router | Command list | Must update BotFather too |

## Modification Rules

### Protected Node Changes:
1. Read Intent Card FIRST
2. Check DO NOT TOUCH section
3. IF modifying DO NOT TOUCH → get user approval
4. Generate ChangeSet with HIGH risk
5. QA validates extra carefully
```

#### Шаг 4.2: QA Validators (20 мин)

**Добавить в qa.md:**

```markdown
# Validators (Mandatory Checks)

## Validator 1: Graph Integrity
```javascript
function validateGraphIntegrity(workflow) {
  const nodeIds = workflow.nodes.map(n => n.id);

  // Check all connections reference existing nodes
  for (const [sourceId, connections] of Object.entries(workflow.connections)) {
    if (!nodeIds.includes(sourceId)) {
      return {valid: false, error: `Connection from non-existent node: ${sourceId}`};
    }

    for (const outputs of Object.values(connections)) {
      for (const conn of outputs) {
        if (!nodeIds.includes(conn.node)) {
          return {valid: false, error: `Connection to non-existent node: ${conn.node}`};
        }
      }
    }
  }

  return {valid: true};
}
```

## Validator 2: Required Nodes
```javascript
function validateRequiredNodes(workflow) {
  const required = ["Telegram Trigger", "AI Agent", "Memory"];
  const existing = workflow.nodes.map(n => n.name);

  const missing = required.filter(r => !existing.includes(r));

  if (missing.length > 0) {
    return {valid: false, error: `Missing required nodes: ${missing.join(', ')}`};
  }

  return {valid: true};
}
```

## Validator 3: Protected Nodes
```javascript
function validateProtectedNodes(before, after, edit_scope) {
  const protected = {
    "Memory": ["parameters.customKey"],
    "AI Agent": ["parameters.tools[].jsonBody"]
  };

  for (const [nodeName, protectedPaths] of Object.entries(protected)) {
    const beforeNode = before.nodes.find(n => n.name === nodeName);
    const afterNode = after.nodes.find(n => n.name === nodeName);

    for (const path of protectedPaths) {
      const beforeValue = getPath(beforeNode, path);
      const afterValue = getPath(afterNode, path);

      if (beforeValue !== afterValue) {
        return {
          valid: false,
          error: `Protected field modified: ${nodeName}.${path}`,
          requires: "USER_APPROVAL"
        };
      }
    }
  }

  return {valid: true};
}
```
```

**ИТОГО ФАЗА 4:**
- Protected Nodes list
- 3 validators implemented
- Время: 30 мин

---

## ЧАСТЬ 5: ЧТО ИЗМЕНИТСЯ (ДО/ПОСЛЕ)

### Сценарий 1: Builder меняет ноду

#### ❌ БЫЛО (до внедрения):
```
User: "Добавь команду /water в Switch"
  ↓
Orchestrator → Builder
  ↓
Builder:
- Читает весь workflow (58,000 tokens)
- Меняет Switch
- СЛУЧАЙНО меняет parameter в другой ноде
- update_full_workflow (весь workflow)
  ↓
QA: Validation PASS (структура OK, но функционал сломан)
  ↓
РЕЗУЛЬТАТ: /water работает, но фото-обработка сломалась
User: "БЛЯДЬ, ОПЯТЬ ВСЁ СЛОМАЛ!"
```

#### ✅ СТАЛО (после внедрения):
```
User: "Добавь команду /water в Switch"
  ↓
Orchestrator → Builder
  ↓
Builder:
1. Читает INDEX → видит "Switch → nodes/switch.md"
2. Читает nodes/switch.md → видит "DO NOT TOUCH: обнови BotFather"
3. Читает structure (2,000 tokens)
4. Читает ТОЛЬКО Switch node (100 tokens)
5. Генерирует ChangeSet:
   - what: "Add /water case"
   - why: "User requested"
   - nodes_affected: ["Switch"]
   - risk: "low"
6. Создает diff:
   - added: ["Switch.parameters.rules[7]"]
7. Применяет n8n_update_partial_workflow (ТОЛЬКО Switch)
8. Логирует edit_scope: ["Switch"]
  ↓
QA:
1. Получает edit_scope: ["Switch"]
2. Сравнивает before/after
3. Проверяет: ТОЛЬКО Switch изменен? ✅
4. Проверяет: Protected nodes не тронуты? ✅
5. Validator: graph integrity ✅
  ↓
РЕЗУЛЬТАТ: /water работает, остальное не тронуто
User: "НАКОНЕЦ-ТО РАБОТАЕТ!"
```

### Сценарий 2: Builder повторяет старую ошибку

#### ❌ БЫЛО:
```
User: "Почини tool Delete Meal"
  ↓
Builder (не знает про v432):
- Добавляет jsonBody к tool
- Бот замолчал (400 errors)
  ↓
User: "ЭТО УЖЕ В v432 ЛОМАЛИ!"
```

#### ✅ СТАЛО:
```
User: "Почини tool Delete Meal"
  ↓
Builder:
1. Читает INDEX → "AI Agent → nodes/ai-agent.md"
2. Читает nodes/ai-agent.md:
   ```
   ## DO NOT TOUCH
   НЕ добавляй jsonBody к tools

   ## История ошибок
   v432: Добавили jsonBody → бот замолчал → откат v434
   ```
3. Builder видит предупреждение!
4. Применяет fix БЕЗ jsonBody
  ↓
РЕЗУЛЬТАТ: Tool работает, бот не сломан
User: "FINALLY!"
```

### Сценарий 3: Orchestrator экономит tokens

#### ❌ БЫЛО:
```
Orchestrator → Builder:
prompt: `
${JSON.stringify(run_state, null, 2)}          // 800 tokens
${JSON.stringify(research_findings, null, 2)}  // 3,000 tokens
${JSON.stringify(build_guidance, null, 2)}     // 5,000 tokens

Build workflow...
`

ИТОГО в промпте: 8,800 tokens
```

#### ✅ СТАЛО:
```
Orchestrator → Builder:
prompt: `
Read files yourself:
1. memory/run_state_active.json
2. memory/agent_results/{id}/build_guidance.json
3. {project}/.context/2-INDEX.md

Build workflow...
`

ИТОГО в промпте: 200 tokens

Builder читает сам: 800 + 2,000 + 300 = 3,100 tokens
(файлы кэшируются, не дублируются)

ЭКОНОМИЯ: 8,800 → 200 = 97%
```

---

## ЧАСТЬ 6: РИСКИ И МИТИГАЦИЯ

### Риск 1: Слишком много новых файлов

**Проблема:** Service Playbooks + Node Intent Cards = 10-15 новых файлов

**Митигация:**
- Создавать ТОЛЬКО для критичных сервисов/нод
- Telegram, Supabase, OpenAI, Whisper = 4 Service Playbooks
- AI Agent, Memory, Switch, Inject Context, Trigger = 5 Node Intent Cards
- **ИТОГО: 9 файлов (не 50!)**

### Риск 2: Агенты не будут читать Intent Cards

**Проблема:** Builder может проигнорировать

**Митигация:**
- GATE в INDEX: "ПЕРЕД ИЗМЕНЕНИЕМ НОДЫ → прочитай Intent Card"
- Orchestrator enforcement: проверяет что Builder прочитал
- QA проверяет: Protected fields не изменились

### Риск 3: Intent Cards устареют

**Проблема:** После изменений карточки не обновляются

**Митигация (простая, без авто-генерации):**
- Analyst обновляет Intent Cards вручную после критичных изменений
- User approval: если изменение затрагивает DO NOT TOUCH → обновить карточку

### Риск 4: Surgical edits сломают что-то

**Проблема:** n8n_update_partial_workflow может не работать

**Митигация:**
- Fallback: если partial fails → use full
- QA всегда проверяет edit_scope (даже при full update)
- Rollback plan в ChangeSet

---

## ЧАСТЬ 7: МЕТРИКИ УСПЕХА

### Целевые показатели:

| Метрика | БЫЛО | ЦЕЛЬ | Измерение |
|---------|------|------|-----------|
| **Tokens per session** | 61,500 | 21,400 | 65% экономия |
| **Context files** | 250+ | 11 | Чистота |
| **Agent prompts** | 21,500 | 7,100 | 67% экономия |
| **Breakage rate** | 30% (3/10 tasks) | 5% (0.5/10) | User frustration |
| **Avg fix time** | 5 hours | 30 min | Efficiency |
| **Builder edit precision** | Full workflow | 1-3 nodes | Surgical |

### Как измерять:

**После каждой сессии:**
1. Сколько tokens потратили? (должно быть <25K)
2. Builder изменил ТОЛЬКО edit_scope? (должно быть YES)
3. Что-то сломалось? (должно быть NO)
4. Intent Card помогла? (спросить Builder в agent_log)

---

## ЧАСТЬ 8: ПОСЛЕДОВАТЕЛЬНОСТЬ ВНЕДРЕНИЯ (ФИНАЛ)

### Приоритеты (что делать в первую очередь):

| Приоритет | Фаза | Почему важно | Время |
|-----------|------|--------------|-------|
| **P0** | ФАЗА 1 (Agent Cleanup) | Экономия 65% tokens немедленно | 2ч |
| **P1** | ФАЗА 3 (Change Protocol) | Останавливает поломки | 1ч |
| **P2** | ФАЗА 2 (Context: ADRs + Node Intent Cards) | Агенты понимают ЗАЧЕМ/ПОЧЕМУ | 1.5ч |
| **P3** | ФАЗА 4 (Validators) | Дополнительная защита | 30мин |

### Минимальный MVP (если времени мало):

**Только P0 + P1 = 3 часа:**
1. Agent Cleanup (file-based context, shared files)
2. Builder Change Protocol (surgical edits, edit_scope)

**Результат MVP:**
- ✅ 65% экономия tokens
- ✅ Builder не ломает случайные ноды
- ⚠️ НО: агенты еще не видят Intent Cards

### Полное внедрение (рекомендовано):

**P0 + P1 + P2 + P3 = 5 часов:**
- Все 4 фазы
- Полная защита от поломок
- Агенты понимают контекст

---

## ФИНАЛЬНЫЙ ЧЕКЛИСТ

### Перед началом (подготовка):
- [ ] Бэкап всех .claude/agents/*.md файлов
- [ ] Бэкап .claude/commands/orch.md
- [ ] Git commit current state

### ФАЗА 1 (2 часа):
- [ ] Создать .claude/agents/shared/ (4 файла)
- [ ] Создать .claude/examples/
- [ ] Компактный orch.md (10K → 700 tokens)
- [ ] File-based context (заменить JSON.stringify на пути)
- [ ] Почистить agent/*.md (2500 → 900 tokens каждый)
- [ ] Тест: /orch --test agent:builder

### ФАЗА 2 (1.5 часа):
- [ ] Создать {project}/.context/1-STRATEGY.md
- [ ] Создать {project}/.context/2-INDEX.md
- [ ] Создать architecture/flow.md
- [ ] Создать 3 ADRs (001, 002, 003)
- [ ] Создать 3 Service Playbooks (telegram, supabase, openai)
- [ ] Создать 5 Node Intent Cards (ai-agent, memory, switch, inject-context, trigger)

### ФАЗА 3 (1 час):
- [ ] Обновить builder.md: Surgical Edits Protocol
- [ ] Обновить qa.md: Edit Scope Validation
- [ ] Обновить orch.md: Enforcement проверки
- [ ] Тест: /orch создать простой workflow, проверить edit_scope

### ФАЗА 4 (30 мин):
- [ ] Добавить Protected Nodes в 2-INDEX.md
- [ ] Добавить Validators в qa.md (3 validator functions)
- [ ] Тест: попытаться изменить protected node

### Финальный тест (15 мин):
- [ ] /orch --test e2e (полный тест системы)
- [ ] Реальная задача: "Добавь команду /test в FoodTracker"
- [ ] Проверить:
  - Builder прочитал Intent Card? ✅
  - Builder использовал partial update? ✅
  - edit_scope правильный? ✅
  - Validators прошли? ✅
  - Tokens < 25K? ✅

---

## ГОТОВ НАЧАТЬ?

**Скажи "ДЕЛАЕМ" и я начну с:**
1. ФАЗА 1, Шаг 1.1: Создание shared/ directory
2. Затем последовательно все шаги

**Или скажи "ТОЛЬКО MVP" и я сделаю:**
- Только ФАЗА 1 + ФАЗА 3 (3 часа)
- Минимум для остановки поломок

**Или задай вопросы если что-то непонятно!**
