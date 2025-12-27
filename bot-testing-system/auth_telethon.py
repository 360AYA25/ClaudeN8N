#!/usr/bin/env python3
"""
One-time Telethon authentication script
Run this to create telegram_session file
"""

import asyncio
import os
from telethon import TelegramClient
import logging
from dotenv import load_dotenv

# Load .env file
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_ID = int(os.getenv('TELEGRAM_API_ID', '34713527'))
API_HASH = os.getenv('TELEGRAM_API_HASH', '87be59b2e6888504a5a40f3f04f8af9c')

async def authenticate():
    """Interactive authentication"""
    logger.info("=" * 60)
    logger.info("Telethon Authentication")
    logger.info("=" * 60)
    logger.info(f"API_ID: {API_ID}")
    logger.info("API_HASH: ****")
    logger.info("")

    client = TelegramClient('telegram_session', API_ID, API_HASH)

    try:
        await client.connect()

        if not client.is_connected():
            logger.error("❌ Could not connect to Telegram")
            return False

        logger.info("✅ Connected to Telegram servers")
        logger.info("")
        logger.info("If this is first run, you'll need to:")
        logger.info("1. Enter your phone number (with +country code)")
        logger.info("2. Enter the verification code sent to Telegram")
        logger.info("3. If two-factor enabled, enter your password")
        logger.info("")

        # Check if already authorized
        if await client.is_user_authorized():
            logger.info("✅ Session already authenticated!")
            me = await client.get_me()
            logger.info(f"   Logged in as: {me.first_name} (@{me.username})")
        else:
            logger.info("⏳ Starting authentication...")
            # This will trigger interactive auth
            await client.start()
            me = await client.get_me()
            logger.info(f"✅ Successfully authenticated as: {me.first_name} (@{me.username})")

        logger.info("")
        logger.info("Session saved to: telegram_session.session")
        logger.info("You can now run telegram_sender.py")

        await client.disconnect()

    except Exception as e:
        logger.error(f"❌ Authentication failed: {e}")
        return False

    return True

if __name__ == "__main__":
    success = asyncio.run(authenticate())
    exit(0 if success else 1)
