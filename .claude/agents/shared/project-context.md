# Протокол загрузки контекста проекта

> **Применяется:** ВСЕ агенты
> **Когда:** В начале КАЖДОЙ задачи

## STEP 0: Определить проект

```bash
# Прочитать из run_state
project_path=$(jq -r '.project_path // empty' memory/run_state_active.json)

# Если нет в run_state → default
if [ -z "$project_path" ]; then
  project_path="/Users/sergey/Projects/ClaudeN8N"
fi
```

## STEP 1: Загрузить контекст

**Порядок чтения (от общего к частному):**

```
1. STRATEGY (обязательно для всех):
   Read: {project_path}/.context/1-STRATEGY.md

2. INDEX (обязательно для всех):
   Read: {project_path}/.context/2-INDEX.md

3. Для Builder/QA - если меняешь ноду:
   → Найди ноду в INDEX
   → Прочитай указанный ADR или Intent Card

4. Для Researcher - если ищешь по сервису:
   Read: {project_path}/.context/architecture/services/{service}.md
```

## Приоритеты по агентам

| Агент | Читает обязательно | Читает по необходимости |
|-------|-------------------|------------------------|
| Architect | STRATEGY, INDEX | flow.md |
| Researcher | STRATEGY, INDEX | services/*.md, decisions/*.md |
| Builder | STRATEGY, INDEX | ADR/Intent Card для изменяемой ноды |
| QA | STRATEGY, INDEX | flow.md |
| Analyst | ВСЁ | - |

## Fallback (если .context/ не существует)

```bash
if [ ! -d "${project_path}/.context" ]; then
  echo "⚠️ Project context not found"
  echo "Fallback: Read ARCHITECTURE.md if exists"
  [ -f "${project_path}/ARCHITECTURE.md" ] && Read "${project_path}/ARCHITECTURE.md"
fi
```
