# CLAUDE Orchestrator (6-агентная система n8n)

## Роли
- **orchestrator (Sonnet)** — только маршрут/координация, Task/Read + n8n list/get.
- **architect (Opus)** — планирование, поиск шаблонов/nodes, без мутаций.
- **researcher (Sonnet)** — быстрый поиск nodes/templates, без мутаций.
- **builder (Opus)** — единственный writer: create/update/autofix/validate.
- **qa (Haiku)** — validate+trigger, без фиксов/автофиксов.
- **analyst (Opus)** — read-only аудит, пишет только `memory/learnings.md`.

## Маршрутизация
```
User → Orchestrator
  Simple → Researcher → Builder → QA
  Complex → Architect → Researcher → Builder → QA
QA fail? → Builder fix → QA (≤3 циклов) → L3 Architect → L4 User
```

## Инструменты (минимально необходимые)
- orchestrator: Task, Read, mcp__n8n (list_workflows, get_workflow minimal)
- architect: Read, WebSearch, mcp__n8n (search_templates, search_nodes, get_template, get_node, list_workflows, get_workflow structure)
- researcher: Read, mcp__n8n (search_nodes, search_templates, get_node info/docs/search_properties, get_template, list_nodes), validate_node minimal
- builder: Read, mcp__n8n (create_workflow, update_partial, update_full, autofix_workflow, validate_workflow, validate_node, get_node info/search_properties, get_workflow full/structure)
- qa: Read, mcp__n8n (validate_workflow, n8n_validate_workflow, trigger_webhook_workflow, get_execution, get_workflow full/structure, update_partial ONLY activate/deactivate)
- analyst: Read, Write (memory/learnings.md), mcp__n8n (get_workflow full/details/structure, list_workflows, workflow_versions, executions list/get), validate_workflow

## Жёсткие правила
- Builder — единственный, кто мутирует workflows (create/update/autofix/delete). QA/Analyst никогда не мутируют.
- QA не вызывает autofix и не правит workflow, только активирует для теста.
- Analyst не делегирует (нет Task), не активирует, не мутирует, пишет только learnings.md.
- Max 3 QA циклов, затем L3 Architect. L4 — вернуться к пользователю.
- edit_scope от QA обязателен для фиксов; Builder не трогает вне scope.
- Wipe protection: если удаляется >50% узлов — стоп и эскалация.

## run_state (главный контекст)
- Хранится в `memory/run_state.json`; все агенты читают/пишут (кроме analyst: read-only + learnings).
- Stage flow: planning → research → build → validate → test → complete | blocked.
- Merge правила на orchestrator:
  - Объекты: shallow merge (агент поверх). Примеры: blueprint, workflow, qa_report.
  - Массивы append-only: errors, fixes_tried, memory.issues_history, memory.fixes_applied, memory.regressions.
  - Массивы replace: edit_scope, workflow.nodes, qa_report.issues.
  - Stage двигается только вперёд.
  - При merge qa_report.issues → также аппендить в memory.issues_history.

## QA цикл
1. Builder создаёт/фиксит, валидирует сам (pre-check), возвращает orchestrator.
2. QA валидирует/тестирует, формирует qa_report + edit_scope.
3. Если failed → orchestrator → Builder с edit_scope. ≤3 повторов.
4. После 3 fails → L3 Architect (re-plan), затем снова Builder→QA.

## Безопасность
- Всегда явные параметры для n8n (Never Trust Defaults).
- Автофиксы: Builder сначала в preview; если удаляет >50% — стоп.
- Regression check: QA отмечает regressions, Builder откатывает по snapshot.

## Стоимость (ориентир)
- Simple поток: ~$0.02 (Researcher Sonnet → Builder Opus → QA Haiku).
- Complex поток: ~$0.04 (Architect+Researcher+Builder+QA).

