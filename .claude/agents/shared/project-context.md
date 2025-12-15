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
| Architect | STRATEGY, INDEX | flow.md, ALL-SERVICES.md |
| Researcher | STRATEGY, INDEX | ALL-SERVICES.md, DATA-FLOW.md, services/*.md, decisions/*.md |
| Builder | STRATEGY, INDEX | AI-AGENT-TOOLS.md (if modifying AI Agent), ADR/Intent Card для изменяемой ноды |
| QA | STRATEGY, INDEX | DATA-FLOW.md, flow.md |
| Analyst | ВСЁ | Все новые файлы для обновления после build |

## Новые файлы контекста (📁 v3.7.0+)

**Comprehensive Documentation:**
- **ALL-SERVICES.md** - полное описание всех сервисов (Telegram, Supabase, OpenAI, etc.)
  - Зачем нужен каждый сервис
  - Какие ноды используют
  - Критичность и failure impact

- **DATA-FLOW.md** - детальные потоки данных для всех типов сообщений
  - Text/Voice/Photo/Command flows
  - Step-by-step transformations
  - Pattern references (L-060, L-068, etc.)

- **AI-AGENT-TOOLS.md** - документация всех AI Agent инструментов
  - 15 tools с параметрами и примерами
  - Паттерны использования
  - v432 incident уроки (jsonBody vs parametersBody)

**Где находятся:**
```
{project_path}/.context/architecture/
├── services/ALL-SERVICES.md
├── flows/DATA-FLOW.md
└── nodes/AI-AGENT-TOOLS.md
```

## Fallback (если .context/ не существует)

```bash
if [ ! -d "${project_path}/.context" ]; then
  echo "⚠️ Project context not found"
  echo "Fallback: Read ARCHITECTURE.md if exists"
  [ -f "${project_path}/ARCHITECTURE.md" ] && Read "${project_path}/ARCHITECTURE.md"
fi
```
