# Bot Test Automation - Архитектура системы

## Обзор

Система автоматического тестирования Telegram ботов. Генерирует тесты через AI, отправляет сообщения от имени реального пользователя, проверяет ответы бота.

```
┌─────────────────────────────────────────────────────────────────┐
│                         n8n Workflow                            │
│                  (n8n.srv1068954.hstgr.cloud)                   │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ Webhook  │───▶│  OpenAI  │───▶│  HTTP    │───▶│  Assert  │  │
│  │ Trigger  │    │ Generate │    │ Request  │    │ Response │  │
│  └──────────┘    │  Tests   │    └────┬─────┘    └──────────┘  │
│                  └──────────┘         │                        │
└───────────────────────────────────────┼────────────────────────┘
                                        │
                                        │ HTTP POST
                                        │ http://72.60.28.252:5001
                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Telegram Sender (VPS)                        │
│                      72.60.28.252:5001                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Quart Server v4.0                      │  │
│  │                   (async-native ASGI)                     │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │  │
│  │  │   /health   │  │/send_telegram│ │/get_last_message│   │  │
│  │  └─────────────┘  └──────┬──────┘  └─────────────────┘   │  │
│  │                          │                                │  │
│  │                          ▼                                │  │
│  │              ┌───────────────────────┐                    │  │
│  │              │   Telethon Client     │                    │  │
│  │              │   (@seno1885 session) │                    │  │
│  │              └───────────┬───────────┘                    │  │
│  └──────────────────────────┼────────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              │ Telegram MTProto API
                              │ (как реальный пользователь)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Telegram Servers                           │
│                                                                 │
│   @seno1885 ────────────────▶ @target_bot                      │
│   (твой аккаунт)              (тестируемый бот)                │
│                                                                 │
│   Сообщение отправляется     Бот получает и                    │
│   от твоего имени            отвечает                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Компоненты

### 1. n8n Workflow (Remote)

**Расположение:** `https://n8n.srv1068954.hstgr.cloud`
**Workflow ID:** `vZ5LnF6GXIIiJ8ku`

**Функции:**
- Генерация тестовых сценариев через OpenAI
- Оркестрация тестов
- Отправка запросов к Telegram Sender
- Валидация ответов бота
- Логирование результатов

**Ноды:**
```
Webhook Trigger → OpenAI (generate tests) → Loop → HTTP Request → Wait → Get Response → Assert
```

### 2. Telegram Sender (VPS)

**Расположение:** `72.60.28.252:5001`
**Технологии:** Python 3.12, Quart 0.19.4, Telethon 1.35.0, Hypercorn 0.16.0

**Файлы:**
```
/root/telegram-sender/
├── telegram_sender.py      # Основной сервер (Quart v4.0)
├── telegram_session.session # Сессия Telethon (авторизация)
├── telegram_sender.log     # Логи
└── requirements.txt        # Зависимости
```

**Локально (Mac):**
```
/Users/sergey/Projects/ClaudeN8N/bot-testing-system/
├── telegram_sender.py       # Копия для разработки
├── auth_telethon.py         # Скрипт авторизации
├── telegram_session.session # Локальная сессия (для тестов)
├── requirements.txt         # Зависимости
├── README.md                # Краткая документация
└── ARCHITECTURE.md          # Этот файл
```

**API Endpoints:**

| Endpoint | Method | Описание |
|----------|--------|----------|
| `/health` | GET | Проверка статуса |
| `/send_telegram` | POST | Отправить сообщение |
| `/get_last_message` | POST | Получить последнее сообщение |
| `/wait_for_response` | POST | Ждать ответ бота |
| `/info` | GET | Информация об API |

### 3. Telethon Client

**Что это:** MTProto клиент для Telegram
**Авторизован как:** @seno1885 (твой личный аккаунт)
**Session файл:** `telegram_session.session`

**Почему Telethon, а не Bot API:**
- Bot API работает только для ботов
- Telethon позволяет отправлять от имени пользователя
- Можно тестировать ботов как реальный юзер

---

## Поток данных

### Сценарий: Тестирование бота

```
1. Webhook триггерит workflow
   ↓
2. OpenAI генерирует тест-кейсы:
   [
     {"input": "/start", "expected": "Привет"},
     {"input": "Помощь", "expected": "Список команд"}
   ]
   ↓
3. Для каждого теста:
   ↓
   3.1. HTTP POST → 72.60.28.252:5001/send_telegram
        Body: {"chat_id": "@target_bot", "message": "/start"}
        ↓
   3.2. Telegram Sender получает запрос
        ↓
   3.3. Telethon отправляет сообщение в Telegram
        (от имени @seno1885)
        ↓
   3.4. Бот (@target_bot) получает сообщение
        ↓
   3.5. Бот отвечает
        ↓
   3.6. HTTP POST → 72.60.28.252:5001/wait_for_response
        Body: {"chat_id": "@target_bot", "timeout": 30}
        ↓
   3.7. Telethon получает ответ бота
        ↓
   3.8. Возвращает в n8n: {"text": "Привет!", "success": true}
        ↓
   3.9. n8n сравнивает с expected
        ↓
4. Результаты тестов агрегируются
   ↓
5. Отчёт отправляется (email/webhook/etc)
```

---

## Техническое решение

### Проблема: Flask + Telethon

**Было (v3.0 - Flask):**
```python
@app.route('/send_telegram')
def send_telegram():
    result = asyncio.run(client.send_message(...))  # Новый event loop!
    return jsonify(result)
```

**Проблема:**
- Flask синхронный (WSGI)
- Каждый `asyncio.run()` создаёт новый event loop
- Telethon привязан к первому event loop
- На VPS с multi-threading → `"event loop must not change after connection"`

**Решение (v4.0 - Quart):**
```python
@app.route('/send_telegram')
async def send_telegram():
    result = await client.send_message(...)  # Тот же event loop!
    return jsonify(result)
```

**Почему работает:**
- Quart асинхронный (ASGI)
- Один event loop для всего приложения
- `asyncio.run(main())` запускается один раз при старте
- Telethon и Quart работают в одном loop

---

## Конфигурация

### .env файл

**Важно:** API ключи хранятся в `.env` файле, который добавлен в `.gitignore`

```bash
# .env файл (НЕ коммитить в git!)
TELEGRAM_API_ID=34713527          # Telegram API ID
TELEGRAM_API_HASH=87be59b2e6888504a5a40f3f04f8af9c  # Telegram API Hash
SESSION_NAME=telegram_session     # Имя файла сессии
PORT=5001                         # Порт сервера
```

**Загрузка:** Скрипты автоматически загружают `.env` через `python-dotenv`:

```python
from dotenv import load_dotenv
load_dotenv()  # Загружает .env в os.environ
```

### n8n Workflow Settings

В HTTP Request ноде:
```
URL: http://72.60.28.252:5001/send_telegram
Method: POST
Headers: Content-Type: application/json
Body:
{
  "chat_id": "{{ $json.bot_username }}",
  "message": "{{ $json.test_message }}"
}
```

---

## Развёртывание

### Первичная установка (VPS)

```bash
# 1. Создать директорию
ssh root@72.60.28.252 "mkdir -p /root/telegram-sender"

# 2. Скопировать файлы с Mac
scp telegram_sender.py telegram_session.session requirements.txt \
    root@72.60.28.252:/root/telegram-sender/

# 3. Установить зависимости
ssh root@72.60.28.252 "cd /root/telegram-sender && \
    pip3 install --break-system-packages -r requirements.txt"

# 4. Запустить
ssh root@72.60.28.252 "cd /root/telegram-sender && \
    nohup python3 telegram_sender.py > /dev/null 2>&1 &"
```

### Перезапуск

```bash
ssh root@72.60.28.252 "fuser -k 5001/tcp; sleep 2; \
    cd /root/telegram-sender && \
    nohup python3 telegram_sender.py > /dev/null 2>&1 &"
```

### Проверка статуса

```bash
curl http://72.60.28.252:5001/health
# {"authenticated":true,"connected":true,"status":"ok","user":"seno1885","version":"4.0-quart"}
```

---

## Авторизация Telethon

**Важно:** Session файл содержит авторизацию. Если нужно переавторизоваться:

```bash
# На Mac (локально):
cd /Users/sergey/Projects/ClaudeN8N/bot-testing-system
python3 auth_telethon.py

# Ввести код из Telegram
# Скопировать новый session на VPS:
scp telegram_session.session root@72.60.28.252:/root/telegram-sender/
```

---

## Мониторинг

### Логи на VPS

```bash
ssh root@72.60.28.252 "tail -f /root/telegram-sender/telegram_sender.log"
```

### Проверка процесса

```bash
ssh root@72.60.28.252 "ps aux | grep telegram_sender"
```

### Тест отправки

```bash
curl -X POST "http://72.60.28.252:5001/send_telegram" \
  -H "Content-Type: application/json" \
  --data-raw '{"chat_id":"@seno1885","message":"Test"}'
```

---

## Безопасность

| Компонент | Защита |
|-----------|--------|
| API_ID/HASH | Хранятся в `.env` файле (защищён `.gitignore`) |
| Session файл | `*.session` в `.gitignore`, не коммитится |
| VPS порт 5001 | Открыт только для n8n сервера |
| Telethon сессия | Привязана к IP VPS |
| `.gitignore` | Исключает `.env`, `*.session`, `__pycache__` |

**Рекомендации:**
- Настроить firewall на VPS (ufw allow from n8n_ip to port 5001)
- Добавить API key для аутентификации запросов
- Использовать HTTPS (nginx reverse proxy)

---

## Troubleshooting

### Ошибка: "event loop must not change"
**Причина:** Используется Flask вместо Quart
**Решение:** Обновить telegram_sender.py до v4.0

### Ошибка: "Not authenticated"
**Причина:** Session файл отсутствует или устарел
**Решение:** Запустить auth_telethon.py локально, скопировать session

### Ошибка: "Address already in use"
**Причина:** Порт 5001 занят
**Решение:** `fuser -k 5001/tcp`

### Ошибка: Connection refused
**Причина:** Сервер не запущен
**Решение:** Проверить процесс, перезапустить

---

## Версии

| Компонент | Версия |
|-----------|--------|
| Python | 3.12 |
| Quart | 0.19.4 |
| Telethon | 1.35.0 |
| Hypercorn | 0.16.0 |
| python-dotenv | 1.0.0 |
| telegram_sender.py | 4.0-quart |

---

## Файлы проекта

```
/Users/sergey/Projects/ClaudeN8N/bot-testing-system/
├── telegram_sender.py       # Основной сервер (v4.0 Quart)
├── auth_telethon.py         # Скрипт авторизации
├── requirements.txt         # Зависимости Python
├── .env                     # API ключи (не коммитить!)
├── .gitignore               # Защита от утечки данных
├── README.md               # Краткая документация
├── ARCHITECTURE.md         # Этот файл
└── test_data/
    └── scenarios/
        └── smoke_tests.json # Тестовые сценарии
```

**⚠️ Защита секретов:**
- `.env` - содержит API ключи, добавлен в `.gitignore`
- `.gitignore` - также исключает `*.session` файлы
- `telegram_session.session` создаётся локально, не коммитится
