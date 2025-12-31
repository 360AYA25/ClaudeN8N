# План улучшений агентской системы

**Дата:** 2025-12-30
**Основание:** SYSTEM_FAILURE_ANALYSIS.md (5+ часов на 1 строку)

---

## Улучшение 1: Builder - Полная проверка Code Node

**Файл:** `.claude/agents/builder.md`

**Проблема:** Builder проверил только строку 2, пропустил строку 5

**Добавить после линии 826:**

```markdown
## 🚨 FULL CODE NODE INSPECTION (MANDATORY!)

When editing Code nodes, MUST inspect ENTIRE code, not just edit_scope:

### Protocol:
1. Read ALL lines of jsCode parameter
2. Search for deprecated patterns on EVERY line:
   - $('Node Name') - deprecated node reference (L-060)
   - $node["Node Name"] - deprecated syntax (L-060)
   - .first() on node references (L-104)
3. Fix ALL occurrences, not just the one mentioned in edit_scope
4. Verify fix applied to ALL matching lines

### Example:
// ❌ WRONG: Fix only line 2
edit_scope: ["line 2"]

// ✅ CORRECT: Fix all lines with deprecated syntax
// Scan entire code, find lines 2 AND 5 have issues
// Fix both lines
edit_scope: ["line 2", "line 5"]
```

---

## Улучшение 2: Orchestrator - GATE enforcement для builder_gotchas

**Файл:** `.claude/agents/shared/gate-enforcement.sh`

**Проблема:** Builder не прочитал builder_gotchas.md перед Code node работой

**Добавить функцию:**

```bash
# GATE 6: builder_gotchas.md mandatory read
check_builder_gotchas_read() {
  local run_state="$1"

  # Check if workflow has Code nodes
  local has_code_nodes=$(jq -r '.qa_report.edit_scope[]? | select(.issue | contains("Code node")) | .node_id' "$run_state")

  if [ -n "$has_code_nodes" ]; then
    # Verify Builder read builder_gotchas.md
    local gotchas_read=$(jq -r '[.agent_log[] | select(.agent=="builder" and (.details | contains("builder_gotchas")))] | length' "$run_state")

    if [ "$gotchas_read" = "0" ]; then
      echo "🚨 GATE 6 VIOLATION: Builder must read builder_gotchas.md before Code node edits!"
      return 1
    fi
  fi

  return 0
}
```

---

## Улучшение 3: QA - GATE 3 Enforcement (Execution Test First)

**Файл:** `.claude/agents/qa.md`

**Проблема:** QA проверил структуру вместо запуска execution test

**Добавить в Phase 5 Validation:**

```markdown
## 🚨 EXECUTION TEST IS FIRST PRIORITY (GATE 3)

When workflow has Code nodes:

1. MANDATORY: Run n8n_test_workflow FIRST
2. Only AFTER execution test, run validate_workflow
3. If execution fails → execution analysis > structure validation
4. Skip execution test = FAIL immediately

Rationale: Structure validation means nothing if code crashes at runtime.
```

---

## Улучшение 4: LEARNINGS.md - Новые learnings

**Файл:** `docs/learning/LEARNINGS.md`

**Добавить:**

```markdown
## L-105: Full Code Node Inspection Required

**Date:** 2025-12-30
**Workflow:** GLDomYl4VVqmMo1m
**Issue:** Builder checked only line 2, missed line 5

**Rule:**
- Code nodes can have MULTIPLE deprecated references
- Must inspect EVERY line, not just edit_scope
- Scan for: $('Node'), $node["Node"], .first() patterns

**Token cost:** 1,000 tokens (read builder_gotchas.md)
**Time saved:** 4.5 hours

---

## L-106: builder_gotchas.md Must Be Read Before Code Edits

**Date:** 2025-12-30
**Workflow:** GLDomYl4VVqmMo1m
**Issue:** Builder didn't know about L-060 warning

**Rule:**
- Before ANY Code node work → read docs/learning/indexes/builder_gotchas.md
- Contains L-060 warning (lines 28-33)
- GATE 6 enforces this check

**Token cost:** 1,000 tokens
**Time saved:** 3 hours

---

## L-107: Phase 5 Execution Test Must Be First Priority

**Date:** 2025-12-30
**Workflow:** GLDomYl4VVqmMo1m
**Issue:** QA validated structure before testing execution

**Rule:**
- For workflows with Code nodes → execution test FIRST
- Structure validation means nothing if code crashes
- GATE 3 enforcement required

**Token cost:** 5,000 tokens (execution test)
**Time saved:** 1 hour
```

---

## Улучшение 5: Update builder_gotchas.md index

**Файл:** `docs/learning/indexes/builder_gotchas.md`

**Усилить L-060 секцию:**

```markdown
## 🚨 L-060: Code Node Deprecated Syntax (CRITICAL!)

**Impact:** HIGH - Most common Code node error
**Detection:** Scan EVERY line of jsCode
**Fix:** Replace $('Node') with $input

### Pattern:
❌ $('Get Current Workflow').first().json.data
✅ $input.first().json.data

### MANDATORY BEFORE CODE NODE WORK:
1. Read entire jsCode parameter (all lines!)
2. Search for deprecated syntax on EACH line
3. Fix ALL occurrences
4. Verify with execution test

**Real example:** Line 2 was correct, line 5 had bug. Both needed inspection!
```

---

## Порядок применения:

1. ✅ **Улучшение 3** (QA.md) - GATE 3 enforcement - приоритет #1
2. ✅ **Улучшение 1** (builder.md) - Full code inspection protocol
3. ✅ **Улучшение 2** (gate-enforcement.sh) - GATE 6 check
4. ✅ **Улучшение 4** (LEARNINGS.md) - L-105, L-106, L-107
5. ✅ **Улучшение 5** (builder_gotchas.md) - Усилить предупреждение

---

## Тестирование после применения:

1. Создать тестовый workflow с Code node (2+ deprecated lines)
2. Запустить `/orch --fix`
3. Проверить: Builder нашёл ВСЕ строки?
4. Проверить: QA запустил execution test первым?
5. Проверить: GATE 6 заблокировал без gotchas?

---

## Метрики успеха:

**До:**
- Time: 5+ hours
- Tokens: 120,000
- QA cycles: 5

**После применения:**
- Time: <30 minutes
- Tokens: <5,000
- QA cycles: 1

**Цель:** 90% улучшение
