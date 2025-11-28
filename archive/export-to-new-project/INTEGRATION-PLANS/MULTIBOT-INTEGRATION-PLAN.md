# MultiBOT Integration Plan

> План интеграции системы 5 агентов ClaudeN8N с проектом MultiBOT Food Tracker

**Дата:** 2025-11-28
**Статус:** ✅ Phase 2 Complete (5/5 файлов готово)

---

## 🎯 Цель

Работать над MultiBOT food-tracker из директории ClaudeN8N, используя систему 5 агентов для создания n8n workflows, при этом:
- ✅ TODO.md, PLAN.md, SESSION_CONTEXT.md остаются в MultiBOT
- ✅ LEARNINGS.md, агенты, MCP остаются в ClaudeN8N
- ✅ Нулевые breaking changes

---

## 📐 Архитектура

```
ClaudeN8N/                        ← РАБОЧАЯ ДИРЕКТОРИЯ (открыта в VS Code)
├── .claude/
│   ├── agents/                   ← Модифицированы (+15 строк каждый)
│   │   ├── researcher.md         ← ✅ TODO
│   │   ├── builder.md            ← ⏳ TODO
│   │   ├── qa.md                 ← ⏳ TODO
│   │   └── analyst.md            ← ⏳ TODO
│   └── commands/
│       ├── orch.md               ← ✅ DONE (+20 строк)
│       └── pm.md                 ← ⏳ TODO (опционально)
├── memory/
│   └── run_state.json            ← Теперь с project_id, project_path
└── docs/learning/                ← Общая база знаний n8n

MultiBOT/bots/food-tracker/       ← ЦЕЛЕВОЙ ПРОЕКТ (только файлы)
├── SESSION_CONTEXT.md            ← PM читает/пишет
├── TODO.md                       ← Активные задачи
├── PLAN.md                       ← Таймлайн проекта
├── ARCHITECTURE.md               ← Агенты читают дизайн
└── workflows/                    ← Бэкапы n8n workflows
```

---

## 🔧 Как это работает

### 1. Вызов команды

```bash
# Из ClaudeN8N директории:
/orch --project=food-tracker workflow_id=NhyjL9bCPSrTM6XG Add Window Buffer Memory

# Или через PM:
/pm --project=food-tracker continue
```

### 2. Orchestrator парсит --project флаг

```bash
# В orch.md:
if [[ "$user_request" =~ --project=([a-z-]+) ]]; then
  project_id="${BASH_REMATCH[1]}"

  case "$project_id" in
    "food-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/food-tracker"
      ;;
    "clauden8n"|"")
      project_path="/Users/sergey/Projects/ClaudeN8N"
      project_id="clauden8n"
      ;;
  esac
fi
```

### 3. run_state.json получает project context

```json
{
  "project_id": "food-tracker",
  "project_path": "/Users/sergey/Projects/MultiBOT/bots/food-tracker",
  "stage": "clarification",
  "user_request": "Add Window Buffer Memory",
  ...
}
```

### 4. Агенты читают project_path

```bash
# В researcher.md, builder.md, qa.md:
project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state.json)

# Читают документацию проекта:
cat "$project_path/SESSION_CONTEXT.md"
cat "$project_path/TODO.md"
cat "$project_path/ARCHITECTURE.md"

# Пишут туда же:
echo "Updated task" >> "$project_path/TODO.md"
```

### 5. База знаний остается общей

```bash
# ВСЕГДА читают из ClaudeN8N:
cat /Users/sergey/Projects/ClaudeN8N/docs/learning/LEARNINGS-INDEX.md
cat /Users/sergey/Projects/ClaudeN8N/docs/learning/PATTERNS.md
```

---

## ✅ Прогресс реализации

| Фаза | Файл | Строк | Статус |
|------|------|-------|--------|
| **Phase 1** | `.claude/commands/orch.md` | +51 | ✅ DONE |
| **Phase 2** | `.claude/agents/researcher.md` | +22 | ✅ DONE |
| **Phase 2** | `.claude/agents/builder.md` | +26 | ✅ DONE |
| **Phase 2** | `.claude/agents/qa.md` | +20 | ✅ DONE |
| **Phase 2** | `.claude/agents/analyst.md` | +17 | ✅ DONE |
| **Phase 3** | `.claude/commands/pm.md` | +15 | ⏳ TODO (optional) |
| **Phase 4** | Testing | - | ⏳ TODO |

**Всего:** ~70 строк кода, 5 файлов

---

## 📝 Детали модификаций

### ✅ 1. orch.md (DONE)

**Добавлено:** Секция "Project Selection" перед "Session Start"

**Что делает:**
- Парсит `--project=NAME` флаг
- Устанавливает `project_id` и `project_path`
- Сохраняет контекст в `run_state.json`
- Запоминает проект между сессиями

**Код:**
```bash
if [[ "$user_request" =~ --project=([a-z-]+) ]]; then
  project_id="${BASH_REMATCH[1]}"
  case "$project_id" in
    "food-tracker")
      project_path="/Users/sergey/Projects/MultiBOT/bots/food-tracker"
      ;;
  esac
fi
```

---

### ⏳ 2. researcher.md (TODO)

**Добавить:** Секция "Project Context Detection" в начале

**Что делает:**
- Читает `project_path` из `run_state.json`
- Загружает SESSION_CONTEXT.md, ARCHITECTURE.md из целевого проекта
- Использует общую базу знаний LEARNINGS.md

**Код:**
```bash
project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state.json)

# Читать контекст проекта:
[ -f "$project_path/SESSION_CONTEXT.md" ] && cat "$project_path/SESSION_CONTEXT.md"
[ -f "$project_path/ARCHITECTURE.md" ] && cat "$project_path/ARCHITECTURE.md"

# Learnings всегда из ClaudeN8N:
cat /Users/sergey/Projects/ClaudeN8N/docs/learning/LEARNINGS-INDEX.md
```

---

### ⏳ 3. builder.md (TODO)

**Добавить:** Секция "Project Context Detection" в начале

**Что делает:**
- Читает `project_path` из `run_state.json`
- Загружает ARCHITECTURE.md перед билдом
- Пишет бэкапы workflows в `$project_path/workflows/`

**Код:**
```bash
project_path=$(jq -r '.project_path // "/Users/sergey/Projects/ClaudeN8N"' memory/run_state.json)

# Перед билдом читать архитектуру:
cat "$project_path/ARCHITECTURE.md" 2>/dev/null

# Бэкапы workflows:
[ -d "$project_path/workflows" ] && cp workflow.json "$project_path/workflows/backup_$(date +%s).json"
```

---

### ⏳ 4. qa.md (TODO)

**Добавить:** Такую же секцию как в builder.md

**Что делает:**
- Читает контекст проекта для валидации
- Проверяет соответствие требованиям из ARCHITECTURE.md

---

### ⏳ 5. analyst.md (TODO)

**Добавить:** Секция "Project Context"

**Что делает:**
- Читает `project_path`
- Пишет learnings в ClaudeN8N (глобальные)
- Может писать project-specific notes в `$project_path/docs/learning/` (если нужно)

---

### ⏳ 6. pm.md (OPTIONAL)

**Добавить:** Секцию "n8n Workflow Delegation"

**Что делает:**
- Определяет когда задача связана с n8n (workflow, memory, nodes)
- Делегирует к `/orch --project=NAME`

**Код:**
```bash
if [[ "$current_task" =~ "workflow"|"n8n"|"memory" ]]; then
  /orch --project=$project_id $task_description
fi
```

---

## 🧪 План тестирования

### Test 1: Выбор проекта food-tracker

```bash
/orch --project=food-tracker Create test workflow for memory management
```

**Ожидается:**
- ✅ `run_state.json` содержит `"project_id": "food-tracker"`
- ✅ `run_state.json` содержит правильный `project_path`
- ✅ Architect читает `food-tracker/SESSION_CONTEXT.md`
- ✅ Workflow создан в n8n instance

### Test 2: Модификация существующего workflow

```bash
/orch workflow_id=NhyjL9bCPSrTM6XG Add Window Buffer Memory node
```

**Ожидается:**
- ✅ Builder читает `food-tracker/ARCHITECTURE.md`
- ✅ Builder модифицирует workflow NhyjL9bCPSrTM6XG
- ✅ Бэкап сохранен в `food-tracker/workflows/`
- ✅ QA валидирует против требований food-tracker

### Test 3: Переключение обратно на ClaudeN8N

```bash
/orch --project=clauden8n Create demo webhook workflow
```

**Ожидается:**
- ✅ `run_state.json` обновлен на `"project_id": "clauden8n"`
- ✅ Работает как раньше, без интерференции

---

## 📊 Критерии успеха

### Must Have (обязательно)

- ✅ `/orch --project=food-tracker` работает из ClaudeN8N
- ✅ Агенты читают food-tracker TODO.md, SESSION_CONTEXT.md, ARCHITECTURE.md
- ✅ Learnings пишутся в ClaudeN8N/docs/learning/LEARNINGS.md
- ✅ run_state.json помнит project_path между вызовами
- ✅ ClaudeN8N `/orch` (без --project) работает как раньше

### Nice to Have (желательно)

- ✅ `/pm` автоматически делегирует n8n задачи к `/orch`
- ✅ Builder пишет бэкапы в food-tracker/workflows/
- ✅ Можно переключаться между проектами через `--project`

---

## 🚀 Следующие шаги

1. **Завершить Phase 2** - модифицировать 4 файла агентов:
   - researcher.md
   - builder.md
   - qa.md
   - analyst.md

2. **Протестировать** с food-tracker Task 2.3:
   ```bash
   /orch --project=food-tracker workflow_id=NhyjL9bCPSrTM6XG Add Window Buffer Memory for conversation history
   ```

3. **Завершить food-tracker Phase 2** используя агенты:
   - Task 2.3: Memory Management
   - Task 2.4: Main Workflow + AI Agent
   - Task 2.5: Testing & Tuning

4. **Добавить другие проекты** (если успешно):
   ```bash
   # В orch.md добавить в case:
   "health-tracker")
     project_path="/Users/sergey/Projects/MultiBOT/bots/health-tracker"
     ;;
   ```

5. **Документировать паттерн** в README.md

---

## 🔄 Пример использования

### Сценарий 1: Работа над food-tracker

```bash
# Открыть ClaudeN8N в VS Code
cd /Users/sergey/Projects/ClaudeN8N

# Работать с food-tracker через агенты
/orch --project=food-tracker workflow_id=NhyjL9bCPSrTM6XG Add Window Buffer Memory

# Агенты:
# 1. Читают food-tracker/SESSION_CONTEXT.md (Phase 2, Task 2.3)
# 2. Читают food-tracker/ARCHITECTURE.md (37 nodes structure)
# 3. Используют ClaudeN8N/docs/learning/ (общие знания n8n)
# 4. Создают/модифицируют workflow в n8n instance
# 5. Обновляют food-tracker/TODO.md (Task 2.3 → completed)
```

### Сценарий 2: Переключение между проектами

```bash
# Работа над food-tracker
/orch --project=food-tracker Create memory node

# Быстро переключиться на ClaudeN8N
/orch --project=clauden8n Create test webhook

# Вернуться к food-tracker (проект запомнен)
/orch Add error handling to memory node
```

---

## ⚠️ Риски и митигации

### Risk 1: Агенты не могут читать внешние файлы

**Вероятность:** Низкая
**Влияние:** Высокое
**Митигация:** Протестировать с `cat $project_path/TODO.md` в первой имплементации
**Fallback:** Добавить symlinks если Read tool имеет ограничения по путям

### Risk 2: jq не доступен

**Вероятность:** Низкая (macOS has jq)
**Влияние:** Среднее
**Митигация:** Проверить `which jq` перед имплементацией
**Fallback:** Использовать grep/sed для JSON parsing

### Risk 3: PM делегация сложна

**Вероятность:** Средняя
**Влияние:** Низкое
**Митигация:** Начать без PM интеграции (Phase 3 опциональна)
**Fallback:** Вызывать /orch вручную, пропустить PM делегацию

---

## 📚 Ссылки

- **Полный план:** `/Users/sergey/.claude/plans/noble-prancing-curry.md`
- **MultiBOT food-tracker:** `/Users/sergey/Projects/MultiBOT/bots/food-tracker/`
- **Session Context:** `/Users/sergey/Projects/MultiBOT/bots/food-tracker/SESSION_CONTEXT.md`
- **LEARNINGS:** `/Users/sergey/Projects/ClaudeN8N/docs/learning/LEARNINGS.md`

---

**Время на реализацию:** 1.5-2 часа
**Сложность изменений:** Низкая (~70 строк)
**Breaking changes:** Нулевые

**Готов продолжить реализацию!** 🚀
