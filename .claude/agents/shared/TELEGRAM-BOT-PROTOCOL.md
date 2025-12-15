# 🔴 CRITICAL: Telegram Bot Command Protocol

## MANDATORY RULES - NO EXCEPTIONS

### When Modifying Bot Commands

**IF** you change ANY Telegram bot commands (add/remove/rename), you **MUST** update in **TWO** places:

1. ✅ **n8n workflow** - Switch node routing (what bot executes)
2. ✅ **BotFather API** - Telegram command menu (what user sees)

**❌ FORBIDDEN:**
- Changing workflow commands without updating BotFather
- Assuming BotFather updates automatically
- Skipping verification step

---

## Required Workflow

### Step 1: Update n8n Workflow

- Modify Switch node command routing
- Update any Code nodes with command arrays
- Test workflow execution with new commands

### Step 2: Update BotFather (ALWAYS!)

**Credentials Location:**
```
/Users/sergey/Projects/ClaudeN8N/CREDENTIALS.env
```

**Get Token:**
```bash
TOKEN=$(grep TELEGRAM_BOT_TOKEN /Users/sergey/Projects/ClaudeN8N/CREDENTIALS.env | cut -d'=' -f2)
```

**Update Commands:**
```bash
curl -X POST "https://api.telegram.org/bot${TOKEN}/setMyCommands" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"command": "help", "description": "Помощь"},
      {"command": "day", "description": "Дневной отчёт"},
      {"command": "week", "description": "Недельный отчёт"},
      {"command": "month", "description": "Месячный отчёт"},
      {"command": "settings", "description": "Настройки"},
      {"command": "welcome", "description": "Профиль"}
    ]
  }'
```

**Verify:**
```bash
curl -X POST "https://api.telegram.org/bot${TOKEN}/getMyCommands"
```

### Step 3: User Verification

**ASK USER to verify:**
1. Open bot in Telegram app
2. Check command menu shows correct commands
3. Confirm old commands removed (if any)

---

## Why This Matters

**Two Separate Systems:**
- **n8n workflow** = Backend logic (what happens when user sends command)
- **BotFather** = Frontend UI (menu user sees in Telegram)

**Changing workflow does NOT update BotFather automatically!**

Result: User sees old commands in menu → tries to use them → workflow doesn't handle them → bot appears broken.

---

## Checklist (MANDATORY)

When modifying commands, verify ALL steps:

- [ ] Updated Switch node routing in n8n workflow
- [ ] Updated command arrays in Code nodes (if any)
- [ ] Read TELEGRAM_BOT_TOKEN from CREDENTIALS.env
- [ ] Called setMyCommands API with new command list
- [ ] Called getMyCommands to verify update
- [ ] Asked user to verify in Telegram app
- [ ] User confirmed commands appear correctly

**DO NOT mark task complete until ALL checkboxes checked!**

---

## Common Mistakes

❌ "I updated the workflow, commands should work now"
✅ "I updated workflow AND BotFather API"

❌ "User can't see the command in menu"
✅ "I verified BotFather was updated via getMyCommands"

❌ "I don't know where the bot token is"
✅ "Token is in /Users/sergey/Projects/ClaudeN8N/CREDENTIALS.env"

---

**Last Updated:** 2025-12-13
**Applies To:** ALL Telegram bot projects
**Priority:** CRITICAL
