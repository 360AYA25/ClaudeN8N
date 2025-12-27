# AI-Driven Bot Testing System

## Architecture Overview

```
Webhook → AI Test Generator → Test Executor → Response Validator → Logger
```

---

## System Components

### 1. Webhook Trigger (n8n)
**Endpoint:** `POST /webhook/bot-test`

**Input:**
```json
{
  "bot_username": "@food_tester_bot",
  "task": "test food logging functionality",
  "scope": "full" | "smoke" | "regression"
}
```

### 2. AI Test Generator (AI Agent)
**Role:** Generates test cases based on task description

**Input:** Task from webhook
**Output:** Array of test cases
```json
{
  "tests": [
    {
      "id": "test_001",
      "type": "text",
      "message": "Куриная грудка 200г",
      "expected": "Recorded.*calories",
      "description": "Add simple text meal"
    },
    {
      "id": "test_002",
      "type": "command",
      "message": "/day",
      "expected": "Today.*summary",
      "description": "Check daily report"
    },
    {
      "id": "test_003",
      "type": "photo",
      "file_path": "/test_data/food_photo_1.jpg",
      "message": "What is this?",
      "expected": "Analysis.*calories"
    }
  ]
}
```

### 3. Test Executor (Loop)
**Role:** Executes tests via Telethon Server

**Per-test flow:**
```
For each test:
  ├─ IF type == "text" → POST /send_telegram
  ├─ IF type == "command" → POST /send_telegram
  ├─ IF type == "photo" → POST /send_photo (NEW!)
  ├─ IF type == "voice" → POST /send_voice (NEW!)
  ├─ Wait 3-5 seconds
  └─ GET /get_last_message
```

### 4. Response Validator
**Role:** Checks if response matches expected

**Logic:**
```javascript
{
  "test_id": "test_001",
  "passed": true/false,
  "actual_response": "Recorded chicken breast 200g (~330 calories)",
  "expected_pattern": "Recorded.*calories",
  "match": true
}
```

### 5. Test Logger
**Role:** Saves results to database/file

**Output:**
```json
{
  "run_id": "run_20251227_143022",
  "bot_username": "@food_tester_bot",
  "total_tests": 15,
  "passed": 14,
  "failed": 1,
  "duration_seconds": 45,
  "results": [...]
}
```

---

## Telethon Server API Extensions

### New Endpoints Required

#### 1. POST /send_photo
Send photo with optional caption

```json
// Request (multipart/form-data):
{
  "chat_id": "@bot_username",
  "photo": <binary file>,
  "caption": "What is this?"  // optional
}

// Response:
{
  "success": true,
  "message_id": 12345,
  "timestamp": "2025-12-27T14:30:22"
}
```

#### 2. POST /send_voice
Send voice message

```json
// Request (multipart/form-data):
{
  "chat_id": "@bot_username",
  "voice": <binary file>
}

// Response:
{
  "success": true,
  "message_id": 12346
}
```

### Updated Endpoints

#### POST /send_telegram (existing)
For text and commands

#### GET /get_last_message (existing)
Get bot response

---

## n8n Workflow Structure

### Main Workflow: `Bot_Test_Automation`

```
┌─────────────────────────────────────────────────────────────┐
│ Node 1: Webhook Trigger                                     │
│   Path: /webhook/bot-test                                   │
│   Method: POST                                              │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Node 2: Set Test Context                                    │
│   - bot_username                                            │
│   - task                                                    │
│   - scope                                                   │
│   - run_id (timestamp)                                      │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Node 3: AI Test Generator (AI Agent)                        │
│   Model: GPT-4o-mini / local LLM                            │
│   Prompt: Generate test cases for task                      │
│   Output: { tests: [...] }                                  │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Node 4: Loop Over Tests (Item Lists)                        │
│   Loop over: tests                                          │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Node 5: Switch (by test.type)                               │
│   Routes: text | command | photo | voice                    │
└─────┬─────────┬─────────┬─────────┬─────────────────────────┘
      │         │         │         │
      ▼         ▼         ▼         ▼
   [Text]   [Command] [Photo]  [Voice]
      │         │         │         │
      └─────────┴─────────┴─────────┴───────┐
                                           ▼
                    ┌─────────────────────────────────────┐
                    │ Node 6A-D: Send via Telethon        │
                    │ (different endpoints per type)      │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 7: Wait (3-5 seconds)          │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 8: Get Bot Response            │
                    │ GET /get_last_message               │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 9: Validate Response (Code)    │
                    │ Check actual vs expected pattern    │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 10: Collect Results            │
                    │ Append to results array             │
                    └────────────��────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 11: After Loop (Loop done)     │
                    │ Generate summary report             │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 12: Log Results                │
                    │ Save to Supabase / File / Webhook   │
                    └────────────┬────────────────────────┘
                                 ▼
                    ┌─────────────────────────────────────┐
                    │ Node 13: Return Response            │
                    │ { run_id, total, passed, failed }   │
                    └─────────────────────────────────────┘
```

---

## Test Data Requirements

### Test Files Location
```
/test_data/
├── photos/
│   ├── food_banana.jpg
│   ├── food_sandwich.jpg
│   ├── barcode_milk.jpg
│   └── barcode_eggs.jpg
├── voice/
│   ├── test_add_meal.ogg
│   └── test_report.ogg
└── prompts/
    └── test_scenarios.json
```

### File Upload in n8n
For photo/voice tests:
```javascript
// Code Node to read file
const fs = require('fs');
const test_data = {
  photo: fs.readFileSync('/test_data/photos/food_banana.jpg'),
  voice: fs.readFileSync('/test_data/voice/test_add_meal.ogg')
};
return { json: test_data };
```

---

## AI Test Generator Prompt Template

```
You are a bot testing expert. Generate test cases for the given task.

Task: {{ $json.task }}
Scope: {{ $json.scope }}
Bot: {{ $json.bot_username }}

Generate 5-15 test cases covering:
- Text inputs (natural language)
- Commands (/day, /week, /month, /help)
- Photo uploads (with/without barcode)
- Edge cases (empty, special characters)

Output JSON format:
{
  "tests": [
    {
      "id": "test_001",
      "type": "text|command|photo|voice",
      "message": "message content or file path",
      "expected": "regex pattern for expected response",
      "description": "what this test verifies"
    }
  ]
}

Rules:
- Be specific in expected patterns (use regex)
- Cover happy path and edge cases
- Test file paths should reference /test_data/
- Each test must be unique
```

---

## Example Test Scenarios

### Smoke Tests (5 tests)
```json
[
  { "type": "text", "message": "/start", "expected": "welcome|hello" },
  { "type": "text", "message": "Apple 100g", "expected": "recorded|added" },
  { "type": "command", "message": "/day", "expected": "today|summary" },
  { "type": "command", "message": "/help", "expected": "commands|available" },
  { "type": "text", "message": "/week", "expected": "weekly|summary" }
]
```

### Full Regression (20+ tests)
```json
[
  // Registration
  { "type": "text", "message": "/start", "expected": "welcome" },
  { "type": "text", "message": "Sergey", "expected": "registered|goal" },

  // Text inputs
  { "type": "text", "message": "Chicken 200g", "expected": "calories" },
  { "type": "text", "message": "Рыба с рисом", "expected": "recorded" },
  { "type": "text", "message": "Update last to 300g", "expected": "updated" },

  // Commands
  { "type": "command", "message": "/day", "expected": "today.*calories" },
  { "type": "command", "message": "/week", "expected": "weekly.*protein" },
  { "type": "command", "message": "/month", "expected": "monthly" },

  // Photos
  { "type": "photo", "message": "/test_data/food_banana.jpg", "expected": "banana|analysis" },
  { "type": "photo", "message": "/test_data/barcode_milk.jpg", "expected": "milk|product" },

  // Edge cases
  { "type": "text", "message": "", "expected": "error|try again" },
  { "type": "text", "message": "!!!@@###", "expected": "didn't understand" }
]
```

---

## Response Validation Logic

### Code Node (Validate Response)
```javascript
// Input: $json (test case + actual response)
const testCase = $json.test;
const actual = $json.response.text;
const expected = testCase.expected;

// Regex match
const pattern = new RegExp(expected, 'i');
const passed = pattern.test(actual);

return {
  json: {
    test_id: testCase.id,
    description: testCase.description,
    type: testCase.type,
    message: testCase.message,
    expected_pattern: expected,
    actual_response: actual,
    passed: passed,
    timestamp: new Date().toISOString()
  }
};
```

---

## Result Logging

### Options:

**Option A: Supabase Table**
```sql
CREATE TABLE bot_test_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id TEXT UNIQUE NOT NULL,
  bot_username TEXT,
  task TEXT,
  total_tests INTEGER,
  passed INTEGER,
  failed INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE bot_test_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id TEXT REFERENCES bot_test_runs(run_id),
  test_id TEXT,
  test_type TEXT,
  message TEXT,
  expected TEXT,
  actual TEXT,
  passed BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**Option B: JSON File**
```json
// /test_results/run_20251227_143022.json
{
  "run_id": "run_20251227_143022",
  "bot_username": "@food_tester_bot",
  "task": "test food logging",
  "total_tests": 15,
  "passed": 14,
  "failed": 1,
  "duration_seconds": 45,
  "timestamp": "2025-12-27T14:30:22Z",
  "tests": [
    {
      "test_id": "test_001",
      "type": "text",
      "message": "Chicken 200g",
      "expected": "recorded.*calories",
      "actual": "Recorded chicken 200g (~330 calories)",
      "passed": true
    }
  ]
}
```

---

## Implementation Priority

### Phase 1: Foundation
1. Update Telethon Server with /send_photo and /send_voice
2. Create Webhook trigger in n8n
3. Build basic loop structure
4. Implement text/command testing

### Phase 2: AI Generation
1. Create AI Test Generator agent
2. Build prompt templates
3. Implement response validator
4. Add result logging

### Phase 3: Media Support
1. Prepare test data files
2. Implement photo upload
3. Implement voice upload
4. Test all message types

### Phase 4: Polish
1. Error handling
2. Retry logic
3. Detailed reporting
4. Dashboard/UI

---

## File Structure

```
/bot-testing-system/
├── telegram_sender.py          # Telethon Server (UPDATED)
├── requirements.txt
├── test_data/                  # Test files
│   ├── photos/
│   ├── voice/
│   └── scenarios/
├── test_results/               # Results storage
├── n8n_workflows/
│   ├── Bot_Test_Automation.json
│   └── Test_Generator_Subworkflow.json
└── docs/
    ├── API.md
    └── TEST_SCENARIOS.md
```

---

## Next Steps

1. ✅ Architecture defined
2. ⏳ Update Telethon Server with multipart support
3. ⏳ Create n8n workflow structure
4. ⏳ Build AI Test Generator
5. ⏳ Prepare test data files
6. ⏳ Implement & test
