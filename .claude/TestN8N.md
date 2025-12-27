# Complete Guide: n8n Bot with Command Generation and Telegram Testing

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Preparation: Getting API Credentials](#preparation-getting-api-credentials)
3. [Installing Dependencies](#installing-dependencies)
4. [Python Telethon Server](#python-telethon-server)
5. [Setting up n8n Workflow](#setting-up-n8n-workflow)
6. [Docker Deployment](#docker-deployment)
7. [System Testing](#system-testing)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

How the system works:

```
+-----------------------------------------------------+
| n8n Workflow (Bot Testing Engine)                   |
|                                                      |
|  1. AI Agent generates test commands               |
|  2. Sends commands from your personal account      |
|  3. Receives response from your Telegram bot       |
|  4. Validates and logs results                     |
|                                                      |
+-----------------------------------------------------+
         |                                     ^
    Telethon Server                    Telegram API
    (sends from your                   (personal
     personal account)                 account)
         |                                     ^
    Telegram Bot (your bot under test)
```

---

## Preparation: Getting API Credentials

### Step 1: Get API_ID and API_HASH

1. Go to: **https://my.telegram.org/apps**
2. Log in with your phone number (you'll receive a confirmation code on mobile)
3. Click "Create new application"
4. Fill in the form:
   - **App title**: "n8n Bot Testing" (any name)
   - **Short name**: "n8n_bot_testing"
   - Leave rest as default
5. Copy:
   - **api_id** (number, example: 12345678)
   - **api_hash** (string, example: abcd1234efgh5678ijkl9012mnop3456)

WARNING: Never share these credentials!

### Step 2: Find Your Telegram User ID (if needed)

1. Find the bot @userinfobot in Telegram
2. Send it /start
3. Bot will return your User ID

---

## Installing Dependencies

### On Linux/Mac:

```bash
# Check Python version (need 3.8+)
python3 --version

# Create virtual environment (optional)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install telethon flask
```

### On Windows:

```bash
# Check Python version (need 3.8+)
python --version

# Create virtual environment (optional)
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install telethon flask
```

---

## Python Telethon Server

### Create File: telegram_sender.py

Create a new file named `telegram_sender.py` in a separate folder:

```python
#!/usr/bin/env python3
"""
Telegram Sender Server
Sends messages from your personal account via Telethon
"""

from flask import Flask, request, jsonify
from telethon.sync import TelegramClient
from telethon.errors import SessionPasswordNeededError
import logging
import os
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ===== IMPORTANT: Replace these with your own values =====
API_ID = 12345678  # Get from https://my.telegram.org/apps
API_HASH = 'your_api_hash_here'  # Get from https://my.telegram.org/apps
# ========================================================

# Initialize client
# Session will be saved in telegram_session.session file
client = TelegramClient('telegram_session', API_ID, API_HASH)

# Flag to track authentication
is_authenticated = False

def authenticate_client():
    """Authenticates client on first run"""
    global is_authenticated
    
    try:
        if client.is_connected():
            logger.info("Client already connected")
            is_authenticated = True
            return True
        
        with client:
            logger.info("Client successfully authenticated")
            is_authenticated = True
            return True
    except SessionPasswordNeededError:
        logger.error("Two-factor authentication required")
        return False
    except Exception as e:
        logger.error(f"Authentication error: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """Check server status"""
    return jsonify({
        'status': 'ok',
        'authenticated': is_authenticated,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/send_telegram', methods=['POST'])
def send_telegram():
    """
    Send message to Telegram
    
    JSON Parameters:
    {
        "chat_id": "@bot_username" or user_id,
        "message": "message text"
    }
    
    Response:
    {
        "success": true,
        "message_id": 12345,
        "timestamp": "2025-12-27T13:15:00"
    }
    """
    try:
        data = request.json
        
        if not data:
            return jsonify({'error': 'Empty request body'}), 400
        
        chat_id = data.get('chat_id')
        message = data.get('message')
        
        if not chat_id or not message:
            return jsonify({
                'error': 'Missing required fields: chat_id and message'
            }), 400
        
        logger.info(f"Sending message to {chat_id}: {message[:50]}...")
        
        with client:
            # Send message
            result = client.send_message(chat_id, str(message))
            
            logger.info(f"Message sent successfully. ID: {result.id}")
            
            return jsonify({
                'success': True,
                'message_id': result.id,
                'timestamp': result.date.isoformat(),
                'chat_id': chat_id
            }), 200
    
    except Exception as e:
        logger.error(f"Error sending message: {str(e)}")
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

@app.route('/get_last_message', methods=['POST'])
def get_last_message():
    """
    Get last message from chat
    
    JSON Parameters:
    {
        "chat_id": "@bot_username" or user_id,
        "limit": 1  (optional, how many messages to get)
    }
    
    Response:
    {
        "success": true,
        "sender_id": 987654321,
        "text": "Bot response",
        "date": "2025-12-27T13:15:05"
    }
    """
    try:
        data = request.json
        chat_id = data.get('chat_id')
        limit = data.get('limit', 1)
        
        if not chat_id:
            return jsonify({'error': 'Missing chat_id'}), 400
        
        logger.info(f"Getting last {limit} messages from {chat_id}")
        
        with client:
            messages = client.get_messages(chat_id, limit=limit)
            
            if not messages:
                return jsonify({
                    'success': False,
                    'text': None,
                    'message': 'No messages found'
                }), 200
            
            # Get first message (newest)
            msg = messages[0]
            
            response = {
                'success': True,
                'sender_id': msg.sender_id,
                'text': msg.text,
                'date': msg.date.isoformat(),
                'message_id': msg.id
            }
            
            logger.info(f"Message received: {msg.text[:50] if msg.text else '[media]'}...")
            
            return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Error getting message: {str(e)}")
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

@app.route('/get_dialog_history', methods=['POST'])
def get_dialog_history():
    """
    Get dialog history
    
    JSON Parameters:
    {
        "chat_id": "@bot_username" or user_id,
        "limit": 10  (how many messages to get)
    }
    
    Response: array of messages
    """
    try:
        data = request.json
        chat_id = data.get('chat_id')
        limit = data.get('limit', 10)
        
        if not chat_id:
            return jsonify({'error': 'Missing chat_id'}), 400
        
        logger.info(f"Getting history from {chat_id} ({limit} messages)")
        
        with client:
            messages = client.get_messages(chat_id, limit=limit)
            
            history = []
            for msg in messages:
                history.append({
                    'sender_id': msg.sender_id,
                    'text': msg.text,
                    'date': msg.date.isoformat(),
                    'message_id': msg.id
                })
            
            return jsonify({
                'success': True,
                'count': len(history),
                'messages': history
            }), 200
    
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

@app.route('/info', methods=['GET'])
def info():
    """Server information"""
    return jsonify({
        'service': 'Telegram Sender Server',
        'version': '1.0',
        'endpoints': {
            'POST /send_telegram': 'Send message',
            'POST /get_last_message': 'Get last message',
            'POST /get_dialog_history': 'Get dialog history',
            'GET /health': 'Check status',
            'GET /info': 'This information'
        }
    })

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("Telegram Sender Server starting")
    logger.info("=" * 60)
    
    # Check API credentials
    if API_ID == 12345678 or API_HASH == 'your_api_hash_here':
        logger.error("ERROR: Replace API_ID and API_HASH in the code!")
        logger.error("Get values from https://my.telegram.org/apps")
        exit(1)
    
    logger.info(f"API_ID: {API_ID}")
    logger.info("API_HASH: ****")
    
    # Try to authenticate
    if not authenticate_client():
        logger.warning("WARNING: Could not authenticate. Check API credentials")
    
    logger.info("Server running on http://0.0.0.0:5000")
    logger.info("Available endpoints:")
    logger.info("  POST /send_telegram - send message")
    logger.info("  POST /get_last_message - get last message")
    logger.info("  GET /health - check status")
    
    app.run(host='0.0.0.0', port=5000, debug=False)
```

### Running the Server

```bash
# Linux/Mac
python3 telegram_sender.py

# Windows
python telegram_sender.py
```

**What happens on first run:**

1. You'll see an authentication message
2. May need to scan QR code or enter confirmation code
3. After authentication, session saves to `telegram_session.session`
4. Server runs on `http://localhost:5000`

WARNING: On first run you need to authenticate. Save the `telegram_session.session` file - it's your session!

---

## Setting up n8n Workflow

### Option 1: Import Ready Workflow

1. Open n8n
2. Click "+ New" -> "Import from URL" or "Paste Workflow Code"
3. Copy and paste JSON below

### JSON Workflow for Import

```json
{
  "name": "Telegram Bot Testing Automation",
  "nodes": [
    {
      "parameters": {
        "triggerTimes": {
          "item": [
            {
              "mode": "everyMinutes",
              "value": 5
            }
          ]
        }
      },
      "id": "Schedule_Trigger",
      "name": "Schedule",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.1,
      "position": [100, 100]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://localhost:5000/health",
        "sendBody": false
      },
      "id": "Check_Server",
      "name": "Check Server Status",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [300, 100]
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "name": "testCommands",
              "value": "['/start', '/help', '/status', '/test', '/info']"
            },
            {
              "name": "botUsername",
              "value": "@your_bot_username"
            }
          ]
        }
      },
      "id": "Set_Test_Data",
      "name": "Set Test Commands",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.4,
      "position": [500, 100]
    },
    {
      "parameters": {
        "values": "={\n  \"commands\": [\n    \"/start\",\n    \"/help\",\n    \"/status\",\n    \"/test\",\n    \"/info\"\n  ]\n}",
        "options": {}
      },
      "id": "Generate_Commands",
      "name": "Generate Test Commands",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [700, 100]
    },
    {
      "parameters": {
        "loopOver": "=commands"
      },
      "id": "Loop_Commands",
      "name": "Loop Through Commands",
      "type": "n8n-nodes-base.itemLists",
      "typeVersion": 3.2,
      "position": [900, 100]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "=http://localhost:5000/send_telegram",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "chat_id",
              "value": "={{ $json.botUsername }}"
            },
            {
              "name": "message",
              "value": "={{ $json.item }}"
            }
          ]
        }
      },
      "id": "Send_Message",
      "name": "Send Test Command",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1100, 100]
    },
    {
      "parameters": {
        "amount": 3,
        "unit": "seconds"
      },
      "id": "Wait_Response",
      "name": "Wait for Bot Response",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1.1,
      "position": [1300, 100]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "=http://localhost:5000/get_last_message",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "chat_id",
              "value": "={{ $json.botUsername }}"
            }
          ]
        }
      },
      "id": "Get_Response",
      "name": "Get Bot Response",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1500, 100]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.success }}",
              "operation": "equals",
              "value2": "true"
            }
          ]
        }
      },
      "id": "Check_Success",
      "name": "Check Response Success",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1.0,
      "position": [1700, 100]
    },
    {
      "parameters": {
        "values": "={\n  \"command\": {{ $json.item | toJSON }},\n  \"success\": true,\n  \"response\": {{ $json.text | toJSON }},\n  \"timestamp\": new Date().toISOString()\n}",
        "options": {}
      },
      "id": "Log_Success",
      "name": "Log Success Result",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1900, 200]
    },
    {
      "parameters": {
        "values": "={\n  \"command\": {{ $json.item | toJSON }},\n  \"success\": false,\n  \"error\": \"No response received\",\n  \"timestamp\": new Date().toISOString()\n}",
        "options": {}
      },
      "id": "Log_Failure",
      "name": "Log Failure Result",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1900, 350]
    }
  ],
  "connections": {
    "Schedule_Trigger": {
      "main": [
        [
          {
            "node": "Check_Server",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Check_Server": {
      "main": [
        [
          {
            "node": "Generate_Commands",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Generate_Commands": {
      "main": [
        [
          {
            "node": "Loop_Commands",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Loop_Commands": {
      "main": [
        [
          {
            "node": "Send_Message",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Send_Message": {
      "main": [
        [
          {
            "node": "Wait_Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Wait_Response": {
      "main": [
        [
          {
            "node": "Get_Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Get_Response": {
      "main": [
        [
          {
            "node": "Check_Success",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Check_Success": {
      "main": [
        [
          {
            "node": "Log_Success",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Log_Failure",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

### Option 2: Manual Creation in n8n UI

1. **Add trigger**:
   - Node: "Schedule" (every N minutes)
   
2. **Check server**:
   - Node: "HTTP Request"
   - URL: `http://localhost:5000/health`
   - Method: GET

3. **Generate commands**:
   - Node: "Code"
   - Language: JavaScript
   - Code:
   ```javascript
   return [
     { item: '/start' },
     { item: '/help' },
     { item: '/status' },
     { item: '/test' }
   ];
   ```

4. **Loop through commands**:
   - Node: "Loop" (Item Lists)
   - Loop over: commands

5. **Send message**:
   - Node: "HTTP Request"
   - URL: `http://localhost:5000/send_telegram`
   - Method: POST
   - Body:
   ```json
   {
     "chat_id": "@your_bot_username",
     "message": "{{$json.item}}"
   }
   ```

6. **Wait for response**:
   - Node: "Wait"
   - Time: 3 seconds

7. **Get response**:
   - Node: "HTTP Request"
   - URL: `http://localhost:5000/get_last_message`
   - Method: POST
   - Body:
   ```json
   {
     "chat_id": "@your_bot_username"
   }
   ```

8. **Check success**:
   - Node: "If"
   - Condition: success == true

9. **Log results**:
   - Success: Code Node
   - Failure: Code Node

---

## Docker Deployment

### Create Dockerfile

Create file `Dockerfile` in folder with `telegram_sender.py`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy files
COPY telegram_sender.py .
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create folder for sessions
RUN mkdir -p /app/sessions

# Expose port
EXPOSE 5000

# Run command
CMD ["python3", "telegram_sender.py"]
```

### File: requirements.txt

```
telethon==1.35.0
flask==3.0.0
```

### Docker Commands

```bash
# Build image
docker build -t telegram-sender:latest .

# Run container
docker run -d \
  --name telegram-sender \
  -p 5000:5000 \
  -v $(pwd)/sessions:/app/sessions \
  telegram-sender:latest

# View logs
docker logs -f telegram-sender

# Stop container
docker stop telegram-sender

# Remove container
docker rm telegram-sender
```

### Docker Compose

Create file `docker-compose.yml`:

```yaml
version: '3.8'

services:
  telegram-sender:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./sessions:/app/sessions
    environment:
      - FLASK_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  n8n:
    image: n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - telegram-sender
    restart: unless-stopped

volumes:
  n8n_data:
```

**Running:**
```bash
docker-compose up -d
```

---

## System Testing

### Test 1: Check Server

```bash
# Linux/Mac
curl http://localhost:5000/health

# Windows (PowerShell)
curl.exe http://localhost:5000/health
```

**Expected response:**
```json
{
  "status": "ok",
  "authenticated": true,
  "timestamp": "2025-12-27T13:15:00"
}
```

### Test 2: Send Message

```bash
curl -X POST http://localhost:5000/send_telegram \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "@your_bot_username",
    "message": "/start"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "message_id": 12345,
  "timestamp": "2025-12-27T13:15:05",
  "chat_id": "@your_bot_username"
}
```

### Test 3: Get Response

```bash
curl -X POST http://localhost:5000/get_last_message \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "@your_bot_username"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "sender_id": 987654321,
  "text": "Hello! This is bot response",
  "date": "2025-12-27T13:15:10",
  "message_id": 12346
}
```

### Test 4: Get Dialog History

```bash
curl -X POST http://localhost:5000/get_dialog_history \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "@your_bot_username",
    "limit": 5
  }'
```

---

## Troubleshooting

### Problem: "Invalid API credentials"

**Solution:**
1. Check you copied API_ID and API_HASH correctly
2. Go to https://my.telegram.org/apps and verify values
3. Make sure no spaces at beginning/end of strings

### Problem: "SessionPasswordNeededError"

**Solution:**
1. This means two-factor authentication is enabled on account
2. On first run enter password when system asks
3. After that session saves and password not needed again

### Problem: "Connection refused" for Telethon server

**Solution:**
1. Check server is running: `python3 telegram_sender.py`
2. Check server running on correct port: 5000
3. If using Docker, check container running: `docker ps`

### Problem: n8n cannot connect to server

**Solution:**
1. If n8n and server on same computer, use `http://localhost:5000`
2. If on different computers, use IP address: `http://192.168.1.100:5000`
3. Make sure firewall not blocking port 5000

### Problem: Message not sending

**Solution:**
1. Check bot ID or username is correct
2. If using username, make sure starts with @
3. If using ID, make sure it's number not string
4. Check server logs - they show detailed error

### Problem: Message sent but no response received

**Solution:**
1. Increase wait time in n8n (Wait node): from 3 sec to 5-10 sec
2. Check bot actually responds to commands manually
3. Check using correct chat_id
4. Look at dialog history: `/get_dialog_history`

### Problem: "RESOURCE_LIMIT_EXCEEDED"

**Solution:**
1. This means sending too many messages too fast
2. Increase interval between messages (in n8n: add Wait between Loop iterations)
3. Telegram has rate limits: max ~30 messages per minute

### Error in logs: "telethon.errors.rpcerrorlist.UserBannedError"

**Solution:**
1. Your account was banned for spam
2. Usually temporary ban (hours to days)
3. Avoid sending large number of messages in row

---

## Quick Reference: Commands and Syntax

### Request Structure

```bash
curl -X POST http://localhost:5000/ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

### Available Endpoints

| Endpoint | Method | Parameters | Description |
|----------|--------|-----------|-------------|
| `/health` | GET | - | Check status |
| `/send_telegram` | POST | chat_id, message | Send message |
| `/get_last_message` | POST | chat_id | Get last message |
| `/get_dialog_history` | POST | chat_id, limit | Get dialog history |
| `/info` | GET | - | Server information |

### Chat ID Examples

```
"@bot_username"        // By username (with @)
123456789              // By user ID (number)
-100123456789          // By channel/group ID (number with minus)
"me"                   // Send to yourself
```

---

## Useful Links

- **Telegram My Apps**: https://my.telegram.org/apps
- **Telethon Documentation**: https://docs.telethon.dev/
- **n8n Documentation**: https://docs.n8n.io/
- **Flask Documentation**: https://flask.palletsprojects.com/
- **Docker Documentation**: https://docs.docker.com/

---

## License

This code distributed under MIT license. Use for your own purposes.

---

**Last Updated**: December 27, 2025
**Version**: 1.0