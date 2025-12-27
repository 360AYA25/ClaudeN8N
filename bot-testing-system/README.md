# Bot Test Automation

**Автоматическое тестирование Telegram ботов от имени реального пользователя**

---

## Быстрый старт

### Что это делает

1. Получает команду через Webhook (например: "200 гр курицы")
2. Генерирует **1 тестовый сценарий** через OpenAI
3. Отправляет сообщение боту **от твоего имени** (@seno1885)
4. Получает ответ бота
5. Проверяет что ответ соответствует ожидаемому паттерну

### Как запустить

```bash
# 1. Установить зависимости
pip3 install -r requirements.txt

# 2. Настроить .env файл (уже создан, содержит API ключи)
# .env файл должен содержать:
# TELEGRAM_API_ID=34713527
# TELEGRAM_API_HASH=87be59b2e6888504a5a40f3f04f8af9c
# SESSION_NAME=telegram_session
# PORT=5001

# 3. Авторизоваться в Telegram (один раз)
python3 auth_telethon.py
# → Ввести номер телефона + код из Telegram

# 4. Запустить сервер
python3 telegram_sender.py
# → Сервер запустится на http://0.0.0.0:5001
```

### Тестирование

```bash
# Проверить что сервер работает
curl http://localhost:5001/health

# Тестовая отправка
curl -X POST http://localhost:5001/send_telegram \
  -H "Content-Type: application/json" \
  -d '{"chat_id": "@Multi_Bot0101_bot", "message": "тест"}'
```

---

## Структура проекта

```
bot-testing-system/
├── telegram_sender.py       # Quart сервер (v4.0)
├── auth_telethon.py         # Авторизация в Telegram
├── requirements.txt         # Python зависимости
├── .env                     # API ключи (НЕ коммитить в git!)
├── .gitignore               # Игнорируемые файлы (.env, *.session)
├── README.md                # Этот файл
└── ARCHITECTURE.md          # Полная техническая документация
```

**Важно:**
- `.env` содержит API ключи - **НЕ коммитить в git!**
- `telegram_session.session` создаётся после авторизации и содержит твои учетные данные - **НЕ коммитить в git!**
- `.gitignore` настроен чтобы исключить эти файлы из git

---

## Конфигурация

### .env файл

API ключи хранятся в `.env` файле (автоматически загружается через `python-dotenv`):

```bash
# Telegram API Credentials
TELEGRAM_API_ID=34713527
TELEGRAM_API_HASH=87be59b2e6888504a5a40f3f04f8af9c

# Session filename
SESSION_NAME=telegram_session

# Server port
PORT=5001
```

**⚠️ ВАЖНО:** `.env` файл добавлен в `.gitignore` и не попадёт в git репозиторий!

### На VPS (деплой)

```bash
# Копирование файлов на VPS (НЕ копировать .env - создать отдельно!)
scp telegram_sender.py auth_telethon.py requirements.txt root@72.60.28.252:/root/telegram-sender/

# Создать .env на VPS (вручную, с реальными ключами)
ssh root@72.60.28.252 "cat > /root/telegram-sender/.env << 'EOF'
TELEGRAM_API_ID=34713527
TELEGRAM_API_HASH=87be59b2e6888504a5a40f3f04f8af9c
SESSION_NAME=telegram_session
PORT=5001
EOF"

# Установка зависимостей
ssh root@72.60.28.252 "cd /root/telegram-sender && pip3 install -r requirements.txt"

# Запуск в фоне
ssh root@72.60.28.252 "cd /root/telegram-sender && nohup python3 telegram_sender.py > /dev/null 2>&1 &"
```

---

## API Endpoints

| Endpoint | Метод | Описание |
|----------|--------|----------|
| `/health` | GET | Статус сервера |
| `/send_telegram` | POST | Отправить сообщение |
| `/get_last_message` | POST | Последнее сообщение из чата |
| `/wait_for_response` | POST | Ждать ответ от бота |
| `/info` | GET | Информация об API |

---

## n8n Workflow

**Workflow ID:** `vZ5LnF6GXIIiJ8ku`
**URL:** https://n8n.srv1068954.hstgr.cloud

### Настройка HTTP Request ноды

```javascript
// "Send via Telethon" node
{
  "method": "POST",
  "url": "http://72.60.28.252:5001/send_telegram",
  "sendBody": true,
  "contentType": "json",
  "specifyBody": "json",
  "jsonBody": "={{ {\"chat_id\": \"@Multi_Bot0101_bot\", \"message\": $json.message} }}"
}

// "Get Bot Response" node
{
  "method": "POST",
  "url": "http://72.60.28.252:5001/get_last_message",
  "sendBody": true,
  "contentType": "json",
  "specifyBody": "json",
  "jsonBody": "={{ {\"chat_id\": \"@Multi_Bot0101_bot\"} }}"
}
```

---

## Troubleshooting

### Ошибка: "Not authenticated"
**Причина:** Нет сессии или она устарела
**Решение:** Запусти `python3 auth_telethon.py` и введи код снова

### Ошибка: "Address already in use"
**Причина:** Порт 5001 занят
**Решение:**
```bash
# Mac
lsof -ti:5001 | xargs kill -9

# Linux
fuser -k 5001/tcp
```

### Ошибка: "event loop must not change"
**Причина:** Используется Flask вместо Quart
**Решение:** Используй `telegram_sender.py` v4.0 (Quart)

---

## Технологии

- **Python 3.12+**
- **Quart 0.19.4** - async web framework (ASGI)
- **Hypercorn 0.16.0** - ASGI сервер
- **Telethon 1.35.0** - Telegram MTProto клиент

---

## Безопасность

✅ API_ID/HASH в `.env` файле (защищён .gitignore)
✅ Session файлы в `.gitignore` (не попадут в git)
✅ Порт 5001 закрыт firewall (только для n8n)
⚠️ Рекомендуется добавить API key аутентификацию

---

## Полная документация

Смотри [ARCHITECTURE.md](ARCHITECTURE.md) для:
- Детальной архитектуры системы
- Описания потока данных
- Технических решений (Flask → Quart миграция)
- Мониторинга и логирования
