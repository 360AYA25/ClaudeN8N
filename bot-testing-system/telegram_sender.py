#!/usr/bin/env python3
"""
Telegram Sender Server v4.0 (Quart async-native)
Sends messages from your personal account via Telethon

FIXED: asyncio event loop conflict (Flask → Quart)
"""

import os
import asyncio
import logging
from datetime import datetime
from pathlib import Path
from quart import Quart, request, jsonify
from telethon import TelegramClient
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# Config
API_ID = int(os.getenv('TELEGRAM_API_ID', '34713527'))
API_HASH = os.getenv('TELEGRAM_API_HASH', '87be59b2e6888504a5a40f3f04f8af9c')
SESSION_NAME = os.getenv('SESSION_NAME', 'telegram_session')
PORT = int(os.getenv('PORT', '5001'))

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler('telegram_sender.log'), logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# App & Client
app = Quart(__name__)
client = TelegramClient(SESSION_NAME, API_ID, API_HASH)
is_authenticated = False
user_info = None


@app.before_serving
async def startup():
    global is_authenticated, user_info
    try:
        await client.connect()
        if client.is_connected():
            is_authenticated = await client.is_user_authorized()
            if is_authenticated:
                user_info = await client.get_me()
                logger.info(f"Connected as: {user_info.first_name} (@{user_info.username})")
            else:
                logger.warning("Not authorized. Run auth_telethon.py first.")
    except Exception as e:
        logger.error(f"Startup error: {e}")


@app.after_serving
async def shutdown():
    if client.is_connected():
        await client.disconnect()
        logger.info("Disconnected")


@app.route('/health', methods=['GET'])
async def health():
    return jsonify({
        'status': 'ok',
        'authenticated': is_authenticated,
        'connected': client.is_connected(),
        'user': user_info.username if user_info else None,
        'version': '4.0-quart'
    })


@app.route('/send_telegram', methods=['POST'])
async def send_telegram():
    try:
        data = await request.get_json()
        chat_id = data.get('chat_id')
        message = data.get('message')

        if not chat_id or not message:
            return jsonify({'error': 'Missing chat_id or message'}), 400
        if not is_authenticated:
            return jsonify({'error': 'Not authenticated'}), 503

        logger.info(f"Sending to {chat_id}: {message[:50]}...")
        result = await client.send_message(chat_id, str(message))

        return jsonify({
            'success': True,
            'message_id': result.id,
            'timestamp': result.date.isoformat() if result.date else datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Send error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/get_last_message', methods=['POST'])
async def get_last_message():
    try:
        data = await request.get_json()
        chat_id = data.get('chat_id')
        limit = data.get('limit', 1)

        if not chat_id:
            return jsonify({'error': 'Missing chat_id'}), 400
        if not is_authenticated:
            return jsonify({'error': 'Not authenticated'}), 503

        messages = await client.get_messages(chat_id, limit=limit)
        if not messages:
            return jsonify({'success': False, 'text': None})

        msg = messages[0]
        return jsonify({
            'success': True,
            'message_id': msg.id,
            'sender_id': msg.sender_id,
            'text': msg.text,
            'date': msg.date.isoformat() if msg.date else None
        })
    except Exception as e:
        logger.error(f"Get error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/wait_for_response', methods=['POST'])
async def wait_for_response():
    try:
        data = await request.get_json()
        chat_id = data.get('chat_id')
        after_id = data.get('after_message_id', 0)
        timeout = data.get('timeout', 30)

        if not chat_id:
            return jsonify({'error': 'Missing chat_id'}), 400
        if not is_authenticated:
            return jsonify({'error': 'Not authenticated'}), 503

        my_id = user_info.id if user_info else None
        start = asyncio.get_event_loop().time()

        while (asyncio.get_event_loop().time() - start) < timeout:
            messages = await client.get_messages(chat_id, limit=5)
            for msg in messages:
                if msg.id > after_id and msg.sender_id != my_id:
                    return jsonify({
                        'success': True,
                        'message_id': msg.id,
                        'text': msg.text,
                        'sender_id': msg.sender_id
                    })
            await asyncio.sleep(1)

        return jsonify({'success': False, 'message': 'Timeout'})
    except Exception as e:
        logger.error(f"Wait error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/info', methods=['GET'])
async def info():
    return jsonify({
        'service': 'Telegram Sender',
        'version': '4.0-quart',
        'endpoints': ['POST /send_telegram', 'POST /get_last_message', 'POST /wait_for_response', 'GET /health']
    })


if __name__ == '__main__':
    async def main():
        logger.info("=" * 50)
        logger.info("Telegram Sender v4.0 (Quart)")
        logger.info(f"Port: {PORT}")
        logger.info("=" * 50)

        try:
            from hypercorn.config import Config
            from hypercorn.asyncio import serve
            config = Config()
            config.bind = [f"0.0.0.0:{PORT}"]
            await serve(app, config)
        except ImportError:
            await app.run_task(host='0.0.0.0', port=PORT)

    asyncio.run(main())
