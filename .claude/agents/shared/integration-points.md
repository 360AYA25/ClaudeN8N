# Integration Points для run-state-lib.sh

**Version:** 1.0.0 (2025-12-11)
**Purpose:** Документация где и как использовать новые функции

---

## Где использовать функции

### orch.md

**Секции для замены (Phase 2 - NOT YET APPLIED):**

| Строки | Текущий код | Новая функция | Экономия |
|--------|-------------|---------------|----------|
| 294-334 | 11 повторов `jq '.stage = "..."'` | `update_stage()` | ~2,300 токенов |
| 912-924 | Inline session initialization | `init_run_state()` | ~500 токенов |
| Разбросано | Inline `jq '.agent_log += [...]'` | `append_agent_log()` | ~1,000 токенов |

**Примеры использования (после Phase 2):**

```bash
# Source library
source .claude/agents/shared/run-state-lib.sh

# Update stage (вместо 11 строк jq)
update_stage "research"
update_stage "decision"
update_stage "implementation"

# Initialize session (вместо 15 строк)
init_run_state

# Append log (вместо 8 строк jq)
append_agent_log "orchestrator" "session_started" "New CREATE flow"
```

### architect.md

**Секции для замены:**
- Append to agent_log → `append_agent_log()`
- Update requirements → `merge_agent_result()`

**Пример:**
```bash
source .claude/agents/shared/run-state-lib.sh
append_agent_log "architect" "clarification_complete" "Requirements extracted"
```

### researcher.md, builder.md, qa.md, analyst.md

**Секции для замены:**
- Append to agent_log → `append_agent_log()`
- Merge results → `merge_agent_result()`

**Пример:**
```bash
source .claude/agents/shared/run-state-lib.sh
append_agent_log "researcher" "search_complete" "Found 5 templates"
merge_agent_result "$AGENT_RESULT"
```

---

## Обратная совместимость

✅ Функции поддерживают legacy paths:
- `memory/run_state_active.json`
- `memory/agent_results/{id}/run_state.json`
- `/Users/sergey/Projects/ClaudeN8N/.n8n/run_state.json`

✅ Безопасный fallback если файл не существует

---

## Функции Reference

### Core Functions

| Функция | Параметры | Описание |
|---------|-----------|----------|
| `get_run_state_path()` | `[project_path] [workflow_id]` | Находит run_state.json (legacy/new) |
| `update_stage()` | `<stage> [path]` | Обновить поле stage |
| `increment_cycle()` | `[path]` | Увеличить cycle_count на 1 |
| `set_cycle()` | `<cycle> [path]` | Установить cycle_count |
| `append_agent_log()` | `<agent> <action> <details> [path]` | Добавить запись в agent_log |
| `update_field()` | `<field_path> <value> [path]` | Обновить любое поле |
| `merge_agent_result()` | `<result_json> [path]` | Слияние результатов агента |

### Safety Functions

| Функция | Параметры | Описание |
|---------|-----------|----------|
| `init_run_state()` | `[project_path] [workflow_id]` | Создать run_state если нет |
| `backup_run_state()` | `[path]` | Создать backup с timestamp |

---

## Тестирование

**Unit tests:**
```bash
bash .claude/tests/test_run_state_lib.sh
```

**Integration tests:**
```bash
bash .claude/tests/test_orch_integration.sh
```

**Ожидаемый результат:**
- Все тесты должны пройти (PASS)
- Никаких конфликтов между библиотеками
- Все функции доступны после source

---

## Миграция (Phase 2 - Planned)

**НЕ ПРИМЕНЯТЬ ДО УТВЕРЖДЕНИЯ ПОЛЬЗОВАТЕЛЕМ!**

Эти изменения будут внесены в Phase 2 после тестирования Phase 1:

1. ✅ Phase 1 COMPLETE: Библиотека создана + тесты
2. ⏸️ Phase 2 PENDING: Замена bash примеров в orch.md
3. ⏸️ Phase 3 PENDING: Тестирование изменений
4. ⏸️ Phase 4 PENDING: Развертывание с rollback

**Текущий статус:** Phase 1 - библиотеки готовы к использованию, но еще НЕ интегрированы в orch.md

---

## Rollback Plan

**Если что-то сломается:**

```bash
# Remove new files
rm .claude/agents/shared/run-state-lib.sh
rm .claude/agents/shared/integration-points.md
rm .claude/tests/test_run_state_lib.sh
rm .claude/tests/test_orch_integration.sh

# No other changes needed (Phase 1 only created new files)
```

**Phase 2 rollback (когда будет применена):**

```bash
# Restore orch.md from backup
mv .claude/commands/orch.md.backup_2025-12-11 .claude/commands/orch.md
```

---

**Статус:** ✅ Phase 1 COMPLETE - Библиотеки готовы, ждем тестирования
