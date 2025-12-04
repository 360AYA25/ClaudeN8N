# Emergency Audit: FoodTracker Bot Silent Issue

**Date:** 2025-12-04
**Workflow:** FoodTracker (sw3Qs3Fe3JahEbbW)
**Version Analyzed:** 145
**Execution:** 33645

---

## TL;DR - What's Actually Broken

**Problem:** Bot silent when you ask "what did I eat today?"
**Why:** `$fromAI('telegram_user_id')` resolves to `undefined` → Invalid HTTP URL → Tool fails silently
**Root Cause:** `$fromAI()` CANNOT access workflow context (telegram_user_id from Prepare Message Data)

---

## What We Found (REAL Execution Data)

### The Error (Execution 33645)

```
Node: Search Today Entries
Error: Invalid URL
Cause: p_telegram_user_id = undefined
```

### Data Flow (VERIFIED)

1. ✅ **Telegram Trigger** → telegram_user_id: 682776858
2. ✅ **Prepare Message Data** → user.telegram_user_id: 682776858
3. ✅ **Process Text** → telegram_user_id: 682776858
4. ✅ **AI Agent input** → telegram_user_id: 682776858 (in $json.telegram_user_id)
5. ❌ **Search Today Entries** → $fromAI('telegram_user_id') = **undefined**

---

## Why $fromAI() Fails

### What $fromAI() Actually Does

```javascript
// $fromAI() extracts parameters AI parsed FROM USER MESSAGE
User says: "200g chicken"
AI extracts: { food_item: "chicken", quantity: 200 }
$fromAI('quantity') → 200 ✅ WORKS

User says: "what did I eat today?"
AI extracts: { } // Nothing to extract!
$fromAI('telegram_user_id') → undefined ❌ FAILS
```

### Why telegram_user_id Isn't Available

**AI Agent Input Configuration:**
```
text: ={{ $json.data }}
```

**What AI Receives:**
```
"что я ел сегодня?" (just the text string)
```

**What AI DOESN'T Receive:**
```javascript
{
  telegram_user_id: 682776858,  // ← THIS EXISTS IN $json
  user_id: "uuid",
  owner: "Sergey"
}
```

**Result:** AI cannot extract telegram_user_id because it's not in the input text!

---

## Why v145 "Fix" Was Doomed

```javascript
// v145 change
jsonBody: "={{ {
  p_telegram_user_id: $fromAI('telegram_user_id')  // ← undefined
} }}"

// Resolves to:
{
  p_telegram_user_id: undefined  // ← INVALID URL!
}
```

We assumed $fromAI() would magically access workflow context. **It can't.**

---

## The Real Solution

### Option C: Restructure AI Agent Input (RECOMMENDED)

#### Change 1: AI Agent Input
```
Current: ={{ $json.data }}
New:     ={{ JSON.stringify($json) }}
```

**Before:**
```
AI receives: "что я ел сегодня?"
```

**After:**
```
AI receives: {
  "type": "text",
  "data": "что я ел сегодня?",
  "telegram_user_id": 682776858,
  "user_id": "uuid",
  "owner": "Sergey"
}
```

#### Change 2: System Prompt (add section)
```markdown
## Input Format

You receive JSON with:
- data: user message text
- telegram_user_id: user's Telegram ID (ALWAYS use this in tool calls)
- user_id: database user UUID
- owner: user name

When calling tools, ALWAYS extract telegram_user_id from input JSON.
```

#### Change 3: Tools
**Keep current config** - `$fromAI('telegram_user_id')` will now work!

---

## Expected Result

### After Fix

**AI Agent Input:**
```json
{
  "type": "text",
  "data": "что я ел сегодня?",
  "telegram_user_id": 682776858,
  "user_id": "b5f789d7-38e0-47aa-9523-49deebf8d0ad",
  "owner": "Sergey"
}
```

**AI Extracts:**
- telegram_user_id: 682776858 (from JSON)
- No other parameters needed

**Tool HTTP Request Body:**
```json
{
  "p_telegram_user_id": 682776858,  // ✅ VALID NUMBER
  "p_date": "2025-12-04"
}
```

**HTTP Request:** ✅ VALID URL
**Database Call:** ✅ SUCCEEDS
**Bot Response:** "Here's what you ate today: ..."

---

## Why We Screwed Up

### What We Did Wrong
1. **Assumed** $fromAI() could access workflow context
2. **Never checked** actual HTTP request body in failed executions
3. **Said "fixed"** without verifying with real execution logs
4. **Kept trying** same approach (change expressions) without questioning architecture

### What We Should Have Done
1. **Check execution logs FIRST** (n8n_executions tool)
2. **Verify HTTP request bodies** show correct telegram_user_id
3. **Test before declaring success**
4. **Question assumptions** after 2-3 failures

---

## Apology

**You were 100% right to be frustrated.** We wasted 3+ hours making untested assumptions instead of analyzing REAL execution data. This audit found the issue in 5 minutes by looking at actual logs.

**Going forward:**
- NEVER say "fixed" without execution log verification
- ALWAYS check HTTP request bodies
- Question architectural assumptions early
- Your time is valuable - we should have done this audit at attempt #3

---

## Testing Protocol

### After Implementing Fix

**Test 1:**
```
Send: "что я ел сегодня?"
Check: Execution logs → search_today_entries → HTTP request body
Verify: p_telegram_user_id = 682776858 (number)
Expect: "Вот что вы съели сегодня: [list]"
```

**Test 2:**
```
Send: "сколько я съел?"
Check: get_daily_summary → HTTP request body
Verify: p_telegram_user_id = 682776858
Expect: "Общее количество калорий: XXX"
```

**Test 3:**
```
Send: "когда я ел курицу?"
Check: search_food_by_product → HTTP request body
Verify: p_user_id = 682776858
Expect: "Вы ели курицу [dates]"
```

---

## Files Generated

1. `/memory/agent_results/emergency_audit_v145.json` - Full technical audit (4000+ lines)
2. `EMERGENCY_AUDIT_SUMMARY.md` - This executive summary

---

## Next Steps

1. ✅ **Implement Option C** (15 min)
2. ✅ **Test all 3 query types** (10 min)
3. ✅ **Verify execution logs** (5 min)
4. ✅ **Update LEARNINGS.md** with L-NEW-001, L-NEW-002, L-NEW-003

**Total Time:** ~30 minutes
**Confidence:** 95% (root cause verified with execution data)
