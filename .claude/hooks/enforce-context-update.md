---
trigger: PostToolUse
tools:
  - mcp__n8n-mcp__n8n_update_partial_workflow
  - mcp__n8n-mcp__n8n_create_workflow
---

# Context Update Reminder

## После успешного изменения workflow

Если ты **Builder** и изменение прошло успешно:

1. Сообщи Orchestrator что нужен Analyst
2. Analyst ОБЯЗАН обновить:
   - `.context/2-INDEX.md` (версия, последние изменения)
   - `.context/technical/state.json` (версия)
   - ADR/Intent Card (если затронута критичная нода)

## Протокол

Читай: `.claude/agents/shared/context-update.md`

## Решение

**PROCEED** - но напомни об обновлении контекста
