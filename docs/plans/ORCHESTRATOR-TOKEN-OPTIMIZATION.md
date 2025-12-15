# ORCHESTRATOR TOKEN OPTIMIZATION PLAN

> **Дата:** 2025-12-15
> **Проблема:** Orchestrator тратит слишком много токенов на передачу контекста агентам
> **Текущее:** ~45,000 tokens на сессию только на контекст
> **Цель:** Снизить до ~5,000 tokens (90% экономия)

---

## ЧАСТЬ 1: АНАЛИЗ (ГДЕ УХОДЯТ ТОКЕНЫ)

### Текущая структура передачи контекста:

```javascript
// Orchestrator вызывает агента:
Task({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: `## ROLE: Builder Agent
Read: .claude/agents/builder.md  // ← 2,000 tokens

## CONTEXT
${JSON.stringify(run_state, null, 2)}  // ← 800 tokens
${JSON.stringify(research_findings, null, 2)}  // ← 3,000 tokens
${JSON.stringify(build_guidance, null, 2)}  // ← 5,000 tokens
${JSON.stringify(canonical_snapshot, null, 2)}  // ← 8,000 tokens

## TASK
Build the workflow based on guidance above`
})
```

**ИТОГО НА 1 AGENT CALL:** ~18,800 tokens

---

### Куда идут токены (breakdown):

| Компонент | Размер | Частота | Итого на сессию |
|-----------|--------|---------|-----------------|
| **orch.md** (сама команда) | 10,000 tokens | 1 раз | 10,000 |
| **Agent role file** (builder.md, qa.md, etc) | 2,000 tokens | 5 агентов | 10,000 |
| **run_state** (встроен в prompt) | 800 tokens | 5 агентов | 4,000 |
| **research_findings** (встроен) | 3,000 tokens | 3 агента (Architect, Builder, QA) | 9,000 |
| **build_guidance** (встроен) | 5,000 tokens | 2 агента (Builder, QA) | 10,000 |
| **canonical_snapshot** (встроен) | 8,000 tokens | 2 агента (Builder, Analyst) | 16,000 |
| **Сам промпт агента** (инструкции) | 500 tokens | 5 агентов | 2,500 |
| **ИТОГО** | | | **61,500 tokens** |

**ЭТО ТОЛЬКО КОНТЕКСТ!** Без ответов агентов, без MCP calls, без результатов!

---

### Проблемные места (top 5):

#### 1. orch.md слишком большой (10,000 tokens)

```bash
$ wc -w .claude/commands/orch.md
7533 words = ~10,000 tokens
```

**Почему:**
- История всех изменений (changelog)
- Детальные примеры для всех режимов
- Дублированные инструкции
- Комментарии и объяснения

**Решение:** Вынести в отдельные файлы

---

#### 2. JSON встроен в prompt (18,800 tokens)

```javascript
// ❌ СЕЙЧАС (плохо):
prompt: `## CONTEXT
${JSON.stringify(run_state)}  // весь объект в строке!
`

// ✅ ДОЛЖНО БЫТЬ (хорошо):
prompt: `## CONTEXT FILES
- run_state: memory/run_state_active.json (read yourself!)
`
```

**Проблема:** Orchestrator КОПИРУЕТ JSON в prompt вместо указания пути.

**Решение:** File-based context (агенты читают сами)

---

#### 3. Дублирование контекста (9,000 tokens лишних)

```
Architect вызывается:
  prompt включает: run_state (800) + research_findings (3000)

Researcher вызывается:
  prompt включает: run_state (800) + research_findings (3000)  ← ТО ЖЕ САМОЕ!

Builder вызывается:
  prompt включает: run_state (800) + research_findings (3000)  ← СНОВА!
```

**Проблема:** Одни и те же данные передаются 3-5 раз.

**Решение:** Агенты читают из файла (файл читается 1 раз, не копируется)

---

#### 4. canonical_snapshot избыточен (16,000 tokens)

```json
{
  "snapshot_metadata": {...},
  "node_inventory": {
    "nodes": [
      {
        "id": "...",
        "name": "...",
        "type": "...",
        "parameters": {...}  // ← 500-1000 токенов НА НОДУ!
      },
      // ... 58 нод = 58,000 tokens!!!
    ]
  }
}
```

**Проблема:** Builder НЕ НУЖНЫ все параметры всех нод! Он изменяет 1-2 ноды.

**Решение:** Lazy load через MCP (читать только нужные ноды)

---

#### 5. Agent role files дублируют CLAUDE.md (4,000 tokens)

```markdown
# builder.md (2000 tokens)
- Includes: gates, protocols, examples
- Много overlap с .claude/CLAUDE.md

# qa.md (2000 tokens)
- Includes: gates, protocols, examples
- Опять overlap!
```

**Проблема:** Каждый agent file повторяет общие правила.

**Решение:** Вынести общее в shared/, agents читают только специфичное

---

## ЧАСТЬ 2: РЕШЕНИЕ (FILE-BASED CONTEXT)

### Идея (просто):

**ВМЕСТО:**
```
Orchestrator → копирует JSON → встраивает в prompt → передает Agent
```

**ДЕЛАТЬ:**
```
Orchestrator → пишет JSON в файл → указывает путь в prompt → Agent читает сам
```

---

### Новая структура:

```
ORCHESTRATOR (роутер)
├── Создает: run_state_active.json (файл)
├── Передает агенту: ТОЛЬКО путь к файлу (50 tokens)
└── Агент читает: файл сам (не в промпте!)

AGENT (исполнитель)
├── Получает: prompt с путями к файлам (200 tokens)
├── Читает: только нужные файлы
└── Возвращает: результат (пишет в свой файл)
```

---

### Пример (Builder):

#### ❌ СЕЙЧАС (плохо):

```javascript
Orchestrator:

const run_state = read_json("memory/run_state_active.json");
const research = read_json("memory/agent_results/.../research_findings.json");
const guidance = read_json("memory/agent_results/.../build_guidance.json");

Task({
  prompt: `## ROLE: Builder

## CONTEXT
${JSON.stringify(run_state, null, 2)}
${JSON.stringify(research, null, 2)}
${JSON.stringify(guidance, null, 2)}

## TASK
Build workflow`
})

// ИТОГО В PROMPT: 8,800 tokens!
```

---

#### ✅ ДОЛЖНО БЫТЬ (хорошо):

```javascript
Orchestrator:

// НЕ читаем JSON! Только записываем пути
Task({
  prompt: `## ROLE: Builder
Read: .claude/agents/builder.md

## CONTEXT FILES
Read these files yourself (in order):
1. run_state: memory/run_state_active.json
2. guidance: memory/agent_results/{workflow_id}/build_guidance.json

## TASK
Build workflow based on guidance`
})

// ИТОГО В PROMPT: 200 tokens!
```

**Builder внутри:**
```javascript
// Читает сам (не через prompt!)
const run_state = Read("memory/run_state_active.json");
const guidance = Read("memory/agent_results/.../build_guidance.json");

// Использует
build_workflow(guidance);
```

**ЭКОНОМИЯ:** 8,800 → 200 tokens = **97% экономия!**

---

## ЧАСТЬ 3: PROGRESSIVE LOADING (читать только нужное)

### Проблема:

Builder читает **ВЕСЬ** build_guidance.json (5,000 tokens), даже если ему нужна только 1 секция.

```json
{
  "node_configs": [...],  // 2000 tokens
  "gotchas": [...],       // 1000 tokens
  "warnings": [...],      // 500 tokens
  "examples": [...],      // 1000 tokens
  "execution_analysis": {...}  // 500 tokens
}
```

Builder использует только `node_configs` (2000 tokens), остальное **ЛИШНЕЕ** (3000 tokens).

---

### Решение: INDEX внутри файла

```json
{
  "_index": {
    "node_configs": "Main section - MUST read",
    "gotchas": "Read if unfamiliar with node type",
    "warnings": "Read if cycle > 1",
    "examples": "Read if need pattern reference",
    "execution_analysis": "Read if fixing bug (not for new builds)"
  },

  "node_configs": [...],
  "gotchas": [...],
  // ...
}
```

**Builder prompt:**
```
## TASK
1. Read build_guidance._index
2. Read only REQUIRED sections (node_configs)
3. Read OPTIONAL sections IF needed
```

**ЭКОНОМИЯ:** 5,000 → 2,000 tokens = **60% экономия**

---

## ЧАСТЬ 4: ОПТИМИЗАЦИЯ orch.md (10,000 → 2,000 tokens)

### Текущая структура orch.md:

```markdown
# /orch

## Overview (500 tokens)
## Rules (1000 tokens)
## Modes (500 tokens)
## Gates (2000 tokens)  ← дублирует VALIDATION-GATES.md
## Examples (2000 tokens)
## Protocols (2000 tokens)  ← дублирует агентов
## Changelog (2000 tokens)  ← история, не нужна в промпте!
```

**ИТОГО:** 10,000 tokens

---

### Новая структура:

```markdown
# /orch

## Quick Reference (200 tokens)
- Modes: create, modify, fix, debug
- Allowed tools: Read, Write, Task, Bash
- Forbidden: ALL mcp__n8n-mcp__* tools

## Delegation Protocol (300 tokens)
- Route to correct agent
- Merge results to run_state
- Update stage

## File Locations (100 tokens)
- run_state: memory/run_state_active.json
- Gates: .claude/VALIDATION-GATES.md
- Protocols: .claude/agents/shared/*.md

## For Details (100 tokens)
Read:
- Gates: .claude/VALIDATION-GATES.md
- Escalation: .claude/PROGRESSIVE-ESCALATION.md
- Shared protocols: .claude/agents/shared/
```

**ИТОГО:** 700 tokens

**ЭКОНОМИЯ:** 10,000 → 700 tokens = **93% экономия**

---

### Что выносим:

| Из orch.md | Куда | Зачем |
|------------|------|-------|
| Gates (2000 tokens) | `.claude/VALIDATION-GATES.md` (уже есть!) | Дублирование |
| Protocols (2000 tokens) | `.claude/agents/shared/protocols.md` | Общее для всех |
| Changelog (2000 tokens) | `.claude/CHANGELOG-ORCH.md` | Не нужно в каждом промпте |
| Examples (1500 tokens) | `.claude/examples/orch-examples.md` | Reference, не inline |

**Orchestrator читает эти файлы ЕСЛИ НУЖНО** (не всегда).

---

## ЧАСТЬ 5: AGENT ROLE FILES (2,000 → 500 tokens)

### Текущая структура builder.md:

```markdown
# Builder

## L-075 Anti-Hallucination (500 tokens)  ← общее для ВСЕХ агентов
## Tool Access (200 tokens)  ← дубликат из CLAUDE.md
## Project Context Detection (800 tokens)  ← общее для ВСЕХ агентов
## MCP Tools Status (200 tokens)  ← дубликат
## Gates (300 tokens)  ← дубликат из VALIDATION-GATES.md
## Builder-specific (500 tokens)  ← ТОЛЬКО это нужно!
```

**ИТОГО:** 2,500 tokens

---

### Новая структура:

```markdown
# Builder

## Read First (100 tokens)
- Shared: .claude/agents/shared/anti-hallucination.md
- Shared: .claude/agents/shared/project-context.md
- Gates: .claude/VALIDATION-GATES.md

## Builder-Specific Role (400 tokens)
- Create/modify workflows via MCP
- ONLY agent that mutates workflows
- Must log mcp_calls array

## Critical Rules (200 tokens)
- Never simulate MCP responses
- Verify version changed after update
- Read build_guidance before building

## Context Loading (200 tokens)
1. Read run_state: memory/run_state_active.json
2. Read guidance: memory/agent_results/{workflow_id}/build_guidance.json
3. Read project context: {project_path}/.context/2-INDEX.md
```

**ИТОГО:** 900 tokens

**ЭКОНОМИЯ:** 2,500 → 900 tokens = **64% экономия**

---

## ЧАСТЬ 6: ИТОГОВАЯ ЭКОНОМИЯ (ТАБЛИЦА)

### Текущие затраты (на 1 сессию):

| Компонент | Tokens | Количество | Итого |
|-----------|--------|------------|-------|
| orch.md | 10,000 | 1 | 10,000 |
| Agent role (builder.md, qa.md, etc) | 2,500 | 5 агентов | 12,500 |
| run_state (in prompt) | 800 | 5 агентов | 4,000 |
| research_findings (in prompt) | 3,000 | 3 агента | 9,000 |
| build_guidance (in prompt) | 5,000 | 2 агента | 10,000 |
| canonical_snapshot (in prompt) | 8,000 | 2 агента | 16,000 |
| **TOTAL CONTEXT** | | | **61,500** |

---

### После оптимизации:

| Компонент | Tokens | Количество | Итого |
|-----------|--------|------------|-------|
| orch.md (compact) | 700 | 1 | 700 |
| Agent role (compact) | 900 | 5 агентов | 4,500 |
| File paths (in prompt) | 200 | 5 агентов | 1,000 |
| Agent reads files themselves | - | - | 0 (не в промпте!) |
| **TOTAL CONTEXT** | | | **6,200** |

**ЭКОНОМИЯ:** 61,500 → 6,200 = **55,300 tokens (90% экономия!)**

---

### Реальные затраты (включая чтение):

Агенты всё равно **ЧИТАЮТ** файлы, но это **НЕ дублируется** в промпте:

| Агент | Читает | Tokens |
|-------|--------|--------|
| Architect | run_state + INDEX | 800 + 300 = 1,100 |
| Researcher | run_state + INDEX + LEARNINGS-INDEX | 800 + 300 + 2,500 = 3,600 |
| Builder | run_state + build_guidance + INDEX | 800 + 2,000 + 300 = 3,100 |
| QA | run_state + qa_report (prev) + INDEX | 800 + 500 + 300 = 1,600 |
| Analyst | run_state + ALL files | 800 + 5,000 = 5,800 |
| **TOTAL** | | **15,200** |

**БЫЛО:** 61,500 tokens (в промптах)
**СТАЛО:** 6,200 (промпты) + 15,200 (агенты читают) = **21,400 tokens**

**ИТОГОВАЯ ЭКОНОМИЯ:** 61,500 → 21,400 = **40,100 tokens (65% экономия)**

---

## ЧАСТЬ 7: ПОШАГОВЫЙ ПЛАН ОПТИМИЗАЦИИ

### ШАГ 1: Вынести общее из agent files (30 мин)

**Что делаем:**
```bash
# Создать shared файлы:
.claude/agents/shared/
├── anti-hallucination.md      (L-075 protocol)
├── project-context.md          (context detection)
├── mcp-tools-status.md         (MCP status)
└── gates-reference.md          (gate checklist)
```

**Обновить агентов:**
```markdown
# builder.md (было 2500 tokens → станет 900)

## Read First
- .claude/agents/shared/anti-hallucination.md
- .claude/agents/shared/project-context.md
- .claude/VALIDATION-GATES.md

## Builder-Specific
[только уникальное для Builder]
```

**Повторить для:** researcher.md, qa.md, architect.md, analyst.md

**ЭКОНОМИЯ:** 12,500 → 4,500 tokens

---

### ШАГ 2: Компактный orch.md (20 мин)

**Что делаем:**
```bash
# Вынести из orch.md:
.claude/
├── CHANGELOG-ORCH.md           (история изменений)
├── examples/
│   └── orch-examples.md        (примеры использования)
└── commands/
    └── orch.md                 (COMPACT - только суть)
```

**Новый orch.md:**
```markdown
# /orch

## Quick Reference
[200 tokens]

## Delegation Protocol
[300 tokens]

## File Locations
[100 tokens]

## For Details
Read: .claude/CHANGELOG-ORCH.md, .claude/examples/orch-examples.md
```

**ЭКОНОМИЯ:** 10,000 → 700 tokens

---

### ШАГ 3: File-based context (40 мин)

**Что делаем:**

Изменить Orchestrator промпты с:
```javascript
// ❌ СТАРОЕ
Task({
  prompt: `## CONTEXT
${JSON.stringify(run_state)}`
})
```

На:
```javascript
// ✅ НОВОЕ
Task({
  prompt: `## CONTEXT FILES
- run_state: memory/run_state_active.json
- guidance: memory/agent_results/{workflow_id}/build_guidance.json

Read these files yourself (in order)`
})
```

**Обновить:** ~15 мест в orch.md где вызываются агенты

**ЭКОНОМИЯ:** ~45,000 tokens (дубликаты JSON исчезнут)

---

### ШАГ 4: Progressive loading в build_guidance (15 мин)

**Что делаем:**

Researcher создает build_guidance с индексом:
```json
{
  "_index": {
    "node_configs": "REQUIRED - node configurations",
    "gotchas": "Optional - read if unfamiliar",
    "warnings": "Optional - read if cycle > 1",
    "examples": "Reference - read if need pattern"
  },
  "node_configs": [...],
  "gotchas": [...],
  "warnings": [...],
  "examples": [...]
}
```

Builder читает:
1. `_index` (50 tokens)
2. `node_configs` (REQUIRED - 2000 tokens)
3. Остальное - только если нужно

**ЭКОНОМИЯ:** 5,000 → 2,000-3,000 tokens

---

### ШАГ 5: Lazy load canonical_snapshot (10 мин)

**Что делаем:**

Вместо:
```javascript
// ❌ СТАРОЕ
const snapshot = read_json("canonical.json");  // 58,000 tokens!
prompt = `${JSON.stringify(snapshot)}`;
```

Делать:
```javascript
// ✅ НОВОЕ
prompt = `Canonical snapshot: {project_path}/.n8n/canonical.json

IF you need node details:
  Call: mcp n8n_get_workflow mode=filtered nodeNames=["AI Agent"]

DON'T read entire snapshot!`
```

**ЭКОНОМИЯ:** 16,000 tokens (не передается в prompt)

---

### ШАГ 6: Тест (15 мин)

**Что делаем:**
```bash
# Запустить тестовую задачу
/orch create simple webhook workflow

# Проверить логи:
- Orchestrator prompt size < 1,000 tokens ✅
- Builder reads files himself ✅
- Total context < 10,000 tokens ✅
```

---

**ИТОГО ВРЕМЯ:** ~2 часа на полную оптимизацию

---

## ЧАСТЬ 8: ДО/ПОСЛЕ (ВИЗУАЛЬНО)

### БЫЛО (сейчас):

```
User: "/orch create webhook"
  ⬇️
Orchestrator:
  orch.md: 10,000 tokens
  prompt для Architect: 12,000 tokens
    ├── role: 2,500 tokens
    ├── run_state: 800 tokens (JSON in prompt)
    └── instructions: 500 tokens
  ⬇️
Architect returns
  ⬇️
Orchestrator:
  prompt для Researcher: 15,000 tokens
    ├── role: 2,500 tokens
    ├── run_state: 800 tokens (СНОВА!)
    ├── requirements: 1,000 tokens (JSON in prompt)
    └── instructions: 500 tokens
  ⬇️
[... еще 3 агента ...]

TOTAL CONTEXT: 61,500 tokens
```

---

### СТАЛО (после оптимизации):

```
User: "/orch create webhook"
  ⬇️
Orchestrator:
  orch.md: 700 tokens (compact)
  prompt для Architect: 1,200 tokens
    ├── role reference: 100 tokens
    ├── files to read: 200 tokens (PATHS only!)
    └── instructions: 200 tokens
  ⬇️
Architect:
  Reads: run_state (800 tokens) himself
  Reads: INDEX (300 tokens) himself
  ⬇️
Architect returns
  ⬇️
Orchestrator:
  prompt для Researcher: 1,400 tokens
    ├── role reference: 100 tokens
    ├── files to read: 300 tokens (PATHS only!)
    └── instructions: 200 tokens
  ⬇️
Researcher:
  Reads: run_state (800 tokens) - file already cached!
  Reads: requirements (500 tokens) himself
  Reads: LEARNINGS-INDEX (2,500 tokens) himself
  ⬇️
[... еще 3 агента ...]

TOTAL CONTEXT: 21,400 tokens (65% экономия!)
```

---

## ЧАСТЬ 9: BONUS ОПТИМИЗАЦИИ

### 1. Кэширование файлов между агентами

**Идея:** Если Architect прочитал `run_state.json`, то Researcher НЕ читает снова (использует кэш).

**Реализация:**
- Claude Code автоматически кэширует файлы внутри сессии
- Если файл НЕ изменился → чтение из кэша (0 tokens!)

**ЭКОНОМИЯ:** ~5,000 tokens (повторные чтения)

---

### 2. Дельта-обновления run_state

**Идея:** Вместо чтения всего run_state, агент читает только ИЗМЕНЕНИЯ.

```json
// run_state_delta.json (вместо full run_state)
{
  "stage": "build",  // changed
  "cycle_count": 2,  // changed
  "last_agent": {    // new
    "agent": "qa",
    "result": "FAILED"
  }
  // всё остальное БЕЗ изменений - не передается!
}
```

**ЭКОНОМИЯ:** 800 → 200 tokens (75%)

---

### 3. Conditional context loading

**Идея:** Разные агенты читают разные файлы.

| Агент | Читает | НЕ читает |
|-------|--------|-----------|
| Architect | run_state, INDEX | build_guidance, canonical_snapshot |
| Researcher | run_state, INDEX, LEARNINGS-INDEX | canonical_snapshot |
| Builder | run_state, build_guidance, INDEX | LEARNINGS (уже в guidance) |
| QA | run_state, qa_report (prev), INDEX | build_guidance, LEARNINGS |
| Analyst | ALL files | - |

**ЭКОНОМИЯ:** ~8,000 tokens (агенты не читают лишнее)

---

## ЧАСТЬ 10: ИТОГОВАЯ ЭКОНОМИЯ

### На 1 сессию:

| Метрика | БЫЛО | СТАЛО | Экономия |
|---------|------|-------|----------|
| Context в промптах | 61,500 | 6,200 | **90%** |
| Агенты читают файлы | 0 (в промпте!) | 15,200 | - |
| **TOTAL** | **61,500** | **21,400** | **65%** |

---

### На 10 сессий:

| Метрика | БЫЛО | СТАЛО | Экономия $ |
|---------|------|-------|------------|
| Context tokens | 615,000 | 214,000 | 401,000 |
| Cost ($0.003/1K input) | $1.85 | $0.64 | **$1.21** |

**+ учитывая output tokens (~2x input):**
- БЫЛО: $5.50 на 10 сессий
- СТАЛО: $1.90 на 10 сессий
- **ЭКОНОМИЯ: $3.60 на 10 сессий** (65%)

---

## ЧАСТЬ 11: ЧТО НУЖНО СДЕЛАТЬ (CHECKLIST)

### Подготовка (20 мин):
- [ ] Создать `.claude/agents/shared/` directory
- [ ] Создать `.claude/examples/` directory
- [ ] Бэкап текущих файлов

### Оптимизация файлов (1 час):
- [ ] Вынести L-075 в `shared/anti-hallucination.md`
- [ ] Вынести project context в `shared/project-context.md`
- [ ] Вынести MCP status в `shared/mcp-tools-status.md`
- [ ] Обновить builder.md (2500 → 900 tokens)
- [ ] Обновить researcher.md (2500 → 900 tokens)
- [ ] Обновить qa.md (2500 → 900 tokens)
- [ ] Обновить architect.md (2000 → 800 tokens)
- [ ] Обновить analyst.md (2000 → 800 tokens)

### Оптимизация orch.md (30 мин):
- [ ] Вынести changelog в `CHANGELOG-ORCH.md`
- [ ] Вынести примеры в `examples/orch-examples.md`
- [ ] Компактный orch.md (10,000 → 700 tokens)

### File-based context (40 мин):
- [ ] Найти все `JSON.stringify(run_state)` в orch.md
- [ ] Заменить на file paths
- [ ] Обновить agent prompts (15 мест)
- [ ] Тест: проверить что агенты читают файлы сами

### Progressive loading (15 мин):
- [ ] Обновить Researcher: добавить `_index` в build_guidance
- [ ] Обновить Builder: читать только нужные секции

### Тест (15 мин):
- [ ] `/orch --test` (quick health check)
- [ ] `/orch create simple workflow` (real test)
- [ ] Проверить логи: context < 10,000 tokens
- [ ] Проверить работоспособность

---

**TOTAL TIME:** ~2 часа

---

## ФИНАЛЬНЫЙ ОТВЕТ

**ДА, ORCHESTRATOR ТРАТИТ СЛИШКОМ МНОГО!**

**Проблема:**
- 61,500 tokens на контекст (только передача!)
- JSON встроен в промпты (дублируется 5 раз)
- Agent files дублируют общие правила

**Решение:**
- File-based context (агенты читают сами)
- Компактный orch.md (10K → 700 tokens)
- Вынести общее в shared/
- Progressive loading (читать только нужное)

**Результат:**
- 61,500 → 21,400 tokens (65% экономия)
- $5.50 → $1.90 на 10 сессий (экономия $3.60)

**Время на реализацию:** 2 часа

---

**Готов начать оптимизацию?** Скажи "ДЕЛАЕМ" и я начну с создания shared/ файлов.
