# MIGRATION: 5-агентная (GPT/Gemini) → 6-агентная Pure Claude

## Цель
Перейти на архитектуру из `docs/PLAN-UNIFIED-AGENT-SYSTEM.md` без смешения старых ролей и инструментов.

## Кратко
- 6 агентов: orchestrator (Sonnet), architect (Opus), researcher (Sonnet), builder (Opus, единственный writer), qa (Haiku), analyst (Opus, read-only + learnings).
- Унифицированные MCP инструменты, жёсткая матрица разрешений.
- Новый `run_state` с `_meta`, `actions`, append-only историями.

## Шаги
1) **Подготовка**
   - Скопируйте `AgentSystem-Sample/` в новый репозиторий или отдельную ветку.
   - Подставьте креды в `.mcp.json`.

2) **Агентные промпты**
   - Замените старые `workflow-builder/validator/tester` на новые: `builder.md`, `qa.md`, `analyst.md`.
   - Удалите/архивируйте файлы с GPT/Gemini и Bash runner-ами.

3) **CLAUDE.md**
   - Обновите автозагрузку: маршрутизация, 4 уровня эскалации, max 3 QA цикла, merge-правила run_state.

4) **Команда /orch**
   - Обновите `.claude/commands/orch.md` под новый пайплайн и run_state передачу.

5) **State**
   - Замените старый `memory/run_state.json` на новый шаблон (из этого примера).
   - Добавьте `memory/history.jsonl` и `memory/learnings.md` (analyst пишет только сюда).

6) **Skills**
   - Заполните `.claude/skills/n8n/*` (patterns, node-configs, validation) из вашей базы знаний.

7) **Тестирование**
   - Простой поток: researcher → builder → qa (без architect).
   - Сложный поток: architect → researcher → builder → qa.
   - Цикл с ошибкой: намеренно сломать node, пройти 3 QA цикла, убедиться в эскалации L3.

8) **Чистка**
   - Удалите устаревшие инструкции про tmp context-файлы; используйте только run_state.
   - Проверьте, что QA не имеет мутирующих MCP инструментов, а builder — единственный writer.

## Готовность к продакшену (чеклист)
- [ ] Все 6 промптов присутствуют и совпадают с планом.
- [ ] `.mcp.json` настроен и проверен на подключение к n8n-mcp.
- [ ] run_state сохраняется и передаётся между агентами; orchestrator применяет merge-правила.
- [ ] QA не вызывает autofix/update/create; builder всегда валидирует перед возвратом.
- [ ] Analyst умеет читать history.jsonl и писать learnings.md.
- [ ] Пройдено минимум 2 сквозных теста + 1 тест с эскалацией.
