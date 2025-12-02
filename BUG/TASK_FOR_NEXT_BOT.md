# TASK FOR NEXT BOT: System Consistency Fixes (v3.4.0)

**Date:** 2025-12-02
**Priority:** HIGH
**Estimated Time:** 2.5 hours
**Context:** После исправления mode="full" (v3.3.2), сделан полный аудит системы

---

## TL;DR

Выполни 30 исправлений inconsistencies в системе 5-Agent n8n orchestration.
**Детальный план:** `~/.claude/plans/warm-floating-peach.md`

---

## Как запустить

```bash
# 1. Прочитай план
Read ~/.claude/plans/warm-floating-peach.md

# 2. Выполняй по фазам (Phase 1 → 2 → 3 → 4)

# 3. После каждой фазы - commit
git add -A && git commit -m "fix: phase N - description"

# 4. В конце - финальный commit
git commit --amend с полным описанием v3.4.0
```

---

## Фазы выполнения

### Phase 1: Critical (35 min) ⚡

**1.1 QA Threshold → 7 cycles (CONFIRMED!)**

Файлы:
- `.claude/CLAUDE.md` line 88: "3 QA fails" → "7 QA cycles"
- `.claude/commands/orch.md` line 148: добавить progressive escalation note

```markdown
# Progressive escalation:
# Cycles 1-3: Builder fixes directly
# Cycles 4-5: Researcher helps find alternative
# Cycles 6-7: Analyst diagnoses root cause
# After 7: stage="blocked"
```

**1.2 IMPACT_ANALYSIS = clarification sub-phase**

Файлы:
- `.claude/commands/orch.md` lines 86, 456
- `.claude/agents/architect.md` line 155

Суть: IMPACT_ANALYSIS это НЕ отдельный stage, а sub-phase внутри clarification.

**1.3 L-067 Consolidation (MAIN TASK)**

1. Создать `.claude/agents/shared/L-067-smart-mode-selection.md` (NEW)
2. Заменить дублирование в 5 файлах на reference:
   - builder.md (5 locations)
   - qa.md (4 locations)
   - researcher.md (2 locations)
   - analyst.md (2 locations)
   - orch.md (1 location)

---

### Phase 2: High Priority (45 min) 🔧

**2.1 Tool Declarations**
- Добавить "Tool Access Model" section во все агенты

**2.2 Undefined Variables**
- orch.md line 529: добавить context
- builder.md line 614: добавить pseudocode note
- researcher.md line 390: добавить helper explanation

**2.3 Dead File References**
- builder.md line 61: удалить ref на MCP-BUG-RESTORE.md
- qa.md line 62: удалить ref на MCP-BUG-RESTORE.md

---

### Phase 3: Cleanup (30 min) 📝

**3.1 Stage Flow Documentation**
- CLAUDE.md line 133: link to orch.md instead of duplication

**3.2 Escalation Consolidation**
- CLAUDE.md line 91-98: summary only, link to orch.md

**3.3 Deprecated Syntax Audit**
- grep `$node["` - should only be in "deprecated" sections

---

### Phase 4: Testing (45 min) 🧪

**4.1 CHANGELOG.md v3.4.0**
- Добавить entry с всеми изменениями

**4.2 LEARNINGS-INDEX.md**
- Update L-067 entry with shared file reference

**4.3 Consistency Test Script**
- Создать `.claude/tests/consistency-check.sh`

**4.4 Test FoodTracker**
```bash
/orch workflow_id=sw3Qs3Fe3JahEbbW --debug
```

---

## Key Files

**Читать первыми:**
1. `~/.claude/plans/warm-floating-peach.md` - FULL PLAN
2. `.claude/CLAUDE.md` - project config
3. `.claude/commands/orch.md` - orchestrator protocol

**Создать:**
1. `.claude/agents/shared/L-067-smart-mode-selection.md`
2. `.claude/tests/consistency-check.sh`

**Модифицировать:**
1. `.claude/CLAUDE.md`
2. `.claude/commands/orch.md`
3. `.claude/agents/builder.md`
4. `.claude/agents/qa.md`
5. `.claude/agents/researcher.md`
6. `.claude/agents/architect.md`
7. `.claude/agents/analyst.md`
8. `CHANGELOG.md`
9. `docs/learning/LEARNINGS-INDEX.md`

---

## User Decisions (CONFIRMED)

- ✅ QA Threshold: **7 cycles** (progressive escalation)
- ✅ Execution: **All at once** (поэтапно)
- ✅ Priority: **Standard** (Phase 1 → 2 → 3 → 4)

---

## Verification

После всех изменений:

```bash
# 1. Run consistency check
chmod +x .claude/tests/consistency-check.sh
.claude/tests/consistency-check.sh

# 2. Test FoodTracker debug
/orch workflow_id=sw3Qs3Fe3JahEbbW --debug

# 3. Verify no crashes
# Expected: No "Prompt is too long", smooth QA escalation
```

---

## Commit Strategy

```bash
# After Phase 1
git add -A && git commit -m "fix: phase 1 - critical system consistency fixes"

# After Phase 2
git add -A && git commit -m "fix: phase 2 - high priority fixes"

# After Phase 3
git add -A && git commit -m "fix: phase 3 - documentation cleanup"

# After Phase 4 - FINAL
git add -A && git commit -m "$(cat <<'EOF'
fix: complete system consistency audit (v3.4.0)

30 inconsistencies fixed across 5-Agent n8n orchestration system.

Critical:
- QA threshold: standardized to 7 cycles (progressive escalation)
- IMPACT_ANALYSIS: clarified as clarification sub-phase
- L-067: consolidated to single source of truth

High Priority:
- Tool declarations standardized
- Undefined variables fixed in examples
- Dead file references removed

Documentation:
- Stage flow consolidated (orch.md = source)
- Escalation levels merged
- Consistency test suite created

Files: 10 modified, 2 new
Impact: Documentation only, no behavior changes

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Context from Previous Bot

**What was done:**
1. ✅ v3.3.2 fix committed (mode="full" → L-067 smart mode)
2. ✅ Full system audit completed (3 Explore agents)
3. ✅ Plan created in `~/.claude/plans/warm-floating-peach.md`
4. ✅ User confirmed: 7 cycles, all at once

**What's next:**
→ Execute Phase 1-4 from plan
→ Commit after each phase
→ Test with FoodTracker

---

**START HERE:**
```
Read ~/.claude/plans/warm-floating-peach.md
```

Then execute Phase 1 first!
