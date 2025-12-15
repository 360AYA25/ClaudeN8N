# Task: Monitor Claude Code Bug Fix #10668

## 🎯 Цель
Проверить исправлен ли regression bug в Claude Code v2.0.30+ который ломает MCP inheritance в Task agents.

## 🔍 Что проверять

### 1. Проверить версию Claude Code
```bash
claude --version
```

**Если показывает v2.0.30 или выше** → продолжить проверку

### 2. Проверить GitHub Issues

**Issue #10668:** https://github.com/anthropics/claude-code/issues/10668
- Статус: Open или Closed?
- Последний комментарий: когда и что?
- Есть ли упоминание fix?

**Issue #7296:** https://github.com/anthropics/claude-code/issues/7296
- Статус: Open или Closed?
- MCP inheritance работает?

### 3. Тестовая проверка (если Issues закрыты)

```bash
# Тест 1: Проверить что Task agents видят MCP tools
/orch --test agent:builder

# Expected если БАГ ИСПРАВЛЕН:
# - ✅ Builder вызывает MCP tools (mcp__n8n-mcp__*)
# - ✅ Создает файл memory/agent_results/workflow_*.json
# - ✅ Workflow существует в n8n

# Expected если БАГ ЕЩЕ ЕСТЬ:
# - ❌ Error: "tools: Tool names must be unique"
# - ИЛИ Builder симулирует (fake данные)
```

### 4. E2E Test (финальная проверка)

```bash
/orch --test e2e
```

**Проверить:**
- [ ] Workflow создан реально (не fake ID)
- [ ] Файл `memory/agent_results/workflow_*.json` существует
- [ ] Workflow виден в n8n (через n8n_list_workflows)
- [ ] Все 21 ноды созданы
- [ ] Execution прошел успешно

---

## 📋 Checklist когда баг исправлен

Если все тесты прошли ✅:

### Шаг 1: Upgrade Claude Code
```bash
# Upgrade to latest
npm install -g @anthropic-ai/claude-code@latest

# Verify version
claude --version
```

### Шаг 2: Исправить Agent Frontmatter
Убрать `tools:` из всех agent файлов для правильного MCP inheritance:

**Файлы для изменения:**
- [ ] `.claude/agents/builder.md` - убрать весь `tools:` section
- [ ] `.claude/agents/researcher.md` - убрать весь `tools:` section
- [ ] `.claude/agents/qa.md` - убрать весь `tools:` section
- [ ] `.claude/agents/architect.md` - оставить только Read, Write, WebSearch (NO MCP!)

**Правильный frontmatter (после fix):**
```yaml
# builder.md
---
name: builder
model: claude-opus-4-5-20251101
description: Creates and modifies n8n workflows. ONLY agent that mutates workflows.
# NO tools: field! → inherit MCP automatically
skills:
  - n8n-node-configuration
  - n8n-expression-syntax
---
```

### Шаг 3: Restart Claude Code
Закрыть все окна и перезапустить

### Шаг 4: Verification Test
```bash
# Test agents work with MCP
/orch --test agent:builder
/orch --test agent:researcher
/orch --test e2e
```

### Шаг 5: Commit Changes
```bash
git add .claude/agents/
git commit -m "fix: remove tools field from agents for MCP inheritance (bug #10668 fixed)"
```

### Шаг 6: Update CLAUDE.md
Обновить Permission Matrix в `.claude/CLAUDE.md`:
```markdown
## Hard Rules (Permission Matrix)

| Action | Arch | Res | Build | QA | Analyst |
|--------|:----:|:---:|:-----:|:--:|:-------:|
| MCP tools | ✅ (inherit) | ✅ (inherit) | ✅ (inherit) | ✅ (inherit) | ✅ (inherit) |
```

---

## ⚠️ Если баг НЕ исправлен

**Оставаться на Claude Code v2.0.29**

**Периодически проверять:**
- Раз в неделю: GitHub Issues
- Раз в месяц: Test upgrade (в тестовом проекте)

**Workarounds остаются:**
- Вариант -1: Claude Code v2.0.29 (текущее состояние)
- Вариант 2: MCP Proxy (если нужны новые features)

---

## 📝 Как использовать этот файл

1. **Еженедельно:** Открыть Issues #10668 и #7296, проверить статус
2. **Когда Issues закрыты:** Выполнить Тестовую проверку (шаг 3)
3. **Если тесты ✅:** Выполнить все шаги из Checklist
4. **Если тесты ❌:** Продолжать ждать, оставаться на v2.0.29

---

**Last checked:** 2025-12-15
**Current Claude Code version:** 2.0.61
**Bug status:** Issue #10668 CLOSED ✅, Issue #7296 OPEN ❌ (MCP inheritance still broken)
**Workaround:** Bash + curl API (n8n-curl-api.md)
**Auto-updates:** ENABLED
**Next check:** 2025-12-22
