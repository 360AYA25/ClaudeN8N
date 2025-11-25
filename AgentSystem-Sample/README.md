# AgentSystem-Sample

Эталонная структура 6-агентной системы (Pure Claude) для n8n. Можно копировать целиком в новый репозиторий или сравнивать с текущим проектом.

## Что внутри
- 6 агентных промптов с жёсткими правами и списками MCP-инструментов.
- Обновлённый `run_state.json` и схемы (`schemas/*.json`).
- Команда `/orch`, skills-файлы для n8n.
- Полный план v2.4.0: `docs/PLAN-UNIFIED-AGENT-SYSTEM.md`.

## Быстрый старт
1. Скопируйте папку `AgentSystem-Sample/` в новый проект (`cp -R AgentSystem-Sample ../AgentSystem`).
2. Заполните переменные в `.mcp.json` (`N8N_API_URL`, `N8N_API_KEY`).
3. Прочтите `MIGRATION.md` — чек-лист перехода со старой 5-агентной схемы.
4. Настройте `.claude/agents/*.md` и `CLAUDE.md` под вашу инфраструктуру (при необходимости поменяйте модели, пути).
5. Запустите сквозной тест: researcher → builder → qa.

## Разделы
- `.claude/agents` — промпты агентов (orchestrator/architect/researcher/builder/qa/analyst).
- `.claude/skills/n8n` — компактные знания (patterns, node-configs, validation).
- `.claude/commands/orch.md` — шаблон slash-команды для оркестратора.
- `memory/` — состояние (run_state, history, learnings) — основной канал контекста.
- `docs/` — план и гайд по контекст-пассингу.
- `schemas/` — JSON Schema для run_state и вывода агентов.

## Принципы
- **Builder — единственный писатель**; QA не фиксит; Analyst только читает (пишет в learnings.md).
- **Макс 3 QA цикла** — затем L3 Architect; L4 — пользователь.
- **Append-only поля** для истории/исправлений; строгие merge-правила на orchestrator.
- **Упор на n8n**: все параметры явные (Never Trust Defaults), templates-first подход.
