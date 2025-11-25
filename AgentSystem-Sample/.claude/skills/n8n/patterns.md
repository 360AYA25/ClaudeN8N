---
name: n8n-patterns
description: Критические паттерны и анти-паттерны для n8n.
---

## Critical Patterns
- **Pattern 0: Incremental Creation** — сначала 3 базовых узла, затем по одному с тестом после каждого.
- **Pattern 23: Supabase fieldsUi** — используем `fieldsUi.fieldValues` вместо пар columns/values; иначе 401/тихие ошибки.
- **Pattern 47: Never Trust Defaults** — всегда задавать httpMethod, responseMode, path, mode:"manual", timeout, retryOnFail.
- **Pattern 52: Unique Webhook Path** — генерируй `/webhook-{uuid}` чтобы избежать коллизий.
- **Pattern 60: Diff Gate** — если правка удаляет >50% узлов/коннектов, остановись и эскалируй.

## Common Errors
- 401 на Supabase → проверь cred + fieldsUi + таблицу.
- Webhook conflict → новый path + deactivate старого.
- IF / Switch: строго типизируй сравнения (`{{$json.key ?? ""}}`).

## Testing Tips
- Всегда валидируй после каждой правки builder’ом, перед передачей в QA.
- QA запускает webhook только на активированном workflow.
