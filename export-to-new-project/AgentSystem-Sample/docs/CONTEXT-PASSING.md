# Context Passing (run_state-first)

## Проблема
Агенты работают изолированно. Единственный источник правды — `memory/run_state.json`. Никаких временных md-файлов.

## Поток
```
User → Orchestrator (init run_state)
  → Researcher/Architect (добавляют findings/blueprint)
  → Builder (мутирует workflow, валидирует)
  → QA (валидирует/тестирует, issues + edit_scope)
  → Orchestrator (цикл ≤3)
  → Analyst (по запросу пользователя или после блокировки)
```

## Что передаёт orchestrator агентам
- Полный JSON run_state (включая workflow.nodes с _meta).
- stage, cycle_count, edit_scope.
- worklog, agent_log.

## Правила merge (orchestrator)
- Objects: shallow merge (agent overwrites): blueprint, workflow, qa_report.
- Arrays append-only: errors, fixes_tried, memory.*.
- Arrays replace: edit_scope, workflow.nodes, qa_report.issues.
- Stage только вперёд (planning→research→build→validate→test→complete|blocked).
- qa_report.issues всегда дублировать в memory.issues_history.

## _meta на узлах (пример)
```
{
  "id": "supabase_1",
  "type": "n8n-nodes-base.supabase",
  "parameters": { ... },
  "_meta": {
    "status": "error",
    "error": "fieldsUi missing",
    "suggested_fix": "Add fieldsUi.fieldValues",
    "evidence": "validate_workflow line 45",
    "fix_attempts": [ {"attempt":1,"change":"added columns","result":"failed","by":"builder"} ],
    "snapshot_before_fix": { ... },
    "regression_caused_by": null
  }
}
```

## Форматы логов
- **worklog**: [{ ts, cycle, agent, action, outcome, nodes_changed?, qa_status?, error_summary? }]
- **agent_log**: [{ ts, agent, action, target?, details, mcp_calls? }]
- **history.jsonl**: построчно сериализованный run_state (или ключевые события) для analyst.

## Когда вызывать Analyst
- После 3 неуспешных QA циклов.
- Когда failure_source=unknown.
- По запросу пользователя («почему сломалось?»).

