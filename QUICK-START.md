# Быстрый старт для нового бота

## Инструкция
Прочитай полный план: `/Users/sergey/Projects/ClaudeN8N/IMPLEMENTATION-PLAN.md`

## Порядок выполнения

### ФАЗА 0: Подготовка (10 мин)
```bash
# Создать директории
mkdir -p /Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/decisions
mkdir -p /Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/services
mkdir -p /Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/nodes
mkdir -p /Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/technical
mkdir -p /Users/sergey/Projects/ClaudeN8N/.claude/agents/shared
mkdir -p /Users/sergey/Projects/ClaudeN8N/.claude/hooks

# Удалить cycle файлы
find /Users/sergey/Projects/ClaudeN8N/memory/agent_results -name "*_cycle*.json" -delete
```

### ФАЗА 1: .context/ файлы (1.5 часа)
Создать 10 файлов с ТОЧНЫМ содержимым из IMPLEMENTATION-PLAN.md:

1. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/1-STRATEGY.md`
2. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/2-INDEX.md`
3. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/flow.md`
4. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/decisions/001-ai-agent-memory.md`
5. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/decisions/002-inject-context.md`
6. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/decisions/003-telegram-sync.md`
7. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/services/telegram.md`
8. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/services/supabase.md`
9. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/architecture/nodes/ai-agent.md`
10. `/Users/sergey/Projects/MultiBOT/bots/food-tracker/.context/technical/state.json`

### ФАЗА 2: shared/ файлы (1 час)
Создать 4 файла:

11. `/Users/sergey/Projects/ClaudeN8N/.claude/agents/shared/anti-hallucination.md`
12. `/Users/sergey/Projects/ClaudeN8N/.claude/agents/shared/project-context.md`
13. `/Users/sergey/Projects/ClaudeN8N/.claude/agents/shared/surgical-edits.md`
14. `/Users/sergey/Projects/ClaudeN8N/.claude/agents/shared/context-update.md`

### ФАЗА 3: hooks/ (30 мин)
Создать 2 hook файла:

15. `/Users/sergey/Projects/ClaudeN8N/.claude/hooks/block-full-update.md`
16. `/Users/sergey/Projects/ClaudeN8N/.claude/hooks/enforce-context-update.md`

### ФАЗА 4: Обновить агентов (1 час)
Изменить 5 файлов (читай IMPLEMENTATION-PLAN.md секции "Изменения в..."):

- `.claude/agents/builder.md` - добавить surgical edits, pre-flight
- `.claude/agents/qa.md` - добавить edit_scope validation
- `.claude/agents/analyst.md` - добавить context update protocol
- `.claude/agents/researcher.md` - добавить pre-flight
- `.claude/agents/architect.md` - добавить pre-flight

### ФАЗА 5: Обновить orch.md (30 мин)
Изменить `.claude/commands/orch.md`:
- File-based context в Task calls
- Enforcement после Builder

### ФАЗА 6: Тест (30 мин)
```bash
# Простая задача
/orch "Add /test command to FoodTracker Switch"

# Проверить:
# - Builder читает INDEX → ADR
# - Builder использует partial update
# - Builder логирует edit_scope
# - QA проверяет edit_scope
# - Analyst обновляет INDEX
```

---

## ВАЖНО!
- Копируй содержимое файлов ТОЧНО из IMPLEMENTATION-PLAN.md
- Выполняй фазы ПО ПОРЯДКУ
- После каждой фазы проверяй что файлы созданы
- Используй Write tool для новых файлов
- Используй Edit tool для изменения существующих

## Проект
- **Path:** `/Users/sergey/Projects/MultiBOT/bots/food-tracker/`
- **Workflow ID:** `sw3Qs3Fe3JahEbbW`
- **ClaudeN8N Path:** `/Users/sergey/Projects/ClaudeN8N/`
