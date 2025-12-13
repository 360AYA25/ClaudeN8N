# AI Prompt Engineering Best Practices 2025

> **Based on:** Anthropic Context Engineering + n8n Community + 20 Production Templates

---

## 🎯 KEY PRINCIPLES

### 1. Context Engineering > Prompt Engineering

**2025 paradigm shift:**
- ❌ OLD: "How do I craft the perfect prompt?"
- ✅ NEW: "Which configuration of context leads to desired behavior?"

**Source:** [Anthropic Context Engineering Research](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

---

## 📊 TOKEN OPTIMIZATION STRATEGIES

### Strategy 1: Concise Prompting (-40-50% tokens)

**Before:**
```
You are a helpful food tracking assistant for Russian-speaking users. Your primary responsibility is to help users track their daily nutrition intake including calories, proteins, fats, and carbohydrates. You should always respond in Russian language and use appropriate emojis to make the conversation more engaging and user-friendly.
```
(~50 tokens)

**After:**
```
You are a Russian-speaking food tracking assistant.
```
(~7 tokens = **86% reduction!**)

**Rule:** Cut fluff, use precise instructions. [Source](https://portkey.ai/blog/optimize-token-efficiency-in-prompts/)

---

### Strategy 2: Hashtags & Structure

**Use concise formatting:**

```
# Core Task
Track food, respond in Russian

# Output Format
- Emoji: 🔥 kcal, 🥩 protein
- Units: ккал, г, мл

# Rules
- No signatures
- Percentages allowed >100%
```

**Why it works:**
- Hashtags (`#`) + bullet points = visual hierarchy
- GPT-4o generalizes well from short, structured prompts
- Claude benefits from semantic tags: `<task>`, `<context>`, `<rules>`

[Source](https://www.lakera.ai/blog/prompt-engineering-guide)

---

### Strategy 3: Example Compression

**Bad (verbose):**
```
Example of good daily report:

📊 **Сводка на сегодня** (10 декабря 2025)

🍽 **Общее потребление:**
- Калории: 1500 ккал (75% от цели 2000 ккал) 🔥
- Белки: 90 г (90% от цели 100 г) 🥩
[etc...]
```
(~150 tokens)

**Good (template):**
```
Format:
📊 Сводка (Date)
🍽 Общее:
- Калории: XXX ккал (YY%) 🔥
- Белки: XX г (YY%) 🥩
```
(~30 tokens = **80% reduction!**)

---

### Strategy 4: Remove Redundancy

**Bad:**
```
CRITICAL RULE: Never add signatures!
You MUST NOT add signatures!
DO NOT add any closing remarks!
FORBIDDEN: "This message was sent..."
YOUR RESPONSE MUST END IMMEDIATELY!
```
(~40 tokens - same message 5 times!)

**Good:**
```
NO signatures/footers - end response after content
```
(~8 tokens = **80% reduction!**)

---

## 🧠 CONTEXT MANAGEMENT TECHNIQUES

### 1. Summarization (for large inputs)

**Before sending to AI:**
```javascript
// Don't send full 10,000-char HTML
const rawHTML = "<html>...</html>"; // 10K chars

// Convert to markdown first
const markdown = htmlToMarkdown(rawHTML); // 2K chars

// Then summarize if still too long
const summary = summarize(markdown); // 500 chars
```

**Token savings:** 90%!

[Source](https://www.theaiautomators.com/context-engineering-strategies-to-build-better-ai-agents/)

---

### 2. Context Trimming

**Limit memory window:**
```javascript
// Bad: Unlimited history
memoryBufferWindow({ contextWindowLength: -1 }) // Grows infinitely!

// Good: Last N messages only
memoryBufferWindow({ contextWindowLength: 10 }) // Last 10 only
```

**Why:** Each extra message = +100-500 tokens per request!

---

### 3. Dynamic Context Injection

**Inject ONLY what's needed:**

```javascript
// Don't hardcode in systemMessage:
systemMessage: `User timezone: ${user.timezone}` // Static!

// Inject dynamically per request:
const chatInput = `[SYSTEM: timezone=${user.timezone}] ${userMessage}`;
```

**Benefit:** Prompt stays short, context stays fresh

---

## ⚡ MODEL-SPECIFIC OPTIMIZATIONS

### GPT-4o / GPT-4o-mini

**Best practices:**
- ✅ Use hashtags `#`, numbered lists
- ✅ Consistent delimiters (`---`, `###`)
- ✅ Short, structured prompts
- ❌ Avoid verbose explanations

### Claude 4

**Best practices:**
- ✅ Use semantic tags: `<task>`, `<context>`, `<rules>`
- ✅ Tags help compress while staying readable
- ✅ Benefit from clarity > wording length

**Example:**
```
<task>Track food, respond in Russian</task>
<rules>
- Units: ккал, г, мл
- NO signatures
</rules>
```

[Source](https://10clouds.com/blog/a-i/mastering-ai-token-optimization-proven-strategies-to-cut-ai-cost/)

---

## 🚀 ADVANCED TECHNIQUES

### 1. Prompt Caching (4x cost reduction!)

**Move static prompts to cache:**

```javascript
// Static part (cached)
const staticPrompt = `
You are a food tracking assistant.
Rules: [long list...]
Format: [examples...]
`;

// Dynamic part (per request)
const dynamicContext = `User: ${user.name}, Date: ${date}`;

// Result: Static part cached = 4x cheaper!
```

**Savings:** First request full price, subsequent 75% cheaper!

[Source](https://guptadeepak.com/complete-guide-to-ai-tokens-understanding-optimization-and-cost-management/)

---

### 2. Batch Processing

**Process multiple items in ONE prompt:**

```javascript
// Bad: 10 separate requests
foods.forEach(food => {
  ai.analyze(food); // 10x cost!
});

// Good: Batch in single request
ai.analyze({
  foods: [food1, food2, food3...] // 1x cost!
});
```

**Savings:** 90% for bulk operations!

[Source](https://medium.com/@anishnarayan09/agentic-ai-automation-optimize-efficiency-minimize-token-costs-69185687713c)

---

### 3. Right-Size Model Selection

**Use smallest model that works:**

| Task | Model | Cost | Speed |
|------|-------|------|-------|
| Simple routing | gpt-4o-mini | $0.15/1M | 🚀🚀🚀 |
| Complex reasoning | gpt-4o | $2.50/1M | 🚀🚀 |
| Creative writing | GPT-4 Turbo | $10/1M | 🚀 |

**Rule:** Start with mini, upgrade only if needed!

[Source](https://www.uipath.com/blog/ai/agent-builder-best-practices)

---

## 📏 TOKEN BUDGET GUIDELINES

### Recommended Limits (per component)

| Component | Ideal | Max | Notes |
|-----------|-------|-----|-------|
| System Prompt | 100-300 | 500 | Base instructions |
| User Message | 50-200 | 1000 | Per request |
| Tool Descriptions | 50-100/tool | 200/tool | Keep concise |
| Memory Window | 10 messages | 20 messages | Balance context vs cost |
| **Total per request** | **500-1000** | **2000** | Sweet spot |

**Why these limits:**
- <500 tokens = Fast, cheap, responsive
- 500-1000 = Good balance
- 1000-2000 = Expensive but detailed
- >2000 = Diminishing returns!

[Source](https://community.n8n.io/t/limiting-token-usage-with-ai-agents-and-long-system-prompts/163229)

---

## ✅ CHECKLIST: Before Deploying Prompt

### 1. Length Check
- [ ] System prompt <300 tokens?
- [ ] No redundant explanations?
- [ ] Examples compressed to templates?

### 2. Structure Check
- [ ] Uses hashtags/bullets?
- [ ] Clear sections?
- [ ] No 5x repetitions?

### 3. Context Check
- [ ] Dynamic data injected per-request?
- [ ] Memory window limited?
- [ ] Caching enabled for static parts?

### 4. Cost Check
- [ ] Right-sized model selected?
- [ ] Batch processing where possible?
- [ ] Token budget <1000 per request?

### 5. Protection Check
- [ ] Canonical snapshot saved?
- [ ] Edit_scope excludes AI Agent?
- [ ] QA validates prompt existence?

---

## 📚 RECOMMENDED READING

**Essential Resources:**
1. [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
2. [9 Context Engineering Strategies (n8n)](https://www.theaiautomators.com/context-engineering-strategies-to-build-better-ai-agents/)
3. [Token Optimization Guide](https://portkey.ai/blog/optimize-token-efficiency-in-prompts/)
4. [Prompt Engineering 2025](https://www.lakera.ai/blog/prompt-engineering-guide)
5. [AI Token Cost Mastery](https://10clouds.com/blog/a-i/mastering-ai-token-optimization-proven-strategies-to-cut-ai-cost/)

**n8n Community:**
- [Limiting Token Usage Discussion](https://community.n8n.io/t/limiting-token-usage-with-ai-agents-and-long-system-prompts/163229)
- [AI Agent Prompting Best Practices](https://medium.com/automation-labs/ai-agent-prompting-for-n8n-the-best-practices-that-actually-work-in-2025-8511c5c16294)

---

## 🎓 REAL-WORLD EXAMPLE: FoodTracker Optimization

**Before:**
- System prompt: 550 tokens
- Cost: $0.08/month (1000 requests)
- Problem: Redundant warnings, verbose examples

**After:**
- System prompt: 270 tokens
- Cost: $0.04/month (1000 requests)
- **Savings:** 51% tokens, 50% cost!

**Applied techniques:**
1. ✅ Remove redundancy (NO SIGNATURES: 500 → 20 tokens)
2. ✅ Compress examples (full → template)
3. ✅ Hashtag structure
4. ✅ Canonical snapshot for protection

**Result:** Cheaper, faster, safer! 🎉

---

## 💡 FINAL TIPS

1. **Start minimal** - Add complexity only when needed
2. **Test & iterate** - A/B test compressed vs verbose
3. **Monitor costs** - Track token usage in logs
4. **Protect prompts** - Save canonical snapshots
5. **Follow context engineering** - Config > crafting

**Remember:** Shorter prompts often perform BETTER than long ones!
