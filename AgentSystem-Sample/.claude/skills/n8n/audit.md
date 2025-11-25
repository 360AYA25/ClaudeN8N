---
name: n8n-audit
description: Шпаргалка по аудиту инцидентов в n8n.
---

- Собирай timeline по `worklog`, `agent_log`, `workflow.actions`, `history.jsonl`, executions.
- Классифицируй failure_source: implementation (реализация), analysis (план/ресёрч), unknown.
- Проверяй регрессии: сравни _meta.previous_status и текущий status.
- Фиксируй паттерны ошибок для learnings (duplicate webhook path, missing fieldsUi, пустые credentials).
