# Workflow Patterns & /orch Usage

## Using the /orch Command

### Basic Workflow Creation

```bash
/orch Create a webhook that responds with "Hello World"
```

**What happens:**
1. Architect clarifies requirements
2. Researcher searches for similar solutions
3. Architect presents options to user
4. Researcher discovers existing credentials
5. Architect asks user to select credentials
6. Researcher deep dives into implementation details
7. Builder creates workflow
8. QA validates and tests

### Complex Workflow

```bash
/orch Create a Telegram bot that:
- Receives messages
- Stores them in Supabase
- Uses OpenAI to generate replies
- Sends replies back to Telegram
```

**5-Phase Flow:**
- Phase 1: Architect ←→ User (clarify services, error handling)
- Phase 2: Researcher searches (templates, existing workflows)
- Phase 3: Architect ←→ User (choose approach, select credentials)
- Phase 4: Researcher deep dive (learnings, patterns, node configs)
- Phase 5: Builder → QA (create, validate, test)

### Modify Existing Workflow

```bash
/orch workflow_id=abc123 Add error handling and retry logic
```

**Principle:** Modify existing > Build new

### Test Modes

| Command | Purpose |
|---------|---------|
| `/orch --test` | Quick health check of all agents |
| `/orch --test agent:builder` | Test specific agent |
| `/orch --test e2e` | Full production test (20+ nodes) |

## Common n8n Patterns

### 1. Webhook → Process → Response

```
┌─────────┐    ┌─────────┐    ┌──────────┐
│ Webhook │───▶│   Set   │───▶│ Respond  │
└─────────┘    └─────────┘    └──────────┘
```

**Use case:** Simple API endpoints

**Example:**
```bash
/orch Create webhook at /api/hello that responds with JSON {message: "Hello"}
```

### 2. Chat Trigger (AI Workflows)

```
┌──────────────┐    ┌─────────┐    ┌──────────┐
│ Chat Trigger │───▶│ AI Agent│───▶│ Response │
└──────────────┘    └─────────┘    └──────────┘
```

**Why Chat Trigger:**
- Dual mode: UI chat + webhook API
- Session memory (conversation history)
- Manual testing in UI
- Optimized for AI agents

**Example:**
```bash
/orch Create AI assistant with Chat Trigger that uses OpenAI
```

### 3. Data Pipeline

```
┌────────┐    ┌───────────┐    ┌────────┐    ┌─────────────┐
│ Source │───▶│ Transform │───▶│ Filter │───▶│ Destination │
└────────┘    └───────────┘    └────────┘    └─────────────┘
```

**Use case:** ETL workflows

**Example:**
```bash
/orch Fetch data from API, transform to table format, save to Supabase
```

### 4. Multi-Service Integration

```
┌──────────┐    ┌────┐    ┌───────────┐    ┌──────────┐
│ Telegram │───▶│ IF │───▶│  Supabase │───▶│ Telegram │
└──────────┘    └────┘    └───────────┘    └──────────┘
                  │
                  ├───────▶ OpenAI ───────┘
```

**Use case:** Complex chatbots

**Example:**
```bash
/orch Create Telegram bot:
- If message contains "weather" → fetch from API
- Otherwise → ask OpenAI
- Save all messages to Supabase
- Reply to user
```

### 5. Scheduled Tasks

```
┌──────────┐    ┌────────┐    ┌──────────────┐
│ Schedule │───▶│ Action │───▶│ Notification │
└──────────┘    └────────┘    └──────────────┘
```

**Use case:** Periodic jobs

**Example:**
```bash
/orch Every day at 9am, fetch reports from Supabase and send to Telegram
```

### 6. Error Handling Pattern

```
┌──────────┐    ┌────────┐
│   Node   │───▶│ Success│
└──────────┘    └────────┘
     │
     └──(error)──▶ ┌────────────┐    ┌──────────┐
                   │ Error Node │───▶│  Notify  │
                   └────────────┘    └──────────┘
```

**Best practice:** Always handle errors

**Example:**
```bash
/orch Create webhook with error handling:
- Try to insert to Supabase
- On error, log to file and notify admin
```

## Credential Management

### Automatic Discovery

Researcher scans existing workflows for credentials:
- Groups by type (telegram, supabase, openai)
- Presents to user via Architect
- User selects which to use

**No manual setup needed!**

### Example Flow:

```
Architect: Found these credentials:

TELEGRAM:
  [1] Main Bot (id: cred_123)
  [2] Test Bot (id: cred_456)

SUPABASE:
  [1] Production DB (id: cred_789)

Which should I use?
```

## Best Practices

### 1. Use Descriptive Names

❌ Bad: `My Workflow`
✅ Good: `Telegram Bot → Supabase Storage`

### 2. Add Notes to Complex Logic

Builder automatically adds notes for:
- Complex expressions
- Conditional logic (IF/Switch)
- API integrations

### 3. Test Before Production

Always use `/orch --test e2e` for critical workflows

### 4. Error Handling

QA enforces:
- Error output routing
- Timeout handling
- Retry logic (when appropriate)

### 5. Leverage Learnings

Researcher reads from knowledge base:
- `LEARNINGS.md` - proven solutions
- `PATTERNS.md` - reusable patterns
- `LEARNINGS-INDEX.md` - fast lookup

**98% token savings** vs reading full files!

## Templates Location

Workflow templates: `templates/` directory (JSON files)

## Troubleshooting

### Workflow Creation Failed

1. Check QA report: `/orch --test agent:qa`
2. Researcher reads `LEARNINGS.md` for similar errors
3. Builder applies fix
4. QA re-validates

### QA Loop (Max 3 Cycles)

```
QA fail → Builder fix → QA validate → repeat (max 3x)
After 3 fails → stage="blocked" → Analyst post-mortem
```

### Analyst Post-Mortem

When blocked:
- Timeline reconstruction
- Root cause analysis
- Token usage report
- Proposed learnings

**Example output:**
```markdown
## Root Cause
- Missing required field in Set node
- FP: QA flagged jsCode as expression error

## Token Usage
- Total: 34,500 tokens ($0.12)
- Builder: 42% of cost

## Recommendation
- Add L-053: "Set node raw mode validation"
```

## Advanced Patterns

See [PATTERNS.md](learning/PATTERNS.md) for:
- Pattern 0: Smart Workflow Creation
- Pattern 15: Cascading Changes
- Anti-Patterns (what to avoid)
