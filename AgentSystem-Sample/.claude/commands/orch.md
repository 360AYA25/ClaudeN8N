# /orch — запуск 6-агентного флоу

## Что делает
- Создаёт/обновляет `memory/run_state.json`.
- Делегирует по маршруту (simple vs complex) и координирует QA циклы.

## Параметры
- `mode`: simple|complex (по умолчанию auto)
- `goal`: краткое описание задачи пользователя
- `services`: список сервисов/интеграций

## Пример вызова (для продакшена)
```
/orch mode=auto goal="Webhook → Supabase" services="webhook,supabase"
```

## Контекст, передаваемый агентам
- Полный `run_state` (JSON)
- `cycle_count`, `edit_scope`, `blueprint`/`research_findings`
- История `worklog` и `agent_log`

## Эскалация
- ≤3 QA циклов → далее Architect (L3)
- L4 → запрос решения у пользователя

