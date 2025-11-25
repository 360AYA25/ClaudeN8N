---
name: n8n-validation
description: Правила валидации и классификация ошибок для QA.
---

## Severity
- **error** — блокирующее: отсутствует credential, сломан connection, неверный path, пустой auth.
- **warning** — некритичное: нет timeout, нет retryOnFail, неявные defaults.

## Checklist
- Узлы связаны? (connections непрерывны, нет висящих)
- Все обязательные параметры заданы явно (Pattern 47).
- webhooks: уникальный path, метод совпадает, responseMode указан.
- БД/HTTP: таймауты, retryOnFail, errorTriggering.
- Credentials: присутствуют и корректно названы.

## QA аннотации
- Заполняй `_meta.status` = ok|warning|error
- `_meta.error` — кратко, `_meta.suggested_fix` — конкретное действие.
- Для регрессий: `_meta.regression_caused_by` = { agent, change }.
